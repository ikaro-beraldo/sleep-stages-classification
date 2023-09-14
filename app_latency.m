%% Get latency to nREM and REM sleep - Mininum 20 seconds or 2 blocks of 10 seconds

% All_Sort = vector with classification code (WK = 3; NREM = 2; REM = 1
% Epoch length = epoch length in seconds (ex: 10 or 30)
% Segment length in hours (0 = whole data; scalar (~0) = segment length in
% hours; matrix = segments timestamps [beginning end; beginning end...]

function latency = app_latency(All_Sort,epoch_length,segment_length)

% Define some important parameters
params.epoch_length = epoch_length;
params.total_length = length(All_Sort);

%If get REM only just after the true periods of sleep beginning
rem_only_after_sleep = true;

%Define a definite sleep bound (inside a window of 5 min, 80% of
%the periods are nREM sleep
n_val = 5;
percentage = 0.80;

% n_consecutive = number of consecutive seconds in a specific state
n_consecutive_rem = 10; %seconds

% Check if it will be segmented or not (0 = whole data; 1 = segmented data)
if segment_length == 0
    params.segment_length_blocks = params.total_length;                             % Length of each segment in number of blocks
    params.timestamps(1,1) = 1;                     % Get the beginning indices
    params.timestamps(1,2) = params.total_length;   % Get the end indices
    params.n_segments = size(params.timestamps,1);  % Get number of indices
elseif numel(segment_length) > 1 % Check if it is a matrix with [Beginning End] of events
    params.timestamps(:,1) = segment_length(:,1);
    params.timestamps(:,2) = segment_length(:,2);
    params.n_segments = size(params.timestamps,1);
else % A specific number of segments
    % Get the indices from the segments (The last segment might have less
    % epochs than the other ones)
    params.segment_length_blocks = floor(segment_length * (3600 / params.epoch_length));   % Length of each segment in number of blocks
    params.timestamps(:,1) = 1:params.segment_length_blocks:params.total_length;    % Get the beginning indices
    params.timestamps(:,2) = [params.timestamps(2:end,1)-1; params.total_length];   % Get the end indices
    params.n_segments = size(params.timestamps,1);  % Get number of indices
end

% Pre-allocate variables
first_rem_idx = nan(params.n_segments,1);
first_nrem_idx = nan(params.n_segments,1);

% Segments loop
for seg_idx = 1:params.n_segments
    
    % Get the the all sort values from a specific segment
    All_Sort_day = All_Sort(params.timestamps(seg_idx,1):params.timestamps(seg_idx,2));    
    
    minutes = n_val*(60/epoch_length);
    for ww = 1:length(All_Sort_day) - n_val* (60/epoch_length)-1
        if length(find(All_Sort_day(ww:ww+minutes) == 2 | All_Sort_day(ww:ww+minutes) == 1)) >= floor(minutes*percentage)
            if All_Sort_day(ww) == 2
                beginning = ww;
                break
            end
        end
    end
    
    % Get the first NREM epoch (inside a definitive bout)
    first_nrem_idx(seg_idx,1) = beginning;
    
    if rem_only_after_sleep == true
        %Define a 'new' All_Sort for rem based on the beginning of sleep
        All_Sort_day = All_Sort(params.timestamps(seg_idx,1)+first_nrem_idx(seg_idx,1) : params.timestamps(seg_idx,2));
    end
    
    %Get the first REM (n_state = 1);
    n_state = 1;
    N = floor(n_consecutive_rem/epoch_length)-1; % Required number of consecutive numbers following a first one
    t = find(All_Sort_day == n_state);
    if isempty(t)
        first_rem_idx(seg_idx,1) = NaN;
    else
        first_rem_idx(seg_idx,1) = t(1);
    end
    
end

% Convert epochs number to minutes
latency.first_nrem_idx = first_nrem_idx;
latency.first_rem_idx = first_rem_idx;
latency.first_nrem_minutes = first_nrem_idx * epoch_length/60;
latency.first_rem_minutes = first_rem_idx * epoch_length/60;

end
