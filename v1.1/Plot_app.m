classdef Plot_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        NoneofthoseButton              matlab.ui.control.Button
        EpochcounterButton             matlab.ui.control.Button
        IamsurePanel                   matlab.ui.container.Panel
        AWAKEButton                    matlab.ui.control.Button
        NREMButton                     matlab.ui.control.Button
        REMButton                      matlab.ui.control.Button
        TransitionPanel                matlab.ui.container.Panel
        AWAKENREMButton                matlab.ui.control.Button
        NREMREMButton                  matlab.ui.control.Button
        REMAWAKEButton                 matlab.ui.control.Button
        PreviousButton                 matlab.ui.control.Button
        NextButton                     matlab.ui.control.Button
        FinishreinspectionButton       matlab.ui.control.Button
        StopandsaveinspectionButton    matlab.ui.control.Button
        AWAKELabel                     matlab.ui.control.Label
        NREMLabel                      matlab.ui.control.Label
        REMLabel                       matlab.ui.control.Label
        NumberofepochsclassifiedLabel  matlab.ui.control.Label
        Label_awake                    matlab.ui.control.Label
        Label_nrem                     matlab.ui.control.Label
        Label_rem                      matlab.ui.control.Label
        UIAxes_CA1                     matlab.ui.control.UIAxes
        UIAxes_PSD                     matlab.ui.control.UIAxes
        UIAxes_EMG                     matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        Current_classification % is a value representing the
    % classification for the current period (jj)
    end
    
    methods (Access = public)
        
        % Function to update the epochs, PSD and scatter plot on visual
        % inspection (epoch_num = selected epoch to be plotted;
        % CA1_lfp = CA1 LFP data (selected epoch)
        % EMG_rec = EMG recorded data (selected epoch)
        function updatePlot(app, time_vector_LFP, time_vector_EMG, epoch_num, CA1_lfp, EMG_rec, freq_vector, PSD_data, scatter_x, scatter_y, scatter_ylabel_text, Visual_inspection)
            sprintf('plot:')
            tic
            
            % Get the handle for each one of the axes
            CA1_UI = app.UIAxes_CA1;
            EMG_UI = app.UIAxes_EMG;
            PSD_UI = app.UIAxes_PSD;
            
            %% Plot
            % CA1
            plot(CA1_UI, time_vector_LFP, CA1_lfp)
            title(CA1_UI, ['Time bin: ' num2str(epoch_num)])   % Change the number of the title
            
            % EMG
            plot(EMG_UI, time_vector_EMG, EMG_rec)
            
            % PSD
            loglog(PSD_UI,freq_vector,nanfastsmooth(PSD_data,10,1,0.5),'k','linewidth',1.2)
% hold(PSD_UI,'on')            
% loglog(PSD_UI,freq_vector,smooth(PSD_data,10),'r','linewidth',0.5)
            ylim(PSD_UI,[0.00001 0.03])
%             ylim(PSD_UI,[min(PSD_data)*0.5 max(PSD_data)*3]);    % Correct Ylim accordingly to the data
% hold(PSD_UI,'off')            
            

            % Update the counters
            app.Label_awake.Text = mat2str(length(Visual_inspection.AWAKE_idx));  % AWAKE
            app.Label_nrem.Text = mat2str(length(Visual_inspection.NREM_idx));    % NREM
            app.Label_rem.Text = mat2str(length(Visual_inspection.REM_idx));      % REM
            
            toc
            % Update the plots 
            drawnow
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
%             exportapp(app.UIFigure,'Plot_app.pdf')
            
        end

        % Key release function: UIFigure
        function UIFigureKeyRelease(app, event)
            % If the user presses a key instead of pressing a classfication
            % button -> Get the key and act accordingly
            % event.Key = pressed key
            
            % Act accordingly
            switch event.Key
                case {'1', 'numpad1'}    % AWAKE
                    app.Current_classification = 1; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
                    
                case {'2', 'numpad2'}    % NREM
                    app.Current_classification = 2; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
                    
                case {'3', 'numpad3'}    % REM
                    app.Current_classification = 3; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
                
                case {'4', 'numpad4'}    % AWAKE <--> NREM
                    app.Current_classification = 4; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
            
                case {'5', 'numpad5'}    % NREM <--> REM
                    app.Current_classification = 5; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        
                case {'6', 'numpad6'}    % REM <--> AWAKE
                    app.Current_classification = 6; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
    
                case {'0', 'numpad0'}    % None of those
                    app.Current_classification = 0; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
                
                case {'7', 'numpad7'}    % Epoch counter
                    app.Current_classification = 7; % Change the current epoch classification accordingly
                    uiresume(app.UIFigure)  % Resume the execution of the visual inspection
                    
                case 'rightarrow'   % Right arrow (next)
                    app.Current_classification = 'next'; % Change the current epoch classification accordingly (informs the algorithm to go back to the previous epoch)
                    uiresume(app.UIFigure) % Resume the execution of the visual inspection
                    
                case 'leftarrow'   % Right arrow (next)
                    app.Current_classification = 'previous'; % Change the current epoch classification accordingly (informs the algorithm to go forward to the next epoch)
                    uiresume(app.UIFigure) % Resume the execution of the visual inspection
                    
            end
            
        end

        % Button pushed function: AWAKEButton
        function AWAKEButtonPushed(app, event)
            sprintf('Classification:')
            tic
            app.Current_classification = 1; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
            toc
        end

        % Button pushed function: NREMButton
        function NREMButtonPushed(app, event)
            app.Current_classification = 2; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        end

        % Button pushed function: REMButton
        function REMButtonPushed(app, event)
            app.Current_classification = 3; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        end

        % Button pushed function: AWAKENREMButton
        function AWAKENREMButtonPushed(app, event)
            app.Current_classification = 4; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        end

        % Button pushed function: NREMREMButton
        function NREMREMButtonPushed(app, event)
            app.Current_classification = 5; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        end

        % Button pushed function: REMAWAKEButton
        function REMAWAKEButtonPushed(app, event)
            app.Current_classification = 6; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        end

        % Button pushed function: NoneofthoseButton
        function NoneofthoseButtonPushed(app, event)
            app.Current_classification = 0; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        end

        % Button pushed function: EpochcounterButton
        function EpochcounterButtonPushed(app, event)
            app.Current_classification = 7; % Change the current epoch classification accordingly
            uiresume(app.UIFigure)  % Resume the execution of the visual inspection
        end

        % Button pushed function: PreviousButton
        function PreviousButtonPushed(app, event)
            % Return to the previous plotted epoch
            app.Current_classification = 'previous'; % Change the current epoch classification accordingly (informs the algorithm to go back to the previous epoch)
            uiresume(app.UIFigure) % Resume the execution of the visual inspection
        end

        % Button pushed function: NextButton
        function NextButtonPushed(app, event)
            % Return to the previous plotted epoch
            app.Current_classification = 'next'; % Change the current epoch classification accordingly (informs the algorithm to go forward to the previous epoch)
            uiresume(app.UIFigure) % Resume the execution of the visual inspection
            
%             exportgraphics(app.UIFigure,'Virtual.pdf','BackgroundColor','none','ContentType','vector')
        end

        % Button pushed function: FinishreinspectionButton
        function FinishreinspectionButtonPushed(app, event)
            app.Current_classification = 'finish_re_inspection';    % Change the current epoch classification to finish to re-inspection
            uiresume(app.UIFigure) % Resume the execution of the visual inspection
        end

        % Button pushed function: StopandsaveinspectionButton
        function StopandsaveinspectionButtonPushed(app, event)
            app.Current_classification = 'stop_and_save';    % Change the current epoch classification to finish the inspection and save it
            uiresume(app.UIFigure) % Resume the execution of the visual inspection
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 1];
            app.UIFigure.Position = [190 50 964 683];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.KeyReleaseFcn = createCallbackFcn(app, @UIFigureKeyRelease, true);

            % Create NoneofthoseButton
            app.NoneofthoseButton = uibutton(app.UIFigure, 'push');
            app.NoneofthoseButton.ButtonPushedFcn = createCallbackFcn(app, @NoneofthoseButtonPushed, true);
            app.NoneofthoseButton.Position = [839 54 111 22];
            app.NoneofthoseButton.Text = '0 - None of those';

            % Create EpochcounterButton
            app.EpochcounterButton = uibutton(app.UIFigure, 'push');
            app.EpochcounterButton.ButtonPushedFcn = createCallbackFcn(app, @EpochcounterButtonPushed, true);
            app.EpochcounterButton.Enable = 'off';
            app.EpochcounterButton.Position = [839 15 111 23];
            app.EpochcounterButton.Text = '7 - Epoch counter';

            % Create IamsurePanel
            app.IamsurePanel = uipanel(app.UIFigure);
            app.IamsurePanel.TitlePosition = 'centertop';
            app.IamsurePanel.Title = 'I am sure!';
            app.IamsurePanel.BackgroundColor = [1 1 1];
            app.IamsurePanel.Position = [17 15 357 61];

            % Create AWAKEButton
            app.AWAKEButton = uibutton(app.IamsurePanel, 'push');
            app.AWAKEButton.ButtonPushedFcn = createCallbackFcn(app, @AWAKEButtonPushed, true);
            app.AWAKEButton.Position = [11 9 100 22];
            app.AWAKEButton.Text = '1 - AWAKE';

            % Create NREMButton
            app.NREMButton = uibutton(app.IamsurePanel, 'push');
            app.NREMButton.ButtonPushedFcn = createCallbackFcn(app, @NREMButtonPushed, true);
            app.NREMButton.Position = [129 9 100 22];
            app.NREMButton.Text = '2 - NREM';

            % Create REMButton
            app.REMButton = uibutton(app.IamsurePanel, 'push');
            app.REMButton.ButtonPushedFcn = createCallbackFcn(app, @REMButtonPushed, true);
            app.REMButton.Position = [243 9 100 22];
            app.REMButton.Text = '3 - REM';

            % Create TransitionPanel
            app.TransitionPanel = uipanel(app.UIFigure);
            app.TransitionPanel.TitlePosition = 'centertop';
            app.TransitionPanel.Title = 'Transition';
            app.TransitionPanel.BackgroundColor = [1 1 1];
            app.TransitionPanel.Position = [395 15 428 61];

            % Create AWAKENREMButton
            app.AWAKENREMButton = uibutton(app.TransitionPanel, 'push');
            app.AWAKENREMButton.ButtonPushedFcn = createCallbackFcn(app, @AWAKENREMButtonPushed, true);
            app.AWAKENREMButton.Position = [8 7 139 22];
            app.AWAKENREMButton.Text = '4 - AWAKE <--> NREM';

            % Create NREMREMButton
            app.NREMREMButton = uibutton(app.TransitionPanel, 'push');
            app.NREMREMButton.ButtonPushedFcn = createCallbackFcn(app, @NREMREMButtonPushed, true);
            app.NREMREMButton.Position = [155 7 123 22];
            app.NREMREMButton.Text = '5 - NREM <--> REM';

            % Create REMAWAKEButton
            app.REMAWAKEButton = uibutton(app.TransitionPanel, 'push');
            app.REMAWAKEButton.ButtonPushedFcn = createCallbackFcn(app, @REMAWAKEButtonPushed, true);
            app.REMAWAKEButton.Position = [289 8 130 22];
            app.REMAWAKEButton.Text = '6 - REM <--> AWAKE';

            % Create PreviousButton
            app.PreviousButton = uibutton(app.UIFigure, 'push');
            app.PreviousButton.ButtonPushedFcn = createCallbackFcn(app, @PreviousButtonPushed, true);
            app.PreviousButton.Position = [431 91 55 23];
            app.PreviousButton.Text = 'Previous';

            % Create NextButton
            app.NextButton = uibutton(app.UIFigure, 'push');
            app.NextButton.ButtonPushedFcn = createCallbackFcn(app, @NextButtonPushed, true);
            app.NextButton.Position = [511 91 55 23];
            app.NextButton.Text = 'Next';

            % Create FinishreinspectionButton
            app.FinishreinspectionButton = uibutton(app.UIFigure, 'push');
            app.FinishreinspectionButton.ButtonPushedFcn = createCallbackFcn(app, @FinishreinspectionButtonPushed, true);
            app.FinishreinspectionButton.Visible = 'off';
            app.FinishreinspectionButton.Position = [834.5 91 120 22];
            app.FinishreinspectionButton.Text = 'Finish re-inspection';

            % Create StopandsaveinspectionButton
            app.StopandsaveinspectionButton = uibutton(app.UIFigure, 'push');
            app.StopandsaveinspectionButton.ButtonPushedFcn = createCallbackFcn(app, @StopandsaveinspectionButtonPushed, true);
            app.StopandsaveinspectionButton.Position = [17 91 150 22];
            app.StopandsaveinspectionButton.Text = 'Stop and save inspection';

            % Create AWAKELabel
            app.AWAKELabel = uilabel(app.UIFigure);
            app.AWAKELabel.Position = [59 229 55 23];
            app.AWAKELabel.Text = 'AWAKE: ';

            % Create NREMLabel
            app.NREMLabel = uilabel(app.UIFigure);
            app.NREMLabel.Position = [59 204 44 23];
            app.NREMLabel.Text = 'NREM:';

            % Create REMLabel
            app.REMLabel = uilabel(app.UIFigure);
            app.REMLabel.Position = [59 179 35 23];
            app.REMLabel.Text = 'REM:';

            % Create NumberofepochsclassifiedLabel
            app.NumberofepochsclassifiedLabel = uilabel(app.UIFigure);
            app.NumberofepochsclassifiedLabel.HorizontalAlignment = 'center';
            app.NumberofepochsclassifiedLabel.Position = [28 267 156 28];
            app.NumberofepochsclassifiedLabel.Text = {'Number of '; 'epochs classified'};

            % Create Label_awake
            app.Label_awake = uilabel(app.UIFigure);
            app.Label_awake.Position = [124 229 35 23];
            app.Label_awake.Text = '0';

            % Create Label_nrem
            app.Label_nrem = uilabel(app.UIFigure);
            app.Label_nrem.Position = [124 204 35 23];
            app.Label_nrem.Text = '0';

            % Create Label_rem
            app.Label_rem = uilabel(app.UIFigure);
            app.Label_rem.Position = [124 179 35 23];
            app.Label_rem.Text = '0';

            % Create UIAxes_CA1
            app.UIAxes_CA1 = uiaxes(app.UIFigure);
            title(app.UIAxes_CA1, 'Title')
            ylabel(app.UIAxes_CA1, {'Hippocampus'; '(mV)'})
            app.UIAxes_CA1.PlotBoxAspectRatio = [7.54954954954955 1 1];
            app.UIAxes_CA1.YLim = [-1 1];
            app.UIAxes_CA1.XTickLabel = {'0'; '1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; '10'};
            app.UIAxes_CA1.Position = [28 509 904 166];

            % Create UIAxes_PSD
            app.UIAxes_PSD = uiaxes(app.UIFigure);
            xlabel(app.UIAxes_PSD, 'Frequency (Hz)')
            ylabel(app.UIAxes_PSD, {'PSD'; 'Power Norm'})
            app.UIAxes_PSD.PlotBoxAspectRatio = [2.5578231292517 1 1];
            app.UIAxes_PSD.XLim = [1 90];
            app.UIAxes_PSD.YLim = [0.0001 0.01];
            app.UIAxes_PSD.XTick = [2 4 6 8 10 20 40 60 80];
            app.UIAxes_PSD.XScale = 'log';
            app.UIAxes_PSD.XTickLabel = {'2'; '4'; '6'; '8'; '10'; '20'; '40'; '60'; '80'};
            app.UIAxes_PSD.XMinorTick = 'on';
            app.UIAxes_PSD.YScale = 'log';
            app.UIAxes_PSD.YMinorTick = 'on';
            app.UIAxes_PSD.Position = [262 135 442 190];

            % Create UIAxes_EMG
            app.UIAxes_EMG = uiaxes(app.UIFigure);
            xlabel(app.UIAxes_EMG, 'Seconds')
            ylabel(app.UIAxes_EMG, {'EMG'; '(mV)'})
            app.UIAxes_EMG.PlotBoxAspectRatio = [6.92561983471074 1 1];
            app.UIAxes_EMG.YLim = [-1 1];
            app.UIAxes_EMG.XTickLabel = {'0'; '1'; '2'; '3'; '4'; '5'; '6'; '7'; '8'; '9'; '10'};
            app.UIAxes_EMG.YTick = [-1 -0.5 0 0.5 1];
            app.UIAxes_EMG.Position = [28 331 904 176];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Plot_app

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

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