classdef recording_parameters < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        OKButton                       matlab.ui.control.Button
        RecordingParametersPanel       matlab.ui.container.Panel
        NoiseRangeHzLabel              matlab.ui.control.Label
        RecordingTimeHoursLabel        matlab.ui.control.Label
        AnimalGroupDropDownLabel       matlab.ui.control.Label
        AnimalGroupDropDown            matlab.ui.control.DropDown
        InferiorEditFieldLabel         matlab.ui.control.Label
        InferiorEditField              matlab.ui.control.NumericEditField
        SuperiorEditFieldLabel         matlab.ui.control.Label
        SuperiorEditField              matlab.ui.control.NumericEditField
        BeginningEditFieldLabel        matlab.ui.control.Label
        BeginningEditField             matlab.ui.control.NumericEditField
        EndEditFieldLabel              matlab.ui.control.Label
        EndEditField                   matlab.ui.control.NumericEditField
        PlottraineddataCheckBox        matlab.ui.control.CheckBox
        StatusTextAreaLabel            matlab.ui.control.Label
        StatusTextArea                 matlab.ui.control.TextArea
        OutputPathEditField            matlab.ui.control.EditField
        OutputPathButton               matlab.ui.control.Button
        SavesomerepresentativeepochsCheckBox  matlab.ui.control.CheckBox
        RunvisualinspectionPanel       matlab.ui.container.Panel
        RunvisualinspectionMandatoryforthefirsttimeCheckBox  matlab.ui.control.CheckBox
        ContinueanunfinishedvisualinspectionCheckBox  matlab.ui.control.CheckBox
        StartfromthelaststepcompletedCheckBox  matlab.ui.control.CheckBox
        Panel                          matlab.ui.container.Panel
        ArtifactdetectionamplitudetresholdSDLabel  matlab.ui.control.Label
        ArtifactdetectionamplitudetresholdSDEditField  matlab.ui.control.NumericEditField
        ClassifythetransitionsbetweenNREMandREMCheckBox  matlab.ui.control.CheckBox
        UseatrainingdatasetCheckBox    matlab.ui.control.CheckBox
        MissingsleepwakestateCheckBox  matlab.ui.control.CheckBox
        MissingStateDropDown           matlab.ui.control.DropDown
    end

    
    properties (Access = private)
        Calling_App % Reference to RMS_pwelch_integrate
    end
    
    properties (Access = public)
        Visual_Inspection_Status % Defines whether the visual inspection step has been finished or not
        Check_Point_Status % Logical value which defines whether already completed steps will or not be repeated
    end
    
    methods (Access = public)
        % Function to change the status edit field accordingly to the
        % algorithm necessities (used by GMM_Classifier_Training_fixed)
        function change_status_text(app,new_text)
            % Change the text value to new text
            app.StatusTextArea.Value = new_text;
        end
    end
    
    methods (Access = private)
        
        function prevent_recording_app_editing(app)
            
            % Prevents editing after the 'OK' button has been pressed            
            app.RecordingParametersPanel.Enable = 'off';
            app.RunvisualinspectionPanel.Enable = 'off';
            app.SavesomerepresentativeepochsCheckBox.Enable = false;
            app.OutputPathButton.Enable = false;
            app.OKButton.Enable = false;
            app.StartfromthelaststepcompletedCheckBox.Enable = false;
            app.ClassifythetransitionsbetweenNREMandREMCheckBox.Enable = false;
            app.MissingsleepwakestateCheckBox.Enable = false;
            app.UseatrainingdatasetCheckBox.Enable = false;
            app.MissingStateDropDown.Enable = false;
            
            % Update the graphical interface
            drawnow
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, Calling_app, outputPath)
            app.Calling_App = Calling_app;  % Getting the main app reference
            app.OutputPathEditField.Value = outputPath; % Change the OutPutPathEditField
            
            % Automatically get the upper and lower power line noise limits
            app.InferiorEditField.Value = app.Calling_App.PowerLineNoiseHzEditField.Value - 5;  % Inferior limit
            app.SuperiorEditField.Value = app.Calling_App.PowerLineNoiseHzEditField.Value + 5;  % Superior limit
            %             exportapp(app.UIFigure,'Recording_parameters.pdf')
            
            % Update the visual inspection status
            app.Visual_Inspection_Status = 'Continue';
            
        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)
            % Function to get the recording parameters used in the algorithm 
            
            recording_params.min_exclude = app.InferiorEditField.Value;
            recording_params.max_exclude = app.SuperiorEditField.Value;
            recording_params.recording_begin = app.BeginningEditField.Value;
            recording_params.recording_end = app.EndEditField.Value;
            recording_params.recording_group = app.AnimalGroupDropDown.Value;
            
            % Get info for plot trained data and visual algorithm
            algorithm_params.plot_trained_data = app.PlottraineddataCheckBox.Value;
            algorithm_params.run_visual_inspection = app.RunvisualinspectionMandatoryforthefirsttimeCheckBox.Value;
            algorithm_params.continue_visual_inspection = app.ContinueanunfinishedvisualinspectionCheckBox.Value;
            algorithm_params.plot_representative_epochs = app.SavesomerepresentativeepochsCheckBox.Value;
            algorithm_params.training_dataset = app.UseatrainingdatasetCheckBox.Value;
            algorithm_params.missing_state = app.MissingsleepwakestateCheckBox.Value;
            algorithm_params.missing_state_name = app.MissingStateDropDown.Value;
            
            % Get the output path
            output_path = app.OutputPathEditField.Value;
            
            % Main app function to get the info from the recording
            % parameters app (app = recording_parameters)
            transfer_recording_parameters(app.Calling_App,app,recording_params,algorithm_params,output_path)     
            
            % Prevents any kind of editing after the button 'OK' has been
            % pressed
            prevent_recording_app_editing(app)
            
            % Gets the the checkpoint status (it defines if the previous
            % completed steps, such as figure plotting, will be repeated)
            app.Check_Point_Status = app.StartfromthelaststepcompletedCheckBox.Value;
            
            % Resume the outer function execution
            uiresume(app.UIFigure)
        end

        % Button pushed function: OutputPathButton
        function OutputPathButtonPushed(app, event)
            % Changes the output path for the sorting algorithm and stores
            % it in a variable
            
            % Get a reference folder
            [main_app_pathway,~,~] = fileparts(which('RMS_pwelch_integrate'));
            % Get a title string the the file selection dialog box
            text = sprintf('Select the Output Folder');
            % Opens the dialog box and enables the selection of a mat file
            % (changes the edit field accordingly)
            app.OutputPathEditField.Value = uigetdir(main_app_pathway,text);
            
            % Keeps the app figure focused
            drawnow;
            figure(app.UIFigure)
                                    
        end

        % Value changed function: 
        % ContinueanunfinishedvisualinspectionCheckBox
        function ContinueanunfinishedvisualinspectionCheckBoxValueChanged(app, event)
            % Get the checkbox value           
            value = app.ContinueanunfinishedvisualinspectionCheckBox.Value;
            
            % Change the visual inspection check box to true automatically
            % if this checkbox have been changed to TRUE
            if value == true
                app.RunvisualinspectionMandatoryforthefirsttimeCheckBox.Value = true;
            end
            
        end

        % Value changed function: MissingsleepwakestateCheckBox
        function MissingsleepwakestateCheckBoxValueChanged(app, event)
            % Enables or Unable the drop down menu according to the user
            % selection
            app.MissingStateDropDown.Enable = app.MissingsleepwakestateCheckBox.Value;
            % Update the interface
            drawnow
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 719 409];
            app.UIFigure.Name = 'MATLAB App';

            % Create OKButton
            app.OKButton = uibutton(app.UIFigure, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [591 50 99 23];
            app.OKButton.Text = 'OK';

            % Create RecordingParametersPanel
            app.RecordingParametersPanel = uipanel(app.UIFigure);
            app.RecordingParametersPanel.TitlePosition = 'centertop';
            app.RecordingParametersPanel.Title = 'Recording Parameters';
            app.RecordingParametersPanel.Position = [30 139 316 207];

            % Create NoiseRangeHzLabel
            app.NoiseRangeHzLabel = uilabel(app.RecordingParametersPanel);
            app.NoiseRangeHzLabel.Position = [25 120 194 23];
            app.NoiseRangeHzLabel.Text = 'Noise Range (Hz) ';

            % Create RecordingTimeHoursLabel
            app.RecordingTimeHoursLabel = uilabel(app.RecordingParametersPanel);
            app.RecordingTimeHoursLabel.Position = [25 50 133 23];
            app.RecordingTimeHoursLabel.Text = 'Recording Time (Hours)';

            % Create AnimalGroupDropDownLabel
            app.AnimalGroupDropDownLabel = uilabel(app.RecordingParametersPanel);
            app.AnimalGroupDropDownLabel.HorizontalAlignment = 'right';
            app.AnimalGroupDropDownLabel.Position = [22 154 79 23];
            app.AnimalGroupDropDownLabel.Text = 'Animal Group';

            % Create AnimalGroupDropDown
            app.AnimalGroupDropDown = uidropdown(app.RecordingParametersPanel);
            app.AnimalGroupDropDown.Items = {'Experimental', 'Control', ''};
            app.AnimalGroupDropDown.Position = [116 155 121 22];
            app.AnimalGroupDropDown.Value = 'Experimental';

            % Create InferiorEditFieldLabel
            app.InferiorEditFieldLabel = uilabel(app.RecordingParametersPanel);
            app.InferiorEditFieldLabel.HorizontalAlignment = 'right';
            app.InferiorEditFieldLabel.Position = [25 85 55 23];
            app.InferiorEditFieldLabel.Text = 'Inferior';

            % Create InferiorEditField
            app.InferiorEditField = uieditfield(app.RecordingParametersPanel, 'numeric');
            app.InferiorEditField.Position = [95 85 48 22];
            app.InferiorEditField.Value = 55;

            % Create SuperiorEditFieldLabel
            app.SuperiorEditFieldLabel = uilabel(app.RecordingParametersPanel);
            app.SuperiorEditFieldLabel.HorizontalAlignment = 'right';
            app.SuperiorEditFieldLabel.Position = [172 84 54.99 23];
            app.SuperiorEditFieldLabel.Text = 'Superior';

            % Create SuperiorEditField
            app.SuperiorEditField = uieditfield(app.RecordingParametersPanel, 'numeric');
            app.SuperiorEditField.Position = [242 84 50 22];
            app.SuperiorEditField.Value = 65;

            % Create BeginningEditFieldLabel
            app.BeginningEditFieldLabel = uilabel(app.RecordingParametersPanel);
            app.BeginningEditFieldLabel.HorizontalAlignment = 'right';
            app.BeginningEditFieldLabel.Position = [35 16 59 23];
            app.BeginningEditFieldLabel.Text = 'Beginning';

            % Create BeginningEditField
            app.BeginningEditField = uieditfield(app.RecordingParametersPanel, 'numeric');
            app.BeginningEditField.Position = [109 16 48 22];
            app.BeginningEditField.Value = 12;

            % Create EndEditFieldLabel
            app.EndEditFieldLabel = uilabel(app.RecordingParametersPanel);
            app.EndEditFieldLabel.HorizontalAlignment = 'right';
            app.EndEditFieldLabel.Position = [173 16 54.99 23];
            app.EndEditFieldLabel.Text = 'End';

            % Create EndEditField
            app.EndEditField = uieditfield(app.RecordingParametersPanel, 'numeric');
            app.EndEditField.Position = [243 16 50 22];
            app.EndEditField.Value = 12;

            % Create PlottraineddataCheckBox
            app.PlottraineddataCheckBox = uicheckbox(app.UIFigure);
            app.PlottraineddataCheckBox.Visible = 'off';
            app.PlottraineddataCheckBox.Text = 'Plot trained data';
            app.PlottraineddataCheckBox.Position = [365 118 109 22];
            app.PlottraineddataCheckBox.Value = true;

            % Create StatusTextAreaLabel
            app.StatusTextAreaLabel = uilabel(app.UIFigure);
            app.StatusTextAreaLabel.HorizontalAlignment = 'right';
            app.StatusTextAreaLabel.Position = [30 19 39 22];
            app.StatusTextAreaLabel.Text = 'Status';

            % Create StatusTextArea
            app.StatusTextArea = uitextarea(app.UIFigure);
            app.StatusTextArea.Editable = 'off';
            app.StatusTextArea.Position = [84 12 606 31];
            app.StatusTextArea.Value = {''; ''};

            % Create OutputPathEditField
            app.OutputPathEditField = uieditfield(app.UIFigure, 'text');
            app.OutputPathEditField.Editable = 'off';
            app.OutputPathEditField.Position = [109 366 581 22];
            app.OutputPathEditField.Value = 'Choose the output path ';

            % Create OutputPathButton
            app.OutputPathButton = uibutton(app.UIFigure, 'push');
            app.OutputPathButton.ButtonPushedFcn = createCallbackFcn(app, @OutputPathButtonPushed, true);
            app.OutputPathButton.Position = [30 358 55 36];
            app.OutputPathButton.Text = {'Output'; ' Path'};

            % Create SavesomerepresentativeepochsCheckBox
            app.SavesomerepresentativeepochsCheckBox = uicheckbox(app.UIFigure);
            app.SavesomerepresentativeepochsCheckBox.Text = 'Save some representative epochs';
            app.SavesomerepresentativeepochsCheckBox.Position = [385 227 204 22];
            app.SavesomerepresentativeepochsCheckBox.Value = true;

            % Create RunvisualinspectionPanel
            app.RunvisualinspectionPanel = uipanel(app.UIFigure);
            app.RunvisualinspectionPanel.Title = 'Run visual inspection';
            app.RunvisualinspectionPanel.Position = [365 259 325 86];

            % Create RunvisualinspectionMandatoryforthefirsttimeCheckBox
            app.RunvisualinspectionMandatoryforthefirsttimeCheckBox = uicheckbox(app.RunvisualinspectionPanel);
            app.RunvisualinspectionMandatoryforthefirsttimeCheckBox.Text = 'Run visual inspection (Mandatory for the first time)';
            app.RunvisualinspectionMandatoryforthefirsttimeCheckBox.Position = [20 36 293 23];
            app.RunvisualinspectionMandatoryforthefirsttimeCheckBox.Value = true;

            % Create ContinueanunfinishedvisualinspectionCheckBox
            app.ContinueanunfinishedvisualinspectionCheckBox = uicheckbox(app.RunvisualinspectionPanel);
            app.ContinueanunfinishedvisualinspectionCheckBox.ValueChangedFcn = createCallbackFcn(app, @ContinueanunfinishedvisualinspectionCheckBoxValueChanged, true);
            app.ContinueanunfinishedvisualinspectionCheckBox.Text = 'Continue an unfinished visual inspection';
            app.ContinueanunfinishedvisualinspectionCheckBox.Position = [44 11 237 22];

            % Create StartfromthelaststepcompletedCheckBox
            app.StartfromthelaststepcompletedCheckBox = uicheckbox(app.UIFigure);
            app.StartfromthelaststepcompletedCheckBox.Text = 'Start from the last step completed';
            app.StartfromthelaststepcompletedCheckBox.Position = [385 194 202 22];
            app.StartfromthelaststepcompletedCheckBox.Value = true;

            % Create Panel
            app.Panel = uipanel(app.UIFigure);
            app.Panel.Position = [30 100 316 31];

            % Create ArtifactdetectionamplitudetresholdSDLabel
            app.ArtifactdetectionamplitudetresholdSDLabel = uilabel(app.Panel);
            app.ArtifactdetectionamplitudetresholdSDLabel.Position = [12 4 226 22];
            app.ArtifactdetectionamplitudetresholdSDLabel.Text = 'Artifact detection amplitude treshold (SD)';

            % Create ArtifactdetectionamplitudetresholdSDEditField
            app.ArtifactdetectionamplitudetresholdSDEditField = uieditfield(app.Panel, 'numeric');
            app.ArtifactdetectionamplitudetresholdSDEditField.HorizontalAlignment = 'center';
            app.ArtifactdetectionamplitudetresholdSDEditField.Position = [263 4 41 22];
            app.ArtifactdetectionamplitudetresholdSDEditField.Value = 7;

            % Create ClassifythetransitionsbetweenNREMandREMCheckBox
            app.ClassifythetransitionsbetweenNREMandREMCheckBox = uicheckbox(app.UIFigure);
            app.ClassifythetransitionsbetweenNREMandREMCheckBox.Text = 'Classify the transitions between NREM and REM';
            app.ClassifythetransitionsbetweenNREMandREMCheckBox.Position = [385 162 286 22];

            % Create UseatrainingdatasetCheckBox
            app.UseatrainingdatasetCheckBox = uicheckbox(app.UIFigure);
            app.UseatrainingdatasetCheckBox.Text = 'Use a training dataset';
            app.UseatrainingdatasetCheckBox.Position = [385 130 139 22];
            app.UseatrainingdatasetCheckBox.Value = true;

            % Create MissingsleepwakestateCheckBox
            app.MissingsleepwakestateCheckBox = uicheckbox(app.UIFigure);
            app.MissingsleepwakestateCheckBox.ValueChangedFcn = createCallbackFcn(app, @MissingsleepwakestateCheckBoxValueChanged, true);
            app.MissingsleepwakestateCheckBox.Text = 'Missing sleep-wake state';
            app.MissingsleepwakestateCheckBox.Position = [385 97 156 22];

            % Create MissingStateDropDown
            app.MissingStateDropDown = uidropdown(app.UIFigure);
            app.MissingStateDropDown.Items = {'WAKE', 'NREM', 'REM'};
            app.MissingStateDropDown.Enable = 'off';
            app.MissingStateDropDown.Position = [555 97 100 22];
            app.MissingStateDropDown.Value = 'WAKE';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = recording_parameters(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
