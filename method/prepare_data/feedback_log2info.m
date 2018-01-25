%% adjust member variables in feedback_info

clear
clc
close all


dev_env = 'linux';

switch dev_env
    case 'windows'
        % step 1: nv->test feedback
        src_dir = '.\data\viper\feedback\log\';
        dst_dir = '.\data\viper\feedback\mmap\';
        src_files = dir([src_dir, '*.mat']);
        file_num = length(src_files);


        for i=1:file_num
            i
            load([src_dir '\' src_files(i).name]);
            feedback_info = feedback_log;
            save([dst_dir '\' src_files(i).name], 'feedback_info');
        end
        
    case 'linux'
        % step 1: nv->test feedback
        src_dir = './data/viper/feedback/log/';
        dst_dir = './data/viper/feedback/mmap/';
        src_files = dir([src_dir, '*.mat']);
        file_num = length(src_files);


        for i=1:file_num
            i
            load([src_dir '/' src_files(i).name]);
            feedback_info = feedback_log;
            save([dst_dir '/' src_files(i).name], 'feedback_info');
        end
end

