function reid_score_delta = pcm14_core_v3(ctrl_para, feedback_set)

tau = ctrl_para.baseline_pcm14.tau;
g2g_dist = ctrl_para.g2g_dist;
g2g_sim = exp(-1*g2g_dist);

gallery_num = size(g2g_sim,1);
reid_score_delta = zeros(gallery_num, 1);

if isempty(feedback_set)
    return;
end

[~, feedback_pair_num] = size(feedback_set);
for i=1:gallery_num
    for j=1:feedback_pair_num
        k = feedback_set(1,j);
        pos_ix = feedback_set(2,j);
        neg_ix = feedback_set(3,j);

        pos_sim_score  = g2g_sim(pos_ix, i, k);
        neg_sim_score  = g2g_sim(neg_ix, i, k);

        if abs(pos_sim_score - neg_sim_score)>tau
            reid_score_delta(i) = reid_score_delta(i) + (pos_sim_score - neg_sim_score);
        end        
    end
end

