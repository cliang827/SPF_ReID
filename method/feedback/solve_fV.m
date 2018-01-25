function [f, V, para_set, J_val] = solve_fV(ctrl_para, probe_id)

DEBUG_FLAG = ctrl_para.DEBUG_FLAG;
SHOW_DETAILS = ctrl_para.SHOW_DETAILS;

if DEBUG_FLAG
    close all
    
    model_type = ctrl_para.model_type;
    init_Y_method = ctrl_para.init_Y_method;
    init_V = ctrl_para.init_V;
    norm_type = ctrl_para.norm_type;
    delta = ctrl_para.delta;
    
    query_times = ctrl_para.query_times;
    prbgal_name_tab = ctrl_para.prbgal_name_tab;
    feedback_info = ctrl_para.feedback_info;
    p2g_dist = ctrl_para.p2g_dist;
    g2p_dist = ctrl_para.g2p_dist;
    g2g_dist = ctrl_para.g2g_dist;

    epsilon_E = ctrl_para.epsilon_E;   
    epsilon_J = ctrl_para.epsilon_J;
    
    if delta==1
        max_iter_times=1;
    else
        max_iter_times = ctrl_para.max_iter_times;   
    end
else
    clc
    
    %% step 0: key control parameters
    model_type = 'nspf';                    % {'spf', 'nspf'}
    init_Y_method = 'p2g';                  % {'p2g', 'g2p', otherwise}
    init_V = 0.99;                          % {5e-2(definite), 5e-1(neutral)}
    norm_type = 1;                          % {1, 2}
    
    max_para_adjust_times = 2;              % when query_times > max_para_adjust_times, alpha/beta/gamma no longer changed
    alpha_range = [0 max_para_adjust_times-1]; 
    beta_range =  [0 1];     
    gamma_range = [0 1-max_para_adjust_times];

    alpha_init_order = -0.5;                % adjustable order range for alpha (bias term)
    beta_init_order =  0;                   % larger beta leads to more sparse V
    gamma_init_order = 0;                   % larger gamma leads to more sparse V
    
    ctrl_para.max_para_adjust_times = max_para_adjust_times;
    ctrl_para.alpha_order_range = alpha_init_order + alpha_range; 
    ctrl_para.beta_order_range = beta_init_order + beta_range; 
    ctrl_para.gamma_order_range = gamma_init_order + gamma_range; 
    
    delta = 0.5;

    epsilon_E = 1e-5;                       % iteration threshold for inner loop
    epsilon_J = 1e-20;                      % iteration threshold for outer loop
    max_iter_times = 5;                     % maximum iteration times
    
    hwait = waitbar(0,'Self paced feedback in process>>>>>>>>');
    waitbar_step = max_iter_times;
end

if DEBUG_FLAG
    
    n = size(prbgal_name_tab, 1);
    m = 1+n;

    Y = [1 1; zeros(n,2)];                  % reference ranking score matrix
    V = [0 0; init_V*ones(n,2)];            % suggestive degree matrix
    FBL = zeros(n,2);                        % survival rounds of feedback galleries
    
    if 1==query_times
        % step 1.1: compute W
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

        f0 = [1; exp(-1*mean(dist,2))];                 % supposed ranking score (for SPF model parameter initialization)
        setappdata(0, 'f0', f0);

        Y(2:end, :) = exp(-1*dist);                     % initialize reference ranking score matrix
        setappdata(0, 'Y', Y);

    else
        W = getappdata(0, 'W');
        Y0 = getappdata(0, 'Y');
        f0 = getappdata(0, 'f0');
        feedback_info = getappdata(0, 'feedback_info');

        [Y, V, FBL] = translate_feedback_info(Y0, V, query_times, prbgal_name_tab, feedback_info);
    end    
