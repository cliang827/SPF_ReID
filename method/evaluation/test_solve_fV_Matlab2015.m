

clc
% clear all
% close all

% cd('F:\cliang\work\code\test\SalUBM_Feedback - score - yu - mver');
cd('D:\work\code\test\SalUBM_Feedback - score - yu - mver');
addpath('.\method\evaluation\');
addpath('.\method\feedback\');
addpath('.\method\Initialization\');
Initialization;

% ���Ʋ�������
ctrl_para.DEBUG_FLAG = true;
ctrl_para.SHOW_DETAILS = false;
ctrl_para.ERASE_TESTED_EXP = true;
ctrl_para.DRAW_FIG = false;
ctrl_para.SAVE_DETAILS = true;
ctrl_para.max_para_adjust_times = 4;

exp_para_list.model_type = {'nspf'}; 
exp_para_list.init_Y_method = {'p2g'};  
exp_para_list.init_V = 0.99;
exp_para_list.norm_type = 2;
exp_para_list.alpha_init_order = -0.5;
exp_para_list.beta_init_order = 0;
exp_para_list.gamma_init_order = 0;
exp_para_list.delta = 0.5;
exp_para_list.max_iter_times = 5;      

% exp_para_list.model_type = {'nspf'}; 
% exp_para_list.init_Y_method = {'p2g'};  
% exp_para_list.init_V = [0.01 0.99];
% exp_para_list.norm_type = 1;
% exp_para_list.alpha_init_order = -1:0.5:1;
% exp_para_list.beta_init_order = -2:1:2;
% exp_para_list.gamma_init_order = -3:1:3;
% exp_para_list.delta = [0 0.5 1];
% exp_para_list.max_iter_times = 5;  

[exp_para_set, para_name_set, exp_name_set] = exp_para_preparation(exp_para_list,ctrl_para);
exp_times = size(exp_para_set, 1);
ctrl_para.epsilon_E = 1e-5;
ctrl_para.epsilon_J = 1e-20;

ctrl_para.query_times = 1;
ctrl_para.prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
ctrl_para.feedback_info = getappdata(0, 'feedback_info');
ctrl_para.p2g_dist = getappdata(0, 'p2g_dist');
ctrl_para.g2p_dist = getappdata(0, 'g2p_dist');
ctrl_para.g2g_dist = getappdata(0, 'g2g_dist');

load('.\data\baseline\MM2015\result_fusion.mat');
MM2015_reid_score = reid_score;
dataset_size = size(reid_score,1);
groundtruth_rank = repmat(1:dataset_size, dataset_size, 1);

% �������м���
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

clc
for i=1:exp_times
    
    % prepare testing parameters
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

    my_reid_score = zeros(dataset_size,dataset_size);
    cmp_result = zeros(dataset_size, 4);
    v_saturation = zeros(dataset_size, 2);
    v_sparseness = zeros(dataset_size, 2);
    dist_reid_score = zeros(dataset_size,3,dataset_size);
    
    f_bat = cell(1, batch_size);
    V_bat = cell(1, batch_size);
    para_set_bat = cell(1, batch_size);
    J_val_bat = cell(1, batch_size);
    dist_bat = cell(1, batch_size);

    tic
    for s = 1:floor(dataset_size/batch_size)
        start = 0 + (s-1)*batch_size;
        nchar = fprintf(1, 'Iter no.%d/%d (%.2f%%): progress %d/%d (%.2f%%) ...', ...
            i, exp_times, 100*i/exp_times, start, dataset_size, 100*start/dataset_size);
        parfor j = 1:batch_size %%parfor
            [f_bat{j}, V_bat{j}, para_set_bat{j}, J_val_bat{j}, dist_bat{j}] = solve_fV_test(ctrl_para, start+j);
        end
        for j = 1:batch_size
            id = start+j;

            f = f_bat{j};
            V = V_bat{j};
            para_set = para_set_bat{j};
            J_val = J_val_bat{j};
            dist = dist_bat{j};
            MM2015_f = MM2015_reid_score(:,id);

            [my_reid_score(:,id), v_saturation(id,:), v_sparseness(id,:), cmp_result(id,:), dist_reid_score(:,:,id)] = ...
                result_translation(f, V, para_set, J_val, MM2015_f, dist, id, exp_name_str, ctrl_para.DRAW_FIG);
            if ctrl_para.SAVE_DETAILS
                save(sprintf('.\\temp\\%s\\details\\%d.mat', exp_name_str, id), 'f', 'V', 'para_set', 'J_val', 'id');
            end
        end
        fprintf(1, repmat('\b', 1, nchar));
    end

    start = s*batch_size;
    res = dataset_size - start;
    f_bat = cell(1, res);
    V_bat = cell(1, res);
    para_set_bat = cell(1, res);
    J_val_bat = cell(1, res);

    nchar = fprintf(1, 'Iter no.%d/%d (%.2f%%): progress %d/%d (%.2f%%) ...', i, exp_times, 100*i/exp_times, start, dataset_size, 100*start/dataset_size);
    parfor j = 1:res
        [f_bat{j}, V_bat{j}, para_set_bat{j}, J_val_bat{j}, data_bat{j}] = solve_fV_test(ctrl_para, start+j);
    end
    for j = 1:res
        id = start+j;

        f = f_bat{j};
        V = V_bat{j};
        para_set = para_set_bat{j};
        J_val = J_val_bat{j};
        dist = data_bat{j};
        MM2015_f = MM2015_reid_score(:,id);

        [my_reid_score(:,id), v_saturation(id,:), v_sparseness(id,:), cmp_result(id,:), dist_reid_score(:,:,id)] = ...
            result_translation(f, V, para_set, J_val, MM2015_f, dist, id, exp_name_str, ctrl_para.DRAW_FIG);
        if ctrl_para.SAVE_DETAILS
            save(sprintf('.\\temp\\%s\\details\\%d.mat', exp_name_str, id), 'f', 'V', 'para_set', 'J_val', 'id');
        end
    end
    fprintf(1, repmat('\b', 1, nchar));
    run_time = toc;

    cmc_result = result_evaluation(my_reid_score, groundtruth_rank);
    v_saturation = mean(v_saturation);
    v_sparseness = mean(v_sparseness);
    cmc_MM2015 = result_evaluation(MM2015_reid_score,groundtruth_rank);
    cmc_dist(:,1) = result_evaluation(squeeze(dist_reid_score(:,1,:)),groundtruth_rank);
    cmc_dist(:,2) = result_evaluation(squeeze(dist_reid_score(:,2,:)),groundtruth_rank);
    cmc_dist(:,3) = result_evaluation(squeeze(dist_reid_score(:,3,:)),groundtruth_rank);

    save(sprintf('.\\temp\\%s\\exp_report.mat', exp_name_str), 'ctrl_para', 'cmc_result', 'cmp_result', 'run_time', 'v_saturation', 'v_sparseness', 'cmc_MM2015', 'cmc_dist');
    
    fprintf(1, 'Iter no.%d/%d (%3.2f s) [%s]: | v_sat=[%.2f%%, %.2f%%] | CMC@1=%.2f%%, CMC@20=%.2f%%\n', ...
        i, exp_times, run_time, exp_name_str, 100*mean(v_saturation(:,1)), 100*mean(v_saturation(:,2)), 100*cmc_result(1), 100*cmc_result(20));
end

if ~isempty(gcp('nocreate'))>0
    delete(gcp('nocreate'))
end

% result_analysis();

% baseline_cmc = result_evaluation(MM2015_reid_score, groundtruth_rank);
% save('.\temp\test_solve_fV_final.mat', ...
%     'my_cmc', 'baseline_cmc', 'exp_para_set', 'para_name_set', 'exp_name_set');


