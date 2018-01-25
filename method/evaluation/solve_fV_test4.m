function [f, V, para_set, J_val, iter_fVs] = solve_fV_test4(ctrl_para, feedback_info, groundtruth_feedback, ix_info_tab) %#ok<*STOUT,*INUSD>

DEBUG_FLAG = ctrl_para.DEBUG_FLAG;
SHOW_DETAILS = ctrl_para.SHOW_DETAILS;
opt_solver = ctrl_para.opt_solver;

if DEBUG_FLAG
    init_debug_solve_fV2;
else
    init_solve_fV;
end

% step 1: init SPF model parameters
query_times = ix_info_tab(2);
[alpha_list, beta_list, gamma_list] = init_SPF_parameters_normalized_mver(W, Y0, f0, V0, model_type, norm_type, FBL, query_times, ctrl_para);
% if query_times == 1
%     [alpha_list, beta_list, gamma_list] = init_SPF_parameters_normalized_mver(W, Y0, f0, V0, model_type, norm_type, FBL, query_times, ctrl_para); %#ok<*NODEF>
%     setappdata(0, 'alpha_list', alpha_list);
%     setappdata(0, 'beta_list', beta_list);
%     setappdata(0, 'gamma_list', gamma_list);
% else
%     alpha_list = getappdata(0, 'alpha_list');
%     beta_list = getappdata(0, 'beta_list');
%     gamma_list = getappdata(0, 'gamma_list');
% end
para_set.alpha_list = alpha_list;
para_set.beta_list = beta_list;
para_set.gamma_list = gamma_list;

%% step 2: 交替优化f与V
V = V0;
Y = Y0;
f = f0;
fl = 1;
iter_times = 0;

J_val = zeros(2, max_iter_times);
time_rec = zeros(2, max_iter_times);
iter_fVs = cell(1, max_iter_times);

if SHOW_DETAILS
    if query_times==1
        fprintf(1, '\n\t query_times = %d\n', query_times);
    else
        fprintf(1, '\t query_times = %d\n', query_times);
    end
end

%% core solve_fV algorithm
while 1
    iter_times = iter_times + 1;
    
    if DEBUG_FLAG && SHOW_DETAILS
        tic
    elseif ~DEBUG_FLAG
        str=['Iteration no.',num2str(iter_times), ' -f'];
        waitbar(min(1,iter_times/waitbar_step),hwait,str);
    end
    
    if 1<query_times % in the init query, jump f-step
        %% f-step
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
        e = ones(n, 1);
        fu = solve_for_f(A,b,e, opt_solver);
        f = [fl;fu];
    end
    J_val(1, iter_times) = J_func(W, Y, f, V, para_set, norm_type, model_type);
    
    if DEBUG_FLAG && SHOW_DETAILS
        time_rec(1, iter_times) = toc;
        fprintf(1, '\t\t%02d-f,\t J(f)=%+5.3e,\t Time=%5.3f\n', iter_times, J_val(1, iter_times), time_rec(1, iter_times));
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
        
        switch model_type
            case 'nspf'
                f_normalized = sqrt(P)\f;
            case 'spf'
                f_normalized = f;
        end
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
        
        A = L_hat_plus; 
        % A = L_hat_plus/(m*m);
        vt = V(:,k);
        t = 0;
        t_max = 1e2;
        
        
        E_12 = zeros(3, t_max);
        E_15 = zeros(3, t_max);
        E_22 = zeros(3, t_max);
        E_cmp = zeros(8, t_max);
        % 第1-3维：Eq.(12), Eq.(15), Eq.(22)
        % 第4维：vt所对应的目标函数 Obj(vt) = vt'*A*vt-vt'*b
        % 第5维：v所对应的目标函数 Obj(v) = v'*A*v-v'*b
        % 第6维：v相对于vt的变化率 norm(v-vt)/(m-sum(c))
        % 第7维：
        
        while 1
            t= t+1;

            if norm_type== 2
                if norm(vt,norm_type)<1e-6
                    partial_vt = zeros(m,1);
                else
                    partial_vt = vt/norm(vt,norm_type);
                end
            elseif norm_type == 1
                partial_vt = ones(m,1);
            end
            
            b = 2*d_hat+2*L_hat_minus*vt+m*gamma*partial_vt;
            % b = 2*d_hat/(m*m)+2*L_hat_minus*vt/(m*m)+gamma*partial_vt/m;
            c = [1;zeros(n, 1)];
            e = ones(m,1);
            c(1+find(FBL(:,k))) = 1;
            
            if t==1
                [E_12(:,1), E_15(:,1), E_22(:,1)] = Ef_func(vt, L, beta, gamma, norm_type, L_hat_plus, L_hat_minus, d_hat, vt);
                
                [~, ix] = sort(vt, 'descend');
                E_cmp(:,1) = [E_12(3,1); E_15(3,1); E_22(3,1); vt'*A*vt-vt'*b; vt'*A*vt-vt'*b; norm(vt-vt)/(m-sum(c));ix(1:2)];
                continue;
            end
          
            v = solve_for_V(A,b,c,e, expected_feedback_num, opt_solver); 

            [E_12(:,t), E_15(:,t), E_22(:,t)] = Ef_func(v, L, beta, gamma, norm_type, L_hat_plus, L_hat_minus, d_hat, vt);
            
            [~, ix] = sort(v, 'descend');
            E_cmp(:,t) = [E_12(3,t); E_15(3,t); E_22(3,t); vt'*A*vt-vt'*b; v'*A*v-v'*b; norm(v-vt)/(m-sum(c));ix(1:2)];
            
            assert(E_22(3,t)-E_22(3,t-1)<epsilon_E);
            if E_22(3,t-1)-E_22(3,t)<epsilon_E || t>t_max
                break;
            else
                vt = v;
            end
        end
        V(:,k) = v;
    end
    iter_fVs{iter_times}.f = f(2:end);
    iter_fVs{iter_times}.V = V(2:end,:);
    
    J_val(2, iter_times) = J_func(W, Y, f, V, para_set, norm_type, model_type);
    
%     % momentum step for V
%     V = V0*delta + V*(1-delta);
%     V0 = V;
    
    if DEBUG_FLAG && SHOW_DETAILS
        time_rec(2, iter_times) = toc;
        [~, ix]=sort(V, 'descend');
        fprintf(1, '\t\t%02d-V,\t J(V)=%+5.3e,\t Time=%5.3f | (%d,%d,%d,%d,%d)-(%d,%d,%d,%d,%d)\n\n',...
            iter_times, J_val(2, iter_times), time_rec(2, iter_times), ix(1:5,1), ix(1:5,2));
    end
   
    if abs(J_val(1,iter_times)-J_val(2,iter_times))<epsilon_J || iter_times>=max_iter_times || 1==query_times
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

