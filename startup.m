function startup

% Get the path for local environment
rootpath = fileparts(mfilename('fullpath'));

% Add relevant matlab folders
addpath(rootpath);
addpath(fullfile(rootpath, 'functions'));
addpath(fullfile(rootpath, 'functions', 'util'));
addpath(fullfile(rootpath, 'functions', 'BA'));
addpath(fullfile(rootpath, 'functions', 'graph'));
addpath(fullfile(rootpath, 'scripts'));

% Check if there is a live java build
javapath = fullfile(getenv('path_java'), 'jCoCoA', 'bin');
if (exist(javapath, 'dir'))
    % Add the live java folder
    javaaddpath(javapath)
else
    % Add the library
    javaaddpath(fullfile(rootpath, 'lib', 'org.anon.cocoa_1.1.jar'));
end

end