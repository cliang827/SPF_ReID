clear
clc
close all

ctrl_para.dev_env = 'linux';
switch ctrl_para.dev_env
    case 'linux'
        addpath(genpath(fullfile([pwd '/method'])));
    case 'windows'
        addpath(genpath(fullfile([pwd '\method'])));
end
Initialization3;

%% control parameters and model parameters setting
ctrl_para.DEBUG_FLAG = true;
ctrl_para.SHOW_DETAILS = false;
ctrl_para.ERASE_TESTED_EXP = true;
ctrl_para.DRAW_FIG = false;
ctrl_para.SAVE_DETAILS = true;

ctrl_para.image_num_per_page = 20;

ctrl_para.max_para_adjust_times = 2;
ctrl_para.alpha_range = [0 ctrl_para.max_para_adjust_times-1]; 
ctrl_para.beta_range =  [0 1];     
ctrl_para.gamma_range = [0 1-ctrl_para.max_para_adjust_times];

ctrl_para.opt_solver = 'quadprog'; %{'quadprog', 'test', 'cvx'}

ctrl_para.epsilon_E = 1e-6;
ctrl_para.epsilon_J = 1e-6;
ctrl_para.outer_loop_max_iter_times = 5;
ctrl_para.inner_loop_max_iter_times = 20;
ctrl_para.p2g_dist = getappdata(0, 'p2g_dist');
ctrl_para.g2p_dist = getappdata(0, 'g2p_dist');
ctrl_para.g2g_dist = getappdata(0, 'g2g_dist');
ctrl_para.init_reid_score = getappdata(0, 'all_reid_score');
ctrl_para.prbgal_name_tab = getappdata(0, 'prbgal_name_tab');

ctrl_para.feedback_type = 'nv';                                     % {'v', 'nv'};
ctrl_para.fbppr = [0 2];                                            % feedback pair per run (in nv mode, fbppr<=7)
ctrl_para.tot_repeat_times = 1;                                     % total repeat times when feedback_type='nv'
ctrl_para.feedback_agent = 'mmap';                                  % {'mmap', 'mm15', 'mmap - 20171116 - backup', 'mmap - 20171128'};
ctrl_para.treat_groundtruth_in_feedback_info_method = 'let-it-be';  % how to treat groundtruth when loading feedback_info
ctrl_para.include_groundtruth_in_the_first_page_flag = true;        % whether label groundtruth appearing in the 1st page
ctrl_para.follow_pcm14_feedback_protocol_flag = true;

ctrl_para.baseline_pcm14.rand_feedback_ix_for_pcm14_method = 'forbid-node-repeatness'; 
ctrl_para.baseline_pcm14.tau = 0.1;

ctrl_para.Y_last_method = 'test'; % test

model_para_list.alpha_init_order = -0.5;
model_para_list.beta_init_order = 0;
model_para_list.gamma_init_order = 0;

model_para_list.model_type = {'nspf'};
model_para_list.init_Y_method = {'p2g'};
model_para_list.norm_type = 2;
model_para_list.update_ratio = 1;

%% feedback info tab
[exp_para_set, para_name_set, exp_name_set] = exp_para_preparation(model_para_list, ctrl_para);
load_feedback_info2;

dataset_size = size(ctrl_para.p2g_dist,1);
groundtruth_rank = repmat(1:dataset_size, dataset_size, 1);
baseline_cmc_result = result_evaluation(reid_score, groundtruth_rank);

% start parallel computing
run_mode_flag = 'parallelization'; 
% run_mode_flag = 's'; 
if ~isempty(gcp('nocreate'))>0
    delete(gcp('nocreate'))
end
if strcmp(run_mode_flag, 'parallelization')==1 
    poolobj = parpool;
    batch_size = poolobj.NumWorkers;
else
    batch_size = 1;
end

