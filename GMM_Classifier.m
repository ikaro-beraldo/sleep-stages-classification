%% Gaussian Mixture Model Classifier
% Developed by Renan Mendes, Ikaro Beraldo and Cleiton Aguiar - 2020
% This is an Sleep-wake cycle classifier algorithm
% Main input:
% Main output:
%
%
%
% IMPORTANT: All figures will be saved in '.pdf' files in your Current
% folder.

close all
clear
clc

%% Pre-processing data

clc
prompt = 'Do you need to pre-process your data? \nSelect: \n1 = Yes \n2 = No \n ';
ip=input(prompt);
if ip==1
    pre_processing;
    load data_variables.mat
elseif ip==2
    load data_variables.mat
end
clear prompt ip

%% Experimental or Control group?

clc
prompt = 'Experimental or Control? \nSelect: \n1 = Experimental \n2 = Control \n ';
ip=input(prompt);
if ip==1
    answer='Experimental';
elseif ip==2
    answer='Control';
end
clear prompt ip

%% Figures parameters

% Selecting data for EMG
x=zscore(EMG.RMS(1,:))';

% General settings
figure_paramenters.transparecy_fa=.9;
figure_paramenters.limx=[-3 8];
figure_paramenters.limy=[-3 14];

% Over time figures
figure_paramenters.time_color=1:size(x,1);
figure_paramenters.smoothing_value=15;
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
figure_paramenters.ticks_aux=-2:4:6;

% Frequency range in figures
figure_paramenters.Fidx=find(LFP.Frequency_distribution<=90);

% Frequencies omitted in figures
clc
prompt = 'What is the range of electrical noyse in your data? \nPlease type only the LOWER value. \n ';
min_exclude=input(prompt);
clc
prompt = 'What is the range of electrical noyse in your data? \nPlease type only the HIGHER value. \n ';
max_exclude=input(prompt);
exclude=find((min_exclude<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=max_exclude));
clc
clear prompt min_exclude max_exclude

% Defining time labels
clc
prompt = 'At which time of the day the recording started? \nPlease type only the hour \nExemple: If started 19:00, then type only 19\n ';
aux_begin=str2double(input(prompt,'s'));
clc
prompt = 'At which time of the day the recording end? \nPlease type only the hour \nExemple: If ended 14:00, then type only 14\n ';
aux_end=str2double(input(prompt,'s'));
clear prompt

% Time vector - Hour by hour
aux_figure_paramenters.time_vector = 1/24:1/24:24/24;
aux_figure_paramenters.time_vector = datestr(aux_figure_paramenters.time_vector,'HH:MM');
aux_figure_paramenters.time_vector = cellstr(aux_figure_paramenters.time_vector);

% Defining how the time labels will be
if aux_begin==aux_end %  ex: start 19:00 of day 1 -> end 19:00 of day 2
    figure_paramenters.time_vector=aux_figure_paramenters.time_vector(aux_begin:end);
    figure_paramenters.time_vector=cat(1,figure_paramenters.time_vector,aux_figure_paramenters.time_vector(1:aux_end));
    figure_over_time=2; % divide subplots over time in 2
    figure_paramenters.time_vector=cat(1,figure_paramenters.time_vector(1:3:25),figure_paramenters.time_vector(25)); % time label is every third hour
elseif aux_begin>aux_end % ex: start 19:00 of day 1 -> end 14:00 of day 2
    figure_paramenters.time_vector=aux_figure_paramenters.time_vector(aux_begin:end);
    figure_paramenters.time_vector=cat(1,figure_paramenters.time_vector,aux_figure_paramenters.time_vector(1:aux_end));
    figure_over_time=1; % divide subplots over time in 1
    if size(figure_paramenters.time_vector,1)>9 % if it lasts more than 9 hours
        figure_paramenters.time_vector=cat(1,figure_paramenters.time_vector(1:3:end),figure_paramenters.time_vector(end)); % time label is every third hour
        figure_over_time=2; % divide subplots over time in 2
    end % if not, then time label is every hour
else
    figure_paramenters.time_vector=aux_figure_paramenters.time_vector(aux_begin:aux_end); %  ex: start 10:00 of day 1 -> end 17:00 of day 1
    figure_over_time=1; % divide subplots over time in 1
    if size(figure_paramenters.time_vector,1)>9 % if it lasts more than 9 hours
        figure_paramenters.time_vector=cat(1,figure_paramenters.time_vector(1:3:end),figure_paramenters.time_vector(end)); % time label is every third hour
        figure_over_time=2; % divide subplots over time in 2
    end % if not, then time label is every hour
end

clear aux*

%% FIGURE: Frequency bands distribution

% Frequency bands
freq_aux_delta=zscore(LFP.Frequency_bands.Delta)';
freq_aux_theta=zscore(LFP.Frequency_bands.Theta)';
freq_aux_beta=zscore(LFP.Frequency_bands.Beta)';
freq_aux_low_gamma=zscore(LFP.Frequency_bands.Low_Gamma)';
freq_aux_high_gamma=zscore(LFP.Frequency_bands.High_Gamma)';

