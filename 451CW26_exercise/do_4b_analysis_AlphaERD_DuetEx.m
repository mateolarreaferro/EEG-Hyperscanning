% do_analysis_alphaERD.m
% adapted from generate_plots_20190124.m

% analysis for UNISON phrase only. see other 07b scripts for phrase or
%       std/dev analysis -BN

% Takako adapted back for Phrase2 and 3 analysis from BN's version (2020
% June, July)

% Takako modified this for Rhythm Prime data (2023-06-27)

% 2026-02-03 Takako modified this for 451C W26 exercise

%% CLOSE Brainstorm First!!!!!

%% LOAD the exported MATLAB workspace 
close all
clear all

% first load the data with the alpha bins for all channels
mydirectory = '/Volumes/MLF/EEG-Hyperscanning/output';
load(sprintf('%s/AlphaERD_DuetEx_20260208.mat',mydirectory));
alpha_e = ae; % rename to match expected variable name

% Diagnostics: check data range and trial counts
fprintf('Alpha data range: [%f, %f]\n', min(alpha_e(:)), max(alpha_e(:)));
fprintf('Number of valid subject-condition combos (nAvg>0): %d out of %d\n', sum(numavg_all(:)>0), numel(numavg_all));
fprintf('numavg_all:\n');
disp(numavg_all);

%% Variables inside the workspace (that's made in do_3c_extract_alphaERD and part of the loaded workspace so we don't re-define)
% subj = {
%     'S01';
%     'S02';
%     'S03';
%     'S04';
%     %         'S05'; % S05 OUT for Alpha and FRN
%     %         'S06';
%     %         'S07'; % S07 S08 OUT for Alpha, IN for FRN
%     %         'S08'; % S07 S08 OUT for Alpha, IN for FRN
%     %         'S09';
%     %         'S10';
%     %         'S11';
%     %         'S12'; % S12 OUT for Alpha and FRN
%     %         'S13';
%     %         'S14';
%     %         'S15'; % S15 S16 OUT for Alpha and FRN
%     %         'S16'; % S15 S16 OUT for Alpha and FRN
%     %         'S17';
%     %         'S18';
%     %         'S19';
%     %         'S20';
%     %         'S21'; % S21 S22 OUT for Alpha and FRN
%     %         'S22'; % S21 S22 OUT for Alpha and FRN
%     %         'S23';
%     %         'S24';
%     };
% nsubj = size(subj,1);
% 
% cond = {
%     'LeaderSameHuman';
%     'LeaderDiffHuman';
%     'FollowerSameHuman';
%     'FollowerDiffHuman';
%     'LeaderSameComp';
%     'LeaderDiffComp';
%     'FollowerSameComp';
%     'FollowerDiffComp';
%     };
% ncond = size(cond,1);
% 
% 
% dirname =  'C:\Users\tfujioka\Documents\brainstorm_db\Duet2017b\data';
% 
% 
% % frequencies copied from data.Freqs ahead of time
% Freqs =[
%     1.0000
%     1.5000
%     2.0000
%     2.6000
%     3.3000
%     3.9000
%     4.7000
%     5.5000
%     6.3000
%     7.2000
%     8.2000
%     9.3000
%     10.4000
%     11.7000
%     13.0000
%     14.4000
%     16.0000
%     17.6000
%     19.4000
%     21.3000
%     23.4000
%     25.6000
%     28.0000
%     30.6000
%     33.4000
%     36.4000
%     39.7000
%     43.1000
%     46.9000
%     51.0000
%     55.3000
%     60.0000
%     ];
% 
% % which frequencies (bins) I will average together to make one time series per channel
% alpha_min = 8; % 13
% alpha_max = 13; % 31
% alpha_bins = find(Freqs > alpha_min & Freqs < alpha_max);
% 
% RowNames62 = {
%     'Fp1';    'Fpz';   'Fp2';   'AF3';    'AF4';    'F7';    'F5';      'F3';    'F1';    'Fz';
%     'F2';     'F4';     'F6';    'F8';    'FT7';    'FC5';    'FC3';    'FC1';    'FCz';   'FC2';
%     'FC4';    'FC6';    'FT8';    'T7';    'C5';    'C3';     'C1' ;    'Cz';     'C2';   'C4';
%     'C6';     'T8';    'TP7';    'CP5';    'CP3';    'CP1';   'CPz';    'CP2';  'CP4';    'CP6';
%     'TP8';    'P7';    'P5';     'P3';     'P1';     'Pz';    'P2';     'P4';   'P6';    'P8';
%     'PO7';    'PO5';   'PO3';    'POz';    'PO4';    'PO6';   'PO8';    'CB1';  'O1';    'Oz';
%     'O2';    'CB2'};
% 
% %
% ntime = 563;
% nchan = 62;
% nfreq = 32;

