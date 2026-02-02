% do_bst_epoch_avg_Duet_FRN.m
% 2015 Dec 20 by Takako Fujioka
% 2016 Mar 6 by Takako Fujioka
% 2017 Dec 7 by Madeline Huberth for FRN study
% 2019 Jan 27 brought back by Takako
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

dirname='C:\Users\tfujioka\Documents\brainstorm_db\Duet2017a\data';

for ipair = 1:npair
    
    sub={pair{ipair,1};
        pair{ipair,2}};
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
             
        
        %         Process: Import MEG/EEG: Events
        sFiles = bst_process(...
            'CallProcess', 'process_import_data_event', ...
            sFiles, [], ...
            'subjectname', subjname, ...
            'condition', '', ...
            'eventname', 'DevSelfSameHuman, DevOtherSameHuman, StdSelfSameHuman, StdOtherSameHuman,DevSelfDiffHuman, DevOtherDiffHuman, StdSelfDiffHuman, StdOtherDiffHuman, DevSelfSameComp, DevOtherSameComp, StdSelfSameComp, StdOtherSameComp, DevSelfDiffComp, DevOtherDiffComp, StdSelfDiffComp, StdOtherDiffComp, DevSelfSameHumanFirst, DevOtherSameHumanFirst, StdSelfSameHumanFirst, StdOtherSameHumanFirst,DevSelfDiffHumanFirst, DevOtherDiffHumanFirst, StdSelfDiffHumanFirst, StdOtherDiffHumanFirst, DevSelfSameCompFirst, DevOtherSameCompFirst, StdSelfSameCompFirst, StdOtherSameCompFirst, DevSelfDiffCompFirst, DevOtherDiffCompFirst, StdSelfDiffCompFirst, StdOtherDiffCompFirst, DevSelfSameHumanSecond, DevOtherSameHumanSecond, StdSelfSameHumanSecond, StdOtherSameHumanSecond,DevSelfDiffHumanSecond, DevOtherDiffHumanSecond, StdSelfDiffHumanSecond, StdOtherDiffHumanSecond, DevSelfSameCompSecond, DevOtherSameCompSecond, StdSelfSameCompSecond, StdOtherSameCompSecond, DevSelfDiffCompSecond, DevOtherDiffCompSecond, StdSelfDiffCompSecond, StdOtherDiffCompSecond', ...
            'timewindow', [0, timemax], ...
            'epochtime', [-0.5 1.0], ...
            'createcond', 1, ...
            'ignoreshort', 1, ...
            'usectfcomp', 1, ...
            'usessp', 0, ...
            'freq', [], ...
            'baseline', []);
        
        % Note that ssp is turned off because we already run it at the
        % first place
        
        % Process: Detect bad channels: Peak-to-peak  EEG(-250-250)
        sFiles = bst_process(...
            'CallProcess', 'process_detectbad', ...
            sFiles, [], ...
            'timewindow', [-0.2, 0.6], ...
            'meggrad', [0, 0], ...
            'megmag', [0, 0], ...
            'eeg', [-250, 250], ...
            'eog', [0, 0], ...
            'ecg', [0, 0], ...
            'rejectmode',  1);  % Reject only the bad channels
        
        % Process: Average: By condition (subject average)
        sFiles = bst_process(...
            'CallProcess', 'process_average', ...
            sFiles, [], ...
            'avgtype', 3, ...
            'avg_func', 1, ...  % <HTML>Arithmetic average: <FONT color="#777777">mean(x)</FONT>
            'keepevents', 0);
        
        % Process: Add time offset: -21.00ms for new arduino, -20 ms for old
        % arduino
        sFiles = bst_process('CallProcess', 'process_timeoffset', ...
            sFiles, [], ...
            'offset', -0.021, ...
            'overwrite', 0);
        
        
        % Process: DC offset correction: [-50ms,0ms]
        sFiles = bst_process('CallProcess', 'process_baseline', sFiles, [], ...
            'baseline',    [-0.05, 0], ...
            'sensortypes', 'EEG', ...
            'method',      'bl', ...  % DC offset correction:    x_std = x - &mu;
            'overwrite',   1);
        
        
    end % isubj
end %ipair

%% you can now make individual ERPs and look at topographies.
% Also you can make grandaverages and difference waveforms in Brainstorm to
% assess what is happening.

%% Note that, however, now, you don't need Brainstorm anymore.
% First, export all datasets and save the workspace.
% After that, use that workspace to keep post-processing (filter, combine
% electrode group, plotting, and stats).