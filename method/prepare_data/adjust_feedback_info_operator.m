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
    [~, stat_info] = feedback_stat(feedback_log);
    for j=1:stat_info.gallery_num
        gallery_name = feedback_log.feedback_details{j}.gallery_name;
        
        for k=1:2
            if strcmp('N', feedback_log.feedback_details{j}.mark_flag(k))
                feedback_log.feedback_details{j}.operator{k} = 'default';
                feedback_log.feedback_details{j}.source(k) = 'U';
                feedback_log.feedback_details{j}.birth_run(k) = 0;
                feedback_log.feedback_details{j}.last_update_time(k,:) = zeros(1,6);
            else
                feedback_log.feedback_details{j}.source(k) = 'M';
                feedback_log.feedback_details{j}.birth_run(k) = 1;
            end
        end
    end
    save([src_dir '\' src_files(i).name], 'feedback_log');
    
    feedback_info = feedback_log;
    save([src_dir2 '\' src_files(i).name], 'feedback_info');
end