%% 2 - data organization for ERSD
% organize the data, making it 64 channel for topoplot making
dat_all = zeros(nsubj,ncond,64,ntime);
for isubj = 1:nsubj
    for icond=1:ncond        
        % fill M1 and M2 for convenience in topoplots        
        for ichan = 1:32               
            dat_all(isubj,icond,ichan,:) = squeeze(alpha_e(isubj,icond,ichan,:));                    
        end
        % 33 is M1 and it does not exist in alpha so do nothing there
        % (leave it as zero)
        for ichan = 34:42
            dat_all(isubj,icond,ichan,:) = squeeze(alpha_e(isubj,icond,ichan-1,:));  
        end
        % 43 is M2 and it does not exist in alphaz so do nothing there
        % (leave it as zero)
        for ichan = 44:64
            dat_all(isubj,icond,ichan,:) = squeeze(alpha_e(isubj,icond,ichan-2,:));  
        end
    end
end

% update number of channel
nchan = 64;

% construct the time vector (epoch [-1.5, 3.0]s at 125 Hz, 563 samples)
time = linspace(-1.5, 3.0, ntime);

% sampling rate
fs = 1/(time(2)-time(1));

%% 3 band-pass filter the data for all electrodes

% now these are new struct to associate all the different versions (filter,
% baseline etc.)

ae = struct;

f1=0.1/fs/2; % HP 0.1 Hz
f2=8/fs/2;  % LP 8 Hz
f22=12/fs/2; % LP 12 Hz
[hb,ha]=butter(4, f2); % using no hp
[hb2,ha2]=butter(4, f22); % using lowpass (hereby all variables ending with '2' is using higher lowpass)
dat_all_nf=zeros(size(dat_all));
dat_all_f=zeros(size(dat_all));
dat_all_f2=zeros(size(dat_all));
for isubj=1:nsubj
    for icond=1:ncond
        for ichan=1:nchan
            tmp=squeeze(dat_all(isubj,icond,ichan,:));

            % lowpass-8
            tmp_f=filtfilt(hb,ha,tmp);
            dat_all_f(isubj,icond,ichan,:)=tmp_f;

            % lowpass-12
            tmp_f2=filtfilt(hb2,ha2,tmp);
            dat_all_f2(isubj,icond,ichan,:)=tmp_f2;
        end
    end
end
% alpha
ae.dat_all_nf = dat_all;
ae.dat_all_f = dat_all_f;
ae.dat_all_f2 = dat_all_f2;

%% 4 - ANALYSIS

% so we are interested in the measure 5th first note which provides time
% 0(s) in these epoched data
% let's take 80ms before the onset as baseline

t01=0.0-0.08; %[s] 
t02=0.0-0.0;   %[s]
it01=max(find(time<=t01));
it02=max(find(time<=t02));

% alpha
for isubj=1:nsubj
    for icond=1:ncond
        for ichan=1:nchan
            tmp1=mean(ae.dat_all_nf(isubj,icond,ichan,it01:it02),4);
            tmp=mean(ae.dat_all_f(isubj,icond,ichan,it01:it02),4);
            tmp2=mean(ae.dat_all_f2(isubj,icond,ichan,it01:it02),4);
            for itime=1:ntime
                ae.dat_all_nf(isubj,icond,ichan,itime)=ae.dat_all_nf(isubj,icond,ichan,itime)-tmp1; % no filt
                ae.dat_all_f(isubj,icond,ichan,itime)=ae.dat_all_f(isubj,icond,ichan,itime)-tmp;
                ae.dat_all_f2(isubj,icond,ichan,itime)=ae.dat_all_f2(isubj,icond,ichan,itime)-tmp2; % lowpass
            end
        end
    end
end

%% check the data

mysubj=[1:4]; 
% look into some individuals by dividing into a small group 
% here, 4 people's data in each condition overlaid in one plot
dat_all=ae.dat_all_nf; % alpha

