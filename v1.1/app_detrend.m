%% Ikaro Beraldo - 23/11/20 Function which gets the polynomial degree value from the main app and aplies it with the function detrend from MATLAB library
% detrended_data = app_detrend(data,polyn_degree)
% detrended_data -> output containg the data after processing
% data -> original data which is going to be processed
% polyn_degree -> value (scalar or string) containing the polynomial degree
%%

function detrended_data = app_detrend(data,polyn_degree)
    detrended_data = detrend(data, polyn_degree);
end