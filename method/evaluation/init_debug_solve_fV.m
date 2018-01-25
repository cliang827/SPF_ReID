%% step1: load model parameters
model_type = ctrl_para.model_type;
init_Y_method = ctrl_para.init_Y_method;
init_V = ctrl_para.init_V;
norm_type = ctrl_para.norm_type;

prbgal_name_tab = ctrl_para.prbgal_name_tab;

p2g_dist = ctrl_para.p2g_dist;
g2p_dist = ctrl_para.g2p_dist;
g2g_dist = ctrl_para.g2g_dist;

epsilon_E = ctrl_para.epsilon_E;   
epsilon_J = ctrl_para.epsilon_J;

delta = ctrl_para.delta;

if delta==1
    max_iter_times=1;
else
    max_iter_times = ctrl_para.max_iter_times;   
end

%% step 2: initializae f0,Y,V,W,FBL
probe_id = ix_info_tab(1);
query_times = ix_info_tab(2);
repeat_times = ix_info_tab(3);

n = size(prbgal_name_tab, 1);
m = 1+n;

if 1==query_times
    Y = [1 1; zeros(n,2)];                  % reference ranking score matrix
    V = [0 0; init_V*ones(n,2)];            % suggestive degree matrix
    FBL = zeros(n,2);                        % survival rounds of feedback galleries

    % step 2.1: compute W
    W = zeros(m, m, 2);
    for k=1:2
        dist_temp = [0, p2g_dist(probe_id,:,k); g2p_dist(:,probe_id,k), g2g_dist(:,:,k)];
        dist_mat = 0.5*(dist_temp+dist_temp');
        [~,A] = scale_dist(dist_mat,2);
        I = eye(size(A,1));
        A(I==1) = 0;
        W(:,:,k) = A;
    end
    setappdata(0, 'W', W);

    % step 2.2: compute Y and f0
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
    setappdata(0, 'dist', dist);
    
    f0 = [1; exp(-1*mean(dist,2))];                 % supposed ranking score (for SPF model parameter initialization)
    
    Y(2:end, :) = exp(-1*dist);                     % initialize reference ranking score matrix
    setappdata(0, 'Y0', Y);
    
    setappdata(0, 'V0', V);
    
    setappdata(0, 'feedback_info', feedback_info);
else
    curr_reid_score = getappdata(0, 'curr_reid_score');
    f0 = [1; curr_reid_score];
    Y_last = getappdata(0, 'Y0');
    Y0 = Y_last*delta + repmat(f0,[1 2])*(1-delta);
    setappdata(0, 'Y0', Y0);

    V0 = cat(1, [0 0], getappdata(0, 'V'));
    V_last = getappdata(0, 'V0');
    V = V_last*delta + V0*(1-delta);
    setappdata(0, 'V0', V);
    
    W = getappdata(0, 'W');
    dist = getappdata(0, 'dist');
    
    % step 2.3: parse feedback info
    if strcmp(ctrl_para.feedback_type, 'nv')
        parse_nv_feedback_info;
    else
        parse_v_feedback_info
    end
    [Y, V, FBL] = translate_feedback_info(Y0, V, query_times, prbgal_name_tab, feedback_info);
    
end    
% save(sprintf('.\\temp_feedback\\%d_%d_%d_f0.mat', probe_id, query_times, repeat_times), 'f0');

