% do_3a_export_data_FRN_DrumDuetImprov.m
%
% Export averaged ERP data from Brainstorm for FRN analysis
% Adapted from EX 1 (do_3a_export_data_FRN_DuetEx.m)
%
% DrumDuetImprov 2026-03-20

dirname = '/Volumes/MLF/EEG-Hyperscanning/brainstorm_db/Duet2026/data';

subjname_all = {
    'UV';
    'ML';
    'LJ';
    'TF';
    'CM';
    'MG';
    };

nsubj = length(subjname_all);
subj = 1:nsubj;

% Condition names as created by do_2a epoching script
% Order: Strategy(Two,One) x Timbre(Mytimb,Pntimb) x Agency(Self,Other) x Type(Std,Dev)
stim_name = {
    'StdSelfMytimbTwo';
    'DevSelfMytimbTwo';
    'StdOtherMytimbTwo';
    'DevOtherMytimbTwo';
    'StdSelfPntimbTwo';
    'DevSelfPntimbTwo';
    'StdOtherPntimbTwo';
    'DevOtherPntimbTwo';
    'StdSelfMytimbOne';
    'DevSelfMytimbOne';
    'StdOtherMytimbOne';
    'DevOtherMytimbOne';
    'StdSelfPntimbOne';
    'DevSelfPntimbOne';
    'StdOtherPntimbOne';
    'DevOtherPntimbOne';
    };

nstim = size(stim_name, 1);
nchan = 67;
ntime = 751; % -0.5 to 1.0 s at 500 Hz

dat_all = zeros(nsubj, nstim, nchan, ntime);

for isubj = 1:nsubj
    subjname = subjname_all{isubj};
    display(isubj);
    for istim = 1:nstim
        stimname = sprintf('%s', stim_name{istim});
        filenames = sprintf('%s/%s/%s/data_*_bl.mat', dirname, subjname, stimname);
        list = dir(filenames);
        try
            matname = sprintf('%s/%s/%s/%s', dirname, subjname, stimname, list(1).name);
            tmp = load(matname);
            time = tmp.Time;
            dat_all(isubj, istim, :, :) = reshape(tmp.F, 1, 1, nchan, ntime);
        catch
            disp(sprintf('Missing: %s / %s', subjname, stimname));
            dat_all(isubj, istim, :, :) = NaN([67, 751]);
        end
    end
end

% make the time vector for later use
time = tmp.Time;

mydirectory = '/Volumes/MLF/EEG-Hyperscanning/EX 2/output';
if ~exist(mydirectory, 'dir')
    mkdir(mydirectory);
end

mydate = '20260320';
savefilename = sprintf('%s/FRN_DrumDuetImprov_%s.mat', mydirectory, mydate);
save(savefilename, 'dat_all', 'time', 'stim_name', 'subjname_all', 'nsubj', 'nstim', 'nchan', 'ntime');

fprintf('Exported %d subjects x %d conditions to %s\n', nsubj, nstim, savefilename);