exp_times = size(exp_para_set, 1);
for i=1:exp_times                                               % traverse all model parameter configurations
    for repeat_times=1:tot_repeat_times                         % repeat XX times to randonmize the feedback info

        % prepare model parameters
        ctrl_para.model_type = exp_para_set{i,strcmp(para_name_set , 'model_type')};  
        ctrl_para.init_Y_method = exp_para_set{i,strcmp(para_name_set , 'init_Y_method')};  
        ctrl_para.norm_type = exp_para_set{i,strcmp(para_name_set , 'norm_type')};
        ctrl_para.alpha_order_range = exp_para_set{i,strcmp(para_name_set , 'alpha_order_range')};
        ctrl_para.beta_order_range = exp_para_set{i,strcmp(para_name_set , 'beta_order_range')};
        ctrl_para.gamma_order_range = exp_para_set{i,strcmp(para_name_set , 'gamma_order_range')};
        ctrl_para.update_ratio = exp_para_set{i,strcmp(para_name_set , 'update_ratio')};
        exp_name_str = exp_name_set{i};

        my_reid_score = zeros(dataset_size, dataset_size, tot_query_times);
        v_saturation = zeros(dataset_size, 2, tot_query_times);
        v_sparseness = zeros(dataset_size, 2, tot_query_times);

        f_bat = cell(tot_query_times, batch_size);
        V_bat = cell(tot_query_times, batch_size);
        para_set_bat = cell(tot_query_times, batch_size);
        J_val_bat = cell(tot_query_times, batch_size);
        iter_fVs_bat = cell(tot_query_times, batch_size);
        
        f_bat_for_pcm14 = cell(tot_query_times, batch_size);
        f_delta_bat_for_pcm14 = cell(tot_query_times, batch_size);
        feedback_set_for_pcm14 = cell(tot_query_times, batch_size);
        reid_score_for_pcm14 = zeros(dataset_size,dataset_size, tot_query_times);
        reid_score_delta_for_pcm14 = zeros(dataset_size,dataset_size, tot_query_times);

        tic
        for s = 1:floor(dataset_size/batch_size)
            start = 0 + (s-1)*batch_size;

            nchar = fprintf(1, '\t exp times.%d/%d (%3.2f%%)| repeat times %d/%d (%3.2f%%)| progress %d/%d (%3.2f%%): ...', ...
                        i, exp_times, 100*i/exp_times, repeat_times, tot_repeat_times, 100*repeat_times/tot_repeat_times, ...
                        start, dataset_size, 100*start/dataset_size);
                    
            parfor j = 1:batch_size %%parfor
                for query_times=1:tot_query_times
                    ix_info_tab = [start+j; query_times; repeat_times];       % probe_id, query_times, repeat_times 
                    
                    [f_bat_for_pcm14{query_times, j}, feedback_set_for_pcm14{query_times, j}, f_delta_bat_for_pcm14{query_times, j}] = ...
                        test_baseline_pcm14_v3(ctrl_para, feedback_info_tab{start+j}, groundtruth_feedback{start+j}, ix_info_tab);
                    
                    [f_bat{query_times, j}, V_bat{query_times, j}, para_set_bat{query_times, j}, J_val_bat{query_times, j}, iter_fVs_bat{query_times, j}] = ...
                        solve_fV_test5(ctrl_para, feedback_info_tab{start+j}, groundtruth_feedback{start+j}, ix_info_tab);   
                end
            end

            for j = 1:batch_size
                id = start+j;
                for query_times = 1:tot_query_times
                    % our result: collect solutions of solve_fV_test 
                    f = f_bat{query_times, j};
                    V = V_bat{query_times, j};
                    para_set = para_set_bat{query_times, j};
                    J_val = J_val_bat{query_times, j};
                    iter_fVs = iter_fVs_bat{query_times, j};
                    [my_reid_score(:, id, query_times), v_saturation(id,:, query_times), v_sparseness(id,:, query_times)] = ...
                        result_translation2(f, V, iter_fVs, J_val, id, query_times, repeat_times, exp_name_str, ctrl_para.DRAW_FIG);
                    
                    % baseline pcm14 result: collect solutions of test_baseline_pcm14
                    reid_score_for_pcm14(:, id, query_times) = f_bat_for_pcm14{query_times, j};
                    reid_score_delta_for_pcm14(:, id, query_times) = f_delta_bat_for_pcm14{query_times, j};

                    if ctrl_para.SAVE_DETAILS
                        switch ctrl_para.dev_env
                            case 'linux'
                                save(sprintf('./temp/%s/details/%d_%d_%d.mat', exp_name_str, id, query_times, repeat_times), ...
                                    'f', 'V', 'para_set', 'J_val', 'id', 'query_times', 'repeat_times');
                            case 'windows'
                                save(sprintf('.\\temp\\%s\\details\\%d_%d_%d.mat', exp_name_str, id, query_times, repeat_times), ...
                                    'f', 'V', 'para_set', 'J_val', 'id', 'query_times', 'repeat_times');
                        end
                                    
                    end
                end
            end
            
            if ~ctrl_para.SHOW_DETAILS
                fprintf(1, repmat('\b', 1, nchar));
            end
        end

        nchar = fprintf(1, '\t exp times.%d/%d (%3.2f%%) | repeat times %d/%d (%3.2f%%) | query times %d/%d (%3.2f%%): ...', ...
            i, exp_times, 100*i/exp_times, repeat_times, tot_repeat_times, 100*repeat_times/tot_repeat_times, ...
            start, dataset_size, 100*start/dataset_size);
        
        start = s*batch_size;
        res = dataset_size - start;
        parfor j = 1:res %parfor j = 1:res
            for query_times=1:tot_query_times
                ix_info_tab = [start+j; query_times; repeat_times];       % probe_id, query_times, repeat_times    
                
                [f_bat_for_pcm14{query_times, j}, feedback_set_for_pcm14{query_times, j}, f_delta_bat_for_pcm14{query_times, j}] = ...
                        test_baseline_pcm14_v3(ctrl_para, feedback_info_tab{start+j}, groundtruth_feedback{start+j}, ix_info_tab);
                    
                [f_bat{query_times, j}, V_bat{query_times, j}, para_set_bat{query_times, j}, J_val_bat{query_times, j}, iter_fVs_bat{query_times, j}] = ...
                    solve_fV_test5(ctrl_para, feedback_info_tab{start+j}, groundtruth_feedback{start+j}, ix_info_tab);   
            end
        end
        for j = 1:res
            id = start+j;
            for query_times = 1:tot_query_times
                % our result: collect solutions of solve_fV_test 
                f = f_bat{query_times, j};
                V = V_bat{query_times, j};
                para_set = para_set_bat{query_times, j};
                J_val = J_val_bat{query_times, j};
                iter_fVs = iter_fVs_bat{query_times, j};
                [my_reid_score(:, id, query_times), v_saturation(id,:, query_times), v_sparseness(id,:, query_times)] = ...
                    result_translation2(f, V, iter_fVs, J_val, id, query_times, repeat_times, exp_name_str, ctrl_para.DRAW_FIG);
                
                % baseline pcm14 result: collect solutions of test_baseline_pcm14
                reid_score_for_pcm14(:, id, query_times) = f_bat_for_pcm14{query_times, j};
                reid_score_delta_for_pcm14(:, id, query_times) = f_delta_bat_for_pcm14{query_times, j};

                if ctrl_para.SAVE_DETAILS
                    switch ctrl_para.dev_env
                        case 'linux'
                            save(sprintf('./temp/%s/details/%d_%d_%d.mat', exp_name_str, id, query_times, repeat_times), ...
                                'f', 'V', 'para_set', 'J_val', 'id', 'query_times', 'repeat_times');
                        case 'windows'
                            save(sprintf('.\\temp\\%s\\details\\%d_%d_%d.mat', exp_name_str, id, query_times, repeat_times), ...
                                'f', 'V', 'para_set', 'J_val', 'id', 'query_times', 'repeat_times');
                    end
                end
            end
        end
        if ~ctrl_para.SHOW_DETAILS
            fprintf(1, repmat('\b', 1, nchar));
        end
        run_time = toc;

        cmc_result = zeros(dataset_size, tot_query_times);
        auc_result = zeros(1, tot_query_times);
        v_sat = zeros(tot_query_times,2);
        v_spa = zeros(tot_query_times,2);
        cmc_dist = zeros(dataset_size, 3, tot_query_times);
        
        cmc_result_for_pcm14 = zeros(dataset_size, tot_query_times);
        auc_result_for_pcm14 = zeros(1, tot_query_times);
        for query_times = 1:tot_query_times
            [cmc_result(:, query_times), auc_result(1, query_times)] = result_evaluation(my_reid_score(:,:,query_times), groundtruth_rank);
            v_sat(query_times,:) = mean(v_saturation(:,:,query_times));
            v_spa(query_times,:) = mean(v_sparseness(:,:,query_times));
            
            [cmc_result_for_pcm14(:, query_times), auc_result_for_pcm14(1, query_times)] = ...
                result_evaluation(reid_score_for_pcm14(:,:,query_times), groundtruth_rank);

            fprintf(1, '\t #exp. %d/%d | #rep. %d/%d | #que. %d/%d [%.2f s]: V_spa=[%.2f%%, %.2f%%] | nAUC=[%.2f%%, %.2f%%]\n', ...
                i, exp_times, repeat_times, tot_repeat_times, query_times, tot_query_times, run_time, ...
                100*mean(v_spa(query_times,1)), 100*mean(v_spa(query_times,2)), ...
                100*auc_result(1, query_times), 100*auc_result_for_pcm14(1, query_times));
        end
        
        
        switch ctrl_para.dev_env
            case 'linux'
                save(sprintf('./temp/%s/exp_report_%d.mat', exp_name_str, repeat_times), ...
                    'ctrl_para', 'run_time', 'cmc_result', 'auc_result', 'v_saturation', 'v_sparseness', 'repeat_times', ...
                    'baseline_cmc_result', 'cmc_result_for_pcm14', 'auc_result_for_pcm14', 'reid_score_delta_for_pcm14');
            case 'windows'
                save(sprintf('.\\temp\\%s\\exp_report_%d.mat', exp_name_str, repeat_times), ...
                    'ctrl_para', 'run_time', 'cmc_result', 'auc_result', 'v_saturation', 'v_sparseness', 'repeat_times', ...
                    'baseline_cmc_result', 'cmc_result_for_pcm14', 'auc_result_for_pcm14', 'reid_score_delta_for_pcm14');
        end
    end
