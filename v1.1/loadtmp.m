%LOADTMP Load data from MAT-file into workspace from file in temp directory
%   S = LOADTMP(FILENAME) loads the variables from a MAT-file into a 
%   structure array, or data from an ASCII file into a double-precision 
%   array.
%
%   S = LOADTMP(FILENAME, VARIABLES) loads only the specified variables 
%   from a MAT-file.  
% 
%   Temp directory for MAC OSX and Linux machines is /tmp/.
% 
%   Temp directory for Windows machines is stored in environment variable 
%   %TEMP%. If this variable doesn't exist, then temp directory is set to
%   C:\TEMP\.
% 
%   Usage of LOADTMP is completely identical to the usage of LOAD
%
%   See also TEMPDIR, SAVETMP, ERASETMP

% Copyright 2011 by Vladimir Filimonov (ETH Zurich).
% $Date: 11-Jul-2011 12:02:37 $ 

function S = loadtmp(fname, varargin)

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
CMD = sprintf('load(''%s%s.mat''%s);', tmp, name, vars);

if nargout==0
    evalin('caller', CMD);
else
    S = evalin('caller', CMD);
end