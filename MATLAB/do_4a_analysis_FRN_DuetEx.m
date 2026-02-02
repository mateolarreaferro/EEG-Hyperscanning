% do_analysis_FRN.m
% adapted from Madeline's version 'do_analysis.m' in '~/Research/Motif_Piano_Duet/analysis_code'

% Now filter, baseline, average, combine-two-voices, and t-test
% analyzing Pilot1 data 2022 03 05

% 2024 03 10 DuetDistance pair 1 
% 2026 01 27 DuetEx(Duet2017 FRN data)

mydirectory = 'C:\\Users\\tfujioka\\Documents\\MATLAB\\451C_W26_practice';

load(sprintf('%s/FRN_DuetEx_20260127.mat',mydirectory));

dat_all_org=dat_all;
nchan=size(dat_all,3);
ntime=size(dat_all,4);

% this is already inside the workspace
% stim_list = {
%     'StdSelfSameHuman';
%     'DevSelfSameHuman';
%     'StdOtherSameHuman';
%     'DevOtherSameHuman';
%     'StdSelfDiffHuman';
%     'DevSelfDiffHuman';
%     'StdOtherDiffHuman';
%     'DevOtherDiffHuman';
%     'StdSelfSameComp';
%     'DevSelfSameComp';
%     'StdOtherSameComp';
%     'DevOtherSameComp';
%     'StdSelfDiffComp';
%     'DevSelfDiffComp';
%     'StdOtherDiffComp';
%     'DevOtherDiffComp'};
% 
% nstim=size(stim_list, 1);

cond_list ={
    'SelfSameHuman';
    'OtherSameHuman';
    'SelfDiffHuman';
    'OtherDiffHuman';
    'SelfSameComp';
    'OtherSameComp';
    'SelfDiffComp';
    'OtherDiffComp';
    };
    
ncond = size(cond_list,1);

%% check the data
for istim=1:nstim
    figure;
    plot(time, squeeze(mean(dat_all_org(:,istim,1:64,:))));
    title(sprintf('Stim-%s',stim_name{istim}));
end
%%
close all

%% extend dat_all to have stndard both self and other so that we can make pair of standard and deviant

% make the data into micro-Volt
dat_all_scaled = 1.0e+6 *dat_all_org;

%% reorganize dat-all further

partner = {'Human';'Comp'};npartner = 2;
melody = {'Same';'Diff'};nmelody=2;
agency = {'Self';'Other'};nagency =2;
type = {'Std';'Dev'};ntype=2;

dat_all_ext2 = zeros(nsubj, npartner,nmelody,nagency,ntype,nchan,ntime); 
for isubj=1:nsubj
    istim=1; % initialize for this subject for the next 16 files
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype = 1:ntype
                    dat_all_ext2(isubj, ipartner, imelody, iagency, itype,:,:) = reshape(dat_all_scaled(isubj,istim,:,:), 1,1,1,1,1,1,nchan,ntime);
                    istim=istim+1; % increment istim
                end
            end
        end
    end
end

dat_all = dat_all_ext2;

%% check the data (do you see FRN as a difference between standard and deviant lines?)
for isubj=1:nsubj
    figure;
    plot(time, squeeze(dat_all_ext2(isubj,1,1,1,1,28,:))); % 28 is Cz
    hold on;
    plot(time, squeeze(dat_all_ext2(isubj,1,1,1,2,28,:)));
    title(sprintf('Subj-%s',subjname_all{isubj}));
end
%% 
close all

%% filtering and setting up baseline on complete data

fs=500;
%f1=0.1/fs/2; % HP 0.1 Hz
f2=25/fs/2;  % LP 25 Hz
f22=40/fs/2; % alt LP 40 Hz

[hb,ha]=butter(4, f2, 'low'); % using no hp
[hb2,ha2]=butter(4, f22, 'low'); % using lowpass (hereby all variables ending with '2' is using higher lowpass)

