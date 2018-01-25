function feedback_info = feedback_info_update(new_feedback_suggest)

feedback_info = getappdata(0, 'feedback_info');
% load('.\temp\feedback_info_update.mat');
% clc

feedback_info.query_times = feedback_info.query_times + 1;

% step 1: 过滤掉上一轮未被用户标注的gallery
feedback_gallery_name_tab = cell(1,1);
feedback_details_num = size(feedback_info.feedback_details, 2);
for i=feedback_details_num:-1:1
    source = feedback_info.feedback_details{i}.source;
    mark_flag = feedback_info.feedback_details{i}.mark_flag;
    gallery_name = feedback_info.feedback_details{i}.gallery_name;
    
    if strcmp(mark_flag(1), 'N') && strcmp(mark_flag(2), 'N')
        feedback_info.feedback_details(i) = [];
    else
        for k=1:2
            if strcmp(source(k), 'S') && strcmp(mark_flag(k), 'N')
                feedback_info.feedback_details{i}.body_part(k) = 0;
                feedback_info.feedback_details{i}.birth_run(k) = 0;
                feedback_info.feedback_details{i}.source(k) = 'U';
                feedback_info.feedback_details{i}.last_update_time(k,:) = zeros(1,6);
            end
        end
        feedback_gallery_name_tab = cat(1, gallery_name, feedback_gallery_name_tab);
    end
end
feedback_gallery_name_tab(end) = [];

% step 2: 将新的反馈建议添加到反馈信息中
suggest_details_num = size(new_feedback_suggest.suggest_details, 2);
for i=1:suggest_details_num
    gallery_name = new_feedback_suggest.suggest_details{i}.gallery_name;
    [tf, loc] = ismember(gallery_name, feedback_gallery_name_tab);
    if tf
        source = new_feedback_suggest.suggest_details{i}.source;
        last_update_time = new_feedback_suggest.suggest_details{i}.last_update_time;
        mark_flag = feedback_info.feedback_details{i}.mark_flag;
        
        for k=1:2
            if strcmp(source(k), 'S') && strcmp(mark_flag(k), 'N')
                feedback_info.feedback_details{loc}.body_part(k) = k;
                feedback_info.feedback_details{loc}.birth_run(k) = feedback_info.query_times;
                feedback_info.feedback_details{loc}.source(k) = 'S';
                feedback_info.feedback_details{loc}.last_update_time(k,:) = last_update_time(k,:);
            end
        end
    else
        feedback_info.feedback_details = cat(2, feedback_info.feedback_details, new_feedback_suggest.suggest_details{i});
    end
end