f=figure('PaperSize', [21 29.7]);
subplot(5,6,1)
histogram(freq_aux_delta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zDelta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,2)
scatter(freq_aux_theta,freq_aux_delta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_theta,freq_aux_delta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zTheta')
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,3)
scatter(freq_aux_beta,freq_aux_delta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_beta,freq_aux_delta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zBeta');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,4)
scatter(freq_aux_low_gamma,freq_aux_delta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_low_gamma,freq_aux_delta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zLow-Gamma');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,5)
scatter(freq_aux_high_gamma,freq_aux_delta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_high_gamma,freq_aux_delta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zHigh-Gamma');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,6)
scatter(x,freq_aux_delta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
xlabel('zEMG');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,8)
histogram(freq_aux_theta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zTheta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,9)
scatter(freq_aux_beta,freq_aux_theta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_beta,freq_aux_theta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zBeta');
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,10)
scatter(freq_aux_low_gamma,freq_aux_theta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_low_gamma,freq_aux_theta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zLow-Gamma');
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,11)
scatter(freq_aux_high_gamma,freq_aux_theta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_high_gamma,freq_aux_theta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zHigh-Gamma');
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,12)
scatter(x,freq_aux_theta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
xlabel('zEMG')
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,15)
histogram(freq_aux_beta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zBeta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,16)
scatter(freq_aux_low_gamma,freq_aux_beta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_low_gamma,freq_aux_beta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zLow-Gamma')
ylabel('zBeta');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,17)
scatter(freq_aux_high_gamma,freq_aux_beta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_high_gamma,freq_aux_beta);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zHigh-Gamma')
ylabel('zBeta');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,18)
scatter(x,freq_aux_beta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
xlabel('zEMG')
ylabel('zBeta');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,22)
histogram(freq_aux_low_gamma,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zLow-Gamma')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,23)
scatter(freq_aux_high_gamma,freq_aux_low_gamma,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corr(freq_aux_high_gamma,freq_aux_low_gamma);
text(2,8,...
    ['r = ' num2str(rho) ...
    '\newlinep = ' num2str(pval)],...
    'fontsize',figure_paramenters.fontsize)
xlabel('zHigh-Gamma');
ylabel('zLow-Gamma')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,24)
scatter(x,freq_aux_low_gamma,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
xlabel('zEMG');
ylabel('zLow-Gamma')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,29)
histogram(freq_aux_high_gamma,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zHigh-Gamma')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(5,6,30)
scatter(x,freq_aux_high_gamma,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('zHigh-Gamma')
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['Frequency bands distribution - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-fillpage','Frequency bands distribution','-dpdf','-r0',f)

close
clear f line pval rho line

%% FIGURE: Frequency bands distribution over time

f=figure('PaperSize', [21 29.7]);
for jj=1:figure_over_time
    subplot(2,1,1)
    plot(smooth(freq_aux_delta(1:end/figure_over_time),figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
    hold on
    plot(smooth(freq_aux_theta(1:end/figure_over_time)+3,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
    plot(smooth(freq_aux_beta(1:end/figure_over_time)+6,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
    plot(smooth(freq_aux_low_gamma(1:end/figure_over_time)+9,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
    plot(smooth(freq_aux_high_gamma(1:end/figure_over_time)+12,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
    plot(figure_paramenters.time_scale+13.5,'-k','LineWidth',figure_paramenters.lw*2,'HandleVisibility','off');
    text(1,15.2,'1 hour','fontsize',figure_paramenters.fontsize)
    hold off
    box off
    ylim([-3 16])
    xlim([1 size(x,1)/figure_over_time+1])
    yticks([mean(freq_aux_delta) mean(freq_aux_theta+3) mean(freq_aux_beta+6) mean(freq_aux_low_gamma+9) mean(freq_aux_high_gamma+12)])
    yticklabels({'zDelta','zTheta','zBeta','zLow-Gamma','zHigh-Gamma'})
    xticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
    xticklabels(figure_paramenters.time_vector(1:end/figure_over_time+1));
    set(gca,'fontsize',figure_paramenters.fontsize)
    set(gca,'Linewidth',figure_paramenters.lw)
    set(gca,'Tickdir','out')
    
    if figure_over_time==2
        subplot(2,1,2)
        plot(smooth(freq_aux_delta(end/2:end),figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
        hold on
        plot(smooth(freq_aux_theta(end/2:end)+3,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
        plot(smooth(freq_aux_beta(end/2:end)+6,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
        plot(smooth(freq_aux_low_gamma(end/2:end)+9,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
        plot(smooth(freq_aux_high_gamma(end/2:end)+12,figure_paramenters.smoothing_value),'linewidth',figure_paramenters.lw)
        plot(figure_paramenters.time_scale+13.5,'-k','LineWidth',figure_paramenters.lw*2,'HandleVisibility','off');
        text(1,15.2,'1 hour','fontsize',figure_paramenters.fontsize)
        hold off
        box off
        ylim([-3 16])
        xlim([1 size(x,1)/figure_over_time+1])
        yticks([mean(freq_aux_delta) mean(freq_aux_theta+3) mean(freq_aux_beta+6) mean(freq_aux_low_gamma+9) mean(freq_aux_high_gamma+12)])
        yticklabels({'zDelta','zTheta','zBeta','zLow-Gamma','zHigh-Gamma'})
        xticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
        xticklabels(figure_paramenters.time_vector(end/2:end));
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
    end
end

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['Frequency bands distribution over time - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','Frequency bands distribution over time','-dpdf','-r0',f)

close
clear f jj

%% FIGURE: Frequency bands combined

% Frequency bands combined
freq_aux_t_d=zscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusb_delta=zscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta)./LFP.Frequency_bands.Delta);
freq_aux_tpluslg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusbpluslg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplushg_d=zscore(LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusbplushg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tpluslgplushg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusbpluslgplushg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta./LFP.Frequency_bands.Delta);

f=figure('PaperSize', [21 29.7]);
subplot(3,5,1)
scatter(x,freq_aux_t_d,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(Theta/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Only z(Theta/Delta)')

subplot(3,5,2)
scatter(x,freq_aux_tplusb_delta,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(Theta+Beta/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Adding Beta')

subplot(3,5,3)
scatter(x,freq_aux_tpluslg_d,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(Theta+Low Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Adding Low Gamma')

subplot(3,5,8)
scatter(x,freq_aux_tplusbpluslg_d,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(Theta+Beta+Low Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,5,4)
scatter(x,freq_aux_tplushg_d,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(Theta+High Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Adding High Gamma')

subplot(3,5,9)
scatter(x,freq_aux_tplusbplushg_d,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(Theta+Beta+High Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,5,14)
scatter(x,freq_aux_tpluslgplushg_d,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(Theta+Low Gamma+High Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,5,5)
scatter(x,freq_aux_tplusbpluslgplushg_d,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel('z(6 to 90Hz/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('z(6 to 90Hz/Delta)')

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['Frequency bands combined - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-fillpage','Frequency bands combined','-dpdf','-r0',f)

close
clear f

%% Preparing data

% Selecting data for Hippocampus
clc
disp 'Our default mode for the classification is using hippocampal Theta/Delta ratio.'
prompt = 'Would you like to add other frequency bands for the classification? Which ones? \n0 = None \n1 = Add Beta  \n2 = Add Low Gamma \n3 = Add High Gamma \n4 = Add all Gamma range \n5 = Use 6 to 90 Hz/ Delta \n ';
ip=input(prompt);
if ip==0
    y=zscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta)';
    label_y='zT/D';
    numerator=zscore(LFP.Frequency_bands.Theta);
    numerator_label='zTheta';
    rest_numerator=numerator;
    rest_numerator_label=numerator_label;
    denominator=zscore(LFP.Frequency_bands.Delta);
    denominator_label='zDelta';
elseif ip==1
    y=zscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta)./LFP.Frequency_bands.Delta)';
    label_y='zTBD';
    numerator=zscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta);
    numerator_label='z(Theta + Beta)';
    rest_numerator=zscore(LFP.Frequency_bands.Beta./LFP.Frequency_bands.Delta)';
    rest_numerator_label='z(Beta/Delta)';
    denominator=LFP.Frequency_bands.Delta;
    denominator_label='zDelta';
elseif ip==2
    y=zscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Low_Gamma)./LFP.Frequency_bands.Delta)';
    label_y='zTLGD';
    numerator=zscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.Low_Gamma);
    numerator_label='z(Theta + Low Gamma)';
    rest_numerator=zscore(LFP.Frequency_bands.Low_Gamma./LFP.Frequency_bands.Delta)';
    rest_numerator_label='z(Low Gamma/Delta)';
    denominator=LFP.Frequency_bands.Delta;
    denominator_label='zDelta';
elseif ip==3
    y=zscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
    label_y='zTHGD';
    numerator=zscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma);
    numerator_label='z(Theta + High Gamma)';
    rest_numerator=zscore(LFP.Frequency_bands.High_Gamma./LFP.Frequency_bands.Delta)';
    rest_numerator_label='z(High Gamma/Delta)';
    denominator=LFP.Frequency_bands.Delta;
    denominator_label='zDelta';
elseif ip==4
    y=zscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
    label_y='zTGD';
    numerator=zscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma);
    numerator_label='z(Theta + Gamma)';
    rest_numerator=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma./LFP.Frequency_bands.Delta)';
    rest_numerator_label='z(Gamma/Delta)';
    denominator=LFP.Frequency_bands.Delta;
    denominator_label='zDelta';
elseif ip==5
    y=zscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
    label_y='z(6 to 90Hz/Delta)';
    numerator=zscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)';
    numerator_label='z(6 to 90Hz)';
    rest_numerator=zscore((LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
    rest_numerator_label='z(10 to 90Hz)';
    denominator=LFP.Frequency_bands.Delta;
    denominator_label='zDelta';
end
clear prompt ip

% Combining data
data_combined=[x y];

%% FIGURE: Selected Frequency bands

f=figure('PaperSize', [21 29.7]);
subplot(3,3,[1 2 4 5])
scatter(x,y,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel(label_y);
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Final Distribution','fontsize',figure_paramenters.fontsize*1.5)

subplot(3,3,3)
scatter(rest_numerator,freq_aux_t_d,...
    figure_paramenters.scatter_size,figure_paramenters.color.selected_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corrcoef(rest_numerator,freq_aux_t_d);
text(-2,7,...
    ['r = ' num2str(rho(2)) ...
    '\newline p = ' num2str(pval(2))],...
    'fontsize',figure_paramenters.fontsize)
ylabel('z(Theta/Delta)')
xlabel(rest_numerator_label)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,6)
scatter(denominator,numerator,...
    figure_paramenters.scatter_size,figure_paramenters.color.selected_color,'.');
line=lsline;
line.LineWidth =1.2;
line.Color ='k';
[rho,pval] = corrcoef(denominator,numerator);
text(2,8,...
    ['r = ' num2str(rho(2)) ...
    '\newline p = ' num2str(pval(2))],...
    'fontsize',figure_paramenters.fontsize)
ylabel(numerator_label)
xlabel(denominator_label)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,9)
histogram(freq_aux_delta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zDelta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,10)
histogram(freq_aux_theta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
xlabel('Z-scores')
title('zTheta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,11)
histogram(numerator,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
xlabel('Z-scores')
title(numerator_label)
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,12)
histogram(x,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
xlabel('Z-scores')
title('zEMG')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['Selected frequency bands - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-fillpage','Selected frequency bands','-dpdf','-r0',f)

close
clear f line freq_aux* denominator* numerator* rest_numerator* pval rho line

%% FIGURE: Data distribution

f=figure('PaperSize', [21 29.7]);
subplot(321)
scatter(x,y,figure_paramenters.scatter_size,figure_paramenters.color.scatter_color,'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
yticks(figure_paramenters.limy(1)+1:2:16)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,2,[2 4])
scatter3(x,y,figure_paramenters.time_color,figure_paramenters.scatter_size,figure_paramenters.time_color,'.');
ylabel(label_y);
xlabel('zEMG');
zlabel('Time of recording');
colormap(copper)
c=colorbar('Ticks',[1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)],...
    'TickLabels',figure_paramenters.time_vector,'FontSize',figure_paramenters.fontsize,'TickDirection','out',...
    'LineWidth',figure_paramenters.lw,'Location','southoutside');
c.Label.String='Time of recording';
c.Label.FontSize = figure_paramenters.fontsize;
zticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
zticklabels('')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('On a scatter plot over time')

subplot(3,4,5)
histogram(y,figure_paramenters.edges,'FaceColor',figure_paramenters.color.LFP,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
xlim([-2 6])
ylim([0 .3])
yticks(0:.1:.3)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title(label_y,'FontSize',figure_paramenters.fontsize*1.2)

subplot(3,4,6)
histogram(x,figure_paramenters.edges,'FaceColor',figure_paramenters.color.EMG,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
xlabel('Z-scores')
xlim([-2 6])
ylim([0 .3])
yticks(0:.1:.3)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('zEMG','FontSize',figure_paramenters.fontsize*1.2)

subplot(3,2,[5 6])
plot(figure_paramenters.axiss,smooth(x+2,figure_paramenters.smoothing_value),'Color',figure_paramenters.color.EMG,'linewidth',figure_paramenters.lw)
hold on
plot(figure_paramenters.axiss,smooth(y+6,figure_paramenters.smoothing_value),'Color',figure_paramenters.color.LFP,'linewidth',figure_paramenters.lw)
plot(figure_paramenters.time_scale+8.5,'-k','LineWidth',figure_paramenters.lw*2,'HandleVisibility','off');
text(1,10,'1 hour','fontsize',figure_paramenters.fontsize)
hold off
box off
ylim([-1 10])
xlim([0 size(x,1)])
yticks([mean(y+2) mean(x+6)])
yticklabels({'zEMG',label_y})
xticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
xticklabels(figure_paramenters.time_vector);
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Variables scores over time','FontSize',figure_paramenters.fontsize*1.2)

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['Data distribution - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-fillpage','Data distribution','-dpdf','-r0',f)

close
clear f c

%% Running Visual Inspection

clc
prompt = 'Do you want to run the Visual Inpection?  \n1 = Yes \n2 = No \n ';
ip=input(prompt);
clc
if ip==1
    disp 'It might take a bit long because the epochs are being loaded'
    Visual_inspection = Visual_Inspection (LFP,x,y,label_y);
elseif ip==2
    load IDX_Visual_Inspection.mat
end
clear prompt ip

%% FIGURE: Visual Inspected data distribution

% Plotting Visually Inspected data's PSD
aux_vi_awa_Pxx_all_24=mean(LFP.Power_normalized(Visual_inspection.AWAKE_idx,figure_paramenters.Fidx),1);
aux_vi_awa_Pxx_all_24(exclude)=nan;
aux_vi_sw_Pxx_all_24=mean(LFP.Power_normalized(Visual_inspection.NREM_idx,figure_paramenters.Fidx),1);
aux_vi_sw_Pxx_all_24(exclude)=nan;
aux_vi_rem_Pxx_all_24=mean(LFP.Power_normalized(Visual_inspection.REM_idx,figure_paramenters.Fidx),1);
aux_vi_rem_Pxx_all_24(exclude)=nan;

% To plot the Visually Inspected data over time
aux_vi_awa=zeros(1,size(x,1));
aux_vi_awa(Visual_inspection.AWAKE_idx)=1;
aux_vi_sws=zeros(1,size(x,1));
aux_vi_sws(Visual_inspection.NREM_idx)=1;
aux_vi_rem=zeros(1,size(x,1));
aux_vi_rem(Visual_inspection.REM_idx)=1;
aux_plot=1:8640;

f=figure('PaperSize', [21 29.7]);
subplot(221)
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(aux_vi_awa_Pxx_all_24,10),'Color',figure_paramenters.color.awake,'linewidth',figure_paramenters.lw);
hold on
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(aux_vi_sw_Pxx_all_24,10),'Color',figure_paramenters.color.nrem,'linewidth',figure_paramenters.lw);
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(aux_vi_rem_Pxx_all_24,10),'Color',figure_paramenters.color.rem,'linewidth',figure_paramenters.lw);
hold off
xlim([1 80])
ylim([min(aux_vi_rem_Pxx_all_24)*3 max(aux_vi_rem_Pxx_all_24)*2]);
xlabel('Frequency (log)')
ylabel('Power (log)')
set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
box off
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Power Spectrum Density','FontSize',figure_paramenters.fontsize*1.2)

subplot(222)
scatter(x(Visual_inspection.AWAKE_idx),y(Visual_inspection.AWAKE_idx),...
    figure_paramenters.scatter_size,figure_paramenters.color.awake,'.');
hold on
scatter(x(Visual_inspection.NREM_idx),y(Visual_inspection.NREM_idx),...
    figure_paramenters.scatter_size,figure_paramenters.color.nrem,'.');
scatter(x(Visual_inspection.REM_idx),y(Visual_inspection.REM_idx),...
    figure_paramenters.scatter_size,figure_paramenters.color.rem,'.');
hold off
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
box off
legend ('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Scatter plot','FontSize',figure_paramenters.fontsize*1.2)

subplot(2,2,[3 4])
plot(aux_plot,aux_vi_awa+4,'color',figure_paramenters.color.awake,'LineWidth',figure_paramenters.lw)
hold on
plot(aux_plot,aux_vi_sws+2,'color',figure_paramenters.color.nrem,'LineWidth',figure_paramenters.lw)
plot(aux_plot,aux_vi_rem,'color',figure_paramenters.color.rem,'LineWidth',figure_paramenters.lw)
hold off
box off
ylim([-1 6])
xlim([0 size(x,1)])
yticks([mean(aux_vi_rem) mean(aux_vi_sws+2) mean(aux_vi_awa+4)])
yticklabels({'REM','NREM','AWAKE'})
xticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):...
    size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
xticklabels(figure_paramenters.time_vector);
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Epochs selected','FontSize',figure_paramenters.fontsize*1.2)

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['Visually Inspected Data distribution - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','Visually Inspected data distribution','-dpdf','-r0',f)

close
clear f aux*

%% Running the untrained Gaussian Mixture Model and training epochs

% Setting number of clusters (states)
number_clusters=3;
a=1;

while a==1
    % GMM without training: Starting with K-means
    aux_GMM.fitted = fitgmdist(data_combined,number_clusters);
    
    % Computing Posterior GMM.Probability to each time bin
    [aux_GMM.Prob,aux_GMM.nlogL] = posterior(aux_GMM.fitted,data_combined);
    
    set(0,'DefaultFigureWindowStyle','docked')
    figure;
    for jj=1:number_clusters
        subplot(2,2,jj);
        scatter(x,y,figure_paramenters.scatter_size,aux_GMM.Prob(:,jj),'.');
        ylabel(label_y);
        xlabel('zEMG');
        caxis([0 1])
        axis([0.1 0.6 0 4])
        xlim(figure_paramenters.limx)
        ylim(figure_paramenters.limy)
        
        subplot(2,2,number_clusters+1)
        c=colorbar;
        colormap(jet);
        c.Location='north';
        s=get(c,'position');
        c.Position=[s(1) s(2)/1.5 s(3) s(4)];
        axis off
        text(s(1)-s(1)*.5,s(2)*1.8,'Posterior GMM.Probability');
        
        set(gcf,'color','white')
        sgtitle(['Gaussian Mixture Model: Unsupervisioned clustering - ' answer])
    end
    
    clc
    prompt = 'Is the best clustering?  \n1 = Yes \n2 = No \n ';
    ip=input(prompt);
    if ip==1
        a=2;
        close
    elseif ip==2
        close
    end
    clear prompt ip
    
end
set(0,'DefaultFigureWindowStyle','normal')
clear c s a jj

%% Training epochs

clc
prompt = 'Do you want to train epochs? \n1 = Yes \n2 = No \n ';
ip=input(prompt);
clc
if ip==1
    disp 'It might take a bit long because the epochs are being loaded'
    Training_data = Train_Model (LFP,x,y,label_y,aux_GMM,Visual_inspection);
elseif ip==2
    load('Trained_data.mat')
end
clear prompt ip aux*

%% FIGURE: Trained data distribution

% Plotting Training data's PSD
aux_tr_awa_Pxx_all_24=mean(LFP.Power_normalized(Training_data.Awake,figure_paramenters.Fidx),1);
aux_tr_awa_Pxx_all_24(exclude)=nan;
aux_tr_sw_Pxx_all_24=mean(LFP.Power_normalized(Training_data.NREM,figure_paramenters.Fidx),1);
aux_tr_sw_Pxx_all_24(exclude)=nan;
aux_tr_rem_Pxx_all_24=mean(LFP.Power_normalized(Training_data.REM,figure_paramenters.Fidx),1);
aux_tr_rem_Pxx_all_24(exclude)=nan;

% To plot the Training data over time
aux_tr_awa=zeros(1,size(x,1));
aux_tr_awa(Training_data.Awake)=1;
aux_tr_sws=zeros(1,size(x,1));
aux_tr_sws(Training_data.NREM)=1;
aux_tr_rem=zeros(1,size(x,1));
aux_tr_rem(Training_data.REM)=1;
aux_plot=1:8640;

f=figure('PaperSize', [21 29.7]);
subplot(221)
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(aux_tr_awa_Pxx_all_24,10),'Color',figure_paramenters.color.awake,'linewidth',figure_paramenters.lw);
hold on
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(aux_tr_sw_Pxx_all_24,10),'Color',figure_paramenters.color.nrem,'linewidth',figure_paramenters.lw);
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(aux_tr_rem_Pxx_all_24,10),'Color',figure_paramenters.color.rem,'linewidth',figure_paramenters.lw);
hold off
xlim([1 80])
ylim([min(aux_tr_rem_Pxx_all_24)*3 max(aux_tr_rem_Pxx_all_24)*2]);
xlabel('Frequency (log)')
ylabel('Power (log)')
set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
box off
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Power Spectrum Density','FontSize',figure_paramenters.fontsize*1.2)

subplot(222)
scatter(x(Training_data.Awake),y(Training_data.Awake),figure_paramenters.scatter_size,figure_paramenters.color.awake,...
    '.');
hold on
scatter(x(Training_data.NREM),y(Training_data.NREM),figure_paramenters.scatter_size,figure_paramenters.color.nrem,...
    '.');
scatter(x(Training_data.REM),y(Training_data.REM),figure_paramenters.scatter_size,figure_paramenters.color.rem,...
    '.');
hold off
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
box off
legend ('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Scatter plot','FontSize',figure_paramenters.fontsize*1.2)

subplot(2,2,[3 4])
plot(aux_plot,aux_tr_awa+4,'color',figure_paramenters.color.awake,'LineWidth',figure_paramenters.lw)
hold on
plot(aux_plot,aux_tr_sws+2,'color',figure_paramenters.color.nrem,'LineWidth',figure_paramenters.lw)
plot(aux_plot,aux_tr_rem,'color',figure_paramenters.color.rem,'LineWidth',figure_paramenters.lw)
hold off
box off
ylim([-1 6])
xlim([0 size(x,1)])
yticks([mean(aux_tr_rem) mean(aux_tr_sws+2) mean(aux_tr_awa+4)])
yticklabels({'REM','NREM','AWAKE'})
xticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
xticklabels(figure_paramenters.time_vector);
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Epochs selected','FontSize',figure_paramenters.fontsize*1.2)

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['Training Data distribution - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','Training data distribution','-dpdf','-r0',f)

close
clear f aux*

%% Fitting the Trained data to Gaussian Mixture parameters

aux_tr_awa_GMM_fitted = fitgmdist([x(Training_data.Awake) y(Training_data.Awake)],1);
aux_tr_sws_GMM_fitted = fitgmdist([x(Training_data.NREM) y(Training_data.NREM)],1);
aux_tr_rem_GMM_fitted = fitgmdist([x(Training_data.REM) y(Training_data.REM)],1);

% GMM parameters (Component proportion, Sigma and Mu)
fitted_GMM.ComponentProportion=cat(2,aux_tr_awa_GMM_fitted.ComponentProportion...
    ,aux_tr_sws_GMM_fitted.ComponentProportion,aux_tr_rem_GMM_fitted.ComponentProportion);
fitted_GMM.Sigma=cat(3,aux_tr_awa_GMM_fitted.Sigma,aux_tr_sws_GMM_fitted.Sigma,aux_tr_rem_GMM_fitted.Sigma);
fitted_GMM.mu=cat(1,aux_tr_awa_GMM_fitted.mu,aux_tr_sws_GMM_fitted.mu,aux_tr_rem_GMM_fitted.mu);

% Running trained GMM
GMM.GMM_distribution = fitgmdist(data_combined,number_clusters,...
    'Start',fitted_GMM);

% Computing Posterior GMM.Probability to each time bin
[GMM.Prob.All,GMM.nlogL] = posterior(GMM.GMM_distribution,data_combined);

clear tr_* fitted_GMM aux*

%% FIGURE: GMM clusters

f=figure('PaperSize', [21 29.7]);
subplot(221)
scatter(x,y,figure_paramenters.scatter_size,GMM.Prob.All(:,1),'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(222)
scatter(x,y,figure_paramenters.scatter_size,GMM.Prob.All(:,2),'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(223)
scatter(x,y,figure_paramenters.scatter_size,GMM.Prob.All(:,3),'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(224)
c=colorbar;
colormap(jet);
c.Location='north';
s=get(c,'position');
c.Position=[s(1) s(2)/1.5 s(3) s(4)];
axis off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
text(s(1)-s(1)*.6,s(2)*1.8,'Posterior GMM.Probability','FontSize',figure_paramenters.fontsize*1.2);

set(gcf,'color','white')
set(f,'PaperPositionMode','auto')
sgtitle(['GMM Clusters - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','GMM Clusters','-dpdf','-r0',f)

close
clear f s c

%% Defining clusters as states

% Defining the GMM.Probability distribution for each state
aux_idx1=find(GMM.Prob.All(:,1)>.9);
aux_idx2=find(GMM.Prob.All(:,2)>.9);
aux_idx3=find(GMM.Prob.All(:,3)>.9);

aux_x1=max(x(aux_idx1));
aux_x2=max(x(aux_idx2));
aux_x3=max(x(aux_idx3));

aux_y1=max(y(aux_idx1));
aux_y2=max(y(aux_idx2));
aux_y3=max(y(aux_idx3));

% WK (All_Sort = 3)
if aux_x1>aux_x2 && aux_x1>aux_x3
    GMM.Prob.AWAKE=GMM.Prob.All(:,1);
elseif aux_x2>aux_x1 && aux_x2>aux_x3
    GMM.Prob.AWAKE=GMM.Prob.All(:,2);
else
    GMM.Prob.AWAKE=GMM.Prob.All(:,3);
end

% NREM (AllSort = 2)
if aux_y1<aux_y2 && aux_y1<aux_y3
    GMM.Prob.NREM=GMM.Prob.All(:,1);
elseif aux_y2<aux_y1 && aux_y2<aux_y3
    GMM.Prob.NREM=GMM.Prob.All(:,2);
else
    GMM.Prob.NREM=GMM.Prob.All(:,3);
end

% REM (AllSort = 1)
if aux_y1>aux_y2 && aux_y1>aux_y3
    GMM.Prob.REM=GMM.Prob.All(:,1);
elseif aux_y2>aux_y1 && aux_y2>aux_y3
    GMM.Prob.REM=GMM.Prob.All(:,2);
else
    GMM.Prob.REM=GMM.Prob.All(:,3);
end

clear aux_idx*

%% Calculating ROC curve in comparison with Visual Inspection data
T=0:0.00001:1;

% Preallocating variables
GMM.All_Threshold.TP_AWK=zeros(1,size(T,2));
GMM.All_Threshold.FP_AWK=zeros(1,size(T,2));
GMM.All_Threshold.TP_SWS=zeros(1,size(T,2));
GMM.All_Threshold.FP_SWS=zeros(1,size(T,2));
GMM.All_Threshold.TP_REM=zeros(1,size(T,2));
GMM.All_Threshold.FP_REM=zeros(1,size(T,2));

% Calculating TP and FP for all possible thresholds
for i=1:size(T,2)
    
    GMM_WK=GMM.Prob.AWAKE>T(i);
    
    positive_true_condition=nan(size(GMM.Prob.AWAKE,1),1);
    positive_true_condition(Visual_inspection.AWAKE_idx)=1;
    
    positive_predicted_condition=nan(size(GMM.Prob.AWAKE,1),1);
    positive_predicted_condition(GMM_WK==1)=1;
    
    negative_true_condition=nan(size(GMM.Prob.AWAKE,1),1);
    negative_true_condition(Visual_inspection.NREM_idx)=1;
    negative_true_condition(Visual_inspection.REM_idx)=1;
    
    negative_predicted_condition=nan(size(GMM.Prob.AWAKE,1),1);
    negative_predicted_condition(GMM_WK==0)=1;
    
    tp=size(find(positive_true_condition == positive_predicted_condition),1);
    fp=size(find(negative_true_condition == positive_predicted_condition),1);
    tn=size(find(negative_true_condition == negative_predicted_condition),1);
    fn=size(find(positive_true_condition == negative_predicted_condition),1);
    
    GMM.All_Threshold.TP_AWK(i)=tp/(tp+fn);
    GMM.All_Threshold.FP_AWK(i)=fp/(fp+tn);
end

for i=1:size(T,2)
    
    GMM_SWS=GMM.Prob.NREM>T(i);
    
    positive_true_condition=nan(size(GMM.Prob.NREM,1),1);
    positive_true_condition(Visual_inspection.NREM_idx)=1;
    
    positive_predicted_condition=nan(size(GMM.Prob.NREM,1),1);
    positive_predicted_condition(GMM_SWS==1)=1;
    
    negative_true_condition=nan(size(GMM.Prob.NREM,1),1);
    negative_true_condition(Visual_inspection.AWAKE_idx)=1;
    negative_true_condition(Visual_inspection.REM_idx)=1;
    
    negative_predicted_condition=nan(size(GMM.Prob.NREM,1),1);
    negative_predicted_condition(GMM_SWS==0)=1;
    
    tp=size(find(positive_true_condition == positive_predicted_condition),1);
    fp=size(find(negative_true_condition == positive_predicted_condition),1);
    tn=size(find(negative_true_condition == negative_predicted_condition),1);
    fn=size(find(positive_true_condition == negative_predicted_condition),1);
    
    GMM.All_Threshold.TP_SWS(i)=tp/(tp+fn);
    GMM.All_Threshold.FP_SWS(i)=fp/(fp+tn);
end

for i=1:size(T,2)
    
    GMM_REM=GMM.Prob.REM>T(i);
    
    positive_true_condition=nan(size(GMM.Prob.REM,1),1);
    positive_true_condition(Visual_inspection.REM_idx)=1;
    
    positive_predicted_condition=nan(size(GMM.Prob.REM,1),1);
    positive_predicted_condition(GMM_REM==1)=1;
    
    negative_true_condition=nan(size(GMM.Prob.REM,1),1);
    negative_true_condition(Visual_inspection.AWAKE_idx)=1;
    negative_true_condition(Visual_inspection.NREM_idx)=1;
    
    negative_predicted_condition=nan(size(GMM.Prob.REM,1),1);
    negative_predicted_condition(GMM_REM==0)=1;
    
    tp=size(find(positive_true_condition == positive_predicted_condition),1);
    fp=size(find(negative_true_condition == positive_predicted_condition),1);
    tn=size(find(negative_true_condition == negative_predicted_condition),1);
    fn=size(find(positive_true_condition == negative_predicted_condition),1);
    
    GMM.All_Threshold.TP_REM(i)=tp/(tp+fn);
    GMM.All_Threshold.FP_REM(i)=fp/(fp+tn);
end

clear GMM_WK GMM_SWS GMM_REM positive_true_condition positive_predicted_condition ...
    negative_true_condition negative_predicted_condition ...
    tp fp tn fn

%% Calculating Optimal threshold using the point closest-to-(0,1)corner

T=0:0.00001:1;
optimal_threshold.awa_idx=zeros(1,size(T,2));
optimal_threshold.nrem_idx=zeros(1,size(T,2));
optimal_threshold.rem_idx=zeros(1,size(T,2));

% Computing optimal threshold
for i=1:size(T,2)
    optimal_threshold.awa_idx(i)=sqrt((1-GMM.All_Threshold.TP_AWK(i))^2 + (GMM.All_Threshold.FP_AWK(i))^2);
    optimal_threshold.nrem_idx(i)=sqrt((1-GMM.All_Threshold.TP_SWS(i))^2 + (GMM.All_Threshold.FP_SWS(i))^2);
    optimal_threshold.rem_idx(i)=sqrt((1-GMM.All_Threshold.TP_REM(i))^2 + (GMM.All_Threshold.FP_REM(i))^2);
end
clear i

optimal_threshold.awa_idx=find(optimal_threshold.awa_idx==min(optimal_threshold.awa_idx),1);
optimal_threshold.nrem_idx=find(optimal_threshold.nrem_idx==min(optimal_threshold.nrem_idx),1);
optimal_threshold.rem_idx=find(optimal_threshold.rem_idx==min(optimal_threshold.rem_idx),1);

% Setting the threshold
GMM.Selected_Threshold.AWAKE_idx=optimal_threshold.awa_idx;
GMM.Selected_Threshold.AWAKE_value=T(optimal_threshold.awa_idx);

GMM.Selected_Threshold.NREM_idx=optimal_threshold.nrem_idx;
GMM.Selected_Threshold.NREM_value=T(optimal_threshold.nrem_idx);

GMM.Selected_Threshold.REM_idx=optimal_threshold.rem_idx;
GMM.Selected_Threshold.REM_value=T(optimal_threshold.rem_idx);

clear optimal_threshold

%% Defining the indices for each threshold

aux_idx1=find(GMM.Prob.AWAKE>=GMM.Selected_Threshold.AWAKE_value);
aux_idx2=find(GMM.Prob.NREM>=GMM.Selected_Threshold.NREM_value);
aux_idx3=find(GMM.Prob.REM>=GMM.Selected_Threshold.REM_value);

% Preallocating All Sort variables
GMM.All_Sort=zeros(size(GMM.Prob.All,1),1);
GMM_WK_All_Sort=zeros(size(GMM.Prob.All,1),1);
GMM_NREM_All_Sort=zeros(size(GMM.Prob.All,1),1);
GMM_REM_All_Sort=zeros(size(GMM.Prob.All,1),1);
GMM.Nonclassified=zeros(size(GMM.Prob.All,1),1);

% Defining All Sort variables
GMM_REM_All_Sort(aux_idx3)=1;
GMM.All_Sort(aux_idx3)=1;

GMM_NREM_All_Sort(aux_idx2)=1;
GMM.All_Sort(aux_idx2)=2;

GMM_WK_All_Sort(aux_idx1)=1;
GMM.All_Sort(aux_idx1)=3;

GMM.Nonclassified(GMM.All_Sort==0)=1;
GMM.not_classified_number=sum(GMM.Nonclassified);

disp(['Number of nonclassified epochs = ' num2str(GMM.not_classified_number)])
clear aux_*

%% Adding Nonclassified data: fitting in the highest GMM.Probability cluster

aux_non=find(GMM.Nonclassified==1);
if ~isempty(aux_non)
    for i=1:size(aux_non,1)
        if GMM.Prob.AWAKE(aux_non(i))>GMM.Prob.NREM(aux_non(i))>GMM.Prob.REM(aux_non(i))
            GMM_WK_All_Sort(aux_non(i))=1;
            GMM_NREM_All_Sort(aux_non(i))=0;
            GMM_REM_All_Sort(aux_non(i))=0;
        elseif GMM.Prob.AWAKE(aux_non(i))>GMM.Prob.REM(aux_non(i))>GMM.Prob.NREM(aux_non(i))
            GMM_WK_All_Sort(aux_non(i))=0;
            GMM_NREM_All_Sort(aux_non(i))=1;
            GMM_REM_All_Sort(aux_non(i))=0;
        elseif GMM.Prob.NREM(aux_non(i))>GMM.Prob.AWAKE(aux_non(i))>GMM.Prob.REM(aux_non(i))
            GMM_WK_All_Sort(aux_non(i))=0;
            GMM_NREM_All_Sort(aux_non(i))=1;
            GMM_REM_All_Sort(aux_non(i))=0;
        elseif GMM.Prob.NREM(aux_non(i))>GMM.Prob.REM(aux_non(i))>GMM.Prob.AWAKE(aux_non(i))
            GMM_WK_All_Sort(aux_non(i))=0;
            GMM_NREM_All_Sort(aux_non(i))=1;
            GMM_REM_All_Sort(aux_non(i))=0;
        elseif GMM.Prob.REM(aux_non(i))>GMM.Prob.NREM(aux_non(i))>GMM.Prob.AWAKE(aux_non(i))
            GMM_WK_All_Sort(aux_non(i))=0;
            GMM_NREM_All_Sort(aux_non(i))=0;
            GMM_REM_All_Sort(aux_non(i))=1;
        elseif GMM.Prob.REM(aux_non(i))>GMM.Prob.AWAKE(aux_non(i))>GMM.Prob.NREM(aux_non(i))
            GMM_WK_All_Sort(aux_non(i))=0;
            GMM_NREM_All_Sort(aux_non(i))=0;
            GMM_REM_All_Sort(aux_non(i))=1;
        else
            disp 'No epochs not classified!'
        end
    end
end

clear aux* i

%% Fixing data sorted in more than one cluster

% Selecting the indexes of each state Epochs
aux_WK=find(GMM_WK_All_Sort==1);
aux_NREM=find(GMM_NREM_All_Sort==1);
aux_REM=find(GMM_REM_All_Sort==1);

aux_WK_NREM=[];
aux_WK_REM=[];
aux_NREM_REM=[];
aux_all=[];

% Awake and NREM
cont=1;
for i=1:size(aux_WK,1)
    for ii=1:size(aux_NREM,1)
        if aux_WK(i)==aux_NREM(ii)
            aux_WK_NREM(cont)=aux_WK(i);
            cont=cont+1;
        end
    end
end
clear cont

% Awake and REM
cont=1;
for i=1:size(aux_WK,1)
    for ii=1:size(aux_REM,1)
        if aux_WK(i)==aux_REM(ii)
            aux_WK_REM(cont)=aux_WK(i);
            cont=cont+1;
        end
    end
end
clear cont

% NREM and REM
cont=1;
for i=1:size(aux_NREM,1)
    for ii=1:size(aux_REM,1)
        if aux_NREM(i)==aux_REM(ii)
            aux_NREM_REM(cont)=aux_NREM(i);
            cont=cont+1;
        end
    end
end
clear cont

% All states
cont=1;
for i=1:size(aux_WK,1)
    for ii=1:size(aux_NREM,1)
        for iii=1:size(aux_REM,1)
            if aux_WK(i)==aux_NREM(ii) && aux_NREM(ii)==aux_REM(iii)
                aux_all(cont)=aux_WK(i);
                cont=cont+1;
            end
        end
    end
end
clear cont

% Fitting to highest probability cluster
if isempty(cat(2,aux_WK_NREM,aux_NREM_REM,aux_WK_REM))
    disp 'No Epochs ambiguously sorted'
else
    for i=1:size(aux_all,2)
        if GMM.Prob.AWAKE(aux_all(i)) >= GMM.Prob.NREM(aux_all(i)) &&...
                GMM.Prob.AWAKE(aux_all(i)) >= GMM.Prob.REM(aux_all(i))
            GMM_WK_All_Sort(aux_all(i))=1;
            GMM_NREM_All_Sort(aux_all(i))=0;
            GMM_REM_All_Sort(aux_all(i))=0;
        elseif GMM.Prob.NREM(aux_all(i)) >= GMM.Prob.REM(aux_all(i)) &&...
                GMM.Prob.NREM(aux_all(i)) >= GMM.Prob.AWAKE(aux_all(i))
            GMM_WK_All_Sort(aux_all(i))=0;
            GMM_NREM_All_Sort(aux_all(i))=1;
            GMM_REM_All_Sort(aux_all(i))=0;
        elseif GMM.Prob.REM(aux_all(i)) > GMM.Prob.AWAKE(aux_all(i)) &&...
                GMM.Prob.REM(aux_all(i)) > GMM.Prob.NREM(aux_all(i))
            GMM_WK_All_Sort(aux_all(i))=0;
            GMM_NREM_All_Sort(aux_all(i))=0;
            GMM_REM_All_Sort(aux_all(i))=1;
        end
    end
    
    for i=1:size(aux_NREM_REM,2)
        if GMM.Prob.NREM(aux_NREM_REM(i)) >= GMM.Prob.REM(aux_NREM_REM(i))
            GMM_WK_All_Sort(aux_NREM_REM(i))=0;
            GMM_NREM_All_Sort(aux_NREM_REM(i))=1;
            GMM_REM_All_Sort(aux_NREM_REM(i))=0;
        elseif GMM.Prob.NREM(aux_NREM_REM(i)) < GMM.Prob.REM(aux_NREM_REM(i))
            GMM_WK_All_Sort(aux_NREM_REM(i))=0;
            GMM_NREM_All_Sort(aux_NREM_REM(i))=0;
            GMM_REM_All_Sort(aux_NREM_REM(i))=1;
        end
    end
    
    for i=1:size(aux_WK_NREM,2)
        if GMM.Prob.AWAKE(aux_WK_NREM(i)) >= GMM.Prob.NREM(aux_WK_NREM(i))
            GMM_WK_All_Sort(aux_WK_NREM(i))=1;
            GMM_NREM_All_Sort(aux_WK_NREM(i))=0;
        elseif GMM.Prob.AWAKE(aux_WK_NREM(i)) < GMM.Prob.NREM(aux_WK_NREM(i))
            GMM_WK_All_Sort(aux_WK_NREM(i))=0;
            GMM_NREM_All_Sort(aux_WK_NREM(i))=1;
        end
    end
    
    for i=1:size(aux_WK_REM,2)
        if GMM.Prob.AWAKE(aux_WK_REM(i)) >= GMM.Prob.REM(aux_WK_REM(i))
            GMM_WK_All_Sort(aux_WK_REM(i))=1;
            GMM_NREM_All_Sort(aux_WK_REM(i))=0;
            GMM_REM_All_Sort(aux_WK_REM(i))=0;
        elseif GMM.Prob.AWAKE(aux_WK_REM(i)) < GMM.Prob.REM(aux_WK_REM(i))
            GMM_WK_All_Sort(aux_WK_REM(i))=0;
            GMM_NREM_All_Sort(aux_WK_REM(i))=0;
            GMM_REM_All_Sort(aux_WK_REM(i))=1;
        end
    end
    
end

clear aux* i ii iii

%% Redifining GMM.All_Sort

GMM.All_Sort(GMM_WK_All_Sort==1)=3;
GMM.All_Sort(GMM_NREM_All_Sort==1)=2;
GMM.All_Sort(GMM_REM_All_Sort==1)=1;

clear GMM_WK_All_Sort GMM_NREM_All_Sort GMM_REM_All_Sort

%% Plotting the ROC curve WITH THRESHOLD

f=figure('PaperSize', [21 29.7]);
subplot(331)
scatter(x,y,figure_paramenters.scatter_size,GMM.Prob.AWAKE,'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Posterior Probability:','FontSize',figure_paramenters.fontsize*1.2)

subplot(334)
scatter(x,y,figure_paramenters.scatter_size,GMM.Prob.NREM,'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(337)
scatter(x,y,figure_paramenters.scatter_size,GMM.Prob.REM,'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(332)
plot(GMM.All_Threshold.FP_AWK,GMM.All_Threshold.TP_AWK,'k','linewidth',figure_paramenters.lw);
colormap(jet)
hold on
scatter(GMM.All_Threshold.FP_AWK,GMM.All_Threshold.TP_AWK,figure_paramenters.scatter_size,T,'o','Fill');
scatter(GMM.All_Threshold.FP_AWK(GMM.Selected_Threshold.AWAKE_idx),GMM.All_Threshold.TP_AWK(GMM.Selected_Threshold.AWAKE_idx),figure_paramenters.scatter_size*10,'xk','Linewidth',figure_paramenters.lw*3);
hold off
box off
xlim([0 1])
ylim([0 1])
xlabel('False positive rate')
ylabel('True positive rate')
set(gca, 'xtick', [0 .2 .4 .6 .8 1])
set(gca, 'ytick', [0 .2 .4 .6 .8 1])
text (end/4,end/2,...
    {['TP = ' num2str(GMM.All_Threshold.TP_AWK(GMM.Selected_Threshold.AWAKE_idx))],...
    ['FP = ' num2str(GMM.All_Threshold.FP_AWK(GMM.Selected_Threshold.AWAKE_idx))],...
    ['Thres. = ' num2str(floor(GMM.Selected_Threshold.AWAKE_value*100)) '%']},...
    'fontsize',figure_paramenters.fontsize);
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title({'Selecting threshold:','AWAKE'},'FontSize',figure_paramenters.fontsize*1.2)

subplot(335)
plot(GMM.All_Threshold.FP_SWS,GMM.All_Threshold.TP_SWS,'k','linewidth',1.5);
colormap(jet)
hold on
scatter(GMM.All_Threshold.FP_SWS,GMM.All_Threshold.TP_SWS,figure_paramenters.scatter_size,T,'o','Fill');
scatter(GMM.All_Threshold.FP_SWS(GMM.Selected_Threshold.NREM_idx),GMM.All_Threshold.TP_SWS(GMM.Selected_Threshold.NREM_idx),figure_paramenters.scatter_size*10,'xk','Linewidth',figure_paramenters.lw*3);
hold off
box off
xlim([0 1])
ylim([0 1])
xlabel('False positive rate')
ylabel('True positive rate')
set(gca, 'xtick', [0 .2 .4 .6 .8 1])
set(gca, 'ytick', [0 .2 .4 .6 .8 1])
text (end/4,end/2,...
    {['TP = ' num2str(GMM.All_Threshold.TP_SWS(GMM.Selected_Threshold.NREM_idx))],...
    ['FP = ' num2str(GMM.All_Threshold.FP_SWS(GMM.Selected_Threshold.NREM_idx))],...
    ['Thres. = ' num2str(floor(GMM.Selected_Threshold.NREM_value*100)) '%']},...
    'fontsize',figure_paramenters.fontsize);
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title({'NREM'},'FontSize',figure_paramenters.fontsize*1.2)

subplot(338)
plot(GMM.All_Threshold.FP_REM,GMM.All_Threshold.TP_REM,'k','linewidth',1.5);
colormap(jet)
hold on
scatter(GMM.All_Threshold.FP_REM,GMM.All_Threshold.TP_REM,figure_paramenters.scatter_size,T,'o','Fill');
scatter(GMM.All_Threshold.FP_REM(GMM.Selected_Threshold.REM_idx),GMM.All_Threshold.TP_REM(GMM.Selected_Threshold.REM_idx),figure_paramenters.scatter_size*10,'xk','Linewidth',figure_paramenters.lw*3);
hold off
box off
xlim([0 1])
ylim([0 1])
xlabel('False positive rate')
ylabel('True positive rate')
set(gca, 'xtick', [0 .2 .4 .6 .8 1])
set(gca, 'ytick', [0 .2 .4 .6 .8 1])
text (end/4,end/2,...
    {['TP = ' num2str(GMM.All_Threshold.TP_REM(GMM.Selected_Threshold.REM_idx))],...
    ['FP = ' num2str(GMM.All_Threshold.FP_REM(GMM.Selected_Threshold.REM_idx))],...
    ['Thres. = ' num2str(floor(GMM.Selected_Threshold.REM_value*100)) '%']},...
    'fontsize',figure_paramenters.fontsize);
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title({'REM'},'FontSize',figure_paramenters.fontsize*1.2)

subplot(333)
scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
ylabel(label_y);
xlabel('zEMG');
caxis([0 1])
axis([0.1 0.6 0 4])
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title({'Final Classification:','AWAKE'},'FontSize',figure_paramenters.fontsize*1.2)

subplot(336)
scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
ylabel(label_y);
xlabel('zEMG');
caxis([0 1])
axis([0.1 0.6 0 4])
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title({'NREM'},'FontSize',figure_paramenters.fontsize*1.2)

subplot(339)
scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
ylabel(label_y);
xlabel('zEMG');
caxis([0 1])
axis([0.1 0.6 0 4])
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title({'REM'},'FontSize',figure_paramenters.fontsize*1.2)

set(gcf,'color','white')
sgtitle(['Clusters Formation - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','Clusters Formation','-dpdf','-r0',f)

close
clear c s hobj h p* f

%% Scatter plot: Comparisons between methods

f1=figure('PaperSize', [21 29.7]);
subplot(221)
scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
hold on
scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
hold off
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('All States','FontSize',figure_paramenters.fontsize*1.2)

subplot(222)
scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Awake State','FontSize',figure_paramenters.fontsize*1.2)

subplot(223)
scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('NREM sleep','FontSize',figure_paramenters.fontsize*1.2)

subplot(224)
scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('REM sleep','FontSize',figure_paramenters.fontsize*1.2)

sgtitle(['Final Clusters - ' answer],'FontSize', 45)
set(gcf,'color',[1 1 1]);
print('-bestfit','Final Clusters','-dpdf','-r0',f1)

close
clear f1

%% Final Classification over time

% Generating separated hypnogram
aux_aw=zeros(size(GMM.All_Sort,1),1);
aux_aw(GMM.All_Sort==3)=1;
aux_sw=zeros(size(GMM.All_Sort,1),1);
aux_sw(GMM.All_Sort==2)=1;
aux_re=zeros(size(GMM.All_Sort,1),1);
aux_re(GMM.All_Sort==1)=1;

f2=figure('PaperSize', [21 29.7]);
for jj=1:figure_over_time
    subplot(211)
    hold on
    plot(aux_aw(1:end/figure_over_time)+12,'Color',figure_paramenters.color.awake,'linewidth',figure_paramenters.lw);
    plot(aux_sw(1:end/figure_over_time)+9,'Color',figure_paramenters.color.nrem,'linewidth',figure_paramenters.lw);
    plot(aux_re(1:end/figure_over_time)+6,'color',figure_paramenters.color.rem,'linewidth',figure_paramenters.lw);
    plot(smooth(y(1:end/figure_over_time),figure_paramenters.smoothing_value)+3,'Color',[0 0 .6],'linewidth',figure_paramenters.lw);
    plot(smooth(x(1:end/figure_over_time),figure_paramenters.smoothing_value),'Color',figure_paramenters.color.EMG,'linewidth',figure_paramenters.lw);
    plot(figure_paramenters.time_scale+13.5,'-k','LineWidth',figure_paramenters.lw*2,'HandleVisibility','off');
    text(1,15.2,'1 hour','fontsize',figure_paramenters.fontsize)
    hold off
    box off
    ylim([-3 16])
    xlim([1 size(x,1)/figure_over_time+1])
    yticks([mean(x) mean(y+3) mean(aux_re+6) mean(aux_sw+9) mean(aux_aw+12)])
    yticklabels({'zEMG',label_y,'REM','NREM','AWAKE'})
    xticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
    xticklabels(figure_paramenters.time_vector(1:end/figure_over_time+1));
    set(gca,'fontsize',figure_paramenters.fontsize)
    set(gca,'Linewidth',figure_paramenters.lw)
    set(gca,'Tickdir','out')
    
    if figure_over_time==2
        subplot(212)
        hold on
        plot(aux_aw(end/figure_over_time:end)+12,'Color',figure_paramenters.color.awake,'linewidth',figure_paramenters.lw);
        plot(aux_sw(end/figure_over_time:end)+9,'Color',figure_paramenters.color.nrem,'linewidth',figure_paramenters.lw);
        plot(aux_re(end/figure_over_time:end)+6,'color',figure_paramenters.color.rem,'linewidth',figure_paramenters.lw);
        plot(smooth(y(end/figure_over_time:end),figure_paramenters.smoothing_value)+3,'Color',[0 0 .6],'linewidth',figure_paramenters.lw);
        plot(smooth(x(end/figure_over_time:end),figure_paramenters.smoothing_value),'Color',figure_paramenters.color.EMG,'linewidth',figure_paramenters.lw);
        plot(figure_paramenters.time_scale+13.5,'-k','LineWidth',figure_paramenters.lw*2,'HandleVisibility','off');
        text(1,15.2,'1 hour','fontsize',figure_paramenters.fontsize)
        hold off
        box off
        ylim([-3 16])
        xlim([1 size(x,1)/figure_over_time+1])
        yticks([mean(x) mean(y+3) mean(aux_re+6) mean(aux_sw+9) mean(aux_aw+12)])
        yticklabels({'zEMG',label_y,'REM','NREM','AWAKE'})
        xticks([1:size(figure_paramenters.time_color,2)/(size(figure_paramenters.time_vector,1)-1):size(figure_paramenters.time_color,2) size(figure_paramenters.time_color,2)])
        xticklabels(figure_paramenters.time_vector(end/2:end));
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
    end
end

set(gcf,'color',[1 1 1]);
sgtitle(['Final Classification over time - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','Final Classification over time','-dpdf','-r0',f2)

close
clear f2 jj hl hobj aux*

%% True Positive Rate and False Positive Rate with all data sorted

% Awake
positive_true_condition=nan(size(GMM.All_Sort,1),1);
positive_true_condition(Visual_inspection.AWAKE_idx)=1;

positive_predicted_condition=nan(size(GMM.All_Sort,1),1);
positive_predicted_condition(GMM.All_Sort==3)=1;

negative_true_condition=nan(size(GMM.All_Sort,1),1);
negative_true_condition(Visual_inspection.NREM_idx)=1;
negative_true_condition(Visual_inspection.REM_idx)=1;

negative_predicted_condition=nan(size(GMM.All_Sort,1),1);
negative_predicted_condition(GMM.All_Sort~=3)=1;

tp=size(find(positive_true_condition == positive_predicted_condition),1);
fp=size(find(negative_true_condition == positive_predicted_condition),1);
tn=size(find(negative_true_condition == negative_predicted_condition),1);
fn=size(find(positive_true_condition == negative_predicted_condition),1);

GMM.ROC.TP_AWAKE=tp/(tp+fn);
GMM.ROC.FP_AWAKE=fp/(fp+tn);

% NREM

positive_true_condition=nan(size(GMM.All_Sort,1),1);
positive_true_condition(Visual_inspection.NREM_idx)=1;

positive_predicted_condition=nan(size(GMM.All_Sort,1),1);
positive_predicted_condition(GMM.All_Sort==2)=1;

negative_true_condition=nan(size(GMM.All_Sort,1),1);
negative_true_condition(Visual_inspection.AWAKE_idx)=1;
negative_true_condition(Visual_inspection.REM_idx)=1;

negative_predicted_condition=nan(size(GMM.All_Sort,1),1);
negative_predicted_condition(GMM.All_Sort~=2)=1;

tp=size(find(positive_true_condition == positive_predicted_condition),1);
fp=size(find(negative_true_condition == positive_predicted_condition),1);
tn=size(find(negative_true_condition == negative_predicted_condition),1);
fn=size(find(positive_true_condition == negative_predicted_condition),1);

GMM.ROC.TP_NREM=tp/(tp+fn);
GMM.ROC.FP_NREM=fp/(fp+tn);

% REM

positive_true_condition=nan(size(GMM.All_Sort,1),1);
positive_true_condition(Visual_inspection.REM_idx)=1;

positive_predicted_condition=nan(size(GMM.All_Sort,1),1);
positive_predicted_condition(GMM.All_Sort==1)=1;

negative_true_condition=nan(size(GMM.All_Sort,1),1);
negative_true_condition(Visual_inspection.AWAKE_idx)=1;
negative_true_condition(Visual_inspection.NREM_idx)=1;

negative_predicted_condition=nan(size(GMM.All_Sort,1),1);
negative_predicted_condition(GMM.All_Sort~=1)=1;

tp=size(find(positive_true_condition == positive_predicted_condition),1);
fp=size(find(negative_true_condition == positive_predicted_condition),1);
tn=size(find(negative_true_condition == negative_predicted_condition),1);
fn=size(find(positive_true_condition == negative_predicted_condition),1);

GMM.ROC.TP_REM=tp/(tp+fn);
GMM.ROC.FP_REM=fp/(fp+tn);

clear positive_true_condition positive_predicted_condition ...
    negative_true_condition negative_predicted_condition ...
    tp fp tn fn

%% Plotting comparisons

f3=figure('PaperSize', [21 29.7]);
subplot(3,2,1.5)
aux_TP_FP=[GMM.ROC.TP_AWAKE GMM.ROC.FP_AWAKE;...
    GMM.ROC.TP_NREM GMM.ROC.FP_NREM;...
    GMM.ROC.TP_REM GMM.ROC.FP_REM];
figure_paramenters.time_scale=bar(aux_TP_FP);
width = figure_paramenters.time_scale.BarWidth;
for i=1:length(aux_TP_FP(:, 1))
    row = aux_TP_FP(i, :);
    % 0.5 is approximate net width of white spacings per group
    offset = ((width) / length(row)) / 2;
    aux = linspace(i-offset, i+offset, length(row))+0.08;
    text(aux,row,num2str(row'),'vert','bottom','horiz','center','FontSize',figure_paramenters.fontsize/1.5);
end
box off
yticks([0 .2 .4 .6 .8 1])
ylim([0 1])
ylabel('Rate')
xticklabels({'AWAKE' 'NREM' 'REM'})
legend(figure_paramenters.time_scale,'True Positive Rate','False Positive Rate',...
    'Orientation','vertical','Location','eastoutside');
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(323)
scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
hold on
scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
hold off
ylabel(label_y);
xlabel('zEMG');
title('All States','FontSize',figure_paramenters.fontsize*1.2)
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Final Classification','FontSize',figure_paramenters.fontsize*1.2)

subplot(326)
scatter(x(Visual_inspection.All_sort==3),y(Visual_inspection.All_sort==3),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
hold on
scatter(x(Visual_inspection.All_sort==2),y(Visual_inspection.All_sort==2),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
scatter(x(Visual_inspection.All_sort==1),y(Visual_inspection.All_sort==1),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
hold off
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Visually Inspected Data','FontSize',figure_paramenters.fontsize*1.2)

subplot(325)
scatter(x(Training_data.Awake),y(Training_data.Awake),figure_paramenters.scatter_size,...
    figure_paramenters.color.awake,'.');
hold on
scatter(x(Training_data.NREM),y(Training_data.NREM),figure_paramenters.scatter_size,...
    figure_paramenters.color.nrem,'.');
scatter(x(Training_data.REM),y(Training_data.REM),figure_paramenters.scatter_size,...
    figure_paramenters.color.rem,'.');
hold off
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Traning Model Data','FontSize',figure_paramenters.fontsize*1.2)

% Plotting global PSD
total_awa_Pxx_all_24=mean(LFP.Power_normalized(GMM.All_Sort==3,figure_paramenters.Fidx),1);
total_awa_Pxx_all_24(exclude)=nan;
total_sw_Pxx_all_24=mean(LFP.Power_normalized(GMM.All_Sort==2,figure_paramenters.Fidx),1);
total_sw_Pxx_all_24(exclude)=nan;
total_rem_Pxx_all_24=mean(LFP.Power_normalized(GMM.All_Sort==1,figure_paramenters.Fidx),1);
total_rem_Pxx_all_24(exclude)=nan;

subplot(324)
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(total_awa_Pxx_all_24,10),'Color',figure_paramenters.color.awake,'linewidth',figure_paramenters.lw*2);
hold on
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(total_sw_Pxx_all_24,10),'Color',figure_paramenters.color.nrem,'linewidth',figure_paramenters.lw*2);
loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(total_rem_Pxx_all_24,10),'Color',figure_paramenters.color.rem,'linewidth',figure_paramenters.lw*2);
hold off
xlim([1 80])
ylim([min(total_rem_Pxx_all_24)*3 max(total_rem_Pxx_all_24)*2]);
xlabel('Frequency (log)')
ylabel('Power (log)')
title ('Power Spectrum Density')
set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
box off
legend('AWAKE','NREM','REM','Location','best')
legend box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

set(gcf,'color','white')
sgtitle(['Final Performance - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','Final Performance','-dpdf','-r0',f3)

close
clear f3 aux_TP_FP b width i row offset aux total*

%% Final frequency bands distribution

aux_GMM.All_Sort=nan(size(GMM.All_Sort,1),1);
aux_GMM.All_Sort(GMM.All_Sort==3)=-1;
aux_GMM.All_Sort(GMM.All_Sort==2)=0;
aux_GMM.All_Sort(GMM.All_Sort==1)=1;

freq_aux_delta=zscore(LFP.Frequency_bands.Delta)';
freq_aux_theta=zscore(LFP.Frequency_bands.Theta)';
freq_aux_beta=zscore(LFP.Frequency_bands.Beta)';
freq_aux_low_gamma=zscore(LFP.Frequency_bands.Low_Gamma)';
freq_aux_high_gamma=zscore(LFP.Frequency_bands.High_Gamma)';

f=figure('PaperSize', [21 29.7]);
subplot(6,7,15)
gscatter(nan(1,8640),nan(1,8640),aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem])
legend('AWAKE','NREM','REM','Location','southoutside','FontSize',figure_paramenters.fontsize*1.2)
box off
axis off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Legend','FontSize',figure_paramenters.fontsize*1.2)

subplot(6,7,[22 23 24 29 30 31 36 37 38])
gscatter(x,y,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
ylabel(label_y);
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limy)
yticks(figure_paramenters.limy(1)+1:2:16)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Final Distribution','FontSize',figure_paramenters.fontsize*1.2)

subplot(6,7,3)
gscatter(freq_aux_high_gamma,freq_aux_delta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zHigh-Gamma');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,4)
gscatter(freq_aux_low_gamma,freq_aux_delta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zLow-Gamma');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,5)
gscatter(freq_aux_theta,freq_aux_delta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zTheta')
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,6)
gscatter(freq_aux_beta,freq_aux_delta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zBeta');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,7)
gscatter(x,freq_aux_delta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zEMG');
ylabel('zDelta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,11)
gscatter(freq_aux_high_gamma,freq_aux_theta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zHigh-Gamma');
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,12)
gscatter(freq_aux_low_gamma,freq_aux_theta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zLow-Gamma');
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,13)
gscatter(freq_aux_beta,freq_aux_theta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zBeta');
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,14)
gscatter(x,freq_aux_theta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zEMG')
ylabel('zTheta')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,19)
gscatter(freq_aux_high_gamma,freq_aux_beta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zHigh-Gamma')
ylabel('zBeta');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,20)
gscatter(freq_aux_low_gamma,freq_aux_beta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zLow-Gamma')
ylabel('zBeta');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,21)
gscatter(x,freq_aux_beta,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zEMG')
ylabel('zBeta');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,27)
gscatter(freq_aux_high_gamma,freq_aux_low_gamma,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zHigh-Gamma');
ylabel('zLow-Gamma')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,28)
gscatter(x,freq_aux_low_gamma,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
xlabel('zEMG');
ylabel('zLow-Gamma')
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,35)
gscatter(x,freq_aux_high_gamma,aux_GMM.All_Sort,[figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
legend off
box off
ylabel('zHigh-Gamma')
xlabel('zEMG');
xlim(figure_paramenters.limx)
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xticks(figure_paramenters.ticks_aux)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,2)
histogram(freq_aux_delta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zDelta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,10)
histogram(freq_aux_theta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zTheta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,18)
histogram(freq_aux_beta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zBeta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,26)
histogram(freq_aux_low_gamma,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zLow-Gamma')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,34)
histogram(freq_aux_high_gamma,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zHigh-Gamma')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(6,7,42)
histogram(x,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zEMG')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

set(gcf,'color','white')
sgtitle(['State distribution for frequency bands - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','State distribution for frequency bands','-dpdf','-r0',f)

close
clear f

%% Sorted selected Frequency bands

freq_aux_t_d=zscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusg=zscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma);
freq_aux_h_d=zscore(LFP.Frequency_bands.High_Gamma./LFP.Frequency_bands.Delta);
freq_aux_high_gamma=zscore(LFP.Frequency_bands.High_Gamma);
freq_aux_theta=zscore(LFP.Frequency_bands.Theta);
freq_aux_delta=zscore(LFP.Frequency_bands.Delta);

f=figure('PaperSize', [21 29.7]);
subplot(3,3,[1 2 4 5])
gscatter(x,y,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
ylabel(label_y);
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
legend('AWAKE','NREM','REM','Location','best','FontSize',figure_paramenters.fontsize*1.2)
legend box off
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Final Distribution','FontSize',figure_paramenters.fontsize*1.2)

subplot(3,3,3)
gscatter(freq_aux_h_d,freq_aux_t_d,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
ylabel('z(Theta/Delta)')
xlabel('z(High-Gamma/Delta)')
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
legend off
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,3,6)
gscatter(freq_aux_delta,freq_aux_tplusg,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
ylabel('z(Theta+High Gamma)')
xlabel('zDelta')
ylim(figure_paramenters.limx)
yticks(figure_paramenters.ticks_aux)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
legend off
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,9)
histogram(freq_aux_delta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zDelta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,10)
histogram(freq_aux_theta,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zTheta')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,11)
histogram(freq_aux_high_gamma,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zHigh-Gamma')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,4,12)
histogram(x,figure_paramenters.edges,'FaceColor',figure_paramenters.color.bar_plot,...
    'FaceAlpha',figure_paramenters.transparecy_fa,'LineStyle','none','Normalization','Probability');
ylabel('Prob.')
xlabel('Z-scores')
title('zEMG')
ylim([0 .08])
yticks(figure_paramenters.GMM_Prob_axiss)
xlim(figure_paramenters.limx)
xticks(figure_paramenters.ticks_aux)
box off
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

set(gcf,'color','white')
sgtitle(['Sorted selected frequency bands - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-bestfit','Sorted selected frequency bands','-dpdf','-r0',f)

close
clear f

%% 6 to 90 Hz
freq_aux_t_d=zscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusb_delta=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tpluslg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusbpluslg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplushg_d=zscore(LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tplusbplushg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
freq_aux_tpluslgplushg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);

f=figure('PaperSize', [21 29.7]);
subplot(3,5,1)
gscatter(x,freq_aux_t_d,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(Theta/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Only z(Theta/Delta)')

subplot(3,5,2)
gscatter(x,freq_aux_tplusb_delta,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(Theta+Beta/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Adding Beta')

subplot(3,5,3)
gscatter(x,freq_aux_tpluslg_d,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(Theta+Low Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Adding Low Gamma')

subplot(3,5,8)
gscatter(x,freq_aux_tplusbpluslg_d,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(Theta+Beta+Low Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,5,4)
gscatter(x,freq_aux_tplushg_d,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(Theta+High Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('Adding High Gamma')

subplot(3,5,9)
gscatter(x,freq_aux_tplusbplushg_d,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(Theta+Beta+High Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,5,14)
gscatter(x,freq_aux_tpluslgplushg_d,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(Theta+Low Gamma+High Gamma/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')

subplot(3,5,5)
gscatter(x,y,aux_GMM.All_Sort,...
    [figure_paramenters.color.awake;figure_paramenters.color.nrem;figure_paramenters.color.rem],'.');
box off
legend off
ylabel('z(6 to 90Hz/Delta)');
xlabel('zEMG');
ylim(figure_paramenters.limy)
xlim(figure_paramenters.limx)
set(gca,'fontsize',figure_paramenters.fontsize)
set(gca,'Linewidth',figure_paramenters.lw)
set(gca,'Tickdir','out')
title('z(6 to 90Hz/Delta)')

set(gcf,'color','white')
sgtitle(['Sorted 6 to 90 Hz - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
print('-fillpage','Sorted 6 to 90 Hz','-dpdf','-r0',f)

close
clear f freq_aux* aux*

%% Plotting representative epochs

clc
prompt = 'Do you want to save some representative epochs? \nSelect: \n1 = Yes \n2 = No \n ';
ip=input(prompt);
if ip==1
    clear prompt ip
    disp 'It might take a bit long because the epochs are being loaded'
    load ALL_DATA.mat
    
    close all
    mkdir representative_epochs
    cd representative_epochs
    
    numb_representative_plots=5; % number of random epochs for each state
    
    clc
    time=(1:1:size(DATA.LFP_epochs,2))./LFP.FS;
    
    % Awake
    % Selecting which epochs to plot
    state=find(GMM.All_Sort==3);
    
    plot_epochs=state;
    plot_epochs=plot_epochs(randperm(size(plot_epochs,1),numb_representative_plots));
    for jj=1:numb_representative_plots
        
        epoch_psd=LFP.Power_normalized(plot_epochs(jj),figure_paramenters.Fidx);
        epoch_psd(exclude)=nan;
        
        aux_fig=figure('PaperSize', [21 29.7]);
        
        subplot(5,2,[1 2])
        plot(time,DATA.LFP_epochs(plot_epochs(jj),:),'Color',figure_paramenters.color.LFP);
        ylim([-1 1])
        ylabel({'Hippocampus','(Amplitude)'})
        title('10 seconds epoch')
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[3 4])
        plot(time,DATA.EMG_epochs(plot_epochs(jj),:),'Color',figure_paramenters.color.EMG);
        ylim([-1 +1])
        ylabel({'EMG filtered','(Amplitude)'})
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[5 6])
        plot(time,DATA.EMG_raw_data(plot_epochs(jj),:),'Color',[0.6350 0.0780 0.1840]);
        ylim([-1 +1])
        ylabel({'Raw EMG','(Amplitude)'})
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        
        subplot(5,2,7)
        scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
            figure_paramenters.color.awake,'.');
        hold on
        scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
            figure_paramenters.color.nrem,'.');
        scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
            figure_paramenters.color.rem,'.');
        scat=scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),figure_paramenters.scatter_size*2,'r','o','filled');
        hold off
        xlim(figure_paramenters.limx)
        ylim(figure_paramenters.limy)
        legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
        legend box off
        xlabel('zEMG')
        ylabel(label_y)
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,8)
        loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd,10),'Color',figure_paramenters.color.awake,'linewidth',2);
        xlim([1 80])
        legend('Hippocampus','location','southwest')
        legend box off
        xlabel('Frequency (log)')
        ylabel('Power (log)')
        set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[9 10])
        smo=15;
        plot(figure_paramenters.axiss,smooth(x+2,smo),'Color',figure_paramenters.color.EMG,'linewidth',.8)
        hold on
        plot(figure_paramenters.axiss,smooth(y+6,smo),'Color',figure_paramenters.color.LFP,'linewidth',.8)
        line_plot=xline(figure_paramenters.axiss(plot_epochs(jj)),'k','linewidth',2);
        hold off
        box off
        ylim([-1 10])
        xlim([0 size(x,1)])
        yticks([mean(x+2) mean(y+6)])
        yticklabels({'zEMG',label_y})
        xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
        xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        text(figure_paramenters.axiss(plot_epochs(jj))+50,9.5,'-> Epoch selected','fontsize',20)
        
        orient(aux_fig,'portrait')
        set(gcf,'color','white')
        sgtitle(['AWAKE epoch ' num2str(jj) ' - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
        
        print('-bestfit',['AWAKE epoch ' num2str(jj)],'-dpdf','-r0',aux_fig)
        close
    end
    clear state in xv yv plot_epochs jj
    close all
    
    % NREM
    % Selecting which epochs to plot
    state=find(GMM.All_Sort==2);
    
    plot_epochs=state;
    plot_epochs=plot_epochs(randperm(size(plot_epochs,1),numb_representative_plots));
    for jj=1:numb_representative_plots
        
        epoch_psd=LFP.Power_normalized(plot_epochs(jj),figure_paramenters.Fidx);
        epoch_psd(exclude)=nan;
        
        aux_fig=figure('PaperSize', [21 29.7]);
        
        subplot(5,2,[1 2])
        plot(time,DATA.LFP_epochs(plot_epochs(jj),:),'Color',figure_paramenters.color.LFP);
        ylim([-1 1])
        ylabel({'Hippocampus','(Amplitude)'})
        title('10 seconds epoch')
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[3 4])
        plot(time,DATA.EMG_epochs(plot_epochs(jj),:),'Color',figure_paramenters.color.EMG);
        ylim([-1 +1])
        ylabel({'EMG filtered','(Amplitude)'})
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[5 6])
        plot(time,DATA.EMG_raw_data(plot_epochs(jj),:),'Color',[0.6350 0.0780 0.1840]);
        ylim([-1 +1])
        ylabel({'Raw EMG','(Amplitude)'})
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,7)
        scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
            figure_paramenters.color.awake,'.');
        hold on
        scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
            figure_paramenters.color.nrem,'.');
        scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
            figure_paramenters.color.rem,'.');
        scat=scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),figure_paramenters.scatter_size*2,'r','o','filled');
        hold off
        xlim(figure_paramenters.limx)
        ylim(figure_paramenters.limy)
        legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
        legend box off
        xlabel('zEMG')
        ylabel(label_y)
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,8)
        loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd,10),'Color',figure_paramenters.color.nrem,'linewidth',2);
        xlim([1 80])
        legend('Hippocampus','location','southwest')
        legend box off
        xlabel('Frequency (log)')
        ylabel('Power (log)')
        set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[9 10])
        smo=15;
        plot(figure_paramenters.axiss,smooth(x+2,smo),'Color',figure_paramenters.color.EMG,'linewidth',.8)
        hold on
        plot(figure_paramenters.axiss,smooth(y+6,smo),'Color',figure_paramenters.color.LFP,'linewidth',.8)
        line_plot=xline(figure_paramenters.axiss(plot_epochs(jj)),'k','linewidth',2);
        hold off
        box off
        ylim([-1 10])
        xlim([0 size(x,1)])
        yticks([mean(x+2) mean(y+6)])
        yticklabels({'zEMG',label_y})
        xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
        xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        text(figure_paramenters.axiss(plot_epochs(jj))+50,9.5,'-> Epoch selected','fontsize',20)
        
        orient(aux_fig,'portrait')
        set(gcf,'color','white')
        sgtitle(['NREM epoch ' num2str(jj) ' - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
        
        print('-bestfit',['NREM epoch ' num2str(jj)],'-dpdf','-r0',aux_fig)
        close
    end
    clear state in xv yv plot_epochs jj
    close all
    
    % REM
    % Selecting which epochs to plot
    state=find(GMM.All_Sort==1);
    plot_epochs=state;
    plot_epochs=plot_epochs(randperm(size(plot_epochs,1),numb_representative_plots));
    for jj=1:numb_representative_plots
        
        epoch_psd=LFP.Power_normalized(plot_epochs(jj),figure_paramenters.Fidx);
        epoch_psd(exclude)=nan;
        
        aux_fig=figure('PaperSize', [21 29.7]);
        
        subplot(5,2,[1 2])
        plot(time,DATA.LFP_epochs(plot_epochs(jj),:),'Color',figure_paramenters.color.LFP);
        ylim([-1 1])
        ylabel({'Hippocampus','(Amplitude)'})
        title('10 seconds epoch')
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[3 4])
        plot(time,DATA.EMG_epochs(plot_epochs(jj),:),'Color',figure_paramenters.color.EMG);
        ylim([-1 +1])
        ylabel({'EMG filtered','(Amplitude)'})
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[5 6])
        plot(time,DATA.EMG_raw_data(plot_epochs(jj),:),'Color',[0.6350 0.0780 0.1840]);
        ylim([-1 +1])
        ylabel({'Raw EMG','(Amplitude)'})
        xticks([0 1 2 3 4 5 6 7 8 9 10])
        xticklabels([0 1 2 3 4 5 6 7 8 9 10])
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,7)
        scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_paramenters.scatter_size,...
            figure_paramenters.color.awake,'.');
        hold on
        scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_paramenters.scatter_size,...
            figure_paramenters.color.nrem,'.');
        scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_paramenters.scatter_size,...
            figure_paramenters.color.rem,'.');
        scat=scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),figure_paramenters.scatter_size*2,'r','o','filled');
        hold off
        xlim(figure_paramenters.limx)
        ylim(figure_paramenters.limy)
        legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
        legend box off
        xlabel('zEMG')
        ylabel(label_y)
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,8)
        loglog(LFP.Frequency_distribution(figure_paramenters.Fidx),smooth(epoch_psd,10),'Color',figure_paramenters.color.rem,'linewidth',2);
        xlim([1 80])
        legend('Hippocampus','location','southwest')
        legend box off
        xlabel('Frequency (log)')
        ylabel('Power (log)')
        set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
        box off
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        
        subplot(5,2,[9 10])
        smo=15;
        plot(figure_paramenters.axiss,smooth(x+2,smo),'Color',figure_paramenters.color.EMG,'linewidth',.8)
        hold on
        plot(figure_paramenters.axiss,smooth(y+6,smo),'Color',figure_paramenters.color.LFP,'linewidth',.8)
        line_plot=xline(figure_paramenters.axiss(plot_epochs(jj)),'k','linewidth',2);
        hold off
        box off
        ylim([-1 10])
        xlim([0 size(x,1)])
        yticks([mean(x+2) mean(y+6)])
        yticklabels({'zEMG',label_y})
        xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
        xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
        set(gca,'fontsize',figure_paramenters.fontsize)
        set(gca,'Linewidth',figure_paramenters.lw)
        set(gca,'Tickdir','out')
        text(figure_paramenters.axiss(plot_epochs(jj))+50,9.5,'-> Epoch selected','fontsize',20)
        
        orient(aux_fig,'portrait')
        set(gcf,'color','white')
        sgtitle(['REM epoch ' num2str(jj) ' - ' answer],'fontsize',figure_paramenters.fontsize*2.2)
        
        print('-bestfit',['REM epoch ' num2str(jj)],'-dpdf','-r0',aux_fig)
        close
    end
    clear state in xv yv plot_epochs jj
    close all
    
    clear numb_random_plots DATA
    cd ..
end
clear prompt ip 

%% Clearing variables created during the classification
GMM.label_y=label_y;
GMM.Group=answer;
GMM.LFP_used=y;
GMM.EMG_used=x;

clear label_y T exclude figure_paramenters figure_over_time data_combined

%% Saving
save ('GMM_Classification','GMM')
