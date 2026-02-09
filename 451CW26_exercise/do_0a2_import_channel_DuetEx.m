% do_0a2_import_channel_DuetEx.m
% Import correct channel file for all subjects after linking raw files
% Run this after do_0a_bst_linkraw_DuetEx.m

% Path to the correct channel file
channelfile = "/Volumes/MLF/EEG-Hyperscanning/channel_initial.mat";

% List of subjects to process (must match what you ran in do_0a)
pair = {
    'S01', 'S02';
    'S03', 'S04';
};
npair = size(pair,1);

% Import channel file for each subject
for ipair = 1:npair
    sub = {pair{ipair,1}; pair{ipair,2}};

    for isubj = 1:2
        % Get all data files for this subject
        sFiles = bst_process('CallProcess', 'process_select_files_data', [], [], ...
            'subjectname', sub{isubj}, ...
            'tag', '');

        if ~isempty(sFiles)
            % Import channel file for this subject
            bst_process('CallProcess', 'process_import_channel', sFiles, [], ...
                'channelfile', {char(channelfile), 'BST'}, ...
                'usedefault', 0, ...
                'channelalign', 0, ...
                'fixunits', 1, ...
                'vox2ras', 1);

            fprintf('Imported channel file for subject %s\n', sub{isubj});
        else
            fprintf('No files found for subject %s\n', sub{isubj});
        end
    end
end

fprintf('Done! Channel files imported for all subjects.\n');
