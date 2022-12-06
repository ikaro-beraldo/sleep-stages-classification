classdef Check_GMM_clustering < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure        matlab.ui.Figure
        RunagainButton  matlab.ui.control.Button
        FinishButton    matlab.ui.control.Button
        StatusLabel     matlab.ui.control.Label
        ReadyLabel      matlab.ui.control.Label
        Image           matlab.ui.control.Image
    end

    
    properties (Access = private)        
        Data_combined       % Store the data which will be used by GMM
        Number_clusters     % Number of clusters
        Axes1               % Axes 1 handle
        Axes2               % Axes 2 handle
        Axes3               % Axes 3 handle
        Axes4               % Axes 4 handle
    end
    
    properties (Access = public)
        GMM_distribution    % GMM distribution after fitgmdist
        GMM_Prob            % GMM posterior probability values
        GMM_nLogL           % GMM negative loglikelihood
        Succeeded           % If the algorithm was succeeded or not
        Threshold_pos_prob  % Posterior probability minimum threshold value for all the GMM clusters
        Aproximate_Classification   % Define indices to each epoch based on the posterior probability
    end
    
    methods (Access = private)
        
        % Main function to run the GMM algorithm and store the results in
        % the app properties 
        function run_gmm(app)
            
            succeeded = false;
            counter = 1;
            while ~succeeded && counter <= 1000
                counter = counter + 1;  % Increase the counter value
                % Repeat until it runs without any error or until 1000 iterations
                % have been executed
                try
                    % Run the GMM algorithm
                    gmm_distribution = fitgmdist(app.Data_combined,app.Number_clusters);
                    succeeded = true;
                catch ME
                    succeeded = false;
                end
            end
            
            % After the loop has finished check if it was NOT succeeded and warn
            % the user about it.
            if ~succeeded
                % Creates an alert informing the user
                app.ReadyLabel.Text = ['GMM Algorithm was not successful. It was not possible to cluster the epochs of your dataset into 3 separate groups (AWAKE, NREM, REM)',"Press 'Run Again'."];
            %% FUNCTION TO CLEAR THE PLOTS                 
            end
            
            % Get the posterior probability values
            [gmm_Prob,gmm_nlogL] = posterior(gmm_distribution,app.Data_combined);
            
            % Insert the values into app properties
            app.GMM_distribution = gmm_distribution;
            app.GMM_Prob = gmm_Prob;
            app.GMM_nLogL = gmm_nlogL;
            app.Succeeded = succeeded;
            
            % Get an aproximate classification based on the higher
            % posterior probability value between the 3 clusters
            [~,app.Aproximate_Classification] = max(app.GMM_Prob,[],2);
            
        end
        
        % Function to plot the GMM results
        function plot_results(app)
            
            cla(app.Axes1)
            cla(app.Axes2)
            cla(app.Axes3)
            cla(app.Axes4)
            drawnow
            
            % Define the clusters
            cluster1 = find(app.Aproximate_Classification == 1);
            cluster2 = find(app.Aproximate_Classification == 2);
            cluster3 = find(app.Aproximate_Classification == 3);
            
            % Get the Probability Density Function
            gmPDF = @(x,y) arrayfun(@(x0,y0) pdf(app.GMM_distribution,[x0 y0]),x,y);
%             gmPDF.component2 = @(x,y) arrayfun(@(x0,y0) pdf(app.GMM_distribution{2},[x0 y0]),x,y);
%             gmPDF.component3 = @(x,y) arrayfun(@(x0,y0) pdf(app.GMM_distribution{3},[x0 y0]),x,y);
            
            % Plot 1 = all the epochs along with the avg and covariance for
            % each component
            hold(app.Axes1,'on')
            scatter(app.Axes1,app.Data_combined(:,1),app.Data_combined(:,2),2.5,"black")
            app.Axes1.XLim = [min(app.Data_combined(:,1)-0.5) max(app.Data_combined(:,1)+1)];
            app.Axes1.YLim = [min(app.Data_combined(:,2)-0.5) max(app.Data_combined(:,2)+0.5)];
            fcontour(app.Axes1,gmPDF,[app.Axes1.XLim app.Axes1.YLim])
            c = colorbar(app.Axes1,'east');
            c.Label.String = 'PDF';
            c.Label.HorizontalAlignment = 'right';
            hold(app.Axes1,'off')
            drawnow
            
            % Test
