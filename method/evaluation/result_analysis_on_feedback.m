%% this script use to test various trail configurations: 'pure', 'mix_n1', %'mix', 'mix_n1_p0.5', 'mix_n1_p1'

clear
% close all
clc

feedback_type = 'v';
tot_repeat_times = 1;
% feedback_type = 'nv';
% tot_repeat_times = 5;

fbppr = [0 7];        % # feedback pair per run
trail_list = {'pure', 'mix_n1'}; %'mix', 'mix_n1_p0.5', 'mix_n1_p1'
tot_query_times = length(fbppr);
trail_num = length(trail_list);

feedback_cmc_tab = zeros(316,tot_repeat_times, tot_query_times, trail_num);


for trail_times = 1:trail_num
    exp_name_str = ['nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_', feedback_type, '_', mat2str(fbppr), '_', trail_list{trail_times}];
    for repeat_times=1:tot_repeat_times
        load(sprintf('.\\temp\\%s\\exp_report_%d.mat', exp_name_str, repeat_times));

        for query_times = 1:tot_query_times
            feedback_cmc_tab(:,repeat_times, query_times, trail_times) = cmc_result(:,query_times);
        end
    end
end

figure
line_type = {'k.-', 'b.--', 'g+-', 'rs-', 'yo-', 'mx-'};
result_name = {'init 0', 'iter 1+pure', 'iter 1+mix_n1'};
test_rank = 316;

trail_id = [1 1; 2 1; 2 2];
trail_num = size(trail_id,1);
feedback_cmc = zeros(test_rank, trail_num);
feedback_auc = zeros(1, trail_num);

for i=1:size(trail_id,1)
    feedback_cmc(:,i) = mean(squeeze(feedback_cmc_tab(1:test_rank,:,trail_id(i,1), trail_id(i,2))),2);
    feedback_auc(i) = sum(feedback_cmc(:,i));
    result_name{i} = [result_name{i} sprintf(': %.2f', feedback_auc(i))];
    plot(1:test_rank, feedback_cmc(:,i), line_type{i}); grid on; hold on;
end




title(['feedback results', ' - ', feedback_type]);
xlabel('rank');ylabel('CMC');
legend(result_name,'Location','southeast');
set(gca,'xtick',0:10:test_rank);

save(sprintf('.\\temp\\%s\\feedback_cmc.mat',exp_name_str), 'feedback_cmc');




