function Visual_inspection= Visual_Inspection (recording_app_handle,LFP,EMG,x,y,label_y,output_path,continue_visual_inspection,epoch_length,pre_pro_params,figure_parameters)

% Loading epochs     ################################
% Get the full name of the output folder
data_full_path = fullfile(output_path,'ALL_DATA.mat');

% Variable with classification info
All_Sort = nan(1,size(LFP.Power_normalized,1));

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

%% Notch filter the LFP

% Get the notch frequency from the superior and inferior noise thresholds
notch_frequencies.base = mean([recording_app_handle.SuperiorEditField.Value recording_app_handle.InferiorEditField.Value]);
% Notch frenquency boundaries (Hz)
notch_frequencies.extension = 2;
% Include the harmonics
notch_frequencies.LFP = notch_frequencies.base:notch_frequencies.base:LFP.FS/2 - notch_frequencies.extension;
notch_frequencies.EMG = notch_frequencies.base:notch_frequencies.base:EMG.FS/2 - notch_frequencies.extension;


% EMG
% Loop for each of the harmonics
for harm = 1:length(notch_frequencies.EMG)

    % Create the filter (Butter 2nd order)
    fs = EMG.FS; % sampling_frequency
    n = 2; % filt order
    nyquist_rate = fs/2;
    Wn = [notch_frequencies.EMG(harm)-notch_frequencies.extension notch_frequencies.EMG(harm)+notch_frequencies.extension]/nyquist_rate;  % Lower and Upper frequency limits
    ftype = 'stop'; % filter type
    [b,a] = butter(n,Wn,ftype); % Create the butter filter
    
%   Filtering EMG data
    DATA.EMG_epochs = filter(b,a,DATA.EMG_epochs,[],2);
end
        
% LFP
% Loop for each of the harmonics
for harm = 1:length(notch_frequencies.LFP)

    % Create the filter (Butter 2nd order)
    fs = LFP.FS; % sampling_frequency
    n = 2; % filt order
    nyquist_rate = fs/2;
    Wn = [notch_frequencies.LFP(harm)-notch_frequencies.extension notch_frequencies.LFP(harm)+notch_frequencies.extension]/nyquist_rate;  % Lower and Upper frequency limits
    ftype = 'stop'; % filter type
    [b,a] = butter(n,Wn,ftype); % Create the butter filter
    
    % Filtering EMG data
    DATA.LFP_epochs = filter(b,a,DATA.LFP_epochs,[],2);
end

%%

%Defines if the visual inspection loop is going to be executed (TRUE) or
%not (FALSE)
visual_inspection_state = true;
% Defines if a complete new visual inspection is going to be created
create_new_inspection = true;
% Keeps the 'Finish re-inspection' button invisible (it can be changed
% later)
visible_finish_re_inspection = false;
% Informs the algorithm that the inspection will be finished (it can be
% changed later)
stop_and_save = false;   
% Define the epoch that the algorithm begins to check (jj + 1) --> plot_epochs(jj)
jj=0;

%% Number of epochs parameters
num_ep_vis = 40; % Number of epochs visualized for each state

% Get the main_app_pathway (important, since the trained data file is
% stored in this same folder)
[main_app_pathway,~,~] = fileparts(which('RMS_pwelch_integrate'));
trained_data_filepathway = fullfile(main_app_pathway,'Trained_data.mat');

% Load the Trained_data.m file
load(trained_data_filepathway,'Training_data')
proportion_factor = num_ep_vis/length(Training_data.All_sort);

clear Training_data
num_ep_vis = round(size(DATA.LFP_epochs,1) * proportion_factor);    % Change the number of epochs visualized for each state according to the dataset size
if num_ep_vis >= 40      % 60 is the maximum number (if the number is higher than that, make it 60)
    num_ep_vis = 40;
elseif num_ep_vis < 40  % 40 is the minimum number (if the number is lower than that, make it 40)
    num_ep_vis = 20;
end

clear proportion_factor

