function startup

% Get the path for local environment
rootpath = fileparts(mfilename('fullpath'));

% Add relevant matlab folders
addpath(rootpath);
addpath(fullfile(rootpath, 'experiment'));
addpath(fullfile(rootpath, 'functions'));
addpath(fullfile(rootpath, 'functions', 'BA'));
addpath(fullfile(rootpath, 'functions', 'export_fig'));
addpath(fullfile(rootpath, 'functions', 'graph'));
addpath(fullfile(rootpath, 'functions', 'util'));
addpath(fullfile(rootpath, 'scripts'));
addpath(fullfile(rootpath, 'scripts', 'hybrid'));
addpath(fullfile(rootpath, 'scripts', 'wpt'));

% Add parent folder
addpath(fileparts(rootpath));

% Check if there is a live java build
% javapath = fullfile(rootpath, '..', 'jCoCoA', 'bin');
javapath = fullfile(getenv('path_develop'), 'CoCoA', 'jCoCoA', 'bin');
if (exist(javapath, 'dir'))
    % Add the live java folder
    javaaddpath(javapath)
else
    % Add the library
    javalib = fullfile(rootpath, 'lib', 'jCoCoA.jar');
    javaaddpath(javalib);
end

dependOnLib(fullfile(rootpath, 'lib', 'gson-2.7.jar'), ...
    'http://central.maven.org/maven2/com/google/code/gson/gson/2.7/gson-2.7.jar');

end
