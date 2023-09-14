function [artifact,finished] = artifacts_detection(EMG,LFP,output_path,amplitude_threshold,noise_inferior,noise_superior,figure_parameters)

% Details
% x = GMM.EMG_used;
% y = GMM.LFP_used;

x = nanzscore(EMG.RMS);
y = nanzscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
clear EMG


%% Load the LFP_epochs data from the Output Path defined in the app 'recording_parameters'

% Get the full filename (path + file)
data_full_path = fullfile(output_path,'ALL_DATA.mat');
% If the file exists in the informed path
if isfile(data_full_path)
    
    % LOAD IT
    % Check if the data was saved using the struct mode
    listOfVariables = who('-file', data_full_path); % Get the list of variables inside it
    if ismember('LFP_epochs', listOfVariables) % Check if it has any of fields saved as variables
        DATA = load(data_full_path,'LFP_epochs');    % Load only the necessary fields (only when save with the -struct option)
    else
        load(data_full_path,'DATA') % Default load (Slower)
        % Remove the extra fields
        fields = {'EMG_hour','EMG_raw_data','LFP_hour','LFP_raw_data','EMG_epochs'};
        DATA = rmfield(DATA,fields);
        clear fields
    end
    
else
    
    % OPEN A DIALOG BOX SO THE USER CAN SELECT THE FILE
    [file,path] = uigetfile('*.m','Select the data_variables file');
    if isfile(fullfile(file,path)) % Check if the file exists
        if ismember('LFP_epochs', who('-file', data_full_path)) % Check if it has any of fields saved as variables
            DATA = load(data_full_path,'LFP_epochs');    % Load only the necessary fields (only when save with the -struct option)
        else
            load(data_full_path,'DATA') % Default load (Slower)
            % Remove the extra fields
            fields = {'EMG_hour','EMG_raw_data','LFP_hour','LFP_raw_data','EMG_epochs'};
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
figure_paramenters.axiss=1:size(x,1);

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

%% Find epochs which have artifacts previously detected

artifact.previously_detected = find(isnan(DATA.LFP_epochs(:,1)));

%% Artifact detection - by amplitude

% Threshold selected as SD in amplitude
artifact.threshold_lfp = amplitude_threshold;
clear prompt

% Finding artifacts
aux_count_lfp=1;
aux_count_emg=1;

% Get the standard deviation of the each epoch
artifact.LFP_epoch_std = std(DATA.LFP_epochs,[],2);
% Find any sample which is higher than the threshold (compare each row with
% its threshold)
[artifact.amplitude_superior,~,~] = find(DATA.LFP_epochs >= artifact.LFP_epoch_std * artifact.threshold_lfp);
[artifact.amplitude_inferior,~,~] = find(DATA.LFP_epochs <= artifact.LFP_epoch_std * -artifact.threshold_lfp);
artifact.amplitude = unique([artifact.amplitude_superior; artifact.amplitude_inferior]);

%% Define amplitude threshold for each band frequency

% band_artifact.Theta = find(zscore(LFP.Frequency_bands.Theta) < -2);
% band_artifact.Delta = find(zscore(LFP.Frequency_bands.Delta) > 2);
% band_artifact.Beta = find(zscore(LFP.Frequency_bands.Beta) < -2.5);
% band_artifact.High_Gamma = find(zscore(LFP.Frequency_bands.High_Gamma) < -0.5);
% band_artifact.Low_Gamma = find(zscore(LFP.Frequency_bands.Low_Gamma) < -2);
% 
% % Final artifact
% band_artifact.unique = unique([band_artifact.Theta band_artifact.Beta band_artifact.Delta band_artifact.High_Gamma band_artifact.Low_Gamma]);
% artifact.band = band_artifact.unique';

%% Computing net noise

% Get the NOISE frequency range
aux_net_noise=find((noise_inferior<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=noise_superior));
% Get the NOISE/SIGNAL ratio
artifact.n_s_ratio = sum(LFP.Power_normalized(:,aux_net_noise),2)./sum(LFP.Power_normalized,2);

