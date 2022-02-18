%SAVETMP Save workspace variables to file in temp directory. 
%   SAVETMP(FILENAME) stores all variables from the current workspace in a
%   MATLAB formatted binary file (MAT-file) called FILENAME.
%
%   SAVETMP(FILENAME,VARIABLES) stores only the specified variables.
% 
%   Temp directory for MAC OSX and Linux machines is /tmp/.
% 
%   Temp directory for Windows machines is stored in environment variable 
%   %TEMP%. If this variable doesn't exist, then temp directory is set to
%   C:\TEMP\. If in this case C:\TEMP\ doesn't exist, it is created.
% 
%   Usage of SAVETMP is completely identical to the usage of SAVE
%
%   See also TEMPDIR, LOADTMP, ERASETMP

% Copyright 2011, Vladimir Filimonov (ETH Zurich).
% $Date: 11-Jul-2011 12:02:37 $ 

function savetmp(fname, append, varargin)

if nargin==0
    fname = 'matlab';
end

vars = '';
for ii = 1:length(varargin)
    if ~isa(varargin{ii}, 'char')
        error(['Input #' num2str(ii) ' is not a valid variable name'])
    end
    vars = [vars ', ''' varargin{ii} '''']; %#ok<AGROW>
end

tmp = tempdir;

[~, name, ~] = fileparts(fname);

if append
    CMD = sprintf('save(''%s%s.mat''%s,"-append");', tmp, name, vars);
else
    CMD = sprintf('save(''%s%s.mat''%s);', tmp, name, vars);
end

evalin('caller', CMD);
