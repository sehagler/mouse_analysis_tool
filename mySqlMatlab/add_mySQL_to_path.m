% This script adds the mySQL directory to the Matlab path
% It should be executed under the mySQL directory

if ~exist('mysql.cpp','file')
    error ('This script must be executed inside the mySQL directory!');
end
MYSQL_HOME = pwd;

% genpath creates a list of all subdirectories.
addpath(genpath(MYSQL_HOME))
savepath
