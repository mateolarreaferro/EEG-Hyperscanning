% do_extract_alphaERD.m
% by Takako and Iran
% 2016 March 12
% for piano duet data.

% adapted for Music451C W19 - 2019 02 04
% Music451C W26 2026 01 31

%% extract alpha bins for every channel and avg.

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


% frequencies copied from data.Freqs ahead of time
Freqs =[
    1.0000
    1.5000
    2.0000
    2.6000
    3.3000
    3.9000
    4.7000
    5.5000
    6.3000
    7.2000
    8.2000
    9.3000
    10.4000
    11.7000
    13.0000
    14.4000
    16.0000
    17.6000
    19.4000
    21.3000
    23.4000
    25.6000
    28.0000
    30.6000
    33.4000
    36.4000
    39.7000
    43.1000
    46.9000
    51.0000
    55.3000
    60.0000
    ];

% which frequencies (bins) I will average together to make one time series per channel
alpha_min = 8; % 13
alpha_max = 13; % 31
alpha_bins = find(Freqs > alpha_min & Freqs < alpha_max);

%% correct channel names (RowNames)
RowNames62 = {
    'Fp1';    'Fpz';   'Fp2';   'AF3';    'AF4';    'F7';    'F5';      'F3';    'F1';    'Fz';
    'F2';     'F4';     'F6';    'F8';    'FT7';    'FC5';    'FC3';    'FC1';    'FCz';   'FC2';
    'FC4';    'FC6';    'FT8';    'T7';    'C5';    'C3';     'C1' ;    'Cz';     'C2';   'C4';
    'C6';     'T8';    'TP7';    'CP5';    'CP3';    'CP1';   'CPz';    'CP2';  'CP4';    'CP6';
    'TP8';    'P7';    'P5';     'P3';     'P1';     'Pz';    'P2';     'P4';   'P6';    'P8';
    'PO7';    'PO5';   'PO3';    'POz';    'PO4';    'PO6';   'PO8';    'CB1';  'O1';    'Oz';
    'O2';    'CB2'};

%% go through each data matrix  Alpha ERD

% save bands in a big matrix [subject x condition X channels X time]
% for these parameters, look at one TF file from Brainstorm -> View file contents
ntime = 563;
nchan = 62;
nfreq = 32;

% storage for number of trials
numavg_all = zeros(nsubj,ncond);
% storage for all the alpha data (mean of 8-13 Hz)
alpha_e = zeros(nsubj,ncond,nchan,ntime);
missing_channel_files = {}; % empty cell

for isubj = 1:nsubj
    for icond = 1:ncond

        subjname = subj{isubj};
        condname = cond{icond};

        % pay attention to date and time when you get ERD time-frequency data
        curr_dir = sprintf('%s/%s/%s/timefreq_morlet_*_ersd_timeoffset.mat', dirname,subjname, condname);

        dd = dir(curr_dir);
        c = struct2cell(dd);
        cc = c(1,:);
        ncc = size(cc,2);

        if isempty(c)
            display(sprintf('there is no time freuqency average file for the subject %s in the condition %s',subjname, condname));
            continue;
        end
        if size(cc,2) >1
            display(sprintf('multiple time frequency average files exist for the subject %s in the condition %s',subjname, condname));
            continue;
        end
        tffilename = sprintf('%s/%s/%s/%s',dirname,subjname,condname,char(cc));
        load(tffilename)

        numavg_all(isubj,icond)=nAvg;

        if size(TF,1) ~= 62
            disp(sprintf('Missing channel %d: tffilename is:%s',size(TF,1), tffilename));

            % check RowNames and determin what's missing
            TF_new = zeros(nchan, ntime, nfreq);
            for ichan=1:62
                % check one by one of RowNames, and if channel name matches to RowNames62
                % then copy TF for that channel
                indx = find(strcmp(RowNames62{ichan}, RowNames));
                if ~isempty(indx)
                    %disp(sprintf('Chan%d Data%d',ichan,indx));
                    TF_new(ichan,:,:)=TF(indx,:,:);
                end
            end
            TF=TF_new;

        end

        % variable TF is [channels x time x bins]
        alpha_e(isubj, icond, :, :) = mean(TF(:,:,alpha_bins), 3);

    end
end

%% save workspace
mydate = '20260203';
save(sprintf('AlphaERD_DuetEx_%s.mat',mydate));

% if you see the message of 'multiple ersd files' then go back to
% Brainstorm and decide which one you like to furhter analyze and delete
% unwanted ones

%% missing conditions?
display('alpha')
for isubj=1:nsubj
   display(isubj)
   find(squeeze(mean(mean(alpha_e(isubj,:,:,:),3),4))==0)
end

% if no missing condition happens for each subject this will spit out
% Empty matrix: 1-by-0 (that's good news)

%% check data
% if some strange peaks exceeding 100% are happening in someone's data, you'd have to
% investigate Average power spectrogram, ERSD, and remove noisy single
% trials then redo the stuff then run this script again to export to MATLAB

for isubj=1:nsubj
    for icond=1:ncond
        figure;
        
        plot(Time, squeeze(alpha_e(isubj,icond,:,:)));
        title(sprintf('Alpha: subj=%s,%s', subj{isubj}, cond{icond}));
               
    end
end

%%
close all
