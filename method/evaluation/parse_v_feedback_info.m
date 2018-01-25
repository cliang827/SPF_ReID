%% output: feedback info on ordinary galleries and groundtruth gallery
% 1. feedback_info

% step1: 产生初步的tmp_feedback_ix
feedback_info = getappdata(0, 'feedback_info');
last_V = getappdata(0, 'V');
[~, ix] = sort(last_V, 'descend');
fb_num = fbppr(query_times);
tf_gt_in_V = zeros(1,2);
loc_gt_in_V = zeros(1,2);
tmp_feedback_ix = zeros(2, fb_num);
groundtruth_name = groundtruth_feedback.gallery_name;
gallery_name_tab = feedback_stat(feedback_info);
for k=1:2
    gallery_name_set = prbgal_name_tab(ix(1:fb_num,k),2);
    [~, tmp_feedback_ix(k,:)] = ismember(gallery_name_set, gallery_name_tab);
    assert(isempty(find(tmp_feedback_ix(k,:)==0, 1)));

    [tf_gt_in_V(k), loc_gt_in_V(k)] = ismember(groundtruth_name, gallery_name_set);
    if feedback_info.consider_groundtruth_flag
        assert(~tf_gt_in_V(k)); % if groundtruth has been labeled，it should not appear again
    end
end

% step2: incorporate groundtruth to revise tmp_feedback_ix
if ctrl_para.include_groundtruth_in_the_first_page_flag && ~feedback_info.consider_groundtruth_flag(repeat_times)
    if tf_gt_in_V(1) && tf_gt_in_V(2)   % groundtruth  appear in both torso and leg suggestions
        feedback_info.feedback_details{tmp_feedback_ix(1, loc_gt_in_V(1))} = groundtruth_feedback;
        feedback_info.consider_groundtruth_flag(repeat_times) = 1;
        
    elseif tf_gt_in_V(1)                % groundtruth only appear in the torso suggestion, add it in the leg suggest
        tmp_feedback_ix(2, fb_num) = tmp_feedback_ix(1, loc_gt_in_V(1));
        feedback_info.feedback_details{tmp_feedback_ix(1, loc_gt_in_V(1))} = groundtruth_feedback;
        feedback_info.consider_groundtruth_flag(repeat_times) = 1;

    elseif tf_gt_in_V(2)                % groundtruth only appear in the leg suggestion, add it in the torso suggest
        tmp_feedback_ix(1, fb_num) = tmp_feedback_ix(2, loc_gt_in_V(2));
        feedback_info.feedback_details{tmp_feedback_ix(2, loc_gt_in_V(2))} = groundtruth_feedback;
        feedback_info.consider_groundtruth_flag(repeat_times) = 1;

    else                                % groundtruth does not appear in neither torso suggest nor leg suggest
        [~, sorted_gallery_id_list] = sort(curr_reid_score, 'descend');
        curr_groundtruth_rank = find(sorted_gallery_id_list==probe_id, 1);

        if curr_groundtruth_rank<=ctrl_para.image_num_per_page
            [tf_gt_in_V, loc_gt_in_V] = ismember(groundtruth_name, gallery_name_tab);
            feedback_num = length(feedback_info.feedback_details);
            if ~tf_gt_in_V
                groundtruth_ix = feedback_num+1;
            else
                groundtruth_ix = loc_gt_in_V;
            end
            
            tmp_feedback_ix(:, fb_num) = groundtruth_ix*ones(2,1);
            feedback_info.feedback_details{groundtruth_ix} = groundtruth_feedback;
            feedback_info.consider_groundtruth_flag(repeat_times) = 1;
        end
    end
end

% step3: update feedback_ix with tmp_feedback_ix
feedback_ix = feedback_info.feedback_ix;
[~,tot_query_times,~] = size(feedback_ix);
for i=query_times:tot_query_times
    for k=1:2
        feedback_ix{1,i,k} = cat(2, feedback_ix{1,i,k}, tmp_feedback_ix(k,:));
    end
end
feedback_info.feedback_ix = feedback_ix;
setappdata(0, 'feedback_info', feedback_info);

% step4: generate feedback_info
curr_feedback_ix = [feedback_ix{1, query_times, 1}; feedback_ix{1, query_times, 2}];
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
        
    else % delete current node
        feedback_info.feedback_details(i)=[];
    end
end



