% do_1a_add_trigger_Duet.m

% 2015 Dec 20
% do_add_trigger_Duet.m
% by Takako Fujioka for Piano Duet study
% modified 2016 March 6

% brought back from Madeline's version (2017 07 24) for 451C W19 exercise

% universal name
% list subj#1 subj#2 in the order of the file
pair = {
    'S01', 'S02';
    'S03', 'S04';
    %         'S05', 'S06'; % S05 OUT for Alpha and FRN
    %         'S07', 'S08'; % S07 S08 OUT for Alpha, IN for FRN
    %         'S09', 'S10';
    %         'S11', 'S12'; % S12 OUT for Alpha and FRN
    %         'S13', 'S14';
    %         'S15', 'S16'; % S15 S16 OUT for Alpha and FRN
    %         'S17', 'S18';
    %         'S19', 'S20';
    %         'S21', 'S22'; % S21 S22 OUT for Alpha and FRN
    %         'S23', 'S24';
    };
npair = size(pair,1);

player = {'SubA';'SubB'};


%first line is first pair, second line is second pair
melnames = [
    1,2,3,4; % pair 1
    3,4,1,2; % pair 2
    %     1,2,3,4; % pair 3
    %     3,4,1,2; % pair 4
    %     1,2,3,4; % pair 5
    %     3,4,1,2; % pair 6
    %     1,2,3,4; % pair 7
    %     3,4,1,2; % pair 8
    %     1,2,3,4; % pair 9
    %     3,4,1,2; % pair 10
    %     1,2,3,4; % pair 11
    %     3,4,1,2; % pair 12
    ];


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
        dirname = 'C:\Users\tfujioka\Documents\brainstorm_db\Duet2017a\data';
