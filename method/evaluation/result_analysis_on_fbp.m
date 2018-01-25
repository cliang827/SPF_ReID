%% this script use to test various fbppr

clear
% close all
clc

test_rank = 316;
for feedback_type = {'nv', 'v'}
    if strcmp(feedback_type, 'v')
        tot_repeat_times = 1;
    elseif strcmp(feedback_type, 'nv')
        tot_repeat_times = 5;
    end
    
    for fbp = 2:15
        fbppr = [0 fbp];        % # feedback pair per run
        tot_query_times = length(fbppr);
        feedback_cmc_tab = zeros(test_rank, tot_repeat_times, tot_query_times);


        exp_name_str = ['nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_', cell2mat(feedback_type), '_', mat2str(fbppr)];
        for repeat_times=1:tot_repeat_times
            load(sprintf('.\\temp\\%s\\exp_report_%d.mat', exp_name_str, repeat_times));

            for query_times = 1:tot_query_times
                feedback_cmc_tab(:,repeat_times, query_times) = cmc_result(:,query_times);
            end
        end

        feedback_cmc = squeeze(mean(feedback_cmc_tab,2));
        feedback_auc = sum(feedback_cmc);
        
        save(sprintf('.\\temp\\%s\\feedback_cmc.mat',exp_name_str), 'feedback_cmc', 'feedback_auc');
    end
end