end

if ~isempty(gcp('nocreate'))>0
    delete(gcp('nocreate'))
end

%%
tot_repeat_times = ctrl_para.tot_repeat_times;
tot_query_times = length(ctrl_para.fbppr);

feedback_auc = zeros(1, tot_query_times);
feedback_cmc = zeros(316,tot_repeat_times,tot_query_times);
feedback_cmc_for_pcm14 = zeros(316,tot_repeat_times,tot_query_times);
exp_name_str = exp_name_set{1};
for repeat_times=1:tot_repeat_times
    
    switch ctrl_para.dev_env
        case 'linux'
            load(sprintf('./temp/%s/exp_report_%d.mat', exp_name_str, repeat_times));
        case 'windows'
            load(sprintf('.\\temp\\%s\\exp_report_%d.mat', exp_name_str, repeat_times));
    end

        
    for query_times = 1:tot_query_times
        feedback_cmc(:,repeat_times, query_times) = cmc_result(:,query_times);
        feedback_cmc_for_pcm14(:,repeat_times, query_times) = cmc_result_for_pcm14(:,query_times);
    end
end

figure
line_type = {'k.-', 'b.--', 'g+-', 'r-'};
result_name = {'iter 0', 'iter 1: ours', 'iter 2', 'iter 3'};
test_rank = 316;

