%% Ikaro Beraldo - 23/11/20 Function which gets the output and input sampling frequencies from the main app, calculates the ratio, and aplies it with the function decimate from MATLAB library
% decimated_data = app_decimate(data,output_sampling_freq,input_sampling_freq_optional)
% decimated_data -> output containg the data after processing
% data -> original data which is going to be processed
% output_sampling_freq -> value (scalar) containing the sampling frequency
% of the data after processing
% input_sampling_freq_optional -> value (scalar) containing the sampling frequency
% of the data before processing (optional)

%%

function decimated_data = app_decimate(data,data_sampling_frequency,output_sampling_freq,input_sampling_freq_optional)

% If the input sampling frequency is empty, the algorithm is going to use
% the sampling frequency associated with the data (default)
if isempty(input_sampling_freq_optional)
    % Gets the ratio (input/output sampling frequencies)
    freq_input_output_ratio = data_sampling_frequency/output_sampling_freq;
else
    % Gets the ratio (input/output sampling frequencies)
    freq_input_output_ratio = input_sampling_freq_optional/output_sampling_freq;
end

% Uses the Matlab function 'decimate' to resample the signal using the
% ratio calculated above
decimated_data = decimate(data, freq_input_output_ratio);

end