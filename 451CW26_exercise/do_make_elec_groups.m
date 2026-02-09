%this function takes in a struct and three data files and appends three new
%fields to your struct - the averaged data values of the electrode
%groupings that you pass in
% Takako changed the variable names so that dat_elec happens (instead of
% dat_all_elec) 2023-01-01
function s = do_make_elec_groups(s,dat_all_nf,dat_all_f,dat_all_f2)

    nelec=numel(fieldnames(s)); % number of regions
    nsubj=size(dat_all_nf,1);
    nstim=size(dat_all_nf,2);
    ntime=size(dat_all_nf,4);
    
    %make new matrices
    dat_elec_nf=zeros(nsubj,nstim,nelec,ntime); % 4-D matrix containing all data grouped into n regions; lowpass25
    dat_elec=zeros(nsubj,nstim,nelec,ntime); % 4-D matrix containing all data grouped into n regions; lowpass25
    dat_elec2=zeros(nsubj,nstim,nelec,ntime); % 4-D matrix containing all data grouped into n regions; lowpass15

    fields = fieldnames(s);
    
    % making mean value of each electrode group
    for ielec=1:nelec
        tmp_elec = s.(fields{ielec}); % e.g. tmp_elec = fcr
        % loop thru all the subjects
        for isubj=1:nsubj
            % loop thru all the stims
            for istim=1:nstim
                dat_elec_nf(isubj,istim,ielec,:)=mean(dat_all_nf(isubj,istim,tmp_elec,:),3,'omitnan');
                dat_elec(isubj,istim,ielec,:)=mean(dat_all_f(isubj,istim,tmp_elec,:),3,'omitnan');
                dat_elec2(isubj,istim,ielec,:)=mean(dat_all_f2(isubj,istim,tmp_elec,:),3,'omitnan'); % lowpass2
                 % take mean of all channels included in tmp_elec (e.g. fcr)
                % and plug into grand matrix 
            end % close loop for istim
        end % close? loop for isubj
    end % close loop for ielec
    % 
    s.dat_elec_nf = dat_elec_nf;
    s.dat_elec = dat_elec;
    s.dat_elec2 = dat_elec2;
end