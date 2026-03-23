% do_4a_analysis_FRN_DrumDuetImprov.m
%
% FRN analysis for DrumDuetImprov experiment
% Runs fully automated — no manual steps required
%
% Factors:
%   Strategy: Two (Complementary) vs One (Continuity)
%   Agency:   Self vs Other
%   Timbre:   Mytimb (own instrument set) vs Pntimb (partner's set)
%   Type:     Std vs Dev (collapsed into difference wave)
%
% 2026-03-20

mydirectory = '/Volumes/MLF/EEG-Hyperscanning/EX 2/output';
mydate = '20260320';

load(sprintf('%s/FRN_DrumDuetImprov_%s.mat', mydirectory, mydate));

dat_all_org = dat_all;
nchan = size(dat_all, 3);
ntime = size(dat_all, 4);

% make the data into micro-Volt
dat_all_scaled = 1.0e+6 * dat_all_org;

%% reorganize into multi-dimensional array
% dat_all_ext2(isubj, istrategy, itimbre, iagency, itype, ichan, itime)

strategy = {'Two'; 'One'}; nstrategy = 2;
timbre = {'Mytimb'; 'Pntimb'}; ntimbre = 2;
agency = {'Self'; 'Other'}; nagency = 2;
type = {'Std'; 'Dev'}; ntype = 2;

dat_all_ext2 = zeros(nsubj, nstrategy, ntimbre, nagency, ntype, nchan, ntime);
for isubj = 1:nsubj
    istim = 1;
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                for itype = 1:ntype
                    dat_all_ext2(isubj, istrategy, itimbre, iagency, itype, :, :) = ...
                        reshape(dat_all_scaled(isubj, istim, :, :), 1, 1, 1, 1, 1, nchan, ntime);
                    istim = istim + 1;
                end
            end
        end
    end
end

dat_all = dat_all_ext2;

%% filtering

fs = 500;
f2 = 25 / fs / 2;
f22 = 40 / fs / 2;

[hb, ha] = butter(4, f2, 'low');
[hb2, ha2] = butter(4, f22, 'low');

dat_all_f = zeros(size(dat_all));
dat_all_f2 = zeros(size(dat_all));
for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                for itype = 1:ntype
                    for ichan = 1:nchan
                        tmp = squeeze(dat_all(isubj, istrategy, itimbre, iagency, itype, ichan, :));
                        dat_all_f(isubj, istrategy, itimbre, iagency, itype, ichan, :) = filtfilt(hb, ha, tmp);
                        dat_all_f2(isubj, istrategy, itimbre, iagency, itype, ichan, :) = filtfilt(hb2, ha2, tmp);
                    end
                end
            end
        end
    end
end

fprintf('Filtering done.\n');

%% baseline correction: -100 to 0 ms
t01 = -0.1;
t02 = 0.0;
it01 = max(find(time <= t01));
it02 = max(find(time <= t02));

dat_all_nf = zeros(size(dat_all));
for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                for itype = 1:ntype
                    for ichan = 1:nchan
                        ndimtime = size(size(dat_all_nf), 2);
                        tmp1 = mean(dat_all(isubj, istrategy, itimbre, iagency, itype, ichan, it01:it02), ndimtime);
                        tmp = mean(dat_all_f(isubj, istrategy, itimbre, iagency, itype, ichan, it01:it02), ndimtime);
                        tmp2 = mean(dat_all_f2(isubj, istrategy, itimbre, iagency, itype, ichan, it01:it02), ndimtime);
                        for itime = 1:ntime
                            dat_all_nf(isubj, istrategy, itimbre, iagency, itype, ichan, itime) = ...
                                dat_all(isubj, istrategy, itimbre, iagency, itype, ichan, itime) - tmp1;
                            dat_all_f(isubj, istrategy, itimbre, iagency, itype, ichan, itime) = ...
                                dat_all_f(isubj, istrategy, itimbre, iagency, itype, ichan, itime) - tmp;
                            dat_all_f2(isubj, istrategy, itimbre, iagency, itype, ichan, itime) = ...
                                dat_all_f2(isubj, istrategy, itimbre, iagency, itype, ichan, itime) - tmp2;
                        end
                    end
                end
            end
        end
    end
end

fprintf('Baseline correction done.\n');

%% make difference waveforms (Dev - Std)
diff_all_nf = zeros(nsubj, nstrategy, ntimbre, nagency, nchan, ntime);
diff_all_f = zeros(nsubj, nstrategy, ntimbre, nagency, nchan, ntime);
diff_all_f2 = zeros(nsubj, nstrategy, ntimbre, nagency, nchan, ntime);

for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                for ichan = 1:nchan
                    diff_all_nf(isubj, istrategy, itimbre, iagency, ichan, :) = ...
                        dat_all_nf(isubj, istrategy, itimbre, iagency, 2, ichan, :) - dat_all_nf(isubj, istrategy, itimbre, iagency, 1, ichan, :);
                    diff_all_f(isubj, istrategy, itimbre, iagency, ichan, :) = ...
                        dat_all_f(isubj, istrategy, itimbre, iagency, 2, ichan, :) - dat_all_f(isubj, istrategy, itimbre, iagency, 1, ichan, :);
                    diff_all_f2(isubj, istrategy, itimbre, iagency, ichan, :) = ...
                        dat_all_f2(isubj, istrategy, itimbre, iagency, 2, ichan, :) - dat_all_f2(isubj, istrategy, itimbre, iagency, 1, ichan, :);
                end
            end
        end
    end
end

fprintf('Difference waveforms done.\n');

%% electrode groups
fc6 = [9, 10, 11, 18, 19, 20]; % F1, Fz, F2, FC1, FCz, FC2
pzp2p4 = [48, 49, 50]; % Pz, P2, P4
elec_list = {'fc6'; 'pzp2p4'};
nelec = length(elec_list);

dat_elec_nf = zeros(nsubj, nstrategy, ntimbre, nagency, ntype, nelec, ntime);
dat_elec_f = zeros(nsubj, nstrategy, ntimbre, nagency, ntype, nelec, ntime);
dat_elec_f2 = zeros(nsubj, nstrategy, ntimbre, nagency, ntype, nelec, ntime);
diff_elec_nf = zeros(nsubj, nstrategy, ntimbre, nagency, nelec, ntime);
diff_elec_f = zeros(nsubj, nstrategy, ntimbre, nagency, nelec, ntime);
diff_elec_f2 = zeros(nsubj, nstrategy, ntimbre, nagency, nelec, ntime);

for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                for itype = 1:ntype
                    for ielec = 1:nelec
                        ndimchan = size(size(dat_all_nf), 2) - 1;
                        tmp_elec = eval(char(elec_list(ielec)));
                        dat_elec_nf(isubj, istrategy, itimbre, iagency, itype, ielec, :) = mean(dat_all_nf(isubj, istrategy, itimbre, iagency, itype, tmp_elec, :), ndimchan);
                        dat_elec_f(isubj, istrategy, itimbre, iagency, itype, ielec, :) = mean(dat_all_f(isubj, istrategy, itimbre, iagency, itype, tmp_elec, :), ndimchan);
                        dat_elec_f2(isubj, istrategy, itimbre, iagency, itype, ielec, :) = mean(dat_all_f2(isubj, istrategy, itimbre, iagency, itype, tmp_elec, :), ndimchan);
                    end
                end
            end
        end
    end
end

for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                for ielec = 1:nelec
                    ndimchan = size(size(diff_elec_nf), 2) - 1;
                    tmp_elec = eval(char(elec_list(ielec)));
                    diff_elec_nf(isubj, istrategy, itimbre, iagency, ielec, :) = mean(diff_all_nf(isubj, istrategy, itimbre, iagency, tmp_elec, :), ndimchan);
                    diff_elec_f(isubj, istrategy, itimbre, iagency, ielec, :) = mean(diff_all_f(isubj, istrategy, itimbre, iagency, tmp_elec, :), ndimchan);
                    diff_elec_f2(isubj, istrategy, itimbre, iagency, ielec, :) = mean(diff_all_f2(isubj, istrategy, itimbre, iagency, tmp_elec, :), ndimchan);
                end
            end
        end
    end
end

% baseline on electrode group data
for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                for itype = 1:ntype
                    for ielec = 1:nelec
                        ndimtime = size(size(dat_elec_nf), 2);
                        tmp = mean(dat_elec_nf(isubj, istrategy, itimbre, iagency, itype, ielec, it01:it02), ndimtime);
                        tmp1 = mean(dat_elec_f(isubj, istrategy, itimbre, iagency, itype, ielec, it01:it02), ndimtime);
                        tmp2 = mean(dat_elec_f2(isubj, istrategy, itimbre, iagency, itype, ielec, it01:it02), ndimtime);

                        tmp_vector = tmp * ones(1, 1, 1, 1, 1, 1, ntime);
                        tmp1_vector = tmp1 * ones(1, 1, 1, 1, 1, 1, ntime);
                        tmp2_vector = tmp2 * ones(1, 1, 1, 1, 1, 1, ntime);

                        dat_elec_nf(isubj, istrategy, itimbre, iagency, itype, ielec, :) = dat_elec_nf(isubj, istrategy, itimbre, iagency, itype, ielec, :) - tmp_vector;
                        dat_elec_f(isubj, istrategy, itimbre, iagency, itype, ielec, :) = dat_elec_f(isubj, istrategy, itimbre, iagency, itype, ielec, :) - tmp1_vector;
                        dat_elec_f2(isubj, istrategy, itimbre, iagency, itype, ielec, :) = dat_elec_f2(isubj, istrategy, itimbre, iagency, itype, ielec, :) - tmp2_vector;
                    end
                end
                % diff baseline
                for ielec = 1:nelec
                    ndimtime = size(size(diff_elec_nf), 2);
                    tmp = mean(diff_elec_nf(isubj, istrategy, itimbre, iagency, ielec, it01:it02), ndimtime);
                    tmp1 = mean(diff_elec_f(isubj, istrategy, itimbre, iagency, ielec, it01:it02), ndimtime);
                    tmp2 = mean(diff_elec_f2(isubj, istrategy, itimbre, iagency, ielec, it01:it02), ndimtime);

                    tmp_vector = tmp * ones(1, 1, 1, 1, 1, ntime);
                    tmp1_vector = tmp1 * ones(1, 1, 1, 1, 1, ntime);
                    tmp2_vector = tmp2 * ones(1, 1, 1, 1, 1, ntime);

                    diff_elec_nf(isubj, istrategy, itimbre, iagency, ielec, :) = diff_elec_nf(isubj, istrategy, itimbre, iagency, ielec, :) - tmp_vector;
                    diff_elec_f(isubj, istrategy, itimbre, iagency, ielec, :) = diff_elec_f(isubj, istrategy, itimbre, iagency, ielec, :) - tmp1_vector;
                    diff_elec_f2(isubj, istrategy, itimbre, iagency, ielec, :) = diff_elec_f2(isubj, istrategy, itimbre, iagency, ielec, :) - tmp2_vector;
                end
            end
        end
    end
end

fprintf('Electrode groups done.\n');

%% grand average and SE
ssubj = 1:nsubj;

dat_elec_f2_GA = squeeze(mean(dat_elec_f2(ssubj, :, :, :, :, :, :), 1));
dat_elec_f2_SE = squeeze(std(dat_elec_f2(ssubj, :, :, :, :, :, :), 0, 1)) / sqrt(length(ssubj));

diff_elec_f2_GA = squeeze(mean(diff_elec_f2(ssubj, :, :, :, :, :), 1));
diff_elec_f2_SE = squeeze(std(diff_elec_f2(ssubj, :, :, :, :, :), 0, 1)) / sqrt(length(ssubj));

%% t-tests
[r, c] = min(find(time > 0.09));
cutoff = r;

st = struct;

% Std vs Dev per condition
h_all = zeros(nstrategy, ntimbre, nagency, nelec, ntime);
p_all = zeros(nstrategy, ntimbre, nagency, nelec, ntime);
for istrategy = 1:nstrategy
    for itimbre = 1:ntimbre
        for iagency = 1:nagency
            for ielec = 1:nelec
                dat1 = squeeze(dat_elec_f2(ssubj, istrategy, itimbre, iagency, 1, ielec, :));
                dat2 = squeeze(dat_elec_f2(ssubj, istrategy, itimbre, iagency, 2, ielec, :));
                for itime = cutoff:ntime
                    [h, p] = my_ttest(dat1(:, itime), dat2(:, itime));
                    h_all(istrategy, itimbre, iagency, ielec, itime) = h;
                    p_all(istrategy, itimbre, iagency, ielec, itime) = p;
                end
            end
        end
    end
end
st.SvD_h_all = h_all;
st.SvD_p_all = p_all;

% Self vs Other
h_all2 = zeros(nstrategy, ntimbre, nelec, ntime);
p_all2 = zeros(nstrategy, ntimbre, nelec, ntime);
for istrategy = 1:nstrategy
    for itimbre = 1:ntimbre
        for ielec = 1:nelec
            dat1 = squeeze(diff_elec_f(ssubj, istrategy, itimbre, 1, ielec, :));
            dat2 = squeeze(diff_elec_f(ssubj, istrategy, itimbre, 2, ielec, :));
            for itime = cutoff:ntime
                [h, p] = my_ttest(dat1(:, itime), dat2(:, itime));
                h_all2(istrategy, itimbre, ielec, itime) = h;
                p_all2(istrategy, itimbre, ielec, itime) = p;
            end
        end
    end
end
st.SelfvOther_h_all = h_all2;
st.SelfvOther_p_all = p_all2;

% Continuity vs Complementary
h_all3 = zeros(ntimbre, nagency, nelec, ntime);
p_all3 = zeros(ntimbre, nagency, nelec, ntime);
for itimbre = 1:ntimbre
    for iagency = 1:nagency
        for ielec = 1:nelec
            dat1 = squeeze(diff_elec_f(ssubj, 1, itimbre, iagency, ielec, :));
            dat2 = squeeze(diff_elec_f(ssubj, 2, itimbre, iagency, ielec, :));
            for itime = cutoff:ntime
                [h, p] = my_ttest(dat1(:, itime), dat2(:, itime));
                h_all3(itimbre, iagency, ielec, itime) = h;
                p_all3(itimbre, iagency, ielec, itime) = p;
            end
        end
    end
end
st.TwovOne_h_all = h_all3;
st.TwovOne_p_all = p_all3;

fprintf('T-tests done.\n');

%% ====================================================================
%  AUTOMATED PEAK DETECTION
%  Finds FRN and P3a windows from the grand-average difference wave
%  with fallback to a fixed window if the waveform is too noisy
%  ====================================================================

ielec = 1; % frontocentral cluster
gdiff = squeeze(mean(mean(mean(diff_elec_f2_GA(:, :, :, ielec, :), 1), 2), 3));

% --- FRN: search for most negative peak between 100-300 ms ---
it_100 = max(find(time <= 0.10));
it_300 = max(find(time <= 0.30));
it_350 = max(find(time <= 0.35));
it_050 = max(find(time <= 0.05));
it_400 = max(find(time <= 0.40));

[frn_val, frn_rel_idx] = min(gdiff(it_100:it_300));
itpkFRN = it_100 + frn_rel_idx - 1;
tpkFRN = time(itpkFRN);
fprintf('FRN peak: %.1f ms (%.3f uV)\n', tpkFRN*1000, frn_val);

% --- P3a: search for most positive peak between FRN peak and 400 ms ---
[p3a_val, p3a_rel_idx] = max(gdiff(itpkFRN:it_400));
itpkP3a = itpkFRN + p3a_rel_idx - 1;
tpkP3a = time(itpkP3a);
fprintf('P3a peak: %.1f ms (%.3f uV)\n', tpkP3a*1000, p3a_val);

% --- FRN time window via half-amplitude method ---
% find positive peak before FRN (search from 50ms)
[~, pre_rel_idx] = max(gdiff(it_050:itpkFRN));
it_beforeFRN = it_050 + pre_rel_idx - 1;

pk2pk_before = gdiff(it_beforeFRN) - gdiff(itpkFRN);
pk2pk_after = gdiff(itpkP3a) - gdiff(itpkFRN);
half_before = 0.5 * pk2pk_before + gdiff(itpkFRN);
half_after = 0.5 * pk2pk_after + gdiff(itpkFRN);

% find half-amplitude crossings
idx1 = find(gdiff(it_beforeFRN:itpkFRN) >= half_before);
idx2 = find(gdiff(itpkFRN:itpkP3a) <= half_after);

if ~isempty(idx1) && ~isempty(idx2)
    it_FRN_start = it_beforeFRN + max(idx1) - 1;
    it_FRN_end = itpkFRN + max(idx2) - 1;
    itw_FRN = it_FRN_start:it_FRN_end;
    fprintf('FRN window (half-amp): %.1f to %.1f ms\n', time(itw_FRN(1))*1000, time(itw_FRN(end))*1000);
else
    % fallback: +/- 50ms around peak
    it_FRN_start = max(find(time <= tpkFRN - 0.05));
    it_FRN_end = max(find(time <= tpkFRN + 0.05));
    itw_FRN = it_FRN_start:it_FRN_end;
    fprintf('FRN window (fallback +/-50ms): %.1f to %.1f ms\n', time(itw_FRN(1))*1000, time(itw_FRN(end))*1000);
end

% --- P3a time window ---
it_P3a_start = itw_FRN(end); % starts right after FRN window

% find trough after P3a
[~, post_rel_idx] = min(gdiff(itpkP3a:it_400));
it_afterP3a = itpkP3a + post_rel_idx - 1;

pk2pk_postP3a = gdiff(itpkP3a) - gdiff(it_afterP3a);
half_postP3a = gdiff(itpkP3a) - 0.5 * pk2pk_postP3a;

idx3 = find(gdiff(itpkP3a:it_afterP3a) >= half_postP3a);
if ~isempty(idx3)
    it_P3a_end = itpkP3a + max(idx3) - 1;
    itw_P3a = it_P3a_start:it_P3a_end;
    fprintf('P3a window (half-amp): %.1f to %.1f ms\n', time(itw_P3a(1))*1000, time(itw_P3a(end))*1000);
else
    it_P3a_end = max(find(time <= tpkP3a + 0.05));
    itw_P3a = it_P3a_start:it_P3a_end;
    fprintf('P3a window (fallback): %.1f to %.1f ms\n', time(itw_P3a(1))*1000, time(itw_P3a(end))*1000);
end

%% ====================================================================
%  EXPORT AMPLITUDES
%  ====================================================================

% Full export: Strategy x Timbre x Agency
filename = sprintf('%s/FRN_P3a_amp_DrumDuetImprov_%s.txt', mydirectory, mydate);
fid = fopen(filename, 'w');
fprintf(fid, 'subjID\tstrategy\ttimbre\tagency\telec\tFRN\tP3a\n');
ielec = 1;
for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for itimbre = 1:ntimbre
            for iagency = 1:nagency
                frn_val = squeeze(mean(diff_elec_f2(isubj, istrategy, itimbre, iagency, ielec, itw_FRN), 6));
                p3a_val = squeeze(mean(diff_elec_f2(isubj, istrategy, itimbre, iagency, ielec, itw_P3a), 6));
                fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%3.3f\t%3.3f\n', ...
                    subjname_all{isubj}, strategy{istrategy}, timbre{itimbre}, agency{iagency}, elec_list{ielec}, frn_val, p3a_val);
            end
        end
    end