aux_net_noise = [find((noise_inferior<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=noise_superior));...
    find((noise_inferior*2+5<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=noise_superior*2-5));...
    find((noise_inferior*3+10<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=noise_superior*3-10));...
    find((noise_inferior*4+15<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=noise_superior*4-15));...
    find((noise_inferior*5+20<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=noise_superior*5-20))];
% Get the NOISE/SIGNAL ratio
artifact.n_s_ratio = sum(LFP.Power_normalized(:,aux_net_noise),2)./sum(LFP.Power_normalized,2);

% Select the epochs which the noise/signal ratio is higher than 15%
artifact.noise = find(zscore(artifact.n_s_ratio) >= 4);

%% Excluding epochs with artifacts

% Exclude epoch repetitions
artifact.LFP_epoch = unique([artifact.amplitude; artifact.noise; artifact.previously_detected]);

artifact.x_artifact_free=x;
artifact.x_artifact_free(artifact.LFP_epoch)=nan;
artifact.x_artifact_free = rmmissing(artifact.x_artifact_free);

artifact.y_artifact_free=y;
artifact.y_artifact_free(artifact.LFP_epoch)=nan;
artifact.y_artifact_free = rmmissing(artifact.y_artifact_free);


%% FIGURE: Noise to signal ratio
aux_nbins=50;
time=linspace(0,size(DATA.LFP_epochs,2)/LFP.FS,size(DATA.LFP_epochs,2));

[aux_max_M,aux_max_I] = max(artifact.n_s_ratio);
[aux_min_M,aux_min_I] = min(artifact.n_s_ratio);

epoch_psd_max=LFP.Power_normalized(aux_max_I,figure_paramenters.Fidx);
epoch_psd_max(figure_paramenters.exclude)=nan;

epoch_psd_min=LFP.Power_normalized(aux_min_I,figure_paramenters.Fidx);
epoch_psd_min(figure_paramenters.exclude)=nan;

f=figure('PaperSize', [21 29.7],'visible','off');
subplot(321)
histogram(artifact.n_s_ratio,aux_nbins,'Normalization','probability',...
    'FaceColor',[.6 .6 .6])
box off
ylabel('Probability')
xlabel('Noise/Signal ratio (%)')
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

aux_multi=1:length(artifact.n_s_ratio);
aux_multi=(aux_multi/10)';
subplot(322)
scatter(x,y,artifact.n_s_ratio.*aux_multi,artifact.n_s_ratio,'o','filled');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
ylabel({'Theta/Delta','(zscore)'});
xlabel([figure_parameters.emg_accel ' (z-score)'])
aux_c=colorbar;
colormap(jet);
aux_c.TickDirection='out';
aux_c.Label.String='Noise/Signal ratio (%)';
aux_c.LineWidth=figure_paramenters.lw;
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,[4 5])
plot(time,DATA.LFP_epochs(aux_max_I,:),'Color','r');
ylim(figure_parameters.ylimits)
yticks(linspace(figure_parameters.ylimits(1),figure_parameters.ylimits(2),3))
ylabel({'LFP','(Amplitude)'})
title('Highiest Noise/Signal ratio')
xticks([linspace(time(1),time(end),11)])
xticklabels('')
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,6)
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd_max,10),...
    'Color','r','linewidth',figure_paramenters.lw*2);
xlim([1 90])
xticks([0 2 4 6 8 10 20 40 60 80]);
ylim([.00001 0.1])
yticks([.00001 .0001 .001 .01 0.1])
xlabel('Frequency (Hz)')
ylabel('PSD (Power Norm.)')
box off
legend('Hippocampus','location','southwest')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,[7 8])
plot(time,DATA.LFP_epochs(aux_min_I,:),'Color','b');
ylim(figure_parameters.ylimits)
yticks(linspace(figure_parameters.ylimits(1),figure_parameters.ylimits(2),3))
ylabel({'LFP','(Amplitude)'})
title('Lowest Noise/Signal ratio')
xticks([linspace(time(1),time(end),11)])
xticklabels([linspace(time(1),time(end),11)])
xlabel('Time (s)')
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,9)
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd_min,10),...
    'Color','b','linewidth',figure_paramenters.lw*2);
