%% output: feedback info on ordinary galleries and groundtruth gallery
% 1. feedback_info

%step1: add groundtruth feedback
image_num_per_page = ctrl_para.image_num_per_page;
curr_reid_score = getappdata(0, 'curr_reid_score');
[~, sorted_gallery_id_list] = sort(curr_reid_score, 'descend');
curr_groundtruth_rank = find(sorted_gallery_id_list==probe_id, 1);
if ~feedback_info.consider_groundtruth_flag(repeat_times) && ...
        ctrl_para.include_groundtruth_in_the_first_page_flag && curr_groundtruth_rank<=image_num_per_page 
    feedback_info = getappdata(0, 'feedback_info');
    [gallery_name_tab, stat_info] = feedback_stat(feedback_info);
    [include_groundtruth_flag, groundtruth_loc] = ismember(groundtruth_feedback.gallery_name, gallery_name_tab);
    if ~include_groundtruth_flag

        feedback_num = stat_info.gallery_num;
        feedback_info.feedback_details{feedback_num+1} = groundtruth_feedback;
        feedback_info.feedback_gallery_name_tab{feedback_num+1} = groundtruth_feedback.gallery_name;
        feedback_info.include_groundtruth_flag = true;

        rand_feedback_ix = feedback_info.rand_feedback_ix;
        [~,tot_query_times,~] = size(rand_feedback_ix);
        new_ix = [feedback_num+1;feedback_num+1];
        start_ix = length(rand_feedback_ix{repeat_times, query_times-1, 1})+1; %从start_ix处把groundtruth插入
        for i=query_times:tot_query_times
            temp = [rand_feedback_ix{repeat_times, i, 1}; rand_feedback_ix{repeat_times, i, 2}];
            temp(:,start_ix) = new_ix;
            rand_feedback_ix{repeat_times, i, 1} = temp(1,:);
            rand_feedback_ix{repeat_times, i, 2} = temp(2,:);
        end
    else
        feedback_info.feedback_details{groundtruth_loc} = groundtruth_feedback;
        rand_feedback_ix = feedback_info.rand_feedback_ix;
        [~,tot_query_times,~] = size(rand_feedback_ix);
        for k=1:2
            temp = rand_feedback_ix{repeat_times, tot_query_times, k};
            [tf, loc] = ismember(groundtruth_loc, temp);
            start_ix = length(rand_feedback_ix{repeat_times, query_times-1, 1})+1;
            if ~tf % for k-th body part, groundtruth is not selected
                for i=query_times:tot_query_times
                    rand_feedback_ix{repeat_times, i, k}(start_ix) = groundtruth_loc;
                end
            else
                groundtruth_query_times = feedback_info.birth_run_tab(loc)+1;
                if groundtruth_query_times>query_times
                    replace_loc = temp(start_ix);
                    for i=query_times:tot_query_times
                        rand_feedback_ix{repeat_times, i, k}(start_ix) = groundtruth_loc;
                        if i>=groundtruth_query_times
                            rand_feedback_ix{repeat_times, i, k}(loc) = replace_loc;
                        end
                    end
                end
            end
        end
    end
    feedback_info.consider_groundtruth_flag(repeat_times) = 1;
    feedback_info.rand_feedback_ix = rand_feedback_ix;
    setappdata(0, 'feedback_info', feedback_info);
end

%step2: generate feedback_info
feedback_info = getappdata(0, 'feedback_info');
rand_feedback_ix = feedback_info.rand_feedback_ix;
curr_feedback_ix = [rand_feedback_ix{repeat_times, query_times, 1}; rand_feedback_ix{repeat_times, query_times, 2}];
birth_run_tab = feedback_info.birth_run_tab;
feedback_num = length(feedback_info.feedback_details);
for i=feedback_num:-1:1
    [tf1, loc1] = ismember(i,curr_feedback_ix(1,:));
    [tf2, loc2] = ismember(i,curr_feedback_ix(2,:));
    
    if tf1 && tf2 % valid in both parts
        feedback_info.feedback_details{i}.source(1) = 'M';
        feedback_info.feedback_details{i}.mark_flag(1) = 'Y';
        feedback_info.feedback_details{i}.birth_run(1) = birth_run_tab(loc1);
        feedback_info.feedback_details{i}.body_part(1) = 1;

        feedback_info.feedback_details{i}.source(2) = 'M';
        feedback_info.feedback_details{i}.mark_flag(2) = 'Y';
        feedback_info.feedback_details{i}.birth_run(2) = birth_run_tab(loc2);
        feedback_info.feedback_details{i}.body_part(2) = 2;

    elseif tf1 % only valid in the first part
        feedback_info.feedback_details{i}.source(1) = 'M';
        feedback_info.feedback_details{i}.mark_flag(1) = 'Y';
        feedback_info.feedback_details{i}.birth_run(1) = birth_run_tab(loc1);
        feedback_info.feedback_details{i}.body_part(1) = 1;

        feedback_info.feedback_details{i}.source(2) = 'U';
        feedback_info.feedback_details{i}.mark_flag(2) = 'N';
        feedback_info.feedback_details{i}.birth_run(2) = 0;
        feedback_info.feedback_details{i}.body_part(2) = 0;
        feedback_info.feedback_details{i}.box_type(2) = 0;
        feedback_info.feedback_details{i}.box_conf(2) = 0;
        feedback_info.feedback_details{i}.cur_pos(2) = 0;
        feedback_info.feedback_details{i}.operator{2} = 'default';
        feedback_info.feedback_details{i}.last_update_time(2,:) = zeros(1,6);
        
    elseif tf2 % only valid in the second part
        [~, loc2] = ismember(i,curr_feedback_ix(2,:));
        feedback_info.feedback_details{i}.source(2) = 'M';
        feedback_info.feedback_details{i}.mark_flag(2) = 'Y';
        feedback_info.feedback_details{i}.birth_run(2) = birth_run_tab(loc2);
        feedback_info.feedback_details{i}.body_part(2) = 2;

        feedback_info.feedback_details{i}.source(1) = 'U';
        feedback_info.feedback_details{i}.mark_flag(1) = 'N';
        feedback_info.feedback_details{i}.birth_run(1) = 0;
        feedback_info.feedback_details{i}.body_part(1) = 0;
        feedback_info.feedback_details{i}.box_type(1) = 0;
        feedback_info.feedback_details{i}.box_conf(1) = 0;
        feedback_info.feedback_details{i}.cur_pos(1) = 0;  
        feedback_info.feedback_details{i}.operator{1} = 'default';
        feedback_info.feedback_details{i}.last_update_time(1,:) = zeros(1,6);
        
    else % delete current node
        feedback_info.feedback_details(i)=[];
    end
end