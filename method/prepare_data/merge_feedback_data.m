clear
clc
close all



% step 1: nv->test feedback
src_dir = '.\data\viper_pcm14\feedback\mmap\';
src_files = dir([src_dir '*.mat']);
file_num = length(src_files);

dst_dir = '.\data\viper_pcm14\feedback\test_feedback\';
if exist(dst_dir, 'dir')
    rmdir(dst_dir, 's');
end
mkdir(dst_dir);

for i=1:file_num
    load([src_dir src_files(i).name]);
    save([dst_dir src_files(i).name], 'feedback_info');
end

% step 2: v->test feedback
src_dir = 'C:\Users\Administrator\Desktop\Code_Jlx_PCM14_VIPER\Picture\FeedBack\FBData\test_feedback\';
dst_dir = '.\data\viper_pcm14\feedback\test_feedback\';

src_files = dir([src_dir '*.mat']);
dst_files = dir([dst_dir '*.mat']);

file_num = length(src_files);
err_num = 1;
err_report = {'err_code', 'probe_id', 'probe_name', 'gallery_name', 'body_part', 'box_type[v:nv]', 'box_conf[v:nv]', 'conf_diff'};
for i=1:file_num
    load([src_dir src_files(i).name]);
    src_feedback_info = feedback_info;
    [src_gallery_name_tab, src_stat_info] = feedback_stat(src_feedback_info);
    src_feedback_num = src_stat_info.gallery_num;
    
    
    load([dst_dir dst_files(i).name]);
    dst_feedback_info = feedback_info;
    [dst_gallery_name_tab, dst_stat_info] = feedback_stat(dst_feedback_info);
    dst_feedback_num = dst_stat_info.gallery_num;
    add_num = 0;
    for j=1:src_feedback_num
        [tf, loc] = ismember(src_feedback_info.feedback_details{j}.gallery_name, dst_gallery_name_tab);
        if tf
            src_mark_flag = src_feedback_info.feedback_details{j}.mark_flag;
            dst_mark_flag = dst_feedback_info.feedback_details{loc}.mark_flag;
            for k=1:2
                if strcmp(src_mark_flag(k),'Y') && strcmp(dst_mark_flag(k),'Y')
                    % merge
                    if src_feedback_info.feedback_details{j}.box_type(k) ~= dst_feedback_info.feedback_details{loc}.box_type(k)
                        err_num = err_num + 1;
                        err_report{err_num,1} = 'box type mismatch';
                        err_report{err_num,2} = i;
                        err_report{err_num,3} = src_files(i).name;
                        err_report{err_num,4} = src_feedback_info.feedback_details{j}.gallery_name;
                        err_report{err_num,5} = k;
                        err_report{err_num,6} = [src_feedback_info.feedback_details{j}.box_type(k);dst_feedback_info.feedback_details{loc}.box_type(k)];
                        err_report{err_num,7} = [src_feedback_info.feedback_details{j}.box_conf(k);dst_feedback_info.feedback_details{loc}.box_conf(k)];
                        err_report{err_num,8} = src_feedback_info.feedback_details{j}.box_type(k)*src_feedback_info.feedback_details{j}.box_conf(k)-...
                            dst_feedback_info.feedback_details{loc}.box_type(k)*dst_feedback_info.feedback_details{loc}.box_conf(k);
%                     elseif src_feedback_info.feedback_details{j}.box_conf(k) ~= dst_feedback_info.feedback_details{loc}.box_conf(k)
%                         err_num = err_num + 1;
%                         err_report{err_num,1} = 'box conf mismatch';
%                         err_report{err_num,2} = i;
%                         err_report{err_num,3} = src_files(i).name;
%                         err_report{err_num,4} = src_feedback_info.feedback_details{j}.gallery_name;
%                         err_report{err_num,5} = k;
%                         err_report{err_num,6} = [src_feedback_info.feedback_details{j}.box_type(k);dst_feedback_info.feedback_details{loc}.box_type(k)];
%                         err_report{err_num,7} = [src_feedback_info.feedback_details{j}.box_conf(k);dst_feedback_info.feedback_details{loc}.box_conf(k)];
%                         err_report{err_num,8} = src_feedback_info.feedback_details{j}.box_type(k)*src_feedback_info.feedback_details{j}.box_conf(k)-...
%                             dst_feedback_info.feedback_details{loc}.box_type(k)*dst_feedback_info.feedback_details{loc}.box_conf(k);
                    end

                elseif strcmp(src_mark_flag(k),'Y')
                    % insert
                    dst_feedback_info.feedback_details{loc}.body_part(k) = src_feedback_info.feedback_details{j}.body_part(k);
                    dst_feedback_info.feedback_details{loc}.box_type(k) = src_feedback_info.feedback_details{j}.box_type(k);
                    dst_feedback_info.feedback_details{loc}.box_conf(k) = src_feedback_info.feedback_details{j}.box_conf(k);
                    dst_feedback_info.feedback_details{loc}.cur_pos(k) = src_feedback_info.feedback_details{j}.cur_pos(k);
                    dst_feedback_info.feedback_details{loc}.birth_run(k) = src_feedback_info.feedback_details{j}.birth_run(k);
                    dst_feedback_info.feedback_details{loc}.source(k) = src_feedback_info.feedback_details{j}.source(k);
                    dst_feedback_info.feedback_details{loc}.mark_flag(k) = src_feedback_info.feedback_details{j}.mark_flag(k);
                    dst_feedback_info.feedback_details{loc}.last_update_time(k,:) = src_feedback_info.feedback_details{j}.last_update_time(k,:);
%                     dst_feedback_info.feedback_details{loc}.operator = src_feedback_info.feedback_details{j}.operator;
                elseif strcmp(src_mark_flag(k),'N') 
                    continue;
                end
            end
        else
            add_num = add_num + 1;
            dst_feedback_info.feedback_details{dst_feedback_num+add_num} = src_feedback_info.feedback_details{j};
        end
        
    end
    feedback_info = dst_feedback_info;
    [~, stat_info] = feedback_stat(feedback_info);
    assert(stat_info.gallery_num>50);
    save([dst_dir '\' dst_files(i).name], 'feedback_info');
end

if err_num>1
    save('.\temp\feedback_invalid_list.mat', 'err_report');
    figure
    conf_diff = cell2mat(err_report(2:end, 8));
%     subplot(2,2,1);
    hist(conf_diff);

    
end