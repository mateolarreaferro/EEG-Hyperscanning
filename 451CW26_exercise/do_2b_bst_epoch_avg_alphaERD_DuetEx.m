% do_bst_epoch_avg_Duet_alphaERD.m
% 2015 Dec 20 by Takako Fujioka
% 2016 Mar 7 by Takako Fujioka


% 2016 Mar 12 Note by Takako Fujioka
% The huge amplitude edges appearing after importing epoches
% from the continuous file were caused by the cnt file when
% you are converting Curry7 .dat files to .cnt files
% you forget to chose 'constant' in the Baseline tab
% inside the Curry7. This is affecting the Brainstorm when it tries to
% downsample the data while it's importing. 
% Whether .cnt file is correctly 'constant' baselined is visible if
% you open the .cnt file from Curry7 main File -> Open menu.
% If the traces don't look equal distance from each other, it is not adjusted.
% But this cannot be visible if you open the original .dat file, because
% Curry7 default to open .dat file is to set the baseline 'Off'.
% You have to open .cnt files to see the difference. 

% 2026 Jan 27 for 451C W26 Exercise


%% list all the pairs

pair = {
        'S01', 'S02';
        'S03', 'S04'; 
%         'S05', 'S06'; % S05 OUT for Alpha and FRN
%         'S07', 'S08'; % S07 S08 OUT for Alpha, IN for FRN
%         'S09', 'S10';
%         'S11', 'S12'; % S12 OUT for Alpha and FRN
%         'S13', 'S14';
%         'S15', 'S16'; % S15 S16 OUT for Alpha and FRN
%         'S17', 'S18';
%         'S19', 'S20';
%         'S21', 'S22'; % S21 S22 OUT for Alpha and FRN
%         'S23', 'S24';
    };
npair = size(pair,1);

player = {'SubA';'SubB'};

%first line is first pair, second line is second pair
melnames = [
    1,2,3,4;
    3,4,1,2;
%     1,2,3,4;
%     3,4,1,2;
%     1,2,3,4;
%     3,4,1,2;
%     1,2,3,4;
%     3,4,1,2;
%     1,2,3,4;
%     3,4,1,2;
%     1,2,3,4;
%     3,4,1,2;
    ];

dirname='C:\Users\tfujioka\Documents\brainstorm_db\Duet2017b\data';


for ipair=1:npair
    sub={pair{ipair,1};pair{ipair,2}};
    pairname = sprintf('%s_%s', sub{1}, sub{2});
    
    for isubj=1:2
        
        subjname = sub{isubj};
        playerID= player{isubj};
        
        % List all the raw files for each subject (but applied
        % repair_steps)
         sFiles = {...
            sprintf('%s/%s_AA%d_1_Data/data_block001_matlab.mat',subjname,subjname,melnames(ipair,1)), ...
            sprintf('%s/%s_AA%d_2_Data/data_block001_matlab.mat',subjname,subjname,melnames(ipair,1)), ...
            sprintf('%s/%s_BC%d_1_Data/data_block001_matlab.mat',subjname,subjname,melnames(ipair,2)), ...
            sprintf('%s/%s_BC%d_2_Data/data_block001_matlab.mat',subjname,subjname,melnames(ipair,2)), ...
            sprintf('%s/%s_AA%d_1_%s_Data/data_block001_matlab.mat',subjname,pairname,melnames(ipair,3),playerID),...
            sprintf('%s/%s_AA%d_2_%s_Data/data_block001_matlab.mat',subjname,pairname,melnames(ipair,3),playerID),...
            sprintf('%s/%s_BC%d_1_%s_Data/data_block001_matlab.mat',subjname,pairname,melnames(ipair,4),playerID), ...
            sprintf('%s/%s_BC%d_2_%s_Data/data_block001_matlab.mat',subjname,pairname,melnames(ipair,4),playerID), ...
            };

        timemax = 1800;
        
        
        % Process: Import MEG/EEG: Events
        sFiles = bst_process(...
            'CallProcess', 'process_import_data_event', ...
            sFiles, [], ...
            'subjectname', subjname, ...
            'condition', '', ...
            'eventname', 'LeaderSameHuman, LeaderDiffHuman, FollowerSameHuman, FollowerDiffHuman, LeaderSameComp, LeaderDiffComp, FollowerSameComp, FollowerDiffComp' , ...
            'timewindow', [0, timemax], ...
            'epochtime', [-1.5, 3.0], ...
            'createcond', 1, ...
            'ignoreshort', 1, ...
            'usectfcomp', 0, ...
            'usessp', 1, ...
            'freq', 125, ... % downsampling from 500Hz to 125Hz
            'baseline', []);
           % 'eventname', 'LeaderSameHuman, LeaderDiffHuman, FollowerSameHuman, FollowerDiffHuman, LeaderSameComp, LeaderDiffComp, FollowerSameComp, FollowerDiffComp' , ...
        
        
        % Process: Detect bad channels: Peak-to-peak  EEG(-350-350)
        sFiles = bst_process(...
            'CallProcess', 'process_detectbad', ...
            sFiles, [], ...
            'timewindow', [-1.0, 3.0], ...
            'meggrad', [0, 0], ...
            'megmag', [0, 0], ...
            'eeg', [-250, 250], ...
            'eog', [0, 0], ...
            'ecg', [0, 0], ...
            'rejectmode',  1);  % Reject only the bad channels
        %'rejectmode', 2);  % Reject trials
        
        % Process: Average: By condition (subject average)
        sFiles = bst_process(...
            'CallProcess', 'process_average', ...
            sFiles, [], ...
            'avgtype', 3, ...
            'avg_func', 1, ...  % <HTML>Arithmetic average: <FONT color="#777777">mean(x)</FONT>
            'keepevents', 0);
        
        % Process: Remove DC offset: [-100ms,0ms]
        sFiles = bst_process(...
            'CallProcess', 'process_baseline', ...
            sFiles, [], ...
            'baseline', [-0.10, 0.00], ...
            'sensortypes', 'EEG', ...
            'overwrite', 1);
                
        
     end % isubj
end %ipair


% after this 