dat_all_f=zeros(size(dat_all));
dat_all_f2=zeros(size(dat_all));
for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype = 1:ntype
                    for ichan=1:nchan
                        tmp=squeeze(dat_all(isubj, ipartner, imelody, iagency, itype,ichan,:));
                        % lowpass-25
                        tmp_f=filtfilt(hb,ha,tmp);
                        dat_all_f(isubj,ipartner, imelody, iagency, itype,ichan,:)=tmp_f;

                        % lowpass-40
                        tmp_f2=filtfilt(hb2,ha2,tmp);
                        dat_all_f2(isubj,ipartner, imelody, iagency, itype,ichan,:)=tmp_f2;
                    end
                end
            end
        end
    end
end

%
%% baseline time window - 100ms for all
t01=0.0-0.1; %[s]
t02=0.0-0.0;   %[s]
it01=max(find(time<=t01));
it02=max(find(time<=t02));

dat_all_nf=zeros(size(dat_all));

for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype = 1:ntype
                    for ichan=1:nchan
                        ndimtime=size(size(dat_all_nf),2);
                        tmp1=mean(dat_all(isubj,ipartner, imelody, iagency, itype,ichan,it01:it02),ndimtime);
                        tmp=mean(dat_all_f(isubj,ipartner, imelody, iagency, itype,ichan,it01:it02),ndimtime);
                        tmp2=mean(dat_all_f2(isubj,ipartner, imelody, iagency, itype,ichan,it01:it02),ndimtime);
                        for itime=1:ntime
                            dat_all_nf(isubj,ipartner, imelody, iagency, itype,ichan,itime)=dat_all(isubj,ipartner, imelody, iagency, itype,ichan,itime)-tmp1;
                            dat_all_f(isubj,ipartner, imelody, iagency, itype,ichan,itime)=dat_all_f(isubj,ipartner, imelody, iagency, itype,ichan,itime)-tmp;
                            dat_all_f2(isubj,ipartner, imelody, iagency, itype,ichan,itime)=dat_all_f2(isubj,ipartner, imelody, iagency, itype,ichan,itime)-tmp2;
                        end
                    end
                end
            end
        end
    end
end


%% make difference waveforms (type is gone because we will make Dev - Std)
diff_all_nf=zeros(nsubj,npartner, nmelody, nagency, nchan,ntime);
diff_all_f=zeros(nsubj,npartner, nmelody, nagency, nchan,ntime);
diff_all_f2=zeros(nsubj,npartner, nmelody, nagency, nchan,ntime);

for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency

                for ichan=1:nchan

                    % make dev - std
                    diff_all_nf(isubj,ipartner, imelody, iagency,ichan,:)= dat_all_nf(isubj,ipartner, imelody, iagency,2,ichan,:)-dat_all_nf(isubj,ipartner, imelody, iagency,1,ichan,:);
                    diff_all_f(isubj,ipartner, imelody, iagency,ichan,:)= dat_all_f(isubj,ipartner, imelody, iagency,2,ichan,:)-dat_all_f(isubj,ipartner, imelody, iagency,1,ichan,:);
                    diff_all_f2(isubj,ipartner, imelody, iagency,ichan,:)= dat_all_f2(isubj,ipartner, imelody, iagency,2,ichan,:)-dat_all_f2(isubj,ipartner, imelody, iagency,1,ichan,:);

                end
            end
        end
    end
end

%% check the data (check filtering, and making difference waveform)
for isubj=1:nsubj
    figure;
    plot(time, squeeze(dat_all_nf(isubj,1,1,1,1,28,:)));
    hold on;
    plot(time, squeeze(dat_all_f2(isubj,1,1,1,1,28,:)));
    plot(time, squeeze(dat_all_f2(isubj,1,1,1,2,28,:)));
    plot(time,  squeeze(diff_all_f2(isubj,1,1,1,28,:)));
    
    title(sprintf('Subj-%s',subjname_all{isubj}));
end
%% 
close all

%% make electrode groups 

