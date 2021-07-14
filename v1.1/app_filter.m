%% Ikaro Beraldo - 23/11/20 Function which gets the high-pass, low-pass and notch frequencies and apply the filter according to the filter type
% filtered_data = app_filter(data,filter_type,high_pass_freq,low_pass_freq,notch_freq)
% filtered_data -> output containg the data after processing
% data -> original data which is going to be processed
% filter_type -> value (string) containing the filter type
% high_pass -> value (Hz) of the high-pass parameter
% low_pass -> value (Hz) of the low-pass parameter
% notch -> value (Hz) of the notch parameter
% input_sampling_freq (Hz) -> data sampling frequency inserted by the user
% (optional)
%%

function [filtered_data, filter_params] = app_filter(data,data_sampling_frequency,filter_type,high_pass_freq,low_pass_freq,notch_freq,input_sampling_freq)
% Get the sampling frequency (if input_sampling_frequency value is false,
% the sampling frequency is going to be automatically extracted from
% variables
if input_sampling_freq % If the input sampling frequency have been inserted by the user
    sampling_frequency = input_sampling_freq;   % Gets the sampling frequency from the user input    
else
    sampling_frequency = data_sampling_frequency;   % Gets the sampling frequency from the variable itself
end

% Filter parameters
filter_params = struct('high',[],'low',[],'notch',[]);

% Check if the data is a row vector (mandatory, since eegfilt function only
% accepts row vectors
if isrow(data)
    % Good to go!
else
    % Change it to a row vector
    data = data';
end

% The algorithm is going to use the sampling frequency associated with the data (default)
% Act accordingly to the filter type
switch filter_type
    case 'band'     % If it is a band-pass filter
        if low_pass_freq > high_pass_freq   % The low-pass frequency must be higher than the high-pass frequency
            % First the high-pass and then, the low-pass
            filtered_data = eegfilt2(data,sampling_frequency,high_pass_freq,[]);
            filtered_data = eegfilt2(filtered_data,sampling_frequency,[],low_pass_freq);
        else
            % If the low-pass is lower than the high-pass frequency a
            % warning message is shown asking if the two parameters are to
            % be inverted
            answer = questdlg('The low-pass frequency must be higher than the high-pass frequency. Do you want to invert both frequencies?', ...
                'Yes','Cancel','Cancel');
            switch answer
                case 'Yes'  % If the user chooses 'Yes' the parameters are inverted and the data is filtered
                    filtered_data = eegfilt(data,sampling_frequency,low_pass_freq,[]);
                    filtered_data = eegfilt(filtered_data,sampling_frequency,[],high_pass_freq);
                case 'Cancel'   % If the user chooses 'Cancel' a warning box is shown, but the data is not filtered
                    msgbox('The data could not be filtered', 'Error','error');
            end
        end
        % Get the params to be inserted into the filtered data
        filter_params.high = high_pass_freq;
        filter_params.low = low_pass_freq;
        
    case 'notch'    % notch filter
        filtered_data = zeros(size(data,1),size(data,2)); % Pre-alocated matrix
        for epoch = 1:size(data,1) % Repeats the notch filtering for each single epoch (rows)
            % Custom notch-filter function (notch width = 0.007)
            filtered_data(epoch,:) = notchfilter(data(epoch,:),sampling_frequency,notch_freq);
        end
        % Get the params to be inserted into the filtered data
        filter_params.notch = notch_freq;
    case 'high'     % high-pass filter
        filtered_data = eegfilt(data,sampling_frequency,[],high_pass_freq);
        % Get the params to be inserted into the filtered data
        filter_params.high = high_pass_freq;
    case 'low'      % low-pass filter
        filtered_data = eegfilt(data,sampling_frequency,low_pass_freq,[]);
        % Get the params to be inserted into the filtered data
        filter_params.high = low_pass_freq;
end
end