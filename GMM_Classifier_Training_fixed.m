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

function GMM_Classifier_Training_fixed(app,CA1_data,EMG_accel_accelX,accelY,accelZ,pre_process_state,load_data,selected_indices,emg_accel_state)

close all
clc

%% Interface dependent processes

% If the data was selected from workspace, exclude it to avoid excessive
% use of memory
if strcmp(app.Algorithm_selected_radio_button_tag,'workspace')
    % Erase the selected data
    app.Workspace(selected_indices) = [];
    % Updatee workspace
    UpdateWorkspace_public(app);
end
%% Load data that has already been processed and saved
% If load_data == true, the a dialog window will be opened and the user
% will be able to choose the file
if load_data
    % Get a title string the the file selection dialog box
    title_text = sprintf('Select the pre-processed data');
    % Opens the dialog box and enables the selection of a mat file
    [file,path] = uigetfile('*.mat',title_text,'MultiSelect','off');
    
    % Make sure that the app figure stay focused
    drawnow;
    figure(app.SleepwakecycleclassificationsoftwareUIFigure)
    
    % If the user cancel or closes the window, the function is finished
    if isequal(file,0)
        return
    end
    
    % Check whether the selected epoch length is apropriate to the ALL_DATA
    % files
    variableInfo = whos('-file', fullfile(path,'ALL_DATA.mat'));     % Get the variables inside the file
    emg_size = variableInfo(strcmp({variableInfo.name},'EMG_epochs')).size;    % Get the EMG size info to compare with the epoch length
    load(fullfile(path,'ALL_DATA.mat'),'EMG_processed_sampling_frequency')       % Get the EMG sampling frequency
    
    if ~(app.EpochLengthValue * EMG_processed_sampling_frequency == emg_size(2)) % Check if the epoch length informed by the user is equal to the epoch length from the ALL_DATA files
        % Case it doesn't match
        % Open a dialog window so the user can choose which epoch length
        % will be used and act accordingly
        
        fig_dlg = app.SleepwakecycleclassificationsoftwareUIFigure; % Handle of the figure (it's the app figurer itself)
        msg = [sprintf("The epoch length informed (%d sec) does not match the data epoch length (%d sec). ",app.EpochLengthValue,emg_size(2)/EMG_processed_sampling_frequency);...  % Message that will apper on the new dialog box
            "(1) You can use the option '1 - Use workspace data' and select the checkbox 'Include the algorithm pre-processing step' in the main window and change the epoch length as you wish. (2) Or change the epoch length informed to match the data."];
        tit = 'Epoch length does not match'; % Title
        selection = uiconfirm(fig_dlg,msg,tit,...
            'Options',{'1 - Finish','2 - Change the epoch length','Cancel'},...
            'DefaultOption',1,'CancelOption',3); % Create the dialog box with the question to either close or not the window
        % Get the user selection
        switch selection
            case '1 - Finish'
                app.StatusTextArea.Value = 'The classification could not be completed'; % Change the status check box from the main window
                return         % Finish the current function
            case '2 - Change the epoch length'
                app.EpochLengthEditField.Value = emg_size(2)/EMG_processed_sampling_frequency; % Change the epoch length informed by the user
                app.EpochLengthValue = emg_size(2)/EMG_processed_sampling_frequency;           % Also change it in the interface
                drawnow % Refresh the interface
            case 'Cancel' % Do not do anything (keeps the app window as it is)
                app.StatusTextArea.Value = 'The classification could not be completed'; % Change the status check box from the main window
                return         % Finish the current function
        end
    end
    clearvars variableInfo emg_size EMG_processed_sampling_frequency tit msg selection
    
    % Get the filepath by concatenating the path and file
    path_file_name = fullfile(path,file);
    % Load the EMG and LFP variables
    load(path_file_name,'LFP','EMG','emg_accel_state','pre_pro_params')
    
    % Change the outputPath to the folder where the data_variables file is located
    outputPath = path;
    
    %     % Change the outputPath to the folder where the main app is located
    %     [outputPath,~,~] = fileparts(which('RMS_pwelch_integrate'));
    
    %% Checkpoint GMM
    
    % Check if a GMM_Classification.mat file already exists (if true, it
    % will probably have the check_point_variable)
    create_GMM_check_point = false;
    create_GMM = false;
    if isfile(fullfile(path,'GMM_Classification.mat'))
        % Check if the GMM_Classification.mat file has a check point variable
        variableInfo = who('-file', fullfile(path,'GMM_Classification.mat'));
        if ismember('check_point_info', variableInfo) % If it exists
            load(fullfile(path,'GMM_Classification.mat'),'check_point_info') % Load
        else                                                        % Case it does not
            create_GMM_check_point = true;
        end
    else % GMM does not exist.
        create_GMM = true;
        create_GMM_check_point = true;
    end
    
else
    
    %% Pre-processing data
    % If the user chooses to pre-process using the algorithm parameters
    % (pre_process_state == true)
    % If the user chooses to use the data already pre-processed (mandatory to pass through the pre-processing algorithm in order to complete the final steps to produce a standard data)
    % (pre_process_state == false)
    if strcmp(emg_accel_state,'EMG')    % If the user has select the EMG option instead of any of the 2 Accelorometer ones
        [LFP, EMG, outputPath, pre_pro_params] = pre_processing(app,CA1_data,EMG_accel_accelX,pre_process_state);
    else
        [LFP, EMG, outputPath, pre_pro_params] = pre_processing_accel(app,CA1_data,EMG_accel_accelX,accelY,accelZ,pre_process_state,emg_accel_state);
    end
    
    % Set the algorithm to create a GMM_Classification file and a check
    % point variable
    create_GMM_check_point = true;
    create_GMM = true;
    
    clear prompt ip
end

%% Get the recording params (recording_parameters > main app > GMM) - noise range, recording time and animal group
rec_par = recording_parameters(app, outputPath); % Call the function (recording_parameters > main app)
uiwait(rec_par.UIFigure) % IMPORTANT (makes sure that the 'OK' button is going to be pressed

recording_params = app.Recording_params; % Get info from main app (main app > GMM)

% Update the output path
outputPath = app.Recording_app.OutputPathEditField.Value;

% Change status text
app.StatusTextArea.Value = 'Running the classification algorithm...';
drawnow % Refresh the interface

%% Open the GMM and Visual Inspection variables if it will continue from the last executed step

%%% ##################### ARRUMAR ####################33   verificar o
%%% check point do IDX pra garantir que ele tem os arquivos certinhos

if ~app.Recording_app.Check_Point_Status     % If the status is false (The user wants to go through every single step)
    create_GMM_check_point = true;           % Informs to the algorithm that a new check point variable has to be created
end

% Create the variable check point if it does not exist already
if create_GMM_check_point
    
    % Obs: if TRUE, the step has already been completed
    check_point_info = struct;                              % Create it
    % Get the check point state
    check_point_info.status = app.Recording_app.Check_Point_Status;     % If it is true (check point is considered)
    check_point_info.freq_band_dist = false;
    check_point_info.freq_band_dist_over_time = false;
    check_point_info.freq_band_comb = false;
    check_point_info.add_freq_bands = false;
    check_point_info.data_dist = false;
    check_point_info.artifact_detection = false;
    check_point_info.run_trained_gmm = false;
    check_point_info.gmm_clusters = false;
    check_point_info.clusters_states = false;
    check_point_info.visual_inspection = false;
    check_point_info.visual_inspection = false;
    check_point_info.ROC_curve = false;
    check_point_info.optimal_threshold = false;
    check_point_info.define_indx_thresh = false;
    check_point_info.add_non_class = false;
    check_point_info.fix_data = false;
    check_point_info.find_transitions_rem_nrem = false;
    check_point_info.redefine_gmm = false;
    check_point_info.plot_ROC = false;
    check_point_info.final_clusters = false;
    check_point_info.final_class = false;
    check_point_info.tp_fp_rate = false;
    check_point_info.plot_comparison = false;
    check_point_info.final_freq = false;
    check_point_info.freq_6_to_90 = false;
    check_point_info.plot_representative = false;
    check_point_info.artifact_detection = false;
    
else    % If a new check point status will not be created, just get the status
    check_point_info.status = app.Recording_app.Check_Point_Status;
end

% Checks whether a new GMM_Classification file will be created or not
if create_GMM % Create a GMM_Classification
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','emg_accel_state')    % Create a new GMM file and save the check point
else
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')  % Avoid an overwrite operation
end

% Load GMM and Visual Inspection files if they already exist and the user
% wants to continue the classification
if app.Recording_app.Check_Point_Status && ~create_GMM      % Check if a new GMM has not been created
    load(fullfile(outputPath,'GMM_Classification.mat'))     % Load GMM
end

if app.Recording_app.Check_Point_Status && check_point_info.visual_inspection   % Check whether the visual inspection has already been completed
    load(fullfile(outputPath,'IDX_Visual_Inspection.mat'))                      % Load Visual Inspection
end

%% Figures parameters

%Update status
status_text = 'Getting figure parameters...';
change_status_text(app.Recording_app,status_text);
drawnow() % Update any changes

% Selecting data for EMG
x=zscore(EMG.RMS(1,:))';

% General settings
figure_parameters.transparecy_fa=.9;
figure_parameters.limx=[-3 8];
figure_parameters.limy=[-3 14];

% Over time figures
figure_parameters.time_color=1:size(x,1);
figure_parameters.smoothing_value=floor(size(x,1)/576);
if figure_parameters.smoothing_value == 0
    figure_parameters.smoothing_value = 1;
end
figure_parameters.time_scale=nan(size(x,1),1);
figure_parameters.time_scale(1:360)=1;
figure_parameters.axiss=1:size(x,1);

% Colors
figure_parameters.color.awake=[0.9290, 0.6940, 0.1250];
figure_parameters.color.nrem=[0 0.4470 0.7410];
figure_parameters.color.rem=[0.3 0.3 0.3];
figure_parameters.color.transition_nrem_rem = [0.4 0 0.2];
figure_parameters.color.LFP=[0 0 .8];
figure_parameters.color.EMG=[0.8500 0.3250 0.0980];
figure_parameters.color.bar_plot=[0.4660 0.6740 0.1880];
figure_parameters.color.scatter_color=[.5 .5 .5];
figure_parameters.color.selected_color=[0.3010 0.7450 0.9330];

% Sizes
figure_parameters.fontsize=20;
figure_parameters.scatter_size=15;
figure_parameters.edges=-3:0.1:6;
figure_parameters.lw=2;

% Axis
figure_parameters.GMM_Prob_axiss=0:0.03:0.06;
figure_parameters.ticks_aux=-2:4:6;

% Frequency range in figures
figure_parameters.Fidx=find(LFP.Frequency_distribution<=90);

% Frequencies omitted in figures
exclude=find((recording_params.min_exclude<=LFP.Frequency_distribution) & (LFP.Frequency_distribution<=recording_params.max_exclude));
clc

% Time vector - Hour by hour
aux_figure_parameters.time_vector = 1/24:1/24:24/24;
aux_figure_parameters.time_vector = datestr(aux_figure_parameters.time_vector,'HH:MM');
aux_figure_parameters.time_vector = cellstr(aux_figure_parameters.time_vector);

% Defining how the time labels will be
if recording_params.recording_begin==recording_params.recording_end %  ex: start 19:00 of day 1 -> end 19:00 of day 2
    figure_parameters.time_vector=aux_figure_parameters.time_vector(recording_params.recording_begin:end);
    figure_parameters.time_vector=cat(1,figure_parameters.time_vector,aux_figure_parameters.time_vector(1:recording_params.recording_end));
    figure_parameters.figure_over_time=2; % divide subplots over time in 2
    figure_parameters.time_vector=cat(1,figure_parameters.time_vector(1:3:25),figure_parameters.time_vector(25)); % time label is every third hour
elseif recording_params.recording_begin>recording_params.recording_end % ex: start 19:00 of day 1 -> end 14:00 of day 2
    figure_parameters.time_vector=aux_figure_parameters.time_vector(recording_params.recording_begin:end);
    figure_parameters.time_vector=cat(1,figure_parameters.time_vector,aux_figure_parameters.time_vector(1:recording_params.recording_end));
    figure_parameters.figure_over_time=1; % divide subplots over time in 1
    if size(figure_parameters.time_vector,1)>9 % if it lasts more than 9 hours
        figure_parameters.time_vector=cat(1,figure_parameters.time_vector(1:3:end),figure_parameters.time_vector(end)); % time label is every third hour
        figure_parameters.figure_over_time=2; % divide subplots over time in 2
    end % if not, then time label is every hour
else
    figure_parameters.time_vector=aux_figure_parameters.time_vector(recording_params.recording_begin:recording_params.recording_end); %  ex: start 10:00 of day 1 -> end 17:00 of day 1
    figure_parameters.figure_over_time=1; % divide subplots over time in 1
    if size(figure_parameters.time_vector,1)>9 % if it lasts more than 9 hours
        figure_parameters.time_vector=cat(1,figure_parameters.time_vector(1:2:end),figure_parameters.time_vector(end)); % time label is every third hour
        figure_parameters.figure_over_time=2; % divide subplots over time in 2
    end % if not, then time label is every hour
end

% Setting number of clusters (states)
number_clusters=3;

% Setting the type of data used to indicate the animal movement (It will
% change the axis labels)
if strcmp(emg_accel_state,'EMG')
    figure_parameters.emg_accel = 'EMG';
else
    figure_parameters.emg_accel = 'Accel';
end

% Setting the y axis limit when plotting an epoch (figure out the unit of
% measurement)
if strcmp(pre_pro_params.unit_measurement,'mV') %milivolts
    figure_parameters.ylimits = [-1 1];
elseif strcmp(pre_pro_params.unit_measurement,'microV') %microvolts
    figure_parameters.ylimits = [-1000 1000];
else %Volts
    figure_parameters.ylimits = [-0.001 0.001];
end

clear aux_figure*

%% FIGURE: Frequency bands distribution

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.freq_band_dist) || ~check_point_info.status
    
    %Update status
    status_text = 'FIGURE: Frequency bands distribution...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Frequency bands
    freq_aux_delta=nanzscore(LFP.Frequency_bands.Delta)';
    freq_aux_theta=nanzscore(LFP.Frequency_bands.Theta)';
    freq_aux_beta=nanzscore(LFP.Frequency_bands.Beta)';
    freq_aux_low_gamma=nanzscore(LFP.Frequency_bands.Low_Gamma)';
    freq_aux_high_gamma=nanzscore(LFP.Frequency_bands.High_Gamma)';
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(5,6,1)
    histogram(freq_aux_delta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zDelta')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,2)
    scatter(freq_aux_theta,freq_aux_delta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_theta,freq_aux_delta);
    text(2,8,...
        ['r = ' num2str(rho)...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zTheta')
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,3)
    scatter(freq_aux_beta,freq_aux_delta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_beta,freq_aux_delta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zBeta');
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,4)
    scatter(freq_aux_low_gamma,freq_aux_delta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_low_gamma,freq_aux_delta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zLow-Gamma');
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,5)
    scatter(freq_aux_high_gamma,freq_aux_delta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_high_gamma,freq_aux_delta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zHigh-Gamma');
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,6)
    scatter(x,freq_aux_delta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,8)
    histogram(freq_aux_theta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zTheta')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,9)
    scatter(freq_aux_beta,freq_aux_theta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_beta,freq_aux_theta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zBeta');
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,10)
    scatter(freq_aux_low_gamma,freq_aux_theta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_low_gamma,freq_aux_theta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zLow-Gamma');
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,11)
    scatter(freq_aux_high_gamma,freq_aux_theta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_high_gamma,freq_aux_theta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zHigh-Gamma');
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,12)
    scatter(x,freq_aux_theta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,15)
    histogram(freq_aux_beta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zBeta')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,16)
    scatter(freq_aux_low_gamma,freq_aux_beta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_low_gamma,freq_aux_beta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zLow-Gamma')
    ylabel('zBeta');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,17)
    scatter(freq_aux_high_gamma,freq_aux_beta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_high_gamma,freq_aux_beta);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zHigh-Gamma')
    ylabel('zBeta');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,18)
    scatter(x,freq_aux_beta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylabel('zBeta');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,22)
    histogram(freq_aux_low_gamma,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zLow-Gamma')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,23)
    scatter(freq_aux_high_gamma,freq_aux_low_gamma,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    line=lsline;
    line.LineWidth =1.2;
    line.Color ='k';
    [rho,pval] = corr(freq_aux_high_gamma,freq_aux_low_gamma);
    text(2,8,...
        ['r = ' num2str(rho) ...
        '\newlinep = ' num2str(pval)],...
        'fontsize',figure_parameters.fontsize)
    xlabel('zHigh-Gamma');
    ylabel('zLow-Gamma')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,24)
    scatter(x,freq_aux_low_gamma,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylabel('zLow-Gamma')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,29)
    histogram(freq_aux_high_gamma,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zHigh-Gamma')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(5,6,30)
    scatter(x,freq_aux_high_gamma,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('zHigh-Gamma')
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    f.Renderer='Painters';
    set(gcf,'color','white')
    set(f,'PaperPositionMode','auto')
    sgtitle(['Frequency bands distribution - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-fillpage',fullfile(outputPath,'Frequency bands distribution'),'-dpdf','-r0',f)
    
    close
    clear f line pval rho line
    
    % Update the check and save it
    check_point_info.freq_band_dist = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% FIGURE: Frequency bands distribution over time

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.freq_band_dist_over_time) || ~check_point_info.status
    
    %Update status
    status_text = 'FIGURE: Frequency bands distribution over time...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    for jj=1:figure_parameters.figure_over_time
        subplot(2,1,1)
        plot(smooth(freq_aux_delta(1:end/figure_parameters.figure_over_time),figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
        hold on
        plot(smooth(freq_aux_theta(1:end/figure_parameters.figure_over_time)+3,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
        plot(smooth(freq_aux_beta(1:end/figure_parameters.figure_over_time)+6,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
        plot(smooth(freq_aux_low_gamma(1:end/figure_parameters.figure_over_time)+9,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
        plot(smooth(freq_aux_high_gamma(1:end/figure_parameters.figure_over_time)+12,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
        plot(figure_parameters.time_scale+13.5,'-k','LineWidth',figure_parameters.lw*2,'HandleVisibility','off');
        text(1,15.2,'1 hour','fontsize',figure_parameters.fontsize)
        hold off
        box off
        ylim([-3 16])
        xlim([1 size(x,1)/figure_parameters.figure_over_time+1])
        yticks([nanmean(freq_aux_delta) nanmean(freq_aux_theta+3) nanmean(freq_aux_beta+6) nanmean(freq_aux_low_gamma+9) nanmean(freq_aux_high_gamma+12)])
        yticklabels({'zDelta','zTheta','zBeta','zLow-Gamma','zHigh-Gamma'})
        xticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
        if figure_parameters.figure_over_time==2
            xticklabels(figure_parameters.time_vector(1:end/figure_parameters.figure_over_time+1));
        else
            xticklabels(figure_parameters.time_vector(1:end/figure_parameters.figure_over_time));
        end
        set(gca,'fontsize',figure_parameters.fontsize)
        set(gca,'Linewidth',figure_parameters.lw)
        set(gca,'Tickdir','out')
        
        if figure_parameters.figure_over_time==2
            subplot(2,1,2)
            plot(smooth(freq_aux_delta(end/2:end),figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
            hold on
            plot(smooth(freq_aux_theta(end/2:end)+3,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
            plot(smooth(freq_aux_beta(end/2:end)+6,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
            plot(smooth(freq_aux_low_gamma(end/2:end)+9,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
            plot(smooth(freq_aux_high_gamma(end/2:end)+12,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
            plot(figure_parameters.time_scale+13.5,'-k','LineWidth',figure_parameters.lw*2,'HandleVisibility','off');
            text(1,15.2,'1 hour','fontsize',figure_parameters.fontsize)
            hold off
            box off
            ylim([-3 16])
            xlim([1 size(x,1)/figure_parameters.figure_over_time+1])
            yticks([nanmean(freq_aux_delta) nanmean(freq_aux_theta+3) nanmean(freq_aux_beta+6) nanmean(freq_aux_low_gamma+9) nanmean(freq_aux_high_gamma+12)])
            yticklabels({'zDelta','zTheta','zBeta','zLow-Gamma','zHigh-Gamma'})
            xticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
            xticklabels(figure_parameters.time_vector(end/2:end));
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
        end
    end
    
    
    set(gcf,'color','white')
    set(f,'PaperPositionMode','auto')
    sgtitle(['Frequency bands distribution over time - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'Frequency bands distribution over time'),'-dpdf','-r0',f)
    
    close
    clear f jj
    
    % Update the check and save it
    check_point_info.freq_band_dist_over_time = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% FIGURE: Frequency bands combined

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.freq_band_comb) || ~check_point_info.status
    
    %Update status
    status_text = 'FIGURE: Frequency bands combined...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Frequency bands combined
    freq_aux_t_d=zscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplusb_delta=zscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta)./LFP.Frequency_bands.Delta);
    freq_aux_tpluslg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplusbpluslg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplushg_d=zscore(LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplusbplushg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tpluslgplushg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplusbpluslgplushg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta./LFP.Frequency_bands.Delta);
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(3,5,1)
    scatter(x,freq_aux_t_d,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(Theta/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Only z(Theta/Delta)')
    
    subplot(3,5,2)
    scatter(x,freq_aux_tplusb_delta,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(Theta+Beta/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Adding Beta')
    
    subplot(3,5,3)
    scatter(x,freq_aux_tpluslg_d,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(Theta+Low Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Adding Low Gamma')
    
    subplot(3,5,8)
    scatter(x,freq_aux_tplusbpluslg_d,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(Theta+Beta+Low Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(3,5,4)
    scatter(x,freq_aux_tplushg_d,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(Theta+High Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Adding High Gamma')
    
    subplot(3,5,9)
    scatter(x,freq_aux_tplusbplushg_d,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(Theta+Beta+High Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(3,5,14)
    scatter(x,freq_aux_tpluslgplushg_d,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(Theta+Low Gamma+High Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(3,5,5)
    scatter(x,freq_aux_tplusbpluslgplushg_d,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel('z(6 to 90Hz/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('z(6 to 90Hz/Delta)')
    
    set(gcf,'color','white')
    set(f,'PaperPositionMode','auto')
    sgtitle(['Frequency bands combined - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-fillpage',fullfile(outputPath,'Frequency bands combined'),'-dpdf','-r0',f)
    
    close
    clear f
    
    % Update the check and save it
    check_point_info.freq_band_comb = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Get the extra frequency band added to ratio theta/delta (add_frequency_bands > main app > GMM) - added frequency band

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.add_freq_bands) || ~check_point_info.status
    
    add_freq_band_app = add_frequency_bands(app, outputPath); % Call the function (add_frequency_bands > main app)
    uiwait(add_freq_band_app.UIFigure) % IMPORTANT (makes sure that the 'OK' button is going to be pressed
    
    % Get info from main app (main app > GMM)
    % Get the string tag indicating the selected option
    % ('none','beta','low_gamma',high_gamma','all_gamma','6_to_90')
    added_frequency_bands = app.Added_frequency_bands;
    
    %% Preparing data
    
    %Update status
    status_text = 'Preparing data...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Selecting data for Hippocampus
    clc
    
    switch added_frequency_bands
        case 'none'
            y=nanzscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta)';
            label_y='Theta/Delta (z-score)';
            numerator=nanzscore(LFP.Frequency_bands.Theta);
            numerator_label='zTheta';
            rest_numerator=numerator;
            rest_numerator_label=numerator_label;
            denominator=nanzscore(LFP.Frequency_bands.Delta);
            denominator_label='zDelta';
        case 'beta'
            y=nanzscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta)./LFP.Frequency_bands.Delta)';
            label_y='Theta+Beta/Delta (z-score)';
            numerator=nanzscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta);
            numerator_label='z(Theta + Beta)';
            rest_numerator=nanzscore(LFP.Frequency_bands.Beta./LFP.Frequency_bands.Delta)';
            rest_numerator_label='z(Beta/Delta)';
            denominator=LFP.Frequency_bands.Delta;
            denominator_label='zDelta';
        case 'low_gamma'
            y=nanzscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Low_Gamma)./LFP.Frequency_bands.Delta)';
            label_y='Theta+Low Gamma/Delta(z-score)';
            numerator=nanzscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.Low_Gamma);
            numerator_label='z(Theta + Low Gamma)';
            rest_numerator=nanzscore(LFP.Frequency_bands.Low_Gamma./LFP.Frequency_bands.Delta)';
            rest_numerator_label='z(Low Gamma/Delta)';
            denominator=LFP.Frequency_bands.Delta;
            denominator_label='zDelta';
        case 'high_gamma'
            y=nanzscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
            label_y='Theta+High Gamma/Delta (z-score)';
            numerator=nanzscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma);
            numerator_label='z(Theta + High Gamma)';
            rest_numerator=nanzscore(LFP.Frequency_bands.High_Gamma./LFP.Frequency_bands.Delta)';
            rest_numerator_label='z(High Gamma/Delta)';
            denominator=LFP.Frequency_bands.Delta;
            denominator_label='zDelta';
        case 'all_gamma'
            y=nanzscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
            label_y='Theta+Gamma/Delta (z-score)';
            numerator=nanzscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma);
            numerator_label='z(Theta + Gamma)';
            rest_numerator=nanzscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma./LFP.Frequency_bands.Delta)';
            rest_numerator_label='z(Gamma/Delta)';
            denominator=LFP.Frequency_bands.Delta;
            denominator_label='zDelta';
        case '6_to_90'
            y=nanzscore((LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
            label_y='6 to 90 Hz/Delta (z-score)';
            numerator=nanzscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)';
            numerator_label='z(6 to 90Hz)';
            rest_numerator=nanzscore((LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma)./LFP.Frequency_bands.Delta)';
            rest_numerator_label='z(10 to 90Hz)';
            denominator=LFP.Frequency_bands.Delta;
            denominator_label='zDelta';
    end
    
    % Combining data
    data_combined=[x y];
    
    % Update the check and save it
    check_point_info.add_freq_bands = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','y','label_y','data_combined','added_frequency_bands','-append')
    
end
%% FIGURE: Selected Frequency bands

% %Update status
% status_text = 'FIGURE: Selected Frequency bands...';
% change_status_text(app.Recording_app,status_text);
% drawnow() % Update any changes
%
% f=figure('PaperSize', [21 29.7],'visible','off');
% subplot(3,3,[1 2 4 5])
% scatter(x,y,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
% ylabel(label_y);
% xlabel([figure_parameters.emg_accel ' (z-score)']);
% ylim(figure_parameters.limy)
% xlim(figure_parameters.limx)
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
% title('Final Distribution','fontsize',figure_parameters.fontsize*1.5)
%
% subplot(3,3,3)
% scatter(rest_numerator,freq_aux_t_d,...
%     figure_parameters.scatter_size,figure_parameters.color.selected_color,'.');
% line=lsline;
% line.LineWidth =1.2;
% line.Color ='k';
% [rho,pval] = corrcoef(rest_numerator,freq_aux_t_d);
% text(-2,7,...
%     ['r = ' num2str(rho(2)) ...
%     '\newline p = ' num2str(pval(2))],...
%     'fontsize',figure_parameters.fontsize)
% ylabel('z(Theta/Delta)')
% xlabel(rest_numerator_label)
% ylim(figure_parameters.limx)
% yticks(figure_parameters.ticks_aux)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,3,6)
% scatter(denominator,numerator,...
%     figure_parameters.scatter_size,figure_parameters.color.selected_color,'.');
% line=lsline;
% line.LineWidth =1.2;
% line.Color ='k';
% [rho,pval] = corrcoef(denominator,numerator);
% text(2,8,...
%     ['r = ' num2str(rho(2)) ...
%     '\newline p = ' num2str(pval(2))],...
%     'fontsize',figure_parameters.fontsize)
% ylabel(numerator_label)
% xlabel(denominator_label)
% ylim(figure_parameters.limx)
% yticks(figure_parameters.ticks_aux)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,9)
% histogram(freq_aux_delta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% ylabel('Prob.')
% xlabel('Z-scores')
% title('zDelta')
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,10)
% histogram(freq_aux_theta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% xlabel('Z-scores')
% title('zTheta')
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,11)
% histogram(numerator,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% xlabel('Z-scores')
% title(numerator_label)
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,12)
% histogram(x,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% xlabel('Z-scores')
% title([figure_parameters.emg_accel ' (z-score)'])
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% set(gcf,'color','white')
% set(f,'PaperPositionMode','auto')
% sgtitle(['Selected frequency bands - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
% print('-fillpage',fullfile(outputPath,'Selected frequency bands'),'-dpdf','-r0',f)
%
% close
% clear f line pval rho line

%% FIGURE: Data distribution

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.data_dist) || ~check_point_info.status
    
    %Update status
    status_text = 'FIGURE: Data distribution...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(321)
    scatter(x,y,figure_parameters.scatter_size,figure_parameters.color.scatter_color,'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    yticks(figure_parameters.limy(1)+1:2:16)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(3,2,[2 4])
    scatter3(x,y,figure_parameters.time_color,figure_parameters.scatter_size,figure_parameters.time_color,'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    zlabel('Time of recording');
    colormap(copper)
    zticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
    zticklabels(figure_parameters.time_vector)
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('On a scatter plot over time')
    
    subplot(3,4,5)
    histogram(y,figure_parameters.edges,'FaceColor',figure_parameters.color.LFP,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    xlim([-2 6])
    ylim([0 .3])
    yticks(0:.1:.3)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title(label_y,'FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,4,6)
    histogram(x,figure_parameters.edges,'FaceColor',figure_parameters.color.EMG,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    xlabel('Z-scores')
    xlim([-2 6])
    ylim([0 .3])
    yticks(0:.1:.3)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title([figure_parameters.emg_accel, ' (z-score)'],'FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,2,[5 6])
    plot(figure_parameters.axiss,smooth(x+2,figure_parameters.smoothing_value),'Color',figure_parameters.color.EMG,'linewidth',figure_parameters.lw)
    hold on
    plot(figure_parameters.axiss,smooth(y+6,figure_parameters.smoothing_value),'Color',figure_parameters.color.LFP,'linewidth',figure_parameters.lw)
    plot(figure_parameters.time_scale+8.5,'-k','LineWidth',figure_parameters.lw*2,'HandleVisibility','off');
    text(1,10,'1 hour','fontsize',figure_parameters.fontsize)
    hold off
    box off
    ylim([-1 10])
    xlim([0 size(x,1)])
    yticks([nanmean(y+2) nanmean(x+6)])
    yticklabels({[figure_parameters.emg_accel, ' (z-score)'],label_y})
    xticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
    xticklabels(figure_parameters.time_vector);
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Variables scores over time','FontSize',figure_parameters.fontsize*1.2)
    
    f.Renderer='Painters';
    set(gcf,'color','white')
    set(f,'PaperPositionMode','auto')
    sgtitle(['Data distribution - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-fillpage',fullfile(outputPath,'Data distribution'),'-dpdf','-r0',f)
    
    close
    clear f c
    
    % Update the check and save it
    check_point_info.data_dist = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Training epochs (Excluded)

% % Get the main_app_pathway (important, since the trained data file is
% % stored in this same folder)
% [main_app_pathway,~,~] = fileparts(which('RMS_pwelch_integrate'));
% trained_data_filepathway = fullfile(main_app_pathway,'Trained_data.mat');
%
% % Load the Trained_data.m file
% load(trained_data_filepathway,'Training_data')
%
% % If the plot trained data has been checked
% if app.Algorithm_params.plot_trained_data
%
%     % Plotting Training data's PSD
%     aux_tr_awa_Pxx_all_24=mean(LFP.Power_normalized(Training_data.Awake,figure_parameters.Fidx),1);
%     aux_tr_awa_Pxx_all_24(exclude)=nan;
%     aux_tr_sw_Pxx_all_24=mean(LFP.Power_normalized(Training_data.NREM,figure_parameters.Fidx),1);
%     aux_tr_sw_Pxx_all_24(exclude)=nan;
%     aux_tr_rem_Pxx_all_24=mean(LFP.Power_normalized(Training_data.REM,figure_parameters.Fidx),1);
%     aux_tr_rem_Pxx_all_24(exclude)=nan;
%
%     % To plot the Training data over time
%     aux_tr_awa=zeros(1,size(x,1));
%     aux_tr_awa(Training_data.Awake)=1;
%     aux_tr_sws=zeros(1,size(x,1));
%     aux_tr_sws(Training_data.NREM)=1;
%     aux_tr_rem=zeros(1,size(x,1));
%     aux_tr_rem(Training_data.REM)=1;
%     aux_plot=1:size(x,1);
%
%     f=figure('PaperSize', [21 29.7],'visible','off');
%     subplot(221)
%     loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(aux_tr_awa_Pxx_all_24,10),'Color',figure_parameters.color.awake,'linewidth',figure_parameters.lw);
%     hold on
%     loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(aux_tr_sw_Pxx_all_24,10),'Color',figure_parameters.color.nrem,'linewidth',figure_parameters.lw);
%     loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(aux_tr_rem_Pxx_all_24,10),'Color',figure_parameters.color.rem,'linewidth',figure_parameters.lw);
%     hold off
%     xlim([1 80])
%     ylim([.0001 0.01])
%     yticks([.0001 .001 .01])
%     xlabel('Frequency (Hz)')
%     ylabel({'   PSD'; '(Power Norm.)'})
%     set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
%     box off
%     legend('AWAKE','NREM','REM','Location','best')
%     legend box off
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title('Power Spectrum Density','FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(222)
%     scatter(x(Training_data.Awake),y(Training_data.Awake),figure_parameters.scatter_size,figure_parameters.color.awake,...
%         '.');
%     hold on
%     scatter(x(Training_data.NREM),y(Training_data.NREM),figure_parameters.scatter_size,figure_parameters.color.nrem,...
%         '.');
%     scatter(x(Training_data.REM),y(Training_data.REM),figure_parameters.scatter_size,figure_parameters.color.rem,...
%         '.');
%     hold off
%     ylabel(label_y);
%     xlabel([figure_parameters.emg_accel ' (z-score)']);
%     xlim(figure_parameters.limx)
%     ylim(figure_parameters.limy)
%     box off
%     legend ('AWAKE','NREM','REM','Location','best')
%     legend box off
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title('Scatter plot','FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(2,2,[3 4])
%     plot(aux_plot,aux_tr_awa+4,'color',figure_parameters.color.awake,'LineWidth',figure_parameters.lw)
%     hold on
%     plot(aux_plot,aux_tr_sws+2,'color',figure_parameters.color.nrem,'LineWidth',figure_parameters.lw)
%     plot(aux_plot,aux_tr_rem,'color',figure_parameters.color.rem,'LineWidth',figure_parameters.lw)
%     hold off
%     box off
%     ylim([-1 6])
%     xlim([0 size(x,1)])
%     yticks([mean(aux_tr_rem) mean(aux_tr_sws+2) mean(aux_tr_awa+4)])
%     yticklabels({'REM','NREM','AWAKE'})
%     xticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
%     xticklabels(figure_parameters.time_vector);
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title('Epochs selected','FontSize',figure_parameters.fontsize*1.2)
%
%     set(gcf,'color','white')
%     set(f,'PaperPositionMode','auto')
%     sgtitle(['Training Data distribution - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
%     print('-bestfit',fullfile(outputPath,'Training data distribution'),'-dpdf','-r0',f)
%
%     close
%     clear f aux*
% end
% clear prompt ip aux*

%% Artifact detection

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.artifact_detection) || ~check_point_info.status
    
    %Update status
    status_text = 'Running artifact detection...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Call the function to proceed with the artifact detection
    [artifact,finished] = artifacts_detection(EMG,LFP,outputPath,app.Recording_app.ArtifactdetectionamplitudetresholdSDEditField.Value,...
        app.Recording_app.InferiorEditField.Value,app.Recording_app.SuperiorEditField.Value,figure_parameters);
    
    % If the user has not finished the artifact detection, stop the
    % classification algorithm and return to the main interface
    if ~finished
        return      % Stops the execution of the function
    end
    
    % Update the check and save it
    check_point_info.artifact_detection = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','artifact','-append')
    
end

%% Running trained GMM

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.run_trained_gmm) || ~check_point_info.status
    
    %Update status
    status_text = 'Running trained GMM...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Get the main_app_pathway (important, since the trained data file is
    % stored in this same folder)
    [main_app_pathway,~,~] = fileparts(which('RMS_pwelch_integrate'));
    trained_data_filepathway = fullfile(main_app_pathway,'Trained_data.mat');
    
    % Load the Trained_data.m file
    load(trained_data_filepathway,'Training_data')
    
    %     % Change the distribution to match the training data distribution
    %     difference_theta_delta = min(Training_data.LFP_used) - min(x);
    %     difference_emg = min(Training_data.EMG_used) - min(y);
    %
    %     % Data
    %     data_combined(:,1) = data_combined(:,1) + difference_emg;
    %     data_combined(:,2) = data_combined(:,2) + difference_theta_delta;
    
    % Running the GMM with the epochs excluded
    artifact.data_combined_artifact_free=[artifact.x_artifact_free' artifact.y_artifact_free'];
    
    %     % Change the distribution to match the training data distribution
    %     difference_theta_delta = nanmedian(Training_data.LFP_used) - nanmedian(artifact.y_artifact_free);
    %     difference_emg = nanmedian(Training_data.EMG_used) - nanmedian(artifact.x_artifact_free);
    %
    %     % Data
    %     artifact.data_combined_artifact_free(:,1) = artifact.data_combined_artifact_free(:,1) + difference_emg;
    %     artifact.data_combined_artifact_free(:,2) = artifact.data_combined_artifact_free(:,2) + difference_theta_delta;
    %
    
    % Check if the user enabled the GMM training
    if app.Algorithm_params.training_dataset    % If it is enabled
        % Fitting trained data
        [artifact.GMM.Prob.All,artifact.GMM.nlogL,threshold_pos_prob,succeeded] = trained_GMM_function(artifact.data_combined_artifact_free,number_clusters,Training_data.Trained_GMM,Training_data.LFP_used,Training_data.EMG_used,app.Algorithm_params.missing_state);
        
    else                                        % If it is disabled (without training dataset
        % Get the label info to be used in the plots
        labels_info.xlabel = figure_parameters.emg_accel;
        labels_info.ylabel = label_y;
        [artifact.GMM.Prob.All,artifact.GMM.nlogL,threshold_pos_prob,succeeded] = untrained_GMM_function(artifact.data_combined_artifact_free,number_clusters,labels_info,app.Algorithm_params.missing_state);
    end
    
    % After the GMM_function has finished check if it was NOT succeeded and warn
    % the user about it. The current function will also be finished
    if ~succeeded
        % Creates an alert informing the user
        fig_warning = uifigure;
        uialert(fig_warning,'It was not possible to cluster the epochs of your dataset into 3 separate groups (AWAKE, NREM, REM)','GMM Algorithm was not successful','CloseFcn',@(h,e) close(fig_warning));
        uiwait(fig_warning) % Wait until the warning is closed
        % Close the recording_app
        delete(app.Recording_app)
        % Finishes this function
        return
    end
    
    % A Partir daqui é o original
    % Keep calculating the GMM until a good cluster is formed (max 1000
    % iterations)
    %     for gmm_loop = 1:1000
    %
    %         try
    %             % Fitting trained data
    %             artifact.GMM.GMM_distribution = fitgmdist(artifact.data_combined_artifact_free,number_clusters,...
    %                 'Start',Training_data.Trained_GMM);
    %         catch ME  % If it finds any kind of error
    %             if strcmp('stats:gmdistribution:IllCondCovIter',ME.identifier)  % If it is a ill-conditioned covariance error
    %                 % Try without the training data set
    %                 artifact.GMM.GMM_distribution = fitgmdist(artifact.data_combined_artifact_free,number_clusters);
    %             end
    %         end
    % %         % Fitting trained data
    % %         artifact.GMM.GMM_distribution = fitgmdist(artifact.data_combined_artifact_free,number_clusters,...
    % %             'Start',Training_data.Trained_GMM);
    %
    %         % Computing Posterior GMM Probability to each time bin
    %         [artifact.GMM.Prob.All,artifact.GMM.nlogL] = posterior(artifact.GMM.GMM_distribution,artifact.data_combined_artifact_free);
    %
    %         clear tr_* fitted_GMM aux*
    %
    %         % Get GMM parameters
    %         GMM.GMM_distribution = artifact.GMM.GMM_distribution;
    %         GMM.Prob.All = artifact.GMM.Prob.All;
    %         GMM.nlogL = artifact.GMM.nlogL;
    %
    % %         GMM.GMM_distribution = fitgmdist(data_combined,number_clusters,...
    % %             'Start',Training_data.Trained_GMM);
    % %
    % %         % Computing Posterior GMM.Probability to each time bin
    % %         [GMM.Prob.All,GMM.nlogL] = posterior(GMM.GMM_distribution,data_combined);
    %
    %         % Make sure that every single one of the 3 clusters has at least 1
    %         % period with posterior probabily higher than 0.5
    %         if ~isempty(find(GMM.Prob.All(:,1) > 0,1)) &&...
    %                 ~isempty(find(GMM.Prob.All(:,2) > 0,1)) &&...
    %                 ~isempty(find(GMM.Prob.All(:,3) > 0,1))
    %             break   % Terminate the execution of the current loop
    %         end
    %
    %     end
    %     % Check if all the clusters have at least 1 epoch with posterior
    %     % probability higher than 90%. If it is not the case, if the user selected
    %     % the option to keep repeating the clustering, it will do 100 more
    %     % iterations
    %     if isempty(find(GMM.Prob.All(:,1)>.9,1)) || isempty(find(GMM.Prob.All(:,2)>.9,1)) || isempty(find(GMM.Prob.All(:,3)>.9,1))
    %         add_iterations_trigger = true;
    %     else
    %         add_iterations_trigger = false;
    %     end
    %
    %     % Defining the GMM.Probability distribution for each state
    %     n_iterations = 89; % number of total iteration
    %     threshold_pos_prob = 0.9; % It will decrease 0.01 each iteration
    %     if add_iterations_trigger  % If it's necessary another set of iterations
    %         for ii = 1:n_iterations
    %             [artifact.GMM.Prob.All,artifact.GMM.nlogL] = posterior(artifact.GMM.GMM_distribution,artifact.data_combined_artifact_free);
    %             % Check if the clusterization was successful
    %             if ~isempty(find(GMM.Prob.All(:,1)>threshold_pos_prob,1)) && ~isempty(find(GMM.Prob.All(:,2)>threshold_pos_prob,1)) && ~isempty(find(GMM.Prob.All(:,3)>threshold_pos_prob,1))
    %                 succeeded = true;
    %                 break  % Stop the current loop to proceed
    %             else
    %                 threshold_pos_prob = threshold_pos_prob - 0.01;
    %                 succeeded = false;
    %             end
    %         end
    %
    %         % After the loop has finished check if it was NOT succeeded and warn
    %         % the user about it. The function will also be finished
    %         if ~succeeded
    %             % Creates an alert informing the user
    %             fig_warning = uifigure;
    %             uialert(fig_warning,'It was not possible to cluster the epochs of your dataset into 3 separate groups (AWAKE, NREM, REM)','GMM Algorithm was not successful','CloseFcn',@(h,e) close(fig_warning));
    %             uiwait(fig_warning) % Wait until the warning is closed
    %             % Close the recording_app
    %             delete(app.Recording_app)
    %             % Finishes this function
    %             return
    %         end
    %     end
    % Até aqui
    
    % Get the new GMM results
    GMM.Prob.All = artifact.GMM.Prob.All;
    GMM.nlogL = artifact.GMM.nlogL;
    
    % Change the number of clusters
    if app.Algorithm_params.missing_state
        number_clusters = number_clusters - 1;
    end
    % Function to add the missing period (artifacts) in GMM posterior
    % probability matrix as zeros (0)
    GMM = fix_gmm_artifacts(GMM,artifact,x,number_clusters);
    
    clear tr_* fitted_GMM aux* n_iterations add_iterations_trigger succeeded
    
    % Update the check and save it
    check_point_info.run_trained_gmm = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','check_point_info','artifact','threshold_pos_prob','-append')
    
    %     save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','threshold_pos_prob','check_point_info','artifact','-append')
    
end

%% FIGURE: GMM clusters with Artifacts

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.gmm_clusters) || ~check_point_info.status
    
    %Update status
    status_text = 'FIGURE: GMM clusters with artifacts...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(334)
    aux_c=colorbar;
    colormap(jet);
    aux_c.TickDirection='out';
    aux_c.Location='west';
    s=get(aux_c,'position');
    aux_c.Position=[s(1) s(2)/1.5 s(3)*2 s(4)*2];
    axis off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    aux_h=text(s(1)-s(1)*2,s(2)-s(2)*1.5,'GMM: Posterior Probability','FontSize',figure_parameters.fontsize*1.2);
    set(aux_h,'Rotation',90);
    
    subplot(332)
    scatter(x,y,figure_parameters.scatter_size,GMM.Prob.All(:,1),'.');
    hold on
    scatter(x(artifact.LFP_epoch),y(artifact.LFP_epoch),figure_parameters.scatter_size,...
        'm','x');
    hold off
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    ylabel(label_y);
    xticklabels('')
    title({'All epochs','Cluster 1'})
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(335)
    scatter(x,y,figure_parameters.scatter_size,GMM.Prob.All(:,2),'.');
    hold on
    aux_sc=scatter(x(artifact.LFP_epoch),y(artifact.LFP_epoch),figure_parameters.scatter_size,...
        'm','x');
    hold off
    legend(aux_sc,'Epochs with artifact','Location','Northeast')
    legend box off
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    ylabel(label_y);
    xticklabels('')
    title('Cluster 2')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    if number_clusters >= 3
        subplot(338)
        scatter(x,y,figure_parameters.scatter_size,GMM.Prob.All(:,3),'.');
        hold on
        scatter(x(artifact.LFP_epoch),y(artifact.LFP_epoch),figure_parameters.scatter_size,...
            'm','x');
        hold off
        ylabel(label_y);
        xlabel([figure_parameters.emg_accel ' (z-score)']);
        xlim(figure_parameters.limx)
        ylim(figure_parameters.limy)
        title('Cluster 3')
        set(gca,'fontsize',figure_parameters.fontsize)
        set(gca,'Linewidth',figure_parameters.lw)
        set(gca,'Tickdir','out')
    end
    
    subplot(333)
    scatter(artifact.x_artifact_free,artifact.y_artifact_free,figure_parameters.scatter_size,artifact.GMM.Prob.All(:,1),'.');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    xticklabels('')
    yticklabels('')
    title({'Artifact free','Cluster 1'})
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(336)
    scatter(artifact.x_artifact_free,artifact.y_artifact_free,figure_parameters.scatter_size,artifact.GMM.Prob.All(:,2),'.');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    xticklabels('')
    yticklabels('')
    title('Cluster 2')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    if number_clusters >= 3
        
        subplot(339)
        scatter(artifact.x_artifact_free,artifact.y_artifact_free,figure_parameters.scatter_size,artifact.GMM.Prob.All(:,3),'.');
        xlim(figure_parameters.limx)
        ylim(figure_parameters.limy)
        yticklabels('')
        xlabel([figure_parameters.emg_accel ' (z-score)']);
        title('Cluster 3')
        set(gca,'fontsize',figure_parameters.fontsize)
        set(gca,'Linewidth',figure_parameters.lw)
        set(gca,'Tickdir','out')
    end
    
    set(gcf,'color','white')
    set(f,'PaperPositionMode','auto')
    sgtitle('GMM Clusters with artifacts','fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'GMM Clusters with artifacts'),'-dpdf','-r0',f)
    
    close
    clear aux* f s c
    
    %% FIGURE: GMM clusters
    
    %Update status
    status_text = 'FIGURE: GMM clusters...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(221)
    scatter(x,y,figure_parameters.scatter_size,GMM.Prob.All(:,1),'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(222)
    scatter(x,y,figure_parameters.scatter_size,GMM.Prob.All(:,2),'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    if number_clusters >= 3
        subplot(223)
        scatter(x,y,figure_parameters.scatter_size,GMM.Prob.All(:,3),'.');
        ylabel(label_y);
        xlabel([figure_parameters.emg_accel ' (z-score)']);
        xlim(figure_parameters.limx)
        ylim(figure_parameters.limy)
        set(gca,'fontsize',figure_parameters.fontsize)
        set(gca,'Linewidth',figure_parameters.lw)
        set(gca,'Tickdir','out')
    end
    
    subplot(224)
    c=colorbar;
    colormap(jet);
    c.Location='north';
    s=get(c,'position');
    c.Position=[s(1) s(2)/1.5 s(3) s(4)];
    axis off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    text(s(1)-s(1)*.6,s(2)*1.8,'GMM: Posterior Probability','FontSize',figure_parameters.fontsize*1.2);
    
    set(gcf,'color','white')
    set(f,'PaperPositionMode','auto')
    sgtitle(['GMM Clusters - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'GMM Clusters'),'-dpdf','-r0',f)
    
    close
    clear f s c
    
    % Update the check and save it
    check_point_info.gmm_clusters = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Defining clusters as states

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.clusters_states) || ~check_point_info.status
    
    %Update status
    status_text = 'Defining clusters as states...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Defining the GMM.Probability distribution for each state
    aux_idx1=find(GMM.Prob.All(:,1)>threshold_pos_prob);
    aux_idx2=find(GMM.Prob.All(:,2)>threshold_pos_prob);
    aux_idx3=find(GMM.Prob.All(:,3)>threshold_pos_prob);
    
    aux_x1=max(x(aux_idx1));
    aux_x2=max(x(aux_idx2));
    aux_x3=max(x(aux_idx3));
    
    aux_y1=max(y(aux_idx1));
    aux_y2=max(y(aux_idx2));
    aux_y3=max(y(aux_idx3));
    
    % Concatenate aux values
    aux_x = [aux_x1 aux_x2 aux_x3];
    aux_y = [aux_y1 aux_y2 aux_y3];
    
    % Check if there is any missing state and which one is it
    if app.Algorithm_params.missing_state && (isempty(aux_x1) || isempty(aux_x2) || isempty(aux_x3))
        if isempty(aux_x1); idx_missing = [1 0 0]; elseif isempty(aux_x2); idx_missing = [0 1 0]; else; idx_missing = [0 0 1]; end
        % Clear missing idxs
        idx_missing = logical(idx_missing);
        % Get the not missing idxs
        idx_not_missing = find(~idx_missing);
        switch app.Algorithm_params.missing_state_name  % Get the missing state name
            case 'WAKE'                                 % WAKE
                GMM.Prob.AWAKE = GMM.Prob.All(:,idx_missing);
                if aux_y(1) > aux_y(2)
                    GMM.Prob.REM = GMM.Prob.All(:,idx_not_missing(1));
                    GMM.Prob.NREM = GMM.Prob.All(:,idx_not_missing(2));
                else
                    GMM.Prob.NREM = GMM.Prob.All(:,idx_not_missing(1));
                    GMM.Prob.REM = GMM.Prob.All(:,idx_not_missing(2));
                end
            case 'NREM'                                 % NREM
                GMM.Prob.NREM = GMM.Prob.All(:,idx_missing);
                if aux_x(1) > aux_x(2)
                    GMM.Prob.AWAKE = GMM.Prob.All(:,idx_not_missing(1));
                    GMM.Prob.REM = GMM.Prob.All(:,idx_not_missing(2));
                else
                    GMM.Prob.REM = GMM.Prob.All(:,idx_not_missing(1));
                    GMM.Prob.AWAKE = GMM.Prob.All(:,idx_not_missing(2));
                end
            case 'REM'                                  % REM
                GMM.Prob.REM = GMM.Prob.All(:,idx_missing);
                if aux_x(1) > aux_x(2)
                    GMM.Prob.AWAKE = GMM.Prob.All(:,idx_not_missing(1));
                    GMM.Prob.NREM = GMM.Prob.All(:,idx_not_missing(2));
                else
                    GMM.Prob.NREM = GMM.Prob.All(:,idx_not_missing(1));
                    GMM.Prob.AWAKE = GMM.Prob.All(:,idx_not_missing(2));
                end
        end
        
    else    % Default (all the 3 states are represented)
        
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
        
    end
    
    clear aux_idx*
    
    % Update the check and save it
    check_point_info.clusters_states = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','check_point_info','-append')
    
end

%% Running Visual Inspection

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.visual_inspection) || ~check_point_info.status
    
    %Update status
    status_text = 'Running Visual Inspection...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % If run visual inspection checkbox has been checked
    if app.Algorithm_params.run_visual_inspection
        Visual_inspection = Visual_Inspection (app.Recording_app,LFP,EMG,x,y,label_y,app.Output_path,app.Algorithm_params.continue_visual_inspection,app.EpochLengthValue,pre_pro_params,figure_parameters);
        % Make sure that the app will be focused
        drawnow();
        figure(rec_par.UIFigure)
        
        % Check if the visual inspection function has not been stopped in the
        % middle of the execution. If that is the case, stop the current
        % function
        if strcmp(app.Recording_app.Visual_Inspection_Status,'Break')
            % Presents a message in the main app status box
            app.StatusTextArea.Value = 'The sleep-wake cycle classification could not be finished';
            return  % Stop the execution of the current function
        end
        
        % Check if the inspection was finished
        if ~Visual_inspection.inspection_finished   % If it have not been finished (STOP the GMM)
            % Change status text and wait a little bit
            status_text = 'The visual inspection has been paused and saved...';
            change_status_text(app.Recording_app,status_text);
            drawnow() % Update any changes
            % Wait a few seconds, so the user can read the the status
            pause(5)
            % Close the Recording_app
            delete(app.Recording_app)
            % Finishes the running function
            return
        end
    else
        % Load the visual inpection data from the app.Output_path
        folder_file = fullfile(app.Output_path,'IDX_Visual_Inspection.mat');
        load(folder_file,'Visual_inspection')
        
        if ~Visual_inspection.inspection_finished   % If it have not been finished (STOP the GMM)
            % Change status text and wait a little bit
            status_text = sprintf('The visual inspection have not been finished. Select a finished visual inspection file.\nThe algorithm will be finished...');
            change_status_text(app.Recording_app,status_text);
            drawnow() % Update any changes
            % Wait a few seconds, so the user can read the the status
            pause(5)
            % Close the Recording_app
            delete(app.Recording_app)
            % Finishes the running function
            return
        end
    end
    clear prompt ip
    
    %% FIGURE: Visual Inspected data distribution
    
    %Update status
    status_text = 'FIGURE: Visual Inspected data distribution...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Plotting Visually Inspected data's PSD
    aux_vi_awa_Pxx_all_24=mean(LFP.Power_normalized(Visual_inspection.AWAKE_idx,figure_parameters.Fidx),1);
    aux_vi_awa_Pxx_all_24(exclude)=nan;
    aux_vi_sw_Pxx_all_24=mean(LFP.Power_normalized(Visual_inspection.NREM_idx,figure_parameters.Fidx),1);
    aux_vi_sw_Pxx_all_24(exclude)=nan;
    aux_vi_rem_Pxx_all_24=mean(LFP.Power_normalized(Visual_inspection.REM_idx,figure_parameters.Fidx),1);
    aux_vi_rem_Pxx_all_24(exclude)=nan;
    
    % To plot the Visually Inspected data over time
    aux_vi_awa=zeros(1,size(x,1));
    aux_vi_awa(Visual_inspection.AWAKE_idx)=1;
    aux_vi_sws=zeros(1,size(x,1));
    aux_vi_sws(Visual_inspection.NREM_idx)=1;
    aux_vi_rem=zeros(1,size(x,1));
    aux_vi_rem(Visual_inspection.REM_idx)=1;
    aux_plot=1:size(x,1);
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(221)
    loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(aux_vi_awa_Pxx_all_24,10),'Color',figure_parameters.color.awake,'linewidth',figure_parameters.lw);
    hold on
    loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(aux_vi_sw_Pxx_all_24,10),'Color',figure_parameters.color.nrem,'linewidth',figure_parameters.lw);
    loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(aux_vi_rem_Pxx_all_24,10),'Color',figure_parameters.color.rem,'linewidth',figure_parameters.lw);
    hold off
    xlim([1 80])
    ylim([.0001 0.1])
    yticks([.0001 .001 .01 0.1])
    xlabel('Frequency (Hz)')
    ylabel({'   PSD'; '(Power Norm.)'})
    set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
    box off
    legend('AWAKE','NREM','REM','Location','best')
    legend box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Power Spectrum Density','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(222)
    scatter(x(Visual_inspection.AWAKE_idx),y(Visual_inspection.AWAKE_idx),...
        figure_parameters.scatter_size,figure_parameters.color.awake,'.');
    hold on
    scatter(x(Visual_inspection.NREM_idx),y(Visual_inspection.NREM_idx),...
        figure_parameters.scatter_size,figure_parameters.color.nrem,'.');
    scatter(x(Visual_inspection.REM_idx),y(Visual_inspection.REM_idx),...
        figure_parameters.scatter_size,figure_parameters.color.rem,'.');
    hold off
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    box off
    legend ('AWAKE','NREM','REM','Location','best')
    legend box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Scatter plot','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(2,2,[3 4])
    plot(aux_plot,aux_vi_awa+4,'color',figure_parameters.color.awake,'LineWidth',figure_parameters.lw)
    hold on
    plot(aux_plot,aux_vi_sws+2,'color',figure_parameters.color.nrem,'LineWidth',figure_parameters.lw)
    plot(aux_plot,aux_vi_rem,'color',figure_parameters.color.rem,'LineWidth',figure_parameters.lw)
    hold off
    box off
    ylim([-1 6])
    xlim([0 size(x,1)])
    yticks([mean(aux_vi_rem) mean(aux_vi_sws+2) mean(aux_vi_awa+4)])
    yticklabels({'REM','NREM','AWAKE'})
    xticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):...
        size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
    xticklabels(figure_parameters.time_vector);
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Epochs selected','FontSize',figure_parameters.fontsize*1.2)
    
    set(gcf,'color','white')
    set(f,'PaperPositionMode','auto')
    sgtitle(['Visually Inspected Data distribution - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'Visually Inspected data distribution'),'-dpdf','-r0',f)
    
    close
    clear f aux*
    
    % Update the check and save it
    check_point_info.visual_inspection = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end


%% Calculating ROC curve in comparison with Visual Inspection data

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.ROC_curve) || ~check_point_info.status
    
    T=0:0.00001:1;
    
    %Update status
    status_text = 'Calculating ROC curve in comparison with Visual Inspection data...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
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
    
    % Update the check and save it
    check_point_info.ROC_curve = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','check_point_info','-append')
    
end

%% Calculating Optimal threshold using the point closest-to-(0,1)corner

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.optimal_threshold) || ~check_point_info.status
    
    %Update status
    status_text = 'Calculating Optimal threshold using the point closest-to-(0,1)corner...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
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
    
    % If there is any missing state
    if app.Algorithm_params.missing_state
        switch app.Algorithm_params.missing_state_name
            case 'WAKE'
                GMM.Selected_Threshold.AWAKE_value=1;
            case 'NREM'
                GMM.Selected_Threshold.NREM_value=1;
            case 'REM'
                GMM.Selected_Threshold.REM_value=1;
        end
    end
    
    clear optimal_threshold
    
    % Update the check and save it
    check_point_info.optimal_threshold = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'T','GMM','check_point_info','-append')
    
end

%% Defining the indices for each threshold

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.define_indx_thresh) || ~check_point_info.status
    
    %Update status
    status_text = 'Defining the indices for each threshold...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
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
    
    % Exclude artifact periods from the classification
    GMM_REM_All_Sort(artifact.LFP_epoch)=0;
    GMM.All_Sort(artifact.LFP_epoch)=-1;
    
    GMM_NREM_All_Sort(artifact.LFP_epoch)=0;
    GMM.All_Sort(artifact.LFP_epoch)=-1;
    
    GMM_WK_All_Sort(artifact.LFP_epoch)=0;
    GMM.All_Sort(artifact.LFP_epoch)=-1;
    
    GMM.Nonclassified(artifact.LFP_epoch)=0;
    GMM.not_classified_number=sum(GMM.Nonclassified);
    
    status_text = ['Number of nonclassified epochs = ' num2str(GMM.not_classified_number)];
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any status changes
    
    clear aux_*
    
    %% Plot figure artifacts
    
    % Call the function to plot the figures related to the artifact
    plot_artifact_figures(GMM,LFP,x,y,artifact,outputPath,app.Recording_app.InferiorEditField.Value,app.Recording_app.SuperiorEditField.Value,figure_parameters,app.EpochLengthValue)
    
    % Update the check and save it
    check_point_info.define_indx_thresh = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','GMM_*','check_point_info','-append')
    
end

%% Adding Nonclassified data: fitting in the highest GMM.Probability cluster

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.add_non_class) || ~check_point_info.status
    
    %Update status
    status_text = 'Adding Nonclassified data: fitting in the highest GMM.Probability cluster...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
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
                status_text = 'No epochs not classified!';
                change_status_text(app.Recording_app,status_text);
                drawnow() % Update any changes
            end
        end
    end
    
    clear aux* i
    
    % Update the check and save it
    check_point_info.add_non_class = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','GMM_*','check_point_info','-append')
    
end

%% Fixing data sorted in more than one cluster

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.fix_data) || ~check_point_info.status
    
    %Update status
    status_text = 'Fixing data sorted in more than one cluster...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Selecting the indexes of each state Epochs
    aux_WK=find(GMM_WK_All_Sort==1);
    aux_NREM=find(GMM_NREM_All_Sort==1);
    aux_REM=find(GMM_REM_All_Sort==1);
    
    aux_WK_NREM=[];
    aux_WK_REM=[];
    aux_NREM_REM=[];
    aux_all=[];
    
    % Get the intersections
    aux_NREM_REM = intersect(aux_NREM,aux_REM);
    aux_WK_REM = intersect(aux_WK,aux_REM);
    aux_WK_NREM = intersect(aux_WK,aux_NREM);
    aux_all = intersect(aux_WK_NREM,aux_NREM_REM);
    
    % Fitting to highest probability cluster
    if isempty(cat(1,aux_WK_NREM,aux_NREM_REM,aux_WK_REM))
        status_text = 'No Epochs ambiguously sorted';
        change_status_text(app.Recording_app,status_text);
        drawnow() % Update any changes
    else
        for i=1:size(aux_all,1)
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
        
        for i=1:size(aux_NREM_REM,1)
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
        
        for i=1:size(aux_WK_NREM,1)
            if GMM.Prob.AWAKE(aux_WK_NREM(i)) >= GMM.Prob.NREM(aux_WK_NREM(i))
                GMM_WK_All_Sort(aux_WK_NREM(i))=1;
                GMM_NREM_All_Sort(aux_WK_NREM(i))=0;
            elseif GMM.Prob.AWAKE(aux_WK_NREM(i)) < GMM.Prob.NREM(aux_WK_NREM(i))
                GMM_WK_All_Sort(aux_WK_NREM(i))=0;
                GMM_NREM_All_Sort(aux_WK_NREM(i))=1;
            end
        end
        
        for i=1:size(aux_WK_REM,1)
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
    
    % Update the check and save it
    check_point_info.fix_data = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM_*','check_point_info','-append')
    
end

%% Find the transitions between nREM - REM

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.find_transitions_rem_nrem) || ~check_point_info.status
    
    %Update status
    status_text = 'Finding transitions between NREM and REM...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Check if the user has chosen to get the transitions between nREM - REM
    if app.Recording_app.ClassifythetransitionsbetweenNREMandREMCheckBox.Value
        % GMM_Transition = transition periods between NREM and REM
        [GMM,GMM_Transition_NREM_REM] = find_nrem_rem_transition(GMM,logical(GMM_NREM_All_Sort),logical(GMM_REM_All_Sort));
    else
        % Produce a zero (nx1) vector to the transition
        GMM_Transition_NREM_REM = zeros(length(GMM_WK_All_Sort),1);
    end
    
    % Update the check and save it
    check_point_info.find_transitions_rem_nrem = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','GMM_Transition_NREM_REM','check_point_info','-append')
    
end

%% Redifining GMM.All_Sort

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.redefine_gmm) || ~check_point_info.status
    
    %Update status
    status_text = 'Redifining GMM.All_Sort...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    GMM.All_Sort(GMM_WK_All_Sort==1) = 3;
    GMM.All_Sort(GMM_NREM_All_Sort==1) = 2;
    GMM.All_Sort(GMM_REM_All_Sort==1) = 1;
    GMM.All_Sort(GMM_Transition_NREM_REM==1) = 5;
    
    clear GMM_WK_All_Sort GMM_NREM_All_Sort GMM_REM_All_Sort
    
    %% Computing AUC
    
    GMM.AUC.AWAKE_TP=round(trapz(T,GMM.All_Threshold.TP_AWK),2);
    GMM.AUC.NREM_TP=round(trapz(T,GMM.All_Threshold.TP_SWS),2);
    GMM.AUC.REM_TP=round(trapz(T,GMM.All_Threshold.TP_REM),2);
    
    GMM.AUC.AWAKE_FP=round(trapz(T,GMM.All_Threshold.FP_AWK),2);
    GMM.AUC.NREM_FP=round(trapz(T,GMM.All_Threshold.FP_SWS),2);
    GMM.AUC.REM_FP=round(trapz(T,GMM.All_Threshold.FP_REM),2);
    
    % Update the check and save it
    check_point_info.redefine_gmm = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','check_point_info','-append')
    
end

%% Plotting the ROC curve WITH THRESHOLD

% % Check if the check point option e enable and if this step has already
% % been done
% if (check_point_info.status && ~check_point_info.plot_ROC) || ~check_point_info.status
%
%     %Update status
%     status_text = 'Plotting the ROC curve WITH THRESHOLD...';
%     change_status_text(app.Recording_app,status_text);
%     drawnow() % Update any changes
%
%     f=figure('PaperSize', [21 29.7],'visible','off');
%     subplot(331)
%     scatter(x,y,figure_parameters.scatter_size,GMM.Prob.AWAKE,'.');
%     ylabel(label_y);
%     xlabel('zEMG');
%     xlim(figure_parameters.limx)
%     ylim(figure_parameters.limy)
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title('Posterior Probability:','FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(334)
%     scatter(x,y,figure_parameters.scatter_size,GMM.Prob.NREM,'.');
%     ylabel(label_y);
%     xlabel('zEMG');
%     xlim(figure_parameters.limx)
%     ylim(figure_parameters.limy)
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%
%     subplot(337)
%     scatter(x,y,figure_parameters.scatter_size,GMM.Prob.REM,'.');
%     ylabel(label_y);
%     xlabel('zEMG');
%     xlim(figure_parameters.limx)
%     ylim(figure_parameters.limy)
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%
%     subplot(332)
%     plot(GMM.All_Threshold.FP_AWK,GMM.All_Threshold.TP_AWK,'k','linewidth',figure_parameters.lw);
%     colormap(jet)
%     hold on
%     scatter(GMM.All_Threshold.FP_AWK,GMM.All_Threshold.TP_AWK,figure_parameters.scatter_size,T,'o','Fill');
%     scatter(GMM.All_Threshold.FP_AWK(GMM.Selected_Threshold.AWAKE_idx),GMM.All_Threshold.TP_AWK(GMM.Selected_Threshold.AWAKE_idx),figure_parameters.scatter_size*10,'xk','Linewidth',figure_parameters.lw*3);
%     hold off
%     box off
%     xlim([0 1])
%     ylim([0 1])
%     xlabel('False positive rate')
%     ylabel('True positive rate')
%     set(gca, 'xtick', [0 .2 .4 .6 .8 1])
%     set(gca, 'ytick', [0 .2 .4 .6 .8 1])
%     text (1/5,1/2,...
%         {['TP = ' num2str(GMM.All_Threshold.TP_AWK(GMM.Selected_Threshold.AWAKE_idx))],...
%         ['FP = ' num2str(GMM.All_Threshold.FP_AWK(GMM.Selected_Threshold.AWAKE_idx))],...
%         ['Thres. = ' num2str(floor(GMM.Selected_Threshold.AWAKE_value*100)) '%'],...
%         ['AUC TP = ' num2str(GMM.AUC.AWAKE_TP)],...
%         ['AUC FP = ' num2str(GMM.AUC.AWAKE_FP)]},...
%         'fontsize',figure_parameters.fontsize);
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title({'Selecting threshold:','AWAKE'},'FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(335)
%     plot(GMM.All_Threshold.FP_SWS,GMM.All_Threshold.TP_SWS,'k','linewidth',1.5);
%     colormap(jet)
%     hold on
%     scatter(GMM.All_Threshold.FP_SWS,GMM.All_Threshold.TP_SWS,figure_parameters.scatter_size,T,'o','Fill');
%     scatter(GMM.All_Threshold.FP_SWS(GMM.Selected_Threshold.NREM_idx),GMM.All_Threshold.TP_SWS(GMM.Selected_Threshold.NREM_idx),figure_parameters.scatter_size*10,'xk','Linewidth',figure_parameters.lw*3);
%     hold off
%     box off
%     xlim([0 1])
%     ylim([0 1])
%     xlabel('False positive rate')
%     ylabel('True positive rate')
%     set(gca, 'xtick', [0 .2 .4 .6 .8 1])
%     set(gca, 'ytick', [0 .2 .4 .6 .8 1])
%     text (1/4,1/2,...
%         {['TP = ' num2str(GMM.All_Threshold.TP_SWS(GMM.Selected_Threshold.NREM_idx))],...
%         ['FP = ' num2str(GMM.All_Threshold.FP_SWS(GMM.Selected_Threshold.NREM_idx))],...
%         ['Thres. = ' num2str(floor(GMM.Selected_Threshold.NREM_value*100)) '%'],...
%         ['AUC TP = ' num2str(GMM.AUC.NREM_TP)],...
%         ['AUC FP = ' num2str(GMM.AUC.NREM_FP)]},...
%         'fontsize',figure_parameters.fontsize);
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title({'NREM'},'FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(338)
%     plot(GMM.All_Threshold.FP_REM,GMM.All_Threshold.TP_REM,'k','linewidth',1.5);
%     colormap(jet)
%     hold on
%     scatter(GMM.All_Threshold.FP_REM,GMM.All_Threshold.TP_REM,figure_parameters.scatter_size,T,'o','Fill');
%     scatter(GMM.All_Threshold.FP_REM(GMM.Selected_Threshold.REM_idx),GMM.All_Threshold.TP_REM(GMM.Selected_Threshold.REM_idx),figure_parameters.scatter_size*10,'xk','Linewidth',figure_parameters.lw*3);
%     hold off
%     box off
%     xlim([0 1])
%     ylim([0 1])
%     xlabel('False positive rate')
%     ylabel('True positive rate')
%     set(gca, 'xtick', [0 .2 .4 .6 .8 1])
%     set(gca, 'ytick', [0 .2 .4 .6 .8 1])
%     text (1/4,1/2,...
%         {['TP = ' num2str(GMM.All_Threshold.TP_REM(GMM.Selected_Threshold.REM_idx))],...
%         ['FP = ' num2str(GMM.All_Threshold.FP_REM(GMM.Selected_Threshold.REM_idx))],...
%         ['Thres. = ' num2str(floor(GMM.Selected_Threshold.REM_value*100)) '%'],...
%         ['AUC TP = ' num2str(GMM.AUC.REM_TP)],...
%         ['AUC FP = ' num2str(GMM.AUC.REM_FP)]},...
%         'fontsize',figure_parameters.fontsize);
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title({'REM'},'FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(333)
%     scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
%         figure_parameters.color.awake,'.');
%     ylabel(label_y);
%     xlabel('zEMG');
%     caxis([0 1])
%     axis([0.1 0.6 0 4])
%     xlim(figure_parameters.limx)
%     ylim(figure_parameters.limy)
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title({'Final Classification:','AWAKE'},'FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(336)
%     scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
%         figure_parameters.color.nrem,'.');
%     ylabel(label_y);
%     xlabel('zEMG');
%     caxis([0 1])
%     axis([0.1 0.6 0 4])
%     xlim(figure_parameters.limx)
%     ylim(figure_parameters.limy)
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title({'NREM'},'FontSize',figure_parameters.fontsize*1.2)
%
%     subplot(339)
%     scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
%         figure_parameters.color.rem,'.');
%     ylabel(label_y);
%     xlabel('zEMG');
%     caxis([0 1])
%     axis([0.1 0.6 0 4])
%     xlim(figure_parameters.limx)
%     ylim(figure_parameters.limy)
%     set(gca,'fontsize',figure_parameters.fontsize)
%     set(gca,'Linewidth',figure_parameters.lw)
%     set(gca,'Tickdir','out')
%     title({'REM'},'FontSize',figure_parameters.fontsize*1.2)
%
%     f.Renderer='Painters';
%     set(gcf,'color','white')
%     sgtitle(['Clusters Formation - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
%     print('-bestfit',fullfile(outputPath,'Clusters Formation'),'-dpdf','-r0',f)
%
%     close
%     clear c s hobj h f
% %     clear c s hobj h p* f
%
%     % Update the check and save it
%     check_point_info.plot_ROC = true;
%     save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
%
% end

%% Plotting the ROC curve WITH THRESHOLD

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.plot_ROC) || ~check_point_info.status
    
    %Update status
    status_text = 'Plotting the ROC curve WITH THRESHOLD...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    aux_nbins=10;
    aux_color_bins=[.6 .6 .6];
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(356)
    c=colorbar;
    colormap(jet);
    c.TickDirection='out';
    c.Location='west';
    s=get(c,'position');
    c.Position=[s(1) s(2)/1.5 s(3)*2 s(4)*2];
    axis off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    aux_h=text(s(1)-s(1)*2.5,s(2)-s(2)*1.5,'GMM: Posterior Probability','FontSize',figure_parameters.fontsize*1.2);
    set(aux_h,'Rotation',90);
    
    subplot(352)
    scatter(x,y,figure_parameters.scatter_size,GMM.Prob.AWAKE,'.');
    ylim(figure_parameters.limy)
    ylabel(label_y);
    xlim(figure_parameters.limx)
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title({'GMM clusters:','Cluster 1'},'FontSize',figure_parameters.fontsize*1.2)
    
    subplot(357)
    scatter(x,y,figure_parameters.scatter_size,GMM.Prob.NREM,'.');
    ylim(figure_parameters.limy)
    ylabel(label_y);
    xlim(figure_parameters.limx)
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Cluster 2','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,5,12)
    scatter(x,y,figure_parameters.scatter_size,GMM.Prob.REM,'.');
    ylim(figure_parameters.limy)
    ylabel(label_y);
    xlim(figure_parameters.limx)
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Cluster 3','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(353)
    histogram(GMM.Prob.AWAKE,aux_nbins,'Normalization','probability','EdgeColor','none',...
        'FaceAlpha',figure_parameters.transparecy_fa,'FaceColor',aux_color_bins)
    box off
    hold on
    xline(GMM.Selected_Threshold.AWAKE_value,'Linewidth',figure_parameters.lw*2,'color','k')
    hold off
    ylim([0 1])
    yticks(0:.2:1)
    ylabel('Probability')
    xlim([0 1])
    xticks(0:.2:1)
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title({'Posterior probability','Cluster 1'},'FontSize',figure_parameters.fontsize*1.2)
    
    subplot(358)
    histogram(GMM.Prob.NREM,aux_nbins,'Normalization','probability','EdgeColor','none',...
        'FaceAlpha',figure_parameters.transparecy_fa,'FaceColor',[.6 .6 .6])
    box off
    hold on
    xline(GMM.Selected_Threshold.NREM_value,'Linewidth',figure_parameters.lw*2,'color','k')
    hold off
    ylim([0 1])
    yticks(0:.2:1)
    ylabel('Probability')
    xlim([0 1])
    xticks(0:.2:1)
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Cluster 2','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,5,13)
    histogram(GMM.Prob.REM,aux_nbins,'Normalization','probability','EdgeColor','none',...
        'FaceAlpha',figure_parameters.transparecy_fa,'FaceColor',aux_color_bins)
    box off
    hold on
    xline(GMM.Selected_Threshold.REM_value,'Linewidth',figure_parameters.lw*2,'color','k')
    hold off
    ylim([0 1])
    yticks(0:.2:1)
    ylabel('Probability')
    xlim([0 1])
    xticks(0:.2:1)
    xlabel('Posterior probability')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Cluster 3','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(354)
    plot(GMM.All_Threshold.FP_AWK,GMM.All_Threshold.TP_AWK,'k','linewidth',figure_parameters.lw);
    colormap(jet)
    hold on
    scatter(GMM.All_Threshold.FP_AWK,GMM.All_Threshold.TP_AWK,figure_parameters.scatter_size,T,'o','Fill');
    scatter(GMM.All_Threshold.FP_AWK(GMM.Selected_Threshold.AWAKE_idx),GMM.All_Threshold.TP_AWK(GMM.Selected_Threshold.AWAKE_idx),figure_parameters.scatter_size*10,'xk','Linewidth',figure_parameters.lw*3);
    hold off
    box off
    ylim([0 1])
    ylabel('True positive rate')
    yticks([0 .2 .4 .6 .8 1])
    xlim([0 1])
    xticks([0 .2 .4 .6 .8 1])
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title({'Selecting threshold:','Cluster 1'},'FontSize',figure_parameters.fontsize*1.2)
    
    subplot(359)
    plot(GMM.All_Threshold.FP_SWS,GMM.All_Threshold.TP_SWS,'k','linewidth',1.5);
    colormap(jet)
    hold on
    scatter(GMM.All_Threshold.FP_SWS,GMM.All_Threshold.TP_SWS,figure_parameters.scatter_size,T,'o','Fill');
    scatter(GMM.All_Threshold.FP_SWS(GMM.Selected_Threshold.NREM_idx),GMM.All_Threshold.TP_SWS(GMM.Selected_Threshold.NREM_idx),figure_parameters.scatter_size*10,'xk','Linewidth',figure_parameters.lw*3);
    hold off
    box off
    ylim([0 1])
    yticks([0 .2 .4 .6 .8 1])
    ylabel('True positive rate')
    xlim([0 1])
    xticks([0 .2 .4 .6 .8 1])
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Cluster 2','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,5,14)
    plot(GMM.All_Threshold.FP_REM,GMM.All_Threshold.TP_REM,'k','linewidth',1.5);
    colormap(jet)
    hold on
    scatter(GMM.All_Threshold.FP_REM,GMM.All_Threshold.TP_REM,figure_parameters.scatter_size,T,'o','Fill');
    scatter(GMM.All_Threshold.FP_REM(GMM.Selected_Threshold.REM_idx),GMM.All_Threshold.TP_REM(GMM.Selected_Threshold.REM_idx),figure_parameters.scatter_size*10,'xk','Linewidth',figure_parameters.lw*3);
    hold off
    box off
    ylim([0 1])
    yticks([0 .2 .4 .6 .8 1])
    ylabel('True positive rate')
    xlim([0 1])
    xticks([0 .2 .4 .6 .8 1])
    xlabel('False positive rate')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Cluster 3','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(355)
    scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
        figure_parameters.color.awake,'.');
    ylabel(label_y);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title({'Final Classification:','AWAKE'},'FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,5,10)
    scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
        figure_parameters.color.nrem,'.');
    ylabel(label_y);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    xticklabels('')
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title({'NREM'},'FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,5,15)
    scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
        figure_parameters.color.rem,'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title({'REM'},'FontSize',figure_parameters.fontsize*1.2)
    
    
    f.Renderer='Painters';
    set(gcf,'color','white')
    sgtitle(['Clusters Formation - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'Clusters Formation'),'-dpdf','-r0',f)
    
    close
    clear c s hobj h f aux_nbins aux_color_bins aux_h
    
    % Update the check and save it
    check_point_info.plot_ROC = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Final Clusters

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.final_clusters) || ~check_point_info.status
    
    %Update status
    status_text = 'Final Clusters...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    f1=figure('PaperSize', [21 29.7],'visible','off');
    subplot(221)
    scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
        figure_parameters.color.awake,'.');
    hold on
    scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
        figure_parameters.color.nrem,'.');
    scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
        figure_parameters.color.rem,'.');
    scatter(x(GMM.All_Sort==5),y(GMM.All_Sort==5),figure_parameters.scatter_size,...
        figure_parameters.color.transition_nrem_rem,'.');
    hold off
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    if ~isempty(find(GMM.All_Sort==5, 1))
        legend('AWAKE','NREM','REM','NREM<->REM','Location','best')
    else
        legend('AWAKE','NREM','REM','Location','best')
    end
    legend box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('All States','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(222)
    scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
        figure_parameters.color.awake,'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Awake State','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(223)
    scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
        figure_parameters.color.nrem,'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('NREM sleep','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(224)
    scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
        figure_parameters.color.rem,'.');
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('REM sleep','FontSize',figure_parameters.fontsize*1.2)
    
    sgtitle(['Final Clusters - ' recording_params.recording_group],'FontSize', 45)
    set(gcf,'color',[1 1 1]);
    print('-bestfit',fullfile(outputPath,'Final Clusters'),'-dpdf','-r0',f1)
    
    close
    clear f1
    
    % Update the check and save it
    check_point_info.final_clusters = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Final Classification over time
%
% % Check if the check point option e enable and if this step has already
% % been done
% if (check_point_info.status && ~check_point_info.final_class) || ~check_point_info.status
%
%     %Update status
%     status_text = 'Final Clusters...';
%     change_status_text(app.Recording_app,status_text);
%     drawnow() % Update any changes
%
%     % Generating separated hypnogram
%     aux_aw=zeros(size(GMM.All_Sort,1),1);
%     aux_aw(GMM.All_Sort==3)=1;
%     aux_sw=zeros(size(GMM.All_Sort,1),1);
%     aux_sw(GMM.All_Sort==2)=1;
%     aux_re=zeros(size(GMM.All_Sort,1),1);
%     aux_re(GMM.All_Sort==1)=1;
%
%     % Frequency bands
%     freq_aux_delta=zscore(LFP.Frequency_bands.Delta)';
%     freq_aux_theta=zscore(LFP.Frequency_bands.Theta)';
%     freq_aux_beta=zscore(LFP.Frequency_bands.Beta)';
%     freq_aux_low_gamma=zscore(LFP.Frequency_bands.Low_Gamma)';
%     freq_aux_high_gamma=zscore(LFP.Frequency_bands.High_Gamma)';
%
%     f2=figure('PaperSize', [21 29.7],'visible','off');
%     for jj=1:figure_parameters.figure_over_time
%         subplot(2,1,1)
%         plot(smooth(freq_aux_delta(1:end/figure_parameters.figure_over_time),figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%         hold on
%         plot(smooth(freq_aux_theta(1:end/figure_parameters.figure_over_time)+3,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%         plot(smooth(freq_aux_beta(1:end/figure_parameters.figure_over_time)+6,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%         plot(smooth(freq_aux_low_gamma(1:end/figure_parameters.figure_over_time)+9,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%         plot(smooth(freq_aux_high_gamma(1:end/figure_parameters.figure_over_time)+12,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%         plot(figure_parameters.time_scale+13.5,'-k','LineWidth',figure_parameters.lw*2,'HandleVisibility','off');
%         text(1,15.2,'1 hour','fontsize',figure_parameters.fontsize)
%         hold off
%         box off
%         ylim([-3 16])
%         xlim([1 size(x,1)/figure_parameters.figure_over_time+1])
%         yticks([mean(freq_aux_delta) mean(freq_aux_theta+3) mean(freq_aux_beta+6) mean(freq_aux_low_gamma+9) mean(freq_aux_high_gamma+12)])
%         yticklabels({'zDelta','zTheta','zBeta','zLow-Gamma','zHigh-Gamma'})
%         xticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
%         if figure_parameters.figure_over_time==2
%             xticklabels(figure_parameters.time_vector(1:end/figure_parameters.figure_over_time+1));
%         else
%             xticklabels(figure_parameters.time_vector(1:end/figure_parameters.figure_over_time));
%         end
%         set(gca,'fontsize',figure_parameters.fontsize)
%         set(gca,'Linewidth',figure_parameters.lw)
%         set(gca,'Tickdir','out')
%
%         if figure_parameters.figure_over_time==2
%             subplot(2,1,2)
%             plot(smooth(freq_aux_delta(end/2:end),figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%             hold on
%             plot(smooth(freq_aux_theta(end/2:end)+3,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%             plot(smooth(freq_aux_beta(end/2:end)+6,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%             plot(smooth(freq_aux_low_gamma(end/2:end)+9,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%             plot(smooth(freq_aux_high_gamma(end/2:end)+12,figure_parameters.smoothing_value),'linewidth',figure_parameters.lw)
%             plot(figure_parameters.time_scale+13.5,'-k','LineWidth',figure_parameters.lw*2,'HandleVisibility','off');
%             text(1,15.2,'1 hour','fontsize',figure_parameters.fontsize)
%             hold off
%             box off
%             ylim([-3 16])
%             xlim([1 size(x,1)/figure_parameters.figure_over_time+1])
%             yticks([mean(freq_aux_delta) mean(freq_aux_theta+3) mean(freq_aux_beta+6) mean(freq_aux_low_gamma+9) mean(freq_aux_high_gamma+12)])
%             yticklabels({'zDelta','zTheta','zBeta','zLow-Gamma','zHigh-Gamma'})
%             xticks([1:size(figure_parameters.time_color,2)/(size(figure_parameters.time_vector,1)-1):size(figure_parameters.time_color,2) size(figure_parameters.time_color,2)])
%             xticklabels(figure_parameters.time_vector(end/2:end));
%             set(gca,'fontsize',figure_parameters.fontsize)
%             set(gca,'Linewidth',figure_parameters.lw)
%             set(gca,'Tickdir','out')
%         end
%     end
%
%     set(gcf,'color',[1 1 1]);
%     sgtitle(['Final Classification over time - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
%     print('-bestfit',fullfile(outputPath,'Final Classification over time'),'-dpdf','-r0',f2)
%
%     close
%     clear f2 jj hl hobj aux*
%
%     % Update the check and save it
%     check_point_info.final_class = true;
%     save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
%
% end


%% Final Classification over time

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.final_class) || ~check_point_info.status
    
    %Update status
    status_text = 'Final Clusters...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Generating separated hypnogram
    aux_aw=nan(size(GMM.All_Sort,1),1);
    aux_aw(GMM.All_Sort==3)=1;
    aux_sw=nan(size(GMM.All_Sort,1),1);
    aux_sw(GMM.All_Sort==2)=1;
    aux_re=nan(size(GMM.All_Sort,1),1);
    aux_re(GMM.All_Sort==1)=1;
    aux_nrem_rem=nan(size(GMM.All_Sort,1),1);
    aux_nrem_rem(GMM.All_Sort==5)=1;
    
    figure_parameters.lw2=30;
    
    f2=figure('PaperSize', [21 29.7], 'visible', 'off');
    for jj=1:figure_parameters.figure_over_time
        subplot(211)
        hold on
        plot(aux_aw(1:end/figure_parameters.figure_over_time)+7,'Color',figure_parameters.color.awake,'linewidth',figure_parameters.lw2);
        plot(aux_sw(1:end/figure_parameters.figure_over_time)+6,'Color',figure_parameters.color.nrem,'linewidth',figure_parameters.lw2);
        plot(aux_re(1:end/figure_parameters.figure_over_time)+5,'color',figure_parameters.color.rem,'linewidth',figure_parameters.lw2);
        plot(aux_nrem_rem(1:end/figure_parameters.figure_over_time)+5.5,'Color',figure_parameters.color.transition_nrem_rem,'linewidth',figure_parameters.lw2);
        plot(smooth(y(1:end/figure_parameters.figure_over_time),figure_parameters.smoothing_value)+3,'Color',[0 0 .6],'linewidth',figure_parameters.lw);
        plot(smooth(x(1:end/figure_parameters.figure_over_time),figure_parameters.smoothing_value),'Color',figure_parameters.color.EMG,'linewidth',figure_parameters.lw);
        plot(figure_parameters.time_scale+8.5,'-k','LineWidth',figure_parameters.lw*2,'HandleVisibility','off');
        text(1,10.2,'1 hour','fontsize',figure_parameters.fontsize)
        hold off
        box off
        ylim([-3 11])
        yticks([mean(x) mean(y+3) 6 7 8])
        %         yticks([mean(x) mean(y+3) mean(aux_re+5,'omitnan') mean(aux_sw+6,'omitnan') mean(aux_aw+7,'omitnan')])
        yticklabels({[figure_parameters.emg_accel, ' (z-score)'],label_y,'REM','NREM','AWAKE'})
        if figure_parameters.figure_over_time==2
            xlim([1 size(x,1)/figure_parameters.figure_over_time])
            xticks([1:size(x,1)/(size(figure_parameters.time_vector,1)-1):...
                size(x,1)/figure_parameters.figure_over_time size(x,1)/figure_parameters.figure_over_time])
            xticklabels(figure_parameters.time_vector(1:end/figure_parameters.figure_over_time+1));
        else
            xlim([1 size(x,1)])
            xticks(round(linspace(1,size(x,1),size(figure_parameters.time_vector,1))))
            xticklabels(figure_parameters.time_vector(1:end));
        end
        set(gca,'fontsize',figure_parameters.fontsize)
        set(gca,'Linewidth',figure_parameters.lw)
        set(gca,'Tickdir','out')
        
        if figure_parameters.figure_over_time==2
            subplot(212)
            hold on
            plot(aux_aw(end/figure_parameters.figure_over_time:end)+7,'Color',figure_parameters.color.awake,'linewidth',figure_parameters.lw2);
            plot(aux_sw(end/figure_parameters.figure_over_time:end)+6,'Color',figure_parameters.color.nrem,'linewidth',figure_parameters.lw2);
            plot(aux_re(end/figure_parameters.figure_over_time:end)+5,'color',figure_parameters.color.rem,'linewidth',figure_parameters.lw2);
            plot(aux_nrem_rem(end/figure_parameters.figure_over_time:end)+5.5,'Color',figure_parameters.color.transition_nrem_rem,'linewidth',figure_parameters.lw2);
            plot(smooth(y(end/figure_parameters.figure_over_time:end),figure_parameters.smoothing_value)+3,'Color',[0 0 .6],'linewidth',figure_parameters.lw);
            plot(smooth(x(end/figure_parameters.figure_over_time:end),figure_parameters.smoothing_value),'Color',figure_parameters.color.EMG,'linewidth',figure_parameters.lw);
            plot(figure_parameters.time_scale+8.5,'-k','LineWidth',figure_parameters.lw*2,'HandleVisibility','off');
            text(1,10.2,'1 hour','fontsize',figure_parameters.fontsize)
            hold off
            box off
            ylim([-3 11])
            yticks([mean(x) mean(y+3) 6 7 8])
            yticklabels({[figure_parameters.emg_accel, ' (z-score)'],label_y,'REM','NREM','AWAKE'})
            xlim([1 size(x,1)/figure_parameters.figure_over_time])
            xticks([1:size(x,1)/(size(figure_parameters.time_vector,1)-1):...
                size(x,1)/figure_parameters.figure_over_time size(x,1)/figure_parameters.figure_over_time])
            xticklabels(figure_parameters.time_vector(end/2:end));
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
        end
    end
    
    set(gcf,'color',[1 1 1]);
    sgtitle(['Final Classification over time - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'Final Classification over time'),'-dpdf','-r0',f2)
    
    close
    clear f2 jj hl hobj aux*
    
    % Update the check and save it
    check_point_info.final_class = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% True Positive Rate and False Positive Rate with all data sorted

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.tp_fp_rate) || ~check_point_info.status
    
    %Update status
    status_text = 'True Positive Rate and False Positive Rate with all data sorted...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
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
    
    % Update the check and save it
    check_point_info.tp_fp_rate = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'GMM','check_point_info','-append')
    
end

%% Plotting comparisons

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.plot_comparison) || ~check_point_info.status
    
    % Update status
    status_text = 'Plotting comparisons...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    % Load the Training_data
    % Get the main_app_pathway (important, since the trained data file is
    % stored in this same folder)
    [main_app_pathway,~,~] = fileparts(which('RMS_pwelch_integrate'));
    trained_data_filepathway = fullfile(main_app_pathway,'Trained_data.mat');
    
    % Load the Trained_data.m file
    load(trained_data_filepathway,'Training_data')
    
    f3=figure('PaperSize', [21 29.7],'visible','off');
    subplot(3,2,1)
    aux_TP_FP=[GMM.ROC.TP_AWAKE GMM.ROC.FP_AWAKE;...
        GMM.ROC.TP_NREM GMM.ROC.FP_NREM;...
        GMM.ROC.TP_REM GMM.ROC.FP_REM];
    figure_parameters.time_scale=bar(aux_TP_FP);
    width = figure_parameters.time_scale.BarWidth;
    for i=1:length(aux_TP_FP(:, 1))
        row = aux_TP_FP(i, :);
        % 0.5 is approximate net width of white spacings per group
        offset = ((width) / length(row)) / 2;
        aux = linspace(i-offset, i+offset, length(row))+0.08;
        text(aux,row,num2str(row'),'vert','bottom','horiz','center','FontSize',figure_parameters.fontsize/1.5);
    end
    box off
    yticks([0 .2 .4 .6 .8 1])
    ylim([0 1])
    ylabel('Rate')
    xticklabels({'AWAKE' 'NREM' 'REM'})
    legend(figure_parameters.time_scale,'True Positive Rate','False Positive Rate',...
        'Orientation','vertical','Location','eastoutside');
    legend box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(323)
    scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
        figure_parameters.color.awake,'.');
    hold on
    scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
        figure_parameters.color.nrem,'.');
    scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
        figure_parameters.color.rem,'.');
    hold off
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    title('All States','FontSize',figure_parameters.fontsize*1.2)
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    legend('AWAKE','NREM','REM','Location','best')
    legend box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Final Classification','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(3,2,6)
    scatter(x(Visual_inspection.All_sort==3),y(Visual_inspection.All_sort==3),figure_parameters.scatter_size,...
        figure_parameters.color.awake,'.');
    hold on
    scatter(x(Visual_inspection.All_sort==2),y(Visual_inspection.All_sort==2),figure_parameters.scatter_size,...
        figure_parameters.color.nrem,'.');
    scatter(x(Visual_inspection.All_sort==1),y(Visual_inspection.All_sort==1),figure_parameters.scatter_size,...
        figure_parameters.color.rem,'.');
    scatter(x(GMM.All_Sort==5),y(GMM.All_Sort==5),figure_parameters.scatter_size,...
        figure_parameters.color.transition_nrem_rem,'.');
    hold off
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    if ~isempty(find(GMM.All_Sort==5, 1))
        legend('AWAKE','NREM','REM','NREM<->REM','Location','best')
    else
        legend('AWAKE','NREM','REM','Location','best')
    end
    legend box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Visually Inspected Data','FontSize',figure_parameters.fontsize*1.2)
    
    % Only plot the Training model data if it was used
    if app.Algorithm_params.training_dataset    % If the trained GMM was enabled
        subplot(325)
        scatter(Training_data.EMG_used(Training_data.Awake),Training_data.LFP_used(Training_data.Awake),figure_parameters.scatter_size,...
            figure_parameters.color.awake,'.');
        hold on
        scatter(Training_data.EMG_used(Training_data.NREM),Training_data.LFP_used(Training_data.NREM),figure_parameters.scatter_size,...
            figure_parameters.color.nrem,'.');
        scatter(Training_data.EMG_used(Training_data.REM),Training_data.LFP_used(Training_data.REM),figure_parameters.scatter_size,...
            figure_parameters.color.rem,'.');
        hold off
        ylabel(label_y);
        xlabel([figure_parameters.emg_accel ' (z-score)']);
        xlim(figure_parameters.limx)
        ylim(figure_parameters.limy)
        legend('AWAKE','NREM','REM','Location','best')
        legend box off
        set(gca,'fontsize',figure_parameters.fontsize)
        set(gca,'Linewidth',figure_parameters.lw)
        set(gca,'Tickdir','out')
        title('Training Model Data','FontSize',figure_parameters.fontsize*1.2)
    end
    
    % Plotting global PSD
    total_awa_Pxx_all_24=mean(LFP.Power_normalized(GMM.All_Sort==3,figure_parameters.Fidx),1);
    total_awa_Pxx_all_24(exclude)=nan;
    total_sw_Pxx_all_24=mean(LFP.Power_normalized(GMM.All_Sort==2,figure_parameters.Fidx),1);
    total_sw_Pxx_all_24(exclude)=nan;
    total_rem_Pxx_all_24=mean(LFP.Power_normalized(GMM.All_Sort==1,figure_parameters.Fidx),1);
    total_rem_Pxx_all_24(exclude)=nan;
    total_transition_nrem_rem_Pxx_all_24=mean(LFP.Power_normalized(GMM.All_Sort==5,figure_parameters.Fidx),1);
    total_transition_nrem_rem_Pxx_all_24(exclude)=nan;
    
    subplot(3,2,[2 4])
    loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(total_awa_Pxx_all_24,10),'Color',figure_parameters.color.awake,'linewidth',figure_parameters.lw*2);
    hold on
    loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(total_sw_Pxx_all_24,10),'Color',figure_parameters.color.nrem,'linewidth',figure_parameters.lw*2);
    loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(total_rem_Pxx_all_24,10),'Color',figure_parameters.color.rem,'linewidth',figure_parameters.lw*2);
    loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(total_transition_nrem_rem_Pxx_all_24,10),'Color',figure_parameters.color.transition_nrem_rem,'linewidth',figure_parameters.lw*2);
    hold off
    box off
    xlim([1 80])
    ylim([.0001 0.1])
    yticks([.0001 .001 .01 0.1])
    xlabel('Frequency (Hz)')
    ylabel({'   PSD'; '(Power Norm.)'})
    title ('Power Spectrum Density')
    xticks([0 2 4 6 8 10 20 40 60 80])
    if ~isempty(find(GMM.All_Sort==5, 1))
        legend('AWAKE','NREM','REM','NREM<->REM','Location','best')
    else
        legend('AWAKE','NREM','REM','Location','best')
    end
    legend box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    set(gcf,'color','white')
    sgtitle(['Final Performance - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'Final Performance'),'-dpdf','-r0',f3)
    
    close
    clear f3 aux_TP_FP b width i row offset aux total*
    
    % Update the check and save it
    check_point_info.plot_comparison = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Final frequency bands distribution

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.final_freq) || ~check_point_info.status
    
    %Update status
    status_text = 'Final frequency bands distribution...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    aux_GMM.All_Sort=nan(size(GMM.All_Sort,1),1);
    aux_GMM.All_Sort(GMM.All_Sort==3)=-1;
    aux_GMM.All_Sort(GMM.All_Sort==2)=0;
    aux_GMM.All_Sort(GMM.All_Sort==1)=1;
    
    freq_aux_delta=zscore(LFP.Frequency_bands.Delta)';
    freq_aux_theta=zscore(LFP.Frequency_bands.Theta)';
    freq_aux_beta=zscore(LFP.Frequency_bands.Beta)';
    freq_aux_low_gamma=zscore(LFP.Frequency_bands.Low_Gamma)';
    freq_aux_high_gamma=zscore(LFP.Frequency_bands.High_Gamma)';
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(6,7,8)
    gscatter(nan(1,size(x,1)),nan(1,size(x,1)),aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem])
    legend('AWAKE','NREM','REM','Location','southoutside','FontSize',figure_parameters.fontsize*1.2)
    box off
    axis off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Legend','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(6,7,[22 23 24 29 30 31 36 37 38])
    gscatter(x,y,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    legend off
    box off
    ylabel(label_y);
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limy)
    yticks(figure_parameters.limy(1)+1:2:16)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Final Distribution','FontSize',figure_parameters.fontsize*1.2)
    
    subplot(6,7,3)
    gscatter(freq_aux_high_gamma,freq_aux_delta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zHigh-Gamma');
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,4)
    gscatter(freq_aux_low_gamma,freq_aux_delta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zLow-Gamma');
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,5)
    gscatter(freq_aux_theta,freq_aux_delta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zTheta')
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,6)
    gscatter(freq_aux_beta,freq_aux_delta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zBeta');
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,7)
    gscatter(x,freq_aux_delta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylabel('zDelta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,11)
    gscatter(freq_aux_high_gamma,freq_aux_theta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zHigh-Gamma');
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,12)
    gscatter(freq_aux_low_gamma,freq_aux_theta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zLow-Gamma');
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,13)
    gscatter(freq_aux_beta,freq_aux_theta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zBeta');
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,14)
    gscatter(x,freq_aux_theta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylabel('zTheta')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,19)
    gscatter(freq_aux_high_gamma,freq_aux_beta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zHigh-Gamma')
    ylabel('zBeta');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,20)
    gscatter(freq_aux_low_gamma,freq_aux_beta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zLow-Gamma')
    ylabel('zBeta');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,21)
    gscatter(x,freq_aux_beta,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel([figure_parameters.emg_accel ' (z-score)'])
    ylabel('zBeta');
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,27)
    gscatter(freq_aux_high_gamma,freq_aux_low_gamma,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel('zHigh-Gamma');
    ylabel('zLow-Gamma')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,28)
    gscatter(x,freq_aux_low_gamma,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylabel('zLow-Gamma')
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,35)
    gscatter(x,freq_aux_high_gamma,aux_GMM.All_Sort,[figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
    legend off
    box off
    ylabel('zHigh-Gamma')
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    xlim(figure_parameters.limx)
    ylim(figure_parameters.limx)
    yticks(figure_parameters.ticks_aux)
    xticks(figure_parameters.ticks_aux)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,2)
    histogram(freq_aux_delta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zDelta')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,10)
    histogram(freq_aux_theta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zTheta')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,18)
    histogram(freq_aux_beta,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zBeta')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,26)
    histogram(freq_aux_low_gamma,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zLow-Gamma')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,34)
    histogram(freq_aux_high_gamma,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title('zHigh-Gamma')
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(6,7,42)
    histogram(x,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
        'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
    ylabel('Prob.')
    xlabel('Z-scores')
    title([figure_parameters.emg_accel ' (z-score)'])
    ylim([0 .08])
    yticks(figure_parameters.GMM_Prob_axiss)
    xlim(figure_parameters.limx)
    xticks(figure_parameters.ticks_aux)
    box off
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    set(gcf,'color','white')
    sgtitle(['State distribution for frequency bands - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-bestfit',fullfile(outputPath,'State distribution for frequency bands'),'-dpdf','-r0',f)
    
    close
    clear f
    
    % Update the check and save it
    check_point_info.final_freq = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'aux_GMM','check_point_info','-append')
    
end

%% Sorted Selected Frequency bands

% %Update status
% status_text = 'Sorted selected Frequency bands...';
% change_status_text(app.Recording_app,status_text);
% drawnow() % Update any changes
%
% freq_aux_t_d=zscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
% freq_aux_tplusg=zscore(LFP.Frequency_bands.Theta+LFP.Frequency_bands.High_Gamma);
% freq_aux_h_d=zscore(LFP.Frequency_bands.High_Gamma./LFP.Frequency_bands.Delta);
% freq_aux_high_gamma=zscore(LFP.Frequency_bands.High_Gamma);
% freq_aux_theta=zscore(LFP.Frequency_bands.Theta);
% freq_aux_delta=zscore(LFP.Frequency_bands.Delta);
%
% f=figure('PaperSize', [21 29.7],'visible','off');
% subplot(3,3,[1 2 4 5])
% gscatter(x,y,aux_GMM.All_Sort,...
%     [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
% ylabel(label_y);
% xlabel('zEMG');
% ylim(figure_parameters.limy)
% xlim(figure_parameters.limx)
% legend('AWAKE','NREM','REM','Location','best','FontSize',figure_parameters.fontsize*1.2)
% legend box off
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
% title('Final Distribution','FontSize',figure_parameters.fontsize*1.2)
%
% subplot(3,3,3)
% gscatter(denominator,numerator,aux_GMM.All_Sort,...
%     [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
% ylabel(numerator_label)
% xlabel(denominator_label)
% ylim(figure_parameters.limx)
% yticks(figure_parameters.ticks_aux)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% legend off
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,3,6)
% gscatter(denominator,rest_numerator,aux_GMM.All_Sort,...
%     [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem],'.');
% ylabel(rest_numerator_label)
% xlabel(denominator_label)
% ylim(figure_parameters.limx)
% yticks(figure_parameters.ticks_aux)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% legend off
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,9)
% histogram(denominator,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% ylabel('Prob.')
% xlabel('Z-scores')
% title('zDelta')
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,10)
% histogram(numerator,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% ylabel('Prob.')
% xlabel('Z-scores')
% title(numerator_label)
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,11)
% histogram(rest_numerator,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% ylabel('Prob.')
% xlabel('Z-scores')
% title('zHigh-Gamma')
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% subplot(3,4,12)
% histogram(x,figure_parameters.edges,'FaceColor',figure_parameters.color.bar_plot,...
%     'FaceAlpha',figure_parameters.transparecy_fa,'LineStyle','none','Normalization','Probability');
% ylabel('Prob.')
% xlabel('Z-scores')
% title('zEMG')
% ylim([0 .08])
% yticks(figure_parameters.GMM_Prob_axiss)
% xlim(figure_parameters.limx)
% xticks(figure_parameters.ticks_aux)
% box off
% set(gca,'fontsize',figure_parameters.fontsize)
% set(gca,'Linewidth',figure_parameters.lw)
% set(gca,'Tickdir','out')
%
% set(gcf,'color','white')
% sgtitle(['Sorted selected frequency bands - ' recording_params.recording_group ],'fontsize',figure_parameters.fontsize*2.2)
% print('-bestfit',fullfile(outputPath,'Sorted selected frequency bands'),'-dpdf','-r0',f)
%
% close
% clear f denominator* numerator* rest_numerator*

%% 6 to 90 Hz

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.freq_6_to_90) || ~check_point_info.status
    
    %Update status
    status_text = '6 to 90 Hz...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    freq_aux_t_d=zscore(LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplusb_delta=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tpluslg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplusbpluslg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplushg_d=zscore(LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tplusbplushg_d=zscore(LFP.Frequency_bands.Beta+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    freq_aux_tpluslgplushg_d=zscore(LFP.Frequency_bands.Low_Gamma+LFP.Frequency_bands.High_Gamma+LFP.Frequency_bands.Theta./LFP.Frequency_bands.Delta);
    
    f=figure('PaperSize', [21 29.7],'visible','off');
    subplot(3,5,1)
    gscatter(x,freq_aux_t_d,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(Theta/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Only z(Theta/Delta)')
    
    subplot(3,5,2)
    gscatter(x,freq_aux_tplusb_delta,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(Theta+Beta/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Adding Beta')
    
    subplot(3,5,3)
    gscatter(x,freq_aux_tpluslg_d,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(Theta+Low Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Adding Low Gamma')
    
    subplot(3,5,8)
    gscatter(x,freq_aux_tplusbpluslg_d,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(Theta+Beta+Low Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(3,5,4)
    gscatter(x,freq_aux_tplushg_d,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(Theta+High Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('Adding High Gamma')
    
    subplot(3,5,9)
    gscatter(x,freq_aux_tplusbplushg_d,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(Theta+Beta+High Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(3,5,14)
    gscatter(x,freq_aux_tpluslgplushg_d,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(Theta+Low Gamma+High Gamma/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    
    subplot(3,5,5)
    gscatter(x,y,aux_GMM.All_Sort,...
        [figure_parameters.color.awake;figure_parameters.color.nrem;figure_parameters.color.rem;figure_parameters.color.transition_nrem_rem],'.');
    box off
    legend off
    ylabel('z(6 to 90Hz/Delta)');
    xlabel([figure_parameters.emg_accel ' (z-score)']);
    ylim(figure_parameters.limy)
    xlim(figure_parameters.limx)
    set(gca,'fontsize',figure_parameters.fontsize)
    set(gca,'Linewidth',figure_parameters.lw)
    set(gca,'Tickdir','out')
    title('z(6 to 90Hz/Delta)')
    
    set(gcf,'color','white')
    sgtitle(['Sorted 6 to 90 Hz - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
    print('-fillpage',fullfile(outputPath,'Sorted 6 to 90 Hz'),'-dpdf','-r0',f)
    
    close
    clear f freq_aux* aux*
    
    % Update the check and save it
    check_point_info.freq_6_to_90 = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Plotting representative epochs

% Check if the check point option e enable and if this step has already
% been done
if (check_point_info.status && ~check_point_info.plot_representative) || ~check_point_info.status
    
    %Update status
    status_text = 'Plotting representative epochs...';
    change_status_text(app.Recording_app,status_text);
    drawnow() % Update any changes
    
    clc
    % If the user have checked the plot_representative_epochs
    if app.Algorithm_params.plot_representative_epochs
        clear prompt ip
        status_text = 'It might take a bit long because the epochs are being loaded';
        change_status_text(app.Recording_app,status_text);
        drawnow() % Update any changes
        
        % Get the complete pathway and then load the file inside it
        file_path = fullfile(app.Output_path,'ALL_DATA.mat');
        
        % Check if the data was saved using the struct mode
        listOfVariables = who('-file', file_path); % Get the list of variables inside it
        if ismember('LFP_epochs', listOfVariables) % Check if it has any of fields saved as variables
            DATA = load(file_path,'LFP_epochs','EMG_epochs','EMG_processed_sampling_frequency');   % Works only if the DATA was save using -struct option
        else
            load(file_path,'DATA') % Default load (Slower)
        end
        
        close all
        % Create a directory inside the output path
        mkdir(fullfile(app.Output_path,'representative_epochs'))
        % Change to the recently created directory
        cd(fullfile(app.Output_path,'representative_epochs'))
        
        numb_representative_plots.AWAKE=5; % number of random epochs for AWAKE
        numb_representative_plots.NREM=5; % number of random epochs for each NREM
        numb_representative_plots.REM=5; % number of random epochs for each REM
        numb_representative_plots.NREM_REM=5; % number of random epochs for the transition NREM_REM
        
        clc
        
        % Time vector for plot
        time_LFP = linspace(0,size(DATA.LFP_epochs,2)/LFP.FS,size(DATA.LFP_epochs,2));
        if isfield(DATA,'EMG_processed_sampling_frequency')  % Check if the field FS exists
            time_EMG = linspace(0,size(DATA.EMG_epochs,2)/DATA.EMG_processed_sampling_frequency,size(DATA.EMG_epochs,2));   % Uses the sampling frequency of the EMG
        else
            time_EMG = linspace(0,size(DATA.EMG_epochs,2)/LFP.FS,size(DATA.EMG_epochs,2));  % Uses the sampling frequency of the LFP
        end
        
        % Awake
        % Selecting which epochs to plot
        state=find(GMM.All_Sort==3);
        
        % Only plot if there is at least one epoch
        if length(state) < numb_representative_plots.AWAKE
            numb_representative_plots.AWAKE = length(state);    % The number of plotted epochs is equal to
        end
        
        % Get the epochs randomly
        if numb_representative_plots.AWAKE > 0  % Check if the number is higher than 0
            plot_epochs=state;
            plot_epochs=plot_epochs(randperm(size(plot_epochs,1),numb_representative_plots.AWAKE));
        end
        
        for jj=1:numb_representative_plots.AWAKE
            
            epoch_psd=LFP.Power_normalized(plot_epochs(jj),figure_parameters.Fidx);
            epoch_psd(exclude)=nan;
            
            aux_fig=figure('PaperSize', [21 29.7],'visible','off');
            
            subplot(5,2,[1 2])
            plot(time_LFP,DATA.LFP_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.LFP);
            ylim(figure_parameters.ylimits)
            ylabel({'Hippocampus','(Amplitude)'})
            title(sprintf('%d seconds epoch',app.EpochLengthValue))
            xticks([linspace(time_LFP(1),time_LFP(end),11)])
            xticklabels([linspace(time_LFP(1),time_LFP(end),11)])
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,[3 4])
            plot(time_EMG,DATA.EMG_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.EMG);
            if strcmp(figure_parameters.emg_accel,'Accel')
                ylim([0 1])
            else
                ylim(figure_parameters.ylimits)
            end
            ylabel({[figure_parameters.emg_accel ' filtered'],'(Amplitude)'})
            xticks([linspace(time_EMG(1),time_EMG(end),11)])
            xticklabels([linspace(time_EMG(1),time_EMG(end),11)])
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            %         subplot(5,2,[5 6])
            %         plot(time_EMG,DATA.EMG_raw_data(plot_epochs(jj),:),'Color',[0.6350 0.0780 0.1840]);
            %         ylim([-1 +1])
            %         ylabel({'Raw EMG','(Amplitude)'})
            %         xticks([0 1 2 3 4 5 6 7 8 9 10])
            %         xticklabels([0 1 2 3 4 5 6 7 8 9 10])
            %         box off
            %         set(gca,'fontsize',figure_parameters.fontsize)
            %         set(gca,'Linewidth',figure_parameters.lw)
            %         set(gca,'Tickdir','out')
            
            
            subplot(5,2,5)
            scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
                figure_parameters.color.awake,'.');
            hold on
            scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
                figure_parameters.color.nrem,'.');
            scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
                figure_parameters.color.rem,'.');
            scatter(x(GMM.All_Sort==5),y(GMM.All_Sort==5),figure_parameters.scatter_size,...
                figure_parameters.color.transition_nrem_rem,'.');
            scat=scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),figure_parameters.scatter_size*2,'r','o','filled');
            hold off
            xlim(figure_parameters.limx)
            ylim(figure_parameters.limy)
            if ~isempty(find(GMM.All_Sort==5, 1))
                legend('Awake','NREM','REM','NREM<->REM','Epoch selected','location','eastoutside')
            else
                legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
            end
            legend box off
            xlabel([figure_parameters.emg_accel ' (z-score)'])
            ylabel(label_y)
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,6)
            loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(epoch_psd,10),'Color',figure_parameters.color.awake,'linewidth',2);
            xlim([1 80])
            ylim([.0001 0.05])
            yticks([.0001 .001 .01])
            legend('Hippocampus','location','southwest')
            legend box off
            xlabel('Frequency (Hz)')
            ylabel({'   PSD'; '(Power Norm.)'})
            set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,[7 8])
            smo=15;
            plot(figure_parameters.axiss,smooth(x+2,smo),'Color',figure_parameters.color.EMG,'linewidth',.8)
            hold on
            plot(figure_parameters.axiss,smooth(y+6,smo),'Color',figure_parameters.color.LFP,'linewidth',.8)
            line_plot=xline(figure_parameters.axiss(plot_epochs(jj)),'k','linewidth',2);
            hold off
            box off
            ylim([-1 10])
            xlim([0 size(x,1)])
            yticks([mean(x+2) mean(y+6)])
            yticklabels({[figure_parameters.emg_accel, ' (z-score)'],label_y})
            xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
            xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            text(figure_parameters.axiss(plot_epochs(jj))+50,9.5,'-> Epoch selected','fontsize',20)
            
            orient(aux_fig,'portrait')
            set(gcf,'color','white')
            sgtitle(['AWAKE epoch ' num2str(jj) ' - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
            
            print('-bestfit',fullfile(outputPath,'representative_epochs',['AWAKE epoch ' num2str(jj)]),'-dpdf','-r0',aux_fig)
            close
        end
        clear state in xv yv plot_epochs jj
        close all
        
        % NREM
        % Selecting which epochs to plot
        state=find(GMM.All_Sort==2);
        
        % Only plot if there is at least one epoch
        if length(state) < numb_representative_plots.NREM
            numb_representative_plots.NREM = length(state);    % The number of plotted epochs is equal to
        end
        
        % Get the epochs randomly
        if numb_representative_plots.NREM > 0  % Check if the number is higher than 0
            plot_epochs=state;
            plot_epochs=plot_epochs(randperm(size(plot_epochs,1),numb_representative_plots.NREM));
        end
        
        for jj=1:numb_representative_plots.NREM
            
            epoch_psd=LFP.Power_normalized(plot_epochs(jj),figure_parameters.Fidx);
            epoch_psd(exclude)=nan;
            
            aux_fig=figure('PaperSize', [21 29.7],'visible','off');
            
            subplot(5,2,[1 2])
            plot(time_LFP,DATA.LFP_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.LFP);
            ylim(figure_parameters.ylimits)
            ylabel({'Hippocampus','(Amplitude)'})
            title(sprintf('%d seconds epoch',app.EpochLengthValue))
            xticks([linspace(time_LFP(1),time_LFP(end),11)])
            xticklabels([linspace(time_LFP(1),time_LFP(end),11)])
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,[3 4])
            plot(time_EMG,DATA.EMG_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.EMG);
            if strcmp(figure_parameters.emg_accel,'Accel')
                ylim([0 1])
            else
                ylim(figure_parameters.ylimits)
            end
            ylabel({[figure_parameters.emg_accel ' filtered'],'(Amplitude)'})
            xticks([linspace(time_EMG(1),time_EMG(end),11)])
            xticklabels([linspace(time_EMG(1),time_EMG(end),11)])
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            %         subplot(5,2,[5 6])
            %         plot(time_EMG,DATA.EMG_raw_data(plot_epochs(jj),:),'Color',[0.6350 0.0780 0.1840]);
            %         ylim([-1 +1])
            %         ylabel({'Raw EMG','(Amplitude)'})
            %         xticks([0 1 2 3 4 5 6 7 8 9 10])
            %         xticklabels([0 1 2 3 4 5 6 7 8 9 10])
            %         box off
            %         set(gca,'fontsize',figure_parameters.fontsize)
            %         set(gca,'Linewidth',figure_parameters.lw)
            %         set(gca,'Tickdir','out')
            
            subplot(5,2,5)
            scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
                figure_parameters.color.awake,'.');
            hold on
            scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
                figure_parameters.color.nrem,'.');
            scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
                figure_parameters.color.rem,'.');
            scatter(x(GMM.All_Sort==5),y(GMM.All_Sort==5),figure_parameters.scatter_size,...
                figure_parameters.color.transition_nrem_rem,'.');
            scat=scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),figure_parameters.scatter_size*2,'r','o','filled');
            hold off
            xlim(figure_parameters.limx)
            ylim(figure_parameters.limy)
            if ~isempty(find(GMM.All_Sort==5, 1))
                legend('Awake','NREM','REM','NREM<->REM','Epoch selected','location','eastoutside')
            else
                legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
            end
            legend box off
            xlabel([figure_parameters.emg_accel ' (z-score)'])
            ylabel(label_y)
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,6)
            loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(epoch_psd,10),'Color',figure_parameters.color.nrem,'linewidth',2);
            xlim([1 80])
            ylim([.0001 0.05])
            yticks([.0001 .001 .01])
            legend('Hippocampus','location','southwest')
            legend box off
            xlabel('Frequency (Hz)')
            ylabel({'   PSD'; '(Power Norm.)'})
            set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,[7 8])
            smo=15;
            plot(figure_parameters.axiss,smooth(x+2,smo),'Color',figure_parameters.color.EMG,'linewidth',.8)
            hold on
            plot(figure_parameters.axiss,smooth(y+6,smo),'Color',figure_parameters.color.LFP,'linewidth',.8)
            line_plot=xline(figure_parameters.axiss(plot_epochs(jj)),'k','linewidth',2);
            hold off
            box off
            ylim([-1 10])
            xlim([0 size(x,1)])
            yticks([mean(x+2) mean(y+6)])
            yticklabels({[figure_parameters.emg_accel, ' (z-score)'],label_y})
            xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
            xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            text(figure_parameters.axiss(plot_epochs(jj))+50,9.5,'-> Epoch selected','fontsize',20)
            
            orient(aux_fig,'portrait')
            set(gcf,'color','white')
            sgtitle(['NREM epoch ' num2str(jj) ' - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
            
            print('-bestfit',fullfile(outputPath,'representative_epochs',['NREM epoch ' num2str(jj)]),'-dpdf','-r0',aux_fig)
            close
        end
        clear state in xv yv plot_epochs jj
        close all
        
        % REM
        % Selecting which epochs to plot
        state=find(GMM.All_Sort==1);
        
        % Only plot if there is at least one epoch
        if length(state) < numb_representative_plots.REM
            numb_representative_plots.REM = length(state);    % The number of plotted epochs is equal to
        end
        
        % Get the epochs randomly
        if numb_representative_plots.REM > 0  % Check if the number is higher than 0
            plot_epochs=state;
            plot_epochs=plot_epochs(randperm(size(plot_epochs,1),numb_representative_plots.REM));
        end
        
        for jj=1:numb_representative_plots.REM
            
            epoch_psd=LFP.Power_normalized(plot_epochs(jj),figure_parameters.Fidx);
            epoch_psd(exclude)=nan;
            
            aux_fig=figure('PaperSize', [21 29.7],'visible','off');
            
            subplot(5,2,[1 2])
            plot(time_LFP,DATA.LFP_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.LFP);
            ylim(figure_parameters.ylimits)
            ylabel({'Hippocampus','(Amplitude)'})
            title(sprintf('%d seconds epoch',app.EpochLengthValue))
            xticks([linspace(time_LFP(1),time_LFP(end),11)])
            xticklabels([linspace(time_LFP(1),time_LFP(end),11)])
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,[3 4])
            plot(time_EMG,DATA.EMG_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.EMG);
            if strcmp(figure_parameters.emg_accel,'Accel')
                ylim([0 1])
            else
                ylim(figure_parameters.ylimits)
            end
            ylabel({[figure_parameters.emg_accel ' filtered'],'(Amplitude)'})
            xticks([linspace(time_EMG(1),time_EMG(end),11)])
            xticklabels([linspace(time_EMG(1),time_EMG(end),11)])
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            %         subplot(5,2,[5 6])
            %         plot(time_EMG,DATA.EMG_raw_data(plot_epochs(jj),:),'Color',[0.6350 0.0780 0.1840]);
            %         ylim([-1 +1])
            %         ylabel({'Raw EMG','(Amplitude)'})
            %         xticks([0 1 2 3 4 5 6 7 8 9 10])
            %         xticklabels([0 1 2 3 4 5 6 7 8 9 10])
            %         box off
            %         set(gca,'fontsize',figure_parameters.fontsize)
            %         set(gca,'Linewidth',figure_parameters.lw)
            %         set(gca,'Tickdir','out')
            
            subplot(5,2,5)
            scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
                figure_parameters.color.awake,'.');
            hold on
            scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
                figure_parameters.color.nrem,'.');
            scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
                figure_parameters.color.rem,'.');
            scatter(x(GMM.All_Sort==5),y(GMM.All_Sort==5),figure_parameters.scatter_size,...
                figure_parameters.color.transition_nrem_rem,'.');
            scat=scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),figure_parameters.scatter_size*2,'r','o','filled');
            hold off
            xlim(figure_parameters.limx)
            ylim(figure_parameters.limy)
            if ~isempty(find(GMM.All_Sort==5, 1))
                legend('Awake','NREM','REM','NREM<->REM','Epoch selected','location','eastoutside')
            else
                legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
            end
            legend box off
            xlabel([figure_parameters.emg_accel ' (z-score)'])
            ylabel(label_y)
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,6)
            loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(epoch_psd,10),'Color',figure_parameters.color.rem,'linewidth',2);
            xlim([1 80])
            ylim([.0001 0.05])
            yticks([.0001 .001 .01])
            legend('Hippocampus','location','southwest')
            legend box off
            xlabel('Frequency (Hz)')
            ylabel({'   PSD'; '(Power Norm.)'})
            set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
            box off
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            
            subplot(5,2,[7 8])
            smo=15;
            plot(figure_parameters.axiss,smooth(x+2,smo),'Color',figure_parameters.color.EMG,'linewidth',.8)
            hold on
            plot(figure_parameters.axiss,smooth(y+6,smo),'Color',figure_parameters.color.LFP,'linewidth',.8)
            line_plot=xline(figure_parameters.axiss(plot_epochs(jj)),'k','linewidth',2);
            hold off
            box off
            ylim([-1 10])
            xlim([0 size(x,1)])
            yticks([mean(x+2) mean(y+6)])
            yticklabels({[figure_parameters.emg_accel, ' (z-score)'],label_y})
            xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
            xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
            set(gca,'fontsize',figure_parameters.fontsize)
            set(gca,'Linewidth',figure_parameters.lw)
            set(gca,'Tickdir','out')
            text(figure_parameters.axiss(plot_epochs(jj))+50,9.5,'-> Epoch selected','fontsize',20)
            
            orient(aux_fig,'portrait')
            set(gcf,'color','white')
            sgtitle(['REM epoch ' num2str(jj) ' - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
            
            print('-bestfit',fullfile(outputPath,'representative_epochs',['REM epoch ' num2str(jj)]),'-dpdf','-r0',aux_fig)
            close
        end
        clear state in xv yv plot_epochs jj
        close all
        
        if ~isempty(find(GMM.All_Sort==5, 1))
            % Transition NREM - REM
            % Selecting which epochs to plot
            state=find(GMM.All_Sort==5);
            
            % Only plot if there is at least one epoch
            if length(state) < numb_representative_plots.NREM_REM
                numb_representative_plots.NREM_REM = length(state);    % The number of plotted epochs is equal to
            end
            
            % Get the epochs randomly
            if numb_representative_plots.NREM_REM > 0  % Check if the number is higher than 0
                plot_epochs=state;
                plot_epochs=plot_epochs(randperm(size(plot_epochs,1),numb_representative_plots.NREM_REM));
            end
            
            for jj=1:numb_representative_plots.NREM_REM
                
                epoch_psd=LFP.Power_normalized(plot_epochs(jj),figure_parameters.Fidx);
                epoch_psd(exclude)=nan;
                
                aux_fig=figure('PaperSize', [21 29.7],'visible','off');
                
                subplot(5,2,[1 2])
                plot(time_LFP,DATA.LFP_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.LFP);
                ylim(figure_parameters.ylimits)
                ylabel({'Hippocampus','(Amplitude)'})
                title(sprintf('%d seconds epoch',app.EpochLengthValue))
                xticks([linspace(time_LFP(1),time_LFP(end),11)])
                xticklabels([linspace(time_LFP(1),time_LFP(end),11)])
                box off
                set(gca,'fontsize',figure_parameters.fontsize)
                set(gca,'Linewidth',figure_parameters.lw)
                set(gca,'Tickdir','out')
                
                subplot(5,2,[3 4])
                plot(time_EMG,DATA.EMG_epochs(plot_epochs(jj),:),'Color',figure_parameters.color.EMG);
                if strcmp(figure_parameters.emg_accel,'Accel')
                    ylim([0 1])
                else
                    ylim(figure_parameters.ylimits)
                end
                ylabel({[figure_parameters.emg_accel ' filtered'],'(Amplitude)'})
                xticks([linspace(time_EMG(1),time_EMG(end),11)])
                xticklabels([linspace(time_EMG(1),time_EMG(end),11)])
                box off
                set(gca,'fontsize',figure_parameters.fontsize)
                set(gca,'Linewidth',figure_parameters.lw)
                set(gca,'Tickdir','out')
                
                %         subplot(5,2,[5 6])
                %         plot(time_EMG,DATA.EMG_raw_data(plot_epochs(jj),:),'Color',[0.6350 0.0780 0.1840]);
                %         ylim([-1 +1])
                %         ylabel({'Raw EMG','(Amplitude)'})
                %         xticks([0 1 2 3 4 5 6 7 8 9 10])
                %         xticklabels([0 1 2 3 4 5 6 7 8 9 10])
                %         box off
                %         set(gca,'fontsize',figure_parameters.fontsize)
                %         set(gca,'Linewidth',figure_parameters.lw)
                %         set(gca,'Tickdir','out')
                
                subplot(5,2,5)
                scatter(x(GMM.All_Sort==3),y(GMM.All_Sort==3),figure_parameters.scatter_size,...
                    figure_parameters.color.awake,'.');
                hold on
                scatter(x(GMM.All_Sort==2),y(GMM.All_Sort==2),figure_parameters.scatter_size,...
                    figure_parameters.color.nrem,'.');
                scatter(x(GMM.All_Sort==1),y(GMM.All_Sort==1),figure_parameters.scatter_size,...
                    figure_parameters.color.rem,'.');
                scatter(x(GMM.All_Sort==5),y(GMM.All_Sort==5),figure_parameters.scatter_size,...
                    figure_parameters.color.transition_nrem_rem,'.');
                scat=scatter(x(plot_epochs(jj)),y(plot_epochs(jj)),figure_parameters.scatter_size*2,'r','o','filled');
                hold off
                xlim(figure_parameters.limx)
                ylim(figure_parameters.limy)
                if ~isempty(find(GMM.All_Sort==5, 1))
                    legend('Awake','NREM','REM','NREM<->REM','Epoch selected','location','eastoutside')
                else
                    legend('Awake','NREM','REM','Epoch selected','location','eastoutside')
                end
                legend box off
                xlabel([figure_parameters.emg_accel ' (z-score)'])
                ylabel(label_y)
                set(gca,'fontsize',figure_parameters.fontsize)
                set(gca,'Linewidth',figure_parameters.lw)
                set(gca,'Tickdir','out')
                
                subplot(5,2,6)
                loglog(LFP.Frequency_distribution(figure_parameters.Fidx),smooth(epoch_psd,10),'Color',figure_parameters.color.transition_nrem_rem,'linewidth',2);
                xlim([1 80])
                ylim([.0001 0.05])
                yticks([.0001 .001 .01])
                legend('Hippocampus','location','southwest')
                legend box off
                xlabel('Frequency (Hz)')
                ylabel({'   PSD'; '(Power Norm.)'})
                set(gca, 'xtick', [0 2 4 6 8 10 20 40 60 80]);
                box off
                set(gca,'fontsize',figure_parameters.fontsize)
                set(gca,'Linewidth',figure_parameters.lw)
                set(gca,'Tickdir','out')
                
                subplot(5,2,[7 8])
                smo=15;
                plot(figure_parameters.axiss,smooth(x+2,smo),'Color',figure_parameters.color.EMG,'linewidth',.8)
                hold on
                plot(figure_parameters.axiss,smooth(y+6,smo),'Color',figure_parameters.color.LFP,'linewidth',.8)
                line_plot=xline(figure_parameters.axiss(plot_epochs(jj)),'k','linewidth',2);
                hold off
                box off
                ylim([-1 10])
                xlim([0 size(x,1)])
                yticks([mean(x+2) mean(y+6)])
                yticklabels({[figure_parameters.emg_accel, ' (z-score)'],label_y})
                xticks([0 size(x,1)/4 size(x,1)/2 3*size(x,1)/4 size(x,1)]);
                xticklabels({' |-','Dark Phase', '-|-','Light Phase','-| '});
                set(gca,'fontsize',figure_parameters.fontsize)
                set(gca,'Linewidth',figure_parameters.lw)
                set(gca,'Tickdir','out')
                
                text(figure_parameters.axiss(plot_epochs(jj))+50,9.5,'-> Epoch selected','fontsize',20)
                
                orient(aux_fig,'portrait')
                set(gcf,'color','white')
                sgtitle(['NREM<->REM epoch ' num2str(jj) ' - ' recording_params.recording_group],'fontsize',figure_parameters.fontsize*2.2)
                
                print('-bestfit',fullfile(outputPath,'representative_epochs',['Transition NREM_REM epoch ' num2str(jj)]),'-dpdf','-r0',aux_fig)
                close
            end
            clear state in xv yv plot_epochs jj
            close all
        end
        
        clear numb_random_plots DATA
        % Return to the ouput_path
        cd(app.Output_path)
    end
    clear prompt ip
    
    % Update the check and save it
    check_point_info.plot_representative = true;
    save(fullfile(outputPath,'GMM_Classification.mat'),'check_point_info','-append')
    
end

%% Clearing variables created during the classification

%Update status
status_text = 'Clearing variables created during the classification...';
change_status_text(app.Recording_app,status_text);
drawnow() % Update any changes

GMM.label_y=label_y;
GMM.Group=recording_params.recording_group;
GMM.LFP_used=y;
GMM.EMG_used=x;

clear label_y T exclude figure_parameters figure_over_time data_combined

%% Saving

%Update status
status_text = 'Saving...';
change_status_text(app.Recording_app,status_text);
drawnow() % Update any changes

% Save the GMM classification data inside the Output path
file_path = fullfile(app.Output_path,'GMM_Classification');
save (file_path,'GMM','-append')

%% END

%Update status
status_text = 'Done!';
change_status_text(app.Recording_app,status_text);
drawnow() % Update any changes

% Change status text
app.StatusTextArea.Value = 'The classication was finished';
drawnow % Refresh the interface

% Pause for a few seconds
pause(5)
% Close the GMM recording App
delete(app.Recording_app)

end
