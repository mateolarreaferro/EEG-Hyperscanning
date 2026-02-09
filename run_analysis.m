% run_analysis.m
% Main configuration and runner script for EEG Hyperscanning Analysis
% Stanford Music 451C - Piano Duet EEG Study
%
% Created: 2026-02-01
% Author: Mateo Larrea Ferro

%% ========== PATH CONFIGURATION ==========
% All paths on MLF drive

% Working directory (this repo)
config.working_dir = '/Volumes/MLF/EEG-Hyperscanning';

% Raw EEG data location (.cnt files)
config.raw_data_path = fullfile(config.working_dir, 'Piano_Duet2017');

% Brainstorm database path (where Brainstorm stores processed data)
config.brainstorm_db_root = fullfile(config.working_dir, 'brainstorm_db');

% Protocol name
config.protocol_name = 'Duet2017';

% Channel file with correct Neuroscan Quik-cap (67) electrode positions
config.channel_file = fullfile(config.working_dir, 'channel_initial.mat');

% EventFiles directory (will be created if needed)
config.eventfiles_dir = fullfile(config.working_dir, 'EventFiles');

% Output directory for analysis results
config.output_dir = fullfile(config.working_dir, 'output');

% MATLAB scripts directory
config.scripts_dir = fullfile(config.working_dir, 'MATLAB');

% Brainstorm toolbox path
config.brainstorm_path = fullfile(config.working_dir, 'brainstorm-tools-brainstorm3-7b366a3');

%% ========== CREATE REQUIRED DIRECTORIES ==========
if ~exist(config.eventfiles_dir, 'dir')
    mkdir(config.eventfiles_dir);
    fprintf('Created EventFiles directory: %s\n', config.eventfiles_dir);
end

if ~exist(config.output_dir, 'dir')
    mkdir(config.output_dir);
    fprintf('Created output directory: %s\n', config.output_dir);
end

if ~exist(config.brainstorm_db_root, 'dir')
    mkdir(config.brainstorm_db_root);
    fprintf('Created Brainstorm database directory: %s\n', config.brainstorm_db_root);
end

%% ========== ADD PATHS ==========
addpath(config.scripts_dir);
addpath(fullfile(config.brainstorm_path, 'toolbox'));

% Add brainstorm to path (needed for brainstorm startup)
if ~exist('brainstorm', 'file')
    addpath(config.brainstorm_path);
end

fprintf('\n===== EEG Hyperscanning Analysis Configuration =====\n');
fprintf('Working directory:   %s\n', config.working_dir);
fprintf('Raw data path:       %s\n', config.raw_data_path);
fprintf('Brainstorm DB root:  %s\n', config.brainstorm_db_root);
fprintf('Protocol name:       %s\n', config.protocol_name);
fprintf('Channel file:        %s\n', config.channel_file);
fprintf('EventFiles:          %s\n', config.eventfiles_dir);
fprintf('Output directory:    %s\n', config.output_dir);
fprintf('====================================================\n\n');

%% ========== BRAINSTORM INITIALIZATION ==========
fprintf('Initializing Brainstorm...\n');

% Start Brainstorm without GUI (use 'brainstorm' for GUI mode)
if ~brainstorm('status')
    brainstorm nogui
end

% Set the database directory
bst_set('BrainstormDbDir', config.brainstorm_db_root);

% Check if protocol exists, if not create it
iProtocol = bst_get('Protocol', config.protocol_name);
if isempty(iProtocol)
    fprintf('Creating new protocol: %s\n', config.protocol_name);
    gui_brainstorm('CreateProtocol', config.protocol_name, 0, 0);
else
    fprintf('Loading existing protocol: %s\n', config.protocol_name);
    gui_brainstorm('SetCurrentProtocol', iProtocol);
end

fprintf('Brainstorm initialized successfully.\n');
fprintf('Database location: %s\n', bst_get('BrainstormDbDir'));

