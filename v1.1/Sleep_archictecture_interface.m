classdef Sleep_archictecture_interface < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        SegmentationButtonGroup         matlab.ui.container.ButtonGroup
        WholeDataButton                 matlab.ui.control.RadioButton
        SegmentedEquallyButton          matlab.ui.control.RadioButton
        CustomSegmentsButton            matlab.ui.control.RadioButton
        CustomSegmentsTable             matlab.ui.control.Table
        AddRow                          matlab.ui.control.Button
        ExcludeRow                      matlab.ui.control.Button
        SegmentLengthHoursLabel         matlab.ui.control.Label
        SegmentLengthHoursEditField     matlab.ui.control.NumericEditField
        ThewholedatawillbeconsideredAbargraphwillbegeneratedLabel  matlab.ui.control.Label
        RefreshButton                   matlab.ui.control.Button
        SaveButton                      matlab.ui.control.Button
        LoadButton                      matlab.ui.control.Button
        stStepLoadthefileGMM_ClassificationLabel  matlab.ui.control.Label
        thStepRefreshaccordingtothecurrentselectionLabel  matlab.ui.control.Label
        thStepSavetheplotsanddataLabel  matlab.ui.control.Label
        rdStepSelecttheEpochLengthSecEditFieldLabel  matlab.ui.control.Label
        rdStepSelecttheEpochLengthSecEditField  matlab.ui.control.NumericEditField
        ndStepSelectoneofthe3optionsbellowLabel  matlab.ui.control.Label
        LoadedLabel                     matlab.ui.control.Label
        SavedLabel                      matlab.ui.control.Label
        TotalLengthLabel                matlab.ui.control.Label
        UIAxes                          matlab.ui.control.UIAxes
        UIAxes_2                        matlab.ui.control.UIAxes
        UIAxes_3                        matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        CustomSegmentsList % Stores the [Beginning and End] values for all the segments
        SelectedRow % A row selected by the user in the CustomSegmentTable
        GMM_fullfile % Full pathway for the 'GMM_Classification' file
        All_Sort % Stores the classification (1-REM; 2-NREM; 3-AWAKE)
        Selected_Radio_Button % Stores the tag related to the selected button
        Architecture_result % Stores the architecture analysis results
        Epoch_Length % Stores the epoch property after the Refresh button has been pressed
        Segment_Length % Stores the segment length (case the option 2 has been selected)
    end
    
    methods (Access = private)
        
        % Function to update the Custom Segment Table in the GUI
        function updateCustomSegmentTable(app)
            
            % Insert the data in the table
            app.CustomSegmentsTable.Data = struct2table(app.CustomSegmentsList);
            
            % Update any graphical changes
            drawnow;
        end
        
        % Function to plot the architecture results (Time spent, number of
        % bouts and its duration)
        function plot_architecture_results(app)
            
            % Get plot handles
            time_spent_UI = app.UIAxes;
            num_bouts_UI = app.UIAxes_2;
            duration_bouts_UI = app.UIAxes_3;
            
            % Colors
            figure_paramenters.color.awake=[0.9290, 0.6940, 0.1250];
            figure_paramenters.color.nrem=[0 0.4470 0.7410];
            figure_paramenters.color.rem=[0.3 0.3 0.3];
            
            % Check if the user selected the whole data (not segmented)
            switch app.Selected_Radio_Button
                case 'whole'
                    x_values = [1; 2; 3];   % X axis values
                    
                    %% Time Spent                    
                    wk = bar(time_spent_UI,x_values(1),app.Architecture_result.AWAKE.total,'FaceColor','flat');
                    hold(time_spent_UI,'on')
                    nrem = bar(time_spent_UI,x_values(2),app.Architecture_result.NREM.total,'FaceColor','flat');
                    hold(time_spent_UI,'on')
                    rem = bar(time_spent_UI,x_values(3),app.Architecture_result.REM.total,'FaceColor','flat');
                    hold(time_spent_UI,'off')
                    
                    wk.CData = figure_paramenters.color.awake;  % AWAKE color
                    nrem.CData = figure_paramenters.color.nrem;   % NREM color
                    rem.CData = figure_paramenters.color.rem;    % REM color
                    
                    time_spent_UI.XLim = [-1 5];     % XLim    
                    time_spent_UI.XTick = [];
                    
                    %% Number of bouts per minute                    
                    wk = bar(num_bouts_UI,x_values(1),app.Architecture_result.AWAKE.Nbouts,'FaceColor','flat');
                    hold(num_bouts_UI,'on')
                    nrem = bar(num_bouts_UI,x_values(2),app.Architecture_result.NREM.Nbouts,'FaceColor','flat');
                    hold(num_bouts_UI,'on')
                    rem = bar(num_bouts_UI,x_values(3),app.Architecture_result.REM.Nbouts,'FaceColor','flat');
                    hold(num_bouts_UI,'off')
                    
                    wk.CData = figure_paramenters.color.awake;  % AWAKE color
                    nrem.CData = figure_paramenters.color.nrem;   % NREM color
                    rem.CData = figure_paramenters.color.rem;    % REM color
                    
                    num_bouts_UI.XLim = [-1 5];     % XLim  
                    num_bouts_UI.XTick = [];
                    
                    %% Average duration of bouts                    
                    wk = bar(duration_bouts_UI,x_values(1),app.Architecture_result.AWAKE.duration_mean,'FaceColor','flat');
                    hold(duration_bouts_UI,'on')
                    nrem = bar(duration_bouts_UI,x_values(2),app.Architecture_result.NREM.duration_mean,'FaceColor','flat');
                    hold(duration_bouts_UI,'on')
                    rem = bar(duration_bouts_UI,x_values(3),app.Architecture_result.REM.duration_mean,'FaceColor','flat');
                    hold(duration_bouts_UI,'off')
                    
                    wk.CData = figure_paramenters.color.awake;  % AWAKE color
                    nrem.CData = figure_paramenters.color.nrem;   % NREM color
                    rem.CData = figure_paramenters.color.rem;    % REM color
                    
                    duration_bouts_UI.XLim = [-1 5];     % XLim
                    duration_bouts_UI.XTick = [];
                    duration_bouts_UI.XTickLabelMode = 'manual';
                    duration_bouts_UI.XTickLabel = [];
                    duration_bouts_UI.XLabel.String = [];
                    
                    duration_bouts_UI.PlotBoxAspectRatio = [5.752380952380952 1 1];
                    
                    legend(duration_bouts_UI,{'AWAKE','NREM','REM'},'Location','none','Box',"off",...
                        'Position',[0.84,0.27,0.132547864506627,0.0642335766423358]);   % Legend

                case 'segmented'      % Segmented and Custom segments
                    
                    % X axis has the same number of elements as the total number of segments
                    x_values = linspace(0,1,size(app.Architecture_result.AWAKE.total,1));   
                    
                    %% Time Spent                    
                    wk = plot(time_spent_UI,x_values,app.Architecture_result.AWAKE.total);
                    hold(time_spent_UI,'on')
                    nrem = plot(time_spent_UI,x_values,app.Architecture_result.NREM.total);
                    hold(time_spent_UI,'on')
                    rem = plot (time_spent_UI,x_values,app.Architecture_result.REM.total);
                    hold(time_spent_UI,'off')
                    
                    wk.Color = figure_paramenters.color.awake;  % AWAKE color
                    nrem.Color = figure_paramenters.color.nrem;   % NREM color
                    rem.Color = figure_paramenters.color.rem;    % REM color
                    
                    time_spent_UI.XLim = [0 1];     % XLim    
                    
                    %% Number of bouts per minute                    
                    wk = plot(num_bouts_UI,x_values,app.Architecture_result.AWAKE.Nbouts);
                    hold(num_bouts_UI,'on')
                    nrem = plot(num_bouts_UI,x_values,app.Architecture_result.NREM.Nbouts);
                    hold(num_bouts_UI,'on')
                    rem = plot (num_bouts_UI,x_values,app.Architecture_result.REM.Nbouts);
                    hold(num_bouts_UI,'off')
                    
                    wk.Color = figure_paramenters.color.awake;  % AWAKE color
                    nrem.Color = figure_paramenters.color.nrem;   % NREM color
                    rem.Color = figure_paramenters.color.rem;    % REM color
                    
                    num_bouts_UI.XLim = [0 1];     % XLim 
                    
                    %% Average duration of bouts                    
                    wk = plot(duration_bouts_UI,x_values,app.Architecture_result.AWAKE.duration_mean);
                    hold(duration_bouts_UI,'on')
                    nrem = plot(duration_bouts_UI,x_values,app.Architecture_result.NREM.duration_mean);
                    hold(duration_bouts_UI,'on')
                    rem = plot (duration_bouts_UI,x_values,app.Architecture_result.REM.duration_mean);
                    hold(duration_bouts_UI,'off')
                    
                    wk.Color = figure_paramenters.color.awake;  % AWAKE color
                    nrem.Color = figure_paramenters.color.nrem;   % NREM color
                    rem.Color = figure_paramenters.color.rem;    % REM color
                    
                    duration_bouts_UI.XLim = [0 1];     % XLim
                    duration_bouts_UI.XTick = 0:0.1:1;  % Get the new Ticks
                    % Get the values of xticks in Hours
                    x_ticks = round(duration_bouts_UI.XTick * (length(app.All_Sort) * app.rdStepSelecttheEpochLengthSecEditField.Value / 3600),1);
                    duration_bouts_UI.XTickLabel = [x_ticks];   % Change the Xticks (only in the 3rd axis)
                    duration_bouts_UI.XLabel.String = 'Hours';
                    
                    legend(duration_bouts_UI,{'AWAKE','NREM','REM'},'Location','none','Box',"off",...
                        'Position',[0.84,0.27,0.132547864506627,0.0642335766423358]);   % Legend
                    
                case 'custom'
                     % Custom segments
                        % In this case, the X values will accompany the
                        % distance between the intervals
                        max_val = max(app.CustomSegmentsList.end(:));       % Upper limit
                        min_val = min(app.CustomSegmentsList.beginning(:)); % Lower limit
                        
                        % Mean along the rows (Dim = 2)
                        x_values = mean([app.CustomSegmentsList.beginning(:) app.CustomSegmentsList.end(:)],2);
                        % Get the proportion according to the interval (min
                        % max)
