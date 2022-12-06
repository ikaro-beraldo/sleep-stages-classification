% Function to add the missing period (artifacts) in GMM posterior
% probability matrix as zeros (0)
function GMM = fix_gmm_artifacts(GMM,artifact,x,number_clusters)

% Check if there is any artifact
if isempty(artifact.LFP_epoch)
    return % Ends the function execution if there is not any artifact
end

% Pre-allocate the new GMM.Prob.All matrix
% GMM_prob_all = zeros(length(x),number_clusters);

%% Define the segments

if artifact.LFP_epoch(1) ~= 1
    % Creat a matrix of segments timestamps
    segments_timestamps = [1 artifact.LFP_epoch(1)-1; artifact.LFP_epoch(1:end-1)+1 artifact.LFP_epoch(2:end)-1];
else % If the first artifact is the period 1
    segments_timestamps = [artifact.LFP_epoch(1:end-1)+1 artifact.LFP_epoch(2:end)-1];    
end

% Check if the last artifact corresponds to the last epoch
if artifact.LFP_epoch(end) ~= length(x)
    segments_timestamps = [segments_timestamps; artifact.LFP_epoch(end)+1 length(x)];
end

% Take into account that the artifact periods are missing
subtract_vector = (0:size(segments_timestamps,1)-1)';
segments_timestamps_fixed = segments_timestamps - subtract_vector;

%% Loop

for lo = 1:size(segments_timestamps,1)
    % Get the GMM posterior probability values for each non artifact period
    GMM_prob_all(segments_timestamps(lo,1):segments_timestamps(lo,2),:)...
        = GMM.Prob.All(segments_timestamps_fixed(lo,1):segments_timestamps_fixed(lo,2),:);
end

% Get the linear indices that will receive the value 0
nan_index = sub2ind(size(GMM_prob_all),artifact.LFP_epoch',ones(1,length(artifact.LFP_epoch)));
% Insert nan
GMM_prob_all(nan_index) = nan;

% Insert the values [0 0 0] for the artifact periods
GMM_prob_all(isnan(GMM_prob_all(:,1)),:) = 0; 

% Organize the new posterior probability values
GMM.Prob.All_no_artifacts = GMM.Prob.All;
GMM.Prob.All = GMM_prob_all;

end