%% Check if the user selected to resume an unfinished visual inspection
if continue_visual_inspection
    % Automatically check for a file 'IDX_Visual_Inspection' inside the output_path
    if exist(fullfile(output_path,'IDX_Visual_Inspection'), 'file') == 2  % File exists.
        load(fullfile(output_path,'IDX_Visual_Inspection'),'Visual_inspection') % Loads it
    else % File does not exist
        title_text = sprintf('Select the IDX_Visual_Inspection file'); % Get a title string the the file selection dialog box
        [file,path] = uigetfile('*.mat',title_text,'MultiSelect','off');     % Opens the dialog box and enables the selection of a mat file
        drawnow;
        figure(recording_app_handle.UIFigure)  % Make sure that the app figure stay focused
        path_file_name = fullfile(path,file);  % Get the filepath by concatenating the path and file
        load(path_file_name,'Visual_inspection') % Load the 'IDX_Visual_Inspection' file
    end
    
    % Check if the visual inspection was finished or not
    if Visual_inspection.inspection_finished % If == true, the inspection has already been finished --> creates a dialog box to inform it
        
        confirmation_text = 'The inspection has already been finished. Do you want to abort, re-inspect or create a new inspection? If you choose to re-inspect, the final set of classified data probably will not be the same.'; % Create the text
        title_text = 'Visual inspection already finished';
        % Creates the alert and asks to abort a new visual inspection or to
        % re-inspect it (it has a CloseFcn callback to close the figure
        % and resume the function execution
        fig = uifigure; % Figue handle
        selection = uiconfirm(fig,confirmation_text,title_text,...
            'Options',{'Abort','Re-inspect','Create new inspection'},...
            'DefaultOption',1,'CloseFcn',@(h,e)close(fig));
        
        % Act in accordance with user input
        switch selection
            case 'Abort'    % 'Abort' button was selected
                visual_inspection_state = false;
                
            case 'Re-inspect'   % 'Re-inspect button was selected'
                create_new_inspection = false;
                Visual_inspection_bkp = Visual_inspection;  % Creates a backup for the original classification
                
                epochs_previously_inspected = [Visual_inspection.All_AWAKE, Visual_inspection.All_NREM, Visual_inspection.All_REM]; % Organize all the epochs previously classified by the user
                idx_perm = randsample(length(epochs_previously_inspected),length(epochs_previously_inspected));   % Created a random permuted index to the epochs
                
                % Insert the epochs already classified at the beginning and
                % excluded them from the orginal places
                exclude_in_epochs = ismember(Visual_inspection.plot_epochs, epochs_previously_inspected(idx_perm));
                Visual_inspection.plot_epochs(exclude_in_epochs) = [];
                Visual_inspection.plot_epochs = [epochs_previously_inspected(idx_perm) Visual_inspection.plot_epochs];
                
                % Clear the visual inspection (We already have a backup!)
                Visual_inspection.AWAKE_idx=[];
                Visual_inspection.NREM_idx=[];
                Visual_inspection.REM_idx=[];
                Visual_inspection.Transition.AWA_NREM=[];
                Visual_inspection.Transition.NREM_REM=[];
                Visual_inspection.Transition.REM_AWA=[];
                Visual_inspection.Transition.unknown=[];
                
                % Enables the 'Finish re-inspection' button to be visible
                visible_finish_re_inspection = true;
                
            case 'Create new inspection'    %  'Create new inspection' button was selected
                create_new_inspection = true;
                Visual_inspection.inspection_finished = false;  % Define a new unfinished visual inspection
        end
        
    else % If it has not finished yet 
        selection = 'Not finished';
        % Change jj to the value of the last checked epoch
        jj = Visual_inspection.last_checked_epoch;
        % Preserve the previous selected epochs
        create_new_inspection = false;
    end
else    % If it is not a continued visual inspection
    selection = 'Brand new inspection';   
end



%% Visual inspection loop

% Time vector for plot
time_vector_LFP=(1:1:size(DATA.LFP_epochs,2))./LFP.FS;
if isfield(DATA,'EMG_processed_sampling_frequency')  % Check if the field FS exists
    time_vector_EMG=(1:1:size(DATA.EMG_epochs,2))./DATA.EMG_processed_sampling_frequency;  % Uses the sampling frequency of the EMG
else
    time_vector_EMG=(1:1:size(DATA.EMG_epochs,2))./LFP.FS;  % Uses the sampling frequency of the LFP
end

% Only proceeds to visual inspection if the user have not selected 'Abort'
% (visual_inspection_state == false)
if visual_inspection_state
    
    % Only create a brand new inspection if the user is starting a new
    % inspection of if the button 'Create new inspection' have been
    % selected (create_new_inspection == true)
    if create_new_inspection
        
        % Generate random numbers to be used as time bins index, which will fulfill 40 time bins per state
        %         plot_epochs=randi([1 size(DATA.LFP_epochs,1)],1,4000);
        %         plot_epochs=unique(plot_epochs);
        %         plot_epochs = plot_epochs(randperm(length(plot_epochs)));
        
        Visual_inspection.AWAKE_idx=[];
        Visual_inspection.NREM_idx=[];
        Visual_inspection.REM_idx=[];
        Visual_inspection.Transition.AWA_NREM=[];
        Visual_inspection.Transition.NREM_REM=[];
        Visual_inspection.Transition.REM_AWA=[];
        Visual_inspection.Transition.unknown=[];
        
        
        % Generate random numbers to be used as time bins index, which will fulfill 40 time bins per state
        %         plot_epochs = randsample(size(DATA.LFP_epochs,1),4000);
        epochs_vector = 1:size(DATA.LFP_epochs,1);
        plot_epochs = epochs_vector(randperm(length(epochs_vector)));
        clear epochs_vector
        
        % Check if the data has the minimum number of epochs (twice
        % the number of visually inspected epochs) Ex: 40 epochs for each
        % state = 40 * 3 * 2;
        if size(DATA.LFP_epochs,1) < num_ep_vis * 3 * 2 
            % Presents a message in the Status box
            recording_app_handle.StatusTextArea.Value = sprintf('The dataset does not have the minimun amount of epochs (%d). The visual inspection has been finished',num_ep_vis * 3 * 2 );
            % Update the visual inspection status
            recording_app_handle.Visual_Inspection_Status = 'Break';
            % Stop the visual inspection
            return
        end
               
        
    else % If this is not a new inspection
        plot_epochs = Visual_inspection.plot_epochs;
    end
    
    % Open the app Plot_app which is going to present the plots and allow the
    % selection of the sleep state classification
    % epoch_length: is a scalar value in seconds which defines the length of the epochs; 
    % num_ep_vis is: scalar value --> minimum number of epochs that must be
    % classified for each one of the 3 states
    app_handle = Plot_app(epoch_length,num_ep_vis,pre_pro_params,figure_parameters.emg_accel);
    if visible_finish_re_inspection   % Check if the selected button was 'Re-inspect' and if the button was enabled
        % Enables the button 'Finish re-inspection' if the user selected the
        % button 'Re-inspect'
        app_handle.FinishreinspectionButton.Visible = true;
        app_handle.StopandsaveinspectionButton.Visible = false;
    else
        app_handle.FinishreinspectionButton.Visible = false;
        app_handle.StopandsaveinspectionButton.Visible = true;
    end
    
    condition=1;
    while condition==1
        
        jj=jj+1;
        % Get the number of NaN epochs
        nan_epochs = 0;
        while sum(isnan(DATA.LFP_epochs(plot_epochs(jj),:))) > 0 || sum(isnan(DATA.EMG_epochs(plot_epochs(jj),:))) > 0
            jj=jj+1;
            nan_epochs = nan_epochs + 1;
        end
        
        % Gather important information
        epoch_num = plot_epochs(jj);
        CA1_lfp = DATA.LFP_epochs(plot_epochs(jj),:);
        EMG_rec = DATA.EMG_epochs(plot_epochs(jj),:);
        Fidx = LFP.Frequency_distribution<=90;
        freq_vector=LFP.Frequency_distribution(Fidx);
        PSD_data = LFP.Power_normalized(plot_epochs(jj),Fidx);
        % Exclude the noise frequencies        
        PSD_data(LFP.Frequency_distribution(Fidx) >= notch_frequencies.base-notch_frequencies.extension & ...
            LFP.Frequency_distribution(Fidx) <= notch_frequencies.base+notch_frequencies.extension) = NaN;
        scatter_x = x;
        scatter_y = y;
        scatter_ylabel_text = label_y;
        
        
        % Sends necessary information to the app
        updatePlot(app_handle, time_vector_LFP, time_vector_EMG, epoch_num, CA1_lfp, EMG_rec, freq_vector, PSD_data, scatter_x, scatter_y, scatter_ylabel_text, Visual_inspection)
        % Make sure that the execution of this function will wait until the
        % user selects an option (app_handle.UIFigure is the figure associated
        % with the app
       
        uiwait(app_handle.UIFigure)

        
       tic
        % app_handle.Current_classification is a value representing the
        % classification for the current period (jj)
        % Check the Current_classification and accordingly
        switch app_handle.Current_classification            
            case 'previous' % Previous button or left array pressed
                if jj == 1  % If this is the first epoch, 'previous' button will not do anything
                    jj = 0;  % Reset the loop
                else
                    jj = jj - 2 - nan_epochs; % j - 2 will effectively go to the previous epoch ( - nan_epochs is considering any NaN epoch)
                end
                
            case 'next' % Next button or left array pressed
                % Changes to the next epoch (Basically, do nothing!)
            case 1  % AWAKE
                Visual_inspection.AWAKE_idx=cat(2,Visual_inspection.AWAKE_idx,plot_epochs(jj));
            case 2  % NREM
                Visual_inspection.NREM_idx=cat(2,Visual_inspection.NREM_idx,plot_epochs(jj));
            case 3  % REM
                Visual_inspection.REM_idx=cat(2,Visual_inspection.REM_idx,plot_epochs(jj));
            case 4 % AWAKE <--> NREM
                Visual_inspection.Transition.AWA_NREM=cat(2,Visual_inspection.Transition.AWA_NREM,plot_epochs(jj));
            case 5 % NREM <--> REM
                Visual_inspection.Transition.NREM_REM=cat(2,Visual_inspection.Transition.NREM_REM,plot_epochs(jj));
            case 6 % REM <--> AWAKE
                Visual_inspection.Transition.REM_AWA=cat(2,Visual_inspection.Transition.REM_AWA,plot_epochs(jj));
            case 0 % None of those
                Visual_inspection.Transition.unknown=cat(2,Visual_inspection.Transition.unknown,plot_epochs(jj));
            case 7 % Check how many epochs were visualized
                
                % Create a warning informing the number of epochs that were visulized
                fig_warning = uifigure; % Handle for the warning
                fig_warning.Position = [500 500 250 100];   % Position
                warning_text = sprintf('%d epochs were counted!',jj); % Create the text
                % Creates the alert
                uialert(fig_warning,warning_text, ...
                    'Epoch counter','Icon','info','CloseFcn','uiresume(fig_warning)')
                uiwait(fig_warning) % Waits until the alert is closed
                
                jj = jj - 1; % Keeps jj in the same epoch
                
            case 'scale_change'     % If the user has selected any scale changing option
                jj = jj - 1 - nan_epochs;   % Keep the same epoch (the -1 is necessary since the while loop will add 1 anyways
                
            case 'stop_and_save'    % The user pressed the button to 'stop' the inspection
                stop_and_save = true;   % Informs the algorithm that the inspection was not finished
                Visual_inspection.inspection_finished = false; % Informs the algorithm that the inspection has not been finished yet
                % Finishes inspection loop
                break
                
            case 'finish_re_inspection' % If the button 'Finish re-inspection' have been pressed (when enabled)
                % Combine the previous classification with the new one by
                % excluding different classified epochs
                               
                % AWAKE
                Visual_inspection_bkp.AWAKE_idx(ismember(Visual_inspection_bkp.AWAKE_idx,[Visual_inspection.NREM_idx Visual_inspection.REM_idx Visual_inspection.Transition.AWA_NREM Visual_inspection.Transition.NREM_REM ...
                    Visual_inspection.Transition.REM_AWA Visual_inspection.Transition.unknown])) = [];
                % NREM
                Visual_inspection_bkp.NREM_idx(ismember(Visual_inspection_bkp.NREM_idx,[Visual_inspection.AWAKE_idx Visual_inspection.REM_idx Visual_inspection.Transition.AWA_NREM Visual_inspection.Transition.NREM_REM ...
                    Visual_inspection.Transition.REM_AWA Visual_inspection.Transition.unknown])) = [];
                % NREM
                Visual_inspection_bkp.REM_idx(ismember(Visual_inspection_bkp.REM_idx,[Visual_inspection.AWAKE_idx Visual_inspection.NREM_idx Visual_inspection.Transition.AWA_NREM Visual_inspection.Transition.NREM_REM ...
                    Visual_inspection.Transition.REM_AWA Visual_inspection.Transition.unknown])) = [];
%                 % Transition AWA-NREM
%                 Visual_inspection_bkp.Transition.REM_AWA(ismember(Visual_inspection_bkp.Transition.REM_AWA,[Visual_inspection.AWAKE_idx Visual_inspection.NREM_idx Visual_inspection.REM_idx Visual_inspection.Transition.NREM_REM ...
%                     Visual_inspection.Transition.REM_AWA Visual_inspection.Transition.unknown])) = [];
%                 % Transition NREM-REM
%                 Visual_inspection_bkp.Transition.NREM_REM(ismember(Visual_inspection_bkp.Transition.NREM_REM,[Visual_inspection.AWAKE_idx Visual_inspection.NREM_idx Visual_inspection.REM_idx Visual_inspection.Transition.AWA_NREM ...
%                     Visual_inspection.Transition.REM_AWA Visual_inspection.Transition.unknown])) = [];
%                 % Transition REM-AWA
%                 Visual_inspection_bkp.Transition.REM_AWA(ismember(Visual_inspection_bkp.Transition.REM_AWA,[Visual_inspection.AWAKE_idx Visual_inspection.NREM_idx Visual_inspection.REM_idx Visual_inspection.Transition.AWA_NREM ...
%                     Visual_inspection.Transition.NREM_REM Visual_inspection.Transition.unknown])) = [];
%                 % Transition unknown
%                 Visual_inspection_bkp.Transition.unknown(ismember(Visual_inspection_bkp.Transition.unknown,[Visual_inspection.AWAKE_idx Visual_inspection.NREM_idx Visual_inspection.REM_idx Visual_inspection.Transition.AWA_NREM ...
%                     Visual_inspection.Transition.NREM_REM Visual_inspection.Transition.REM_AWA])) = [];
                
                % Concatenate the backup and new classification
                Visual_inspection.AWAKE_idx = unique([Visual_inspection.AWAKE_idx Visual_inspection_bkp.AWAKE_idx'],'stable');
                Visual_inspection.NREM_idx = unique([Visual_inspection.NREM_idx Visual_inspection_bkp.NREM_idx'],'stable');
                Visual_inspection.REM_idx = unique([Visual_inspection.REM_idx Visual_inspection_bkp.REM_idx'],'stable');
%                 Visual_inspection.Transition.AWA_NREM = unique([Visual_inspection.Transition.AWA_NREM Visual_inspection_bkp.Transition.AWA_NREM]);
%                 Visual_inspection.Transition.NREM_REM = unique([Visual_inspection.Transition.NREM_REM Visual_inspection_bkp.Transition.NREM_REM]);
%                 Visual_inspection.Transition.REM_AWA = unique([Visual_inspection.Transition.REM_AWA Visual_inspection_bkp.Transition.REM_AWA]);
%                 Visual_inspection.Transition.unknown = unique([Visual_inspection.Transition.unknown Visual_inspection_bkp.Transition.unknown]);
%                 
                break % Finishes the loop
        end
        toc
        
        %% Log evaluation (important to excluded a repeated classification)
        tic
        if isscalar(app_handle.Current_classification)   % Check if a specific state was attributed the epoch
            if ~(app_handle.Current_classification == All_Sort(plot_epochs(jj)))   % If the classified epoch wasn't the same
                switch All_Sort(plot_epochs(jj))    % Check which state has been attributed
                    case 1  % AWAKE
                        Visual_inspection.AWAKE_idx(Visual_inspection.AWAKE_idx == plot_epochs(jj)) = [];    % Exclude from AWAKE
                    case 2
                        Visual_inspection.NREM_idx(Visual_inspection.NREM_idx == plot_epochs(jj)) = [];      % Exclude from NREM
                    case 3
                        Visual_inspection.REM_idx(Visual_inspection.REM_idx == plot_epochs(jj)) = [];        % Exclude from REM
                end
            else % If it has already been classified as informed by the user (make sure only one of the same epoch is considered)
                Visual_inspection.AWAKE_idx = unique(Visual_inspection.AWAKE_idx,'stable'); % Awake
                Visual_inspection.NREM_idx = unique(Visual_inspection.NREM_idx,'stable');   % NREM
                Visual_inspection.REM_idx = unique(Visual_inspection.REM_idx,'stable');     % REM
            end
            All_Sort(plot_epochs(jj)) = app_handle.Current_classification;  % Attribute the new classification
        end
        
                
        %%
        
        if size(Visual_inspection.AWAKE_idx,2)~=1 || ...
                size(Visual_inspection.NREM_idx,2)~=1 || size(Visual_inspection.REM_idx,2)~=1
            Visual_inspection.AWAKE_idx = unique(nonzeros(Visual_inspection.AWAKE_idx),'stable')';
            Visual_inspection.NREM_idx = unique(nonzeros(Visual_inspection.NREM_idx),'stable')';
            Visual_inspection.REM_idx = unique(nonzeros(Visual_inspection.REM_idx),'stable')';
        end
        
        % Final condition to the inspection loop to be finished
        if size(Visual_inspection.AWAKE_idx,2)>=num_ep_vis && ...
                size(Visual_inspection.NREM_idx,2)>=num_ep_vis && ...
                size(Visual_inspection.REM_idx,2)>=num_ep_vis && ~app_handle.FinishreinspectionButton.Visible
            condition=0;
            % Very important! Defines that the algorithm can finish and
            % make the final changes in the visual inspection data
            Visual_inspection.inspection_finished = true;
        end
        
        if jj == length(plot_epochs)
            % If the Visual Inspection has reached the final epoch, start again
            % from the first one
            jj = 0;
        end
        toc
    end % End of while
    
    
    %Save the selected epochs
    Visual_inspection.plot_epochs = plot_epochs;
    
    % Closes the app
    app_handle.delete
    
    close all
    
    Visual_inspection.All_AWAKE = Visual_inspection.AWAKE_idx(randsample(length(Visual_inspection.AWAKE_idx),length(Visual_inspection.AWAKE_idx)));
    Visual_inspection.All_NREM = Visual_inspection.NREM_idx(randsample(length(Visual_inspection.NREM_idx),length(Visual_inspection.NREM_idx)));
    Visual_inspection.All_REM = Visual_inspection.REM_idx(randsample(length(Visual_inspection.REM_idx),length(Visual_inspection.REM_idx)));
    
    
%     Visual_inspection.All_AWAKE=Visual_inspection.AWAKE_idx(randperm(length(Visual_inspection.AWAKE_idx)));
%     Visual_inspection.All_NREM=Visual_inspection.NREM_idx(randperm(length(Visual_inspection.NREM_idx)));
%     Visual_inspection.All_REM=Visual_inspection.REM_idx(randperm(length(Visual_inspection.REM_idx)));
    
    % Final modifications in the visual inspection data (only done when the
    % inspection has been finished)
    if Visual_inspection.inspection_finished % 
        Visual_inspection.AWAKE_idx=Visual_inspection.AWAKE_idx(1:num_ep_vis);
        Visual_inspection.NREM_idx=Visual_inspection.NREM_idx(1:num_ep_vis);
        Visual_inspection.REM_idx=Visual_inspection.REM_idx(1:num_ep_vis);
        
        % Calculate the transition number
        % If it is a re-inspection
        if strcmp(selection,'Re-inspection')
            Visual_inspection.Transition.AWA_NREM = length(Visual_inspection.Transition.AWA_NREM) + Visual_inspection_bkp.Transition.AWA_NREM;
            Visual_inspection.Transition.NREM_REM = length(Visual_inspection.Transition.NREM_REM)+ Visual_inspection_bkp.Transition.NREM_REM;
            Visual_inspection.Transition.REM_AWA = length(Visual_inspection.Transition.REM_AWA)+ Visual_inspection_bkp.Transition.REM_AWA;
            Visual_inspection.Transition.unknown = length(Visual_inspection.Transition.unknown)+ Visual_inspection_bkp.Transition.unknown;
        else
            Visual_inspection.Transition.AWA_NREM = length(Visual_inspection.Transition.AWA_NREM); 
            Visual_inspection.Transition.NREM_REM = length(Visual_inspection.Transition.NREM_REM);
            Visual_inspection.Transition.REM_AWA = length(Visual_inspection.Transition.REM_AWA);
            Visual_inspection.Transition.unknown = length(Visual_inspection.Transition.unknown);
        end
        
        % Change the dimensions
        Visual_inspection.AWAKE_idx=Visual_inspection.AWAKE_idx';
        Visual_inspection.NREM_idx=Visual_inspection.NREM_idx';
        Visual_inspection.REM_idx=Visual_inspection.REM_idx';
    end
    
    Visual_inspection.All_sort=nan(size(DATA.LFP_epochs,1),1);
    Visual_inspection.All_sort(Visual_inspection.AWAKE_idx)=3;
    Visual_inspection.All_sort(Visual_inspection.NREM_idx)=2;
    Visual_inspection.All_sort(Visual_inspection.REM_idx)=1;
    
   
    
    if stop_and_save % The user pressed the button to stop and save the inspection
        % Change the visual inspection state to unfinished
        Visual_inspection.inspection_finished = false;
        % Define the last checked epoch (must include any possible NaN
        % epochs
        Visual_inspection.last_checked_epoch = jj-1-nan_epochs;
    else
        % Change the visual inspection state to finished
        Visual_inspection.inspection_finished = true;
        % Define the last checked epoch
        Visual_inspection.last_checked_epoch = jj;
    end
    
    clearvars -except Visual_inspection output_path
    folder_file = fullfile(output_path,'IDX_Visual_Inspection');
    save (folder_file, 'Visual_inspection')
    
end
end