for icond = [1:8]
    figure;
    plot(time, squeeze(dat_all(mysubj,icond,28,:))) % 28 is Cz
    %axis([-1.0, 3.0, -6, 6]);
    %axis([-1.0, 4.0, -6, 6]);
    title(sprintf('%s',cond{icond}))
end

% Checkpoints: individual lines belong to individual people.
% - Is there anyone exceeding largely the range of the group? (more than
% 100%)
% - Is there anyone any condition getting abnormaly noisy or big/peaky?

% If yes, you have to go back to the Brainstorm and do the time-frequency
% analysis, and do the export (do_3c) again and come back here

%%
close all

%% plot individual subjects and grand average for channel 28 - Cz

% ssubj is 'selected subjects'
% So make your list of subjects without people you want to exclude
% ex) ssubj = [1 3 5 6]; % when excluding 2 and 4
ssubj=1:nsubj;

nssubj=length(ssubj);

dat_all=ae.dat_all_nf; % alpha
band_name = 'Alpha';

for icond = 1:ncond
    figure;
    % plot conditions by subj

    for issubj = 1:nssubj
        hold on
        p2 = plot(time, squeeze(dat_all(issubj,icond,28,:)));
        % adjust the y-range here if needed
        axis([-0.5, 3.0, -100, 100]);

        %p2(1).Color = 'b';
        p2(1).LineWidth = 1.3;
    end
    p1 = plot(time, mean(squeeze(dat_all(ssubj,icond,28,:))));
    p1(1).Color = 'k';
    p1(1).LineWidth = 3.0;
    hold on

    xlabel('Time (S)');
    ylabel('Alpha ERS/ERD');
    title(sprintf('%s at Cz for Individual Subjects',cond{icond}));
    legend()
    legend(p1(1),'Grand Average')
    %legend([p1(1)],{'Grand Average'})
    %legend([p1(1) p2(1)],{'Grand Average','Individual Subject (16)'})
end

%%
close all

%% 4 - electrode grouping


% channel_name'
%   Columns 1 through 11
%     'Fp1'    'Fpz'    'Fp2'    'AF3'    'AF4'    'F7'    'F5'    'F3'    'F1'    'Fz'    'F2'
%   Columns 12 through 22
%     'F4'    'F6'    'F8'    'FT7'    'FC5'    'FC3'    'FC1'    'FCz'    'FC2'    'FC4'    'FC6'
%   Columns 23 through 34
%     'FT8'    'T7'    'C5'    'C3'    'C1'    'Cz'    'C2'    'C4'    'C6'    'T8'    'M1'    'TP7'
%   Columns 35 through 45
%     'CP5'    'CP3'    'CP1'    'CPz'    'CP2'    'CP4'    'CP6'    'TP8'    'M2'    'P7'    'P5'
%   Columns 46 through 56
%     'P3'    'P1'    'Pz'    'P2'    'P4'    'P6'    'P8'    'PO7'    'PO5'    'PO3'    'POz'
%   Columns 57 through 67
%     'PO4'    'PO6'    'PO8'    'CB1'    'O1'    'Oz'    'O2'    'CB2'    'VEO'    'HEO'    'Trig'

% % we now determine electrode groupings
 
% 2020 07 22
% looking at ERSD topomaps, it looks better to stay with the previous
% Duet2017's choice of cpl and cpr 
% because the hot spots of alpha increase cover C and CP rows
% Interestingly also, We-Me difference involve only the right side
fc=[9 10 11 18 19 20 ]; %F1 Fz F2 FC1 FCz FC2 
% % central parietal left
cpl=[27 26 25 36 35 34]; %C1 C3 C5 CP1 CP3 CP5
% % central parietal right
cpr=[29 30 31 38 39 40]; %C2 C4 C6 CP2 CP4 CP6
% %cpr=[39 40 48 49]; %CP4 CP6 P4 P6
po=[45 46 47 55 56 57]; % P1 Pz P2 PO3 P0z PO4

s = struct('fc',fc,'cpl',cpl,'cpr',cpr,'po',po);
elec_list = {'fc','cpl','cpr','po'};
nelec = length(elec_list);
short_subj_list = ssubj;

% the three functions below are made by Madeline for making the data
% incorporated into the struct

