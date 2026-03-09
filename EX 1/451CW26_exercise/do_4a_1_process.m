% do_4a_1_process.m
% Load data, reorganize, filter, baseline, difference waveforms,
% electrode grouping, grand average, and t-tests.
% Run this first. All variables stay in workspace for subsequent scripts.

%% Load
mydirectory = '/Volumes/MLF/EEG-Hyperscanning/output';
load(sprintf('%s/FRN_DuetEx_20260208.mat',mydirectory));

dat_all_org=dat_all;
nchan=size(dat_all,3);
ntime=size(dat_all,4);

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

%% Scale to micro-Volt and reorganize
dat_all_scaled = 1.0e+6 *dat_all_org;

partner = {'Human';'Comp'};npartner = 2;
melody = {'Same';'Diff'};nmelody=2;
agency = {'Self';'Other'};nagency =2;
type = {'Std';'Dev'};ntype=2;

dat_all_ext2 = zeros(nsubj, npartner,nmelody,nagency,ntype,nchan,ntime);
for isubj=1:nsubj
    istim=1;
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype = 1:ntype
                    dat_all_ext2(isubj, ipartner, imelody, iagency, itype,:,:) = reshape(dat_all_scaled(isubj,istim,:,:), 1,1,1,1,1,1,nchan,ntime);
                    istim=istim+1;
                end
            end
        end
    end
end

dat_all = dat_all_ext2;

%% Filtering (25 Hz and 40 Hz lowpass)
fs=500;
f2=25/fs/2;
f22=40/fs/2;

[hb,ha]=butter(4, f2, 'low');
[hb2,ha2]=butter(4, f22, 'low');

dat_all_f=zeros(size(dat_all));
dat_all_f2=zeros(size(dat_all));
for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype = 1:ntype
                    for ichan=1:nchan
                        tmp=squeeze(dat_all(isubj, ipartner, imelody, iagency, itype,ichan,:));
                        dat_all_f(isubj,ipartner, imelody, iagency, itype,ichan,:)=filtfilt(hb,ha,tmp);
                        dat_all_f2(isubj,ipartner, imelody, iagency, itype,ichan,:)=filtfilt(hb2,ha2,tmp);
                    end
                end
            end
        end
    end
end

%% Baseline correction (-100ms to 0ms)
t01=0.0-0.1;
t02=0.0-0.0;
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

%% Difference waveforms (Dev - Std)
diff_all_nf=zeros(nsubj,npartner, nmelody, nagency, nchan,ntime);
diff_all_f=zeros(nsubj,npartner, nmelody, nagency, nchan,ntime);
diff_all_f2=zeros(nsubj,npartner, nmelody, nagency, nchan,ntime);

for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for ichan=1:nchan
                    diff_all_nf(isubj,ipartner, imelody, iagency,ichan,:)= dat_all_nf(isubj,ipartner, imelody, iagency,2,ichan,:)-dat_all_nf(isubj,ipartner, imelody, iagency,1,ichan,:);
                    diff_all_f(isubj,ipartner, imelody, iagency,ichan,:)= dat_all_f(isubj,ipartner, imelody, iagency,2,ichan,:)-dat_all_f(isubj,ipartner, imelody, iagency,1,ichan,:);
                    diff_all_f2(isubj,ipartner, imelody, iagency,ichan,:)= dat_all_f2(isubj,ipartner, imelody, iagency,2,ichan,:)-dat_all_f2(isubj,ipartner, imelody, iagency,1,ichan,:);
                end
            end
        end
    end
end

%% Electrode grouping
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

for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for itype=1:ntype
                    for ielec=1:nelec
                        ndimchan=size(size(dat_all_nf),2)-1;
                        tmp_elec=eval(char(elec_list(ielec)));
                        dat_elec_nf(isubj,ipartner, imelody, iagency,itype,ielec,:)=mean(dat_all_nf(isubj,ipartner, imelody, iagency,itype,tmp_elec,:),ndimchan);
                        dat_elec_f(isubj,ipartner, imelody, iagency,itype,ielec,:)=mean(dat_all_f(isubj,ipartner, imelody, iagency,itype,tmp_elec,:),ndimchan);
                        dat_elec_f2(isubj,ipartner, imelody, iagency,itype,ielec,:)=mean(dat_all_f2(isubj,ipartner, imelody, iagency,itype,tmp_elec,:),ndimchan);
                    end
                end
            end
        end
    end
end

