clear
% close all
clc 

feedback_type = 'v';
tot_repeat_times = 1;
% feedback_type = 'nv';
% tot_repeat_times = 5;

fbppr = [0 4];        % # feedback pair per run
tot_query_times = length(fbppr);
feedback_auc = zeros(1, tot_query_times);
feedback_cmc = zeros(316,tot_repeat_times,tot_query_times);

feedback_cmc_for_pcm14 = zeros(316,tot_repeat_times,tot_query_times);

exp_name_str = ['nspf_p2g_2.000_-0.500_0.000_0.000_1.000_', feedback_type, '_', mat2str(fbppr)];

for repeat_times=1:tot_repeat_times
    load(sprintf('.\\temp\\%s\\exp_report_%d.mat', exp_name_str, repeat_times));
    
    for query_times = 1:tot_query_times
        feedback_cmc(:,repeat_times, query_times) = cmc_result(:,query_times);
        feedback_cmc_for_pcm14(:,repeat_times, query_times) = cmc_result_for_pcm14(:,query_times);
    end
end



figure
line_type = {'k.-', 'b.--', 'g+-', 'r-'};
result_name = {'init 0', 'iter 1', 'iter 2', 'iter 3'};
test_rank = 316;

for query_times = 1:tot_query_times
    cmc_score = mean(feedback_cmc(1:test_rank,:,query_times), 2);
    plot(1:test_rank, cmc_score, line_type{query_times}); hold on;
    feedback_auc(query_times) = 0.5*(2*sum(cmc_score) - cmc_score(1) - cmc_score(end))/length(cmc_score);
    result_name{query_times} = sprintf('[%2.2f] %s', 100*feedback_auc(query_times), result_name{query_times});
end

cmc_score_for_pcm14 = mean(feedback_cmc_for_pcm14(1:test_rank,:, 2), 2);
plot(1:test_rank, cmc_score_for_pcm14, line_type{query_times+1}); hold on; grid on; 
feedback_auc_for_pcm14 = 0.5*(2*sum(cmc_score_for_pcm14) - cmc_score_for_pcm14(1) - cmc_score_for_pcm14(end))/length(cmc_score_for_pcm14);
result_name{3} = sprintf('[%2.2f] iter 1', 100*feedback_auc_for_pcm14);
query_times = 3;

title(sprintf('CMC with fbp=%d', fbppr(2)));
xlabel('rank');ylabel('CMC');
legend(result_name{1:query_times},'Location','southeast');
set(gca,'xtick',0:50:test_rank);
set(gca,'ylim',[0 1]);

save(sprintf('.\\temp\\%s\\feedback_cmc.mat',exp_name_str), 'feedback_cmc');