end
fclose(fid);
fprintf('Full amplitude file: %s\n', filename);

% Collapsed across timbre: Strategy x Agency (primary analysis)
filename2 = sprintf('%s/FRN_amp_collapsed_DrumDuetImprov_%s.txt', mydirectory, mydate);
fid2 = fopen(filename2, 'w');
fprintf(fid2, 'subjID\tstrategy\tagency\tFRN\tP3a\n');
ielec = 1;
for isubj = 1:nsubj
    for istrategy = 1:nstrategy
        for iagency = 1:nagency
            frn_val = squeeze(mean(mean(diff_elec_f2(isubj, istrategy, :, iagency, ielec, itw_FRN), 3), 6));
            p3a_val = squeeze(mean(mean(diff_elec_f2(isubj, istrategy, :, iagency, ielec, itw_P3a), 3), 6));
            fprintf(fid2, '%s\t%s\t%s\t%3.3f\t%3.3f\n', ...
                subjname_all{isubj}, strategy{istrategy}, agency{iagency}, frn_val, p3a_val);
        end
    end
end
fclose(fid2);
fprintf('Collapsed amplitude file: %s\n', filename2);

%% ====================================================================
%  DESCRIPTIVE STATS — print to console
%  ====================================================================

fprintf('\n========== DESCRIPTIVE STATISTICS (FRN, frontocentral) ==========\n');
ielec = 1;
for istrategy = 1:nstrategy
    for iagency = 1:nagency
        vals = zeros(nsubj, 1);
        for isubj = 1:nsubj
            vals(isubj) = squeeze(mean(mean(diff_elec_f2(isubj, istrategy, :, iagency, ielec, itw_FRN), 3), 6));
        end
        fprintf('  %s / %s:  M = %+.3f uV,  SE = %.3f,  N = %d\n', ...
            strategy{istrategy}, agency{iagency}, mean(vals), std(vals)/sqrt(length(vals)), length(vals));
    end
