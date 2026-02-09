% do_4a_3_peaks.m
% Peak identification for FRN and P3a time windows.
% Run after do_4a_1_process (and optionally do_4a_2_plots).
%
% This script finds peaks automatically, then shows you the results.
% If the peaks look wrong, adjust the search windows below and re-run.

%% Grand average difference waveform (collapsed across conditions)
ielec=1;
gdiff = squeeze(mean(mean(mean(diff_elec_f2_GA(:,:,:,ielec,:),1),2),3));

figure('Name','Grand Avg Diff - Peak Identification');
subplot(2,1,1);
plot(time, gdiff, 'LineWidth', 2);
xlabel('Time (s)'); ylabel('\muV');
title('Grand Average Difference Waveform (fc6)');
grid on;

subplot(2,1,2);
plot(1:length(time), gdiff, 'LineWidth', 2);
xlabel('Sample index'); ylabel('\muV');
title('Same data by sample index');
grid on;

%% Find FRN peak (most negative)
[value,idx]=min(gdiff);
itpkFRN=idx;
tpkFRN=time(idx);
fprintf('\nFRN peak: sample %d, time %.4f s, amplitude %.3f uV\n', itpkFRN, tpkFRN, value);

%% Find positive peak before FRN
% Adjust 0.05 if the search window is too narrow/wide
it03=max(find(time<=0.05));
[r,c]=max(gdiff(it03:itpkFRN,1));
t_beforeFRN=time(it03+c-1);
it_beforeFRN = it03+c-1;
fprintf('Positive peak before FRN: sample %d, time %.4f s, amplitude %.3f uV\n', it_beforeFRN, t_beforeFRN, r);

%% Find P3a peak (most positive)
[value,idx]=max(gdiff);
itpkP3a=idx;
tpkP3a=time(idx);
fprintf('P3a peak: sample %d, time %.4f s, amplitude %.3f uV\n', itpkP3a, tpkP3a, value);

%% Find negative peak after P3a
% Adjust 0.34 if the search window is too narrow/wide
it04=max(find(time<=0.34));
[r,c]=min(gdiff(itpkP3a:it04,1));
t_afterP3a=time(it04+c-1);
it_afterP3a = it04+c-1;
fprintf('Negative peak after P3a: sample %d, time %.4f s, amplitude %.3f uV\n', it_afterP3a, t_afterP3a, r);

%% Compute half-amplitude time windows

% FRN window
pk2pk_amp1_before = gdiff(it_beforeFRN) - gdiff(itpkFRN);
pk2pk_amp1_after =  gdiff(itpkP3a) - gdiff(itpkFRN);
amp1_before_half = 0.5*pk2pk_amp1_before+gdiff(itpkFRN);
amp1_after_half = 0.5*pk2pk_amp1_after+gdiff(itpkFRN);

[r, c]= max(find(gdiff(it_beforeFRN:itpkFRN)>=amp1_before_half));
it_beforeFRN_half = it_beforeFRN+c-1;
[r, c]= max(find(gdiff(itpkFRN:itpkP3a)<=amp1_after_half));
it_afterFRN_half = itpkFRN+c-1;

itw_FRN=it_beforeFRN_half:it_afterFRN_half;
fprintf('\nFRN time window: %.4f - %.4f s (samples %d-%d)\n', time(itw_FRN(1)), time(itw_FRN(end)), itw_FRN(1), itw_FRN(end));

% P3a window
it_beforeP3a_half = it_afterFRN_half;
pk2pk_amp1_afterP3a = (-1.0)*(gdiff(it_afterP3a) - gdiff(itpkP3a));
amp1_afterP3a_half = -(0.5*pk2pk_amp1_afterP3a)+gdiff(itpkP3a);

[r, c]= max(find(gdiff(itpkP3a:it_afterP3a)>=amp1_afterP3a_half));
it_afterP3a_half = itpkP3a+c-1;

itw_P3a=it_beforeP3a_half:it_afterP3a_half;
fprintf('P3a time window: %.4f - %.4f s (samples %d-%d)\n', time(itw_P3a(1)), time(itw_P3a(end)), itw_P3a(1), itw_P3a(end));

%% Show the windows on the waveform
figure('Name','Peak Windows');
plot(time, gdiff, 'k', 'LineWidth', 2); hold on;
% shade FRN window
xFRN = [time(itw_FRN(1)), time(itw_FRN(end)), time(itw_FRN(end)), time(itw_FRN(1))];
yFRN = [-8 -8 8 8];
patch(xFRN, yFRN, 'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
% shade P3a window
xP3a = [time(itw_P3a(1)), time(itw_P3a(end)), time(itw_P3a(end)), time(itw_P3a(1))];
yP3a = [-8 -8 8 8];
patch(xP3a, yP3a, 'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
legend('Diff waveform', 'FRN window', 'P3a window');
xlabel('Time (s)'); ylabel('\muV');
title('Grand Avg Diff with FRN (red) and P3a (blue) windows');
grid on;

fprintf('\n=== Peak identification complete ===\n');
fprintf('If windows look good, run do_4a_4_export\n');
fprintf('If not, adjust search parameters above and re-run this script.\n');
