% do_1a_add_trigger_Duet.m

% 2015 Dec 20
% do_add_trigger_Duet.m
% by Takako Fujioka for Piano Duet study
% modified 2016 March 6

% brought back from Madeline's version (2017 07 24) for 451C W19 exercise

% 2026-03-08 DrumDuetImprov (451C W26 final)

% universal name
% list subj#1 subj#2 in the order of the file
pair = {
        'UV', 'ML';
        'LJ', 'TF';
        'CM', 'MG';
        };    
npair = size(pair,1);

player = {'SubA';'SubB'};

% loop all the pairs
for ipair=1:npair
    sub={pair{ipair,1};pair{ipair,2}};
    pairname = sprintf('%s_%s', sub{1}, sub{2});

    % loop two partners
    for isubj=1:2

        subjname = sub{isubj};
        playerID= player{isubj};

        % List all the raw files for each subject
        % check the exact location of your directory for the brainstorm
        % data (until the 'exist (line 94) is successful
        dirname = '/Volumes/MLF/EEG-Hyperscanning/brainstorm_db/Duet2026/data';
% 
% 
% Path: C:\Users\tfujioka\Documents\brainstorm_db\DrumDuetImprov\data
% Name: LJ/@rawLJ_TF_01_SubA_Data/data_0raw_LJ_TF_01_SubA_Data.mat

% List all the raw files for each subject
        all_filenames = {
            sprintf('%s/%s/@raw%s_01_%s_Data/data_0raw_%s_01_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            sprintf('%s/%s/@raw%s_02_%s_Data/data_0raw_%s_02_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            sprintf('%s/%s/@raw%s_03_%s_Data/data_0raw_%s_03_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            sprintf('%s/%s/@raw%s_04_%s_Data/data_0raw_%s_04_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            sprintf('%s/%s/@raw%s_05_%s_Data/data_0raw_%s_05_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            sprintf('%s/%s/@raw%s_06_%s_Data/data_0raw_%s_06_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            sprintf('%s/%s/@raw%s_07_%s_Data/data_0raw_%s_07_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            sprintf('%s/%s/@raw%s_08_%s_Data/data_0raw_%s_08_%s_Data.mat',dirname,subjname,pairname,playerID,pairname,playerID), ...
            };        
        
        nfile = size(all_filenames,2);

        %%% loop all the files
        for ifile=1:nfile

            raw_filename = all_filenames{ifile};
            display(raw_filename)
            if ~exist(raw_filename) continue;end


            load(raw_filename);


            % this is the original trigger data
            events = F.events;
            nstim = size(events,2);
            % list only Stim stuff
            stimidx = [];
            for istim = 1:nstim
                if strfind(events(istim).label, 'Stim') % not strcmp anymore
                    stimidx = [stimidx, istim];
                end
            end
            events_stim = events(stimidx);
            %only count these
            nstim = size(events_stim,2);
            
            %% first, do the first 6 phrase trials
            
            % Block conditions
            % 201=Two + P1 start
            % 202=Two + P2 start
            % 203=One + P1 start
            % 204=One + P2 start
            
            % FRN

            % 201 & 203 = P1odd
            % this makes
            % DevOdd (14,15,16,17, 34,35,36,37, 54,55,56,57) as DevSelf for SubA
            % DevEven(24,25,26,27, 44,45,46,47, 64,65,66,67) as DevOther for SubA
            
            % 202 & 204 = P1even
            % odd and even are differently associated to the dev-self and dev-other
            % DevOdd (14,15,16,17, 34,35,36,37, 54,55,56,57) as DevOther
            % for SubB
            % DevEven(24,25,26,27, 44,45,46,47, 64,65,66,67) as DevSelf for
            % SubB
            
            % For DevOdd or DevEven
            % number ending 4,5 = My timbre (DevSelfMytimb,DevOtherMytimb)
            % number ending 6,7 = Partner timbre (DevSelfPttimb,
            % DevOtherPttimb)

            % so what is Standard?
            % 11 just before 14,15 -> StdOddMy, 16,17-> StdOddPt
            % 31 just before 34,35 -> StdOddMy, 36,37 -> StdOddPt
            % 51 just before 54,55 -> StdOddMy, 36,37 -> StdOddPt
            
            % 21 just before 24,25 -> StdEvenMy, 26,27-> StdEvenPt 
            % 41 just before 44,45 -> StdEvenMy, 46,47-> StdEvenPt 
            % 61 just before 64,65 -> StdEvenMy, 66,67-> StdEvenPt 

            % Alpha
            % looking at Phrase 2,3,4,5 but only when Deviant free

            % Phrase 2 & 4 (first 21, first 41) -> StarterListen, JoinerPlay
            % Phrase 3 & 5 (first 31, first 51) -> StarterPlay, JoinerListen

            % excluding Phrase 1 and 6 
            
            % were there any success trials?
            time_success = [];
            t0=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label, 'Stim 81'))
                    t0=[t0, ev.times];
                end
            end
            time_success = sort(t0);

            % extract condition and regular trial start times
            time_regular = [];
            t0=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label, 'Stim 201'))
                    task = 'Two';
                    order = 'P1odd';
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 202'))
                    task = 'Two';
                    order = 'P1even';
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 203'))
                    task = 'One';
                    order = 'P1odd';
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 204'))
                    task = 'One';
                    order = 'P1even';
                    t0=[t0, ev.times];
                end
            end % stim
            time_regular = sort(t0);

            % find the valid trial start followed by 81 approximately
            % 20 seconds later
            
            % for each of 81, find the starting time (201/202/203/204)
            t0=[];
            t1=[]; % we have to look only 81 excluding practice trials
            nsucc = length(time_success);
            for isucc=1:nsucc
                curr_succ_time = time_success(isucc);
                idx=find(abs(time_regular - (curr_succ_time-20))< 2.0 );
                if ~isempty(idx)
                    t0=[t0, time_regular(idx)];
                    t1=[t1,curr_succ_time];
                end
            end
            % have a list of windows that are valid
            time_success_start_end = [t0' t1'];

            % ok, then find DevOdd and DevEven, and verify whether they are within this 
            % success time windows 
            
            % DevOdd
            t1=[]; %My
            t2=[]; %Pt
            % DevEven
            t3=[]; %My
            t4=[]; %Pt
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label, 'Stim 14'))||(strcmp(ev.label, 'Stim 15'))||(strcmp(ev.label, 'Stim 34'))||(strcmp(ev.label, 'Stim 35')) || (strcmp(ev.label, 'Stim 54'))||(strcmp(ev.label, 'Stim 55'))
                    t1 = [t1,ev.times];
                elseif (strcmp(ev.label, 'Stim 16'))||(strcmp(ev.label, 'Stim 17'))||(strcmp(ev.label, 'Stim 36'))||(strcmp(ev.label, 'Stim 37')) || (strcmp(ev.label, 'Stim 56'))||(strcmp(ev.label, 'Stim 57'))
                    t2 = [t2,ev.times];
                elseif (strcmp(ev.label, 'Stim 24'))||(strcmp(ev.label, 'Stim 25'))||(strcmp(ev.label, 'Stim 44'))||(strcmp(ev.label, 'Stim 45')) || (strcmp(ev.label, 'Stim 64'))||(strcmp(ev.label, 'Stim 65'))
                    t3 = [t3,ev.times];
                elseif (strcmp(ev.label, 'Stim 26'))||(strcmp(ev.label, 'Stim 27'))||(strcmp(ev.label, 'Stim 46'))||(strcmp(ev.label, 'Stim 47')) || (strcmp(ev.label, 'Stim 66'))||(strcmp(ev.label, 'Stim 67'))
                    t4 = [t4,ev.times];  
                end
            end
            % now screen them, choose only when within success time windows
            t1_succ = [];
            for myidx=1:length(t1)
                curr_time = t1(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t1_succ = [t1_succ, curr_time];
                end
            end
            t2_succ = [];
            for myidx=1:length(t2)
                curr_time = t2(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t2_succ = [t2_succ, curr_time];
                end
            end
            t3_succ = [];
            for myidx=1:length(t3)
                curr_time = t3(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t3_succ = [t3_succ, curr_time];
                end
            end
            t4_succ = [];
            for myidx=1:length(t4)
                curr_time = t4(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t4_succ = [t4_succ, curr_time];
                end
            end
            time_dev_odd_my = sort(t1_succ);
            time_dev_odd_pt = sort(t2_succ);
            time_dev_even_my= sort(t3_succ);
            time_dev_even_pt = sort(t4_succ);
            
            % Standard
            % find the unaltered note just before each deviant
            % do this from the concatenated big pool of regular notes for
            % odd phrases, and even phrases
            % Note that we don't have 'screen' them for success trials
            % because we already did for deviants

            t1=[]; % notes in odd phrases
            t2=[]; % notes in even phrases
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label, 'Stim 11'))||(strcmp(ev.label, 'Stim 31'))||(strcmp(ev.label, 'Stim 51'))
                    t1 = [t1,ev.times];
                elseif (strcmp(ev.label, 'Stim 21'))||(strcmp(ev.label, 'Stim 41'))||(strcmp(ev.label, 'Stim 61'))
                    t2 = [t2,ev.times];
                end
            end
            t_odd_std_all = sort(t1);
            t_even_std_all = sort(t2);

            % now for each dev note
            % look for the closest note before.
            % generic dev time vector (we'll reuse this code for each dev
            % (odd/even x my/pt)
            
            % (1) dev odd my
            time_dev = time_dev_odd_my;
            time_std = t_odd_std_all;
            t_std_beforeDev = [];            
            % find the note before for each dev
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev);
                [value, idx] = sort(abs(curr_t-time_std));
                if ~isempty(idx)
                    idx2=find(curr_t > time_std(idx)); % standard earlier than deviant 
                    % take the first one that gives you 1 (not 0)
                    t_std_beforeDev = [t_std_beforeDev, time_std(idx(idx2(1)))];
                end
            end
            time_std_odd_my = t_std_beforeDev;
            % (2) dev odd pt
            time_dev = time_dev_odd_pt;
            time_std = t_odd_std_all;
            t_std_beforeDev = [];            
            % find the note before for each dev
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev);
                [value, idx] = sort(abs(curr_t-time_std));
                if ~isempty(idx)
                    idx2=find(curr_t > time_std(idx)); % standard earlier than deviant 
                    % take the first one that gives you 1 (not 0)
                    t_std_beforeDev = [t_std_beforeDev, time_std(idx(idx2(1)))];
                end
            end
            time_std_odd_pt = t_std_beforeDev;

            % (3) even my
            time_dev = time_dev_even_my;
            time_std = t_even_std_all;
            t_std_beforeDev = [];            
            % find the note before for each dev
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev);
                [value, idx] = sort(abs(curr_t-time_std));
                if ~isempty(idx)
                    idx2=find(curr_t > time_std(idx)); % standard earlier than deviant 
                    % take the first one that gives you 1 (not 0)
                    t_std_beforeDev = [t_std_beforeDev, time_std(idx(idx2(1)))];
                end
            end
            time_std_even_my = t_std_beforeDev;
            % (4) even pt
            time_dev = time_dev_even_pt;
            time_std = t_even_std_all;
            t_std_beforeDev = [];            
            % find the note before for each dev
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev);
                [value, idx] = sort(abs(curr_t-time_std));
                if ~isempty(idx)
                    idx2=find(curr_t > time_std(idx)); % standard earlier than deviant 
                    % take the first one that gives you 1 (not 0)
                    t_std_beforeDev = [t_std_beforeDev, time_std(idx(idx2(1)))];
                end
            end
            time_std_even_pt = t_std_beforeDev;
            % Okay, FRN is done

            % Now turning to Alpha
            
            % find the first 31 and 51 for odd phrases, and 21 and 41 for even phrases
            % but not only success, it should not have deviants in the phrase

            t2=[]; % phrase 2
            t3=[]; % phrase 3
            t4=[]; % phrase 4
            t5=[]; % phrase 5            
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label,'Stim 31')) 
                    t3 =[t3, ev.times];
                elseif (strcmp(ev.label,'Stim 51'))
                    t5 =[t5, ev.times];
                elseif (strcmp(ev.label, 'Stim 21')) 
                    t2 =[t2, ev.times];
                elseif (strcmp(ev.label,'Stim 41'))
                    t4 =[t4, ev.times];
                end
            end
            % screen for success
            % phrase 3
            t3_succ = [];
            for myidx=1:length(t3)
                curr_time = t3(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t3_succ = [t3_succ, curr_time];
                end
            end
            % phrase 5
            t5_succ = [];
            for myidx=1:length(t5)
                curr_time = t5(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t5_succ = [t5_succ, curr_time];
                end
            end
            
            % phrase 2
            t2_succ = [];
            for myidx=1:length(t2)
                curr_time = t2(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t2_succ = [t2_succ, curr_time];
                end
            end
            % phrase 4
            t4_succ = [];
            for myidx=1:length(t4)
                curr_time = t4(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t4_succ = [t4_succ, curr_time];
                end
            end
            % now for each of these notes,
            % first one in the local repeats 
            % and not followed by any deviant within the phrase

            % let's do phrase 3
            tp=t3_succ;
            tp_diff = tp(2:end)-tp(1:end-1); % consecutive time interval
            idx = find(tp_diff>19); % different trials then would be about 20sec apart
            tp_first0 = tp(idx+1); % these are the first of 31 spree 
            tp_first = [tp(1),tp_first0];
            tp_end0 = tp(idx-1);
            tp_end = [tp_end0,tp(end)];
            tp_start_end = [tp_first' tp_end'];
            % now look if there are deviants within these windows
            tp_first_dev = [];
            time_dev=sort([time_dev_odd_my, time_dev_odd_pt]); % odd phrase deviants
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev); 
                % is this deviant inside? 
                idx=find(curr_t > tp_start_end(:,1) & curr_t < tp_start_end(:,2));
                if ~isempty(idx) % deviant found
                    tp_first_dev = [tp_first_dev, tp_start_end(idx,1)]; % add this start time
                end
            end
            tp_first_std = setxor(tp_first, tp_first_dev); % remove dev phrase from t3_first
            % store
            t3_first_std=tp_first_std;

            % do the same for phrase 5
            tp=t5_succ;
            tp_diff = tp(2:end)-tp(1:end-1); % consecutive time interval
            idx = find(tp_diff>19); % different trials then would be about 20sec apart
            tp_first0 = tp(idx+1); % these are the first of 31 spree 
            tp_first = [tp(1),tp_first0];
            tp_end0 = tp(idx-1);
            tp_end = [tp_end0,tp(end)];
            tp_start_end = [tp_first' tp_end'];
            % now look if there are deviants within these windows
            tp_first_dev = [];
            time_dev=sort([time_dev_odd_my, time_dev_odd_pt]); % odd phrase deviants
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev); 
                % is this deviant inside? 
                idx=find(curr_t > tp_start_end(:,1) & curr_t < tp_start_end(:,2));
                if ~isempty(idx) % deviant found
                    tp_first_dev = [tp_first_dev, tp_start_end(idx,1)]; % add this start time
                end
            end
            tp_first_std = setxor(tp_first, tp_first_dev); % remove dev phrase from t3_first
            % store
            t5_first_std=tp_first_std;
            time_first_std_odd = sort([t3_first_std, t5_first_std]);

            % do phrase 2
            tp=t2_succ;
            tp_diff = tp(2:end)-tp(1:end-1); % consecutive time interval
            idx = find(tp_diff>19); % different trials then would be about 20sec apart
            tp_first0 = tp(idx+1); % these are the first of 31 spree 
            tp_first = [tp(1),tp_first0];
            tp_end0 = tp(idx-1);
            tp_end = [tp_end0,tp(end)];
            tp_start_end = [tp_first' tp_end'];
            % now look if there are deviants within these windows
            tp_first_dev = [];
            time_dev=sort([time_dev_even_my, time_dev_even_pt]); % even phrase deviants
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev); 
                % is this deviant inside? 
                idx=find(curr_t > tp_start_end(:,1) & curr_t < tp_start_end(:,2));
                if ~isempty(idx) % deviant found
                    tp_first_dev = [tp_first_dev, tp_start_end(idx,1)]; % add this start time
                end
            end
            tp_first_std = setxor(tp_first, tp_first_dev); % remove dev phrase from t3_first
            % store
            t2_first_std=tp_first_std;

            % do phrase 4
            tp=t4_succ;
            tp_diff = tp(2:end)-tp(1:end-1); % consecutive time interval
            idx = find(tp_diff>19); % different trials then would be about 20sec apart
            tp_first0 = tp(idx+1); % these are the first of 31 spree 
            tp_first = [tp(1),tp_first0];
            tp_end0 = tp(idx-1);
            tp_end = [tp_end0,tp(end)];
            tp_start_end = [tp_first' tp_end'];
            % now look if there are deviants within these windows
            tp_first_dev = [];
            time_dev=sort([time_dev_even_my, time_dev_even_pt]); % even phrase deviants
            ndev = length(time_dev);
            for idev = 1:ndev
                curr_t = time_dev(idev); 
                % is this deviant inside? 
                idx=find(curr_t > tp_start_end(:,1) & curr_t < tp_start_end(:,2));
                if ~isempty(idx) % deviant found
                    tp_first_dev = [tp_first_dev, tp_start_end(idx,1)]; % add this start time
                end
            end
            tp_first_std = setxor(tp_first, tp_first_dev); % remove dev phrase from t3_first
            % store
            t4_first_std=tp_first_std;
            time_first_std_even = sort([t2_first_std, t4_first_std]);
           
            % Unison phrase 7 (mark the phrase onset)
            time_ph7 = [];
            t7=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label,'Stim 71'))
                    t7 =[t7, ev.times];
                end
            end
            t7_succ = [];
            for myidx=1:length(t7)
                curr_time = t7(myidx);
                idx=find(curr_time > time_success_start_end(:,1) & curr_time < time_success_start_end(:,2));
                if ~isempty(idx)
                    t7_succ = [t7_succ, curr_time];
                end
            end
            time_ph7 =sort(t7_succ);

            % now we have 
            % dev_odd, std_odd, dev_even, std_even x (my_timbre/partner_timbre)
            % first_std_odd, first_std_even
            % phrase7 
            % timepoints for trials correctly performed
            
            % now add all stuff to the events and store it to brainstorm raw file
            % make labels and timepoints

            % A:P1odd -> DevSelf = DevOdd, DevOther = DevEven
            if strcmp(order,'P1odd') && strcmp(playerID,'SubA')
                % this person is Starter

                % deviant
                label_dev_self_my = sprintf('DevSelfMytimb%s', task);
                time_dev_self_my = time_dev_odd_my;

                label_dev_self_pt = sprintf('DevSelfPntimb%s', task);
                time_dev_self_pt = time_dev_odd_pt;

                label_dev_other_my = sprintf('DevOtherMytimb%s', task);
                time_dev_other_my = time_dev_even_my;

                label_dev_other_pt = sprintf('DevOtherPntimb%s', task);
                time_dev_other_pt = time_dev_even_pt;

                % standard
                label_std_self_my = sprintf('StdSelfMytimb%s', task);
                time_std_self_my = time_std_odd_my;

                label_std_self_pt = sprintf('StdSelfPntimb%s', task);
                time_std_self_pt = time_std_odd_pt;

                label_std_other_my = sprintf('StdOtherMytimb%s', task);
                time_std_other_my = time_std_even_my;

                label_std_other_pt = sprintf('StdOtherPntimb%s', task);
                time_std_other_pt = time_std_even_pt;

                % Playing odd phrases
                label_first_std_play = sprintf('StarterPlayPhrase%s', task);
                time_first_std_play = time_first_std_odd;

                % Listen even phrases
                label_first_std_listen = sprintf('StarterListenPhrase%s', task);
                time_first_std_listen = time_first_std_even;

                % Unison 7th phrase this player is a leader
                label_ph7 = sprintf('StarterUnison%s', task);

            end

            % A:P1even -> DevSelf = DevEven, DevOther = DevOdd
            if strcmp(order,'P1even') && strcmp(playerID,'SubA')
                % this person is Joiner
                
                % deviant
                label_dev_self_my = sprintf('DevSelfMytimb%s', task);
                time_dev_self_my = time_dev_even_my;

                label_dev_self_pt = sprintf('DevSelfPntimb%s', task);
                time_dev_self_pt = time_dev_even_pt;

                label_dev_other_my = sprintf('DevOtherMytimb%s', task);
                time_dev_other_my = time_dev_odd_my;

                label_dev_other_pt = sprintf('DevOtherPntimb%s', task);
                time_dev_other_pt = time_dev_odd_pt;

                % standard
                label_std_self_my = sprintf('StdSelfMytimb%s', task);
                time_std_self_my = time_std_even_my;

                label_std_self_pt = sprintf('StdSelfPntimb%s', task);
                time_std_self_pt = time_std_even_pt;

                label_std_other_my = sprintf('StdOtherMytimb%s', task);
                time_std_other_my = time_std_odd_my;

                label_std_other_pt = sprintf('StdOtherPntimb%s', task);
                time_std_other_pt = time_std_odd_pt;

                % Playing even phrases
                label_first_std_play = sprintf('JoinerPlayPhrase%s', task);
                time_first_std_play = time_first_std_even;

                % Listen odd phrases
                label_first_std_listen = sprintf('JoinerListenPhrase%s', task);
                time_first_std_listen = time_first_std_odd;

                % Unison 7th phrase this player is Joiner
                label_ph7 = sprintf('JoinerUnison%s', task);
            end


            % B:P1odd -> DevSelf = DevEven, DevOther = DevOdd
            if strcmp(order,'P1odd') && strcmp(playerID,'SubB')
                % this person is Joiner
                
                % deviant
                label_dev_self_my = sprintf('DevSelfMytimb%s', task);
                time_dev_self_my = time_dev_even_my;

                label_dev_self_pt = sprintf('DevSelfPntimb%s', task);
                time_dev_self_pt = time_dev_even_pt;

                label_dev_other_my = sprintf('DevOtherMytimb%s', task);
                time_dev_other_my = time_dev_odd_my;

                label_dev_other_pt = sprintf('DevOtherPntimb%s', task);
                time_dev_other_pt = time_dev_odd_pt;

                % standard
                label_std_self_my = sprintf('StdSelfMytimb%s', task);
                time_std_self_my = time_std_even_my;

                label_std_self_pt = sprintf('StdSelfPntimb%s', task);
                time_std_self_pt = time_std_even_pt;

                label_std_other_my = sprintf('StdOtherMytimb%s', task);
                time_std_other_my = time_std_odd_my;

                label_std_other_pt = sprintf('StdOtherPntimb%s', task);
                time_std_other_pt = time_std_odd_pt;

                % Playing even phrases
                label_first_std_play = sprintf('JoinerPlayPhrase%s', task);
                time_first_std_play = time_first_std_even;

                % Listen odd phrases
                label_first_std_listen = sprintf('JoinerListenPhrase%s', task);
                time_first_std_listen = time_first_std_odd;

                % Unison 7th phrase this player is a Joiner
                label_ph7 = sprintf('JoinerUnison%s', task);

            end

            % B:P1even => DevSelf = DevOdd, DevOther = DevEven
            if strcmp(order,'P1even') && strcmp(playerID,'SubB')
                % this person is Starter
                
                % deviant
                label_dev_self_my = sprintf('DevSelfMytimb%s', task);
                time_dev_self_my = time_dev_odd_my;

                label_dev_self_pt = sprintf('DevSelfPntimb%s', task);
                time_dev_self_pt = time_dev_odd_pt;

                label_dev_other_my = sprintf('DevOtherMytimb%s', task);
                time_dev_other_my = time_dev_even_my;

                label_dev_other_pt = sprintf('DevOtherPntimb%s', task);
                time_dev_other_pt = time_dev_even_pt;

                % standard
                label_std_self_my = sprintf('StdSelfMytimb%s', task);
                time_std_self_my = time_std_odd_my;

                label_std_self_pt = sprintf('StdSelfPntimb%s', task);
                time_std_self_pt = time_std_odd_pt;

                label_std_other_my = sprintf('StdOtherMytimb%s', task);
                time_std_other_my = time_std_even_my;

                label_std_other_pt = sprintf('StdOtherPntimb%s', task);
                time_std_other_pt = time_std_even_pt;

                % Playing odd phrases
                label_first_std_play = sprintf('StarterPlayPhrase%s', task);
                time_first_std_play = time_first_std_odd;

                % Listen even phrases
                label_first_std_listen = sprintf('StarterListenPhrase%s', task);
                time_first_std_listen = time_first_std_even;

                % Unison 7th phrase this player is a Starter
                label_ph7 = sprintf('StarterUnison%s', task);

            end

            % dev_self_my
            event_dev_self_my = events_stim(1);
            event_dev_self_my.label = label_dev_self_my;
            event_dev_self_my.times = time_dev_self_my;
            event_dev_self_my.reactTimes = zeros(size(time_dev_self_my));
            event_dev_self_my.epochs = ones(size(time_dev_self_my));
            % dev_self_pt
            event_dev_self_pt = events_stim(1);
            event_dev_self_pt.label = label_dev_self_pt;
            event_dev_self_pt.times = time_dev_self_pt;
            event_dev_self_pt.reactTimes = zeros(size(time_dev_self_pt));
            event_dev_self_pt.epochs = ones(size(time_dev_self_pt));
            % dev_other_my
            event_dev_other_my = events_stim(1);
            event_dev_other_my.label = label_dev_other_my;
            event_dev_other_my.times = time_dev_other_my;
            event_dev_other_my.reactTimes = zeros(size(time_dev_other_my));
            event_dev_other_my.epochs = ones(size(time_dev_other_my));
            % dev_other_pt
            event_dev_other_pt = events_stim(1);
            event_dev_other_pt.label = label_dev_other_pt;
            event_dev_other_pt.times = time_dev_other_pt;
            event_dev_other_pt.reactTimes = zeros(size(time_dev_other_pt));
            event_dev_other_pt.epochs = ones(size(time_dev_other_pt));
            
            % std_self_my
            event_std_self_my = events_stim(1);
            event_std_self_my.label = label_std_self_my;
            event_std_self_my.times = time_std_self_my;
            event_std_self_my.reactTimes = zeros(size(time_std_self_my));
            event_std_self_my.epochs = ones(size(time_std_self_my));
            % std_self_pt
            event_std_self_pt = events_stim(1);
            event_std_self_pt.label = label_std_self_pt;
            event_std_self_pt.times = time_std_self_pt;
            event_std_self_pt.reactTimes = zeros(size(time_std_self_pt));
            event_std_self_pt.epochs = ones(size(time_std_self_pt));
            % std_other_my
            event_std_other_my = events_stim(1);
            event_std_other_my.label = label_std_other_my;
            event_std_other_my.times = time_std_other_my;
            event_std_other_my.reactTimes = zeros(size(time_std_other_my));
            event_std_other_my.epochs = ones(size(time_std_other_my));
            % std_other_pt
            event_std_other_pt = events_stim(1);
            event_std_other_pt.label = label_std_other_pt;
            event_std_other_pt.times = time_std_other_pt;
            event_std_other_pt.reactTimes = zeros(size(time_std_other_pt));
            event_std_other_pt.epochs = ones(size(time_std_other_pt));

            % Play phrases
            event_play = events_stim(1);
            event_play.label = label_first_std_play;
            event_play.times = time_first_std_play;
            event_play.reactTimes = zeros(size(time_first_std_play));
            event_play.epochs = ones(size(time_first_std_play));
            % Listen phrases
            event_listen = events_stim(1);
            event_listen.label = label_first_std_listen;
            event_listen.times = time_first_std_listen;
            event_listen.reactTimes = zeros(size(time_first_std_listen));
            event_listen.epochs = ones(size(time_first_std_listen));
            % 7th phrase
            event_ph7 = events_stim(1);
            event_ph7.label = label_ph7;
            event_ph7.times = time_ph7;
            event_ph7.reactTimes = zeros(size(time_ph7));
            event_ph7.epochs = ones(size(time_ph7));

            % combine everything and put in the data
            % make the event list appended with the new ones
            events_new = [event_dev_self_my, event_dev_self_pt,event_dev_other_my,event_dev_other_pt, event_std_self_my, event_std_self_pt,event_std_other_my,event_std_other_pt, event_play, event_listen, event_ph7];

            % call it as events
            events = events_new;

            % save in the file with all the other variables in the event
            % specific file (make a directory called EventFiles first)

            % windows PC
            %event_filename=sprintf('C:\\Users\\tfujioka\\Documents\\MATLAB\\451CW22\\EventFiles\\events_%s_run%d',subjname, ifile);

            % when linux or mac
            %event_filename= (whatever your directory is)
            %event_filename=sprintf('/user/t/takako/MATLAB/Duet/eeg_analysis/Duet2022/EventFiles/events_%s_run%d',subjname, ifile);
            event_filename=sprintf('/Volumes/MLF/EEG-Hyperscanning/EX 2/EventFiles/events_%s_run%d',subjname, ifile);

            save(event_filename, 'events');
            display('file written');

        end % ifile
    end % isubj
end % ipair

%% check EventFiles content - each person has to have 8 files made