end

% Self vs Other collapsed across strategy and timbre
fprintf('\n--- Self vs Other (collapsed across strategy & timbre) ---\n');
vals_self = zeros(nsubj, 1);
vals_other = zeros(nsubj, 1);
for isubj = 1:nsubj
    vals_self(isubj) = squeeze(mean(mean(mean(diff_elec_f2(isubj, :, :, 1, ielec, itw_FRN), 2), 3), 6));
    vals_other(isubj) = squeeze(mean(mean(mean(diff_elec_f2(isubj, :, :, 2, ielec, itw_FRN), 2), 3), 6));
end
fprintf('  Self:   M = %+.3f uV,  SE = %.3f\n', mean(vals_self), std(vals_self)/sqrt(nsubj));
fprintf('  Other:  M = %+.3f uV,  SE = %.3f\n', mean(vals_other), std(vals_other)/sqrt(nsubj));
[h_so, p_so] = my_ttest(vals_self, vals_other);
fprintf('  Paired t-test Self vs Other: p = %.4f, sig = %d\n', p_so, h_so);

% Complementary vs Continuity collapsed across agency and timbre
fprintf('\n--- Complementary (Two) vs Continuity (One) (collapsed) ---\n');
vals_two = zeros(nsubj, 1);
vals_one = zeros(nsubj, 1);
for isubj = 1:nsubj
    vals_two(isubj) = squeeze(mean(mean(mean(diff_elec_f2(isubj, 1, :, :, ielec, itw_FRN), 3), 4), 6));
    vals_one(isubj) = squeeze(mean(mean(mean(diff_elec_f2(isubj, 2, :, :, ielec, itw_FRN), 3), 4), 6));