for isubj=1:nsubj
    for ipartner = 1:npartner
        for imelody=1:nmelody
            for iagency=1:nagency
                for ielec=1:nelec
                    ndimchan=size(size(diff_elec_nf),2)-1;
                    tmp_elec=eval(char(elec_list(ielec)));
                    diff_elec_nf(isubj,ipartner, imelody,iagency,ielec,:)=mean(diff_all_nf(isubj,ipartner, imelody, iagency,tmp_elec,:),ndimchan);
                    diff_elec_f(isubj,ipartner,imelody,iagency,ielec,:)=mean(diff_all_f(isubj,ipartner, imelody, iagency,tmp_elec,:),ndimchan);
                    diff_elec_f2(isubj,ipartner,imelody,iagency,ielec,:)=mean(diff_all_f2(isubj,ipartner, imelody, iagency,tmp_elec,:),ndimchan);
                end
            end
        end
    end
end

%% Baseline on electrode groups
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

%% Grand average and SE
ssubj=1:15; % excluding S24 (idx 16) - severe eye artifacts

dat_elec_f2_GA=squeeze(mean(dat_elec_f2(ssubj,:,:,:,:,:,:),1));
dat_elec_f2_SE=squeeze(std(dat_elec_f2(ssubj,:,:,:,:,:,:),1))/sqrt(length(ssubj));
dat_elec_f2_USE=dat_elec_f2_GA+dat_elec_f2_SE;
dat_elec_f2_LSE=dat_elec_f2_GA-dat_elec_f2_SE;

diff_elec_f2_GA=squeeze(mean(diff_elec_f2(ssubj,:,:,:,:,:),1));
diff_elec_f2_SE=squeeze(std(diff_elec_f2(ssubj,:,:,:,:,:),1))/sqrt(length(ssubj));
diff_elec_f2_USE=diff_elec_f2_GA+diff_elec_f2_SE;
diff_elec_f2_LSE=diff_elec_f2_GA-diff_elec_f2_SE;

%% T-tests

[r,c]=min(find(time>0.09));
cutoff=r;

% T-test 1: Standard vs Deviant
h_all=zeros(npartner, nmelody, nagency, nelec,ntime);
p_all=zeros(npartner, nmelody, nagency, nelec,ntime);

st=struct;
fprintf('Running t-tests: Std vs Dev...\n');
for ipartner = 1:npartner
    for imelody=1:nmelody
        for iagency=1:nagency
            for ielec=1:nelec
                dat1=squeeze(dat_elec_f2(ssubj,ipartner, imelody, iagency,1,ielec,:));
                dat2=squeeze(dat_elec_f2(ssubj,ipartner, imelody, iagency,2,ielec,:));
                for itime=cutoff:ntime
                    [h, p]=my_ttest(dat1(:,itime),dat2(:,itime));
                    h_all(ipartner, imelody, iagency, ielec,itime)=h;
                    p_all(ipartner, imelody, iagency, ielec,itime)=p;
                end
            end
        end
    end
end
st.SvD_h_all = h_all;
st.SvD_p_all = p_all;
fprintf('  %d significant timepoints found.\n', sum(h_all(:)));

% T-test 2: Human vs Computer
h_all=zeros(nmelody,nagency,nelec,ntime);
p_all=zeros(nmelody,nagency,nelec,ntime);

fprintf('Running t-tests: Human vs Computer...\n');
for imelody=1:nmelody
    for iagency=1:nagency
        for ielec=1:nelec
            dat1=squeeze(diff_elec_f(ssubj,1, imelody,iagency,ielec,:));
            dat2=squeeze(diff_elec_f(ssubj,2, imelody, iagency,ielec,:));
            for itime=cutoff:ntime
                [h, p]=my_ttest(dat1(:,itime),dat2(:,itime));
                h_all(imelody,iagency, ielec,itime)=h;
                p_all(imelody, iagency,ielec,itime)=p;
            end
        end
    end
end
st.HMvCP_h_all = h_all;
st.HMvCP_p_all = p_all;
fprintf('  %d significant timepoints found.\n', sum(h_all(:)));

% T-test 3: Same vs Different melody
h_all=zeros(npartner,nagency,nelec,ntime);
p_all=zeros(npartner,nagency,nelec,ntime);

fprintf('Running t-tests: Same vs Diff melody...\n');
for ipartner = 1:npartner
    for iagency=1:nagency
        for ielec=1:nelec
            dat1=squeeze(diff_elec_f(ssubj,ipartner,1, iagency,ielec,:));
            dat2=squeeze(diff_elec_f(ssubj,ipartner,2, iagency,ielec,:));
            for itime=cutoff:ntime
                [h, p]=my_ttest(dat1(:,itime),dat2(:,itime));
                h_all(ipartner,iagency, ielec,itime)=h;
                p_all(ipartner, iagency,ielec,itime)=p;
            end
        end
    end
end
st.SMvDF_h_all = h_all;
st.SMvDF_p_all = p_all;
fprintf('  %d significant timepoints found.\n', sum(h_all(:)));

fprintf('\n=== do_4a_1_process complete ===\n');
fprintf('Next: run do_4a_2_plots to inspect waveforms\n');
