clc
clear
close all

ctrl_para.dev_env = 'linux';
switch ctrl_para.dev_env
    case 'linux'
        addpath(genpath(fullfile([pwd '/method'])));
    case 'windows'
        addpath(genpath(fullfile([pwd '\method'])));
end

Initialization3; 

reid_feedback();
