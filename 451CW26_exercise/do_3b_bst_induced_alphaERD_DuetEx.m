% % do_bst_induced_Duet_alphaERD.m
% adapted from do_bst_freq_for_long_epochs_2017Nov.m that I made for Aury

%% list all the subjects 
% it's not pair anymore

subj = {
        'S01';
        'S02';
        'S03';
        'S04'; 
%         'S05'; % S05 OUT for Alpha and FRN
%         'S06'; 
%         'S07'; % S07 S08 OUT for Alpha, IN for FRN
%         'S08'; % S07 S08 OUT for Alpha, IN for FRN
%         'S09';
%         'S10';
%         'S11';
%         'S12'; % S12 OUT for Alpha and FRN
%         'S13';
%         'S14';
%         'S15'; % S15 S16 OUT for Alpha and FRN
%         'S16'; % S15 S16 OUT for Alpha and FRN
%         'S17';
%         'S18';
%         'S19';
%         'S20';
%         'S21'; % S21 S22 OUT for Alpha and FRN
%         'S22'; % S21 S22 OUT for Alpha and FRN
%         'S23';
%         'S24';
};
nsubj = size(subj,1);

cond = {
    'LeaderSameHuman';
    'LeaderDiffHuman';
    'FollowerSameHuman';
    'FollowerDiffHuman';
    'LeaderSameComp';
    'LeaderDiffComp';
    'FollowerSameComp';
    'FollowerDiffComp';
    };
ncond = size(cond,1);

dirname =  'C:\Users\tfujioka\Documents\brainstorm_db\Duet2017b\data';

for isubj= 1:nsubj
    subjname = subj{isubj};
   
    for icond = 1:ncond
        condname = cond{icond};
        curr_dir = sprintf('%s/%s/%s/data_%s_trial*.mat',dirname,subjname,condname,condname); % 
        dd = dir(curr_dir);
        c = struct2cell(dd);
        cc = c(1,:);
        ncc = size(cc,2);
        sFiles = cell(1,ncc);
        for icc=1:ncc
            sFiles{icc}=sprintf('%s/%s/%s',subjname,condname,char(cc{icc}));
        end
        
        nfile = size(cc,2);
          
        % Start a new report
        %bst_report('Start', sFiles);
        
% Process: Time-frequency (Morlet wavelets)
sFiles = bst_process('CallProcess', 'process_timefreq', sFiles, [], ...
    'sensortypes',   'MEG, EEG', ...
    'edit',          struct(...
         'Comment',         'Avg,Power,1-60Hz', ...
         'TimeBands',       [], ...
         'Freqs',           [1, 1.5, 2, 2.6, 3.3, 3.9, 4.7, 5.5, 6.3, 7.2, 8.2, 9.3, 10.4, 11.7, 13, 14.4, 16, 17.6, 19.4, 21.3, 23.4, 25.6, 28, 30.6, 33.4, 36.4, 39.7, 43.1, 46.9, 51, 55.3, 60], ...
         'MorletFc',        1, ...
         'MorletFwhmTc',    3, ...
         'ClusterFuncTime', 'none', ...
         'Measure',         'power', ...
         'Output',          'average', ...
         'RemoveEvoked',    1, ...
         'SaveKernel',      0), ...
    'normalize2020', 1, ...
    'normalize',     'none');  % None: Save non-standardized time-frequency maps

        % Process: Event-related perturbation (ERS/ERD): [-1.004s,2.500s]
        sFiles = bst_process('CallProcess', 'process_baseline_norm', sFiles, [], ...
            'baseline',  [-1.004, 2.5], ...
            'method',    'ersd', ...  % Event-related perturbation (ERS/ERD):    x_std = (x - &mu;) / &mu; * 100
            'overwrite', 0);


        % Process: Add time offset: -21.00ms for new arduino, -20 ms for old
        % arduino
        sFiles = bst_process('CallProcess', 'process_timeoffset', ...
            sFiles, [], ...
            'offset', -0.021, ...
            'overwrite', 0);
                
        % Save and display report
        %ReportFile = bst_report('Save', sFiles);
        %bst_report('Open', ReportFile);
        
    end % icond
end % isubj

