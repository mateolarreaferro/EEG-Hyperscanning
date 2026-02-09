% do_4a_2_plots.m
% Visual inspection plots. Run after do_4a_1_process.
% Close figures when done inspecting, then move on to do_4a_3_peaks.

%% Individual subject ERPs at Cz (Std vs Dev, SameHuman condition)
figure('Name','Individual Subjects - Cz');
for isubj=1:nsubj
    subplot(2,ceil(nsubj/2),isubj);
    plot(time, squeeze(dat_all(isubj,1,1,1,1,28,:))); % Std
    hold on;
    plot(time, squeeze(dat_all(isubj,1,1,1,2,28,:))); % Dev
    legend('Std','Dev');
    title(sprintf('%s',subjname_all{isubj}));
    xlabel('Time (s)');
end

%% Individual subject electrode-group waveforms (Std, Dev, Diff)
for isubj=1:nsubj
    figure('Name',sprintf('Subj %s - Electrode Groups',subjname_all{isubj}));
    for ielec=1:nelec
        subplot(1,nelec,ielec)
        hold on
        plot(time, squeeze(dat_elec_f2(isubj,1,1,1,1,ielec,:)));
        plot(time, squeeze(dat_elec_f2(isubj,1,1,1,2,ielec,:)));
        plot(time, squeeze(diff_elec_f2(isubj,1,1,1,ielec,:)),'--');
        legend('Std','Dev','Diff');
        title(sprintf('%s - %s',subjname_all{isubj},elec_list{ielec}));
        xlabel('Time (s)'); ylabel('\muV');
    end
end

%% Grand average with SE bands
figure('Name','Grand Average Difference - with SE');
imelody=1; iagency=1;
for ipartner=1:npartner
    for ielec=1:nelec
        subplot(npartner,nelec,(ipartner-1)*nelec+ielec);
        plot(time, squeeze(diff_elec_f2_GA(ipartner, imelody, iagency,ielec,:)),'LineWidth',2);
        hold on;
        plot(time, squeeze(diff_elec_f2_USE(ipartner, imelody, iagency,ielec,:)),'--','Color',[0.7 0.7 0.7]);
        plot(time, squeeze(diff_elec_f2_LSE(ipartner, imelody, iagency,ielec,:)),'--','Color',[0.7 0.7 0.7]);
        title(sprintf('%s - %s',partner{ipartner}, elec_list{ielec}));
        xlabel('Time (s)'); ylabel('\muV');
        grid on;
    end
end

%% ERP with t-test significance dots (Std vs Dev, all conditions)
ielec=1;
figure('Name','Std vs Dev - All Conditions');
isubplot=1;
k=-3.5;
for ipartner=1:2
    for imelody=1:2
        for iagency=1:2
            subplot(2,4,isubplot);
            dat_erp = squeeze(dat_elec_f2_GA(ipartner, imelody, iagency,1:2,ielec,:));
            dat_diff = squeeze(diff_elec_f2_GA(ipartner, imelody, iagency,ielec,:));
            h_dat = squeeze(st.SvD_h_all(ipartner, imelody, iagency,ielec,:));
            plot(time, dat_erp); hold on; grid on;
            plot(time, dat_diff,'--');
            indx=find(h_dat(it02+1:ntime));
            plot(time(indx+it02), k*h_dat(indx+it02),'ro','MarkerSize',3);
            axis([-0.1 0.5 -6 6])
            title(sprintf('%s-%s-%s', partner{ipartner}, melody{imelody}, agency{iagency}));
            xlabel('Time (s)'); ylabel('\muV');
            if isubplot==8; legend('Std','Dev','Diff','p<.05'); end
            isubplot=isubplot + 1;
        end
    end
end
print('/Volumes/MLF/EEG-Hyperscanning/output/fig_ERP_diff_fc6', '-dpng');

fprintf('\n=== Plots generated ===\n');
fprintf('Inspect the figures. When done: close all\n');
fprintf('Next: run do_4a_3_peaks\n');
