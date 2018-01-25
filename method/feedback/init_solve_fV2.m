clc

%% step 0: key control parameters
ctrl_para.max_para_adjust_times = getappdata(0, 'max_para_adjust_times');
ctrl_para.alpha_order_range = getappdata(0, 'alpha_order_range');
ctrl_para.beta_order_range = getappdata(0, 'beta_order_range');
ctrl_para.gamma_order_range = getappdata(0, 'gamma_order_range');

ctrl_para.model_type = getappdata(0, 'model_type');            
ctrl_para.opt_solver = getappdata(0, 'opt_solver');
ctrl_para.norm_type = getappdata(0, 'norm_type');                    
ctrl_para.epsilon_E = getappdata(0, 'epsilon_E');  
ctrl_para.inner_loop_max_iter_times = getappdata(0, 'inner_loop_max_iter_times');

epsilon_J = getappdata(0, 'epsilon_J'); 
outer_loop_max_iter_times = getappdata(0, 'outer_loop_max_iter_times');
init_Y_method = getappdata(0, 'init_Y_method');
update_ratio = getappdata(0, 'update_ratio');
init_reid_score = getappdata(0, 'all_reid_score');

fbppr = getappdata(0, 'fbppr');
expected_feedback_num = max(fbppr);
ctrl_para.expected_feedback_num = expected_feedback_num;

hwait = waitbar(0,'Self paced feedback in process>>>>>>>>');
waitbar_step = outer_loop_max_iter_times;

%% step 1: ≥ı ºªØ
prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
n = size(prbgal_name_tab, 1);
m = 1+n;

query_times = getappdata(0, 'query_times');
if 1==query_times
    p2g_dist = getappdata(0, 'p2g_dist');
    g2p_dist = getappdata(0, 'g2p_dist');
    g2g_dist = getappdata(0, 'g2g_dist');
    probe_id = getappdata(0, 'probe_id');

    % step 1.1: compute W
    W = zeros(m, m, 2);
    for k=1:2
        dist_mat = [0, p2g_dist(probe_id,:,k); g2p_dist(:,probe_id,k), g2g_dist(:,:,k)];
        dist_mat = 0.5*(dist_mat+dist_mat');
        [~,A] = scale_dist(dist_mat,2);
        I = eye(size(A,1));
        A(I==1) = 0;
        W(:,:,k) = A;
    end
    setappdata(0, 'W', W);

    % step 1.2: compute Y and f0
    switch init_Y_method
        case 'p2g'
            dist = squeeze(p2g_dist(probe_id,:,:));
        case 'p2g-mean'
            dist = squeeze(p2g_dist(probe_id,:,:));
            dist2 = mean(dist,2);
            dist = repmat(dist2,[1,2]);
        case 'g2p'
            dist = squeeze(g2p_dist(:,probe_id,:));
        case 'g2p-mean'
            dist = squeeze(g2p_dist(:,probe_id,:));
            dist2 = mean(dist,2);
            dist = repmat(dist2,[1,2]);
        otherwise                                   
            dist = 1e3*ones(n,2);
    end

    Y0 = [1 1; zeros(n,2)];              % reference ranking score matrix
    Y0(2:end, :) = exp(-1*dist);         % initialize reference ranking score matrix
    Y0(:,1) = normalization(Y0(:,1), [-1 1], 0);
    Y0(:,2) = normalization(Y0(:,2), [-1 1], 0);
    setappdata(0, 'Y0', Y0);
    
    % step 2.3: compute f0
    f0 = [1; init_reid_score(:, probe_id)];
    f0 = normalization(f0, [-1 1], 0);
    setappdata(0, 'f0', f0);
    
    % step 2.4: compute V0
    v0 = expected_feedback_num/n;
    V0 = [0 0; repmat(v0, n, 2)];            % suggestive degree matrix
    setappdata(0, 'V0', V0);
    
    % step 2.5: compute FBL
    FBL = zeros(n,2);                    % survival rounds of feedback galleries
    
else

%     if 1==update_ratio
%         update_ratio = update_ratio - 1/m;
%     elseif 0==update_ratio
%         update_ratio = update_ratio + 1/m;
%     end
    
    % step 2.6: recover W and dist
    W = getappdata(0, 'W');
    
    % step 2.7 update V0
    V0 = getappdata(0, 'V0');
    V_last = cat(1, [0 0], getappdata(0, 'V'));
    V0 = V0*(1-update_ratio) + V_last*update_ratio;
    setappdata(0, 'V0', V0);
    
    % step 2.8 update f0
    f0 = getappdata(0, 'f0');
    curr_reid_score = getappdata(0, 'curr_reid_score');
    f_last = [1; curr_reid_score];
    f0 = f0*(1-update_ratio) + f_last*update_ratio;
    setappdata(0, 'f0', f0);    
    
    % step 2.9: recover Y0
    Y0 = getappdata(0, 'Y0');
    Y_last = zeros(m,2);
    lambda = 0.5;
    for k=1:2
        A = W(:,:,k);
        D = sum(A,2);
        D = spdiags(D,0,speye(size(A,1)));
        S = full(D)^(-1/2) * A * full(D)^(-1/2);
        Y_last(:,k) = (eye(m) - lambda*S)\f_last;
        Y_last(:,k) = normalization(Y_last(:,k), [-1 1], 0);
    end
    Y0 = Y0*(1-update_ratio) + Y_last*update_ratio;
    setappdata(0, 'Y0', Y0);
    
    % step 2.10: parse feedback info
    parse_feedback_info
    [Y0, V0, FBL] = translate_feedback_info(Y0, V0, query_times, prbgal_name_tab, feedback_info);
end

for k=1:2
    assert(1e-9<(f0-Y0(:,k))'*(f0-Y0(:,k))/m);
end
assert(min(f0)>=-1 && max(f0)<=1);
assert(min(V0(:))>=0 && max(V0(:))<=1);
assert(min(Y0(:))>=-1 && max(Y0(:))<=1);