%             colors = parula;
%             colors_idx = floor(app.GMM_Prob(:,1).*(size(colors,1)-1))+1;
%             hold(app.Axes2,'on')
%             for idx=1:length(colors_idx)
%                 props = {'LineStyle','none','Marker','o','MarkerEdge',colors(colors_idx(idx),:),'MarkerSize',5};
%                 line(app.Axes2,[app.Data_combined(:,1),app.Data_combined(:,1)],[app.Data_combined(:,2),app.Data_combined(:,2)],props{:});
%             end
            
            % Plot 2 = the posterior probability value for component 1
            hold(app.Axes2,'on')
            scatter(app.Axes2,app.Data_combined([cluster2; cluster3],1),app.Data_combined([cluster2; cluster3],2),5,'black')
            scatter(app.Axes2,app.Data_combined(cluster1,1),app.Data_combined(cluster1,2),5,'red')
            app.Axes2.XLim = [min(app.Data_combined(:,1)-0.5) max(app.Data_combined(:,1)+0.5)];
            app.Axes2.YLim = [min(app.Data_combined(:,2)-0.5) max(app.Data_combined(:,2)+0.5)];
%             c1 = colorbar(app.Axes2,'east');
%             c1.Label.String = 'Posterior Probability';
            hold(app.Axes2,'off')
            drawnow
            
            % Plot 3 = the posterior probability value for component 2
            hold(app.Axes3,'on')
            scatter(app.Axes3,app.Data_combined([cluster1; cluster3],1),app.Data_combined([cluster1; cluster3],2),5,'black')
            scatter(app.Axes3,app.Data_combined(cluster2,1),app.Data_combined(cluster2,2),5,'red')
            app.Axes3.XLim = [min(app.Data_combined(:,1)-0.5) max(app.Data_combined(:,1)+0.5)];
            app.Axes3.YLim = [min(app.Data_combined(:,2)-0.5) max(app.Data_combined(:,2)+0.5)];
%             c2 = colorbar(app.Axes3,'east');
%             c2.Label.String = 'Posterior Probability';
            hold(app.Axes3,'off')
            drawnow
            
            %% If the number of clusters is lesser than 3
            if app.Number_clusters >= 3
                % Plot 4 = the posterior probability value for component 3
                hold(app.Axes4,'on')
                scatter(app.Axes4,app.Data_combined([cluster1; cluster2],1),app.Data_combined([cluster1; cluster2],2),5,'black')
                scatter(app.Axes4,app.Data_combined(cluster3,1),app.Data_combined(cluster3,2),5,'red')
                app.Axes4.XLim = [min(app.Data_combined(:,1)-0.5) max(app.Data_combined(:,1)+0.5)];
                app.Axes4.YLim = [min(app.Data_combined(:,2)-0.5) max(app.Data_combined(:,2)+0.5)];
                %             c3 = colorbar(app.Axes4,'east');
                %             c3.Label.String = 'Posterior Probability';
                hold(app.Axes4,'off')
                drawnow
            end
            
        end
        
        function create_axes(app,labels_info)
            
            % Allows the created axes to be turned into subplots
            app.UIFigure.AutoResizeChildren = 'off';
            
            % Create axes 1 and transform it into a suplot
            app.Axes1 = axes(app.UIFigure);
            subplot(2,2,1,app.Axes1)
            
            % Create axes 2 and transform it into a suplot
            app.Axes2 = axes(app.UIFigure);
            subplot(2,2,2,app.Axes2)
            
            % Create axes 1 and transform it into a suplot
            app.Axes3 = axes(app.UIFigure);
            subplot(2,2,3,app.Axes3)
            
            % Create axes 1 and transform it into a suplot
            app.Axes4 = axes(app.UIFigure);
            subplot(2,2,4,app.Axes4)
            
            % Get the labels info
            app.Axes1.XLabel.String = labels_info.xlabel;
            app.Axes2.XLabel.String = labels_info.xlabel;
            app.Axes3.XLabel.String = labels_info.xlabel;
            app.Axes4.XLabel.String = labels_info.xlabel;
            
            app.Axes1.YLabel.String = labels_info.ylabel;
            app.Axes2.YLabel.String = labels_info.ylabel;
            app.Axes3.YLabel.String = labels_info.ylabel;
            app.Axes4.YLabel.String = labels_info.ylabel;
            
            % Insert the titles
            app.Axes1.Title.String = 'Data Distribution';
            app.Axes2.Title.String = 'Component 1';
            app.Axes3.Title.String = 'Component 2';
            app.Axes4.Title.String = 'Component 3';
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, data_combined, number_clusters, labels_info)
            % Store the data into app properties
            app.Data_combined = data_combined;
            app.Number_clusters = number_clusters;
            
            % Create the for axes
            create_axes(app,labels_info)
            
            % Run the first iteration for the GMM algorithm            
            run_gmm(app)
            
            % Plot the results
            plot_results(app)
                        
            % Switch to an alternative render engine if there is more than
            % 1500 epochs
