clear
% close all
clc 

% feedback_type = 'v';
% tot_repeat_times = 1;
feedback_type = 'nv';
tot_repeat_times = 5;
test_rank = 316;
auc_result = zeros(1,15);

for n=1:15
    fbppr = [0 n];        % # feedback pair per run
    tot_query_times = length(fbppr);
    feedback_auc = zeros(1, tot_query_times);
    feedback_cmc = zeros(316,tot_repeat_times,tot_query_times);
    exp_name_str = ['nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_', feedback_type, '_', mat2str(fbppr)];

    for repeat_times=1:tot_repeat_times
        load(sprintf('.\\temp\\%s\\exp_report_%d.mat', exp_name_str, repeat_times));

        for query_times = 1:tot_query_times
            feedback_cmc(:,repeat_times, query_times) = cmc_result(:,query_times);
        end
    end
    
    cmc_score = mean(feedback_cmc(1:test_rank,:,2), 2);
    auc_result(n) = sum(cmc_score);
end

figure
line_type = {'k.-', 'b.--', 'g+-', 'r-'};
result_name = {'init 0', 'iter 1', 'iter 2', 'iter 3'};

plot(1:n, auc_result, line_type{1}); grid on; hold on;
set(gca,'xtick',0:1:n);

title('AUC with different fbppr');
xlabel('fbppr');ylabel('AUC');