%                         x_values = x_values' / (max_val - min_val);
%                         x_values = x_values' / length(app.All_Sort);
                        
                        %% Time Spent                    
                    wk = plot(time_spent_UI,x_values,app.Architecture_result.AWAKE.total,'--.','MarkerSize',15);
                    hold(time_spent_UI,'on')
                    nrem = plot(time_spent_UI,x_values,app.Architecture_result.NREM.total,'--.','MarkerSize',15);
                    hold(time_spent_UI,'on')
                    rem = plot (time_spent_UI,x_values,app.Architecture_result.REM.total,'--.','MarkerSize',15);
                    hold(time_spent_UI,'off')
                    
                    wk.Color = figure_paramenters.color.awake;  % AWAKE color
                    nrem.Color = figure_paramenters.color.nrem;   % NREM color
                    rem.Color = figure_paramenters.color.rem;    % REM color
                    
                    time_spent_UI.XLim = [0 length(app.All_Sort)];     % XLim    

                    
                    %% Number of bouts per minute                    
                    wk = plot(num_bouts_UI,x_values,app.Architecture_result.AWAKE.Nbouts,'--.','MarkerSize',15);
                    hold(num_bouts_UI,'on')
                    nrem = plot(num_bouts_UI,x_values,app.Architecture_result.NREM.Nbouts,'--.','MarkerSize',15);
                    hold(num_bouts_UI,'on')
                    rem = plot (num_bouts_UI,x_values,app.Architecture_result.REM.Nbouts,'--.','MarkerSize',15);
                    hold(num_bouts_UI,'off')
                    
                    wk.Color = figure_paramenters.color.awake;  % AWAKE color
                    nrem.Color = figure_paramenters.color.nrem;   % NREM color
                    rem.Color = figure_paramenters.color.rem;    % REM color
                    
                    num_bouts_UI.XLim = [0 length(app.All_Sort)];     % XLim 
                    
                    %% Average duration of bouts                    
                    wk = plot(duration_bouts_UI,x_values,app.Architecture_result.AWAKE.duration_mean,'--.','MarkerSize',15);
                    hold(duration_bouts_UI,'on')
                    nrem = plot(duration_bouts_UI,x_values,app.Architecture_result.NREM.duration_mean,'--.','MarkerSize',15);
                    hold(duration_bouts_UI,'on')
                    rem = plot (duration_bouts_UI,x_values,app.Architecture_result.REM.duration_mean,'--.','MarkerSize',15);
                    hold(duration_bouts_UI,'off')
                    
                    wk.Color = figure_paramenters.color.awake;  % AWAKE color
                    nrem.Color = figure_paramenters.color.nrem;   % NREM color
                    rem.Color = figure_paramenters.color.rem;    % REM color
                    
                    duration_bouts_UI.XLim = [0 length(app.All_Sort)];     % XLim
                    duration_bouts_UI.XTick = linspace(0,length(app.All_Sort),10);  % Get the new Ticks
                    % Get the values of xticks in Hours
