%% Ikaro Beraldo - 23/11/20 Function which gets the polynomial degree value from the main app and aplies it with the function detrend from MATLAB library
% blocked_data = app_period_separation(data,epoch_length)
% blocked_data -> output containg the data after processing
% data -> original data which is going to be processed
% epoch_length -> value (scalar or string) containing the epoch length in
% seconds
%%

function blocked_data = app_separate_in_epochs(data,epoch_length)

% Check if the data is a linear vector
if size(data.data,1) ~= 1 && size(data.data,2) ~= 1 % If it is not a vector
    disp('Tha separation into epochs was not possible. The data inserted must have the following dimensions: 1 x n')
else
    % Get the total number of epochs
    epoch_length_samples = epoch_length * data.sampling_frequency;
    number_of_epochs = floor(length(data.data) / epoch_length_samples);
    
    % Exclude the additional samples from the data
    data.data(epoch_length_samples * number_of_epochs + 1 : end) = [];
    
    % Separate in epochs
    blocked_data = reshape(data.data,epoch_length_samples,number_of_epochs)';    
end

end