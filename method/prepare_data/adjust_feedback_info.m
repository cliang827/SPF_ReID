%% adjust member variables in feedback_info

clear
clc
close all



% step 1: nv->test feedback
src_dir = '.\data\viper_pcm14\feedback\log\';
src_dir2 = '.\data\viper_pcm14\feedback\mmap\';
src_files = dir([src_dir, '*.mat']);
file_num = length(src_files);


for i=1:file_num
    i
    load([src_dir '\' src_files(i).name]);
    feedback_log = rmfield(feedback_info, {'operator', 'query_times'});
    [~, stat_info] = feedback_stat(feedback_log);
    for j=1:stat_info.gallery_num
        if isfield(feedback_log.feedback_details{j}, 'operator')
            operator = feedback_log.feedback_details{j}.operator;
            feedback_log.feedback_details{j}.operator = {operator; operator};
        else
            feedback_log.feedback_details{j}.operator = {'syan'; 'syan'};
        end
    end
    save([src_dir '\' src_files(i).name], 'feedback_log');
    
    feedback_info = feedback_log;
    save([src_dir2 '\' src_files(i).name], 'feedback_info');
end