%                     x_ticks = round(duration_bouts_UI.XTick * (length(app.All_Sort) * app.rdStepSelecttheEpochLengthSecEditField.Value / 3600),1);
                    duration_bouts_UI.XTickLabel = [duration_bouts_UI.XTick];   % Change the Xticks (only in the 3rd axis)
                    duration_bouts_UI.XLabel.String = 'Hours';
                    
                    legend(duration_bouts_UI,{'AWAKE','NREM','REM'},'Location','none','Box',"off",...
                        'Position',[0.84,0.27,0.132547864506627,0.0642335766423358]);   % Legend 
            end
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Initialize app.CustomSegmentsButton
            app.CustomSegmentsList = struct('beginning',[NaN],'end',[NaN]);
            
            % Insert a dummy data [0 0] for the table to be initialized
            custom_segments_struct = app.CustomSegmentsList;
            
            % Insert the data in the table
            app.CustomSegmentsTable.Data = struct2table(custom_segments_struct);
            
            % SelectedRow must be Nan until the user selects a row
            app.SelectedRow = NaN;
        end

        % Button pushed function: AddRow
        function AddRowPushed(app, event)
            % Add new roles in the table (after a selected one or the last)
            
            if isnan(app.SelectedRow) || size(app.CustomSegmentsList.beginning,1) <= 1 || app.SelectedRow == size(app.CustomSegmentsList.beginning,1)  % A row has not been selected yet or the table has only one row or the selected row is the last one (Add a new role after the last one)
                app.CustomSegmentsList.beginning(end+1,1) = NaN;    % Add beginning
                app.CustomSegmentsList.end(end+1,1) = NaN;          % Add end
            else % A row has already been selected
                app.CustomSegmentsList.beginning = [app.CustomSegmentsList.beginning(1:app.SelectedRow); 0; app.CustomSegmentsList.beginning(app.SelectedRow+1:end)];  % Add beginning
                app.CustomSegmentsList.end = [app.CustomSegmentsList.end(1:app.SelectedRow); 0; app.CustomSegmentsList.end(app.SelectedRow+1:end)];                    % Add end
            end
            
            % Change the selected row to NaN or else a previouslly selected row will be kept as the one selected 
            app.SelectedRow = NaN;
            
            % Update the table
            updateCustomSegmentTable(app)
        end

        % Button pushed function: ExcludeRow
        function ExcludeRowPushed(app, event)
            % Exclude a row from the Custom Segment Table (a selected one
            % or the last)
            
            if size(app.CustomSegmentsList.beginning,1) == 1     % Don't exclude any row if there is only 1
                % Don't do anything!
            elseif isnan(app.SelectedRow) && size(app.CustomSegmentsList.beginning,1) ~= 0 % A row has not been selected yet (Exclude the last row if the table has at least 1 to be excluded)
                app.CustomSegmentsList.beginning(end) = []; % Clear beginning
                app.CustomSegmentsList.end(end) = [];       % Clear end
            else % A row has already been selected
                app.CustomSegmentsList.beginning(app.SelectedRow) = []; % Clear beginning
                app.CustomSegmentsList.end(app.SelectedRow) = [];       % Clear end
            end
            
            % Change the selected row to NaN or else a previouslly selected row will be kept as the one selected 
            app.SelectedRow = NaN;
            
            % Update the table
            updateCustomSegmentTable(app)
        end

        % Cell selection callback: CustomSegmentsTable
        function CustomSegmentsTableCellSelection(app, event)
            % Get which row from the table was selected
            app.SelectedRow = event.Indices(1); % Get the selected row and store it in the property SelectedRow  
        end

        % Cell edit callback: CustomSegmentsTable
        function CustomSegmentsTableCellEdit(app, event)
            % Store every single change in the property  CustomSegmentsList
            % Check which collumn has been changed
            if event.Indices(2) == 1    % Beginning
                app.CustomSegmentsList.beginning(event.Indices(1)) = event.NewData; % Store the new value
            else                        % End
                app.CustomSegmentsList.end(event.Indices(1)) = event.NewData;       % Store the new value
            end
            
            % Update the table
            updateCustomSegmentTable(app)
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            % Clear the label informing that the result has been saved since
            % a new set of results has been generated
            app.SavedLabel.Visible = false;
            
            % Get a title string the the file selection dialog box
            text = sprintf("Select 'GMM_Classification' file");
            % Opens the dialog box and enables the selection of a mat file
            [file,path] = uigetfile('*.mat',text,'MultiSelect','off');
            
            % Make sure that the app figure stay focused
            drawnow;
            figure(app.UIFigure)
            
            % Make sure that the user selected a file
            if ~isequal(file,0)
                
                % Get the filepath by concatenating the path and file
                app.GMM_fullfile = fullfile(path,file);                                
                load(app.GMM_fullfile,'GMM');   % Load the entire variable
                app.All_Sort = GMM.All_Sort;    % Store the All_Sort struct
                
                clear GMM
                
                % Show the label informing that the data has been loaded
                app.LoadedLabel.Visible = true;
                
                % Show the total length of loaded All_Sort
                app.TotalLengthLabel.Visible = true;
                app.TotalLengthLabel.Text = sprintf('Total Length: %d', length(app.All_Sort));
            end
        end

        % Button pushed function: RefreshButton
        function RefreshButtonPushed(app, event)
            % Call the app_architecture function, plots e organize the
            % results
            
            % Clear the label informing that the result has been saved since
            % a new set of results has been generated 
            app.SavedLabel.Visible = false;
            
            % Clean the property Architecture_result
            app.Architecture_result = [];
            
            % Get the selected radio button and act accordingly
            app.Selected_Radio_Button = app.SegmentationButtonGroup.Buttons([app.SegmentationButtonGroup.Buttons.Value]).Tag;
            
            % Save the Epoch Length in a Property
            app.Epoch_Length = app.rdStepSelecttheEpochLengthSecEditField.Value;
            
            % Check which option was selected
            switch app.Selected_Radio_Button
                case 'whole'        % Call the function to execute the architecture analysis without any segmentation
                    app.Architecture_result = app_architecture(app.All_Sort,app.rdStepSelecttheEpochLengthSecEditField.Value,0);
                case 'segmented'    % Uses the value informed by the user to execute the function  
                    app.Segment_Length = app.SegmentLengthHoursEditField.Value; % Stores the segment length value in a property
                    app.Architecture_result = app_architecture(app.All_Sort,app.rdStepSelecttheEpochLengthSecEditField.Value,app.SegmentLengthHoursEditField.Value);
                case 'custom'       % Uses the custom intervals informed by the user
                    % Get the matrix with the intervals from the table
                    % Custom Segmentation Table
                    segment_length = [app.CustomSegmentsList.beginning app.CustomSegmentsList.end];
                    % Call the function
                    app.Architecture_result = app_architecture(app.All_Sort,app.rdStepSelecttheEpochLengthSecEditField.Value,segment_length);                
            end
            
            % Call the function to plot the results
            plot_architecture_results(app)
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
               
            % Get some details such as epoch length and the segmentation type
            Segmentation_Type = cellstr(app.Selected_Radio_Button);  % Segmentation type
            Epoch_length = app.Epoch_Length;                % Epoch Length in seconds
            
            if strcmp(app.Selected_Radio_Button,'segmented')
                Segment_length = app.Segment_Length;         % Segment Length (when the option 2 has been selected)
            else
                Segment_length = NaN;                       % NaN value case any other option has been selected
            end
            Date_Time = cellstr(datestr(datetime));                           % Current date and time
            
            % Segment number
            Segment_number = cellstr(num2str([1:length(app.Architecture_result.AWAKE.total)]'));
            
            % Get the segments initial and final indices
            Segment_Beginning = app.Architecture_result.params.timestamps(:,1);
            Segment_End = app.Architecture_result.params.timestamps(:,2);
            % Time spent
            Time_Spent_AWAKE = app.Architecture_result.AWAKE.total;
            Time_Spent_NREM = app.Architecture_result.NREM.total;
            Time_Spent_REM = app.Architecture_result.REM.total;
            % Number of bouts per minute
            Number_Bouts_AWAKE = app.Architecture_result.AWAKE.Nbouts;
            Number_Bouts_NREM = app.Architecture_result.NREM.Nbouts;
            Number_Bouts_REM = app.Architecture_result.REM.Nbouts;
            % Bouts Duration
            Duration_Bouts_AWAKE = app.Architecture_result.AWAKE.duration_mean;
            Duration_Bouts_NREM = app.Architecture_result.NREM.duration_mean;
            Duration_Bouts_REM = app.Architecture_result.REM.duration_mean;
            
            % Create tables
            time_spent_table = table(Segment_Beginning,Segment_End,Time_Spent_AWAKE,Time_Spent_NREM,Time_Spent_REM,'RowNames',Segment_number);
            number_bouts_table = table(Segment_Beginning,Segment_End,Number_Bouts_AWAKE,Number_Bouts_NREM,Number_Bouts_REM,'RowNames',Segment_number);
            duration_bouts_table = table(Segment_Beginning,Segment_End,Duration_Bouts_AWAKE,Duration_Bouts_NREM,Duration_Bouts_REM,'RowNames',Segment_number);
            details_table = table(Epoch_length,Segmentation_Type,Segment_length,Date_Time);
            
            % Get the path where the Excel file is going to be saved (same as
            % the GMM_Classification
            [filepath,~,~] = fileparts(app.GMM_fullfile);
            
            % Create a filename for the Excel file using the filepath
            excel_filename = sprintf('Architecture_analysis_%s.xlsx',strrep(char(datetime('now')),':','_'));
            filename = fullfile(filepath,excel_filename);            
            
            % Convert to a unique Excel file (each table will be a sheet)
            writetable(time_spent_table,filename,'Sheet','Time Spent',"FileType","spreadsheet")        % Time spent
            writetable(number_bouts_table,filename,'Sheet','Number of bouts (min)',"FileType","spreadsheet")      % Number of bouts
            writetable(duration_bouts_table,filename,'Sheet','Duration of bouts (s)',"FileType","spreadsheet")    % Bouts duration
            writetable(details_table,filename,'Sheet','Details',"FileType","spreadsheet")           % Details
            
            % Show the label informing that the result has been saved
            app.SavedLabel.Visible = true;
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [150 50 679 685];
            app.UIFigure.Name = 'MATLAB App';

            % Create SegmentationButtonGroup
            app.SegmentationButtonGroup = uibuttongroup(app.UIFigure);
            app.SegmentationButtonGroup.Position = [279 16 389 155];

            % Create WholeDataButton
            app.WholeDataButton = uiradiobutton(app.SegmentationButtonGroup);
            app.WholeDataButton.Tag = 'whole';
            app.WholeDataButton.Text = '1 - Whole Data';
            app.WholeDataButton.Position = [11 122 102 22];
            app.WholeDataButton.Value = true;

            % Create SegmentedEquallyButton
            app.SegmentedEquallyButton = uiradiobutton(app.SegmentationButtonGroup);
            app.SegmentedEquallyButton.Tag = 'segmented';
            app.SegmentedEquallyButton.Text = '2 - Segmented Equally';
            app.SegmentedEquallyButton.Position = [11 35 143 22];

            % Create CustomSegmentsButton
            app.CustomSegmentsButton = uiradiobutton(app.SegmentationButtonGroup);
            app.CustomSegmentsButton.Tag = 'custom';
            app.CustomSegmentsButton.Text = '3 - Custom Segments';
            app.CustomSegmentsButton.Position = [216 124 138 22];

            % Create CustomSegmentsTable
            app.CustomSegmentsTable = uitable(app.SegmentationButtonGroup);
            app.CustomSegmentsTable.ColumnName = {'Beginning'; 'End'};
            app.CustomSegmentsTable.ColumnWidth = {72, 57};
            app.CustomSegmentsTable.RowName = {};
            app.CustomSegmentsTable.ColumnEditable = true;
            app.CustomSegmentsTable.CellEditCallback = createCallbackFcn(app, @CustomSegmentsTableCellEdit, true);
            app.CustomSegmentsTable.CellSelectionCallback = createCallbackFcn(app, @CustomSegmentsTableCellSelection, true);
            app.CustomSegmentsTable.Position = [215 10 131 104];

            % Create AddRow
            app.AddRow = uibutton(app.SegmentationButtonGroup, 'push');
            app.AddRow.ButtonPushedFcn = createCallbackFcn(app, @AddRowPushed, true);
            app.AddRow.FontSize = 18;
            app.AddRow.FontWeight = 'bold';
            app.AddRow.Position = [353 85 29 29];
            app.AddRow.Text = '+';

            % Create ExcludeRow
            app.ExcludeRow = uibutton(app.SegmentationButtonGroup, 'push');
            app.ExcludeRow.ButtonPushedFcn = createCallbackFcn(app, @ExcludeRowPushed, true);
            app.ExcludeRow.FontSize = 18;
            app.ExcludeRow.FontWeight = 'bold';
            app.ExcludeRow.Position = [353 47 29 31];
            app.ExcludeRow.Text = '-';

            % Create SegmentLengthHoursLabel
            app.SegmentLengthHoursLabel = uilabel(app.SegmentationButtonGroup);
            app.SegmentLengthHoursLabel.Position = [11 9 137 22];
            app.SegmentLengthHoursLabel.Text = 'Segment Length (Hours)';

            % Create SegmentLengthHoursEditField
            app.SegmentLengthHoursEditField = uieditfield(app.SegmentationButtonGroup, 'numeric');
            app.SegmentLengthHoursEditField.HorizontalAlignment = 'center';
            app.SegmentLengthHoursEditField.Position = [147 8 57 22];
            app.SegmentLengthHoursEditField.Value = 1;

            % Create ThewholedatawillbeconsideredAbargraphwillbegeneratedLabel
            app.ThewholedatawillbeconsideredAbargraphwillbegeneratedLabel = uilabel(app.SegmentationButtonGroup);
            app.ThewholedatawillbeconsideredAbargraphwillbegeneratedLabel.Position = [12 86 194 28];
            app.ThewholedatawillbeconsideredAbargraphwillbegeneratedLabel.Text = {'The whole data will be considered. '; 'A bar graph will be generated '};

            % Create RefreshButton
            app.RefreshButton = uibutton(app.UIFigure, 'push');
            app.RefreshButton.ButtonPushedFcn = createCallbackFcn(app, @RefreshButtonPushed, true);
            app.RefreshButton.Position = [109 63 58 22];
            app.RefreshButton.Text = 'Refresh';

            % Create SaveButton
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Position = [113 10 50 22];
            app.SaveButton.Text = 'Save';

            % Create LoadButton
            app.LoadButton = uibutton(app.UIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [16 169 52 22];
            app.LoadButton.Text = 'Load';

            % Create stStepLoadthefileGMM_ClassificationLabel
            app.stStepLoadthefileGMM_ClassificationLabel = uilabel(app.UIFigure);
            app.stStepLoadthefileGMM_ClassificationLabel.Position = [18 194 242 22];
            app.stStepLoadthefileGMM_ClassificationLabel.Text = '1st Step - Load the file ''GMM_Classification''';

            % Create thStepRefreshaccordingtothecurrentselectionLabel
            app.thStepRefreshaccordingtothecurrentselectionLabel = uilabel(app.UIFigure);
            app.thStepRefreshaccordingtothecurrentselectionLabel.Position = [19 82 238 28];
            app.thStepRefreshaccordingtothecurrentselectionLabel.Text = {'4th Step - Refresh according to the current '; 'selection'};

            % Create thStepSavetheplotsanddataLabel
            app.thStepSavetheplotsanddataLabel = uilabel(app.UIFigure);
            app.thStepSavetheplotsanddataLabel.Position = [19 34 187 22];
            app.thStepSavetheplotsanddataLabel.Text = '5th Step - Save the plots and data';

            % Create rdStepSelecttheEpochLengthSecEditFieldLabel
            app.rdStepSelecttheEpochLengthSecEditFieldLabel = uilabel(app.UIFigure);
            app.rdStepSelecttheEpochLengthSecEditFieldLabel.Position = [19 141 226 22];
            app.rdStepSelecttheEpochLengthSecEditFieldLabel.Text = '3rd Step - Select the Epoch Length (Sec)';

            % Create rdStepSelecttheEpochLengthSecEditField
            app.rdStepSelecttheEpochLengthSecEditField = uieditfield(app.UIFigure, 'numeric');
            app.rdStepSelecttheEpochLengthSecEditField.HorizontalAlignment = 'center';
            app.rdStepSelecttheEpochLengthSecEditField.Position = [110 117 56 22];
            app.rdStepSelecttheEpochLengthSecEditField.Value = 10;

            % Create ndStepSelectoneofthe3optionsbellowLabel
            app.ndStepSelectoneofthe3optionsbellowLabel = uilabel(app.UIFigure);
            app.ndStepSelectoneofthe3optionsbellowLabel.Position = [279 178 246 22];
            app.ndStepSelectoneofthe3optionsbellowLabel.Text = '2nd Step - Select one of the 3 options bellow';

            % Create LoadedLabel
            app.LoadedLabel = uilabel(app.UIFigure);
            app.LoadedLabel.Visible = 'off';
            app.LoadedLabel.Position = [81 169 49 22];
            app.LoadedLabel.Text = 'Loaded!';

            % Create SavedLabel
            app.SavedLabel = uilabel(app.UIFigure);
            app.SavedLabel.Visible = 'off';
            app.SavedLabel.Position = [189 10 43 22];
            app.SavedLabel.Text = 'Saved!';

            % Create TotalLengthLabel
            app.TotalLengthLabel = uilabel(app.UIFigure);
            app.TotalLengthLabel.Visible = 'off';
            app.TotalLengthLabel.Position = [140 169 117 22];
            app.TotalLengthLabel.Text = 'Total Length:';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, '% of Time Spent In Each State ')
            ylabel(app.UIAxes, '% of Time Spent')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.PlotBoxAspectRatio = [5.75238095238095 1 1];
            app.UIAxes.YLim = [0 100];
            app.UIAxes.XTickLabel = {''; ''; ''; ''; ''; ''; ''; ''; ''; ''};
            app.UIAxes.Position = [11 518 663 159];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.UIFigure);
            title(app.UIAxes_2, 'Number of Bouts per Minute')
            ylabel(app.UIAxes_2, 'Bouts/min')
            zlabel(app.UIAxes_2, 'Z')
            app.UIAxes_2.PlotBoxAspectRatio = [5.75238095238095 1 1];
            app.UIAxes_2.XTick = [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.UIAxes_2.XTickLabel = {''; ''; ''; ''; ''; ''; ''; ''; ''; ''};
            app.UIAxes_2.Position = [16 376 652 159];

            % Create UIAxes_3
            app.UIAxes_3 = uiaxes(app.UIFigure);
            title(app.UIAxes_3, 'Average Duration of Bouts')
            xlabel(app.UIAxes_3, 'X')
            ylabel(app.UIAxes_3, 'Seconds')
            zlabel(app.UIAxes_3, 'Z')
            app.UIAxes_3.Position = [5 223 667 159];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Sleep_archictecture_interface

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