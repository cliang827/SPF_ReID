clear
close all
clc

id = 1;
tot_repeat_times = 1;
% fbppr = [0 7];        % # feedback pair per run
fbppr = [0 3 4];        % # feedback pair per run
tot_query_times = length(fbppr);

exp_name_str = ['nspf_p2g_0.990_2.000_-0.500_0.000_0.000_0.500_5.000_', mat2str(fbppr)];
feedback_cmc = zeros(316,tot_repeat_times,tot_query_times);

for query_times=1:tot_query_times
    load(sprintf('.\\temp\\%s\\details\\%d_%d_%d.mat', exp_name_str, id, query_times, tot_repeat_times));

end

