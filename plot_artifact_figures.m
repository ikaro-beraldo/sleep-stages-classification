function plot_artifact_figures(GMM,LFP,x,y,artifact,output_path,noise_inferior,noise_superior,figure_parameters,epoch_length)

%% Load the LFP_epochs data from the Output Path defined in the app 'recording_parameters'

% Get the full filename (path + file)
data_full_path = fullfile(output_path,'ALL_DATA.mat');
% If the file exists in the informed path
if isfile(data_full_path)
    
    % LOAD IT
    % Check if the data was saved using the struct mode
    listOfVariables = who('-file', data_full_path); % Get the list of variables inside it
    if ismember('LFP_epochs', listOfVariables) % Check if it has any of fields saved as variables
        DATA = load(data_full_path,'LFP_epochs','EMG_epochs','EMG_processed_sampling_frequency');    % Load only the necessary fields (only when save with the -struct option)
    else
        load(data_full_path,'DATA') % Default load (Slower)
        % Remove the extra fields
        fields = {'EMG_hour','EMG_raw_data','LFP_hour','LFP_raw_data'};
        DATA = rmfield(DATA,fields);
        clear fields
    end
    
else
    
    % OPEN A DIALOG BOX SO THE USER CAN SELECT THE FILE
    [file,path] = uigetfile('*.m','Select the data_variables file');
    if isfile(fullfile(file,path)) % Check if the file exists
        if ismember('LFP_epochs', who('-file', data_full_path)) % Check if it has any of fields saved as variables
            DATA = load(data_full_path,'LFP_epochs','EMG_epochs');    % Load only the necessary fields (only when save with the -struct option)
        else
            load(data_full_path,'DATA') % Default load (Slower)
            % Remove the extra fields
            fields = {'EMG_hour','EMG_raw_data','LFP_hour','LFP_raw_data'};
            DATA = rmfield(DATA,fields);
            clear fields
        end
    else % If the user has selected a wrong file
        finished = false;   % Informs that the ar
        return              % Finishes the function execution
    end
    
end

finished = true;    % If the loading of all the files went according to what was planned
%% Figures parameters

label_y='Theta/Delta (z-score)';

% General settings
figure_paramenters.transparecy_fa=.9;
figure_paramenters.limx=[-3 8];
figure_paramenters.limy=[-3 15];
figure_paramenters.Fidx=find(LFP.Frequency_distribution<=90);

% Over time figures
figure_paramenters.time_color=1:size(x,1);
figure_paramenters.smoothing_value=floor(size(x,1)/576);
figure_paramenters.time_scale=nan(size(x,1),1);
figure_paramenters.time_scale(1:360)=1;
figure_paramenters.axiss=1:length(x);

% Colors
figure_paramenters.color.awake=[0.9290, 0.6940, 0.1250];
figure_paramenters.color.nrem=[0 0.4470 0.7410];
figure_paramenters.color.rem=[0.3 0.3 0.3];
figure_paramenters.color.LFP=[0 0 .8];
figure_paramenters.color.EMG=[0.8500 0.3250 0.0980];
figure_paramenters.color.bar_plot=[0.4660 0.6740 0.1880];
figure_paramenters.color.scatter_color=[.5 .5 .5];
figure_paramenters.color.selected_color=[0.3010 0.7450 0.9330];

% Sizes
figure_paramenters.fontsize=20;
figure_paramenters.scatter_size=15;
figure_paramenters.edges=-3:0.1:6;
figure_paramenters.lw=2;

% Axis
figure_paramenters.GMM_Prob_axiss=0:0.03:0.06;
figure_paramenters.ticks_aux=-2:4:6;%% Detection artifact

% Frequencies omitted in figures
min_exclude = noise_inferior;
max_exclude = noise_superior;
figure_paramenters.exclude=find((min_exclude<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=max_exclude));
clc
clear min_exclude max_exclude


%% FIGURE: Clusters with artifacts

f1=figure('PaperSize', [21 29.7],'visible','off');
subplot(121)
scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
hold on
scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
hold off
ylabel(label_y);
xlabel([figure_parameters.emg_accel ' (z-score)']);
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('All States','FontSize',figure_paramenters.fontsize*1.2)

subplot(122)
scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
hold on
scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
aux_sc=scatter(x(artifact.LFP_epoch),y(artifact.LFP_epoch),figure_paramenters.scatter_size,...
    'r','o','Filled');
hold off
ylabel(label_y);
xlabel([figure_parameters.emg_accel ' (z-score)']);
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
legend(aux_sc,sprintf('Epochs with artifact \n%d found',length(artifact.LFP_epoch)),'Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Artifacts in the LFP','FontSize',figure_paramenters.fontsize*1.2)

sgtitle('Clusters and the artifacts','FontSize', 45)
set(gcf,'color',[1 1 1]);
print('-bestfit',fullfile(output_path,'Clusters and the artifacts'),'-dpdf','-r0',f1)

close
clear f1 aux*

%% Plotting random epoch with artifact - LFP