% % fronto-central
% fcl=[6,7,8,15,16,17,24,25,26]; % F7, F5, F3, FT7, FC5, FC3, T7, C5, C3
% fcm=[9,10,11,18,19,20,27,28,29]; %F1, Fz, F2, FC1, FCz, FC2, C1, Cz, C2
% fcr=[12,13,14,21,22,23,30,31,32]; % F4, F6, F8, FC4, FC6, FT8, C4, C6, T8
% % parietal 
% pl = [34,35,36,44,45,46,53,54]; % TP7, CP5, CP3, P7, P5, P3, PO7, PO5
% pm = [37,38,39,47,48,49,55,56,57]; %61,62,63]; %CP1, CPz, CP2, P1, Pz, P2, PO3, POz, PO4, % optional O1, Oz, O2
% pr = [40,41,42,50,51,52,58,59]; % CP4, CP6, TP8, P4, P6, P8, PO6, PO8
% elec_list = {'fcl';'fcm';'fcr';'pl';'pm';'pr'};
% nelec = length(elec_list);

fc6=[9,10,11,18,19,20];
pzp2p4=[48,49,50];
elec_list = {'fc6';'pzp2p4'};
nelec = length(elec_list);

dat_elec_nf = zeros(nsubj, npartner, nmelody, nagency, ntype,nelec,ntime);
dat_elec_f = zeros(nsubj, npartner, nmelody, nagency, ntype,nelec,ntime);
dat_elec_f2 = zeros(nsubj, npartner, nmelody, nagency, ntype,nelec,ntime);

diff_elec_nf=zeros(nsubj,npartner, nmelody, nagency, nelec,ntime);
diff_elec_f=zeros(nsubj,npartner, nmelody, nagency, nelec,ntime);
diff_elec_f2=zeros(nsubj,npartner, nmelody, nagency, nelec,ntime);

% making mean value of each electrode group
for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype=1:ntype
                    for ielec=1:nelec
                        ndimchan=size(size(dat_all_nf),2)-1; % the channel is the 2nd last dimension
                        tmp_elec=eval(char(elec_list(ielec))); % e.g. tmp_elec = fcr (evaluated as number list)
                        dat_elec_nf(isubj,ipartner, imelody, iagency,itype,ielec,:)=mean(dat_all_nf(isubj,ipartner, imelody, iagency,itype,tmp_elec,:),ndimchan);
                        dat_elec_f(isubj,ipartner, imelody, iagency,itype,ielec,:)=mean(dat_all_f(isubj,ipartner, imelody, iagency,itype,tmp_elec,:),ndimchan);
                        dat_elec_f2(isubj,ipartner, imelody, iagency,itype,ielec,:)=mean(dat_all_f2(isubj,ipartner, imelody, iagency,itype,tmp_elec,:),ndimchan);
                    end
                end
            end
        end
    end
end

% diff 
% making mean value of each electrode group
for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for ielec=1:nelec
                    ndimchan=size(size(diff_elec_nf),2)-1; % the channel is the 2nd last dimension
                    tmp_elec=eval(char(elec_list(ielec))); % e.g. tmp_elec = fcr (evaluated as number list)
                    diff_elec_nf(isubj,ipartner, imelody,iagency,ielec,:)=mean(diff_all_nf(isubj,ipartner, imelody, iagency,tmp_elec,:),ndimchan);
                    diff_elec_f(isubj,ipartner,imelody,iagency,ielec,:)=mean(diff_all_f(isubj,ipartner, imelody, iagency,tmp_elec,:),ndimchan);
                    diff_elec_f2(isubj,ipartner,imelody,iagency,ielec,:)=mean(diff_all_f2(isubj,ipartner, imelody, iagency,tmp_elec,:),ndimchan);
                end
            end
        end
    end
