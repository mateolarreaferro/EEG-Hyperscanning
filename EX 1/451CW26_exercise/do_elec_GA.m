%this function takes in a struct and three data files and appends three new
%fields to your struct - the averaged data values of the electrode
%groupings that you pass in
% Takako changed the variable names so that dat_elec happens (instead of
% dat_all_elec) 2023-01-01
function s = do_elec_GA(s,subj_list)

    nstim=size(s.dat_elec,2); nstim
    nelec=size(s.dat_elec,3); nelec
    ntime=size(s.dat_elec,4); ntime
    
    %make new GAs - not split by subject
    s.dat_GA_nf=zeros(nstim,nelec,ntime); % 3-D matrix containing all data, grand averaged across subjects
    s.dat_GA=zeros(nstim,nelec,ntime); % 3-D matrix containing all data, grand averaged across subjects
    s.dat_GA2=zeros(nstim,nelec,ntime); % 3-D matrix containing all data, grand averaged across subjects
    
    % plug in data
    for ielec=1:nelec
        % loop thru all the stims
        for icond=1:nstim
            s.dat_GA_nf(icond,ielec,:)=squeeze(mean(s.dat_elec_nf(subj_list,icond,ielec,:),1,'omitnan')); % take GA and plug into matrix
            s.dat_GA(icond,ielec,:)=squeeze(mean(s.dat_elec(subj_list,icond,ielec,:),1,'omitnan')); % take GA and plug into matrix
            s.dat_GA2(icond,ielec,:)=squeeze(mean(s.dat_elec2(subj_list,icond,ielec,:),1,'omitnan')); % take GA and plug into matrix
        end

    end
end