end
fprintf('  Complementary: M = %+.3f uV,  SE = %.3f\n', mean(vals_two), std(vals_two)/sqrt(nsubj));
fprintf('  Continuity:    M = %+.3f uV,  SE = %.3f\n', mean(vals_one), std(vals_one)/sqrt(nsubj));
[h_tc, p_tc] = my_ttest(vals_two, vals_one);
fprintf('  Paired t-test Two vs One: p = %.4f, sig = %d\n', p_tc, h_tc);

% MyTimbre vs PnTimbre collapsed across strategy and agency
fprintf('\n--- MyTimbre vs PartnerTimbre (collapsed) ---\n');
vals_my = zeros(nsubj, 1);
vals_pn = zeros(nsubj, 1);
for isubj = 1:nsubj
    vals_my(isubj) = squeeze(mean(mean(mean(diff_elec_f2(isubj, :, 1, :, ielec, itw_FRN), 2), 4), 6));
    vals_pn(isubj) = squeeze(mean(mean(mean(diff_elec_f2(isubj, :, 2, :, ielec, itw_FRN), 2), 4), 6));
end
fprintf('  MyTimbre:      M = %+.3f uV,  SE = %.3f\n', mean(vals_my), std(vals_my)/sqrt(nsubj));
fprintf('  PartnerTimbre: M = %+.3f uV,  SE = %.3f\n', mean(vals_pn), std(vals_pn)/sqrt(nsubj));
[h_mp, p_mp] = my_ttest(vals_my, vals_pn);
fprintf('  Paired t-test My vs Pn: p = %.4f, sig = %d\n', p_mp, h_mp);

