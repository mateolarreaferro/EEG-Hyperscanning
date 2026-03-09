% do_4a_4_export.m
% Extract amplitudes, write text file for R, save workspace, plot topomaps.
% Run after do_4a_3_peaks (needs itw_FRN and itw_P3a in workspace).

mydate='20260208';
outdir = '/Volumes/MLF/EEG-Hyperscanning/output';

%% Write amplitude values to text file for R
ielec=1;
filename = sprintf('%s/FRN_P3a_amp_%s.txt', outdir, mydate);
fid = fopen(filename,'w');
fprintf(fid, 'subjID\t partner\t melody\t agency\t elec\t FRN\t P3a\n');
for isubj=ssubj
    for ipartner=1:npartner
        for imelody=1:nmelody
            for iagency = 1:nagency
                fprintf(fid, '%s\t %s\t %s\t %s\t %s\t ', subjname_all{isubj}, partner{ipartner}, melody{imelody},agency{iagency}, elec_list{ielec});
                fprintf(fid, '%3.3f\t',squeeze(mean(diff_elec_f2(isubj, ipartner, imelody, iagency, ielec, itw_FRN),6)));
                fprintf(fid, '%3.3f\n',squeeze(mean(diff_elec_f2(isubj, ipartner, imelody, iagency, ielec, itw_P3a),6)));
            end
        end
    end
end
fclose(fid);
fprintf('Amplitude file written: %s\n', filename);

%% Save workspace
savefilename = sprintf('%s/Workspace_FRN_DuetEx_%s.mat', outdir, mydate);
save(savefilename, 'dat_all', 'dat_all_org', 'dat_all_scaled', 'dat_all_f', 'dat_all_f2', ...
    'dat_all_nf', 'diff_all_nf', 'diff_all_f', 'diff_all_f2', ...
    'dat_elec_nf', 'dat_elec_f', 'dat_elec_f2', 'diff_elec_nf', 'diff_elec_f', 'diff_elec_f2', ...
    'dat_elec_f2_GA', 'dat_elec_f2_SE', 'dat_elec_f2_USE', 'dat_elec_f2_LSE', ...
    'diff_elec_f2_GA', 'diff_elec_f2_SE', 'diff_elec_f2_USE', 'diff_elec_f2_LSE', ...
    'time', 'stim_name', 'subjname_all', 'nsubj', 'nstim', 'nchan', 'ntime', ...
    'partner', 'melody', 'agency', 'type', 'npartner', 'nmelody', 'nagency', 'ntype', ...
    'elec_list', 'nelec', 'ssubj', 'st', ...
    'itw_FRN', 'itw_P3a', 'tpkFRN', 'tpkP3a', 'itpkFRN', 'itpkP3a', ...
    'fc6', 'pzp2p4', 'it01', 'it02');
fprintf('Workspace saved: %s\n', savefilename);

%% Topomaps
fprintf('Plotting topomaps...\n');
for ipartner=1:npartner
    for imelody=1:nmelody
        for iagency=1:nagency
            % FRN
            FRN_minmax = [-2 2];
            xdat= squeeze(mean(mean(mean(diff_all_f2(ssubj,ipartner,imelody, iagency,1:64,itw_FRN),1),2),6));
            figure;
            rri_topoplot(xdat,{'maplimits',FRN_minmax})
            hcb=colorbar('eastoutside');
            hcb.Title.String='\muV';
            t = sprintf('%s-%s-%s-%s','FRN',partner{ipartner},melody{imelody},agency{iagency});
            title(t);
            print(sprintf('%s/%s', outdir, t),'-dpng')

            % P3a
            P3a_minmax = [-2 2];
            xdat= squeeze(mean(mean(mean(diff_all_f2(ssubj,ipartner,imelody,iagency,1:64,itw_P3a),1),2),6));
            figure;
            rri_topoplot(xdat,{'maplimits',P3a_minmax})
            hcb=colorbar('eastoutside');
            hcb.Title.String='\muV';
            t = sprintf('%s-%s-%s-%s','P3a',partner{ipartner},melody{imelody},agency{iagency});
            title(t);
            print(sprintf('%s/%s', outdir, t),'-dpng')
        end
    end
end

fprintf('\n=== All done! ===\n');
fprintf('Outputs in: %s\n', outdir);
fprintf('  - FRN_P3a_amp_%s.txt (for R stats)\n', mydate);
fprintf('  - Workspace_FRN_DuetEx_%s.mat\n', mydate);
fprintf('  - FRN/P3a topomap PNGs\n');
