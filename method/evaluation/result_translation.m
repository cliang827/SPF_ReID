function [f, v_saturation, v_sparseness, cmp_result, dist_f] = result_translation(f, V, iter_fVs, J_val, MM2015_reid_score, dist, id, exp_name_str, fig_flag)

% step 1: evaluate result
iter_times = size(J_val,2);
groundtruth_rank = zeros(iter_times,1);
for i=1:iter_times
    [~, sorted_gallery_id_list] = sort(iter_fVs{i}.f, 'descend');
    groundtruth_rank(i) = find(sorted_gallery_id_list==id, 1);
end

% step 2: evaluate V saturation
v_saturation = mean(V);

% step 3: evaluate V sparseness
n = size(V,1);
v_sparseness = zeros(1,2);
v_sparseness(1,1) = (sqrt(n)-norm(V(:,1),1)/norm(V(:,1),2))/(sqrt(n)-1);
v_sparseness(1,2) = (sqrt(n)-norm(V(:,2),1)/norm(V(:,2),2))/(sqrt(n)-1);

% step 4: dist_f 
dist_f = [exp(-1*dist), exp(-1*mean(dist,2))];


% step 5: load MM 2015 result (as baseline)
[~, sorted_gallery_id_list] = sort(MM2015_reid_score, 'descend');
baseline_groundtruth_rank = find(sorted_gallery_id_list==id, 1);

cmp_result = zeros(1,4);
cmp_result(1) = baseline_groundtruth_rank;
cmp_result(2) = groundtruth_rank(end);
cmp_result(3) = cmp_result(1)-cmp_result(2);
if cmp_result(1)>cmp_result(2)
    cmp_result(4) = 1;
end

% step 6: draw convergence process
if fig_flag
    hfig = figure(id);

    %%
    subplot(2,2,1);

    plot([iter_times iter_times], [baseline_groundtruth_rank, baseline_groundtruth_rank], 'gs', 'Linewidth', 2); hold on;
    plot(groundtruth_rank, 'b*-', 'Linewidth', 2); grid on; hold on;

    [best_rank, best_iter_times] = min(groundtruth_rank);
    plot([best_iter_times best_iter_times], [best_rank, best_rank], 'r*', 'Linewidth', 2); hold on;

    legend('MM2015 result', 'our result', 'our best result', 'Location','NorthEast');
    xlim([0 iter_times+1])
    xlabel('step');
    ylabel('groundtruth rank');
    title('Groundtruth Ranking Result');

    %%
    subplot(2,2,2); 
    n = size(V,1);
    plot(1:n, V(:,1), 'ro', 1:n, V(:,2), 'bs'); grid on; hold on;
    xlim([0 n+1])
    legend('torso part', 'leg part');

    xlabel('gallery id');
    ylabel('suggest value (V)');
    title('Suggestive Map');

    %%
    subplot(2,2,3); 
    plot(J_val(1, 1:iter_times), 'r-', 'Linewidth', 2, 'Visible', 'off'); hold on;
    plot(J_val(2, 1:iter_times), 'b-', 'Linewidth', 2, 'Visible', 'off'); hold on;
    plot(2:iter_times, J_val(2, 1:iter_times-1)-J_val(2, 2:iter_times), 'g--', 'Linewidth', 2); hold on;

    plot(J_val(1, 1:iter_times), 'r--'); hold on;
    plot(J_val(2, 1:iter_times), 'b-.'); hold on;

    for i=1:iter_times
        plot([i i], [J_val(1, i), J_val(1, i)], 'rs', 'Linewidth', 2); hold on;
        plot([i i], [J_val(1, i), J_val(2, i)], 'r-', 'Linewidth', 2); hold on;

        plot([i i], [J_val(2, i), J_val(2, i)], 'bo', 'Linewidth', 2); hold on;
        if i<iter_times
            plot([i i+1], [J_val(2, i), J_val(1, i+1)], 'b-', 'Linewidth', 2); hold on;
        end
    end

    grid on;
    xlim([0 iter_times+1])
    legend('V-step', 'f-step', 'Delta E(f)');

    xlabel('step');
    ylabel('E(f,V)');
    title('Alternative Optmization of E(f,V)')

    saveas(gcf, sprintf('.\\temp\\%s\\figs\\%d.fig', exp_name_str, id));
    close(hfig);
end