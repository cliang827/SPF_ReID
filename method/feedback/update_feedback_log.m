function feedback_log = update_feedback_log(feedback_info, log_dir)

load(log_dir);
[log_gallery_name_tab, log_stat_info] = feedback_stat(feedback_log);

[~, stat_info] = feedback_stat(feedback_info);
add_num = 0;
for i=1:stat_info.gallery_num
    info_gallery_name = feedback_info.feedback_details{i}.gallery_name;
    [tf, loc] = ismember(info_gallery_name, log_gallery_name_tab);
    
    if tf
        info_mark_flag = feedback_info.feedback_details{i}.mark_flag;
        info_box_type = feedback_info.feedback_details{i}.box_type;
        info_box_conf = feedback_info.feedback_details{i}.box_conf;
        
        log_mark_flag = feedback_log.feedback_details{loc}.mark_flag;
        log_box_type = feedback_log.feedback_details{loc}.box_type;
        log_box_conf = feedback_log.feedback_details{loc}.box_conf;
        for k=1:2
            if info_box_type(k)*info_box_conf(k)~=log_box_type(k)*log_box_conf(k)
                feedback_log.feedback_details{loc}.box_type(k) = feedback_info.feedback_details{i}.box_type(k);
                feedback_log.feedback_details{loc}.box_conf(k) = feedback_info.feedback_details{i}.box_conf(k);
                feedback_log.feedback_details{loc}.cur_pos(k) = feedback_info.feedback_details{i}.cur_pos(k);
                feedback_log.feedback_details{loc}.last_update_time(k,:) = feedback_info.feedback_details{i}.last_update_time(k,:);
                feedback_log.feedback_details{loc}.operator{k} = feedback_info.feedback_details{i}.operator{k};
                switch info_mark_flag(k)
                    case 'Y'
                        feedback_log.feedback_details{loc}.body_part(k) = k;
                        feedback_log.feedback_details{loc}.birth_run(k) = 1;              
                        feedback_log.feedback_details{loc}.source(k) = 'M';             
                        feedback_log.feedback_details{loc}.mark_flag(k) = 'Y';  
                    case 'N'
                        feedback_log.feedback_details{loc}.body_part(k) = 0;
                        feedback_log.feedback_details{loc}.birth_run(k) = 0;              
                        feedback_log.feedback_details{loc}.source(k) = 'U';           
                        feedback_log.feedback_details{loc}.mark_flag(k) = 'N';  
                end
            end
                
%             if strcmp('Y', info_mark_flag(k)) && ...
%                     (info_box_type(k)*info_box_conf(k)~=log_box_type(k)*log_box_conf(k))
%                 feedback_log.feedback_details{loc}.body_part(k) = k;
%                 feedback_log.feedback_details{loc}.birth_run(k) = 1;              
%                 feedback_log.feedback_details{loc}.source(k) = 'M';             
%                 feedback_log.feedback_details{loc}.mark_flag(k) = 'Y';     
%                 feedback_log.feedback_details{loc}.box_type(k) = feedback_info.feedback_details{i}.box_type(k);
%                 feedback_log.feedback_details{loc}.box_conf(k) = feedback_info.feedback_details{i}.box_conf(k);
%                 feedback_log.feedback_details{loc}.cur_pos(k) = feedback_info.feedback_details{i}.cur_pos(k);
%                 feedback_log.feedback_details{loc}.last_update_time(k,:) = feedback_info.feedback_details{i}.last_update_time(k,:);
%                 feedback_log.feedback_details{loc}.operator{k} = feedback_info.feedback_details{i}.operator{k};
%             elseif strcmp('N', log_mark_flag(k))
%                 assert(feedback_log.feedback_details{loc}.box_type(k)==0);
%                 assert(feedback_log.feedback_details{loc}.box_conf(k)==0);
%                 assert(feedback_log.feedback_details{loc}.cur_pos(k)==0);
%                 assert(feedback_log.feedback_details{loc}.birth_run(k)==0);
%                 assert(feedback_log.feedback_details{loc}.last_update_time(k,1)==0);
% 
%                 assert(strcmp('U', feedback_log.feedback_details{loc}.source(k)));
%                 assert(feedback_log.feedback_details{loc}.body_part(k)==0);
%             end
        end
    else
        add_num = add_num + 1;
        feedback_log.feedback_details{log_stat_info.gallery_num + add_num} = ...
            feedback_info.feedback_details{i};
    end
end

save(log_dir, 'feedback_log');

        