%% ====================================================================
%  SAVE WORKSPACE
%  ====================================================================

savefilename = sprintf('%s/Workspace_FRN_DrumDuetImprov_%s', mydirectory, mydate);
save(savefilename);
fprintf('\nWorkspace saved to %s.mat\n', savefilename);

%% ====================================================================
%  PLOTS — all saved automatically
%  ====================================================================

% --- 1. Grand average difference wave ---
figure('Visible', 'on');
plot(time, gdiff, 'k', 'LineWidth', 2);
hold on;
xline(time(itw_FRN(1)), '--r'); xline(time(itw_FRN(end)), '--r');
xline(time(itw_P3a(1)), '--b'); xline(time(itw_P3a(end)), '--b');
xline(0, '-', 'Color', [0.5 0.5 0.5]);
grid on; axis([-0.1 0.5 -6 6]);
xlabel('Time (s)'); ylabel('\muV');
title('Grand average diff wave (FC cluster) with FRN/P3a windows');
legend('Diff', 'FRN window', '', 'P3a window');
print(sprintf('%s/GrandAvg_diff_DrumDuetImprov_%s', mydirectory, mydate), '-dpng');

% --- 2. ERP waveforms: Strategy x Agency (collapsed across timbre) ---
ielec = 1;
figure('Position', [100 100 1200 800], 'Visible', 'on');
isubplot = 1;
for istrategy = 1:nstrategy
    for iagency = 1:nagency
        subplot(2, 2, isubplot);
        std_wave = squeeze(mean(dat_elec_f2_GA(istrategy, :, iagency, 1, ielec, :), 2));
        dev_wave = squeeze(mean(dat_elec_f2_GA(istrategy, :, iagency, 2, ielec, :), 2));
        diff_wave = squeeze(mean(diff_elec_f2_GA(istrategy, :, iagency, ielec, :), 2));

        plot(time, std_wave, 'b', 'LineWidth', 1.5); hold on;
        plot(time, dev_wave, 'r', 'LineWidth', 1.5);
        plot(time, diff_wave, 'k--', 'LineWidth', 1.5);
        xline(0, '-', 'Color', [0.5 0.5 0.5]);
        grid on; axis([-0.1 0.5 -6 6]);
        xlabel('Time (s)'); ylabel('\muV');
        title(sprintf('%s - %s', strategy{istrategy}, agency{iagency}));
        if isubplot == 1
            legend('Std', 'Dev', 'Diff');
        end
        isubplot = isubplot + 1;
    end