end
             
                    
%% once again, do the baseline now in the electrode group data
for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype=1:ntype
                    ndimtime=size(size(dat_elec_nf),2);

                    tmp=mean(dat_elec_nf(isubj,ipartner, imelody, iagency,itype,ielec,it01:it02),ndimtime);
                    tmp1=mean(dat_elec_f(isubj,ipartner, imelody, iagency,itype,ielec,it01:it02),ndimtime);
                    tmp2=mean(dat_elec_f2(isubj,ipartner, imelody, iagency,itype,ielec,it01:it02),ndimtime);

                    tmp_vector =  tmp*ones(1,1,1,1,1,1,ntime);
                    tmp1_vector = tmp1*ones(1,1,1,1,1,1,ntime);
                    tmp2_vector = tmp2*ones(1,1,1,1,1,1,ntime);

                    dat_elec_nf(isubj,ipartner, imelody, iagency,itype,ielec,:)=dat_elec_nf(isubj,ipartner, imelody, iagency,itype,ielec,:)-tmp_vector;
                    dat_elec_f(isubj,ipartner, imelody, iagency,itype,ielec,:)=dat_elec_f(isubj,ipartner, imelody, iagency,itype,ielec,:)-tmp1_vector;
                    dat_elec_f2(isubj,ipartner, imelody, iagency,itype,ielec,:)=dat_elec_f2(isubj,ipartner, imelody, iagency,itype,ielec,:)-tmp2_vector;
                end
                % now doing diff
                tmp=mean(diff_elec_nf(isubj,ipartner, imelody, iagency,ielec,it01:it02),ndimtime-1);
                tmp1=mean(diff_elec_f(isubj,ipartner, imelody, iagency,ielec,it01:it02),ndimtime-1);
                tmp2=mean(diff_elec_f2(isubj,ipartner, imelody, iagency,ielec,it01:it02),ndimtime-1);

                tmp_vector =  tmp*ones(1,1,1,1,1,ntime);
                tmp1_vector = tmp1*ones(1,1,1,1,1,ntime);
                tmp2_vector = tmp2*ones(1,1,1,1,1,ntime);

                diff_elec_nf(isubj,ipartner, imelody, iagency,ielec,:)=diff_elec_nf(isubj,ipartner, imelody, iagency,ielec,:)-tmp_vector;
                diff_elec_f(isubj,ipartner, imelody, iagency,ielec,:)=diff_elec_f(isubj,ipartner, imelody, iagency,ielec,:)-tmp1_vector;
                diff_elec_f2(isubj,ipartner, imelody, iagency,ielec,:)=diff_elec_f2(isubj,ipartner, imelody, iagency,ielec,:)-tmp2_vector;

            end
        end
    end
end


%% check the data (see std,dev,diff waveforms)
for isubj=1:nsubj
    figure;
    for ielec=1:nelec
        subplot(1,2,ielec)
        hold on
        plot(time, squeeze(dat_elec_f2(isubj,1,1,1,1,ielec,:)));
        plot(time, squeeze(dat_elec_f2(isubj,1,1,1,2,ielec,:)));
        plot(time,  squeeze(diff_elec_f2(isubj,1,1,1,ielec,:)));
    
        title(sprintf('Subj-%s-%s',subjname_all{isubj},elec_list{ielec}));
    end
end
%% 
close all

%% make grand average and SE

% selected subjects (who is noisy/no FRN and hopeless?)
ssubj=1:nsubj; % everyone OR ssubj=[1:10, 12:18] etc.

% the 1st dimension goes into mean
dat_elec_f2_GA=squeeze(mean(dat_elec_f2(ssubj,:,:,:,:,:,:),1));
dat_elec_f2_SE=squeeze(std(dat_elec_f2(ssubj,:,:,:,:,:,:),1))/sqrt(length(ssubj)); % standard error of mean (SEM)
dat_elec_f2_USE=dat_elec_f2_GA+dat_elec_f2_SE; % upper
dat_elec_f2_LSE=dat_elec_f2_GA-dat_elec_f2_SE; % lower

diff_elec_f2_GA=squeeze(mean(diff_elec_f2(ssubj,:,:,:,:,:),1));
diff_elec_f2_SE=squeeze(std(diff_elec_f2(ssubj,:,:,:,:,:),1))/sqrt(length(ssubj));
diff_elec_f2_USE=diff_elec_f2_GA+diff_elec_f2_SE;
diff_elec_f2_LSE=diff_elec_f2_GA-diff_elec_f2_SE;

%% check the data (check gavg should be in the middle of upper SE and lower SE)
imelody=1;
iagency=1;