xlim([1 90])
xticks([0 2 4 6 8 10 20 40 60 80]);
ylim([.00001 0.1])
yticks([.00001 .0001 .001 .01 0.1])
xlabel('Frequency (Hz)')
ylabel('PSD (Power Norm.)')
box off
legend('Hippocampus','location','southwest')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle({'Noise to signal ratio',''},'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit',fullfile(output_path,'Noise to signal ratio'),'-dpdf','-r0',f)

clear aux* time
close

%% FIGURE: Noise to signal ratio
aux_nbins=50;
time=linspace(0,size(DATA.LFP_epochs,2)/LFP.FS,size(DATA.LFP_epochs,2));

[aux_max_M,aux_max_I] = max(artifact.n_s_ratio);
[aux_min_M,aux_min_I] = min(artifact.n_s_ratio);

epoch_psd_max=LFP.Power_normalized(aux_max_I,figure_paramenters.Fidx);
epoch_psd_max(figure_paramenters.exclude)=nan;

epoch_psd_min=LFP.Power_normalized(aux_min_I,figure_paramenters.Fidx);
epoch_psd_min(figure_paramenters.exclude)=nan;

f=figure('PaperSize', [21 29.7],'visible','off');
subplot(321)
histogram(artifact.n_s_ratio,aux_nbins,'Normalization','probability',...
    'FaceColor',[.6 .6 .6])
box off
ylabel('Probability')
xlabel('Noise/Signal ratio (%)')
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

aux_multi=1:length(artifact.n_s_ratio);
aux_multi=(aux_multi/10)';
subplot(322)
scatter(x,y,artifact.n_s_ratio.*aux_multi,artifact.n_s_ratio,'o','filled');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
ylabel({'Theta/Delta','(zscore)'});
xlabel([figure_parameters.emg_accel ' (z-score)'])
aux_c=colorbar;
colormap(jet);
aux_c.TickDirection='out';
aux_c.Label.String='Noise/Signal ratio (%)';
aux_c.LineWidth=figure_paramenters.lw;
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,[4 5])
plot(time,DATA.LFP_epochs(aux_max_I,:),'Color','r');
ylim(figure_parameters.ylimits)
yticks(linspace(figure_parameters.ylimits(1),figure_parameters.ylimits(2),3))
ylabel({'LFP','(Amplitude)'})
title('Highiest Noise/Signal ratio')
xticks([linspace(time(1),time(end),11)])
xticklabels('')
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,6)
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd_max,10),...
    'Color','r','linewidth',figure_paramenters.lw*2);
xlim([1 90])
xticks([0 2 4 6 8 10 20 40 60 80]);
ylim([.00001 0.1])
yticks([.00001 .0001 .001 .01 0.1])
xlabel('Frequency (Hz)')
ylabel('PSD (Power Norm.)')
box off
legend('Hippocampus','location','southwest')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,[7 8])
plot(time,DATA.LFP_epochs(aux_min_I,:),'Color','b');
ylim(figure_parameters.ylimits)
yticks(linspace(figure_parameters.ylimits(1),figure_parameters.ylimits(2),3))
ylabel({'LFP','(Amplitude)'})
title('Lowest Noise/Signal ratio')
xticks([linspace(time(1),time(end),11)])
xticklabels([linspace(time(1),time(end),11)])
xlabel('Time (s)')
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,9)
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd_min,10),...
    'Color','b','linewidth',figure_paramenters.lw*2);
xlim([1 90])
xticks([0 2 4 6 8 10 20 40 60 80]);
ylim([.00001 0.1])
yticks([.00001 .0001 .001 .01 0.1])
xlabel('Frequency (Hz)')
ylabel('PSD (Power Norm.)')
box off
legend('Hippocampus','location','southwest')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle({'Noise to signal ratio',''},'fontsize',figure_paramenters.fontsize*2.2)
print('-fillpage',fullfile(output_path,'Noise to signal ratio (filling page)'),'-dpdf','-r0',f)

clear aux* time
close


end