else
    %% step 1: 初始化
    query_times = getappdata(0, 'query_times');
    prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
    n = size(prbgal_name_tab, 1);
    m = 1+n;

    Y = [1 1; zeros(n,2)];                  % reference ranking score matrix
    V = [0 0; init_V*ones(n,2)];            % suggestive degree matrix
    FBL = zeros(n,2);                        % survival rounds of feedback galleries

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

        f0 = [1; exp(-1*mean(dist,2))];                 % supposed ranking score (for SPF model parameter initialization)
        setappdata(0, 'f0', f0);

        Y(2:end, :) = exp(-1*dist);                     % initialize reference ranking score matrix
        setappdata(0, 'Y', Y);

    else

        W = getappdata(0, 'W');
        Y0 = getappdata(0, 'Y');
        f0 = getappdata(0, 'f0');
        feedback_info = getappdata(0, 'feedback_info');

        [Y, V, FBL] = translate_feedback_info(Y0, V, query_times, prbgal_name_tab, feedback_info);
    end
end

% step 1.3: init SPF model parameters
[alpha_list, beta_list, gamma_list] = init_SPF_parameters_normalized_mver(f0, W, V, Y, model_type, norm_type, FBL, query_times, ctrl_para);

%% step 2: 交替优化F与V
fl = 1;
iter_times = 0;
V0 = V;

J_val = zeros(2, max_iter_times);
time_rec = zeros(2, max_iter_times);
para_set = cell(1, max_iter_times);