%% ========== SUBJECT CONFIGURATION ==========
% Uncomment the pairs you want to process

config.pairs = {
    'S01', 'S02';
    'S03', 'S04';
%     'S05', 'S06'; % S05 OUT for Alpha and FRN
    'S07', 'S08'; % S07 S08 OUT for Alpha, IN for FRN
    'S09', 'S10';
%     'S11', 'S12'; % S12 OUT for Alpha and FRN
    'S13', 'S14';
%     'S15', 'S16'; % S15 S16 OUT for Alpha and FRN
    'S17', 'S18';
    'S19', 'S20';
%     'S21', 'S22'; % S21 S22 OUT for Alpha and FRN
    'S23', 'S24';
};

% Melody names for each pair (which score combination)
config.melnames = [
    1,2,3,4; % pair 1 (S01-S02)
    3,4,1,2; % pair 2 (S03-S04)
%     1,2,3,4; % pair 3 (S05-S06)
    3,4,1,2; % pair 4 (S07-S08)
    1,2,3,4; % pair 5 (S09-S10)
%     3,4,1,2; % pair 6 (S11-S12)
    1,2,3,4; % pair 7 (S13-S14)
%     3,4,1,2; % pair 8 (S15-S16)
    1,2,3,4; % pair 9 (S17-S18)
    3,4,1,2; % pair 10 (S19-S20)
%     1,2,3,4; % pair 11 (S21-S22)
    3,4,1,2; % pair 12 (S23-S24)
];

config.players = {'SubA'; 'SubB'};

%% ========== ANALYSIS PIPELINE ==========
fprintf('\n===== Analysis Pipeline =====\n');
fprintf('Available steps:\n');
fprintf('  Step 0a: do_0a_bst_linkraw_DuetEx      - Link raw files to Brainstorm\n');
fprintf('  Step 0b: do_0b_bst_ssp_DuetEx          - SSP eye artifact detection\n');
fprintf('  Step 1a: do_1a_add_trigger_DuetEx      - Create event files\n');
fprintf('  Step 1b: do_1b_bst_import_trigger_DuetEx - Import triggers\n');
fprintf('  Step 1c: do_1c_bst_import_continuous_DuetEx - Import continuous data\n');
fprintf('  Step 1d: do_1d_bst_run_repair_steps_DuetEx - Repair data gaps\n');
fprintf('  Step 2a: do_2a_bst_epoch_avg_FRN_DuetEx - Epoch and average\n');
fprintf('  Step 3a: do_3a_export_data_FRN_DuetEx  - Export to MATLAB\n');
fprintf('  Step 4a: do_4a_analysis_FRN_DuetEx     - Analysis and plotting\n');
fprintf('=============================\n\n');

%% ========== RUN PIPELINE STEPS ==========
% Uncomment the steps you want to run:

% Step 0a: Link raw files to Brainstorm
run('do_0a_bst_linkraw_DuetEx.m');

% Step 0b: SSP eye artifact detection (requires manual review after)
% run('do_0b_bst_ssp_DuetEx.m');

% Step 1a: Create event files
% run('do_1a_add_trigger_DuetEx.m');

% Step 1b: Import triggers to Brainstorm
% run('do_1b_bst_import_trigger_DuetEx.m');

% Step 1c: Import continuous data with SSP applied
% run('do_1c_bst_import_continuous_DuetEx.m');

% Step 1d: Repair data gaps (10-second drift correction)
% run('do_1d_bst_run_repair_steps_DuetEx.m');

% Step 2a: Epoch and average FRN data
% run('do_2a_bst_epoch_avg_FRN_DuetEx.m');

% Step 3a: Export data to MATLAB workspace
% run('do_3a_export_data_FRN_DuetEx.m');

% Step 4a: Analysis and plotting (can run without Brainstorm)
% run('do_4a_analysis_FRN_DuetEx.m');

fprintf('Configuration complete. Uncomment pipeline steps above to run.\n');