end
sgtitle('FRN at frontocentral cluster (collapsed across timbre)');
print(sprintf('%s/ERP_FRN_DrumDuetImprov_%s', mydirectory, mydate), '-dpng');

% --- 3. Topomaps: FRN for Strategy x Agency ---
for istrategy = 1:nstrategy
    for iagency = 1:nagency
        FRN_minmax = [-2 2];
        xdat = squeeze(mean(mean(mean(diff_all_f2(ssubj, istrategy, :, iagency, 1:64, itw_FRN), 1), 3), 6));
        figure('Visible', 'on');
        rri_topoplot(xdat, {'maplimits', FRN_minmax});
        hcb = colorbar('eastoutside');
        hcb.Title.String = '\muV';
        t = sprintf('FRN-%s-%s', strategy{istrategy}, agency{iagency});
        title(t);
        print(sprintf('%s/%s', mydirectory, t), '-dpdf');
        print(sprintf('%s/%s', mydirectory, t), '-dpng');
    end
end

% --- 4. Bar plot: Self vs Other by Strategy ---
figure('Visible', 'on');
bar_data = zeros(nstrategy, nagency);
bar_se = zeros(nstrategy, nagency);
for istrategy = 1:nstrategy
    for iagency = 1:nagency
        vals = zeros(nsubj, 1);
        for isubj = 1:nsubj
            vals(isubj) = squeeze(mean(mean(diff_elec_f2(isubj, istrategy, :, iagency, 1, itw_FRN), 3), 6));
        end
        bar_data(istrategy, iagency) = mean(vals);
        bar_se(istrategy, iagency) = std(vals) / sqrt(nsubj);
    end
