function dat_out = repair_steps_12_data2(Data, TimeVector)
% 2023-04-15 Takako revised this as 'repair_steps_12_data2' based on
% the previous version 'repair_steps_12_data'
% If you used the previous version for the ERP and alpha analysis it's most likely
% fine. 
% However, you want to do the beta analysis, redo the
% 'do_1?_bst_run_repair_steps.m' process with this version

time = TimeVector;
dat = Data(1:size(Data,1)-1,:); % remove the last channel (trigger)

[nchan,nsample]=size(dat);
fs=[nsample-1]/(time(end)-time(1));
fs2=fs/2;

% prepare the shift - judge whether the shift is necessary
% do this at each channel
% steps at multiples of 10s
nseg=round(time(end)/10)-1;
steps=zeros(nchan,nseg);
stepidx=zeros(nchan,nseg+1); % the final segment is a short one
for iseg=1:nseg
    % make this time window shorter
	tidx_centre = find(time>iseg*10,1)-1; % it will be 5001, 10001, etc.
    tidx=[find(time>(iseg*10-0.03),1):find(time>(iseg*10+0.03),1)]; % look at 30ms before and 30ms after
	for ichan=1:nchan
		curr_diff = diff(dat(ichan,tidx)); % thus you don't zero at the beginning
        curr_diff_z = (curr_diff - mean(curr_diff))/std(curr_diff); % z-score
        [mx,ix]=max(abs(curr_diff_z)); % now do it per channel so it's not variance anymore
        curr_gap_idx = tidx(1)+ix-1; % now it's the index only backward by 1
        % look at z-score and how far from 10-sec mark
        if mx > 2 && abs(curr_gap_idx - tidx_centre)<2 % accept the next neighbouring point
            stepidx(ichan,iseg)=curr_gap_idx; 
            steps(ichan,iseg)=curr_diff(ix); % this is the shift needed
        else
            stepidx(ichan,iseg)=tidx_centre; % if that's not in the neighbouring points, take the tidx_centre
            steps(ichan,iseg)=dat(ichan,tidx_centre+1)-dat(ichan,tidx_centre);    
        end
    end %ichan
end

% append the last (short) segment
for ichan=1:nchan    
    stepidx(ichan, nseg+1)=nsample;
end

% now do the shift
dat1=zeros(size(dat));
for ichan=1:nchan
    dat1(ichan,:)=dat(ichan,:);
    offs=0;
    for iseg=1:nseg
            offs=offs-steps(ichan,iseg);
            curr=dat1(ichan,stepidx(ichan,iseg)+1:stepidx(ichan,iseg+1));
            dat1(ichan,stepidx(ichan, iseg)+1:stepidx(ichan,iseg+1))=curr+offs;
    end
end

% highpass 0.1Hz
[hb,ha]=butter(2,0.1/fs2,'high');
dat1=filtfilt(hb,ha,dat1')';

% remove line frequency artifacts
B1=fir1(2048,[0.99,1/0.99]*1*60/fs2);
B2=fir1(2048,[0.99,1/0.99]*2*60/fs2);
B3=fir1(2048,[0.99,1/0.99]*3*60/fs2);
B4=fir1(2048,[0.99,1/0.99]*4*60/fs2);

dat2=zeros(size(dat1));
for ichan=1:nchan
	dat2(ichan,:)=dat1(ichan,:)-...
		conv(dat1(ichan,:),B1,'same')-...
		conv(dat1(ichan,:),B2,'same')-...
		conv(dat1(ichan,:),B3,'same')-...
		conv(dat1(ichan,:),B4,'same');
end

dat_out = Data;
% copy over the cleaned one (1-66 chan)
dat_out(1:size(Data,1)-1,:)= dat2;
return;