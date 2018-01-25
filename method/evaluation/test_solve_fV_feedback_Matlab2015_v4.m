clear
close all
clc

addpath(genpath(fullfile([pwd '\method'])));
Initialization2;

%% 控制参数设置
ctrl_para.DEBUG_FLAG = true;
ctrl_para.SHOW_DETAILS = false;
ctrl_para.ERASE_TESTED_EXP = true;
ctrl_para.DRAW_FIG = false;
ctrl_para.SAVE_DETAILS = false;

ctrl_para.image_num_per_page = 20;

ctrl_para.max_para_adjust_times = 2;
ctrl_para.alpha_range = [0 ctrl_para.max_para_adjust_times-1]; 
ctrl_para.beta_range =  [0 1];     % beta值越大，V越稀疏
ctrl_para.gamma_range = [0 1-ctrl_para.max_para_adjust_times];

ctrl_para.opt_solver = 'quadprog';
ctrl_para.expected_feedback_num = 5;

ctrl_para.epsilon_E = 1e-6;
ctrl_para.epsilon_J = 1e-20;

ctrl_para.p2g_dist = getappdata(0, 'p2g_dist');
ctrl_para.g2p_dist = getappdata(0, 'g2p_dist');
ctrl_para.g2g_dist = getappdata(0, 'g2g_dist');
ctrl_para.init_reid_score = getappdata(0, 'all_reid_score');
ctrl_para.prbgal_name_tab = getappdata(0, 'prbgal_name_tab');

model_para_list.model_type = {'nspf'}; 
model_para_list.init_Y_method = {'p2g'};  
model_para_list.init_V = 0.1;
model_para_list.norm_type = 2;
model_para_list.alpha_init_order = -0.5;
model_para_list.beta_init_order = 0;
model_para_list.gamma_init_order = 0;
model_para_list.delta = 0;
model_para_list.max_iter_times = 5;

%% feedback info tab
feedback_type = 'nv';   % {'v', 'nv'};
tot_repeat_times = 1;
fbppr = [0 2];          % feedback pair per run (in nv mode, fbppr<=7)
load_feedback_info;

dataset_size = size(ctrl_para.p2g_dist,1);
groundtruth_rank = repmat(1:dataset_size, dataset_size, 1);

% 开启并行计算
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

[exp_para_set, para_name_set, exp_name_set] = exp_para_preparation(model_para_list, ctrl_para);
exp_times = size(exp_para_set, 1);