for ipartner=1:npartner
    figure;
    for ielec=1:nelec
        subplot(1,2,ielec);
        plot(time, squeeze(diff_elec_f2_GA(ipartner, imelody, iagency,ielec,:)),'LineWidth',3);
        hold on;
        plot(time, [squeeze(diff_elec_f2_USE(ipartner, imelody, iagency,ielec,:)),squeeze(diff_elec_f2_LSE(ipartner, imelody, iagency,ielec,:))],'LineWidth',1);
    
        title(sprintf('Partner-%s-%s',partner{ipartner}, elec_list{ielec}));
    end
end
%% 
close all

%% t-test for each time point


h_all=zeros(npartner, nmelody, nagency, nelec,ntime);
p_all=zeros(npartner, nmelody, nagency, nelec,ntime);

%only storing values after 90 msec
[r,c]=min(find(time>0.09));
cutoff=r;

st=struct;
for ipartner = 1:npartner
    for imelody=1:nmelody
        for iagency=1:nagency
            for ielec=1:nelec
                dat1=squeeze(dat_elec_f2(ssubj,ipartner, imelody, iagency,1,ielec,:));% Standard
                dat2=squeeze(dat_elec_f2(ssubj,ipartner, imelody, iagency,2,ielec,:));% Deviant
                for itime=cutoff:ntime
                    [h, p]=ttest(dat1(:,itime),dat2(:,itime)); % paired t-test

                    h_all(ipartner, imelody, iagency, ielec,itime)=h;
                    p_all(ipartner, imelody, iagency, ielec,itime)=p;
                    if h
                        display(sprintf('%d\t%d\t%d\t%d\n',ipartner, imelody, iagency,ielec));
                    end
                end
            end
        end
    end
end

st.SvD_h_all = h_all;
st.SvD_p_all = p_all;

%% check the data (h_all)
for ielec=1:2 % ielec=1 -> FRN and P3a, ielec=2 -> P3b   
    figure;
    isubplot=1;
    for ipartner=1:2
        for imelody=1:2
            subplot(2,2,isubplot)
            plot(time, squeeze(h_all(ipartner, imelody, 1, ielec,:)));
            hold on;
            plot(time, squeeze(h_all(ipartner, imelody, 2, ielec,:)));
            legend('Self','Other');
            title(sprintf('%s:%s:%s',elec_list{ielec},partner{ipartner},melody{imelody}));
            isubplot=isubplot + 1;
        end
    end
end

%%
close all
%% plotting Standard and Deviant with ttest dots

ielec=1;
figure;
isubplot=1;

k=-3.5; % adjust the location of the dots if necessary
for ipartner=1:2
    for imelody=1:2
        for iagency=1:2

            subplot(2,4,isubplot);
            elec_char=elec_list{ielec}; % name of current region we're plotting
            partner_char=partner{ipartner};
            melody_char=melody{imelody};
            agency_char=agency{iagency};

            % plotting these data in one figure
            dat_erp = squeeze(dat_elec_f2_GA(ipartner, imelody, iagency,1:2,ielec,:));
            dat_diff = squeeze(diff_elec_f2_GA(ipartner, imelody, iagency,ielec,:));

            h_dat = squeeze(st.SvD_h_all(ipartner, imelody, iagency,ielec,:));

            % plot lines
            plot(time, dat_erp);
            hold on;grid on;
            plot(time, dat_diff,'--');

            % only significant dot appears
            plot(-0.2,1,'ro'); % dummy
            indx=find(h_dat(it02+1:ntime)); % after time zero
            plot(time(indx+it02), k*h_dat(indx+it02),'ro');

            % axis range
            axis([-0.1 0.5 -6 6]) % adjust if needed

            % title and legend
            title(sprintf('%s-%s-%s-%s', partner_char, melody_char, agency_char, elec_char));
            xlabel('Time (S)'); ylabel('Voltage (micro-V)');
            if isubplot==8
                legend('Std','Dev','Diff','SvsD');
            end
            % increment the subplot position
            isubplot=isubplot + 1;
        end
    end
end

% write the figure into a file
print(sprintf('fig_ERP_diff_%s', elec_char), '-dpng')
%% 
close all



%% t-test: comparing diff between partners per melody and agency 
% I don't compare now the agency because always self should be larger than
% other

h_all=zeros(nmelody,nagency,nelec,ntime);
p_all=zeros(nmelody,nagency,nelec,ntime);

