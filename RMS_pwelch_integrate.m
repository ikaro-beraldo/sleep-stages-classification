classdef RMS_pwelch_integrate < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        SleepwakecycleclassificationsoftwareUIFigure  matlab.ui.Figure
        GridLayout                      matlab.ui.container.GridLayout
        LeftPanel                       matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        DatamanipulationPanel           matlab.ui.container.Panel
        LoadvariablesLabel              matlab.ui.control.Label
        LoadButton                      matlab.ui.control.Button
        SaveselectedvariablesLabel      matlab.ui.control.Label
        ExcludeselectedvariablesLabel   matlab.ui.control.Label
        SaveButton                      matlab.ui.control.Button
        ExcludeButton                   matlab.ui.control.Button
        WorkspaceTable                  matlab.ui.control.Table
        Panel                           matlab.ui.container.Panel
        StatusTextAreaLabel             matlab.ui.control.Label
        StatusTextArea                  matlab.ui.control.TextArea
        RightPanel                      matlab.ui.container.Panel
        GridLayout3                     matlab.ui.container.GridLayout
        PreprocessingstepPanel          matlab.ui.container.Panel
        TabGroup                        matlab.ui.container.TabGroup
        DetailsTab                      matlab.ui.container.Tab
        TextArea                        matlab.ui.control.TextArea
        DonotsegmentthedataCheckBox     matlab.ui.control.CheckBox
        SegmentsdurationhEditFieldLabel  matlab.ui.control.Label
        SegmentsdurationhEditField      matlab.ui.control.NumericEditField
        SegmentsdurationsamplesEditFieldLabel  matlab.ui.control.Label
        SegmentsdurationsamplesEditField  matlab.ui.control.NumericEditField
        DetrendTab                      matlab.ui.container.Tab
        ONCheckBox_detrend              matlab.ui.control.CheckBox
        PolynomialdegreeButtonGroup     matlab.ui.container.ButtonGroup
        ConstantdefaultButton           matlab.ui.control.RadioButton
        LinearButton                    matlab.ui.control.RadioButton
        QuadraticButton                 matlab.ui.control.RadioButton
        OtherButton                     matlab.ui.control.RadioButton
        PolynomialDegreeEditField       matlab.ui.control.NumericEditField
        ResamplingTab                   matlab.ui.container.Tab
        OutputsamplingfrequencyHzEditFieldLabel  matlab.ui.control.Label
        OutputsamplingfrequencyHzEditField  matlab.ui.control.NumericEditField
        ChangeinputsamplingfrequencyHzEditFieldLabel  matlab.ui.control.Label
        ChangeinputsamplingfrequencyHzEditField  matlab.ui.control.NumericEditField
        CheckBox_input_sampling_freq_resampling  matlab.ui.control.CheckBox
        ONCheckBox_resampling           matlab.ui.control.CheckBox
        InputOutputfrequencyratioEditFieldLabel  matlab.ui.control.Label
        InputOutputfrequencyratioEditField  matlab.ui.control.NumericEditField
        FilteringTab                    matlab.ui.container.Tab
        FiltertypeButtonGroup           matlab.ui.container.ButtonGroup
        BandpassButton                  matlab.ui.control.RadioButton
        NotchHzButton                   matlab.ui.control.RadioButton
        LowpassEditField                matlab.ui.control.NumericEditField
        HighpassEditField               matlab.ui.control.NumericEditField
        NotchEditField                  matlab.ui.control.NumericEditField
        HighpassHzButton                matlab.ui.control.RadioButton
        LowpassHzButton                 matlab.ui.control.RadioButton
        ONCheckBox_filtering            matlab.ui.control.CheckBox
        SamplingfrequencyEditFieldLabel  matlab.ui.control.Label
        SamplingfrequencyEditField_filtering  matlab.ui.control.EditField
        CheckBox_filtering_sampling_frequency  matlab.ui.control.CheckBox
        PeriodseparationTab             matlab.ui.container.Tab
        PeriodLengthsecEditFieldLabel   matlab.ui.control.Label
        PeriodLengthsecEditField        matlab.ui.control.NumericEditField
        PeriodLengthsamplesEditFieldLabel  matlab.ui.control.Label
        PeriodLengthsamplesEditField    matlab.ui.control.NumericEditField
        NumberofPeriodsEditFieldLabel   matlab.ui.control.Label
        NumberofPeriodsEditField        matlab.ui.control.NumericEditField
        ONCheckBox_period_separation    matlab.ui.control.CheckBox
        SamplingfrequencyEditField_2Label  matlab.ui.control.Label
        SamplingfrequencyEditField_period_separation  matlab.ui.control.NumericEditField
        sampling_frequency_checkbox_period_separation  matlab.ui.control.CheckBox
        NumberofdiscardedsamplesEditFieldLabel  matlab.ui.control.Label
        NumberofdiscardedsamplesEditField  matlab.ui.control.NumericEditField
        Run_preprocessing_Button        matlab.ui.control.Button
        RuntheselectedstepsusingtheselectedvariablesLabel  matlab.ui.control.Label
        SleepwakecyclesortingPanel      matlab.ui.container.Panel
        SleepWakeAlgorithmButtonGroup   matlab.ui.container.ButtonGroup
        LoadpreprocessedvariablesButton_2  matlab.ui.control.RadioButton
        RunButton_classification_algorithm  matlab.ui.control.Button
        PowerLineNoiseHzLabel           matlab.ui.control.Label
        PowerLineNoiseHzEditField       matlab.ui.control.NumericEditField
        OutputSamplingFrequencyLabel    matlab.ui.control.Label
        OutputSamplingFrequencyDropDown  matlab.ui.control.DropDown
        Selectthedata_variablematfileLabel  matlab.ui.control.Label
        ststepSelectiononeoftheoptionsbellow1or2Label  matlab.ui.control.Label
        ndstepChangetheparametersbellowandpressRunLabel  matlab.ui.control.Label
        EpochLengthsecLabel             matlab.ui.control.Label
        EpochLengthEditField            matlab.ui.control.NumericEditField
        UseworkpacedataButton           matlab.ui.control.RadioButton
        CA1ChannelDropDownLabel         matlab.ui.control.Label
        CA1ChannelDropDown              matlab.ui.control.DropDown
        EMGAccelChannelDropDown         matlab.ui.control.DropDown
        EMG_Accel_ButtonGroup           matlab.ui.container.ButtonGroup
        EMGChannelButton                matlab.ui.control.RadioButton
        Accel1ChButton                  matlab.ui.control.RadioButton
        Accel3ChButton                  matlab.ui.control.RadioButton
        AccelXDropDown                  matlab.ui.control.DropDown
        AccelYDropDown                  matlab.ui.control.DropDown
        AccelZDropDown                  matlab.ui.control.DropDown
        IncludethealgorithmpreprocessingstepCheckBox  matlab.ui.control.CheckBox
        XLabel                          matlab.ui.control.Label
        YLabel                          matlab.ui.control.Label
        ZLabel                          matlab.ui.control.Label
        PostClassificationAnalysisMenu  matlab.ui.container.Menu
        SleepwakecyclearchitectureMenu  matlab.ui.container.Menu
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = private)
        FilenameLoad % Path to the file that is being loaded
        
        %LoadedFilesFromDialogApp % Output from load_variables app (struct with the variables data and info)
    end
    
    properties (Access = public)
        Workspace % Variable which keeps all the data from the workflow
        Polynomial_degree % Variable containing the polynomial degree for detrend function
        Active_pre_processing_functions % Logical vector indicating the pre-processing functions that are active (true) or not (false)
        Selected_radio_button_tag % String containing the selected filter type ('band-pass','notch','high-pass','low-pass')
        Algorithm_preprocessing_step % Logical defining if the classification algorith is going to use the preprocessing step or not
        Recording_params % Parameters used on recordings that are going to be transfered between apps
        Added_frequency_bands % Tag containing the frequency band added in the algorithm
        Algorithm_params % Struct containing logical values to be used by the sorting algorithm
        Output_path % String containing the output folder for the sorting algorithm
        Recording_app % Reference to the recording app
        Algorithm_selected_radio_button_tag % Radio button define workspace or load
        Add_frequency_bands_app  % Reference to the Add_frequency_bands_app
        Temp_files_path % Creates a cell that will store the paths to the temporary files (important, since they will be deleted if the software is closed)
        CheckBox_previous_states % Struct with the original states from the pre-processing input sampling frequency check boxes
        Algorithm_preprocessing_step_final_sampling_frequency % Scalar value informing the final sampling frequency if the user has selected the algorithm pre-processing step
        EpochLengthValue % Get the value from the edit field and insert it in a property (where the user cannot change while the algorithm is running and will be used as a reference)
        EMG_Accel_selected_radio_button_tag % Get the tag associated to the user selection (1 - EMG; 2 - Accel 1 channel; 3 - Accel 3 channels)
    end
    
    methods (Access = private)
        
        % Update the workspace as soon as an action needs it to happen
        function UpdateWorkspace(app)
                       
            % Organize the workspace information in a cell (cell with the
            % number of rows = number of vars from the struct 'vars_info'
            % number of collumns = number of rows from WorkspaceTable
            struct_workspace = struct('name',[],'class',[],'size',[],'sampling_frequency',[],'current_state',[]);
            % Fill the cell with the variables important info
            for l_count = 1:size(app.Workspace,2)   % Loops throughout the elements (2, here columns) of the struct
                struct_workspace(l_count).name = app.Workspace(l_count).name;  %Get the name
                struct_workspace(l_count).class = app.Workspace(l_count).class;  %Get the type
                %Show the dimensions of the variable if it is a double type var with more than 10 values
                if isa(app.Workspace(l_count).data,'double') && length(app.Workspace(l_count).data)>10
                    %Get the dimensions as a string ('n x n')
                    struct_workspace(l_count).size = app.Workspace(l_count).size;
                    % Else if it is a scalar or a string, insert the value itself
                else
                    struct_workspace(l_count).size = app.Workspace(l_count).data; %Get the values
                end
                struct_workspace(l_count).sampling_frequency = app.Workspace(l_count).sampling_frequency;
                
                % Define the current state for each variable
                struct_workspace(l_count).current_state = app.Workspace(l_count).current_state;
                
            end
            % Fill the Workspace table with the cell info
            % If the table is going to have only 1 row (only 1 variable),
            % it is necessary the add the parameter 'AsArray'
            if size(app.Workspace,1) <= 1
                app.WorkspaceTable.Data = struct2table(struct_workspace,'AsArray',true);
            else
                app.WorkspaceTable.Data = struct2table(struct_workspace);
            end
            
            % Update the sleep-wake cycle sorting algorithm drop down lists
            variableNames = {app.Workspace.name}; % Converts the the struct to a cell in order to extract only the name of the vars
            app.CA1ChannelDropDown.Items = variableNames; % CA1 drop down list
            app.EMGAccelChannelDropDown.Items = variableNames; % EMG drop down list
            
            % Update any graphical changes
            drawnow;
        end
        
        % Calculate the parameters to be shown on the edit field boxes of
        % period separation preprocessing step
        function period_separation_params = calc_period_separation_params(app,reference_index,epoch_length,sampling_frequency)
            period_separation_params = struct;
            % Get the sampling frequency from the reference variable from
            % workspace
            period_separation_params.sampling_frequency = sampling_frequency;
            % Get the epoch length in samples
            period_separation_params.epoch_length_samples = epoch_length * sampling_frequency;
            % Get the total number of epochs;
            period_separation_params.number_of_epochs = floor(length(app.Workspace(reference_index).data) / period_separation_params.epoch_length_samples);
            % Get the number of discarded epochs
            period_separation_params.discarded_epochs = length(app.Workspace(reference_index).data)...
                - (period_separation_params.epoch_length_samples * period_separation_params.number_of_epochs);
            
            % Automatically changes the values inside the edit boxes
            app.PeriodLengthsamplesEditField.Value = period_separation_params.epoch_length_samples;
            app.NumberofPeriodsEditField.Value = period_separation_params.number_of_epochs;
            app.NumberofdiscardedsamplesEditField.Value = period_separation_params.discarded_epochs;
            
        end
        
        function prevent_edition(app)
            % Prevents any edition from happening
            app.PolynomialdegreeButtonGroup.Enable = 'off';
            app.OutputsamplingfrequencyHzEditField.Enable = false;
            app.InputOutputfrequencyratioEditField.Enable = false;
            app.FiltertypeButtonGroup.Enable = 'off';
            app.PeriodLengthsecEditField.Enable = false;            

            % Get the previous states of the pre-processing input sampling
            % frequency check boxes
            app.CheckBox_previous_states.resampling = app.CheckBox_input_sampling_freq_resampling.Value;
            app.CheckBox_previous_states.filtering = app.CheckBox_filtering_sampling_frequency.Value;
            app.CheckBox_previous_states.period_separation = app.sampling_frequency_checkbox_period_separation.Value;
            % Resampling
            app.CheckBox_input_sampling_freq_resampling.Enable = false; % Checkbox
            app.ChangeinputsamplingfrequencyHzEditField.Enable = false; % Edit field
            % Filtering
            app.CheckBox_filtering_sampling_frequency.Enable = false;   % Checkbox
            app.SamplingfrequencyEditField_filtering.Enable = false;    % Edit field
            % Period separation
            app.sampling_frequency_checkbox_period_separation.Enable = false;   % Checkbox
            app.SamplingfrequencyEditField_period_separation.Enable = false;    % Edit field
            
            % Run button
            app.Run_preprocessing_Button.Enable = false;
            
            % Update the interface
            drawnow
        end
        
        function enable_edition(app)
            % Enables pre-processing check boxes e and edit fields edition
            app.PolynomialdegreeButtonGroup.Enable = 'on';
            app.OutputsamplingfrequencyHzEditField.Enable = true;
            app.InputOutputfrequencyratioEditField.Enable = true;
            app.FiltertypeButtonGroup.Enable = 'on';
            app.PeriodLengthsecEditField.Enable = true;
            
            % Input sampling frequecy check boxes
            app.CheckBox_input_sampling_freq_resampling.Enable = true;
            app.CheckBox_filtering_sampling_frequency.Enable = true;
            app.sampling_frequency_checkbox_period_separation.Enable = true;
            
            % Change the sampling frequency ENABLE parameter edit fields accordingly to the
            % previous states
            % Resampling
            app.ChangeinputsamplingfrequencyHzEditField.Enable = app.CheckBox_previous_states.resampling; % Edit field
            % Filtering
            app.SamplingfrequencyEditField_filtering.Enable = app.CheckBox_previous_states.filtering;    % Edit field
            % Period separation
            app.SamplingfrequencyEditField_period_separation.Enable = app.CheckBox_previous_states.period_separation;    % Edit field
        
            % Run button
            app.Run_preprocessing_Button.Enable = true;
            
            % Update the interface
            drawnow
        end
        
        % Used when the 'Run' button is pushed starting the pre-processing
        % step and the check box 'Do not segment the data' is checked(important to have the reference_variable = variables
        % selected in the Workspace)
        function pre_processing_non_segmented(app,reference_variable)
            
            % Creates a temporary .mat file and saves the data that is
            % going to be processed
            temp_file_name = sprintf('%s_preprocessing',strrep(char(datetime('now')),':','_'));
            
            preprocessing_temporary = struct;   % Creates a struct to store the temporary files as a backup
            % Loop to save the original variables inside the temporary
            % file
            for original_loop = reference_variable
                % Gets the original data
                preprocessing_temporary.(app.Workspace(original_loop).name).data = app.Workspace(original_loop).data;
                % Gets the original sampling frequency
                preprocessing_temporary.(app.Workspace(original_loop).name).sampling_frequency = app.Workspace(original_loop).sampling_frequency;
            end
            % Saves the temporary file inside the default temporary folder
            % of the system (the append option is false, so to create a new
            % file
            savetmp(temp_file_name,false,'preprocessing_temporary');
            % Exclude the temporary file from workspace after it is saved
            clear preprocessing_temporary
            
            % First pre-processing stept: DETREND (check if it active)
            if app.ONCheckBox_detrend.Value
                % Change status text
                app.StatusTextArea.Value = 'Detrend...';
                drawnow % Refresh the interface
                
                preprocessing_temporary_detrend = struct;   % Creates a struct to store the temporary detrended files as a backup
                % Loop to detrend and save the detrended variables inside the temporary
                % file
                for detrend_loop = reference_variable
                    % Call the detrend function and gets the polynomial
                    % degree from the either the radio buttons or edit
                    % field
                    app.Workspace(detrend_loop).data = app_detrend(app.Workspace(detrend_loop).data,app.Polynomial_degree);
                    % Gets the original data
                    preprocessing_temporary_detrend.(app.Workspace(detrend_loop).name).data = app.Workspace(detrend_loop).data;
                    % Gets the original sampling frequency
                    preprocessing_temporary_detrend.(app.Workspace(detrend_loop).name).sampling_frequency = app.Workspace(detrend_loop).sampling_frequency;
                end
                % Saves the temporary file inside the default temporary folder
                % of the system (the append option is true, to save inside
                % an existing file
                savetmp(temp_file_name,true,'preprocessing_temporary_detrend');
                % Exclude the temporary file from workspace after it is saved
                clear preprocessing_temporary_detrend
                
                % Update Workspace after this pre-processing step
                UpdateWorkspace(app)
            end
            
            % Second pre-processing stept: RESAMPLING (check if it active)
            if app.ONCheckBox_resampling.Value
                % Change status text
                app.StatusTextArea.Value = 'Resampling...';
                drawnow % Refresh the interface
                
                preprocessing_temporary_resampling = struct;   % Creates a struct to store the temporary detrended files as a backup
                % Loop to detrend and save the detrended variables inside the temporary
                % file
                for resampling_loop = reference_variable
                    % Call the resampling function and gets the output
                    % (mandatory) and input (optional) sampling frequencies
                    if logical(app.ChangeinputsamplingfrequencyHzEditField.Enable)  % If the input sampling frequency have been inserted by the user (optional)
                        app.Workspace(resampling_loop).data = app_decimate(app.Workspace(resampling_loop).data,app.Workspace(resampling_loop).sampling_frequency,app.OutputsamplingfrequencyHzEditField.Value,app.ChangeinputsamplingfrequencyHzEditField);
                    else % If the input sampling frequency have not been inserted by the user (default - the parameter is empty)
                        app.Workspace(resampling_loop).data = app_decimate(app.Workspace(resampling_loop).data,app.Workspace(resampling_loop).sampling_frequency,app.OutputsamplingfrequencyHzEditField.Value,[]);
                    end
                    % Changes the sampling frequency
                    app.Workspace(resampling_loop).sampling_frequency = app.OutputsamplingfrequencyHzEditField.Value;
                    
                    % Gets the original data
                    preprocessing_temporary_resampling.(app.Workspace(resampling_loop).name).data = app.Workspace(resampling_loop).data;
                    % Gets the original sampling frequency
                    preprocessing_temporary_resampling.(app.Workspace(resampling_loop).name).sampling_frequency = app.Workspace(resampling_loop).sampling_frequency;
                end
                % Saves the temporary file inside the default temporary folder
                % of the system (the append option is true, to save inside
                % an existing file
                savetmp(temp_file_name,true,'preprocessing_temporary_resampling');
                % Exclude the temporary file from workspace after it is saved
                clear preprocessing_temporary_resampling
                
                % Update Workspace after this pre-processing step
                UpdateWorkspace(app)
            end
            
            % Second pre-processing stept: FILTERING (check if it active)
            if app.ONCheckBox_filtering.Value
                % Change status text
                app.StatusTextArea.Value = 'Filtering...';
                drawnow % Refresh the interface
                
                preprocessing_temporary_filtering = struct;   % Creates a struct to store the temporary detrended files as a backup
                % Loop to detrend and save the detrended variables inside the temporary
                % file
                for filtering_loop = reference_variable
                    % Call the resampling function and gets the output
                    % (mandatory) and input (optional) sampling frequencies
                    if logical(app.SamplingfrequencyEditField_filtering.Enable) && ... % If the input sampling frequency have been inserted by the user (optional)
                            isnan(str2double(app.SamplingfrequencyEditField_filtering)) == false
                        % Filtering function using the sampling frequency
                        % inserted by the user
                        [app.Workspace(filtering_loop).data,filter_params] = app_filter(app.Workspace(filtering_loop).data,app.Workspace(filtering_loop).sampling_frequency,app.Selected_radio_button_tag,...
                            app.HighpassEditField.Value,app.LowpassEditField.Value,app.NotchEditField.Value,...
                            str2double(app.SamplingfrequencyEditField_filtering));
                    else % If the input sampling frequency have not been inserted by the user (default - the parameter is empty)
                        % The sampling frequency input = false (so the
                        % function uses the variable associated sampling frequency
                        [app.Workspace(filtering_loop).data,filter_params] = app_filter(app.Workspace(filtering_loop).data,app.Workspace(filtering_loop).sampling_frequency,app.Selected_radio_button_tag,...
                            app.HighpassEditField.Value,app.LowpassEditField.Value,app.NotchEditField.Value,...
                            false);
                    end
                    % Insert the filter params into the workspace variable
                    app.Workspace(filtering_loop).filter_params = filter_params;
                    preprocessing_temporary_filtering.(app.Workspace(filtering_loop).name).filter_params = app.Workspace(filtering_loop).filter_params;
                    % Gets the original data
                    preprocessing_temporary_filtering.(app.Workspace(filtering_loop).name).data = app.Workspace(filtering_loop).data;
                    % Gets the original sampling frequency
                    preprocessing_temporary_filtering.(app.Workspace(filtering_loop).name).sampling_frequency = app.Workspace(filtering_loop).sampling_frequency;
                end
                % Saves the temporary file inside the default temporary folder
                % of the system (the append option is true, to save inside
                % an existing file
                savetmp(temp_file_name,true,'preprocessing_temporary_filtering');
                % Exclude the temporary file from workspace after it is saved
                clear preprocessing_temporary_filtering
                
                % Update Workspace after this pre-processing step
                UpdateWorkspace(app)
            end
            
            % First pre-processing stept: PERIOD SEPARATION (check if it active)
            if app.ONCheckBox_period_separation.Value
                % Change status text
                app.StatusTextArea.Value = 'Period separation...';
                drawnow % Refresh the interface
                
                preprocessing_temporary_period_separation = struct;   % Creates a struct to store the temporary detrended files as a backup
                % Loop to detrend and save the detrended variables inside the temporary
                % file
                
                for per_sep_loop = reference_variable
                    % Call the detrend function and gets the polynomial
                    % degree from the either the radio buttons or edit
                    % field
                    app.Workspace(per_sep_loop).data = app_separate_in_epochs(app.Workspace(per_sep_loop),app.PeriodLengthsecEditField.Value);
                    % Add a period length param in the workspace variable
                    app.Workspace(per_sep_loop).epoch_length = app.PeriodLengthsecEditField.Value;
                    % Update the workspace size
                    app.Workspace(per_sep_loop).size = sprintf('%dx%d',size(app.Workspace(per_sep_loop).data,1),size(app.Workspace(per_sep_loop).data,2));
                    
                    % Gets the original data
                    preprocessing_temporary_period_separation.(app.Workspace(per_sep_loop).name).data = app.Workspace(per_sep_loop).data;
                    % Gets the original sampling frequency
                    preprocessing_temporary_period_separation.(app.Workspace(per_sep_loop).name).sampling_frequency = app.Workspace(per_sep_loop).sampling_frequency;
                    % Gets the epoch length
                    preprocessing_temporary_period_separation.(app.Workspace(per_sep_loop).name).epoch_length = app.PeriodLengthsecEditField.Value;
                end
                % Saves the temporary file inside the default temporary folder
                % of the system (the append option is true, to save inside
                % an existing file
                savetmp(temp_file_name,true,'preprocessing_temporary_period_separation');
                % Exclude the temporary file from workspace after it is saved
                clear preprocessing_temporary_period_separation
                
                % Update Workspace after this pre-processing step
                UpdateWorkspace(app)
            end
            
            % Insert the path to the temporary file in the cell that stores
            % this kind of information            
            if isempty(app.Temp_files_path{1})  % Check if it is the first input
                app.Temp_files_path{1} = temp_file_name;    % Insert the the temp file name
            else
                app.Temp_files_path{end+1} = temp_file_name;    % Concatenate with previous file names
            end
            
        
        end
        
        % Get information about the segmentation of the variables
        function segmentation_info = get_segmentation_info(app, variable_index)
            var_length = length(app.Workspace(variable_index).data);    % Variable length
            segment_length_sample = app.SegmentsdurationhEditField.Value* 3600 * app.Workspace(variable_index).sampling_frequency;   % Hrs * sampling_frequency * 3600 (number of seconds in 1 hour)
            
            if var_length/segment_length_sample < 1 && var_length/segment_length_sample > 0 % If the var length is lower than the segment length
                n_segments = 1;
                segment_length_sample = var_length;
                adjusted_var_length = var_length;
                % Check if the variable length can be perfectly segmented
            elseif mod(var_length,segment_length_sample) ~= 0
                n_segments = floor(var_length/segment_length_sample);   % Number of segments
                extra_samples = mod(var_length,segment_length_sample);  % Number of extra samples
                segment_length_sample = segment_length_sample + floor(extra_samples/n_segments);    % Insert the correct number of samples
                adjusted_var_length = n_segments * segment_length_sample;   % Adjusted number of samples after adding the extra ones
            else
                adjusted_var_length = var_length;   % Keep it as it was before (the variable adjusted_var_length is essential for the next conditional)
                n_segments = var_length/segment_length_sample;
            end
            
            % If the variables are going to be divided into N seconds
            % blocks and N * fs is not a divisor of segment_length_sample
            if app.ONCheckBox_period_separation.Value && mod(adjusted_var_length,app.PeriodLengthsecEditField.Value * app.Workspace(variable_index).sampling_frequency) ~= 0
                % Get the block N * fs (number of samples)
                block_length_samples = app.PeriodLengthsecEditField.Value * app.Workspace(variable_index).sampling_frequency;
                % Get the new number of samples for the variable
                adjusted_var_length = floor(adjusted_var_length/block_length_samples) * block_length_samples;   
            end
            
            % Create a matrix with timestamps (beginning and end of each
            % segment --> row = segments; column 1 = beginning; column 2 = end)
            segmentation_info.timestamps(:,1) = 1:adjusted_var_length/n_segments:adjusted_var_length;
            segmentation_info.timestamps(:,2) = [segmentation_info.timestamps(2:end,1)-1; adjusted_var_length];
            segmentation_info.adjusted_var_length = adjusted_var_length;    % Final variable length
            segmentation_info.n_segments = n_segments;  % Number of segments
            segmentation_info.segments = 1:n_segments;  % List of segments
            segmentation_info.segment_length_sample = segment_length_sample;    % Segments length
        end
        
        % Used when the 'Run' button is pushed starting the pre-processing
        % step and the check box 'Do not segment the data' is NOT checked (important to have the reference_variable = variables
        % selected in the Workspace)
        function pre_processing_segmented(app, reference_variable)
            
            for variable_index = reference_variable     % Loop for each variable selected
                
                % Defines how the data is going to be segmented (necessary to
                % use the block length)
                segmentation_info = get_segmentation_info(app, reference_variable(variable_index));
                
                % Create a separate sampling frequency value for each
                % segment (ESSENTIAL)
                app.Workspace(variable_index).sampling_frequency = ones(1,segmentation_info.n_segments) * app.Workspace(variable_index).sampling_frequency;
                
                % RESAMPLING (check if it active) --> Create a temporary
                % variable to store the decimated variables
                if app.ONCheckBox_resampling.Value
                    if app.CheckBox_input_sampling_freq_resampling.Value    % If the user has inserted a new input sampling frequency
                        ratio_decimate = app.ChangeinputsamplingfrequencyHzEditField.Value / app.OutputsamplingfrequencyHzEditField.Value;   % Get the ratio for decimate (Input fs/Output fs)
                    else
                        ratio_decimate = app.Workspace(variable_index).sampling_frequency(1) / app.OutputsamplingfrequencyHzEditField.Value;   % Get the ratio for decimate (Input fs/Output fs)
                    end
                    decimated_temporary = NaN(segmentation_info.n_segments,segmentation_info.adjusted_var_length/ratio_decimate/segmentation_info.n_segments);    % Create temporary variable;
                end
                
                % Loop for each segment of selected variables
                for segments = segmentation_info.segments   
                    segment_timestamp = segmentation_info.timestamps(segments,1):segmentation_info.timestamps(segments,2);  % Get the indices from the beginning to the end
                    
                                   
                    % Creates a temporary .mat file and saves the data that is
                    % going to be processed
                    temp_file_name = sprintf('%s_preprocessing',strrep(char(datetime('now')),':','_'));
                    
                    preprocessing_temporary = struct;   % Creates a struct to store the temporary files as a backup
                    % Loop to save the original variables inside the temporary
                    % file
                    
                    % Gets the original data
                    preprocessing_temporary.(app.Workspace(variable_index).name).data = app.Workspace(variable_index).data(segment_timestamp);
                    % Gets the original sampling frequency
                    preprocessing_temporary.(app.Workspace(variable_index).name).sampling_frequency = app.Workspace(variable_index).sampling_frequency(segments);
                    
                    % Saves the temporary file inside the default temporary folder
                    % of the system (the append option is false, so to create a new
                    % file
%                     savetmp(temp_file_name,false,'preprocessing_temporary');
                    % Exclude the temporary file from workspace after it is saved
                    clear preprocessing_temporary
                    
                    % First pre-processing stept: DETREND (check if it active)
                    if app.ONCheckBox_detrend.Value
                        % Change status text
                        app.StatusTextArea.Value = 'Detrend...';
                        drawnow % Refresh the interface
                        
                        preprocessing_temporary_detrend = struct;   % Creates a struct to store the temporary detrended files as a backup
                        % Loop to detrend and save the detrended variables inside the temporary
                        % file
                        
                        % Call the detrend function and gets the polynomial
                        % degree from the either the radio buttons or edit
                        % field
                        app.Workspace(variable_index).data(segment_timestamp) = app_detrend(app.Workspace(variable_index).data(segment_timestamp),app.Polynomial_degree);
                        % Gets the original data
                        preprocessing_temporary_detrend.(app.Workspace(variable_index).name).data(segment_timestamp) = app.Workspace(variable_index).data(segment_timestamp);
                        % Gets the original sampling frequency
                        preprocessing_temporary_detrend.(app.Workspace(variable_index).name).sampling_frequency = app.Workspace(variable_index).sampling_frequency(segments);
                        
                        % Saves the temporary file inside the default temporary folder
                        % of the system (the append option is true, to save inside
                        % an existing file
%                         savetmp(temp_file_name,true,'preprocessing_temporary_detrend');
                        % Exclude the temporary file from workspace after it is saved
                        clear preprocessing_temporary_detrend
                        
                        % Update Workspace after this pre-processing step
                        UpdateWorkspace(app)
                    end
                    
                    % Second pre-processing stept: RESAMPLING (check if it active)
                    if app.ONCheckBox_resampling.Value
                        % Change status text
                        app.StatusTextArea.Value = 'Resampling...';
                        drawnow % Refresh the interface
                        
                        preprocessing_temporary_resampling = struct;   % Creates a struct to store the temporary detrended files as a backup
                        % Loop to detrend and save the detrended variables inside the temporary
                        % file
                        
                        % Call the resampling function and gets the output
                        % (mandatory) and input (optional) sampling frequencies
                        if logical(app.ChangeinputsamplingfrequencyHzEditField.Enable)  % If the input sampling frequency have been inserted by the user (optional)
                            % Get the decimated segment and stores it
                            % inside the temporary variable
                            decimated_temporary(segments,:) = app_decimate(app.Workspace(variable_index).data(segment_timestamp),app.Workspace(variable_index).sampling_frequency(segments),app.OutputsamplingfrequencyHzEditField.Value,app.ChangeinputsamplingfrequencyHzEditField);
                        else % If the input sampling frequency have not been inserted by the user (default - the parameter is empty)
                            decimated_temporary(segments,:) = app_decimate(app.Workspace(variable_index).data(segment_timestamp),app.Workspace(variable_index).sampling_frequency(segments),app.OutputsamplingfrequencyHzEditField.Value,[]);
                        end
                        app.Workspace(variable_index).sampling_frequency(segments) = app.OutputsamplingfrequencyHzEditField.Value;    % Get the new sampling frequency

                        % Store variable in the workspace if it is the
                        % original segment
                        if segments == segmentation_info.segments(end)
                            app.Workspace(variable_index).data = reshape(decimated_temporary,1,[]);    % Transform the matrix into a vector
                            clear decimated_temporary
                        end
                        
                        % Gets the original data
                        preprocessing_temporary_resampling.(app.Workspace(variable_index).name).data = app.Workspace(variable_index).data;
                        % Gets the original sampling frequency
                        preprocessing_temporary_resampling.(app.Workspace(variable_index).name).sampling_frequency = app.OutputsamplingfrequencyHzEditField.Value;
                        
                        % Saves the temporary file inside the default temporary folder
                        % of the system (the append option is true, to save inside
                        % an existing file
%                         savetmp(temp_file_name,true,'preprocessing_temporary_resampling');
                        % Exclude the temporary file from workspace after it is saved
                        clear preprocessing_temporary_resampling
                        
                        % Update Workspace after this pre-processing step
                        UpdateWorkspace(app)
                    end
                end
                    
               
                % Update the segments timestamps
                segmentation_info.timestamps(:,2) = segmentation_info.timestamps(:,2)/ratio_decimate;
                segmentation_info.timestamps(:,1) = [1; segmentation_info.timestamps(1:end-1,2)+1];
                % Loop for each segment of selected variables
                for segments = segmentation_info.segments   
                    segment_timestamp = segmentation_info.timestamps(segments,1):segmentation_info.timestamps(segments,2);  % Get the indices from the beginning to the end
                    
                    % Second pre-processing stept: FILTERING (check if it active)
                    if app.ONCheckBox_filtering.Value
                        % Change status text
                        app.StatusTextArea.Value = 'Filtering...';
                        drawnow % Refresh the interface
                        
                        preprocessing_temporary_filtering = struct;   % Creates a struct to store the temporary detrended files as a backup
                        % Loop to detrend and save the detrended variables inside the temporary
                        % file
                        
                        % Call the resampling function and gets the output
                        % (mandatory) and input (optional) sampling frequencies
                        if logical(app.SamplingfrequencyEditField_filtering.Enable) && ... % If the input sampling frequency have been inserted by the user (optional)
                                isnan(str2double(app.SamplingfrequencyEditField_filtering)) == false
                        % Filtering function using the sampling frequency
                        % inserted by the user
                        [app.Workspace(variable_index).data(segment_timestamp),filter_params] = app_filter(app.Workspace(variable_index).data(segment_timestamp),app.Workspace(variable_index).sampling_frequency(segments),app.Selected_radio_button_tag,...
                            app.HighpassEditField.Value,app.LowpassEditField.Value,app.NotchEditField.Value,...
                            str2double(app.SamplingfrequencyEditField_filtering));
                        else % If the input sampling frequency have not been inserted by the user (default - the parameter is empty)
                            % The sampling frequency input = false (so the
                            % function uses the variable associated sampling frequency
                            [app.Workspace(variable_index).data(segment_timestamp),filter_params] = app_filter(app.Workspace(variable_index).data(segment_timestamp),app.Workspace(variable_index).sampling_frequency(segments),app.Selected_radio_button_tag,...
                                app.HighpassEditField.Value,app.LowpassEditField.Value,app.NotchEditField.Value,...
                                false);
                        end
                        % Insert the filter params into the workspace variable
                        app.Workspace(variable_index).filter_params = filter_params;
                        preprocessing_temporary_filtering.(app.Workspace(variable_index).name).filter_params = app.Workspace(variable_index).filter_params;
                        % Gets the original data
                        preprocessing_temporary_filtering.(app.Workspace(variable_index).name).data = app.Workspace(variable_index).data;
                        % Gets the original sampling frequency
                        preprocessing_temporary_filtering.(app.Workspace(variable_index).name).sampling_frequency = app.Workspace(variable_index).sampling_frequency(segments);
                        
                        % Saves the temporary file inside the default temporary folder
                        % of the system (the append option is true, to save inside
                        % an existing file
%                         savetmp(temp_file_name,true,'preprocessing_temporary_filtering');
                        % Exclude the temporary file from workspace after it is saved
                        clear preprocessing_temporary_filtering
                        
                        % Update Workspace after this pre-processing step
                        UpdateWorkspace(app)
                    end
                end
                
                % Get a unique sampling frequency for all the segments (Use
                % the value from the last segment
                app.Workspace(variable_index).sampling_frequency = app.Workspace(variable_index).sampling_frequency(1);
                
                % OUT OF THE SEGMENT LOOP 
                % First pre-processing stept: PERIOD SEPARATION (check if it active)
                if app.ONCheckBox_period_separation.Value
                    % Change status text
                    app.StatusTextArea.Value = 'Period separation...';
                    drawnow % Refresh the interface
                    
                    preprocessing_temporary_period_separation = struct;   % Creates a struct to store the temporary detrended files as a backup
                    % Loop to detrend and save the detrended variables inside the temporary
                    % file
                    
                    
                    % Call the detrend function and gets the polynomial
                    % degree from the either the radio buttons or edit
                    % field
                    app.Workspace(variable_index).data = app_separate_in_epochs(app.Workspace(variable_index),app.PeriodLengthsecEditField.Value);
                    % Add a period length param in the workspace variable
                    app.Workspace(variable_index).epoch_length = app.PeriodLengthsecEditField.Value;
                    % Update the workspace size
                    app.Workspace(variable_index).size = sprintf('%dx%d',size(app.Workspace(variable_index).data,1),size(app.Workspace(variable_index).data,2));
                    
                    % Gets the original data
                    preprocessing_temporary_period_separation.(app.Workspace(variable_index).name).data = app.Workspace(variable_index).data;
                    % Gets the original sampling frequency
                    preprocessing_temporary_period_separation.(app.Workspace(variable_index).name).sampling_frequency = app.Workspace(variable_index).sampling_frequency;
                    % Gets the epoch length
                    preprocessing_temporary_period_separation.(app.Workspace(variable_index).name).epoch_length = app.PeriodLengthsecEditField.Value;
                    
                    % Saves the temporary file inside the default temporary folder
                    % of the system (the append option is true, to save inside
                    % an existing file
%                     savetmp(temp_file_name,true,'preprocessing_temporary_period_separation');
                    % Exclude the temporary file from workspace after it is saved
                    clear preprocessing_temporary_period_separation
                    
                    % Update Workspace after this pre-processing step
                    UpdateWorkspace(app)
                end
                
                % Insert the path to the temporary file in the cell that stores
                % this kind of information
                if isempty(app.Temp_files_path{1})  % Check if it is the first input
                    app.Temp_files_path{1} = temp_file_name;    % Insert the the temp file name
                else
                    app.Temp_files_path{end+1} = temp_file_name;    % Concatenate with previous file names
                end
                
            end
        end
    end
    
    methods (Access = public) % Public functions which can be called from outside the current app
        
        % Function to get the data from the dialog app (load_variables)
        function get_data_from_load_variables(app,loaded_files_output)
            %app: dialog app object
            %loaded_files_output: struct with the loaded data info
            % Check if this is first set of variables loaded
            if numel(app.Workspace) == 0
                app.Workspace = loaded_files_output;    % Just get the loaded_files and insert them inside app.Workspace since there isn't any problem of erasing any variable
            else % If there is already any variable inside app.Workspace
                if isempty(app.Workspace(1).name)   % Sometimes the Workspace has empty fields
                    app.Workspace = loaded_files_output;    % Just get the loaded_files and insert them inside app.Workspace since there isn't any problem of erasing any variable
                else
                    app.Workspace = [app.Workspace, loaded_files_output]; % Concatenate structs (Important! avoid the erasing of previous variables)
                end
            end
            
            % Update the workspace after the variables have been loaded
            UpdateWorkspace(app)
        end
        
        % Get the recording params from recording_parameters app and save it
        % on a properties (to be used by recording_parameters app)
        function transfer_recording_parameters(app,recording_app,recording_params,algorithm_params,output_path)
            % Transfer the params obtained from the recording_parameters
            % and from the added frequency bands
            app.Recording_params = recording_params;
            app.Algorithm_params = algorithm_params;
            app.Output_path = output_path;
            app.Recording_app = recording_app;
        end
        
        
        function transfer_frequency_bands_parameters(app,add_frequency_bands_app,frequency_bands_radio_button_tag)
            % Get the tag from the add_frequency_bands app and transfer to
            % the property Added_frequency_bands
            app.Added_frequency_bands = frequency_bands_radio_button_tag;
            app.Add_frequency_bands_app = add_frequency_bands_app;
        end
        
        % Update the workspace as soon as an action needs it to happen
        function UpdateWorkspace_public(app)
                       
            % Organize the workspace information in a cell (cell with the
            % number of rows = number of vars from the struct 'vars_info'
            % number of collumns = number of rows from WorkspaceTable
            struct_workspace = struct('name',[],'class',[],'size',[],'sampling_frequency',[],'current_state',[]);
            % Fill the cell with the variables important info
            for l_count = 1:size(app.Workspace,2)   % Loops throughout the elements (2, here columns) of the struct
                struct_workspace(l_count).name = app.Workspace(l_count).name;  %Get the name
                struct_workspace(l_count).class = app.Workspace(l_count).class;  %Get the type
                %Show the dimensions of the variable if it is a double type var with more than 10 values
                if isa(app.Workspace(l_count).data,'double') && length(app.Workspace(l_count).data)>10
                    %Get the dimensions as a string ('n x n')
                    struct_workspace(l_count).size = app.Workspace(l_count).size;
                    % Else if it is a scalar or a string, insert the value itself
                else
                    struct_workspace(l_count).size = app.Workspace(l_count).data; %Get the values
                end
                struct_workspace(l_count).sampling_frequency = app.Workspace(l_count).sampling_frequency;
                
                % Define if the variable is going to automatically receive
                % the checked current_state (== true);
                % This decision is based on the existence of an associated
                % sampling frequency (app.Workspace(i).sampling_frequency ~= false)
                if app.Workspace(l_count).sampling_frequency ~= false   %If the the variable has an associated sampling frequency
                    struct_workspace(l_count).current_state = true;     % Automatically make the current state true (allows the processing steps on this variables)
                else
                    struct_workspace(l_count).current_state = false;    % If not, turns it into a false value
                end
            end
            % Fill the Workspace table with the cell info
            % If the table is going to have only 1 row (only 1 variable),
            % it is necessary the add the parameter 'AsArray'
            if size(app.Workspace,1) <= 1
                app.WorkspaceTable.Data = struct2table(struct_workspace,'AsArray',true);
            else
                app.WorkspaceTable.Data = struct2table(struct_workspace);
            end
            
            % Update the sleep-wake cycle sorting algorithm drop down lists
            variableNames = {app.Workspace.name}; % Converts the the struct to a cell in order to extract only the name of the vars
            app.CA1ChannelDropDown.Items = variableNames; % CA1 drop down list
            app.EMGAccelChannelDropDown.Items = variableNames; % EMG drop down list
            
            % Update any graphical changes
            drawnow;
        end
        
        
        % Get information about the segmentation of the variables (Public)        
        function segmentation_info = get_segmentation_info_public(app, var_length, sampling_frequency)
            % var_length = length of the variable being processed
             segment_length_sample = app.SegmentsdurationhEditField.Value* 3600 * sampling_frequency;   % Hrs * sampling_frequency * 3600 (number of seconds in 1 hour)
            
            % Check if the variable length can be perfectly segmented
            if var_length/segment_length_sample < 1 && var_length/segment_length_sample > 0 % If the var length is lower than the segment length
                n_segments = 1;
                segment_length_sample = var_length;
                adjusted_var_length = var_length;
            elseif mod(var_length,segment_length_sample) ~= 0
                n_segments = floor(var_length/segment_length_sample);   % Number of segments
                extra_samples = mod(var_length,segment_length_sample);  % Number of extra samples
                segment_length_sample = segment_length_sample + floor(extra_samples/n_segments);    % Insert the correct number of samples
                adjusted_var_length = n_segments * segment_length_sample;   % Adjusted number of samples after adding the extra ones
            else
                adjusted_var_length = var_length;   % Keep it as it was before (the variable adjusted_var_length is essential for the next conditional)
                n_segments = var_length/segment_length_sample;
            end
            
            % Create a matrix with timestamps (beginning and end of each
            % segment --> row = segments; column 1 = beginning; column 2 = end)
            segmentation_info.timestamps(:,1) = 1:adjusted_var_length/n_segments:adjusted_var_length;
            segmentation_info.timestamps(:,2) = [segmentation_info.timestamps(2:end,1)-1; adjusted_var_length];
            segmentation_info.adjusted_var_length = adjusted_var_length;    % Final variable length
            segmentation_info.n_segments = n_segments;  % Number of segments
            segmentation_info.segments = 1:n_segments;  % List of segments
            segmentation_info.segment_length_sample = segment_length_sample;
            
        end
        
        % Function to change enable/disable the interface elements
        % accordingly to the user selection (app.EMG_Accel_ButtonGroup)
        function update_emg_accel_selection(app)
                    
            switch app.EMG_Accel_selected_radio_button_tag  % Get the tag selected by the user
                case 'EMG'
                    % Enable the EMG_Accel dropbox
                    app.EMGAccelChannelDropDown.Enable = true;
                    % Disable the x,y and z accelerometer axes
                    app.ZLabel.Enable = false;
                    app.YLabel.Enable = false;
                    app.XLabel.Enable = false;
                    app.AccelXDropDown.Enable = false;
                    app.AccelYDropDown.Enable = false;
                    app.AccelZDropDown.Enable = false;
                    % Update the variables
                    update_drop_down_variables(app)
                    
                case 'Accel1'
                    % Enable the EMG_Accel dropbox
                    app.EMGAccelChannelDropDown.Enable = true;
                    % Disable the x,y and z accelerometer axes
                    app.ZLabel.Enable = false;
                    app.YLabel.Enable = false;
                    app.XLabel.Enable = false;
                    app.AccelXDropDown.Enable = false;
                    app.AccelYDropDown.Enable = false;
                    app.AccelZDropDown.Enable = false;
                    % Update the variables
                    update_drop_down_variables(app)
                    
                case 'Accel3'
                    % Disable the EMG_Accel dropbox
                    app.EMGAccelChannelDropDown.Enable = false;
                    % Disable the x,y and z accelerometer axes
                    app.ZLabel.Enable = true;
                    app.YLabel.Enable = true;
                    app.XLabel.Enable = true;
                    app.AccelXDropDown.Enable = true;
                    app.AccelYDropDown.Enable = true;
                    app.AccelZDropDown.Enable = true;
                    % Update the variables
                    update_drop_down_variables(app)
            end
            
        end
        
        % Function to update all the Drop Down buttons
        function update_drop_down_variables(app)
            % Only works if there is at least 1 variable in the Workspace
            if ~isempty(app.Workspace(1).name)
                % Update the sleep-wake cycle sorting algorithm drop down lists
                variableNames = {app.Workspace.name}; % Converts the the struct to a cell in order to extract only the name of the vars
                app.CA1ChannelDropDown.Items = variableNames;   % CA1 drop down list
                app.EMGAccelChannelDropDown.Items = variableNames;   % EMG drop down list
                app.AccelXDropDown.Items = variableNames;       % Accel X axes drop list
                app.AccelYDropDown.Items = variableNames;       % Accel Y axes drop list
                app.AccelZDropDown.Items = variableNames;       % Accel Z axes drop list
            end
        end
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Initialize the workspace
            app.Workspace = struct('name',[],'size',[],'class',[],'current_state',[],'sampling_frequency_state',[],'data',[],'sampling_frequency',[],'load_state',[]);
            % Default polynomial degree to decimate function
            app.Polynomial_degree = 'constant';
            % Default filter type to filter function
            app.Selected_radio_button_tag = 'band';
            % Default (the algorith will not proceed with the preprocessing
            % step)
            app.Algorithm_preprocessing_step = false;
            % Creates a cell that will store the paths to the temporary
            % files (important, since they will be deleted if the software
            % is closed)
            app.Temp_files_path = cell(1);
            % Initialize the classification algorithm with de 'Default'
            % option selected
            app.Algorithm_preprocessing_step_final_sampling_frequency = 'Default';
            % Get the default value from the epoch length edit field
            app.EpochLengthValue = app.EpochLengthEditField.Value;
            % Define the radio button tag as the default one
            app.EMG_Accel_selected_radio_button_tag = 'EMG';
            % Enables the pre-processing step automatically when the app is
            % started
            app.IncludethealgorithmpreprocessingstepCheckBox.Value = true;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.SleepwakecycleclassificationsoftwareUIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {633, 633};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {394, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

        % Callback function
        function Load2ButtonPushed(app, event)
            %             text = sprintf('Select the LFP data');
            %             [file,path] = uigetfile('*.mat',text,'MultiSelect','on');
            %             % Get the filepath
            %             app.FilenameLoad = fullfile(path,file);
            %             % Change the file path in the edit field below
            %             app.SelectedFilePathEditField.Value = app.FilenameLoad;
            %             % Load the file (the variable is LFP1)
            %             load(app.FilenameLoad,'LFP1','srate')
            %             % Store the data in a app.Workspace together with its infos
            %             app.Workspace.name = 'LFP1';        % Var name
            %             app.Workspace.type = class(LFP1);   % Var type
            %             app.Workspace.size = size(LFP1);    % Var dimensions
            %             app.Workspace.data = LFP1;          % Var data
            %             app.Workspace.sampling_rate = srate;% Sampling rate value
            %             app.Workspace.state = true;         % Define if this data will be processed
            %             % (true) or not (false) by the next functions
            %             clear LFP1
            %
            %             % Update workspace; it's mandatory to initialize the function
            %             app.UpdateWorkspace();
            %             %
        end

        % Cell edit callback: WorkspaceTable
        function WorkspaceTableCellEdit(app, event)
            % Get the changed indices
            indices = event.Indices;
            % Get the data inserted in the new index
            newData = event.NewData;
            % Only the 'state' column can be changed in order to allow
            % that one variable to be processed by the following algorithms
            % True = allowed; False = not allowed;
            
            % Check if only the the 'state' column was changed
            if indices(2) == 5 % 5 = state column                
                %indices(1) is row index that is going to be changed
                app.Workspace(indices(1)).current_state = newData; % Change to the correct logical value
            end
            
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            % Get a title string the the file selection dialog box
            text = sprintf('Select the LFP data');
            % Opens the dialog box and enables the selection of a mat file
            [file,path] = uigetfile('*.mat',text,'MultiSelect','off');
            
            % Make sure that the app figure stay focused
            drawnow;
            figure(app.SleepwakecycleclassificationsoftwareUIFigure)
            
            % Make sure that the user selected a file
            if ~isequal(file,0)
                
                % Get the filepath by concatenating the path and file
                app.FilenameLoad = fullfile(path,file);
                % Change the file path in the edit field below
                % app.SelectedFilePathEditField.Value = app.FilenameLoad;
                
                %This function opens another app (load_variables) which organizes
                %the loading of specif variables from the selected mfile
                %app.LoadedFilesFromDialog: struct containing the loaded
                %variables and important informations
                %load_variables: app created to load variables, enables the
                %selection of specific variables
                %app: self (important to permit the exchange of variables
                %between apps
                %app.FilenameLoad: mfile pathway which is going to be loaded
                load_variables(app,app.FilenameLoad);
            end
        end

        % Value changed function: PeriodLengthsecEditField
        function PeriodLengthsecEditFieldValueChanged(app, event)
            reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
            
            % Check if there is at least 1 useful variable
            if sum(reference_variable) > 0
                % Gets the first index from which the sampling
                % frequency can be obtained
                first_index = find(reference_variable == true);
                first_index = first_index(1);
                
                % Automatically gets the other parameters
                calc_period_separation_params(app,first_index,app.PeriodLengthsecEditField.Value,app.Workspace(first_index).sampling_frequency)
            end
            
        end

        % Value changed function: ONCheckBox_period_separation
        function ONCheckBox_period_separationValueChanged(app, event)
            value = app.ONCheckBox_period_separation.Value;
            switch value
                case true
                    app.ONCheckBox_period_separation.Text = 'ON';
                case false
                    app.ONCheckBox_period_separation.Text = 'OFF';
            end
        end

        % Callback function
        function PlotButtonPushed(app, event)
            % Checks the number and which Workspace variables are selected
            if sum([app.Workspace.current_state] == true) == 0  % If the number of selected variables is 0
                % Displays an alert dialog box indicating that at least 1
                % variable must be selected
                uialert(app.SleepwakecycleclassificationsoftwareUIFigure,'You must select at least 1 variable to plot','Error - minimum variables')
            elseif sum([app.Workspace.current_state] == true) > 3 % If the number of selected variables is higher than 3
                % Displays an alert dialog box indicating that the maximum
                % number of selected variables is 3
                uialert(app.SleepwakecycleclassificationsoftwareUIFigure,'You must select up to 3 variables to plot','Error - maximum variables')
            else % If at least 1 and at maximum 3 variables were selected
                % Calls the plot app
                selected_variables = app.Workspace.current_state; % selected_variables is a logical index
                Plot_app(app,selected_variables)
            end
        end

        % Selection changed function: PolynomialdegreeButtonGroup
        function PolynomialdegreeButtonGroupSelectionChanged(app, event)
            % Function that changes the selected the radio button and
            % stores it to be an input when the detrend function is called
            % by 'Run' button
            selected_radio_button_index = [app.PolynomialdegreeButtonGroup.Buttons.Value];  % Logical index indicating the selected radio button (true)
            % Check if radio button 'Other' was checked
            if find(selected_radio_button_index == true) == 4
                % Enables the edit field to be edited
                app.PolynomialDegreeEditField.Enable = true;
            else
                % Prevents the edit field from being edited
                app.PolynomialDegreeEditField.Enable = false;
            end
            % Extracts the numerical value of the index and act accordingly
            switch find(selected_radio_button_index == true)
                case 1  % Constant
                    app.Polynomial_degree = 'constant';
                case 2  % Linear
                    app.Polynomial_degree = 'linear';
                case 3  % Quadratic
                    app.Polynomial_degree = 2;
                case 4  % Other
                    % Don't do anything, since the important value is
                    % inside the Edit Field box
            end
            %selectedButton = app.PolynomialdegreeButtonGroup.SelectedObject;
            
        end

        % Value changed function: PolynomialDegreeEditField
        function PolynomialDegreeEditFieldValueChanged(app, event)
            % When 'Other' radio button is checked, it enables the field to
            % be changed. The polynomial degree value is inserted in the
            % numerical edit field
            app.Polynomial_degree = app.PolynomialDegreeEditField.Value;
            
        end

        % Value changed function: 
        % CheckBox_input_sampling_freq_resampling
        function CheckBox_input_sampling_freq_resamplingValueChanged(app, event)
            % Changing the checkbox value will enable the numeric edit
            % field to be changed. It permits a new sampling frequency
            % value to be inserted instead of the sampling frequency
            % associated with the vector
            
            % If the value == true
            if app.CheckBox_input_sampling_freq_resampling.Value
                % Enables the edit field to be changed
                app.ChangeinputsamplingfrequencyHzEditField.Enable = true;
            else    % If the value == false
                % Forbids the edit field to be changed
                app.ChangeinputsamplingfrequencyHzEditField.Enable = false;
            end
            
        end

        % Value changed function: ONCheckBox_resampling
        function ONCheckBox_resamplingValueChanged(app, event)
            value = app.ONCheckBox_resampling.Value;
            switch value
                case true
                    app.ONCheckBox_resampling.Text = 'ON';
                case false
                    app.ONCheckBox_resampling.Text = 'OFF';
            end
        end

        % Value changed function: ONCheckBox_filtering
        function ONCheckBox_filteringValueChanged(app, event)
            value = app.ONCheckBox_filtering.Value;
            switch value
                case true
                    app.ONCheckBox_filtering.Text = 'ON';
                case false
                    app.ONCheckBox_filtering.Text = 'OFF';
            end
        end

        % Value changed function: ONCheckBox_detrend
        function ONCheckBox_detrendValueChanged(app, event)
            value = app.ONCheckBox_detrend.Value;
            switch value
                case true
                    app.ONCheckBox_detrend.Text = 'ON';
                case false
                    app.ONCheckBox_detrend.Text = 'OFF';
            end
        end

        % Selection changed function: FiltertypeButtonGroup
        function FiltertypeButtonGroupSelectionChanged(app, event)
            % Function that changes the selected the radio button and
            % stores it to be an input once the filtering function is called
            % by the 'Run' button
            
            % String containing the tag from the selected radio button
            % ('Band','High','Low','Notch')
%                         app.Selected_radio_button_tag = app.FiltertypeButtonGroup.Buttons(1).Tag;

           app.Selected_radio_button_tag = app.FiltertypeButtonGroup.Buttons([app.FiltertypeButtonGroup.Buttons.Value]).Tag;
            % Check which radio button was checked according to its Tag
            switch app.Selected_radio_button_tag
                case 'band'
                    app.NotchEditField.Enable = false;
                    app.LowpassEditField.Enable = true;
                    app.HighpassEditField.Enable = true;
                case 'high'
                    app.NotchEditField.Enable = false;
                    app.LowpassEditField.Enable = false;
                    app.HighpassEditField.Enable = true;
                case 'low'
                    app.NotchEditField.Enable = false;
                    app.HighpassEditField.Enable = false;
                    app.LowpassEditField.Enable = true;
                case 'notch'
                    app.HighpassEditField.Enable = false;
                    app.LowpassEditField.Enable = false;
                    app.NotchEditField.Enable = true;
            end
            
        end

        % Selection change function: TabGroup
        function TabGroupSelectionChanged(app, event)
            % If the tab is changed, check which one was selected according
            % to its Tag
            selectedTab_tag = app.TabGroup.SelectedTab.Tag;
                        
            switch selectedTab_tag
                case 'period_separation'
                    % Reference_variable = logical index indicating the
                    % variables that either are selected and have an
                    % associated sampling frequency
                    reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
                    
                    % Check if there is at least 1 useful variable
                    if sum(reference_variable) > 0
                        % Gets the first index from which the sampling
                        % frequency can be obtained
                        first_index = find(reference_variable == true);
                        first_index = first_index(1);
                        
                        % Only update the sampling frequency edit field if the
                        % check box is unchecked
                        if app.sampling_frequency_checkbox_period_separation.Value == false
                                                        
                            % Automatically change the sampling frequency
                            % presented in the edit field
                            % Gets the first variable with an associated
                            % sampling frequency, enables edition and then, forbids
                            % it
                            app.SamplingfrequencyEditField_period_separation.Enable = true;
                            app.SamplingfrequencyEditField_period_separation.Value = app.Workspace(first_index).sampling_frequency;
                            app.SamplingfrequencyEditField_period_separation.Enable = false;
                            
                            % Automatically gets the other parameters
                            [~] = calc_period_separation_params(app,first_index,app.PeriodLengthsecEditField.Value,app.Workspace(first_index).sampling_frequency);
                                                        
                        else % If the sampling frequency is checked
                            
                            % Automatically gets the other parameters using
                            % the sampling frequency informed by the user
                            [~] = calc_period_separation_params(app,first_index,app.PeriodLengthsecEditField.Value, app.SamplingfrequencyEditField_period_separation.Value);
                        end
                        
                    else    % If there is no variable to get the sampling frequency from, insert the value 0
                        app.SamplingfrequencyEditField_period_separation.Value = 0;
                    end
                    
                    
                    
                case 'resampling'
                    % Reference_variable = logical index indicating the
                    % variables that either are selected and have an
                    % associated sampling frequency
                    reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
                    
                    % Only update the input/output sampling frequency
                    % ratio if the output sampling frequency have been
                    % correctly inserted
                    if app.OutputsamplingfrequencyHzEditField.Value ~= false && app.OutputsamplingfrequencyHzEditField.Value ~= 0
                        
                        % Check if there is at least 1 useful variable
                        if sum(reference_variable) > 0
                            % Gets the first index from which the sampling
                            % frequency can be obtained
                            first_index = find(reference_variable == true);
                            first_index = first_index(1);
                            % If the input sampling frequency field is
                            % enabled and has an value
                            if logical(app.ChangeinputsamplingfrequencyHzEditField.Enable) && app.ChangeinputsamplingfrequencyHzEditField.Value ~= 0
                                % Update the ratio value according to the
                                % input and out inserted by the user
                                app.InputOutputfrequencyratioEditField.Value = app.ChangeinputsamplingfrequencyHzEditField.Value / app.OutputsamplingfrequencyHzEditField.Value;
                            else    % If the input sampling frequency is automatically obtained from the first selected variable
                                app.InputOutputfrequencyratioEditField.Value = app.Workspace(first_index).sampling_frequency / app.OutputsamplingfrequencyHzEditField.Value;
                            end
                        else    % If there is no variable to get the sampling frequency from, insert the value 0
                            app.InputOutputfrequencyratioEditField.Value = 0;
                        end
                    end
                    
                    % If the panel 'Details' has been selected, update the number of samples for each segment
                case 'details'
                    % Reference_variable = logical index indicating the
                    % variables that either are selected and have an
                    % associated sampling frequency
                    reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
                    
                    % Check if there is at least 1 useful variable
                    if sum(reference_variable) > 0
                        % Gets the first index from which the sampling
                        % frequency can be obtained
                        first_index = find(reference_variable == true);
                        first_index = first_index(1);
                        
                        % Change the sample number edit field to the
                        % appropirate number (number of hours * sampling
                        % frequency)
                        app.SegmentsdurationsamplesEditField.Value =  app.SegmentsdurationhEditField.Value * app.Workspace(first_index).sampling_frequency * 3600;
                    end                   
            end
            
            
            
        end

        % Value changed function: 
        % sampling_frequency_checkbox_period_separation
        function sampling_frequency_checkbox_period_separationValueChanged(app, event)
            % If the checkbox is checked the associated edit field can be
            % edited
            if app.sampling_frequency_checkbox_period_separation.Value
                app.SamplingfrequencyEditField_period_separation.Enable = true; % Make it possible to be edited
            else    % If it is unchecked
                app.SamplingfrequencyEditField_period_separation.Enable = false; % Make it impossible to be edited
            end
            
        end

        % Button pushed function: Run_preprocessing_Button
        function Run_preprocessing_ButtonPushed(app, event)
            % The most important callback from the pre-processing group of
            % functions, since this is the function that triggers all the
            % other ones
            
            % Prevents any kind of editing inside the pre-processing panel
            prevent_edition(app)
            
            % Change status text
            app.StatusTextArea.Value = 'Saving original data...';
            drawnow % Refresh the interface
            
            % Logical vector indicating the pre-processing functions that are active (true) or not (false)
            app.Active_pre_processing_functions = [app.ONCheckBox_detrend.Value ...
                app.ONCheckBox_filtering.Value ...
                app.ONCheckBox_resampling.Value ...
                app.ONCheckBox_period_separation.Value ...
                ];
            
            % Get the workspace variables that are going to be processed
            reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
            reference_variable = find(reference_variable == true);
            
            % Check if the data is going to be segmented or not
            if app.DonotsegmentthedataCheckBox.Value % Checked
                pre_processing_non_segmented(app,reference_variable)    % Call the appropriate function
            else        % Not checked
                pre_processing_segmented(app,reference_variable)    % Call the appropriate function
            end
            
            % Change status text
            app.StatusTextArea.Value = 'Done!';
            drawnow % Refresh the interface
            
            % Allows editing inside the pre-processing panel after it has
            % been finished
            enable_edition(app)
        end

        % Value changed function: 
        % CheckBox_filtering_sampling_frequency
        function CheckBox_filtering_sampling_frequencyValueChanged(app, event)
            % If the checkbox is checked the associated edit field can be
            % edited
            if app.sampling_frequency_checkbox_period_separation.Value
                app.SamplingfrequencyEditField_filtering.Enable = true; % Make it possible to be edited
            else    % If it is unchecked
                app.SamplingfrequencyEditField_filtering.Enable = false; % Make it impossible to be edited
            end
            
        end

        % Value changed function: OutputsamplingfrequencyHzEditField
        function OutputsamplingfrequencyHzEditFieldValueChanged(app, event)
            % Reference_variable = logical index indicating the
            % variables that either are selected and have an
            % associated sampling frequency
            reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
            
            % Only update the input/output sampling frequency
            % ratio if the output sampling frequency have been
            % correctly inserted
            if app.OutputsamplingfrequencyHzEditField.Value ~= false && app.OutputsamplingfrequencyHzEditField.Value ~= 0
                
                % Check if there is at least 1 useful variable
                if sum(reference_variable) > 0
                    % Gets the first index from which the sampling
                    % frequency can be obtained
                    first_index = find(reference_variable == true);
                    first_index = first_index(1);
                    % If the input sampling frequency field is
                    % enabled and has an value
                    if logical(app.ChangeinputsamplingfrequencyHzEditField.Enable) && app.ChangeinputsamplingfrequencyHzEditField.Value ~= 0
                        % Update the ratio value according to the
                        % input and out inserted by the user
                        app.InputOutputfrequencyratioEditField.Value = app.ChangeinputsamplingfrequencyHzEditField.Value / app.OutputsamplingfrequencyHzEditField.Value;
                    else    % If the input sampling frequency is automatically obtained from the first selected variable
                        app.InputOutputfrequencyratioEditField.Value = app.Workspace(first_index).sampling_frequency / app.OutputsamplingfrequencyHzEditField.Value;
                    end
                else    % If there is no variable to get the sampling frequency from, insert the value 0
                    app.InputOutputfrequencyratioEditField.Value = 0;
                end
            end
     
        end

        % Value changed function: 
        % ChangeinputsamplingfrequencyHzEditField
        function ChangeinputsamplingfrequencyHzEditFieldValueChanged(app, event)
            % Update the ratio value according to the
            % input and out inserted by the user
            app.InputOutputfrequencyratioEditField.Value = app.ChangeinputsamplingfrequencyHzEditField.Value / app.OutputsamplingfrequencyHzEditField.Value;
            
        end

        % Value changed function: CA1ChannelDropDown
        function CA1ChannelDropDownValueChanged(app, event)
            % Make sure that the selected value will be different from the
            % EMG drop down
%             if strcmp(app.CA1ChannelDropDown.Value,app.EMGAccelChannelDropDown.Value)
%                 % Clears the EMG drop down
%                 app.EMGAccelChannelDropDown.Value = '';
%             end
        end

        % Value changed function: EMGAccelChannelDropDown
        function EMGAccelChannelDropDownValueChanged(app, event)
            % Make sure that the selected value will be different from the
            % EMG drop down
%             if strcmp(app.EMGAccelChannelDropDown.Value,app.CA1ChannelDropDown.Value)
%                 % Clears the EMG drop down
%                 app.CA1ChannelDropDown.Value = '';
%             end
        end

        % Value changed function: 
        % IncludethealgorithmpreprocessingstepCheckBox
        function IncludethealgorithmpreprocessingstepCheckBoxValueChanged(app, event)
            % Makes the algorithm run (true) or not (false) the
            % preprocessing step
            app.Algorithm_preprocessing_step = app.IncludethealgorithmpreprocessingstepCheckBox.Value;
            
%             % Open the dialog box only if the check box has been checked
%             if app.IncludethealgorithmpreprocessingstepCheckBox.Value
%                 
%                 % Opens a dialog box asking to user about the final Sampling
%                 % Frequency data after the algorithm pre-processing step
%                 confirmation_text = 'Select the recording final sampling frequency after the algorithm pre-processing step has been executed. If your data cannot be resampled to any of the listed sampling frequencies, it will be the nearest value possible.'; % Create the text
%                 title_text = 'Select the final sampling frequency for your data';
%                 % Creates the alert and asks to abort a new visual inspection or to
%                 % re-inspect it (it has a CloseFcn callback to close the figure
%                 % and resume the function execution
%                 fig = uifigure; % Figue handle
%                 selection = uiconfirm(fig,confirmation_text,title_text,...
%                     'Options',{'1000 Hz','500 Hz'},...
%                     'DefaultOption',1,'CloseFcn',@(h,e)close(fig));
%                 
%                 % Act accordlying to the selected option (It will be used by
%                 % the function pre-processing)
%                 switch selection
%                     case '1000 Hz'
%                         app.Algorithm_preprocessing_step_final_sampling_frequency = 1000;
%                     case '500 Hz'
%                         app.Algorithm_preprocessing_step_final_sampling_frequency = 500;
%                 end
%                 
%             end
        end

        % Button pushed function: RunButton_classification_algorithm
        function RunButton_classification_algorithmPushed(app, event)
            % Change status text
            app.StatusTextArea.Value = 'Running the classification algorithm...';
            drawnow % Refresh the interface
            
            % Get the answer to preprocessing (the algorithm will or not
            % preprocess the data TRUE or FALSE
            pre_process_state = app.IncludethealgorithmpreprocessingstepCheckBox.Value;
            
            % Get the selected radio button and act accordingly
            app.Algorithm_selected_radio_button_tag = app.SleepWakeAlgorithmButtonGroup.Buttons([app.SleepWakeAlgorithmButtonGroup.Buttons.Value]).Tag;
            
            switch app.Algorithm_selected_radio_button_tag % Get which radio button was selected
                case 'workspace'
                    load_data = false;  % The data from workspace will be used
                    % Get the selected variable names for CA1 and EMG
                    % CA1
                    selected_var_name_CA1 = app.CA1ChannelDropDown.Value;  % Get the selected CA1 var name from the drop box
                    selected_index_CA1 = find(contains({app.Workspace.name},selected_var_name_CA1));  % Find the index corresponding to the name of the selected var
                    
                    switch app.EMG_Accel_selected_radio_button_tag
                        case 'EMG'
                            % EMG
                            selected_var_name_EMG = app.EMGAccelChannelDropDown.Value;  % Get the selected EMG var name from the drop box
                            selected_index_EMG = find(contains({app.Workspace.name},selected_var_name_EMG));  % Find the index corresponding to the name of the selected var
                            
                            selected_indices = [selected_index_CA1 selected_index_EMG];
                            % Call the sorting algorithm using the specified variables
                            %                     Copy_of_GMM_Classifier_Training_fixed(app,app.Workspace(selected_index_CA1),app.Workspace(selected_index_EMG),pre_process_state,load_data,selected_indices)
                            GMM_Classifier_Training_fixed(app,app.Workspace(selected_index_CA1),app.Workspace(selected_index_EMG),[],[],pre_process_state,load_data,selected_indices,'EMG')
                            
                        case 'Accel1'
                            % EMG
                            selected_var_name_Accel = app.EMGAccelChannelDropDown.Value;  % Get the selected Accel var name from the drop box
                            selected_index_Accel = find(contains({app.Workspace.name},selected_var_name_Accel));  % Find the index corresponding to the name of the selected var
                            
                            selected_indices = [selected_index_CA1 selected_index_Accel];
                            % Call the sorting algorithm using the specified variables
                            %                     Copy_of_GMM_Classifier_Training_fixed(app,app.Workspace(selected_index_CA1),app.Workspace(selected_index_EMG),pre_process_state,load_data,selected_indices)
                            GMM_Classifier_Training_fixed(app,app.Workspace(selected_index_CA1),app.Workspace(selected_index_Accel),[],[],pre_process_state,load_data,selected_indices,'Accel1')
                            
                        case 'Accel3'
                            % Accel X
                            selected_var_name_AccelX = app.AccelXDropDown.Value;  % Get the selected Accel X axes var name from the drop box
                            selected_index_AccelX = find(contains({app.Workspace.name},selected_var_name_AccelX));  % Find the index corresponding to the name of the selected var
                            % Accel Y
                            selected_var_name_AccelY = app.AccelYDropDown.Value;  % Get the selected Accel Y axes var name from the drop box
                            selected_index_AccelY = find(contains({app.Workspace.name},selected_var_name_AccelY));  % Find the index corresponding to the name of the selected var
                            % Accel Z
                            selected_var_name_AccelZ = app.AccelZDropDown.Value;  % Get the selected Accel Z axes var name from the drop box
                            selected_index_AccelZ = find(contains({app.Workspace.name},selected_var_name_AccelZ));  % Find the index corresponding to the name of the selected var
                            
                            selected_indices = [selected_index_CA1 selected_index_AccelX selected_index_AccelY selected_index_AccelZ];
                            % Call the sorting algorithm using the specified variables
                            %                     Copy_of_GMM_Classifier_Training_fixed(app,app.Workspace(selected_index_CA1),app.Workspace(selected_index_EMG),pre_process_state,load_data,selected_indices)
                            GMM_Classifier_Training_fixed(app,app.Workspace(selected_index_CA1),app.Workspace(selected_index_AccelX),app.Workspace(selected_index_AccelY),app.Workspace(selected_index_AccelZ),pre_process_state,load_data,selected_indices,'Accel3')
                    end
                    
                case 'load_file' % Data already saved will be used
                    load_data = true;
                    % Call the sorting algorithm using the specified variables
                    GMM_Classifier_Training_fixed(app,[],[],[],[],pre_process_state,load_data)
            end
            
        end

        % Selection changed function: SleepWakeAlgorithmButtonGroup
        function SleepWakeAlgorithmButtonGroupSelectionChanged(app, event)
            % Get the selected radio button and act accordingly
            app.Algorithm_selected_radio_button_tag = app.SleepWakeAlgorithmButtonGroup.Buttons([app.SleepWakeAlgorithmButtonGroup.Buttons.Value]).Tag;
            % Check which radio button was checked according to its Tag
            switch app.Algorithm_selected_radio_button_tag                
                case 'workspace' % Default (it will use the variables already in the workspace)
                    % Enable the selection of LFP and EMG variables (List) and
                    % Enable the selection of the pre-processing step check box
                    app.EMGAccelChannelDropDown.Enable = true;
                    app.CA1ChannelDropDown.Enable = true;
                    app.CA1ChannelDropDownLabel.Enable = true;
                    app.IncludethealgorithmpreprocessingstepCheckBox.Enable = true;
                    app.Selectthedata_variablematfileLabel.Enable = false;
                    % Accelerometer axes elements (True only if the
                    % Accelometer 3 axes option has been selected
                    if strcmp(app.EMG_Accel_selected_radio_button_tag,'Accel3')
                        app.ZLabel.Enable = true;
                        app.YLabel.Enable = true;
                        app.XLabel.Enable = true;
                        app.AccelXDropDown.Enable = true;
                        app.AccelYDropDown.Enable = true;
                        app.AccelZDropDown.Enable = true;
                        app.EMGAccelChannelDropDown.Enable = true;  % Make the EMG Accel drop down false
                    end
                    % EMG Accel button group
                    app.EMG_Accel_ButtonGroup.Enable = 'on';
                
                case 'load_file' % It will load a set of variables previously saved after the algorithm pre-processing step
                    % Unable the selection of LFP and EMG variables (List) and
                    % Unable the selection of the pre-processing step check box
                    app.EMGAccelChannelDropDown.Enable = false;
                    app.CA1ChannelDropDown.Enable = false;
                    app.CA1ChannelDropDownLabel.Enable = false;
                    app.IncludethealgorithmpreprocessingstepCheckBox.Enable = false;
                    app.Selectthedata_variablematfileLabel.Enable = true;
                    % Accelerometer axes elements
                    app.ZLabel.Enable = false;
                    app.YLabel.Enable = false;
                    app.XLabel.Enable = false;
                    app.AccelXDropDown.Enable = false;
                    app.AccelYDropDown.Enable = false;
                    app.AccelZDropDown.Enable = false;
                    % EMG Accel button group
                    app.EMG_Accel_ButtonGroup.Enable = 'off';
                    
            end
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            % Get the workspace variables that are going to be saved
            reference_variable = [app.Workspace.current_state];
            % Get a list with the names of the selected variables
            variable_names_cell = {app.Workspace(reference_variable).name};
            
            % Create a GUI to select the folder and file name
            [file,name,path] = uiputfile('*.*','File Selection','Change_the_file_name.m');
            
            % Make sure that the app figure stay focused
            drawnow;
            figure(app.SleepwakecycleclassificationsoftwareUIFigure)
            
            % Makes sure that a name and folder were selected or that the
            % user have not pressed 'Cancel'
            if path == 1    % Filename and path were selected
                % Create a full name
                file_name = fullfile(name,file,filesep);
                
                % Check the size (in memory) to choose if it will be saved
                % using the v7.3 flag (if > 2Gb)
                max_size = 2097152; % number of bytes in 2 GB
                % Get information from the variables stored inside the
                % workspace (only 'double')
                total_size = 0;
                
                for cont = find(reference_variable == true)    % loop with only the selected variables
                    if isa(app.Workspace(reference_variable(cont)).data,'double')  % If it is double
                        total_size = total_size + numel(app.Workspace(reference_variable(cont)).data) * 8; % It is times 8 because each value occupies 8 bytes
                    end
                end
                
                % Check if it total size is higher or lower than the
                % maximum 2 GB
                if total_size >= max_size
                    % Save using the flag v7.3
                    save(file_name,variable_names_cell{:},'-v7.3','-nocompression')
                else % Case the total size is lesser than the maximum
                    % Save without the flag v7.3
                    save(file_name,variable_names_cell)
                end
            end
            
        end

        % Button pushed function: ExcludeButton
        function ExcludeButtonPushed(app, event)
            % Get the workspace variables that are going to be excluded
            reference_variable = [app.Workspace.current_state];
               
            % Efectivelly excludes the variables from the Workspace
            app.Workspace(reference_variable) = [];
            
            % Update the workspace
            UpdateWorkspace(app)
        end

        % Close request function: 
        % SleepwakecycleclassificationsoftwareUIFigure
        function SleepwakecycleclassificationsoftwareUIFigureCloseRequest(app, event)
            % Check if it is not empty
            if ~isempty(app.Temp_files_path{1})
                % Clear any temporary file that has been created
                erasetmp(app.Temp_files_path)
            end
            
            % Clear
            delete(app)
            
            % Clear every single variable from workspace
            clear all                             
            
        end

        % Value changed function: 
        % SamplingfrequencyEditField_period_separation
        function SamplingfrequencyEditField_period_separationValueChanged(app, event)
            % Automatically updates the period length accordingly to the sampling frequency
            
            % Reference_variable = logical index indicating the
            % variables that either are selected and have an
            % associated sampling frequency
            reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
            
            % Check if there is at least 1 useful variable
            if sum(reference_variable) > 0
                % Gets the first index from which the sampling
                % frequency can be obtained
                first_index = find(reference_variable == true);
                first_index = first_index(1);
                
                % Automatically gets the other parameters using
                % the sampling frequency informed by the user
                [~] = calc_period_separation_params(app,first_index,app.PeriodLengthsecEditField.Value, app.SamplingfrequencyEditField_period_separation.Value);
            end
            
        end

        % Value changed function: SegmentsdurationhEditField
        function SegmentsdurationhEditFieldValueChanged(app, event)
            % Function to update the number of samples for each segment when
            % the duration of segment (in hours) is modified
            
            % Reference_variable = logical index indicating the
            % variables that either are selected and have an
            % associated sampling frequency
            reference_variable = [app.Workspace.current_state] & [app.Workspace.sampling_frequency] ~= false;
            
            % Check if there is at least 1 useful variable
            if sum(reference_variable) > 0
                % Gets the first index from which the sampling
                % frequency can be obtained
                first_index = find(reference_variable == true);
                first_index = first_index(1);
                
                % Change the sample number edit field to the
                % appropirate number (number of hours * sampling
                % frequency)
                app.SegmentsdurationsamplesEditField.Value =  app.SegmentsdurationhEditField.Value * app.Workspace(first_index).sampling_frequency * 3600;
            end
            
        end

        % Menu selected function: SleepwakecyclearchitectureMenu
        function SleepwakecyclearchitectureMenuSelected(app, event)
            % Opens a new window with options, graphs related to the
            % architecture analysis
            Sleep_archictecture_interface;
        end

        % Value changed function: OutputSamplingFrequencyDropDown
        function OutputSamplingFrequencyDropDownValueChanged(app, event)
            % Get the sampling frequency value selected by the user
            switch app.OutputSamplingFrequencyDropDown.Value
                case 'Default'
                    app.Algorithm_preprocessing_step_final_sampling_frequency = 'Default';
                case '1000 Hz'
                    % Presents a warning
                    uiwait(msgbox(['Using a high sampling frequency increases the computational cost of this task. '...
                        'It is recommended to use either the Default or 500 Hz options'],'Warning','modal'));
                    app.Algorithm_preprocessing_step_final_sampling_frequency = 1000;
                case '500 Hz'
                    app.Algorithm_preprocessing_step_final_sampling_frequency = 500;
            end
        end

        % Value changed function: EpochLengthEditField
        function EpochLengthEditFieldValueChanged(app, event)
            % Get the value from the edit field and insert it in a
            % property (where the user cannot change while the algorithm is
            % running and will be used as a reference)
            app.EpochLengthValue = app.EpochLengthEditField.Value;
            
        end

        % Selection changed function: EMG_Accel_ButtonGroup
        function EMG_Accel_ButtonGroupSelectionChanged(app, event)
            % Function which responds to the user selection about the data
            % type (EMG; Accel 1 channel; Accel 3 channels)            
            % Get the selected radio button and act accordingly
            app.EMG_Accel_selected_radio_button_tag = app.EMG_Accel_ButtonGroup.Buttons([app.EMG_Accel_ButtonGroup.Buttons.Value]).Tag;
            
            % Update the interface elements
            update_emg_accel_selection(app)
              
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create SleepwakecycleclassificationsoftwareUIFigure and hide until all components are created
            app.SleepwakecycleclassificationsoftwareUIFigure = uifigure('Visible', 'off');
            app.SleepwakecycleclassificationsoftwareUIFigure.AutoResizeChildren = 'off';
            app.SleepwakecycleclassificationsoftwareUIFigure.Color = [1 1 1];
            app.SleepwakecycleclassificationsoftwareUIFigure.Position = [100 100 856 633];
            app.SleepwakecycleclassificationsoftwareUIFigure.Name = 'Sleep-wake cycle classification software';
            app.SleepwakecycleclassificationsoftwareUIFigure.Resize = 'off';
            app.SleepwakecycleclassificationsoftwareUIFigure.CloseRequestFcn = createCallbackFcn(app, @SleepwakecycleclassificationsoftwareUIFigureCloseRequest, true);
            app.SleepwakecycleclassificationsoftwareUIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.SleepwakecycleclassificationsoftwareUIFigure.Tag = 'MainInterface';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.SleepwakecycleclassificationsoftwareUIFigure);
            app.GridLayout.ColumnWidth = {394, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.LeftPanel);
            app.GridLayout2.ColumnWidth = {'1.31x'};
            app.GridLayout2.RowHeight = {120, 391, 80};
            app.GridLayout2.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create DatamanipulationPanel
            app.DatamanipulationPanel = uipanel(app.GridLayout2);
            app.DatamanipulationPanel.TitlePosition = 'centertop';
            app.DatamanipulationPanel.Title = 'Data manipulation';
            app.DatamanipulationPanel.BackgroundColor = [1 1 1];
            app.DatamanipulationPanel.Layout.Row = 1;
            app.DatamanipulationPanel.Layout.Column = 1;
            app.DatamanipulationPanel.FontWeight = 'bold';

            % Create LoadvariablesLabel
            app.LoadvariablesLabel = uilabel(app.DatamanipulationPanel);
            app.LoadvariablesLabel.Position = [17 69 84 22];
            app.LoadvariablesLabel.Text = 'Load variables';

            % Create LoadButton
            app.LoadButton = uibutton(app.DatamanipulationPanel, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [288 69 73 22];
            app.LoadButton.Text = 'Load';

            % Create SaveselectedvariablesLabel
            app.SaveselectedvariablesLabel = uilabel(app.DatamanipulationPanel);
            app.SaveselectedvariablesLabel.Position = [17 41 132 23];
            app.SaveselectedvariablesLabel.Text = 'Save selected variables';

            % Create ExcludeselectedvariablesLabel
            app.ExcludeselectedvariablesLabel = uilabel(app.DatamanipulationPanel);
            app.ExcludeselectedvariablesLabel.Position = [17 13 148 23];
            app.ExcludeselectedvariablesLabel.Text = 'Exclude selected variables';

            % Create SaveButton
            app.SaveButton = uibutton(app.DatamanipulationPanel, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [288 41 73 23];
            app.SaveButton.Text = 'Save';

            % Create ExcludeButton
            app.ExcludeButton = uibutton(app.DatamanipulationPanel, 'push');
            app.ExcludeButton.ButtonPushedFcn = createCallbackFcn(app, @ExcludeButtonPushed, true);
            app.ExcludeButton.Position = [288 13 73 23];
            app.ExcludeButton.Text = 'Exclude';

            % Create WorkspaceTable
            app.WorkspaceTable = uitable(app.GridLayout2);
            app.WorkspaceTable.ColumnName = {'Name'; 'Type'; 'Values'; 'S.F'; 'State'};
            app.WorkspaceTable.ColumnWidth = {'auto', 50, 'auto', 50, 50};
            app.WorkspaceTable.RowName = {};
            app.WorkspaceTable.ColumnSortable = [true false false false];
            app.WorkspaceTable.ColumnEditable = [false false false false true];
            app.WorkspaceTable.CellEditCallback = createCallbackFcn(app, @WorkspaceTableCellEdit, true);
            app.WorkspaceTable.Layout.Row = 2;
            app.WorkspaceTable.Layout.Column = 1;

            % Create Panel
            app.Panel = uipanel(app.GridLayout2);
            app.Panel.BackgroundColor = [1 1 1];
            app.Panel.Layout.Row = 3;
            app.Panel.Layout.Column = 1;

            % Create StatusTextAreaLabel
            app.StatusTextAreaLabel = uilabel(app.Panel);
            app.StatusTextAreaLabel.Position = [8 52 40 22];
            app.StatusTextAreaLabel.Text = 'Status';

            % Create StatusTextArea
            app.StatusTextArea = uitextarea(app.Panel);
            app.StatusTextArea.Position = [8 10 353 36];
            app.StatusTextArea.Value = {'Inactive'};

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.RightPanel);
            app.GridLayout3.ColumnWidth = {'1x'};
            app.GridLayout3.RowHeight = {240, '1x'};

            % Create PreprocessingstepPanel
            app.PreprocessingstepPanel = uipanel(app.GridLayout3);
            app.PreprocessingstepPanel.TitlePosition = 'centertop';
            app.PreprocessingstepPanel.Title = 'Pre-processing step';
            app.PreprocessingstepPanel.BackgroundColor = [1 1 1];
            app.PreprocessingstepPanel.Layout.Row = 1;
            app.PreprocessingstepPanel.Layout.Column = 1;
            app.PreprocessingstepPanel.FontWeight = 'bold';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.PreprocessingstepPanel);
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);
            app.TabGroup.Position = [0 55 439 166];

            % Create DetailsTab
            app.DetailsTab = uitab(app.TabGroup);
            app.DetailsTab.Title = 'Details';
            app.DetailsTab.Tag = 'details';

            % Create TextArea
            app.TextArea = uitextarea(app.DetailsTab);
            app.TextArea.Position = [15 62 376 68];
            app.TextArea.Value = {'The data is going to be divided in segments (1 hour - default) in order to reduce the computational costs. However, it will increase the time spent during the pre-processing step. This is also valid for the classification algorithm pre-processing step.'};

            % Create DonotsegmentthedataCheckBox
            app.DonotsegmentthedataCheckBox = uicheckbox(app.DetailsTab);
            app.DonotsegmentthedataCheckBox.Text = {' Do not segment'; ' the data'};
            app.DonotsegmentthedataCheckBox.Position = [298 11 110 28];

            % Create SegmentsdurationhEditFieldLabel
            app.SegmentsdurationhEditFieldLabel = uilabel(app.DetailsTab);
            app.SegmentsdurationhEditFieldLabel.HorizontalAlignment = 'center';
            app.SegmentsdurationhEditFieldLabel.Position = [9 12 67 28];
            app.SegmentsdurationhEditFieldLabel.Text = {'Segments'; 'duration (h)'};

            % Create SegmentsdurationhEditField
            app.SegmentsdurationhEditField = uieditfield(app.DetailsTab, 'numeric');
            app.SegmentsdurationhEditField.ValueChangedFcn = createCallbackFcn(app, @SegmentsdurationhEditFieldValueChanged, true);
            app.SegmentsdurationhEditField.HorizontalAlignment = 'center';
            app.SegmentsdurationhEditField.Position = [84 14 31 22];
            app.SegmentsdurationhEditField.Value = 1;

            % Create SegmentsdurationsamplesEditFieldLabel
            app.SegmentsdurationsamplesEditFieldLabel = uilabel(app.DetailsTab);
            app.SegmentsdurationsamplesEditFieldLabel.HorizontalAlignment = 'center';
            app.SegmentsdurationsamplesEditFieldLabel.Position = [123 12 105 28];
            app.SegmentsdurationsamplesEditFieldLabel.Text = {'Segments'; 'duration (samples)'};

            % Create SegmentsdurationsamplesEditField
            app.SegmentsdurationsamplesEditField = uieditfield(app.DetailsTab, 'numeric');
            app.SegmentsdurationsamplesEditField.Editable = 'off';
            app.SegmentsdurationsamplesEditField.HorizontalAlignment = 'center';
            app.SegmentsdurationsamplesEditField.Position = [233 14 51 22];

            % Create DetrendTab
            app.DetrendTab = uitab(app.TabGroup);
            app.DetrendTab.Title = 'Detrend';
            app.DetrendTab.Tag = 'detrend';

            % Create ONCheckBox_detrend
            app.ONCheckBox_detrend = uicheckbox(app.DetrendTab);
            app.ONCheckBox_detrend.ValueChangedFcn = createCallbackFcn(app, @ONCheckBox_detrendValueChanged, true);
            app.ONCheckBox_detrend.Text = 'ON';
            app.ONCheckBox_detrend.Position = [343 5 63 22];
            app.ONCheckBox_detrend.Value = true;

            % Create PolynomialdegreeButtonGroup
            app.PolynomialdegreeButtonGroup = uibuttongroup(app.DetrendTab);
            app.PolynomialdegreeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @PolynomialdegreeButtonGroupSelectionChanged, true);
            app.PolynomialdegreeButtonGroup.Title = 'Polynomial degree:';
            app.PolynomialdegreeButtonGroup.Position = [25 17 282 106];

            % Create ConstantdefaultButton
            app.ConstantdefaultButton = uiradiobutton(app.PolynomialdegreeButtonGroup);
            app.ConstantdefaultButton.Text = 'Constant (default)';
            app.ConstantdefaultButton.Position = [11 53 117 22];
            app.ConstantdefaultButton.Value = true;

            % Create LinearButton
            app.LinearButton = uiradiobutton(app.PolynomialdegreeButtonGroup);
            app.LinearButton.Text = 'Linear';
            app.LinearButton.Position = [11 31 65 22];

            % Create QuadraticButton
            app.QuadraticButton = uiradiobutton(app.PolynomialdegreeButtonGroup);
            app.QuadraticButton.Text = 'Quadratic';
            app.QuadraticButton.Position = [11 9 74 22];

            % Create OtherButton
            app.OtherButton = uiradiobutton(app.PolynomialdegreeButtonGroup);
            app.OtherButton.Text = 'Other';
            app.OtherButton.Position = [161 52 52 22];

            % Create PolynomialDegreeEditField
            app.PolynomialDegreeEditField = uieditfield(app.PolynomialdegreeButtonGroup, 'numeric');
            app.PolynomialDegreeEditField.ValueChangedFcn = createCallbackFcn(app, @PolynomialDegreeEditFieldValueChanged, true);
            app.PolynomialDegreeEditField.Enable = 'off';
            app.PolynomialDegreeEditField.Position = [221 52 44 22];

            % Create ResamplingTab
            app.ResamplingTab = uitab(app.TabGroup);
            app.ResamplingTab.Title = 'Resampling';
            app.ResamplingTab.BackgroundColor = [1 1 1];
            app.ResamplingTab.Tag = 'resampling';

            % Create OutputsamplingfrequencyHzEditFieldLabel
            app.OutputsamplingfrequencyHzEditFieldLabel = uilabel(app.ResamplingTab);
            app.OutputsamplingfrequencyHzEditFieldLabel.HorizontalAlignment = 'right';
            app.OutputsamplingfrequencyHzEditFieldLabel.Position = [28 104 175 22];
            app.OutputsamplingfrequencyHzEditFieldLabel.Text = 'Output sampling frequency (Hz)';

            % Create OutputsamplingfrequencyHzEditField
            app.OutputsamplingfrequencyHzEditField = uieditfield(app.ResamplingTab, 'numeric');
            app.OutputsamplingfrequencyHzEditField.ValueChangedFcn = createCallbackFcn(app, @OutputsamplingfrequencyHzEditFieldValueChanged, true);
            app.OutputsamplingfrequencyHzEditField.Position = [37 78 80 22];
            app.OutputsamplingfrequencyHzEditField.Value = 1000;

            % Create ChangeinputsamplingfrequencyHzEditFieldLabel
            app.ChangeinputsamplingfrequencyHzEditFieldLabel = uilabel(app.ResamplingTab);
            app.ChangeinputsamplingfrequencyHzEditFieldLabel.HorizontalAlignment = 'right';
            app.ChangeinputsamplingfrequencyHzEditFieldLabel.Enable = 'off';
            app.ChangeinputsamplingfrequencyHzEditFieldLabel.Position = [28 42 211 22];
            app.ChangeinputsamplingfrequencyHzEditFieldLabel.Text = 'Change input sampling frequency (Hz)';

            % Create ChangeinputsamplingfrequencyHzEditField
            app.ChangeinputsamplingfrequencyHzEditField = uieditfield(app.ResamplingTab, 'numeric');
            app.ChangeinputsamplingfrequencyHzEditField.ValueChangedFcn = createCallbackFcn(app, @ChangeinputsamplingfrequencyHzEditFieldValueChanged, true);
            app.ChangeinputsamplingfrequencyHzEditField.Enable = 'off';
            app.ChangeinputsamplingfrequencyHzEditField.Position = [37 14 80 22];

            % Create CheckBox_input_sampling_freq_resampling
            app.CheckBox_input_sampling_freq_resampling = uicheckbox(app.ResamplingTab);
            app.CheckBox_input_sampling_freq_resampling.ValueChangedFcn = createCallbackFcn(app, @CheckBox_input_sampling_freq_resamplingValueChanged, true);
            app.CheckBox_input_sampling_freq_resampling.Text = '';
            app.CheckBox_input_sampling_freq_resampling.Position = [12 42 25 22];

            % Create ONCheckBox_resampling
            app.ONCheckBox_resampling = uicheckbox(app.ResamplingTab);
            app.ONCheckBox_resampling.ValueChangedFcn = createCallbackFcn(app, @ONCheckBox_resamplingValueChanged, true);
            app.ONCheckBox_resampling.Text = 'ON';
            app.ONCheckBox_resampling.Position = [343 5 63 22];
            app.ONCheckBox_resampling.Value = true;

            % Create InputOutputfrequencyratioEditFieldLabel
            app.InputOutputfrequencyratioEditFieldLabel = uilabel(app.ResamplingTab);
            app.InputOutputfrequencyratioEditFieldLabel.HorizontalAlignment = 'right';
            app.InputOutputfrequencyratioEditFieldLabel.Position = [237 104 154 22];
            app.InputOutputfrequencyratioEditFieldLabel.Text = 'Input/Output frequency ratio';

            % Create InputOutputfrequencyratioEditField
            app.InputOutputfrequencyratioEditField = uieditfield(app.ResamplingTab, 'numeric');
            app.InputOutputfrequencyratioEditField.Position = [246 78 80 22];

            % Create FilteringTab
            app.FilteringTab = uitab(app.TabGroup);
            app.FilteringTab.Title = 'Filtering';
            app.FilteringTab.BackgroundColor = [1 1 1];
            app.FilteringTab.Tag = 'filtering';

            % Create FiltertypeButtonGroup
            app.FiltertypeButtonGroup = uibuttongroup(app.FilteringTab);
            app.FiltertypeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @FiltertypeButtonGroupSelectionChanged, true);
            app.FiltertypeButtonGroup.Title = 'Filter type';
            app.FiltertypeButtonGroup.Position = [9 35 335 87];

            % Create BandpassButton
            app.BandpassButton = uiradiobutton(app.FiltertypeButtonGroup);
            app.BandpassButton.Tag = 'band';
            app.BandpassButton.Text = 'Band-pass';
            app.BandpassButton.Position = [185 37 79 22];
            app.BandpassButton.Value = true;

            % Create NotchHzButton
            app.NotchHzButton = uiradiobutton(app.FiltertypeButtonGroup);
            app.NotchHzButton.Tag = 'notch';
            app.NotchHzButton.Text = 'Notch (Hz)';
            app.NotchHzButton.Position = [185 7 79 22];

            % Create LowpassEditField
            app.LowpassEditField = uieditfield(app.FiltertypeButtonGroup, 'numeric');
            app.LowpassEditField.Position = [115 7 48 22];
            app.LowpassEditField.Value = 250;

            % Create HighpassEditField
            app.HighpassEditField = uieditfield(app.FiltertypeButtonGroup, 'numeric');
            app.HighpassEditField.Position = [115 37 48 22];
            app.HighpassEditField.Value = 0.7;

            % Create NotchEditField
            app.NotchEditField = uieditfield(app.FiltertypeButtonGroup, 'numeric');
            app.NotchEditField.Enable = 'off';
            app.NotchEditField.Position = [270 7 48 22];

            % Create HighpassHzButton
            app.HighpassHzButton = uiradiobutton(app.FiltertypeButtonGroup);
            app.HighpassHzButton.Tag = 'high';
            app.HighpassHzButton.Text = 'High-pass (Hz)';
            app.HighpassHzButton.Position = [11 37 102 22];

            % Create LowpassHzButton
            app.LowpassHzButton = uiradiobutton(app.FiltertypeButtonGroup);
            app.LowpassHzButton.Tag = 'low';
            app.LowpassHzButton.Text = 'Low-pass (Hz)';
            app.LowpassHzButton.Position = [11 7 99 22];

            % Create ONCheckBox_filtering
            app.ONCheckBox_filtering = uicheckbox(app.FilteringTab);
            app.ONCheckBox_filtering.ValueChangedFcn = createCallbackFcn(app, @ONCheckBox_filteringValueChanged, true);
            app.ONCheckBox_filtering.Text = 'ON';
            app.ONCheckBox_filtering.Position = [343 5 63 22];
            app.ONCheckBox_filtering.Value = true;

            % Create SamplingfrequencyEditFieldLabel
            app.SamplingfrequencyEditFieldLabel = uilabel(app.FilteringTab);
            app.SamplingfrequencyEditFieldLabel.HorizontalAlignment = 'right';
            app.SamplingfrequencyEditFieldLabel.Enable = 'off';
            app.SamplingfrequencyEditFieldLabel.Position = [38 5 112 22];
            app.SamplingfrequencyEditFieldLabel.Text = 'Sampling frequency';

            % Create SamplingfrequencyEditField_filtering
            app.SamplingfrequencyEditField_filtering = uieditfield(app.FilteringTab, 'text');
            app.SamplingfrequencyEditField_filtering.Enable = 'off';
            app.SamplingfrequencyEditField_filtering.Position = [163 5 55 22];
            app.SamplingfrequencyEditField_filtering.Value = 'Default';

            % Create CheckBox_filtering_sampling_frequency
            app.CheckBox_filtering_sampling_frequency = uicheckbox(app.FilteringTab);
            app.CheckBox_filtering_sampling_frequency.ValueChangedFcn = createCallbackFcn(app, @CheckBox_filtering_sampling_frequencyValueChanged, true);
            app.CheckBox_filtering_sampling_frequency.Text = '';
            app.CheckBox_filtering_sampling_frequency.Position = [20 5 25 22];

            % Create PeriodseparationTab
            app.PeriodseparationTab = uitab(app.TabGroup);
            app.PeriodseparationTab.Title = 'Period separation';
            app.PeriodseparationTab.BackgroundColor = [1 1 1];
            app.PeriodseparationTab.Tag = 'period_separation';

            % Create PeriodLengthsecEditFieldLabel
            app.PeriodLengthsecEditFieldLabel = uilabel(app.PeriodseparationTab);
            app.PeriodLengthsecEditFieldLabel.HorizontalAlignment = 'right';
            app.PeriodLengthsecEditFieldLabel.Position = [7 99 110 22];
            app.PeriodLengthsecEditFieldLabel.Text = 'Period Length (sec)';

            % Create PeriodLengthsecEditField
            app.PeriodLengthsecEditField = uieditfield(app.PeriodseparationTab, 'numeric');
            app.PeriodLengthsecEditField.ValueChangedFcn = createCallbackFcn(app, @PeriodLengthsecEditFieldValueChanged, true);
            app.PeriodLengthsecEditField.HorizontalAlignment = 'center';
            app.PeriodLengthsecEditField.Position = [152 99 66 22];
            app.PeriodLengthsecEditField.Value = 10;

            % Create PeriodLengthsamplesEditFieldLabel
            app.PeriodLengthsamplesEditFieldLabel = uilabel(app.PeriodseparationTab);
            app.PeriodLengthsamplesEditFieldLabel.HorizontalAlignment = 'right';
            app.PeriodLengthsamplesEditFieldLabel.Position = [7 70 136 22];
            app.PeriodLengthsamplesEditFieldLabel.Text = 'Period Length (samples)';

            % Create PeriodLengthsamplesEditField
            app.PeriodLengthsamplesEditField = uieditfield(app.PeriodseparationTab, 'numeric');
            app.PeriodLengthsamplesEditField.Editable = 'off';
            app.PeriodLengthsamplesEditField.HorizontalAlignment = 'center';
            app.PeriodLengthsamplesEditField.Position = [152 70 66 22];

            % Create NumberofPeriodsEditFieldLabel
            app.NumberofPeriodsEditFieldLabel = uilabel(app.PeriodseparationTab);
            app.NumberofPeriodsEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofPeriodsEditFieldLabel.Position = [6 41 106 22];
            app.NumberofPeriodsEditFieldLabel.Text = 'Number of Periods';

            % Create NumberofPeriodsEditField
            app.NumberofPeriodsEditField = uieditfield(app.PeriodseparationTab, 'numeric');
            app.NumberofPeriodsEditField.Editable = 'off';
            app.NumberofPeriodsEditField.HorizontalAlignment = 'center';
            app.NumberofPeriodsEditField.Position = [152 41 66 22];

            % Create ONCheckBox_period_separation
            app.ONCheckBox_period_separation = uicheckbox(app.PeriodseparationTab);
            app.ONCheckBox_period_separation.ValueChangedFcn = createCallbackFcn(app, @ONCheckBox_period_separationValueChanged, true);
            app.ONCheckBox_period_separation.Text = 'ON';
            app.ONCheckBox_period_separation.Position = [343 5 63 22];
            app.ONCheckBox_period_separation.Value = true;

            % Create SamplingfrequencyEditField_2Label
            app.SamplingfrequencyEditField_2Label = uilabel(app.PeriodseparationTab);
            app.SamplingfrequencyEditField_2Label.HorizontalAlignment = 'right';
            app.SamplingfrequencyEditField_2Label.Enable = 'off';
            app.SamplingfrequencyEditField_2Label.Position = [279 95 112 22];
            app.SamplingfrequencyEditField_2Label.Text = 'Sampling frequency';

            % Create SamplingfrequencyEditField_period_separation
            app.SamplingfrequencyEditField_period_separation = uieditfield(app.PeriodseparationTab, 'numeric');
            app.SamplingfrequencyEditField_period_separation.ValueChangedFcn = createCallbackFcn(app, @SamplingfrequencyEditField_period_separationValueChanged, true);
            app.SamplingfrequencyEditField_period_separation.Enable = 'off';
            app.SamplingfrequencyEditField_period_separation.Position = [298 69 71 22];

            % Create sampling_frequency_checkbox_period_separation
            app.sampling_frequency_checkbox_period_separation = uicheckbox(app.PeriodseparationTab);
            app.sampling_frequency_checkbox_period_separation.ValueChangedFcn = createCallbackFcn(app, @sampling_frequency_checkbox_period_separationValueChanged, true);
            app.sampling_frequency_checkbox_period_separation.Text = '';
            app.sampling_frequency_checkbox_period_separation.Position = [265 95 25 22];

            % Create NumberofdiscardedsamplesEditFieldLabel
            app.NumberofdiscardedsamplesEditFieldLabel = uilabel(app.PeriodseparationTab);
            app.NumberofdiscardedsamplesEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofdiscardedsamplesEditFieldLabel.Position = [6 13 168 22];
            app.NumberofdiscardedsamplesEditFieldLabel.Text = 'Number of discarded samples:';

            % Create NumberofdiscardedsamplesEditField
            app.NumberofdiscardedsamplesEditField = uieditfield(app.PeriodseparationTab, 'numeric');
            app.NumberofdiscardedsamplesEditField.Position = [179 13 39 22];

            % Create Run_preprocessing_Button
            app.Run_preprocessing_Button = uibutton(app.PreprocessingstepPanel, 'push');
            app.Run_preprocessing_Button.ButtonPushedFcn = createCallbackFcn(app, @Run_preprocessing_ButtonPushed, true);
            app.Run_preprocessing_Button.Position = [292 16 100 22];
            app.Run_preprocessing_Button.Text = 'Run';

            % Create RuntheselectedstepsusingtheselectedvariablesLabel
            app.RuntheselectedstepsusingtheselectedvariablesLabel = uilabel(app.PreprocessingstepPanel);
            app.RuntheselectedstepsusingtheselectedvariablesLabel.Position = [15 16 233 29];
            app.RuntheselectedstepsusingtheselectedvariablesLabel.Text = {'Run the selected steps using the selected '; 'variables'};

            % Create SleepwakecyclesortingPanel
            app.SleepwakecyclesortingPanel = uipanel(app.GridLayout3);
            app.SleepwakecyclesortingPanel.TitlePosition = 'centertop';
            app.SleepwakecyclesortingPanel.Title = 'Sleep-wake cycle sorting';
            app.SleepwakecyclesortingPanel.BackgroundColor = [1 1 1];
            app.SleepwakecyclesortingPanel.Layout.Row = 2;
            app.SleepwakecyclesortingPanel.Layout.Column = 1;
            app.SleepwakecyclesortingPanel.FontWeight = 'bold';

            % Create SleepWakeAlgorithmButtonGroup
            app.SleepWakeAlgorithmButtonGroup = uibuttongroup(app.SleepwakecyclesortingPanel);
            app.SleepWakeAlgorithmButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @SleepWakeAlgorithmButtonGroupSelectionChanged, true);
            app.SleepWakeAlgorithmButtonGroup.BackgroundColor = [1 1 1];
            app.SleepWakeAlgorithmButtonGroup.Position = [7 8 426 329];

            % Create LoadpreprocessedvariablesButton_2
            app.LoadpreprocessedvariablesButton_2 = uiradiobutton(app.SleepWakeAlgorithmButtonGroup);
            app.LoadpreprocessedvariablesButton_2.Tag = 'load_file';
            app.LoadpreprocessedvariablesButton_2.Text = {''; '2 - Load pre-processed'; '     variables'};
            app.LoadpreprocessedvariablesButton_2.Position = [266 265 146 42];

            % Create RunButton_classification_algorithm
            app.RunButton_classification_algorithm = uibutton(app.SleepWakeAlgorithmButtonGroup, 'push');
            app.RunButton_classification_algorithm.ButtonPushedFcn = createCallbackFcn(app, @RunButton_classification_algorithmPushed, true);
            app.RunButton_classification_algorithm.Position = [367 8 50 34];
            app.RunButton_classification_algorithm.Text = 'Run';

            % Create PowerLineNoiseHzLabel
            app.PowerLineNoiseHzLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.PowerLineNoiseHzLabel.Position = [188 41 126 29];
            app.PowerLineNoiseHzLabel.Text = 'Power Line Noise (Hz)';

            % Create PowerLineNoiseHzEditField
            app.PowerLineNoiseHzEditField = uieditfield(app.SleepWakeAlgorithmButtonGroup, 'numeric');
            app.PowerLineNoiseHzEditField.Position = [321 44 31 22];
            app.PowerLineNoiseHzEditField.Value = 60;

            % Create OutputSamplingFrequencyLabel
            app.OutputSamplingFrequencyLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.OutputSamplingFrequencyLabel.HorizontalAlignment = 'right';
            app.OutputSamplingFrequencyLabel.Position = [11 4 156 29];
            app.OutputSamplingFrequencyLabel.Text = 'Output Sampling Frequency';

            % Create OutputSamplingFrequencyDropDown
            app.OutputSamplingFrequencyDropDown = uidropdown(app.SleepWakeAlgorithmButtonGroup);
            app.OutputSamplingFrequencyDropDown.Items = {'Default', '1000 Hz', '500 Hz'};
            app.OutputSamplingFrequencyDropDown.ValueChangedFcn = createCallbackFcn(app, @OutputSamplingFrequencyDropDownValueChanged, true);
            app.OutputSamplingFrequencyDropDown.Position = [182 9 87 22];
            app.OutputSamplingFrequencyDropDown.Value = 'Default';

            % Create Selectthedata_variablematfileLabel
            app.Selectthedata_variablematfileLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.Selectthedata_variablematfileLabel.Position = [259 208 162 42];
            app.Selectthedata_variablematfileLabel.Text = {'Select the ''data_variable.mat'''; 'file previously generated by'; 'the software'};

            % Create ststepSelectiononeoftheoptionsbellow1or2Label
            app.ststepSelectiononeoftheoptionsbellow1or2Label = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.ststepSelectiononeoftheoptionsbellow1or2Label.HorizontalAlignment = 'center';
            app.ststepSelectiononeoftheoptionsbellow1or2Label.FontWeight = 'bold';
            app.ststepSelectiononeoftheoptionsbellow1or2Label.Position = [73 301 307 22];
            app.ststepSelectiononeoftheoptionsbellow1or2Label.Text = '1st step: Selection one of the options bellow (1 or 2)';

            % Create ndstepChangetheparametersbellowandpressRunLabel
            app.ndstepChangetheparametersbellowandpressRunLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.ndstepChangetheparametersbellowandpressRunLabel.FontWeight = 'bold';
            app.ndstepChangetheparametersbellowandpressRunLabel.Position = [60 76 334 22];
            app.ndstepChangetheparametersbellowandpressRunLabel.Text = '2nd step: Change the parameters bellow and press ''Run''';

            % Create EpochLengthsecLabel
            app.EpochLengthsecLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.EpochLengthsecLabel.Position = [18 41 110 29];
            app.EpochLengthsecLabel.Text = 'Epoch Length (sec)';

            % Create EpochLengthEditField
            app.EpochLengthEditField = uieditfield(app.SleepWakeAlgorithmButtonGroup, 'numeric');
            app.EpochLengthEditField.ValueChangedFcn = createCallbackFcn(app, @EpochLengthEditFieldValueChanged, true);
            app.EpochLengthEditField.Position = [132 44 31 22];
            app.EpochLengthEditField.Value = 10;

            % Create UseworkpacedataButton
            app.UseworkpacedataButton = uiradiobutton(app.SleepWakeAlgorithmButtonGroup);
            app.UseworkpacedataButton.Tag = 'workspace';
            app.UseworkpacedataButton.Text = '1 - Use workpace data';
            app.UseworkpacedataButton.Position = [21 275 142 22];
            app.UseworkpacedataButton.Value = true;

            % Create CA1ChannelDropDownLabel
            app.CA1ChannelDropDownLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.CA1ChannelDropDownLabel.HorizontalAlignment = 'right';
            app.CA1ChannelDropDownLabel.Position = [41 248 77 22];
            app.CA1ChannelDropDownLabel.Text = 'CA1 Channel';

            % Create CA1ChannelDropDown
            app.CA1ChannelDropDown = uidropdown(app.SleepWakeAlgorithmButtonGroup);
            app.CA1ChannelDropDown.Items = {};
            app.CA1ChannelDropDown.ValueChangedFcn = createCallbackFcn(app, @CA1ChannelDropDownValueChanged, true);
            app.CA1ChannelDropDown.Position = [142 248 69 22];
            app.CA1ChannelDropDown.Value = {};

            % Create EMGAccelChannelDropDown
            app.EMGAccelChannelDropDown = uidropdown(app.SleepWakeAlgorithmButtonGroup);
            app.EMGAccelChannelDropDown.Items = {};
            app.EMGAccelChannelDropDown.ValueChangedFcn = createCallbackFcn(app, @EMGAccelChannelDropDownValueChanged, true);
            app.EMGAccelChannelDropDown.Position = [142 208 70 22];
            app.EMGAccelChannelDropDown.Value = {};

            % Create EMG_Accel_ButtonGroup
            app.EMG_Accel_ButtonGroup = uibuttongroup(app.SleepWakeAlgorithmButtonGroup);
            app.EMG_Accel_ButtonGroup.AutoResizeChildren = 'off';
            app.EMG_Accel_ButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @EMG_Accel_ButtonGroupSelectionChanged, true);
            app.EMG_Accel_ButtonGroup.BackgroundColor = [1 1 1];
            app.EMG_Accel_ButtonGroup.Position = [18 176 110 73];

            % Create EMGChannelButton
            app.EMGChannelButton = uiradiobutton(app.EMG_Accel_ButtonGroup);
            app.EMGChannelButton.Tag = 'EMG';
            app.EMGChannelButton.Text = 'EMG Channel';
            app.EMGChannelButton.Position = [11 45 97 22];
            app.EMGChannelButton.Value = true;

            % Create Accel1ChButton
            app.Accel1ChButton = uiradiobutton(app.EMG_Accel_ButtonGroup);
            app.Accel1ChButton.Tag = 'Accel1';
            app.Accel1ChButton.Text = 'Accel (1 Ch)';
            app.Accel1ChButton.Position = [11 23 88 22];

            % Create Accel3ChButton
            app.Accel3ChButton = uiradiobutton(app.EMG_Accel_ButtonGroup);
            app.Accel3ChButton.Tag = 'Accel3';
            app.Accel3ChButton.Text = 'Accel (3 Ch)';
            app.Accel3ChButton.Position = [11 2 88 22];

            % Create AccelXDropDown
            app.AccelXDropDown = uidropdown(app.SleepWakeAlgorithmButtonGroup);
            app.AccelXDropDown.Items = {};
            app.AccelXDropDown.Enable = 'off';
            app.AccelXDropDown.Position = [31 143 49 22];
            app.AccelXDropDown.Value = {};

            % Create AccelYDropDown
            app.AccelYDropDown = uidropdown(app.SleepWakeAlgorithmButtonGroup);
            app.AccelYDropDown.Items = {};
            app.AccelYDropDown.Enable = 'off';
            app.AccelYDropDown.Position = [102 143 49 22];
            app.AccelYDropDown.Value = {};

            % Create AccelZDropDown
            app.AccelZDropDown = uidropdown(app.SleepWakeAlgorithmButtonGroup);
            app.AccelZDropDown.Items = {};
            app.AccelZDropDown.Enable = 'off';
            app.AccelZDropDown.Position = [177 143 50 22];
            app.AccelZDropDown.Value = {};

            % Create IncludethealgorithmpreprocessingstepCheckBox
            app.IncludethealgorithmpreprocessingstepCheckBox = uicheckbox(app.SleepWakeAlgorithmButtonGroup);
            app.IncludethealgorithmpreprocessingstepCheckBox.ValueChangedFcn = createCallbackFcn(app, @IncludethealgorithmpreprocessingstepCheckBoxValueChanged, true);
            app.IncludethealgorithmpreprocessingstepCheckBox.Text = '  Include the algorithm pre-processing step';
            app.IncludethealgorithmpreprocessingstepCheckBox.Position = [21 105 251 29];
            app.IncludethealgorithmpreprocessingstepCheckBox.Value = true;

            % Create XLabel
            app.XLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.XLabel.Enable = 'off';
            app.XLabel.Position = [17 143 10 22];
            app.XLabel.Text = 'X';

            % Create YLabel
            app.YLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.YLabel.Enable = 'off';
            app.YLabel.Position = [88 143 25 22];
            app.YLabel.Text = 'Y';

            % Create ZLabel
            app.ZLabel = uilabel(app.SleepWakeAlgorithmButtonGroup);
            app.ZLabel.Enable = 'off';
            app.ZLabel.Position = [162 143 25 22];
            app.ZLabel.Text = 'Z';

            % Create PostClassificationAnalysisMenu
            app.PostClassificationAnalysisMenu = uimenu(app.SleepwakecycleclassificationsoftwareUIFigure);
            app.PostClassificationAnalysisMenu.Text = 'Post Classification Analysis';

            % Create SleepwakecyclearchitectureMenu
            app.SleepwakecyclearchitectureMenu = uimenu(app.PostClassificationAnalysisMenu);
            app.SleepwakecyclearchitectureMenu.MenuSelectedFcn = createCallbackFcn(app, @SleepwakecyclearchitectureMenuSelected, true);
            app.SleepwakecyclearchitectureMenu.Text = 'Sleep-wake cycle architecture';

            % Show the figure after all components are created
            app.SleepwakecycleclassificationsoftwareUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RMS_pwelch_integrate

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.SleepwakecycleclassificationsoftwareUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.SleepwakecycleclassificationsoftwareUIFigure)
        end
    end
end