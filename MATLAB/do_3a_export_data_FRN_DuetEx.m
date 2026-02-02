% do_3a_export_data_FRN.m

% export and save in the workspace
% dat_export_data.m
% for OverlapMMN3a dataset 
% 2015-04-10 by Takako Fujioka for Madeline Huberth
% modified on 3/11/2016 by Madeline for Motif_Piano_Duet study
% brought back by Takako 2019 Jan 27 for 451C exercise.

dirname =  'C:\Users\tfujioka\Documents\brainstorm_db\Duet2017a\data';

subjname_all = {
    'S01';
    'S02';
    'S03';
    'S04';
%     'S05';
%     'S06';
%     'S07';
%     'S08';
%     'S09';
%     'S10';
%     'S11';
%     'S13';
%     'S14';
%     'S17';
%     'S18';
%     'S19';
%     'S20';
%     'S21';
%     'S22';
%     'S23';
%     'S24';
    };

nsubj = length(subjname_all);
subj = 1:nsubj;      

           
stim_name = {
    'StdSelfSameHuman';
    'DevSelfSameHuman';
    'StdOtherSameHuman';
    'DevOtherSameHuman';
    'StdSelfDiffHuman';
    'DevSelfDiffHuman';
    'StdOtherDiffHuman';
    'DevOtherDiffHuman';
    'StdSelfSameComp';
    'DevSelfSameComp';
    'StdOtherSameComp';
    'DevOtherSameComp';
    'StdSelfDiffComp';
    'DevSelfDiffComp';
    'StdOtherDiffComp';
    'DevOtherDiffComp';
    };



nstim = size(stim_name, 1);
nchan=67;
ntime=751; %need to find out ntime - export to matlab and look at length?

dat_all=zeros(nsubj,nstim,nchan,ntime);

for isubj=1:nsubj
    subjname = subjname_all{isubj};
    display(isubj);
    for istim = 1:nstim
        stimname = sprintf('%s',stim_name{istim});
        filenames = sprintf('%s/%s/%s/data_*_bl.mat',dirname, subjname, stimname); %look up naming
        list = dir(filenames);
        try
            % this should yield only one file
            matname = sprintf('%s/%s/%s/%s',dirname,subjname, stimname, list(1).name);
            tmp=load(matname);
            time = tmp.Time;
            dat_all(isubj,istim,:,:)=reshape(tmp.F,1,1,nchan,ntime);
        catch
            disp('in loop')
            dat_all(isubj,istim,:,:)=NaN([67,751]);
        end
    end
end

% make the time vector for later use
time = tmp.Time;

mydirectory =  'C:\Users\tfujioka\Documents\MATLAB/451C_W26_practice';

mydate = '20260127';
savefilename=sprintf('%s/FRN_DuetEx_%s.mat',mydirectory,mydate); %FRN_DuetEx_20260127.mat'
save(savefilename);