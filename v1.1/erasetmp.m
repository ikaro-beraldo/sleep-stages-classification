%ERASETMP Erase file in temp directory
%   ERASETMP(FILENAME) erases file FILENAME in temp directory
%
%   See also TEMPDIR, SAVETMP, LOADTMP, DELETE

% Copyright 2011 by Vladimir Filimonov (ETH Zurich).
% $Date: 11-Jul-2011 20:05:49 $

function erasetmp(file_names)

if iscell(file_names)    % Check if it is a cell
    n_loop = length(file_names); % Get the total number of iterations
end

tmp = tempdir;

% Erasing loop
for n = 1:n_loop
    fname = file_names{n};  %Gettin
    
    if exist([tmp fname '.mat'], 'file')
        delete([tmp fname '.mat'])
        disp([tmp fname '.mat deleted'])
        
    elseif exist([tmp fname], 'file')
        delete([tmp fname])
        
    else
        warning([tmp fname ' was not found'])        
    end
end
end