clear
close all
clc

figure
set(gcf,'outerposition',get(0,'screensize')); %窗口最大化

fbp_list = 2:1:15;
n = length(fbp_list);
auc_diff = zeros(1, n);
nv_feedback_auc = zeros(2,n);
v_feedback_auc = zeros(1,n);

for i = 1:n
    
    fbp = fbp_list(i);

    load(sprintf('.\\temp_mm15\\nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_nv_[0 %d]\\feedback_cmc.mat', fbp));
    nv_feedback_cmc = feedback_cmc;
    nv_feedback_auc(:,i) = feedback_auc;

    load(sprintf('.\\temp_mm15\\nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_v_[0 %d]\\feedback_cmc.mat', fbp));
    v_feedback_cmc = feedback_cmc(:,2);
    v_feedback_auc(i) = feedback_auc(:,2);

    auc_diff(i) = v_feedback_auc(i)-nv_feedback_auc(2,i);
    
    subplot(4,4,i);
    line_type = {'k.-', 'b--', 'r.-'};
    result_name = {sprintf('[%2.2f] init 0',nv_feedback_auc(1)), ...
                    sprintf('[%2.2f] iter 1 - nv', nv_feedback_auc(2)),...
                    sprintf('[%2.2f] iter 1 - v', v_feedback_auc(1))};
                
    test_rank = 100;
    for query_times = 1:2
        plot(1:test_rank, nv_feedback_cmc(1:test_rank,query_times), line_type{query_times}); grid on; hold on;
    end
    plot(1:test_rank, v_feedback_cmc(1:test_rank), line_type{3}); grid on; hold on;

    
    title(sprintf('CMC with fbp=%d, auc-diff=%2.2f', fbp, auc_diff(i)));
    xlabel('rank');ylabel('CMC');
    legend(result_name{1:3},'Location','southeast');
    set(gca,'xtick',0:10:test_rank);
end

subplot(4,4,i+1);
line_type = {'k.-', 'b.-', 'r.-'};
plot(fbp_list, nv_feedback_auc(1,:), line_type{1}); grid on; hold on;
plot(fbp_list, nv_feedback_auc(2,:), line_type{2}); grid on; hold on;
plot(fbp_list, v_feedback_auc, line_type{3}); grid on; hold on;
title('AUC cmp (v-nv)');
xlabel('fbp');ylabel('auc');
legend({'iter 0', 'iter 1 - nv','iter 1 - v'},'Location','southeast');