for query_times = 1:tot_query_times
    cmc_score = mean(feedback_cmc(1:test_rank,:,query_times), 2);
    plot(1:test_rank, cmc_score, line_type{query_times}); grid on; hold on;
    feedback_auc(query_times) = 0.5*(2*sum(cmc_score) - cmc_score(1) - cmc_score(end))/length(cmc_score);
    result_name{query_times} = sprintf('[%2.2f%%] %s', 100*feedback_auc(query_times), result_name{query_times});
end

cmc_score_for_pcm14 = mean(feedback_cmc_for_pcm14(1:test_rank,:, 2), 2);
plot(1:test_rank, cmc_score_for_pcm14, line_type{query_times+1}); hold on; grid on; 
feedback_auc_for_pcm14 = 0.5*(2*sum(cmc_score_for_pcm14) - cmc_score_for_pcm14(1) - cmc_score_for_pcm14(end))/length(cmc_score_for_pcm14);
result_name{3} = sprintf('[%2.2f%%] iter 1: pcm14', 100*feedback_auc_for_pcm14);
query_times = 3;

title(sprintf('CMC with fbp=%d', fbppr(2)));
xlabel('rank');ylabel('CMC');
legend(result_name{1:query_times},'Location','southeast');
axis([0,test_rank,0,1]);

