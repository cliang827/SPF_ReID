% parse_nv_feeback_info_for_pcm14

% step 1: check groundtruth appearing in the first retrieval page
assert('forbid-node-repeatness', ctrl_para.baseline_pcm14.rand_feedback_ix_for_pcm14_method);
% 注：对于标记样本对可以重复的情况，比较复杂，其groundtruth的添加还需要再详细考虑

curr_reid_score = getappdata(0, 'curr_reid_score_for_pcm14');
fbppp = ctrl_para.fbppp;
[~, sorted_gallery_id_list] = sort(curr_reid_score, 'descend');
curr_groundtruth_rank = find(sorted_gallery_id_list==probe_id, 1);
if ~feedback_info.consider_groundtruth_flag_for_pcm14(repeat_times) && ...
        ctrl_para.include_groundtruth_in_the_first_page_flag && ...
        curr_groundtruth_rank<=ctrl_para.image_num_per_page
    
    feedback_info = getappdata(0, 'feedback_info');
    rand_feedback_ix_for_pcm14 = feedback_info.rand_feedback_ix_for_pcm14;
    [gallery_name_tab, stat_info] = feedback_stat(feedback_info);
    [include_groundtruth_flag, groundtruth_loc] = ismember(groundtruth_feedback.gallery_name, gallery_name_tab);
    if ~include_groundtruth_flag
        for k=1:2
            start_ix = sum(fbppp(1:query_times-1))+1;
            for i = query_times:tot_query_times
                rand_feedback_ix_for_pcm14{repeat_times, i}(1, start_ix, k) = 0;   
            end
        end
    else % groundtruth is labeled
        [~,tot_query_times] = size(rand_feedback_ix_for_pcm14, 2);
        temp = rand_feedback_ix_for_pcm14{repeat_times, tot_query_times};
        for k=1:2
            [tf, loc] = ismember(groundtruth_loc, temp(1,:,k));
            if ~tf % but groundtruth is not selected
                start_ix = sum(fbppp(1:query_times-1))+1;
                
                for i=query_times:tot_query_times
                    rand_feedback_ix_for_pcm14{repeat_times, i}(1, start_ix, k) = groundtruth_loc;  
                end
            else % and groundtruth is selected
                for groundtruth_query_times=1:tot_query_times
                    if sum(fbppp(1:groundtruth_query_times))>=loc
                        break;
                    end
                end
                if groundtruth_query_times>query_times % and groundtruth is selected in future runs
                    start_ix = sum(fbppp(1:query_times-1))+1;
                    replace_loc = rand_feedback_ix_for_pcm14{repeat_times, i}(1, start_ix, k);
                    for i=query_times:tot_query_times
                        rand_feedback_ix_for_pcm14{repeat_times, i}(1, start_ix, k) = groundtruth_loc;
                        if i>=groundtruth_query_times
                            rand_feedback_ix_for_pcm14{repeat_times, i}(1, loc, k) = replace_loc;
                        end
                    end
                end
            end
        end
    end
    
    feedback_info.consider_groundtruth_flag_for_pcm14(repeat_times) = 1;
    feedback_info.rand_feedback_ix_for_pcm14 = rand_feedback_ix_for_pcm14;
    setappdata(0, 'feedback_info', feedback_info);
end
    
% step 2: change index in feedback_info to that of prbgal_name_tab
feedback_info = getappdata(0, 'feedback_info');
feedback_set = feedback_info.rand_feedback_ix_for_pcm14{repeat_times, query_times};
[~, feedback_num, ~] = size(feedback_set);
for i=1:2
    for j = 1:feedback_num
        for k=1:2
            if feedback_set(i,j)>0
                gallery_name = feedback_info.feedback_details{feedback_set(i,j)}.gallery_name;
            elseif feedback_set(i,j)==0
                gallery_name = groundtruth_feedback.gallery_name;
            end
            [~, loc] = ismember(gallery_name, prbgal_name_tab(:,2));
            feedback_set(i,j, k) = loc;
        end
    end
end




