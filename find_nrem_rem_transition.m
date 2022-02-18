%% Function to find the transition periods according to the posterior probability values inside the REM and nREM clusters
function [GMM,GMM_Transition_NREM_REM] = find_nrem_rem_transition(GMM,GMM_NREM_All_Sort,GMM_REM_All_Sort)

% Stablished threshold values
threshold.upper.rem = 0.75; 
threshold.lower.rem = 0.25;
threshold.upper.nrem = 0.75; 
threshold.lower.nrem = 0.25;

% Get each state epochs
NREM = find(GMM_NREM_All_Sort == 1);
REM = find(GMM_REM_All_Sort == 1);

%% Check whether the posterior probability thresholds are higher or lower than the upper and lower thresholds defined above

%NREM
if GMM.Selected_Threshold.NREM_value < threshold.lower.nrem
    threshold.lower.nrem = GMM.Selected_Threshold.NREM_value;   % Change the selected threshold value
end

%REM
if GMM.Selected_Threshold.REM_value < threshold.lower.rem
    threshold.lower.rem = GMM.Selected_Threshold.REM_value;   % Change the selected threshold value
end

%%

% Find the nREM cluster epochs which corresponds to the stablished
% conditions
GMM.Transition.NREM = NREM(GMM.Prob.NREM(GMM_NREM_All_Sort) >= threshold.lower.nrem & GMM.Prob.NREM(GMM_NREM_All_Sort) < threshold.upper.nrem);

% Find the REM cluster epochs which corresponds to the stablished
% conditions
GMM.Transition.REM = REM(GMM.Prob.REM(GMM_REM_All_Sort) >= threshold.lower.rem & GMM.Prob.REM(GMM_REM_All_Sort) < threshold.upper.rem);

% Get only the unique epochs
GMM.Transition.unique = unique([GMM.Transition.REM; GMM.Transition.NREM]);

% Find the epochs in which the WAKE posterior probability is higher
GMM.Transition.selected = GMM.Transition.unique(GMM.Prob.NREM(GMM.Transition.unique) > GMM.Prob.AWAKE(GMM.Transition.unique) & GMM.Prob.REM(GMM.Transition.unique) > GMM.Prob.AWAKE(GMM.Transition.unique));

% Get the final transition epochs
GMM_Transition_NREM_REM = zeros(length(GMM_NREM_All_Sort),1);
GMM_Transition_NREM_REM(GMM.Transition.selected) = 1;
end