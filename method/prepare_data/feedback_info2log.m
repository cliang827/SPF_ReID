%% adjust member variables in feedback_info

clear
clc
close all



% step 1: nv->test feedback
dst_dir = '.\data\viper\feedback\log\';
src_dir = '.\data\viper\feedback\mmap\';
src_files = dir([src_dir, '*.mat']);
file_num = length(src_files);


for i=1:file_num
    i
    load([src_dir '\' src_files(i).name]);
    feedback_log = feedback_info;
    save([dst_dir '\' src_files(i).name], 'feedback_log');
end

