classdef add_frequency_bands < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        TextArea                      matlab.ui.control.TextArea
        NewfrequencybandsButtonGroup  matlab.ui.container.ButtonGroup
        NoneButton                    matlab.ui.control.RadioButton
        AddBetaButton                 matlab.ui.control.RadioButton
        AddLowGammaButton             matlab.ui.control.RadioButton
        AddHighGammaButton            matlab.ui.control.RadioButton
        AddallGammarangeButton        matlab.ui.control.RadioButton
        Use6to90HzDeltaButton         matlab.ui.control.RadioButton
        OpenPDFfilesButton            matlab.ui.control.Button
        OpenPDFfilestoevaluateanypossibleadditionsoffrequencybandsLabel  matlab.ui.control.Label
        OKButton                      matlab.ui.control.Button
    end

    
    properties (Access = private)
        Calling_app % Reference to RMS_pwelch_integrate app
        Output_Path % Path were the needed PDF files were saved
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, calling_app, outputPath)
            app.Calling_app = calling_app;  % Transfering the reference to RMS_pwelch_integrate to a property 
            app.Output_Path = outputPath;   % Transfer the PDF files path to a property
            
%            exportapp(app.UIFigure,'add_frequency_bands.pdf')

        end

        % Button pushed function: OKButton
        function OKButtonPushed(app, event)
            % Function to get the added frenquency bands

            % Get the frequency bands from the radio button group
            frequency_bands_radio_button_tag = app.NewfrequencybandsButtonGroup.Buttons([app.NewfrequencybandsButtonGroup.Buttons.Value]).Tag;
            
            % Main app function to get the info from the recording
            % parameters app (app = recording_parameters)
            transfer_frequency_bands_parameters(app.Calling_app,app,frequency_bands_radio_button_tag)
            
            % Resume the outer function execution
            uiresume(app.UIFigure)
            
            % Close app
            delete(app)
        end

        % Button pushed function: OpenPDFfilesButton
        function OpenPDFfilesButtonPushed(app, event)
            % Function to open the PDF files containing graphs about
            % distribution of power in diferente frequency bands 
            
            % Get the name of each PDF file
            graph_names_list = {'Frequency bands distribution.pdf', 'Frequency bands distribution over time.pdf', 'Frequency bands combined.pdf'};
            
            % Loop to open each one of the files (Using the specific
            % software for it)
            for list_loop = 1:length(graph_names_list)
                complete_filename = fullfile(app.Output_Path,graph_names_list{list_loop});  % Get the complete filename using the apropriate system parameters
                open(complete_filename) % Effectively opens the pdf
            end
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 449 358];
            app.UIFigure.Name = 'MATLAB App';

            % Create TextArea
            app.TextArea = uitextarea(app.UIFigure);
            app.TextArea.HorizontalAlignment = 'center';
            app.TextArea.Position = [30 282 397 54];
            app.TextArea.Value = {'Our default mode for the classification is using hippocampal Theta/Delta ratio. Would you like to add other frequency bands for the classification? Which ones?'};

            % Create NewfrequencybandsButtonGroup
            app.NewfrequencybandsButtonGroup = uibuttongroup(app.UIFigure);
            app.NewfrequencybandsButtonGroup.TitlePosition = 'centertop';
            app.NewfrequencybandsButtonGroup.Title = 'New frequency bands';
            app.NewfrequencybandsButtonGroup.Position = [29 102 398 166];

            % Create NoneButton
            app.NoneButton = uiradiobutton(app.NewfrequencybandsButtonGroup);
            app.NoneButton.Tag = 'none';
            app.NoneButton.Text = 'None';
            app.NoneButton.Position = [11 119 58 23];
            app.NoneButton.Value = true;

            % Create AddBetaButton
            app.AddBetaButton = uiradiobutton(app.NewfrequencybandsButtonGroup);
            app.AddBetaButton.Tag = 'beta';
            app.AddBetaButton.Text = 'Add Beta';
            app.AddBetaButton.Position = [11 97 72 23];

            % Create AddLowGammaButton
            app.AddLowGammaButton = uiradiobutton(app.NewfrequencybandsButtonGroup);
            app.AddLowGammaButton.Tag = 'low_gamma';
            app.AddLowGammaButton.Text = 'Add Low Gamma';
            app.AddLowGammaButton.Position = [11 75 114 23];

            % Create AddHighGammaButton
            app.AddHighGammaButton = uiradiobutton(app.NewfrequencybandsButtonGroup);
            app.AddHighGammaButton.Tag = 'high_gamma';
            app.AddHighGammaButton.Text = 'Add High Gamma';
            app.AddHighGammaButton.Position = [11 52 117 23];

            % Create AddallGammarangeButton
            app.AddallGammarangeButton = uiradiobutton(app.NewfrequencybandsButtonGroup);
            app.AddallGammarangeButton.Tag = 'all_gamma';
            app.AddallGammarangeButton.Text = 'Add all Gamma range';
            app.AddallGammarangeButton.Position = [11 30 138 23];

            % Create Use6to90HzDeltaButton
            app.Use6to90HzDeltaButton = uiradiobutton(app.NewfrequencybandsButtonGroup);
            app.Use6to90HzDeltaButton.Tag = '6_to_90';
            app.Use6to90HzDeltaButton.Text = 'Use 6 to 90 Hz/ Delta';
            app.Use6to90HzDeltaButton.Position = [11 6 136 23];

            % Create OpenPDFfilesButton
            app.OpenPDFfilesButton = uibutton(app.UIFigure, 'push');
            app.OpenPDFfilesButton.ButtonPushedFcn = createCallbackFcn(app, @OpenPDFfilesButtonPushed, true);
            app.OpenPDFfilesButton.Position = [27 16 98 23];
            app.OpenPDFfilesButton.Text = 'Open PDF files';

            % Create OpenPDFfilestoevaluateanypossibleadditionsoffrequencybandsLabel
            app.OpenPDFfilestoevaluateanypossibleadditionsoffrequencybandsLabel = uilabel(app.UIFigure);
            app.OpenPDFfilestoevaluateanypossibleadditionsoffrequencybandsLabel.Position = [29 48 382 45];
            app.OpenPDFfilestoevaluateanypossibleadditionsoffrequencybandsLabel.Text = {'Open PDF files to evaluate any possible additions of frequency bands'; 'according to the presented distributions:'};

            % Create OKButton
            app.OKButton = uibutton(app.UIFigure, 'push');
            app.OKButton.ButtonPushedFcn = createCallbackFcn(app, @OKButtonPushed, true);
            app.OKButton.Position = [328 17 99 23];
            app.OKButton.Text = 'OK';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = add_frequency_bands_exported(varargin)

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