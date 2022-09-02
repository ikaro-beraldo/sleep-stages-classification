% Function to change the data fit accordingly to the training dataset
function data_combined_fitted = check_best_fit(data_combined,trained_LFP,trained_EMG,fit_type)

% Separate X and Y elements
data_combined_struct.x = data_combined(:,1);
data_combined_struct.y = data_combined(:,2);

switch fit_type
    case 1  % Subtract median
        % Change the distribution to match the training data distribution
        difference_theta_delta = nanmedian(trained_LFP) - nanmedian(data_combined_struct.y);
        difference_emg = nanmedian(trained_EMG) - nanmedian(data_combined_struct.x);
        
        % Data
        data_combined_fitted(:,1) = data_combined_struct.x + difference_emg;
        data_combined_fitted(:,2) = data_combined_struct.y + difference_theta_delta;
    case 2  % Subtract average
        % Change the distribution to match the training data distribution
        difference_theta_delta = nanmean(trained_LFP) - nanmean(data_combined_struct.y);
        difference_emg = nanmean(trained_EMG) - nanmean(data_combined_struct.x);
        
        % Data
        data_combined_fitted(:,1) = data_combined_struct.x + difference_emg;
        data_combined_fitted(:,2) = data_combined_struct.y + difference_theta_delta;
    case 3  % Subtract minimum value
        % Change the distribution to match the training data distribution
        difference_theta_delta = min(trained_LFP) - min(data_combined_struct.y);
        difference_emg = min(trained_EMG) - min(data_combined_struct.x);
        
        % Data
        data_combined_fitted(:,1) = data_combined_struct.x + difference_emg;
        data_combined_fitted(:,2) = data_combined_struct.y + difference_theta_delta;
end
end
