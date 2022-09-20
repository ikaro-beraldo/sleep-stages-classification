classdef load_variables < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        LoadVarInterfaceUIFigure      matlab.ui.Figure
        DataSelectionTable            matlab.ui.control.Table
        SelectedFileLabel             matlab.ui.control.Label
        FilePathLabel                 matlab.ui.control.Label
        CheckthevariableswhichshouldbeloadedLabel  matlab.ui.control.Label
        SelectedPathway               matlab.ui.control.Label
        LoadButton                    matlab.ui.control.Button
        SamplingFrequencyButtonGroup  matlab.ui.container.ButtonGroup
        VariablesButton               matlab.ui.control.RadioButton
        ManualButton                  matlab.ui.control.RadioButton
        NoneButton                    matlab.ui.control.RadioButton
        SamplingFrequencyDropDown     matlab.ui.control.DropDown
        SamplingFrequencyEditField    matlab.ui.control.NumericEditField
        CancelButton                  matlab.ui.control.Button
        ChangeLoadStateCheckBox       matlab.ui.control.CheckBox
        ChangeSamplingFrequencyCheckBox  matlab.ui.control.CheckBox
        LoadingLabel                  matlab.ui.control.Label
    end

    
    properties (Access = private)
        CallingApp %main app object; important to exchange data between apps
        FilePathway % imported main app mfile pathway 
        DataStructSelection % This is a structure that permits data manipulation and proper comparisons
        DataExportationStruct % Data which is going to be exported to the main app (contains the variable infos and data)
    end
    
    methods (Access = private)
        
        % Updates the selected file pathway 
        function update_selected_filepathway(app) % Needs only the 'self' input
            % Change the app.SelectedPathway (text label) accordingly to
            % the file pathway imported from the main app
            app.SelectedPathway.Text = app.FilePathway;            
        end
        
        % Updates the DataSelectionTable with the infos from the selected
        % mfile
        function update_varselection_table(app,mfile_infos)
            
            % Initialize a struct to store specific informations, such as
            % name, size, class, load_state
            data_selection_struct = struct('name',[],'size',[],'class',[],'load_state',[],'sampling_frequency_state',[],'sampling_frequency',[],'current_state',[]);
            
            % Loop to extract the info from each one of the variables
            for loop_count = 1:size(mfile_infos,1) % 1 : number of rows of this struct
                % Transfer only the important informations about the mfile
                %varibles
                data_selection_struct(loop_count).name = mfile_infos(loop_count).name;  % Var name
                % Check the size (sometimes, a variable can have an empty
                % [] size)
                if isempty(mfile_infos(loop_count).size)  % Empty
                    data_selection_struct(loop_count).size = mfile_infos(loop_count).size;  % Var dimensions
                else % non-empty
                    data_selection_struct(loop_count).size = sprintf('%dx%d',mfile_infos(loop_count).size(1),mfile_infos(loop_count).size(2));  % Var dimensions
                end
                data_selection_struct(loop_count).class = mfile_infos(loop_count).class;   % Var class
                data_selection_struct(loop_count).load_state = true;   % Define if this data will be loaded (true) or not (false); the default value is true
                % Checks if the variable is a vector or matrix which
                % probably has an associated sampling frequency
                data_selection_struct(loop_count).sampling_frequency_state = check_if_it_has_sampling_frequency(app,mfile_infos(loop_count).size);
                % Automatically insert the current state as true to be used
                % in the main application
                data_selection_struct(loop_count).current_state = true;
            end
            
            % Check if the file has only 1 variable
            if size(mfile_infos,1) == 1 % Creates a table as an array
                % Transfers the mfile information to the GUI table
                % (DataSelectionTable)
                app.DataSelectionTable.Data = struct2table(data_selection_struct,'AsArray',true);
            else    % Creates a standard table
                app.DataSelectionTable.Data = struct2table(data_selection_struct);
            end
            
            % Creates a property with the values within a structure (this step
            % is important since values inside a table class cannot be so
            % easily manipulated or used to conduct comparisons)
            app.DataStructSelection = data_selection_struct;     
            
            % Update the SamplingRateDropDown list with the variables
            update_var_names_drop_down(app)
        end
        
        % Get the mfile infos using the MatLab function 'whos'
        function mfile_infos = get_mfile_info(app)
            % Returns the mfile informations to be used by the
            % update_varselection table (struct)
            mfile_infos = whos('-file', app.FilePathway);  
            
            % If the file is empty stops the loading process and show an
            % alert
            if numel(mfile_infos) == 0  % If numel(struct) == 0, it means it is empty
                
                mfile_infos = false;    % Answer to finish the loading process                        
            end
        end
        
        % Function used to update the DataSelectionTable after quick
        % changes on it
        function quick_update_varselection_table(app)
            % Get the values from the DataCellSelection (easily manipulated
            % and just insert them in the GUI table
            app.DataSelectionTable.Data = struct2table(app.DataStructSelection);
        end
        
        % This function initialize the variables into the
        % SamplingRateDropDown list and automatically chooses a variable
        % which name is related to standard names
        function update_var_names_drop_down(app)
            variableNames = {app.DataStructSelection.name}; % Converts the the struct to a cell in order to extract only the name of the vars
            app.SamplingFrequencyDropDown.Items = variableNames; % Insert the variables name into the drop down list
            
            % Automatically chooses a variable which name is related to standard names
            % Standard names library for variables containing the sampling
            % frequency
            standard_names = {'sampling_rate','samplingrate','srate','s_rate'...
                ,'sampler','sample_r','sampling_r','samplingr','sr','s_r','fs','f_s',...
                'frequency_sampling','frequency_sample','frequencysampling','frequencysample'...
                ,'samplingfrequency','sampling_frequency','sample_frequency','samplefrequency',...
                'sfrequency','s_frequency','samplef','sample_f','sampling_f','samplingf'};
            % This function compares the two group of strings and provides
            % the similar ones. The FIRST similar name will be used as the
            % sampling frequency variable
            [selected_index, ~] = CStrAinBP(variableNames, standard_names, 'i'); % The 'i' value indicates that this fuction is not case sensitive
            
            % Make sure that a variable is going to be selected only if a
            % index has been selected
            if isempty(selected_index)
                % Do nothing!
            else % Change the Value according to the selected variable
                % Change the DropDown value to the selected one
                app.SamplingFrequencyDropDown.Value = app.DataStructSelection(selected_index).name;
            end
            
        end
        
        % Function that loads the variables and send them to the main app
        function load_send_to_main_app(app,selected_variables_idx)
            % Gets the variable names according to the selected indices
            selected_variables_names_cell = {app.DataStructSelection(selected_variables_idx).name};
            
            % Loads (finally!) the variables data inside a structure
            % load('pathway','names of the variables') --> the {:} indexing
            % was used to extract the variable names from the cell
            variable_values = load(app.FilePathway,selected_variables_names_cell{:});
            
            % Gets only the selected variables infos and insert it into the
            % exportation struct (app.DataExportationStruct)
            app.DataExportationStruct = app.DataStructSelection(selected_variables_idx);
            
            % Loop which gets each data at a time (n = length of the
            % selected_variables_names_cell)
            for loop_count = 1:length(selected_variables_names_cell)
                s_field = selected_variables_names_cell{loop_count};    % string containing the variable names as field names (changes according to the iteration)
                                
                % Gets the variable data and insert it into the
                % DataExportationStruct (field 'data')
                app.DataExportationStruct(loop_count).data = variable_values.(s_field);
            end
            
            % Sends the DataStructSelection to the main app;
            % This structure has the main informations about the loaded
            % variables
            get_data_from_load_variables(app.CallingApp,app.DataExportationStruct)
            
            % Change the label to 'Loading...' to inform that the process
            % is still ocurring when the Load button is pressed
            app.LoadingLabel.Text = 'Finished!';
            
            % Close the dialog app when the selected variables are selected
            delete(app)
        end
        
        % Function that checks if the variable is eligible to have an
        % associated sampling frequency
        function sampling_frequency_state = check_if_it_has_sampling_frequency(app,mfile_info_variable_size)
            % Check if its size is empty
            if isempty(mfile_info_variable_size)
                sampling_frequency_state = false;
            else
                % Check if the variable dimensions are different from a scalar
                % variable
                if mfile_info_variable_size(1)*mfile_info_variable_size(2) > 1 %If it is not a scalar
                    % Change the sampling frequency state to true; As a
                    % consequence, the sampling frequency will be associated to
                    % this specific variable
                    sampling_frequency_state = true;
                else %If the variable is a scalar, the sampling_frequency_state will not be associated
                    sampling_frequency_state = false;
                end %if
            end
            
        end %function check_if_it_has_sampling_frequency
        
    end %methods (Functions)
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, main_app, mfile_pathway)
            % Get the string regarding the selected m-file pathway
            % app: self
            % main_app: the main app object
            % mfile_pathway: string containing the file pathway
            app.CallingApp = main_app; % get the main app object as a property to be used inside the current app
            app.FilePathway = mfile_pathway; % get the mfile pathway as a property to be used inside the current app
            
            %% Secondary functions
            update_selected_filepathway(app) % function to update the text label
            %get_mfile_info: funtion to get the mfile informations about the vars
            mfile_info = get_mfile_info(app);
            
            % Check if the selected file is empty (== false)
            if numel(mfile_info) ~= 0
                update_varselection_table(app,mfile_info)% function to update the variable selection table (DataSelectionTable)
            else
                delete(app) % Delete the app after it has finished its function       
                % The loading process will be finished!
                
                % Creates a warning in the main app
                fig_dlg = main_app.SleepwakecycleclassificationsoftwareUIFigure; % Handle of the figure (it's the main_app figurer itself)
                msg = 'The file is empty. The loading process was finished.';   % Message that will apper on the new dialog box
                title = 'File is empty'; % Title
                uiconfirm(fig_dlg,msg,title,'Options',{'Ok'}); % Confirmation box
                % Wait until 'ok' button is pressed
            end
            
%              exportapp(app.LoadVarInterfaceUIFigure,'load_variables.pdf')


        end

        % Cell edit callback: DataSelectionTable
        function DataSelectionTableCellEdit(app, event)
             % Get the changed indices
            indices = event.Indices;
            row = indices(1); % Get the index of the row that has been changed
            column = indices(2); % Get the index of the column that has been changed
           
            % Only the 'Load State' and 'Sampling Frequency' columns can be changed 
            % If 'Load State' is true, the variable will be loaded
            % If 'Sampling Frequency' is true, the variable will be
            % associated to a sampling frequency value
            % True = allowed; False = not allowed;
            
            %% LOAD STATE
            % Check if only the the 'Load State' column was changed            
            if column == find(strcmp('Load State',app.DataSelectionTable.ColumnName) == true)% Get the index regarding the 'load' column (column 4)
                % indices(1) is row index that is going to be changed
                % Changes the logical value within the cell (easily
                % manipulated)
                app.DataStructSelection(row).load_state = ~app.DataStructSelection(row).load_state; %NOT --> change true to false, and the other way around
            end
            
            %% SAMPLING FREQUENCY
            % Check if only the the 'Sampling Frequency' column was changed            
            if column == find(strcmp('Sampling Frequency',app.DataSelectionTable.ColumnName) == true)% Get the index regarding the 'load' column (column 4)
                % indices(1) is row index that is going to be changed
                % Changes the logical value within the cell (easily
                % manipulated)
                app.DataStructSelection(row).sampling_frequency_state = ~app.DataStructSelection(row).sampling_frequency_state; %NOT --> change true to false, and the other way around
            end
            
             % Update the GUI table (DataSelectionTable) accordingly to
             % new changes: either 'Load State' or 'Sampling Frequency'
             quick_update_varselection_table(app)
            
        end

        % Value changed function: ChangeLoadStateCheckBox
        function ChangeLoadStateCheckBoxValueChanged(app, event)
            % This function causes all the Load State check boxes to be checked
            % or unchecked at once
            value = app.ChangeLoadStateCheckBox.Value; %Gets the value inside the box
            
            % condicional to verify if the new value is true or false
            switch value
                case true %if it is true
                    [app.DataStructSelection.load_state] = deal(true); % Change the check box value to 'true'
                    app.ChangeLoadStateCheckBox.Text = 'All';           % Change the check box associated text
                case false %if it is false
                    [app.DataStructSelection.load_state] = deal(false); % Change the check box value to 'false'
                    app.ChangeLoadStateCheckBox.Text = 'None';           % Change the check box associated text
            end
            
             % Update the GUI table (DataSelectionTable) accordingly to
             % new changes
             quick_update_varselection_table(app)
            
        end

        % Value changed function: SamplingFrequencyEditField
        function SamplingFrequencyEditFieldValueChanged(app, event)
            % This function will automatically change the 'manual' radio
            % button to true if the box value is changed
            app.ManualButton.Value = true;
            
        end

        % Value changed function: SamplingFrequencyDropDown
        function SamplingFrequencyDropDownValueChanged(app, event)
            % This function will automatically change the 'variables' radio
            % button to true if the drop down list value is changed
            app.VariablesButton.Value = true;
            
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            % Function is active after the 'Load' button pressed
            
            % Change the label to 'Loading...' to inform that the process
            % is still ocurring when the Load button is pressed
            app.LoadingLabel.Text = 'Loading...';
            drawnow()  % Force MatLab to update
            
            % Check the variables that will receive the associated
            % sampling frequency
            checked_sf_logical = [app.DataStructSelection.sampling_frequency_state];

            % If the 'VariablesButton' is true, make sure that selected
            % variable will be loaded
            if app.VariablesButton.Value == true  % Check if it is true
                selected_var_name = app.SamplingFrequencyDropDown.Value;  % Get the selected var name from the drop box
                selected_index = find(contains({app.DataStructSelection.name},selected_var_name));  % Find the index corresponding to the name of the selected var
                app.DataStructSelection(selected_index).load_state = true;  % Change the load_state of this specific index to true
                
                % Quickly loads the sampling rate variable and transfers
                % its value to the field 'sampling_frequency' of the other
                % variables
                % sampling_rate_value is a structure containing only the
                % variable related to the sampling frequency
                sampling_rate_value = load(app.FilePathway,app.SamplingFrequencyDropDown.Value); %app.SamplingFrequencyDropDown.Value is a string containing the sampling frequency variable name
                % Associate a sampling frequency to the variables;
                % The function 'deal' makes sure that a unique value is going
                % to be distributed to more than one index of the struct
                [app.DataStructSelection(checked_sf_logical).sampling_frequency] = deal(sampling_rate_value.(app.SamplingFrequencyDropDown.Value));
            end
            
            % If the 'ManualButton' is true, make sure that selected value
            % will be used as the sampling frequency
            if app.ManualButton.Value == true  % Check if it is true
                                
                % Associate a sampling frequency to the variables (the
                % value inside the SamplingFrequencyEditField box
                [app.DataStructSelection(checked_sf_logical).sampling_frequency] = deal(app.SamplingFrequencyEditField.Value);
            end
            
            % Insert the value False on the sampling frequency parameter of
            % those variables which were not checked
            [app.DataStructSelection(~checked_sf_logical).sampling_frequency] = deal(false);
            
            % Get the variables that will be loaded
            % First transform the struct into a cell and than into a matrix.
            % After that, gets the indices of the selected variables
            selected_variables_idx = find(cell2mat({app.DataStructSelection.load_state}) == 1); 
            
            %Load and send the variables to the main app
            load_send_to_main_app(app,selected_variables_idx)
            
        end

        % Value changed function: ChangeSamplingFrequencyCheckBox
        function ChangeSamplingFrequencyCheckBoxValueChanged(app, event)
             % This function causes all the Sampling Frequency check boxes to be checked
            % or unchecked at once
            value = app.ChangeSamplingFrequencyCheckBox.Value; %Gets the value inside the box
            
            % condicional to verify if the new value is true or false
            switch value
                case true %if it is true
                    [app.DataStructSelection.sampling_frequency_state] = deal(true); % Change the check box value to 'true'
                    app.ChangeSamplingFrequencyCheckBox.Text = 'All';           % Change the check box associated text
                case false %if it is false
                    [app.DataStructSelection.sampling_frequency_state] = deal(false); % Change the check box value to 'false'
                    app.ChangeSamplingFrequencyCheckBox.Text = 'None';           % Change the check box associated text
            end
            
             % Update the GUI table (DataSelectionTable) accordingly to
             % new changes
             quick_update_varselection_table(app)
            
        end

        % Close request function: LoadVarInterfaceUIFigure
        function LoadVarInterfaceUIFigureCloseRequest(app, event)
%             delete(app)
            fig_dlg = app.LoadVarInterfaceUIFigure; % Handle of the figure (it's the app figurer itself)
            msg = 'The variables will not be loaded. Close the window ?';   % Message that will apper on the new dialog box
            title = 'Close the window'; % Title
            selection = uiconfirm(fig_dlg,msg,title,...
           'Options',{'Yes','No','Cancel'},...
           'DefaultOption',2,'CancelOption',3); % Create the dialog box with the question to either close or not the window
       switch selection
           case 'Yes'
               delete(app) % Delete the app after it has finished its functions
           case 'No' % Do not do anything (keeps the app window as it is)
           case 'Cancel' % Do not do anything (keeps the app window as it is)
       end
            
        end

        % Button pushed function: CancelButton
        function CancelButtonPushed(app, event)
            delete(app) % Delete the app after it has finished its functions
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create LoadVarInterfaceUIFigure and hide until all components are created
            app.LoadVarInterfaceUIFigure = uifigure('Visible', 'off');
            app.LoadVarInterfaceUIFigure.Position = [100 100 595 510];
            app.LoadVarInterfaceUIFigure.Name = 'LoadVarInterface';
            app.LoadVarInterfaceUIFigure.CloseRequestFcn = createCallbackFcn(app, @LoadVarInterfaceUIFigureCloseRequest, true);
            app.LoadVarInterfaceUIFigure.Tag = 'LoadVarInterface';

            % Create DataSelectionTable
            app.DataSelectionTable = uitable(app.LoadVarInterfaceUIFigure);
            app.DataSelectionTable.ColumnName = {'Name'; 'Size'; 'Class'; 'Load State'; 'Sampling Frequency'};
            app.DataSelectionTable.ColumnWidth = {125, 80, 50, 130, 180};
            app.DataSelectionTable.RowName = {};
            app.DataSelectionTable.ColumnEditable = [false false false true true];
            app.DataSelectionTable.CellEditCallback = createCallbackFcn(app, @DataSelectionTableCellEdit, true);
            app.DataSelectionTable.Position = [18 149 563 311];

            % Create SelectedFileLabel
            app.SelectedFileLabel = uilabel(app.LoadVarInterfaceUIFigure);
            app.SelectedFileLabel.Position = [18 121 82 22];
            app.SelectedFileLabel.Text = 'Selected File: ';

            % Create FilePathLabel
            app.FilePathLabel = uilabel(app.LoadVarInterfaceUIFigure);
            app.FilePathLabel.Position = [106 425 25 22];
            app.FilePathLabel.Text = ' ';

            % Create CheckthevariableswhichshouldbeloadedLabel
            app.CheckthevariableswhichshouldbeloadedLabel = uilabel(app.LoadVarInterfaceUIFigure);
            app.CheckthevariableswhichshouldbeloadedLabel.Position = [18 463 248 32];
            app.CheckthevariableswhichshouldbeloadedLabel.Text = 'Check the variables which should be loaded:';

            % Create SelectedPathway
            app.SelectedPathway = uilabel(app.LoadVarInterfaceUIFigure);
            app.SelectedPathway.Position = [99 121 460 22];
            app.SelectedPathway.Text = '';

            % Create LoadButton
            app.LoadButton = uibutton(app.LoadVarInterfaceUIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [185 12 100 22];
            app.LoadButton.Text = 'Load';

            % Create SamplingFrequencyButtonGroup
            app.SamplingFrequencyButtonGroup = uibuttongroup(app.LoadVarInterfaceUIFigure);
            app.SamplingFrequencyButtonGroup.BorderType = 'none';
            app.SamplingFrequencyButtonGroup.TitlePosition = 'centertop';
            app.SamplingFrequencyButtonGroup.Title = 'Sampling Frequency';
            app.SamplingFrequencyButtonGroup.Position = [18 54 563 59];

            % Create VariablesButton
            app.VariablesButton = uiradiobutton(app.SamplingFrequencyButtonGroup);
            app.VariablesButton.Text = 'Variables';
            app.VariablesButton.Position = [26 12 71 22];
            app.VariablesButton.Value = true;

            % Create ManualButton
            app.ManualButton = uiradiobutton(app.SamplingFrequencyButtonGroup);
            app.ManualButton.Text = 'Manual';
            app.ManualButton.Position = [280 12 65 22];

            % Create NoneButton
            app.NoneButton = uiradiobutton(app.SamplingFrequencyButtonGroup);
            app.NoneButton.Text = 'None';
            app.NoneButton.Position = [479 13 65 22];

            % Create SamplingFrequencyDropDown
            app.SamplingFrequencyDropDown = uidropdown(app.SamplingFrequencyButtonGroup);
            app.SamplingFrequencyDropDown.Items = {'', ''};
            app.SamplingFrequencyDropDown.ValueChangedFcn = createCallbackFcn(app, @SamplingFrequencyDropDownValueChanged, true);
            app.SamplingFrequencyDropDown.Position = [97 12 156 22];
            app.SamplingFrequencyDropDown.Value = '';

            % Create SamplingFrequencyEditField
            app.SamplingFrequencyEditField = uieditfield(app.SamplingFrequencyButtonGroup, 'numeric');
            app.SamplingFrequencyEditField.ValueChangedFcn = createCallbackFcn(app, @SamplingFrequencyEditFieldValueChanged, true);
            app.SamplingFrequencyEditField.Position = [344 12 102 22];

            % Create CancelButton
            app.CancelButton = uibutton(app.LoadVarInterfaceUIFigure, 'push');
            app.CancelButton.ButtonPushedFcn = createCallbackFcn(app, @CancelButtonPushed, true);
            app.CancelButton.BusyAction = 'cancel';
            app.CancelButton.Position = [316 12 100 22];
            app.CancelButton.Text = 'Cancel';

            % Create ChangeLoadStateCheckBox
            app.ChangeLoadStateCheckBox = uicheckbox(app.LoadVarInterfaceUIFigure);
            app.ChangeLoadStateCheckBox.ValueChangedFcn = createCallbackFcn(app, @ChangeLoadStateCheckBoxValueChanged, true);
            app.ChangeLoadStateCheckBox.Text = 'All';
            app.ChangeLoadStateCheckBox.Position = [356 435 38 22];
            app.ChangeLoadStateCheckBox.Value = true;

            % Create ChangeSamplingFrequencyCheckBox
            app.ChangeSamplingFrequencyCheckBox = uicheckbox(app.LoadVarInterfaceUIFigure);
            app.ChangeSamplingFrequencyCheckBox.ValueChangedFcn = createCallbackFcn(app, @ChangeSamplingFrequencyCheckBoxValueChanged, true);
            app.ChangeSamplingFrequencyCheckBox.Text = 'All';
            app.ChangeSamplingFrequencyCheckBox.Position = [538 435 34 22];
            app.ChangeSamplingFrequencyCheckBox.Value = true;

            % Create LoadingLabel
            app.LoadingLabel = uilabel(app.LoadVarInterfaceUIFigure);
            app.LoadingLabel.Position = [19 12 112 22];
            app.LoadingLabel.Text = '';

            % Show the figure after all components are created
            app.LoadVarInterfaceUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = load_variables(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.LoadVarInterfaceUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.LoadVarInterfaceUIFigure)
        end
    end
end