end
b = bar(bar_data);
hold on;
% add error bars
ngroups = size(bar_data, 1);
nbars = size(bar_data, 2);
groupwidth = min(0.8, nbars/(nbars + 1.5));
for i = 1:nbars
    x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
    errorbar(x, bar_data(:,i), bar_se(:,i), 'k', 'linestyle', 'none', 'LineWidth', 1.5);
end
set(gca, 'XTickLabel', {'Complementary', 'Continuity'});
ylabel('FRN amplitude (\muV)');
legend('Self', 'Other');
title('FRN amplitude: Strategy x Agency');
grid on;
print(sprintf('%s/BarPlot_FRN_DrumDuetImprov_%s', mydirectory, mydate), '-dpng');

close all;

fprintf('\n====== ANALYSIS COMPLETE ======\n');
fprintf('Output files in: %s\n', mydirectory);
fprintf('  - FRN_P3a_amp_DrumDuetImprov_%s.txt (full)\n', mydate);
fprintf('  - FRN_amp_collapsed_DrumDuetImprov_%s.txt (Strategy x Agency)\n', mydate);
fprintf('  - Workspace_FRN_DrumDuetImprov_%s.mat\n', mydate);
fprintf('  - GrandAvg_diff, ERP_FRN, BarPlot_FRN (.png)\n');
fprintf('  - FRN-Two-Self, FRN-Two-Other, FRN-One-Self, FRN-One-Other (.pdf/.png)\n');