% Make sure you have 'do_make_elec_groups.m' 'do_elec_GA.m'
tmpa = do_make_elec_groups(s,ae.dat_all_nf,ae.dat_all_f,ae.dat_all_f2); %makes electrode group averages for all people
tmpa = do_elec_GA(tmpa,short_subj_list); %makes GA for just short_subj_list

%% 5 - do t-test for all possble comparison pairings for leader and follower separately

dtype={'leader';'follower'};
ndtype=length(dtype);

cond_leader = [1,2,5,6];
cond_follower = [3,4,7,8];

%     'LeaderSameHuman';
%     'LeaderDiffHuman';
%     'FollowerSameHuman';
%     'FollowerDiffHuman';
%     'LeaderSameComp';
%     'LeaderDiffComp';
%     'FollowerSameComp';
%     'FollowerDiffComp'
contrast = [
    1, 2;
    1, 3;
    1, 4;
    2, 3;
    2, 4;
    3, 4;
    ];

contrast_list = {
    'SameHumanVsDiffHuman'; 
    'SameHumanVsSameComp';
    'SameHumanVsDiffComp';
    'DiffHumanVsSameComp';
    'DiffHumanVsDiffComp';
    'SameCompVsDiffComp';
    };
ncontrast = length(contrast);

% simple stats comparing single pairings of conditions

h_elec=zeros(ndtype,ncontrast,nelec,ntime);
p_elec=zeros(ndtype,ncontrast,nelec,ntime);
for idtype=1:2
    if idtype==1
        % leader 4
        dat_elec_nf = tmpa.dat_elec_nf(short_subj_list, cond_leader,:,:);
    else
        % follower 4
        dat_elec_nf = tmpa.dat_elec_nf(short_subj_list, cond_follower,:,:);
    end

    for icontrast=1:ncontrast
        cond1 = contrast(icontrast,1);
        cond2 = contrast(icontrast,2);

        for ielec=1:nelec
            dat1=squeeze(dat_elec_nf(short_subj_list,cond1, ielec,:));
            dat2=squeeze(dat_elec_nf(short_subj_list,cond2, ielec,:));
            for itime=1:ntime
                [h_elec(idtype,icontrast,ielec,itime),p_elec(idtype,icontrast,ielec,itime)]=my_ttest(dat1(:,itime),dat2(:,itime));
            end
        end
    end
    
end % dtype

tmpa.h_elec = h_elec;
tmpa.p_elec = p_elec;