% 
% Path: C:\Users\tfujioka\Documents\brainstorm_db\Duet2017\data
% Name: S01/@rawS01_AA1_1_Data/data_0raw_S01_AA1_1_Data.mat
        % List all the raw files for each subject
        all_filenames = {
            sprintf('%s/%s/@raw%s_AA%d_1_Data/data_0raw_%s_AA%d_1_Data.mat',dirname,subjname,subjname,melnames(ipair,1),subjname,melnames(ipair,1)), ...
            sprintf('%s/%s/@raw%s_AA%d_2_Data/data_0raw_%s_AA%d_2_Data.mat',dirname,subjname,subjname,melnames(ipair,1),subjname,melnames(ipair,1)), ...
            sprintf('%s/%s/@raw%s_BC%d_1_Data/data_0raw_%s_BC%d_1_Data.mat',dirname,subjname,subjname,melnames(ipair,2),subjname,melnames(ipair,2)), ...
            sprintf('%s/%s/@raw%s_BC%d_2_Data/data_0raw_%s_BC%d_2_Data.mat',dirname,subjname,subjname,melnames(ipair,2),subjname,melnames(ipair,2)), ...
            sprintf('%s/%s/@raw%s_AA%d_1_%s_Data/data_0raw_%s_AA%d_1_%s_Data.mat',dirname,subjname,pairname,melnames(ipair,3),playerID,pairname,melnames(ipair,3),playerID), ...
            sprintf('%s/%s/@raw%s_AA%d_2_%s_Data/data_0raw_%s_AA%d_2_%s_Data.mat',dirname,subjname,pairname,melnames(ipair,3),playerID,pairname,melnames(ipair,3),playerID), ...
            sprintf('%s/%s/@raw%s_BC%d_1_%s_Data/data_0raw_%s_BC%d_1_%s_Data.mat',dirname,subjname,pairname,melnames(ipair,4),playerID,pairname,melnames(ipair,4),playerID), ...
            sprintf('%s/%s/@raw%s_BC%d_2_%s_Data/data_0raw_%s_BC%d_2_%s_Data.mat',dirname,subjname,pairname,melnames(ipair,4),playerID,pairname,melnames(ipair,4),playerID), ...
            };

        % elucidate the condition of combination from filename (2017 10
        % 25)
        all_cond = {'Same';'Same';'Diff';'Diff';'Same';'Same';'Diff';'Diff';};
        all_partner = {'Comp';'Comp';'Comp';'Comp';'Human';'Human';'Human';'Human'};
        all_order = {'P1odd';'P1even';'P1odd';'P1even';'P1odd';'P1even';'P1odd';'P1even'};

        
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
            %% first, do the first 4 phrase trials
            % Human-pair

            % 201,202,203,204 exist - SameMel (AA), P1odd
            % this makes
            % DevOdd (54,55 & 64,65) as DevSelf for subA
            % DevEven(154,155 & 164,165) as DevOther for subA


            % as for the following three cases
            % 205,206,207,208 exist - AA, P1even
            % 209,210,211,212 exist - BC, P1odd
            % 213,214,215,216 exist - BC, P1even
            % odd and even are differently associated to the dev-self and dev-other


            % when Max is partner,
            % everything is +16, thus making 217-232


            % we will now rely on the filename to elucidate the condition
            % 2017 10 25
            partner = all_partner{ifile};
            cond = all_cond{ifile};
            order = all_order{ifile};

            % 2017 11 06 to correct trigger labels for S05 and S06 AA3_1
            % data
            %             partner = all_partner{7};
            %             cond = all_cond{7};
            %             order = all_order{7};

            % 2017 10 25 note by takako Here, we found S17_BC4_1 _SubA data
            % was mislabeled as Same instead of Diff because of an orphaned
            % stim 217
            % thus the following section is disabled
            %                 % what is the condition here?
            %                 for istim = 1:nstim
            %                     ev = events(istim);
            %                     if (strcmp(ev.label, 'Stim 201'))
            %                         partner = 'Human';
            %                         cond='Same';
            %                         order='P1odd';
            %                     elseif (strcmp(ev.label, 'Stim 205'))
            %                         partner = 'Human';
            %                         cond='Same';
            %                         order='P1even';
            %                     elseif (strcmp(ev.label, 'Stim 209'))
            %                         partner = 'Human';
            %                         cond='Diff';
            %                         order='P1odd';
            %                     elseif (strcmp(ev.label, 'Stim 213'))
            %                         partner = 'Human';
            %                         cond='Diff';
            %                         order = 'P1even';
            %                     elseif (strcmp(ev.label, 'Stim 217'))
            %                         partner = 'Comp';
            %                         cond='Same';
            %                         order='P1odd';
            %                     elseif (strcmp(ev.label, 'Stim 221'))
            %                         partner = 'Comp';
            %                         cond='Same';
            %                         order='P1even';
            %                     elseif (strcmp(ev.label, 'Stim 225'))
            %                         partner = 'Comp';
            %                         cond='Diff';
            %                         order='P1odd';
            %                     elseif (strcmp(ev.label, 'Stim 229'))
            %                         partner = 'Comp';
            %                         cond='Diff';
            %                         order = 'P1even';
            %                     end
            %                 end

            % were there any err trials?
            time_err = [];
            t0=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label, 'Stim 240'))
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 241'))
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 242'))
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 243'))
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 244'))
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 245'))
                    t0=[t0, ev.times];
                elseif (strcmp(ev.label, 'Stim 246'))
                    t0=[t0, ev.times];
                end
            end
            time_err = sort(t0);

            % the initial cue for each trial is going to be categorized
            time_trial = [];
            t0=[];
            if strcmp(cond,'Same') && strcmp(order, 'P1odd')
                % 201-204 (Human) or 217-220 (Comp)
                for istim = 1:nstim
                    ev = events_stim(istim);
                    if (strcmp(ev.label, 'Stim 201')) || (strcmp(ev.label, 'Stim 217'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 202')) || (strcmp(ev.label, 'Stim 218'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 203')) || (strcmp(ev.label, 'Stim 219'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 204')) || (strcmp(ev.label, 'Stim 220'))
                        t0=[t0, ev.times];
                    end
                end
                % 205-208 (Human) or 221-224 (Comp)
            elseif strcmp(cond,'Same') && strcmp(order, 'P1even')
                for istim = 1:nstim
                    ev = events_stim(istim);
                    if (strcmp(ev.label, 'Stim 205')) || (strcmp(ev.label, 'Stim 221'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 206')) || (strcmp(ev.label, 'Stim 222'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 207')) || (strcmp(ev.label, 'Stim 223'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 208')) || (strcmp(ev.label, 'Stim 224'))
                        t0=[t0, ev.times];
                    end
                end
                % 209-212 (Human) or 225-228 (Comp)
            elseif strcmp(cond,'Diff') && strcmp(order, 'P1odd')
                for istim = 1:nstim
                    ev = events_stim(istim);
                    if (strcmp(ev.label, 'Stim 209'))  || (strcmp(ev.label, 'Stim 225'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 210'))  || (strcmp(ev.label, 'Stim 226'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 211'))  || (strcmp(ev.label, 'Stim 227'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 212'))  || (strcmp(ev.label, 'Stim 228'))
                        t0=[t0, ev.times];
                    end
                end
                % 213-216 (Human) or 229-232 (Comp)
            else
                for istim = 1:nstim
                    ev = events_stim(istim);
                    if (strcmp(ev.label, 'Stim 213'))  || (strcmp(ev.label, 'Stim 229'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 214'))  || (strcmp(ev.label, 'Stim 230'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 215'))  || (strcmp(ev.label, 'Stim 231'))
                        t0=[t0, ev.times];
                    elseif (strcmp(ev.label, 'Stim 216'))  || (strcmp(ev.label, 'Stim 232'))
                        t0=[t0, ev.times];
                    end
                end % istim
            end % if
            time_trial = sort(t0);

            % have a list of windows that are invalid
            t0=[];
            nerr = size(time_err,2);
            ntrial = size(time_trial,2);
            for itrial = 1:(ntrial-1)
                curr_t1 = time_trial(itrial);
                curr_t2 = time_trial(itrial+1);
                for ierr = 1:nerr
                    curr_time_err = time_err(ierr);
                    if (curr_t1 < curr_time_err) && (curr_time_err < curr_t2)
                        t0=[t0;[curr_t1 curr_t2]];
                    end
                end
            end
            time_window_invalid = unique(t0,'rows');


            % ok, then find DevOdd and DevEven, and verify whether they are followed by
            % 235 or 239 (correctly key-press made)
            % for standard, 237 is correct trial, so 237 is also extracted.

            % 235,237,239
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label, 'Stim 235'))
                    time235 = ev.times;
                elseif (strcmp(ev.label, 'Stim 237'))
                    time237 = ev.times;
                elseif (strcmp(ev.label, 'Stim 239'))
                    time239 = ev.times;
                end
            end
            time_dev_corr = [time235, time239];
            time_std_corr = time237;

            % four different combinations (dev/std x odd/even)
            % dev_odd =54,55,64,65
            time_dev_odd = [];
            t1=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label,'Stim 54'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 55'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label,'Stim 64'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 65'))
                    t1 =[t1, ev.times];
                end
            end
            time_dev_odd =t1;

            % now for each dev note
            % look for close (about 20ms later) 235 or 239 stamp
            % if that's find, put it to the 'correct' list t2
            t2 = [];
            t3 = [];
            ndev = size(time_dev_odd,2);
            for idev = 1:ndev
                curr_t = time_dev_odd(idev);
                idx = find((time_dev_corr-curr_t)<0.045 & (time_dev_corr-curr_t)>0.01);
                if size(idx)==[1,1]
                    t2 = [t2, curr_t];
                    t3 = [t3, time_dev_corr(idx)];
                end
            end
            % you can see how '20ms' ranges by [t2' t3' t2'-t3']
            time_dev_odd_corr = sort(t2);


            % dev_even = 154,155, 164,165
            time_dev_even = [];
            t1=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label,'Stim 154'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 155'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label,'Stim 164'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 165'))
                    t1 =[t1, ev.times];
                end
            end
            time_dev_even =t1;
            % now for each dev note
            % look for close (20ms later) 235 or 239 stamp
            % if that's find, put it to the 'correct' list t2
            t2 = [];
            t3 = [];
            ndev = size(time_dev_even,2);
            for idev = 1:ndev
                curr_t = time_dev_even(idev);
                idx = find((time_dev_corr-curr_t)<0.045 & (time_dev_corr-curr_t)>0.01);
                if size(idx)==[1,1]
                    t2 = [t2, curr_t];
                    t3 = [t3, time_dev_corr(idx)];
                end
            end
            % you can see how '20ms' ranges by [t2' t3' t2'-t3']
            time_dev_even_corr = sort(t2);

            % so the deviant is done
            % now turn to standard

            % std_odd = 34,35, 44,45
            time_std_odd = [];
            t1=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label,'Stim 34'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 35'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label,'Stim 44'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 45'))
                    t1 =[t1, ev.times];
                end
            end
            time_std_odd =t1;

            % now for each std note
            % look for close (20ms later) 237 stamp
            % if that's find, put it to the 'correct' list t2
            t2 = [];
            t3 = [];
            nstd = size(time_std_odd,2);
            for istd = 1:nstd
                curr_t = time_std_odd(istd);
                idx = find((time_std_corr-curr_t)<0.045 & (time_std_corr-curr_t)>0.01);
                if size(idx)==[1,1]
                    t2 = [t2, curr_t];
                    t3 = [t3, time_std_corr(idx)];
                end
            end
            % you can see how '20ms' ranges by [t2' t3' t2'-t3']
            time_std_odd_corr = sort(t2);

            % std_even = 134,135, 144,145
            time_std_even = [];
            t1=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label,'Stim 134'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 135'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label,'Stim 144'))
                    t1 =[t1, ev.times];
                elseif (strcmp(ev.label, 'Stim 145'))
                    t1 =[t1, ev.times];
                end
            end
            time_std_even =t1;

            % now for each dev note
            % look for close (20ms later) 237 stamp
            % if that's find, put it to the 'correct' list t2
            t2 = [];
            t3 = [];
            nstd = size(time_std_even,2);
            for istd = 1:nstd
                curr_t = time_std_even(istd);
                idx = find((time_std_corr-curr_t)<0.045 & (time_std_corr-curr_t)>0.01);
                if size(idx)==[1,1]
                    t2 = [t2, curr_t];
                    t3 = [t3, time_std_corr(idx)];
                end
            end
            % you can see how '20ms' ranges by [t2' t3' t2'-t3']
            time_std_even_corr = sort(t2);

            % ph5 (mark the 5th phrase onset)
            time_ph5 = [];
            t1=[];
            for istim = 1:nstim
                ev = events_stim(istim);
                if (strcmp(ev.label,'Stim 71'))
                    t1 =[t1, ev.times];
                end
            end
            time_ph5 =sort(t1);
            % I cannot perform whether this and subsequent notes are
            % correct and valid, because of the mixup of the triggers
            % so this is overall trials at the 5th phrase




            % now we have dev_odd, std_odd, dev_even, std_even timepoints for notes
            % correctly performed
            % we are going to turn off some of them if the note falls in the
            % time_window_invalid
            ntw=size(time_window_invalid,1);
            if ntw==0
                time_dev_odd_corr_valid = time_dev_odd_corr;
                time_std_odd_corr_valid = time_std_odd_corr;
                time_dev_even_corr_valid = time_dev_even_corr;
                time_std_even_corr_valid = time_std_even_corr;
            else
                % dev_odd
                tin=time_dev_odd_corr; % input
                tout=[]; % output
                nt = size(tin,2);
                for it=1:nt
                    curr_t=tin(it);
                    valid = 1;
                    for itw=1:ntw
                        t1=time_window_invalid(itw, 1);
                        t2=time_window_invalid(itw, 2);
                        if (t1<curr_t) && (curr_t<t2) % within the err_trial
                            valid = valid * 0;
                        else
                            valid = valid * 1; % if it is out of any of the invalid window
                        end
                    end
                    if valid
                        tout=[tout, curr_t];
                    end
                end
                time_dev_odd_corr_valid = tout;
                % std_odd
                tin=time_std_odd_corr; % input
                tout=[]; % output
                nt = size(tin,2);
                for it=1:nt
                    curr_t=tin(it);
                    valid = 1;
                    for itw=1:ntw
                        t1=time_window_invalid(itw, 1);
                        t2=time_window_invalid(itw, 2);
                        if (t1<curr_t) && (curr_t<t2) % within the err_trial
                            valid = valid * 0;
                        else
                            valid = valid * 1; % if it is out of any of the invalid window
                        end
                    end
                    if valid
                        tout=[tout, curr_t];
                    end
                end
                time_std_odd_corr_valid = tout;
                % dev_even
                tin=time_dev_even_corr; % input
                tout=[]; % output
                nt = size(tin,2);
                for it=1:nt
                    curr_t=tin(it);
                    valid = 1;
                    for itw=1:ntw
                        t1=time_window_invalid(itw, 1);
                        t2=time_window_invalid(itw, 2);
                        if (t1<curr_t) && (curr_t<t2) % within the err_trial
                            valid = valid * 0;
                        else
                            valid = valid * 1; % if it is out of any of the invalid window
                        end
                    end
                    if valid
                        tout=[tout, curr_t];
                    end
                end
                time_dev_even_corr_valid = tout;
                % std_even
                tin=time_std_even_corr; % input
                tout=[]; % output
                nt = size(tin,2);
                for it=1:nt
                    curr_t=tin(it);
                    valid = 1;
                    for itw=1:ntw
                        t1=time_window_invalid(itw, 1);
                        t2=time_window_invalid(itw, 2);
                        if (t1<curr_t) && (curr_t<t2) % within the err_trial
                            valid = valid * 0;
                        else
                            valid = valid * 1; % if it is out of any of the invalid window
                        end
                    end
                    if valid
                        tout=[tout, curr_t];
                    end
                end
                time_std_even_corr_valid = tout;
            end %if

            % now add all stuff to the events and store it to brainstorm raw file
            % make labels and timepoints
            % A:P1odd -> DevSelf = DevOdd, DevOther = DevEven

            % add partner to the label too
            if strcmp(order,'P1odd') && strcmp(playerID,'SubA')
                label_dev_self = sprintf('DevSelf%s%s', cond,partner);
                time_dev_self = time_dev_odd_corr_valid;

                label_dev_other = sprintf('DevOther%s%s', cond,partner);
                time_dev_other = time_dev_even_corr_valid;

                label_std_self = sprintf('StdSelf%s%s', cond,partner);
                time_std_self = time_std_odd_corr_valid;

                label_std_other = sprintf('StdOther%s%s', cond,partner);
                time_std_other = time_std_even_corr_valid;

                % at the 5th phrase this player is a leader
                label_ph5 = sprintf('Leader%s%s', cond, partner);

            end

            % A:P1even -> DevSelf = DevEven, DevOther = DevOdd
            if strcmp(order,'P1even') && strcmp(playerID,'SubA')
                label_dev_self = sprintf('DevSelf%s%s', cond,partner);
                time_dev_self = time_dev_even_corr_valid;

                label_dev_other = sprintf('DevOther%s%s', cond,partner);
                time_dev_other = time_dev_odd_corr_valid;

                label_std_self = sprintf('StdSelf%s%s', cond,partner);
                time_std_self = time_std_even_corr_valid;

                label_std_other = sprintf('StdOther%s%s', cond,partner);
                time_std_other = time_std_odd_corr_valid;

                % at the 5th phrase this person is a follower
                label_ph5 = sprintf('Follower%s%s', cond, partner);
            end


            % B:P1odd -> DevSelf = DevEven, DevOther = DevOdd
            if strcmp(order,'P1odd') && strcmp(playerID,'SubB')
                label_dev_self = sprintf('DevSelf%s%s', cond,partner);
                time_dev_self = time_dev_even_corr_valid;

                label_dev_other = sprintf('DevOther%s%s', cond,partner);
                time_dev_other = time_dev_odd_corr_valid;

                label_std_self = sprintf('StdSelf%s%s', cond,partner);
                time_std_self = time_std_even_corr_valid;

                label_std_other = sprintf('StdOther%s%s', cond,partner);
                time_std_other = time_std_odd_corr_valid;

                % at the 5th phrase this person is a follower
                label_ph5 = sprintf('Follower%s%s', cond, partner);
            end

            % B:P1even => DevSelf = DevOdd, DevOther = DevEven
            if strcmp(order,'P1even') && strcmp(playerID,'SubB')
                label_dev_self = sprintf('DevSelf%s%s', cond,partner);
                time_dev_self = time_dev_odd_corr_valid;

                label_dev_other = sprintf('DevOther%s%s', cond,partner);
                time_dev_other = time_dev_even_corr_valid;

                label_std_self = sprintf('StdSelf%s%s', cond,partner);
                time_std_self = time_std_odd_corr_valid;

                label_std_other = sprintf('StdOther%s%s', cond,partner);
                time_std_other = time_std_even_corr_valid;

                % at the 5th phrase this player is a leader
                label_ph5 = sprintf('Leader%s%s', cond, partner);
            end

            % dev_self
            event_dev_self = events_stim(1);
            event_dev_self.label = label_dev_self;
            event_dev_self.times = time_dev_self;
            event_dev_self.reactTimes = zeros(size(time_dev_self));
            event_dev_self.epochs = ones(size(time_dev_self));
            % dev_other
            event_dev_other = events_stim(1);
            event_dev_other.label = label_dev_other;
            event_dev_other.times = time_dev_other;
            event_dev_other.reactTimes = zeros(size(time_dev_other));
            event_dev_other.epochs = ones(size(time_dev_other));
            % std_self
            event_std_self = events_stim(1);
            event_std_self.label = label_std_self;
            event_std_self.times = time_std_self;
            event_std_self.reactTimes = zeros(size(time_std_self));
            event_std_self.epochs = ones(size(time_std_self));
            % std_other
            event_std_other = events_stim(1);
            event_std_other.label = label_std_other;
            event_std_other.times = time_std_other;
            event_std_other.reactTimes = zeros(size(time_std_other));
            event_std_other.epochs = ones(size(time_std_other));

            % 5th phrase
            event_ph5 = events_stim(1);
            event_ph5.label = label_ph5;
            event_ph5.times = time_ph5;
            event_ph5.reactTimes = zeros(size(time_ph5));
            event_ph5.epochs = ones(size(time_ph5));

            % combine everything and put in the data
            % make the event list appended with the new ones
            events_new = [event_dev_self, event_dev_other, event_std_self, event_std_other, event_ph5];

            % call it as events
            events = events_new;

            % save in the file with all the other variables in the event
            % specific file (make a directory called EventFiles first)

            % windows PC
            %event_filename=sprintf('C:\\Users\\tfujioka\\Documents\\MATLAB\\451CW22\\EventFiles\\events_%s_run%d',subjname, ifile);

            % when linux or mac
            %event_filename= (whatever your directory is)
            %event_filename=sprintf('/user/t/takako/MATLAB/Duet/eeg_analysis/Duet2022/EventFiles/events_%s_run%d',subjname, ifile);
            event_filename=sprintf('C:\\Users\\tfujioka\\Documents\\MATLAB\\451C_W26_practice\\EventFiles\\events_%s_run%d',subjname, ifile);

            save(event_filename, 'events');
            display('file written');

        end % ifile
    end % isubj
end % ipair

%% check EventFiles content - each person has to have 8 files made