%             if length(data_combined(:,1)) > 1500
%                 opengl software
%             end
            
            
        end

        % Button pushed function: RunagainButton
        function RunagainButtonPushed(app, event)
            % Function to run the GMM algorithm again and plot its results
            app.ReadyLabel.Visible = 'off';
            app.Image.Visible = 'on';
            drawnow
            
            run_gmm(app)        % Run
            plot_results(app)   % Plot
            
            app.ReadyLabel.Visible = 'on';
            app.Image.Visible = 'off';
            drawnow
            
        end

        % Button pushed function: FinishButton
        function FinishButtonPushed(app, event)
            % Function to get the GMM results to the
            % GMM_Classifier_Training_fixed and define a starting threshold
            % for posterior probability
            
            % Defining the GMM.Probability distribution for each state
            n_iterations = 89; % number of total iteration
            app.Threshold_pos_prob = 0.9; % It will decrease 0.01 each iteration
            for ii = 1:n_iterations
                % Check if the clusterization was successful
                if ~isempty(find(app.GMM_Prob(:,1)>app.Threshold_pos_prob,1)) && ~isempty(find(app.GMM_Prob(:,2)>app.Threshold_pos_prob,1)) && ~isempty(find(app.GMM_Prob(:,1)>app.Threshold_pos_prob,1))
                    app.Succeeded = true;
                    break  % Stop the current loop to proceed
                else
                    app.Threshold_pos_prob = app.Threshold_pos_prob - 0.01;
                    app.Succeeded = false;
                end
                
            end
            
            uiresume(app.UIFigure)  % Resume the execution of the code right after the execution of this app
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 1];
            app.UIFigure.Position = [100 100 784 601];
            app.UIFigure.Name = 'MATLAB App';

            % Create RunagainButton
            app.RunagainButton = uibutton(app.UIFigure, 'push');
            app.RunagainButton.ButtonPushedFcn = createCallbackFcn(app, @RunagainButtonPushed, true);
            app.RunagainButton.Position = [286 12 100 22];
            app.RunagainButton.Text = 'Run again';

            % Create FinishButton
            app.FinishButton = uibutton(app.UIFigure, 'push');
            app.FinishButton.ButtonPushedFcn = createCallbackFcn(app, @FinishButtonPushed, true);
            app.FinishButton.Position = [430 12 100 22];
            app.FinishButton.Text = 'Finish';

            % Create StatusLabel
            app.StatusLabel = uilabel(app.UIFigure);
            app.StatusLabel.Position = [51 8 43 22];
            app.StatusLabel.Text = 'Status:';

            % Create ReadyLabel
            app.ReadyLabel = uilabel(app.UIFigure);
            app.ReadyLabel.Position = [102 8 44 22];
            app.ReadyLabel.Text = 'Ready!';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Visible = 'off';
            app.Image.Position = [71 1 105 105];
            app.Image.ImageSource = 'Loader.gif';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Check_GMM_clustering(varargin)

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