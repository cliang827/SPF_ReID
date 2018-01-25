clc
clear
close all

[sta,res] = dos('systeminfo');
if ~isempty(regexp(res, 'CLIANG-VBOX-PC', 'once'))              % X270虚拟机
    cd('G:\code\test\SalUBM_Feedback - score - yu - mver');
elseif ~isempty(regexp(res, 'PC-20170623DBSD', 'once'))         % 实验室台式机
    cd('D:\work\code\test\SalUBM_Feedback - score - yu - mver');
elseif ~isempty(regexp(res, 'WIN-09UCQCTCVPV', 'once'))         % 实验室服务器
    cd('F:\cliang\work\code\test\SalUBM_Feedback - score - yu - mver');    
end

addpath(genpath(fullfile([pwd '\method'])));
Initialization2;

%% 控制参数设置
ctrl_para.DEBUG_FLAG = true;
ctrl_para.SHOW_DETAILS = false;
ctrl_para.ERASE_TESTED_EXP = true;
ctrl_para.DRAW_FIG = false;
ctrl_para.SAVE_DETAILS = true;

ctrl_para.image_num_per_page = 20;

ctrl_para.max_para_adjust_times = 2;
ctrl_para.alpha_range = [0 ctrl_para.max_para_adjust_times-1]; 
ctrl_para.beta_range =  [0 1];     % beta值越大，V越稀疏
ctrl_para.gamma_range = [0 1-ctrl_para.max_para_adjust_times];

ctrl_para.epsilon_E = 1e-5;
ctrl_para.epsilon_J = 1e-20;

ctrl_para.p2g_dist = getappdata(0, 'p2g_dist');
ctrl_para.g2p_dist = getappdata(0, 'g2p_dist');
ctrl_para.g2g_dist = getappdata(0, 'g2g_dist');
ctrl_para.init_reid_score = getappdata(0, 'all_reid_score');
ctrl_para.prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
feedback_info = cell(316,10);

model_para_list.model_type = {'nspf'}; 
model_para_list.init_Y_method = {'p2g'};  
model_para_list.init_V = 0.99;
model_para_list.norm_type = 2;
model_para_list.alpha_init_order = -0.5;
model_para_list.beta_init_order = 0;
model_para_list.gamma_init_order = 0;
model_para_list.delta = 0.5;
model_para_list.max_iter_times = 5;

%%%
fbt = {'v'};
fbp = 6;

for ii=1:length(fbt)
    for jj=1:length(fbp)
        feedback_type = fbt{ii};
        if strcmp(feedback_type, 'v')
            tot_repeat_times = 1;
        elseif strcmp(feedback_type, 'nv')
            tot_repeat_times = 5;
        end
        
        
        if fbp(jj)>0
            fbppr = [0 fbp(jj)];
            fprintf('feedback_type=%s, fbppr=[0 %d], tot_repeat_times=%d\n', feedback_type, fbppr(2), tot_repeat_times);
        else
            fbppr = 0;
            fprintf('feedback_type=%s, fbppr=0, tot_repeat_times=%d\n', feedback_type, tot_repeat_times);
        end
        
        test_solve_fV_feedback_Matlab2015_v2;
    end
end

