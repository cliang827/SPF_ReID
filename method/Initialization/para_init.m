%% this function initializae SPF's model parameters and control parameters

%% step 1: GUI inilization
image_num_per_page = 20;
setappdata(0,'image_num_per_page',image_num_per_page);

page_id = 1; 
setappdata(0,'page_id',page_id);

% operator = 'default';
% setappdata(0, 'operator', operator);

%% step 2: model parameters: alpha, beta and gamma
max_para_adjust_times = 2;              % when query_times > max_para_adjust_times, alpha/beta/gamma no longer changed

alpha_init_order = -0.5;                % adjustable order range for alpha (bias term)
beta_init_order =  0;                   % larger beta leads to more sparse V
gamma_init_order = 0;                   % larger gamma leads to more sparse V

alpha_range = [0 max_para_adjust_times-1]; 
beta_range =  [0 1];     
gamma_range = [0 1-max_para_adjust_times];

alpha_order_range = alpha_init_order + alpha_range; 
beta_order_range = beta_init_order + beta_range; 
gamma_order_range = gamma_init_order + gamma_range; 

setappdata(0, 'max_para_adjust_times', max_para_adjust_times);
setappdata(0, 'alpha_order_range', alpha_order_range);
setappdata(0, 'beta_order_range', beta_order_range);
setappdata(0, 'gamma_order_range', gamma_order_range);

tau = 0.1;
setappdata(0, 'tau', tau);

model_type = 'nspf';                    % {'nspf', 'spf'} | whether normalization
setappdata(0, 'model_type', model_type);

init_Y_method = 'p2g';                  % {'p2g', 'g2p'} | how to initialize Y
setappdata(0, 'init_Y_method', init_Y_method);

Y_last_method = 'test';
setappdata(0, 'Y_last_method', Y_last_method);

norm_type = 2;                          % {1, 2} | norm type for the sparsity term
setappdata(0, 'norm_type', norm_type);

update_ratio = 1;                       % 0:0.1:1 | update ratio for f0, V0 and Y0 
setappdata(0, 'update_ratio', update_ratio);


%% step 3: optimization control parameters
opt_solver = 'quadprog';                % {'cvx', 'quadprog'} | optimization method
setappdata(0, 'opt_solver', opt_solver);

epsilon_E = 1e-6;                       % iteration threshold for inner loop
setappdata(0, 'epsilon_E', epsilon_E);

epsilon_J = 1e-6;                       % iteration threshold for outer loop
setappdata(0, 'epsilon_J', epsilon_J);

outer_loop_max_iter_times = 5;          % maxium iteration times for outer loop
setappdata(0, 'outer_loop_max_iter_times', outer_loop_max_iter_times);

inner_loop_max_iter_times = 20;         % maxium iteration times for inner loop
setappdata(0, 'inner_loop_max_iter_times', inner_loop_max_iter_times);

%% step 4: feedback control parameters
fbppr = 4;                              % feedback pair per run/query
setappdata(0,'fbppr',fbppr);

load_feedback_log_flag = false;      % whether include log feedback
setappdata(0, 'load_feedback_log_flag', load_feedback_log_flag);