% just check the data (how much h became 1 (= significant)
figure;
plot(time, squeeze(mean(mean(tmpa.h_elec(1,:,:,:),2),3)));
title('leader');

figure;
plot(time, squeeze(mean(mean(tmpa.h_elec(2,:,:,:),2),3)));
title('follower');


%%
close all

%% plotting elec lines with ttest dots for pair-wise contrasts

% save figures?
save_figure=0;

for idtype =1:2
    if idtype ==1
        % leader
        dat = squeeze(tmpa.dat_GA2(cond_leader,:,:));
        h_dat = squeeze(tmpa.h_elec(idtype,:,:,:));
        curr_cond_list=cond_leader;
    else
        % follower
        dat = squeeze(tmpa.dat_GA2(cond_follower,:,:));
        h_dat = squeeze(tmpa.h_elec(idtype,:,:,:));
        curr_cond_list=cond_follower;
    end

    % where the dots are in the plot (adjust if needed)
    k=-5.0;

    for icontrast = 1:ncontrast

        figure; % one figure for one condition, subplotting electrode groups
        icond1=contrast(icontrast,1); % among 4
        icond2=contrast(icontrast,2);
        cond1_name = cond{curr_cond_list(icond1)}; % among 8
        cond2_name = cond{curr_cond_list(icond2)};

        for ielec=1:nelec
            subplot(1, nelec, ielec);
            
            %figurename = sprintf('GA_%s', cond_list{idiff});
            elec_char=char(elec_list(ielec)); % name of current region we're plotting
            cont_char=char(contrast_list(icontrast,:)); % name of current condition we're plotting
            
            % two lines and the contrast between them
            curr_dat=squeeze(dat([icond1,icond2],ielec,:));
            curr_h_dat=squeeze(h_dat(icontrast,ielec,:));

            % plotting these data in one figure

            % plot lines
            p = plot(time, curr_dat);
            p(1).Color = [187.0/255.0 56.0/255.0 60.0/255.0];;
            p(2).Color = [56.0/255.0 65.0/255.0 186.0/255.0];
            p(1).LineWidth = 1.3;
            p(2).LineWidth = 1.3;
            hold on;grid on;

            % only significant dot appears
            it0 = find(time>0,1);
            it2 = find(time>1.5,1);
            indx=find(curr_h_dat(it0:it2));
            % put dots at the y=k position
            plot(time(it0+indx-1), k*squeeze(curr_h_dat(it0+indx-1)),'co');

            % draw vertical line at 1.5sec
            xline(1.5 , '--r')
            % axis range (adjust if needed)
            ymax = 60;
            axis([-1 2.5 -ymax ymax])
            % xticks every 0.5 sec
            xticks(-1:0.5:2.5);

            % title and legend
            if ielec==nelec
                title(sprintf('%s\n%s', cont_char, elec_char));
                legend(sprintf('%s',cond1_name), sprintf('%s',cond2_name));
            else
                title(sprintf('\n%s', elec_char));
            end
            xlabel('Time (S)');
            ylabel(sprintf('%s ERS/ERD',dtype{idtype}));
            
        end
    end

    if save_figure==1
        % % save all figures
        h = get(0,'children');
        for i=1:length(h)
            saveas(h(i), sprintf('ERSD_lineplot_%s_%s', dtype{idtype}, contrast_list{i}), 'epsc');

        end
    end
end

%% 
close all

%% Find appropriate time window for alpha power ANOVA

% alpha 

%% leader
figure;
gA = squeeze(mean(mean(tmpa.dat_GA2(cond_leader,:,:),1),2)); % average over conditions and electrodes
fprintf('Leader gA range: [%f, %f]\n', min(gA), max(gA));
plot(time,gA); % x-axis is time
title('Alpha:Leader:all conditions');

figure;
plot(1:ntime,gA); % x-axis is sample point
  
% It looks like there is a dip around 0 
% Later we may want to change that because I am making this based on
% the first 4 subjects

% looking for a peak and half-amp window

% make a time window to capture the first positive peak between -1.5 and -1
t02 = -1.5;
it02 = max(find(time<=t02));
t03 = -1.0;
it03 = max(find(time<=t03));
% this one for the positive peak around 1.5
t04 = 1.2;
it04 = max(find(time<=t04));
t05 = 1.7;
it05 = max(find(time<=t05));

% 1st positive peak
[value idx_pk1] =max(gA(it02:it03));
itpk1 = it02+idx_pk1-1;
tpk1 = time(itpk1); %  -1.3050
% next negative peak
[value idx_pk2] =min(gA(it03:it04));
itpk2 = it03+idx_pk2-1;
tpk2 = time(itpk2); %  0.2390
% following positive peak
[value idx_pk3] =max(gA(it04:it05));
itpk3 = it04+idx_pk3-1;
tpk3 = time(itpk3); % 1.4230

% the negative peak in the middle makes the ERD amp
pk2amp = gA(itpk2);

% half amp at the earlier slope where the last point before the amplitude gets
% smaller than the half-way
[value,idx]=max(find(gA(itpk1:itpk2)>gA(itpk1)+(gA(itpk2)-gA(itpk1))/2));
itpk2_b = itpk1+idx-1;
tpk2_b = time(itpk2_b);%  -0.9610

% half amp at the later slope where the last point before the amplitude gets
% larger than the half-way
[value,idx]=max(find(gA(itpk2:itpk3)<gA(itpk2)+(gA(itpk3)-gA(itpk2))/2));
itpk2_e = itpk2+idx-1;
tpk2_e = time(itpk2_e);% 0.9430

itimeA=itpk2_b:itpk2_e;
timeA=[tpk2_b tpk2_e]
%     -0.9610    0.9430

% fallback if half-amplitude window is empty (e.g. flat data)
if isempty(timeA)
    warning('Leader: half-amplitude window empty. Using default [-0.5, 1.0]s');
    tpk2_b = -0.5; tpk2_e = 1.0;
    itpk2_b = max(find(time<=tpk2_b));
    itpk2_e = max(find(time<=tpk2_e));
    itimeA = itpk2_b:itpk2_e;
    timeA = [tpk2_b tpk2_e];
end

% store
itimeA_leader = itimeA;
timeA_leader = timeA;
%%
close all

%% follower
figure;
gA = squeeze(mean(mean(tmpa.dat_GA2(cond_follower,:,:),1),2)); % average over conditions and electrodes
fprintf('Follower gA range: [%f, %f]\n', min(gA), max(gA));
plot(time,gA); % x-axis is time
title('Alpha:Follower:all conditions');

figure;
plot(1:ntime,gA); % x-axis is sample point
  
% It looks like there is a dip around 0 
% Later we may want to change that because I am making this based on
% the first 4 subjects

% looking for a peak and half-amp window

% make a time window to capture the first positive peak between -1.5 and -1
t02 = -1.5;
it02 = max(find(time<=t02));
t03 = -1.0;
it03 = max(find(time<=t03));
% this one for the positive peak around 1.5
t04 = 1.2;
it04 = max(find(time<=t04));
t05 = 1.7;
it05 = max(find(time<=t05));

% 1st positive peak
[value idx_pk1] =max(gA(it02:it03));
itpk1 = it02+idx_pk1-1;
tpk1 = time(itpk1); %   -1.3370
% next negative peak
[value idx_pk2] =min(gA(it03:it04));
itpk2 = it03+idx_pk2-1;
tpk2 = time(itpk2); %  0.1990
% following positive peak
[value idx_pk3] =max(gA(it04:it05));
itpk3 = it04+idx_pk3-1;
tpk3 = time(itpk3); % 1.4230

% the negative peak in the middle makes the ERD amp
pk2amp = gA(itpk2);

% half amp at the earlier slope where the last point before the amplitude gets
% smaller than the half-way
[value,idx]=max(find(gA(itpk1:itpk2)>gA(itpk1)+(gA(itpk2)-gA(itpk1))/2));
itpk2_b = itpk1+idx-1;
tpk2_b = time(itpk2_b);%    -0.2490

% half amp at the later slope where the last point before the amplitude gets
% larger than the half-way
[value,idx]=max(find(gA(itpk2:itpk3)<gA(itpk2)+(gA(itpk3)-gA(itpk2))/2));
itpk2_e = itpk2+idx-1;
tpk2_e = time(itpk2_e);%    0.3750 

itimeA=itpk2_b:itpk2_e;
timeA=[tpk2_b tpk2_e]
%       -0.2490    0.3750

% fallback if half-amplitude window is empty (e.g. flat data)
if isempty(timeA)
    warning('Follower: half-amplitude window empty. Using default [-0.5, 1.0]s');
    tpk2_b = -0.5; tpk2_e = 1.0;
    itpk2_b = max(find(time<=tpk2_b));
    itpk2_e = max(find(time<=tpk2_e));
    itimeA = itpk2_b:itpk2_e;
    timeA = [tpk2_b tpk2_e];
end

% store
itimeA_follower = itimeA;
timeA_follower = timeA;

%%
close all

%% write out data for R or SPSS in a tab-delimitered text file

% change this date to today's date
date_str = '20260208';

% Variables for quick ANOVA inside MATLAB
Xe1 = zeros(nsubj, ncond, nelec); % Alpha

filename = sprintf('AlphaERD_DuetEx_%s.txt',date_str);
fid = fopen(filename,'w');

% first line
fprintf(fid,'Subj\tRole\tMelody\tPartner\tElec\tAlphaERD\n');
for isubj=1:nsubj
    for icond=1:ncond
        for ielec=1:nelec
            curr_subj = subj{isubj};
            curr_cond = cond{icond};
            curr_elec = elec_list{ielec};
            
            % role
            if ismember(icond,[1,2,5,6])
                itw = itimeA_leader;
                curr_role = 'leader';
            else
                itw = itimeA_follower;
                curr_role = 'follower';
            end
            
            % melody
            if ismember(icond,[1,3,5,7])
                curr_mel='same';
            else
                curr_mel = 'diff';
            end

            % partner
            if ismember(icond,[1,2,3,4])
                curr_partner = 'human';
            else
                curr_partner ='comp';
            end

            curr_dat_alpha = mean(tmpa.dat_elec_nf(isubj,icond,ielec,itw),4);
            Xe1(isubj, icond,ielec) = curr_dat_alpha;
            
            fprintf(fid,'%s\t%s\t%s\t%s\t%s\t%3.3f\n',curr_subj, curr_role, curr_mel, curr_partner, curr_elec, curr_dat_alpha);
        end
    end
end
fclose(fid)
% You should check the text file

%% do anova in R (or SPSS) using the file you made above


%% prepare data for anova here in MATLAB 
% Alpha  use Xe1

% leader or follower
X1 = Xe1(:, cond_leader,:);
X2 = Xe1(:, cond_follower,:);

% prepare indices
mel_index = [];
part_index = [];
elec_index = [];
subj_index = [];
score_alpha_leader = [];
score_alpha_follower = [];

icond=1;
for ipart=1:2
    for imel = 1:2
        for ielec = 1:nelec
            for isubj = 1:nsubj
                mel_index = [mel_index;imel];
                part_index = [part_index;ipart];
                elec_index = [elec_index;ielec];
                subj_index = [subj_index;isubj];
                score_alpha_leader = [score_alpha_leader; X1(isubj,icond,ielec)];   
                score_alpha_follower = [score_alpha_follower; X2(isubj,icond,ielec)];  
            end % subj
        end % elec
        icond=icond+1;
    end
end

% prepare data matrix for aov  
% IV1 is mel, IV2 is partner, IV3 is elec
X_leader = [score_alpha_leader, mel_index, part_index, elec_index, subj_index];
X_follower = [score_alpha_follower, mel_index, part_index, elec_index, subj_index];

%% run ANOVA
% Alpha leader
X=X_leader;
%display(twindow)
display(sprintf('Leader: time %3.3f - %3.3f', timeA_leader(1), timeA_leader(2)));
display('IV1:Melody, IV2:Partner, IV3:Elec')
% have to have this function
% download rmaov1, rmaov2, rmaov31, rmaov32, rmaov33.m from
% /user/t/takako/MATLAB
rmaov33(X,0.05)


% Alpha follower
X=X_follower;
%display(twindow)
display(sprintf('Follower: time %3.3f - %3.3f', timeA_follower(1), timeA_follower(2)));
display('IV1:Melody, IV2:Partner, IV3:Elec')
rmaov33(X,0.05)

%% inspect ANOVA results
% Leader: time -0.961 - 0.943
% IV1:Melody, IV2:Partner, IV3:Elec
%    
% The number of IV1 levels are: 2
% The number of IV2 levels are: 2
% The number of IV3 levels are: 4
% The number of subjects are:    4
% 
% Three-Way Analysis of Variance With Repeated Measures on Three Factors (Within-Subjects) Table.
% ---------------------------------------------------------------------------------------------------
% SOV                             SS          df           MS             F        P      Conclusion
% ---------------------------------------------------------------------------------------------------
% Between-Subjects            5058.741         3
% 
% Within-Subjects             9546.167        60
% IV1                            0.000         1          0.000         0.000   0.9992       NS
% Error(IV1)                   973.957         3        324.652
% 
% IV2                          283.843         1        283.843         0.341   0.6001       NS
% Error(IV2)                  2494.375         3        831.458
% 
% IV3                           82.766         3         27.589         0.416   0.7461       NS
% Error(IV3)                   597.573         9         66.397
% 
% IV1xIV2                       44.379         1         44.379         0.067   0.8120       NS
% Error(IV1xIV2)              1976.170         3        658.723
% 
% IV1xIV3                        9.190         3          3.063         0.026   0.9941       NS
% Error(IV1xIV3)              1080.484         9        120.054
% 
% IV2xIV3                      478.366         3        159.455         2.166   0.1619       NS
% Error(IV2-IV3)               662.678         9         73.631
% 
% IV1xIV2xIV3                   48.074         3         16.025         0.179   0.9079       NS
% Error(IV1-IV2-IV3)           805.122         9         89.458
% ---------------------------------------------------------------------------------------------------
% Total                      14595.718        63
% ---------------------------------------------------------------------------------------------------
% With a given significance level of: 0.05
% The results are significant (S) or not significant (NS).
% 
% 
% Follower: time -0.249 - 0.375
% IV1:Melody, IV2:Partner, IV3:Elec
%    
% The number of IV1 levels are: 2
% The number of IV2 levels are: 2
% The number of IV3 levels are: 4
% The number of subjects are:    4
% 
% Three-Way Analysis of Variance With Repeated Measures on Three Factors (Within-Subjects) Table.
% ---------------------------------------------------------------------------------------------------
% SOV                             SS          df           MS             F        P      Conclusion
% ---------------------------------------------------------------------------------------------------
% Between-Subjects              62.755         3
% 
% Within-Subjects             2011.366        60
% IV1                           13.953         1         13.953         0.221   0.6704       NS
% Error(IV1)                   189.421         3         63.140
% 
% IV2                           28.958         1         28.958         0.634   0.4841       NS
% Error(IV2)                   137.019         3         45.673
% 
% IV3                           26.715         3          8.905         0.471   0.7101       NS
% Error(IV3)                   170.275         9         18.919
% 
% IV1xIV2                       26.093         1         26.093         0.237   0.6596       NS
% Error(IV1xIV2)               329.924         3        109.975
% 
% IV1xIV3                       86.728         3         28.909         0.558   0.6558       NS
% Error(IV1xIV3)               466.164         9         51.796
% 
% IV2xIV3                       17.314         3          5.771         0.185   0.9040       NS
% Error(IV2-IV3)               280.954         9         31.217
% 
% IV1xIV2xIV3                   43.100         3         14.367         1.197   0.3650       NS
% Error(IV1-IV2-IV3)           108.022         9         12.002
% ---------------------------------------------------------------------------------------------------
% Total                       1987.393        63
% ---------------------------------------------------------------------------------------------------
% With a given significance level of: 0.05
% The results are significant (S) or not significant (NS).
%% now generate topoplots for the points of interest 
partner = {'human';'comp'};
melody = {'same';'diff'};

% Alpha (human/comp) x (same/diff)

% Leader
% (total 4 topo)
role='leader';
itw = itimeA_leader;
dat_all_leader = ae.dat_all_nf(ssubj,cond_leader,1:64,:);
icond=1;
for ipartner=1:2
    for imelody=1:2
        % adjust according to how saturated the color is, but use the same color bar for one target ERP component
        Alpha_minmax = [-40 40];
        xdat= squeeze(mean(mean(dat_all_leader(ssubj,icond,1:64,itw),1),4));
        figure;
        rri_topoplot(xdat,{'maplimits',Alpha_minmax}) % [min max] in micro volt (because the data are already in micro volt)
        % color bar title
        hcb=colorbar('eastoutside'); % color bar location
        hcb.Title.String='%'; % this will appear on top of the color bar
        % the figure title (also filename)
        t = sprintf('%s-%s-%s-%s','Alpha',role, partner{ipartner},melody{imelody});
        title(t);
        print(t,'-dpdf') % you can do png too

    end
end

% Follower
% (total 4 topo)
role='follower';
itw = itimeA_follower;
dat_all_follower = ae.dat_all_nf(ssubj,cond_follower,1:64,:);
icond=1;
for ipartner=1:2
    for imelody=1:2
        % adjust according to how saturated the color is, but use the same color bar for one target ERP component
        Alpha_minmax = [-40 40];
        xdat= squeeze(mean(mean(dat_all_follower(ssubj,icond,1:64,itw),1),4));
        figure;
        rri_topoplot(xdat,{'maplimits',Alpha_minmax}) % [min max] in micro volt (because the data are already in micro volt)
        % color bar title
        hcb=colorbar('eastoutside'); % color bar location
        hcb.Title.String='%'; % this will appear on top of the color bar
        % the figure title (also filename)
        t = sprintf('%s-%s-%s-%s','Alpha',role, partner{ipartner},melody{imelody});
        title(t);
        print(t,'-dpdf') % you can do png too

    end
end
%%
close all

%% save workspace
outdir = '/Volumes/MLF/EEG-Hyperscanning/output';
save(sprintf('%s/Workspace_AlphaERD_DuetEx_%s.mat', outdir, date_str), ...
    'ae', 'tmpa', 'time', 'ntime', 'nchan', 'nfreq', 'subj', 'nsubj', ...
    'cond', 'ncond', 'Freqs', 'alpha_bins', 'ssubj', 'nssubj', ...
    'elec_list', 'nelec', 'fc', 'cpl', 'cpr', 'po', 's', ...
    'h_elec', 'p_elec', 'contrast', 'contrast_list', 'ncontrast', ...
    'cond_leader', 'cond_follower', 'dtype', 'ndtype', ...
    'itimeA_leader', 'timeA_leader', 'itimeA_follower', 'timeA_follower', ...
    'Xe1', 'X_leader', 'X_follower', 'date_str', 'short_subj_list');