% Only plot a representative epoch with artifact when there is at least one
% Check if the artifact vector is empty (no artifacts were detected) or not
artifact.amp_noise = [artifact.amplitude];
if ~isempty(artifact.amp_noise)
    
    time1 = linspace(0,size(DATA.LFP_epochs,2)/LFP.FS,size(DATA.LFP_epochs,2));
    time2 = linspace(0,size(DATA.EMG_epochs,2)/DATA.EMG_processed_sampling_frequency,size(DATA.EMG_epochs,2));
    plot_epochs=artifact.amp_noise(randi(length(artifact.amp_noise)));    
    
    epoch_psd=LFP.Power_normalized(plot_epochs,figure_paramenters.Fidx);
    epoch_psd(figure_paramenters.exclude)=nan;
    
    fig=figure('PaperSize', [21 29.7],'visible','off');
    subplot(4,2,[1 2])
    plot(time1,DATA.LFP_epochs(plot_epochs,:),'Color',figure_paramenters.color.LFP);
    hold on
    yline(artifact.threshold_lfp*artifact.LFP_epoch_std(plot_epochs))
    yline(-artifact.threshold_lfp*artifact.LFP_epoch_std(plot_epochs))
    hold off
    ylim(figure_parameters.ylimits)
    yticks(linspace(figure_parameters.ylimits(1),figure_parameters.ylimits(2),3))
    ylabel({'LFP','(Amplitude)'})
    title(sprintf('%d seconds epoch',epoch_length))
    xticks([linspace(time1(1),time1(end),11)])
    xticklabels([linspace(time1(1),time1(end),11)])
    box off
    set(gca,'fontsize',figure_paramenters.fontsize)
    set(gca,'Linewidth',figure_paramenters.lw)
    set(gca,'Tickdir','out')
    legend ('Signal','Threshold','Location','best','Numcolumns',2)
    legend box off
    
    subplot(4,2,[3 4])
    plot(time2,DATA.EMG_epochs(plot_epochs,:),'Color',[0.6350 0.0780 0.1840]);
    if strcmp(figure_parameters.emg_accel,'Accel')
        ylim([0 1])
        yticks([0 0.5 1])
    else
        ylim(figure_parameters.ylimits)
        yticks(linspace(figure_parameters.ylimits(1),figure_parameters.ylimits(2),3))
    end
    
    ylabel({figure_parameters.emg_accel,'(Amplitude)'})
    xticks([linspace(time2(1),time2(end),11)])
    xticklabels([linspace(time2(1),time2(end),11)])
    box off
    set(gca,'fontsize',figure_paramenters.fontsize)
    set(gca,'Linewidth',figure_paramenters.lw)
    set(gca,'Tickdir','out')
    
    subplot(4,2,5)
    scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
        figure_paramenters.color.awake,'.');
    hold on
    scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
        figure_paramenters.color.nrem,'.');
    scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
        figure_paramenters.color.rem,'.');
    scatter(x(plot_epochs),y(plot_epochs),figure_paramenters.scatter_size*2,'r','o','filled');
    hold off
    xlim(figure_paramenters.limx)
    ylim(figure_paramenters.limy)
    legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
    legend box off
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylabel(label_y)
    set(gca,'fontsize',figure_paramenters.fontsize)
    set(gca,'Linewidth',figure_paramenters.lw)
    set(gca,'Tickdir','out')
    
    subplot(4,2,[6 8])
    loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd,10),...
        'Color','r','linewidth',figure_paramenters.lw*2);
    xlim([1 90])
    xticks([0 2 4 6 8 10 20 40 60 80]);
    ylim([.00001 0.1])
    yticks([.00001 .0001 .001 .01 0.1])
    xlabel('Frequency (Hz)')
    ylabel({'   PSD'; '(Power Norm.)'})
    box off
    legend('Hippocampus','location','southwest')
    legend box off
    set(gca,'fontsize',figure_paramenters.fontsize)
    set(gca,'Linewidth',figure_paramenters.lw)
    set(gca,'Tickdir','out')
    
    subplot(4,2,7)
    smo=15;
    plot(figure_paramenters.axiss,smooth(x+2,smo),'Color',figure_paramenters.color.EMG,'linewidth',.8)
    hold on
    plot(figure_paramenters.axiss,smooth(y+6,smo),'Color',figure_paramenters.color.LFP,'linewidth',.8)
    xline(figure_paramenters.axiss(plot_epochs),'k','linewidth',2);
    hold off
    box off
    ylim([-1 10])
    xlim([0 size(x,1)])
    yticks([mean(x+2) mean(y+6)])
    yticklabels({[figure_parameters.emg_accel ' (z-score)'],label_y})
    xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
    xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
    set(gca,'fontsize',figure_paramenters.fontsize)
    set(gca,'Linewidth',figure_paramenters.lw)
    set(gca,'Tickdir','out')
    
    text(figure_paramenters.axiss(plot_epochs)+50,9.5,'-> Epoch selected','fontsize',20)
    
    orient(fig,'portrait')
    set(gcf,'color','white')
    sgtitle('Representative Epoch with Artifact - LFP','fontsize',figure_paramenters.fontsize*2.2)
    print('-bestfit',fullfile(output_path,'Representative Epoch with Artifact - LFP'),'-dpdf','-r0',fig)
    close
    
    clear fig state in xv yv plot_epochs jj epoch_psd smo time line_plot scat
    close all
    
end
end