%only storing values after 90 msec
[r,c]=min(find(time>0.09));
cutoff=r;
for imelody=1:nmelody
    for iagency=1:nagency
        for ielec=1:nelec
            dat1=squeeze(diff_elec_f(ssubj,1, imelody,iagency,ielec,:));
            dat2=squeeze(diff_elec_f(ssubj,2, imelody, iagency,ielec,:));

            for itime=cutoff:ntime

                [h, p]=ttest(dat1(:,itime),dat2(:,itime)); % paired t-test
                h_all(imelody,iagency, ielec,itime)=h;
                p_all(imelody, iagency,ielec,itime)=p;
                if h
                    display(sprintf('%d\t%d\t%d\n',imelody,iagency,ielec));
                end
            end
        end
    end
end

st.HMvCP_h_all = h_all;
st.HMvCP_p_all = p_all;

%% plotting Human vs. Computer with ttest dots
ielec=1;
k=-3.5; % adjust the location of the dots if necessary
figure;
isubplot=1;
for imelody=1:2
    for iagency=1:2

        subplot(2,2,isubplot);

        elec_char=elec_list{ielec}; % name of current region we're plotting

        melody_char=melody{imelody};
        agency_char=agency{iagency};
        % plotting these data in one figure
        dat_diff1 = squeeze(diff_elec_f2_GA(1,imelody,iagency,ielec,:));
        dat_diff2 = squeeze(diff_elec_f2_GA(2,imelody,iagency,ielec,:));
        h_dat = squeeze(st.HMvCP_h_all(imelody,iagency,ielec,:));

        % plot lines
        plot(time, dat_diff1);
        hold on;grid on;
        plot(time, dat_diff2)

        % only significant dot appears
        plot(-0.2,1,'ro'); % dummy
        indx=find(h_dat(it02+1:ntime)); % after time zero
        plot(time(indx+it02), k*h_dat(indx+it02),'ro');

        % axis range
        axis([-0.1 0.5 -6 6]) % adjust if needed

        % title and legend
        title(sprintf('%s-%s-%s', melody_char, agency_char, elec_char));
        xlabel('Time (S)'); ylabel('Voltage (micro-V)');
        
        if isubplot==4
            legend('HM','CP','HMvsCP');
        end
        isubplot=isubplot+1;
    end
end
%% 
close all

%% t-test: comparing diff between melody per partner and agency 
% I don't compare now the agency because always self should be larger than
% other

h_all=zeros(npartner,nagency,nelec,ntime);
p_all=zeros(npartner,nagency,nelec,ntime);

%only storing values after 90 msec
[r,c]=min(find(time>0.09));
cutoff=r;
for ipartner = 1:npartner
    for iagency=1:nagency
        for ielec=1:nelec
            dat1=squeeze(diff_elec_f(ssubj,ipartner,1, iagency,ielec,:));
            dat2=squeeze(diff_elec_f(ssubj,ipartner,2, iagency,ielec,:));

            for itime=cutoff:ntime

                [h, p]=ttest(dat1(:,itime),dat2(:,itime)); % paired t-test
                h_all(ipartner,iagency, ielec,itime)=h;
                p_all(ipartner, iagency,ielec,itime)=p;
                if h
                    display(sprintf('%d\t%d\t%d\n',ipartner,iagency,ielec));
                end
            end
        end
    end
end

st.SMvDF_h_all = h_all;
st.SMvDF_p_all = p_all;

