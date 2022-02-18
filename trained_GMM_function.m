function [GMM_Prob,GMM_nlogL,threshold_pos_prob,succeeded] = trained_GMM_function(data_combined,number_clusters,training_dataset)

% Pre-allocate the results
GMM_Prob = [];
GMM_nlogL = [];
threshold_pos_prob = 0.9;   % Define the posterior probability minimum threshold (it might change)

gmm_loop = 1;
succeeded = false;
% Keep calculating the GMM until a good cluster is formed (max 1000
% iterations) or the task is succeeded
while gmm_loop <= 1000 && ~succeeded
    gmm_loop = gmm_loop + 1;    % Add 1 iteration
    
    % Try a set of commands to run the GMM algorithm and check if the 3
    % clusters formed have at least 1 epoch with a minimum posterior
    % probability value
    try
        % Fitting trained data
        GMM_distribution = fitgmdist(data_combined,number_clusters,...
            'Start',training_dataset);
        succeeded = true;
        
        % Computing Posterior GMM Probability to each time bin
        [GMM_Prob,GMM_nlogL] = posterior(GMM_distribution,data_combined);
        
        clear tr_* fitted_GMM aux*
        
        % Get GMM parameters
        GMM.GMM_distribution = GMM_distribution;
        GMM.Prob.All = GMM_Prob;
        GMM.nlogL = GMM_nlogL;
        
        % Make sure that every single one of the 3 clusters has at least 1
        % period with posterior probabily higher than 0.5
        if ~isempty(find(GMM.Prob.All(:,1) > 0,1)) &&...
                ~isempty(find(GMM.Prob.All(:,2) > 0,1)) &&...
                ~isempty(find(GMM.Prob.All(:,3) > 0,1))
            break   % Terminate the execution of the current loop
        end
        
        
        % Check if all the clusters have at least 1 epoch with posterior
        % probability higher than 90%. If it is not the case, if the user selected
        % the option to keep repeating the clustering, it will do 100 more
        % iterations
        if isempty(find(GMM.Prob.All(:,1)>.9,1)) || isempty(find(GMM.Prob.All(:,2)>.9,1)) || isempty(find(GMM.Prob.All(:,3)>.9,1))
            add_iterations_trigger = true;
        else
            add_iterations_trigger = false;
        end
        
        % Defining the GMM.Probability distribution for each state
        n_iterations = 89; % number of total iteration
        threshold_pos_prob = 0.9; % It will decrease 0.01 each iteration
        if add_iterations_trigger  % If it's necessary another set of iterations
            for ii = 1:n_iterations
                [GMM_Prob,GMM_nlogL] = posterior(GMM_distribution,data_combined);
                % Check if the clusterization was successful
                if ~isempty(find(GMM.Prob.All(:,1)>threshold_pos_prob,1)) && ~isempty(find(GMM.Prob.All(:,2)>threshold_pos_prob,1)) && ~isempty(find(GMM.Prob.All(:,3)>threshold_pos_prob,1))
                    succeeded = true;
                    break  % Stop the current loop to proceed
                else
                    threshold_pos_prob = threshold_pos_prob - 0.01;
                    succeeded = false;
                end
            end
        end
        
    catch ME % Catch a possible error
        succeeded = false;      
        
    end    
end

end