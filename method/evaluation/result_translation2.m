function [f, v_saturation, v_sparseness] = result_translation2(f, V, iter_fVs, J_val, id, query_times, repeat_times, exp_name_str, fig_flag)

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

% step 4: draw convergence process
if fig_flag
    hfig = figure(id);
    set(hfig,'visible','off');  
    
    %% f
    subplot(2,2,1);
    plot(1:n, f, 'b-'); grid on; hold on;
    plot(id, f(id), 'r*', 'Linewidth', 2); hold on;
    plot(1:n, f(id)*ones(1,n), 'k--', 'Linewidth', 1); hold on;
    xlim([1 n]); 
    xlabel('gallery');
    ylabel('f');
    title('ranking score (f)')
    

    %% V
    subplot(2,2,2); 
    plot(1:n, V(:,1), 'b-', 1:n, -1*V(:,2), 'g--'); grid on; hold on;
    legend('torso', 'leg');
    plot(id, 0, 'r*', 'Linewidth', 2); hold on;
    xlim([1 n]);
    xlabel('gallery');
    ylabel('V');
    title('suggestive value (V)');

    %% E(f,V)
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
    title('Alternative Optmization of E(f,V)');
    
    %% groundtruth
    subplot(2,2,4); 
    plot(1:iter_times, groundtruth_rank, 'k--o', 'Linewidth', 2, 'Visible', 'on'); grid on; hold on;
    xlabel('step');
    ylabel('rank');
    title('Groundtruth Rank');

    saveas(gcf, sprintf('.\\temp\\%s\\figs\\%d_%d_%d.jpg', exp_name_str, id, query_times, repeat_times));
    close(hfig);
end