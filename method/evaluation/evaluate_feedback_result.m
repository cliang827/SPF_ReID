function evaluate_feedback_result(prbgal_name_tab, p2g_dist, last_reid_score, new_reid_score, groundtruth)
save('.\temp\evaluate_feedback_result.mat', 'prbgal_name_tab', 'p2g_dist', 'last_reid_score', 'new_reid_score', 'groundtruth');

% clear; clc; close all;
% load('.\temp\evaluate_feedback_result.mat');

[last_cmc_result last_auc_result last_hist_result] = result_evaluation(last_reid_score, groundtruth);
[dummy, last_ordered] = sort(last_reid_score, 'descend');  %每一列从大到小排序
last_match = (last_ordered == groundtruth);
[last_rank dummy] = find(last_match==1);



[new_cmc_result new_auc_result new_hist_result] = result_evaluation(new_reid_score, groundtruth);
[dummy, new_ordered] = sort(new_reid_score, 'descend');  %每一列从大到小排序
new_match = (new_ordered == groundtruth);
[new_rank dummy] = find(new_match==1);

rank_var = last_rank-new_rank;
better_num = sum(rank_var>0); better_ave_rank = sum(rank_var(rank_var>0))/better_num;
worse_num = sum(rank_var<0);  worse_ave_rank = sum(rank_var(rank_var<0))/worse_num;
unchanged_num = sum(rank_var==0);

fprintf(1, 'CMC@1: %.2f%% vs. %.2f%% | CMC@5: %.2f%% vs. %.2f%% | CMC@10: %.2f%% vs. %.2f%% | CMC@20: %.2f%% vs. %.2f%% \n', ...
    last_cmc_result(1)*100, new_cmc_result(1)*100, last_cmc_result(5)*100, new_cmc_result(5)*100, ...
    last_cmc_result(10)*100, new_cmc_result(10)*100, last_cmc_result(20)*100, new_cmc_result(20)*100);

%画图
figure(1) 
plot(100*new_cmc_result, '-r','LineWidth',1); axis([1, 316, 0, 100]);
hold on; 
plot(100*last_cmc_result, '--g','LineWidth',1); axis([1, 316, 0, 100]);
hold on;
title('Cumulative Matching Characteristic (CMC)');
xlabel( 'Rank' );
ylabel( 'Matching Rate (%)' );
legend('after user feedback','before user feedback',0) %在指定位置建立图例


fprintf(1, 'nAUC: %.2f%% vs %.2f%% | better_num = %d (ave_rank = %.2f), worse_num = %d (ave_rank = %.2f), unchanged_num = %d\n', ...
    last_auc_result*100, new_auc_result*100, better_num, better_ave_rank, worse_num, worse_ave_rank, unchanged_num);

v = find(rank_var==min(rank_var));
fprintf(1, '%d-th probe: %s | rank from %d to %d\n', v(1), prbgal_name_tab{v(1),1}, last_rank(v(1)), new_rank(v(1)));

%%
[probe_num gallery_num body_div_num] = size(p2g_dist);
feedback_statistics = cell(probe_num, 6);
[sorted_reid_score sorted_gallery_id_list] = sort(last_reid_score, 'descend');
feedback_validness = zeros(probe_num,1);
for i=1:probe_num
    % probe name
    probe_name = prbgal_name_tab{i,1};
    feedback_statistics{i,1} = prbgal_name_tab{i,1};

    % feedback stat
    load(['.\data\feedback\cam_a_' probe_name, '.mat']);
    feedback_statistics{i,2} = [feedback_info.stat_info.gallery_num, feedback_info.stat_info.pos_box_num, feedback_info.stat_info.neg_box_num];

    feedback_label = read_feedback_label(i, prbgal_name_tab, p2g_dist);
    ix = find(sum(feedback_label,2));
    [dummy feedback_gallery_rank] = ismember(ix, sorted_gallery_id_list(:,i));
    feedback_label = cat(2, feedback_label, zeros(gallery_num,3));
    feedback_label(ix,3) = feedback_gallery_rank;
    feedback_label(ix,4) = last_rank(i);
    feedback_label(ix,5) = sign(feedback_gallery_rank-last_rank(i));
    
    pos_before_gt_num = sum(feedback_label(feedback_label(:,1)>0,5)<0) + sum(feedback_label(feedback_label(:,2)>0,5)<0);
    pos_after_gt_num = sum(feedback_label(feedback_label(:,1)>0,5)>0) + sum(feedback_label(feedback_label(:,2)>0,5)>0);
    neg_before_gt_num = sum(feedback_label(feedback_label(:,1)<0,5)<0) + sum(feedback_label(feedback_label(:,2)<0,5)<0);
    neg_after_gt_num = sum(feedback_label(feedback_label(:,1)<0,5)>0) + sum(feedback_label(feedback_label(:,2)<0,5)>0);
    
    feedback_statistics{i,3} = [pos_before_gt_num, pos_after_gt_num;neg_before_gt_num, neg_after_gt_num];
    
    feedback_statistics{i,4} = sum(feedback_statistics{i,3});
    feedback_statistics{i,4} = feedback_statistics{i,4}/sum(feedback_statistics{i,4});
    
    temp = feedback_statistics{i,4};
    feedback_statistics{i,5} = sign(temp(1)-temp(2));
    feedback_validness(i) = sign(temp(1)-temp(2));
    
    feedback_statistics{i,6} = sign(rank_var(i));
end
feedback_statistics = cat(1, {'probe name', '# feedback','# comp. rank','comp. rank %','valid/invalid','better/worse'}, feedback_statistics);

% test rank var on validness
better_probe_invalid_feedback_num = sum(feedback_validness(rank_var>0)==-1);
better_probe_valid_feedback_num = sum(feedback_validness(rank_var>0)==1);
unchanged_probe_invalid_feedback_num = sum(feedback_validness(rank_var==0)==-1);
unchanged_probe_valid_feedback_num = sum(feedback_validness(rank_var==0)==1);
worse_probe_invalid_feedback_num = sum(feedback_validness(rank_var<0)==-1);
worse_probe_valid_feedback_num = sum(feedback_validness(rank_var<0)==1);

rank_var_on_validness{1,1} = 'better';
rank_var_on_validness{2,1} = 'unchanged';
rank_var_on_validness{3,1} = 'worse';
rank_var_on_validness{1,2} = better_probe_valid_feedback_num;
rank_var_on_validness{1,3} = better_probe_invalid_feedback_num;
rank_var_on_validness{2,2} = unchanged_probe_valid_feedback_num;
rank_var_on_validness{2,3} = unchanged_probe_invalid_feedback_num;
rank_var_on_validness{3,2} = worse_probe_valid_feedback_num;
rank_var_on_validness{3,3} = worse_probe_invalid_feedback_num;
rank_var_on_validness = cat(1, {'', 'valid', 'invalid'}, rank_var_on_validness)
                        

