%% step1: load model parameters
probe_id = ix_info_tab(1);
query_times = ix_info_tab(2);
repeat_times = ix_info_tab(3);

model_type = ctrl_para.model_type;
init_Y_method = ctrl_para.init_Y_method;
norm_type = ctrl_para.norm_type;
prbgal_name_tab = ctrl_para.prbgal_name_tab;
fbppr = ctrl_para.fbppr;
expected_feedback_num = max(fbppr);
ctrl_para.expected_feedback_num = expected_feedback_num;

p2g_dist = ctrl_para.p2g_dist;
g2p_dist = ctrl_para.g2p_dist;
g2g_dist = ctrl_para.g2g_dist;
init_reid_score = ctrl_para.init_reid_score;
epsilon_J = ctrl_para.epsilon_J;

update_ratio = ctrl_para.update_ratio;
outer_loop_max_iter_times = ctrl_para.outer_loop_max_iter_times;   

%% step 2: initializae W, Y0, f0, V0, FBL
n = size(prbgal_name_tab, 1);
m = 1+n;

if 1==query_times
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

    % step 2.2: compute Y
    switch init_Y_method
        case 'p2g'
            dist = squeeze(p2g_dist(probe_id,:,:));
        case 'p2g-mean'
            dist = squeeze(p2g_dist(probe_id,:,:));
            dist2 = mean(dist,2);       % mean the K body parts
            dist = repmat(dist2,[1,2]); % repeat the mean value
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
    
    % step 2.6: save feedback_info (for parsing when query_times>1)
    setappdata(0, 'feedback_info', feedback_info);
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
    Y0 = Y0*(1-update_ratio) + repmat(f_last,[1 2])*update_ratio;
    setappdata(0, 'Y0', Y0);
    
    % step 2.10: parse feedback info
    if strcmp(ctrl_para.feedback_type, 'nv')
        parse_nv_feedback_info;
    else
        parse_v_feedback_info
    end
    [Y0, V0, FBL] = translate_feedback_info(Y0, V0, query_times, prbgal_name_tab, feedback_info);
end

for k=1:2
    assert(1e-9<(f0-Y0(:,k))'*(f0-Y0(:,k))/m);
end
assert(min(f0)>=-1 && max(f0)<=1);
assert(min(V0(:))>=0 && max(V0(:))<=1);
assert(min(Y0(:))>=-1 && max(Y0(:))<=1);

% save(sprintf('.\\temp_feedback\\%d_%d_%d_f0.mat', probe_id, query_times, repeat_times), 'f0');

