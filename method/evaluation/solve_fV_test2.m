function [f, V, para_set, J_val, dist, iter_fVs] = solve_fV_test2(ctrl_para, feedback_info, groundtruth_feedback, ix_info_tab) %#ok<*STOUT,*INUSD>

DEBUG_FLAG = ctrl_para.DEBUG_FLAG;
SHOW_DETAILS = ctrl_para.SHOW_DETAILS;

if DEBUG_FLAG
    init_debug_solve_fV;    
else
    init_solve_fV;
end

% step 1: init SPF model parameters
[alpha_list, beta_list, gamma_list] = init_SPF_parameters_normalized_mver(f0, W, V, Y, model_type, norm_type, FBL, query_times, ctrl_para); %#ok<*NODEF>
para_set.alpha_list = alpha_list;
para_set.beta_list = beta_list;
para_set.gamma_list = gamma_list;


%% step 2: 交替优化F与V
fl = 1;
iter_times = 0;
V0 = V;

J_val = zeros(2, max_iter_times);
time_rec = zeros(2, max_iter_times);
iter_fVs = cell(1, max_iter_times);

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
    iter_fVs{iter_times}.f = f(2:end);
    iter_fVs{iter_times}.V = V(2:end,:);
    
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
iter_fVs = iter_fVs(1, 1:iter_times);

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

% save(sprintf('.\\temp_feedback\\%d_%d_%d_f.mat', probe_id, query_times, repeat_times), 'f');
