function [f, feedback_set, f_delta] = test_baseline_pcm14(ctrl_para, feedback_info, groundtruth_feedback, ix_info_tab) %#ok<*STOUT,*INUSD>

probe_id = ix_info_tab(1);
query_times = ix_info_tab(2);
repeat_times = ix_info_tab(3);

if query_times == 1
    f = ctrl_para.init_reid_score(:, probe_id);
    setappdata(0, 'curr_reid_score_for_pcm14', f);
    feedback_set = [];
    f_delta = zeros(size(f));
    return;
else
    f0 = getappdata(0, 'curr_reid_score_for_pcm14');
end


% step 1: check groundtruth appearing in the first retrieval page
assert(strcmp('forbid-node-repeatness', ctrl_para.baseline_pcm14.rand_feedback_ix_for_pcm14_method));
% ע�����ڱ����Կ����ظ���������Ƚϸ��ӣ���groundtruth����ӻ���Ҫ����ϸ����


fbppp = ctrl_para.fbppp;
[~, sorted_gallery_id_list] = sort(f0, 'descend');
curr_groundtruth_rank = find(sorted_gallery_id_list==probe_id, 1);
if ~feedback_info.consider_groundtruth_flag_for_pcm14(repeat_times) && ...
        ctrl_para.include_groundtruth_in_the_first_page_flag && ...
        curr_groundtruth_rank<=ctrl_para.image_num_per_page
    
    feedback_info = getappdata(0, 'feedback_info');
    rand_feedback_ix_for_pcm14 = feedback_info.rand_feedback_ix_for_pcm14;
    [~,tot_query_times, ~] = size(rand_feedback_ix_for_pcm14);
    [gallery_name_tab, ~] = feedback_stat(feedback_info);
    [include_groundtruth_flag, groundtruth_loc] = ismember(groundtruth_feedback.gallery_name, gallery_name_tab);
    if ~include_groundtruth_flag
        for k=1:2
            start_ix = sum(fbppp(1:query_times-1))+1;
            for i = query_times:tot_query_times
                rand_feedback_ix_for_pcm14{repeat_times, i}(1, start_ix, k) = 0;   
            end
        end
    else % groundtruth is labeled
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
prbgal_name_tab = ctrl_para.prbgal_name_tab;
feedback_info = getappdata(0, 'feedback_info');
feedback_set = feedback_info.rand_feedback_ix_for_pcm14{repeat_times, query_times};
[~, part_feedback_pair_num, ~] = size(feedback_set);
for i=1:2
    for j = 1:part_feedback_pair_num
        for k=1:2
            if feedback_set(i,j,k)>0
                gallery_name = feedback_info.feedback_details{feedback_set(i,j,k)}.gallery_name;
            elseif feedback_set(i,j,k)==0
                gallery_name = groundtruth_feedback.gallery_name;
            end
            [~, loc] = ismember(gallery_name, prbgal_name_tab(:,2));
            feedback_set(i,j, k) = loc;
        end
    end
end

% step 3: pcm14 core
tau = ctrl_para.baseline_pcm14.tau;
g2g_dist = ctrl_para.g2g_dist;
g2g_sim = exp(-1*g2g_dist);
gallery_num = size(g2g_sim, 1);
f_delta = zeros(gallery_num, 1);
for i=1:gallery_num
    for j=1:part_feedback_pair_num
        for k=1:2
            pos_ix = feedback_set(1, j, k);
            neg_ix = feedback_set(2, j, k);

            pos_sim_score  = g2g_sim(pos_ix, i, k);
            neg_sim_score  = g2g_sim(neg_ix, i, k);

            if abs(pos_sim_score - neg_sim_score)>tau
                f_delta(i) = f_delta(i) + (pos_sim_score - neg_sim_score);
            end
        end
    end
end
    
f = f0 + f_delta;
setappdata(0, 'curr_reid_score_for_pcm14', f);