for i=1:exp_times                                               % traverse all model parameter configurations
    for repeat_times=1:tot_repeat_times                         % repeat XX times to randonmize the feedback info

        % prepare model parameters
        ctrl_para.model_type = exp_para_set{i,strcmp(para_name_set , 'model_type')};  
        ctrl_para.init_Y_method = exp_para_set{i,strcmp(para_name_set , 'init_Y_method')};  
        ctrl_para.init_V = exp_para_set{i,strcmp(para_name_set , 'init_V')};
        ctrl_para.norm_type = exp_para_set{i,strcmp(para_name_set , 'norm_type')};
        ctrl_para.alpha_order_range = exp_para_set{i,strcmp(para_name_set , 'alpha_order_range')};
        ctrl_para.beta_order_range = exp_para_set{i,strcmp(para_name_set , 'beta_order_range')};
        ctrl_para.gamma_order_range = exp_para_set{i,strcmp(para_name_set , 'gamma_order_range')};
        ctrl_para.delta = exp_para_set{i,strcmp(para_name_set , 'delta')};
        ctrl_para.max_iter_times = exp_para_set{i,strcmp(para_name_set , 'max_iter_times')};
        exp_name_str = exp_name_set{i};

        my_reid_score = zeros(dataset_size,dataset_size, tot_query_times);
        v_saturation = zeros(dataset_size, 2, tot_query_times);
        v_sparseness = zeros(dataset_size, 2, tot_query_times);

        f_bat = cell(tot_query_times, batch_size);
        V_bat = cell(tot_query_times, batch_size);
        para_set_bat = cell(tot_query_times, batch_size);
        J_val_bat = cell(tot_query_times, batch_size);
        iter_fVs_bat = cell(tot_query_times, batch_size);

        tic
        for s = 1:floor(dataset_size/batch_size)
            start = 0 + (s-1)*batch_size;

            nchar = fprintf(1, '\t exp times.%d/%d (%3.2f%%)| repeat times %d/%d (%3.2f%%)| progress %d/%d (%3.2f%%): ...', ...
                        i, exp_times, 100*i/exp_times, repeat_times, tot_repeat_times, 100*repeat_times/tot_repeat_times, ...
                        start, dataset_size, 100*start/dataset_size);
                    
            parfor j = 1:batch_size %%parfor
                for query_times=1:tot_query_times
                    ix_info_tab = [start+j; query_times; repeat_times];       % probe_id, query_times, repeat_times               
                    [f_bat{query_times, j}, V_bat{query_times, j}, para_set_bat{query_times, j}, J_val_bat{query_times, j}, iter_fVs_bat{query_times, j}] = ...
                        solve_fV_test4(ctrl_para, feedback_info_tab{start+j}, groudntruth_feedback{start+j}, ix_info_tab);   
                end
            end

            for j = 1:batch_size
                id = start+j;
                for query_times = 1:tot_query_times
                    f = f_bat{query_times, j};
                    V = V_bat{query_times, j};
                    para_set = para_set_bat{query_times, j};
                    J_val = J_val_bat{query_times, j};
                    iter_fVs = iter_fVs_bat{query_times, j};

                    [my_reid_score(:, id, query_times), v_saturation(id,:, query_times), v_sparseness(id,:, query_times)] = ...
                        result_translation2(f, V, iter_fVs, J_val, id, query_times, repeat_times, exp_name_str, ctrl_para.DRAW_FIG);
                    if ctrl_para.SAVE_DETAILS
                        save(sprintf('.\\temp\\%s\\details\\%d_%d_%d.mat', exp_name_str, id, query_times, repeat_times), ...
                            'f', 'V', 'para_set', 'J_val', 'id', 'query_times', 'repeat_times');
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
                [f_bat{query_times, j}, V_bat{query_times, j}, para_set_bat{query_times, j}, J_val_bat{query_times, j}, iter_fVs_bat{query_times, j}] = ...
                    solve_fV_test4(ctrl_para, feedback_info_tab{start+j}, groudntruth_feedback{start+j}, ix_info_tab);   
            end
        end
        for j = 1:res
            id = start+j;
            for query_times = 1:tot_query_times
                f = f_bat{query_times, j};
                V = V_bat{query_times, j};
                para_set = para_set_bat{query_times, j};
                J_val = J_val_bat{query_times, j};
                iter_fVs = iter_fVs_bat{query_times, j};

                [my_reid_score(:, id, query_times), v_saturation(id,:, query_times), v_sparseness(id,:, query_times)] = ...
                    result_translation2(f, V, iter_fVs, J_val, id, query_times, repeat_times, exp_name_str, ctrl_para.DRAW_FIG);
                if ctrl_para.SAVE_DETAILS
                    save(sprintf('.\\temp\\%s\\details\\%d_%d_%d.mat', exp_name_str, id, query_times, repeat_times), ...
                        'f', 'V', 'para_set', 'J_val', 'id', 'query_times', 'repeat_times');
                end
            end
        end
        if ~ctrl_para.SHOW_DETAILS
            fprintf(1, repmat('\b', 1, nchar));
        end
        run_time = toc;

        cmc_result = zeros(dataset_size, tot_query_times);
        v_sat = zeros(tot_query_times,2);
        v_spa = zeros(tot_query_times,2);
        cmc_dist = zeros(dataset_size, 3, tot_query_times);
        for query_times = 1:tot_query_times
            cmc_result(:, query_times) = result_evaluation(my_reid_score(:,:,query_times), groundtruth_rank);
            v_sat(query_times,:) = mean(v_saturation(:,:,query_times));
            v_spa(query_times,:) = mean(v_sparseness(:,:,query_times));

            fprintf(1, '\t exp times.%d/%d (%3.2f%%) | repeat times %d/%d (%3.2f%%) | query times %d/%d (%3.2f%%) [%.2f sec]: v_sat=[%.2f%%, %.2f%%] | CMC@[1 20]=[%.2f%%, %.2f%%]\n', ...
                i, exp_times, 100*i/exp_times, ...
                repeat_times, tot_repeat_times, 100*repeat_times/tot_repeat_times, ...
                query_times, tot_query_times, 100*query_times/tot_query_times, run_time, ...
                100*mean(v_sat(query_times,1)), 100*mean(v_sat(query_times,2)), ...
                100*cmc_result(1,query_times), 100*cmc_result(20,query_times));
        end
        
        save(sprintf('.\\temp\\%s\\exp_report_%d.mat', exp_name_str, repeat_times), ...
            'ctrl_para', 'run_time', 'cmc_result', 'v_saturation', 'v_sparseness', 'repeat_times');
    end
end

if ~isempty(gcp('nocreate'))>0
    delete(gcp('nocreate'))
end

% result_analysis();

% baseline_cmc = result_evaluation(MM2015_reid_score, groundtruth_rank);
% save('.\temp\test_solve_fV_final.mat', ...
%     'my_cmc', 'baseline_cmc', 'exp_para_set', 'para_name_set', 'exp_name_set');


