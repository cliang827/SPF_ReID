clear
% close all
clc

load('.\temp\nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_nv_[0 7]_mix_n1\feedback_cmc.mat');
nv_feedback_cmc = feedback_cmc(:,[1 3]);

load('.\temp\nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_v_[0 7]_mix_n1\feedback_cmc.mat');
v_feedback_cmc = feedback_cmc(:,3);

figure
line_type = {'k.-', 'b.--', 'r-'};
result_name = {'init 0', 'iter 1 - nv', 'iter 1 - v'};
test_rank = 100;
for query_times = 1:2
    plot(1:test_rank, nv_feedback_cmc(1:test_rank,query_times), line_type{query_times}); grid on; hold on;
end
plot(1:test_rank, v_feedback_cmc(1:test_rank), line_type{3}); grid on; hold on;

title('feedback results');
xlabel('rank');ylabel('CMC');
legend(result_name{1:3},'Location','southeast');
set(gca,'xtick',0:10:test_rank);