%% core solve_fV algorithm
while 1
    iter_times = iter_times + 1;

    if ~DEBUG_FLAG
        str=['Iteration no.',num2str(iter_times), ' -f'];
        waitbar(min(1,iter_times/waitbar_step),hwait,str);
    end
    
    %% f-step
    tic
    
    if iter_times>1
        Y = Y*delta + repmat(f,[1 2])*(1-delta);
        V = V0*delta + V*(1-delta);
        V0 = V;
    end
    
    A = zeros(n,n);
    b = zeros(n,1);
    for k=1:2
        Wk = W(:,:,k);
        Vk = V(:,k);
        Yuk = Y(2:m,k);
        alpha = diag(alpha_list(2:m,k));
        
        P = diag(sum(Wk,2));
        V_tilde = (1-Vk)*(1-Vk)';
        W_tilde = V_tilde.*Wk;
        P_tilde = diag(sum(W_tilde,2));
        Q_tilde = diag(sum(V_tilde,2));
        P_hat = sqrt(P)\P_tilde/sqrt(P);
        W_hat = sqrt(P)\W_tilde/sqrt(P);
        
        Quu_tilde = Q_tilde(2:m,2:m);
        Quu_hat = alpha*Quu_tilde;
        
        switch model_type
            case 'nspf'
                Puu = P_hat(2:m,2:m);
                Wuu = W_hat(2:m,2:m);
                Wul = W_hat(2:m,1);
            case 'spf'
                Puu = P_tilde(2:m,2:m);
                Wuu = W_tilde(2:m,2:m);
                Wul = W_tilde(2:m,1);
        end
        
        A = A + 2*(Puu-Wuu+Quu_hat);
        b = b + 4*(Wul*fl+Quu_hat*Yuk); 
    end

    [~, p]=chol(A); 
    assert(0==p); %确保A是正定矩阵
    
    d = ones(n, 1);
    tic
    cvx_begin quiet 
        variable f(n)
        minimize( f'*A*f-f'*b)
        subject to
            f-1<=0;
            -1*f-1<=0;
            f'*d == 0;
    cvx_end
    fu = f;
    f = [fl;fu];
    
    J_val(1, iter_times) = J_func(f, V, W, Y, alpha_list, beta_list, gamma_list, norm_type, model_type);
    if DEBUG_FLAG && SHOW_DETAILS
        time_rec(1, iter_times) = toc;
        fprintf(1, '%02d-f,\t J(f)=%+5.3e,\t Time=%5.3f\n',iter_times, J_val(1, iter_times), time_rec(1, iter_times));
    end    
    

    %% V-step
    if ~DEBUG_FLAG
        str=['Iteration no.',num2str(iter_times), ' -V'];
        waitbar(min(1,iter_times/waitbar_step),hwait,str);
    end

    for k=1:2
        Wk = W(:,:,k);
        Yk = Y(:,k);
        P = diag(sum(Wk,2));
        
        f_normalized = sqrt(P)\f;
        ff = repmat(f_normalized,[1 m])-repmat(f_normalized',[m 1]);
    
        alpha = alpha_list(:,k);
        beta = beta_list(k);
        gamma = gamma_list(k);
        
        alpha_fY = repmat(alpha.*(f-Yk).*(f-Yk), [1 m]) + repmat(alpha'.*(f-Yk)'.*(f-Yk)',[m 1]);
        L = Wk.*ff.*ff + alpha_fY;
        L_hat = L-beta;
        assert(0==norm(L_hat-L_hat'));
        d_hat = sum(L_hat,2);
        
        eig_value = abs(eig(L_hat));
        lambda = max(eig_value)+min(eig_value);
        L_hat_plus = lambda*eye(m);
        L_hat_minus = lambda*eye(m)-L_hat;
        [~, p]=chol(L_hat_minus); 
        assert(0==p); %确保L_hat_minus是正定矩阵
        
        A = L_hat_plus/(m*m);
        vt = V(:,k);
        t = 0;
        t_max = 1e2;
        E = zeros(3, t_max);

        while 1
            t= t+1;
            if t==1
                E(1,1) = (1-vt)'*L_hat*(1-vt)/(m*m);
                E(2,1) = gamma*norm(vt,norm_type)/m;
                E(3,1) = E(1,1) - E(2,1);
                continue;
            end

            if norm(vt,2)<1e-6
                partial_vt = zeros(m,1);
            else
                if norm_type== 2
                    partial_vt = vt/norm(vt);
                elseif norm_type == 1
                    partial_vt = ones(m,1);
                end
            end
            
            b = 2*d_hat/(m*m)+2*L_hat_minus*vt/(m*m)+gamma*partial_vt/m;
            c = [1;zeros(n, 1)];
            c(1+find(FBL(:,k)>1)) = 1;
            cvx_begin quiet 
                variable v(m)
                minimize( v'*A*v-v'*b)
                subject to
                    -1*v <= 0;
                    v-1 <= 0;
                    v'*c == 0;
            cvx_end

            E(1,t) = (1-v)'*L_hat*(1-v)/(m*m);
            E(2,t) = gamma*norm(v,norm_type)/m;
            E(3,t) = E(1,t) - E(2,t);
            
            if E(3,t-1)-E(3,t)<epsilon_E || t>t_max
                if DEBUG_FLAG
                    loss_term_order = log10(abs(E(1,t)));
                    smooth_term_order = log10(abs(E(2,t)));
                    
                    max_order_diff = 3;
                    if smooth_term_order-loss_term_order>max_order_diff
%                         error('over large gamma initialization!');
                    end
                end
                break;
            else
                vt = v;
            end
        end
        V(:,k) = v;
    end
    para_set{iter_times}.f = f(2:end);
    para_set{iter_times}.V = V(2:end,:);
    
    J_val(2, iter_times) = J_func(f, V, W, Y, alpha_list, beta_list, gamma_list, norm_type, model_type);
    
    if DEBUG_FLAG && SHOW_DETAILS
        time_rec(2, iter_times) = toc;
        [~, ix]=sort(V, 'descend');
        fprintf(1, '%02d-V,\t J(V)=%+5.3e,\t Time=%5.3f | (%d,%d,%d)-(%d,%d,%d)\n\n',...
            iter_times, J_val(2, iter_times), time_rec(2, iter_times), ix(1:3,1), ix(1:3,2));
    end
   
    if abs(J_val(1,iter_times)-J_val(2,iter_times))<epsilon_J || iter_times>=max_iter_times
        break;
    end
end

J_val = J_val(:,1:iter_times);
para_set = para_set(1, 1:iter_times);

f(1) = [];
V(1,:) = [];

if ~DEBUG_FLAG
    waitbar(1,hwait,str);
    close(hwait);
end

%% result feedback: f->curr_reid_score, V->feedback suggestion
if 1==query_times
    last_reid_score = [];
else
    last_reid_score = getappdata(0, 'curr_reid_score');
end
setappdata(0, 'curr_reid_score', f);
setappdata(0, 'last_reid_score', last_reid_score);
setappdata(0, 'V', V);


