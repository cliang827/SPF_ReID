function [V, fval, time, sparseness] = solve_for_V2(f,V0,W,Y, FBL, model_para, ctrl_para)

m = size(V0,1);
n = m - 1;

V = zeros(m,2);
fval = zeros(1,2);
time = zeros(1,2);
sparseness = zeros(1,2);

alpha_list = model_para.alpha_list;
beta_list = model_para.beta_list;
gamma_list = model_para.gamma_list;

expected_feedback_num = ctrl_para.expected_feedback_num;
model_type = ctrl_para.model_type;
norm_type = ctrl_para.norm_type;
opt_solver = ctrl_para.opt_solver;
epsilon_E = ctrl_para.epsilon_E;
inner_loop_max_iter_times = ctrl_para.inner_loop_max_iter_times;

epsilon = 1e-2;               % avoid v=1，to gurantee A is posi-definite
sparseness_threshold = 5e-2;

fval_rec = zeros(8+expected_feedback_num, inner_loop_max_iter_times, 2);
% 1-5th dimensions：Eq.(12), Eq.(15), Eq.(18), Eq.(21), Eq.(22)
% 6th dimension： Obj(vt) = vt'*A*vt-vt'*b
% 7th dimension： Obj(v) = v'*A*v-v'*b
% 8th dimension：norm(v-vt)/(m-sum(c))
% 9th - end dimension：idx of expected_feedback_num largest v

for k=1:2
    
    alpha = alpha_list(:,k);
    beta = beta_list(k);
    gamma = gamma_list(k);
    
    vt = V0(:,k);
    Yk = Y(:,k);
    Wk = W(:,:,k);
    
    P = diag(sum(Wk,2));
    switch model_type
        case 'nspf'
            f_normalized = sqrt(P)\f;
        case 'spf'
            f_normalized = f;
    end
    ff = repmat(f_normalized,[1 m])-repmat(f_normalized',[m 1]);
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
    A = (A+A')/2;

    iter_times = 0;
    while 1
        iter_times= iter_times+1;

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
        c(1+find(FBL(:,k))) = 1;
        e = ones(m,1);

        if iter_times==1
            v = vt;
        else
           %% solve for v
            switch opt_solver
                case 'cvx'
                  %% cvx solver
                    tic
                    cvx_begin quiet 
                        variable v(m)
                        minimize( v'*A*v-v'*b)
                        subject to
                            -1*v <= 0;
                            v-1 <= -1*epsilon; 
                            v'*c == 0;
                            v'*e == expected_feedback_num;
                    cvx_end
                    fval(k) = v'*A*v-v'*b;
                    time(k) = time(k)+toc;
                    sparseness(k) = (sqrt(m)-norm(v,1)/norm(v,2))/(sqrt(m)-1);
                    assert(sparseness(k)>sparseness_threshold);

                case 'quadprog'
                  %% matlab solver
                    tic
                    H = 2*A;
                    z = -b;
                    Aeq = cat(2,c,e)';
                    beq = [0;expected_feedback_num];
                    lb = zeros(m,1);
                    ub = ones(m,1)-epsilon;
                    options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off');
                    [v, temp] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
                    v(v<0) = 0;
                    fval(k) = temp;
                    time(k) = time(k)+toc;
                    sparseness(k) = (sqrt(m)-norm(v,1)/norm(v,2))/(sqrt(m)-1);
                    assert(sparseness(k)>sparseness_threshold);
%                     if sparseness(k)<=sparseness_threshold
%                         sparseness(k)
%                         assert(sparseness(k)>sparseness_threshold);
%                     end

                case 'test' 
                  %% matlab solver
                    tic
                    H = 2*A;
                    z = -b;
                    Aeq = cat(2,c,e)';
                    beq = [0;expected_feedback_num];
                    lb = zeros(m,1);
                    ub = ones(m,1)-epsilon;
                    options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off');
                    [quadprog_v, quadprog_fval] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
                    quadprog_v(quadprog_v<0) = 0;
                    quadprog_time = toc;
                    quadprog_sparseness = (sqrt(m)-norm(quadprog_v,1)/norm(quadprog_v,2))/(sqrt(m)-1);
                    assert(quadprog_sparseness>sparseness_threshold);

                  %% cvx solver
                    tic
                    cvx_begin quiet 
                        variable v(m)
                        minimize( v'*A*v-v'*b)
                        subject to
                            -1*v <= 0;
                            v-1 <= -1*epsilon;
                            v'*c == 0;
                            v'*e == expected_feedback_num;
                    cvx_end
                    cvx_v = v;
                    cvx_fval = v'*A*v-v'*b;
                    cvx_time = toc;
                    cvx_sparseness = (sqrt(m)-norm(cvx_v,1)/norm(cvx_v,2))/(sqrt(m)-1);
                    assert(cvx_sparseness>sparseness_threshold);

                    assert(abs(cvx_fval-quadprog_fval)/abs(cvx_fval)<1e-3);

                    if quadprog_sparseness>cvx_sparseness
                        v = quadprog_v;
                        fval(k) = quadprog_fval;
                        time(k) = time(k) + quadprog_time;
                        sparseness(k) = quadprog_sparseness;
                    else
                        v = cvx_v;
                        fval(k) = cvx_fval;
                        time(k) = time(k) + cvx_time;
                        sparseness(k) = cvx_sparseness;
                    end
            end % end of solve for v
        end
        
        [~, ix] = sort(v, 'descend');
        Eqs = Eq_func(v, L, beta, gamma, norm_type, L_hat_plus, L_hat_minus, d_hat, vt);
        fval_rec(:,iter_times,k) = [    Eqs.Eq_12; ... 
                                        Eqs.Eq_15; ... 
                                        Eqs.Eq_18; ...
                                        Eqs.Eq_21; ...
                                        Eqs.Eq_22; ...
                                        vt'*A*vt-vt'*b; ...
                                        v'*A*v-v'*b; ...
                                        norm(v-vt)/(m-sum(c)); ...
                                        ix(1:expected_feedback_num)];

        if (iter_times>1 && abs(fval_rec(5,iter_times-1,k)-fval_rec(5,iter_times,k))<epsilon_E) || iter_times>inner_loop_max_iter_times
            assert(iter_times<=inner_loop_max_iter_times);
            break;
        else
            vt = v;
        end
    end
    V(:,k) = v;
end