%% plotting Same vs. Diff with ttest dots
ielec=1;
k=-3.5; % adjust the location of the dots if necessary
figure;
isubplot=1;
for ipartner=1:2
    for iagency=1:2

        subplot(2,2,isubplot);

        elec_char=elec_list{ielec}; % name of current region we're plotting

        partner_char=partner{ipartner};
        agency_char=agency{iagency};
        % plotting these data in one figure
        dat_diff1 = squeeze(diff_elec_f2_GA(ipartner,1,iagency,ielec,:));
        dat_diff2 = squeeze(diff_elec_f2_GA(ipartner,2,iagency,ielec,:));
        h_dat = squeeze(st.SMvDF_h_all(ipartner,iagency,ielec,:));

        % plot lines
        plot(time, dat_diff1);
        hold on;grid on;
        plot(time, dat_diff2)

        % only significant dot appears
        plot(-0.2,1,'ro'); % dummy
        indx=find(h_dat(it02+1:ntime)); % after time zero
        plot(time(indx+it02), k*h_dat(indx+it02),'ro');

        % axis range
        axis([-0.1 0.5 -6 6]) % adjust if needed

        % title and legend
        title(sprintf('%s-%s-%s', partner_char, agency_char, elec_char));
        xlabel('Time (S)'); ylabel('Voltage (micro-V)');
        
        if isubplot==4
            legend('SM','DF','SMvsDF');
        end
        isubplot=isubplot+1;
    end
end

%% 
close all

%% determine the peak latency area for amplitude calculation

% use only ielec=1 

ielec=1;
gdiff = squeeze(mean(mean(mean(diff_elec_f2_GA(:,:,:,ielec,:),1),2),3));

figure;
% time axis
plot(time, gdiff)
% sample axis
figure;
plot(1:length(time), gdiff)


% most negative peak (FRN)
[value,idx]=min(gdiff);
%idx=348
itpkFRN=idx;
tpkFRN=time(idx);
% 0.1730(s)

% try find a positive peak before FRN
it03=max(find(time<=0.05)); % watch the width
% maxima before
[r,c]=max(gdiff(it03:itpkFRN,1)) 
% should not be empty -if so adjust the it03

% see how to set up it03 search window to see only one positive peak
t_beforeFRN=time(it03+c-1); % 0.0970
it_beforeFRN = it03+c-1; % 310


% most positive peak (P3a)
[value,idx]=max(gdiff);
% idx = 390
itpkP3a=idx;
tpkP3a=time(idx);
% 0.2570 (s)

% try find a negative peak after P3a
it04=max(find(time<=0.34)); % watch the width
% maxima before
[r,c]=min(gdiff(itpkP3a:it04,1)) 
% should not be empty -if so adjust the it03

% see how to set up it03 search window to see only one positive peak
t_afterP3a=time(it04+c-1); % 0.4130
it_afterP3a = it04+c-1; % 468

% peak to peak amp to the FRN negative peak
pk2pk_amp1_before = gdiff(it_beforeFRN) - gdiff(itpkFRN);
pk2pk_amp1_after =  gdiff(itpkP3a) - gdiff(itpkFRN);
% this is half way amplitude 
amp1_before_half = 0.5*pk2pk_amp1_before+gdiff(itpkFRN);
amp1_after_half = 0.5*pk2pk_amp1_after+gdiff(itpkFRN);

[r, c]= max(find(gdiff(it_beforeFRN:itpkFRN)>=amp1_before_half)); % decreasing, so find the max of larger side
it_beforeFRN_half = it_beforeFRN+c-1;
[r, c]= max(find(gdiff(itpkFRN:itpkP3a)<=amp1_after_half)); % increasing, so find the max of smaller side
it_afterFRN_half = itpkFRN+c-1;

