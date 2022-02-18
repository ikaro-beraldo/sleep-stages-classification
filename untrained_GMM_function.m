function [GMM_Prob,GMM_nlogL,GMM_Threshold_pos_prob,succeeded] = untrained_GMM_function(data_combined,number_clusters,labels_info)

% Pre-allocate the results
GMM_Prob = [];
GMM_nlogL = [];
succeeded = false;

% Call the app to check to GMM clustering
app_handle = Check_GMM_clustering(data_combined,number_clusters,labels_info);
uiwait(app_handle.UIFigure)  % Wait for the user to press the 'Finish' button

% Get GMM parameters
GMM_distribution = app_handle.GMM_distribution;
GMM_Prob = app_handle.GMM_Prob;
GMM_nlogL = app_handle.GMM_nLogL;
succeeded = app_handle.Succeeded;
GMM_Threshold_pos_prob = app_handle.Threshold_pos_prob;

% Delete the Check_GMM_clustering app
app_handle.delete;
end