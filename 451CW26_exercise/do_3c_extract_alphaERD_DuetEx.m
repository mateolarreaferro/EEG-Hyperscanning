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
        'S09';
        'S10';
        'S13';
        'S14';
        'S17';
        'S18';
        'S19';
        'S20';
        'S23';
        'S24';
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


dirname =  '/Volumes/MLF/EEG-Hyperscanning/brainstorm_db/Duet2017/data';


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


%% go through each data matrix  Alpha ERD

% save bands in a big matrix [subject x condition X channels X time]
% for these parameters, look at one TF file from Brainstorm -> View file contents
ntime = 563;
nchan = 62;
nfreq = 32;

% storage for number of trials
numavg_all = zeros(nsubj,ncond);
% storage for all the alpha data (mean of 8-13 Hz)
ae = zeros(nsubj,ncond,nchan,ntime);
for isubj = 1:nsubj
    for icond = 1:ncond
        
        subjname = subj{isubj};
        condname = cond{icond};
       
        % pay attention to date and time when you get ERD time-frequency data
        curr_dir = sprintf('%s/%s/%s/timefreq_morlet_*_ersd.mat', dirname,subjname, condname);
        
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
            display(sprintf('there is less number of channel for this subject %s in the condition %s', subjname, condname))
            display('You should fix that condition file by interporating the missing channel(s)');
            continue;
        end
        
        % variable TF is [channels x time x bins]
        ae(isubj, icond, :, :) = mean(TF(:,:,alpha_bins), 3);
        
    end
end

%% save workspace
mydate = '20260208';
outdir = '/Volumes/MLF/EEG-Hyperscanning/output';
save(sprintf('%s/AlphaERD_DuetEx_%s.mat',outdir,mydate), 'ae', 'numavg_all', 'subj', 'nsubj', 'cond', 'ncond', 'Freqs', 'alpha_bins', 'ntime', 'nchan', 'nfreq', 'Time');