% half-way amp window for FRN (vector of time index numbers0
itw_FRN=it_beforeFRN_half:it_afterFRN_half; 
% display time window
[time(itw_FRN(1)),time(itw_FRN(end))] %  0.1390    0.2130


% P3 window
it_beforeP3a_half = it_afterFRN_half;
% peak to peak amp to the P3 positive peak
pk2pk_amp1_afterP3a =  (-1.0)*(gdiff(it_afterP3a) - gdiff(itpkP3a));
% this is half way amplitude or quarter
amp1_afterP3a_half =  -(0.5*pk2pk_amp1_afterP3a)+gdiff(itpkP3a);

[r, c]= max(find(gdiff(itpkP3a:it_afterP3a)>=amp1_afterP3a_half)); % decreasing, so find the max of larger side
it_afterP3a_half = itpkP3a+c-1;

itw_P3a=it_beforeP3a_half:it_afterP3a_half;
% display time window
[time(itw_P3a(1)),time(itw_P3a(end))] %   0.2130    0.2790


%% making amplitude values for time windows of interest, and write out for R
mydate='20260127';
filename = sprintf('FRN_P3a_amp_%s.txt',mydate);
fid = fopen(filename,'w');
fprintf(fid, 'subjID\t partner\t melody\t agency\t elec\t FRN\t P3a\n');
ielec=1;
for isubj=1:nsubj
    for ipartner=1:npartner
        for imelody=1:nmelody
            for iagency = 1:nagency
                fprintf(fid, '%s\t %s\t %s\t %s\t %s\t ', subjname_all{isubj}, partner{ipartner}, melody{imelody},agency{iagency}, elec_list{ielec});
                fprintf(fid, '%3.3f\t',squeeze(mean(diff_elec_f2(isubj, ipartner, imelody, iagency, ielec, itw_FRN),6)));
                fprintf(fid, '%3.3f\n',squeeze(mean(diff_elec_f2(isubj, ipartner, imelody, iagency, ielec, itw_P3a),6)));
            end
        end
    end
end
fclose(fid);
%% save workspace

savefilename = sprintf('Workspace_FRN_DuetEx_%s',mydate);
save(savefilename)

%% go to R

% see R script 'anova_FRN_20220308.r' for FRN and P3a anova and post-hoc
% comparisons, also making bargraphs

%% bonus - topomap plotting

% you need rri_topoplot.m


% 
%% understanding topoplot and colorbar with its title 
% 
% % For this section to work, you need EEGLAB toolbox and add the 'add
% % subdirectories' in your MATLAB path.
% 
% % load('P3topo_data.mat'); % I use xdat (size: 64 x 1)from here that
% % contains a topography
% 
% rri_topoplot(xdat,{'maplimits',[-1, 1]}) % [min max] in micro volt (because the data are already in micro volt)
% hcb=colorbar('eastoutside'); % color bar location
% hcb.Title.String='\muV'; % this will appear on top of the color bar
% % the escape mu (\mu) will give you the greek letter of 'micro'
% 
% % if you want an additional title, along the color bar, use this XLabel 
% set(hcb.XLabel,{'String','Rotation','Position'},{'MyXLabel',90,[2.0 -0.01]})
% % the rotation and position should be adjusted according to needs
% 
% % At this moment I ignore the fact that nose and ears are half cut off

%% plot topomaps

%FRN and P3a for (human/comp) x (same/diff) x (self/other) 
%(total 16 topo)
for ipartner=1:npartner
    for imelody=1:nmelody
        for iagency=1:nagency

            % FRN
            
            % adjust according to how saturated the color is, but use the same color bar for one target ERP component  
            FRN_minmax = [-2 2]; 
            xdat= squeeze(mean(mean(mean(diff_all_f2(ssubj,ipartner,imelody, iagency,1:64,itw_FRN),1),2),6));
            figure;
            rri_topoplot(xdat,{'maplimits',FRN_minmax}) % [min max] in micro volt (because the data are already in micro volt)
            % color bar title
            hcb=colorbar('eastoutside'); % color bar location
            hcb.Title.String='\muV'; % this will appear on top of the color bar
            % the figure title (also filename)
            t = sprintf('%s-%s-%s-%s','FRN',partner{ipartner},melody{imelody},agency{iagency});
            title(t);
            print(t,'-dpdf') % you can do png too
            
            
            % P3a
            
            % adjust according to how saturated the color is, but use the same color bar for one target ERP component  
            P3a_minmax = [-2 2]; 
            xdat= squeeze(mean(mean(mean(diff_all_f2(ssubj,ipartner,imelody,iagency,1:64,itw_P3a),1),2),6));
            figure;
            rri_topoplot(xdat,{'maplimits',P3a_minmax}) % [min max] in micro volt (because the data are already in micro volt)
            % color bar title
            hcb=colorbar('eastoutside'); % color bar location
            hcb.Title.String='\muV'; % this will appear on top of the color bar
            % the figure title (also filename)
            t = sprintf('%s-%s-%s-%s','P3a',partner{ipartner},melody{imelody},agency{iagency});
            title(t);
            print(t,'-dpdf') % you can do png too
            
        end
    end
end
%%
close all

%% That's the end of it for now....



