function [f, fval, time] = solve_for_f2(V,W,Y, model_para, ctrl_para)

alpha_list = model_para.alpha_list;
model_type = ctrl_para.model_type;
opt_solver = ctrl_para.opt_solver;

fl = 1;

m = size(V,1);
n = m - 1;

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
A = (A+A')/2;
[~, p]=chol(A); 
assert(0==p); % assure A is positive-definite. Large V (>=1) values may trigger this error.

e = ones(n, 1);

switch opt_solver
    case 'cvx'
        %% cvx solver
        tic
        cvx_begin quiet 
            variable fu(n)
            minimize( fu'*A*fu-fu'*b)
            subject to
                fu-1<=0;
                -1*fu-1<=0;
                fu'*e == 0;
        cvx_end
        fval = fu'*A*fu-fu'*b;
        time = toc;

    case 'quadprog'
        %% matlab solver
        tic
        H = 2*A;
        z = -b;
        Aeq = e';
        beq = 0;
        lb = -1*ones(n,1);
        ub = ones(n,1);
        options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off');
        [fu, fval] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
        time = toc;
        
    case 'test' 
        %% matlab solver
        tic
        H = 2*A;
        z = -b;
        Aeq = e';
        beq = 0;
        lb = -1*ones(n,1);
        ub = ones(n,1);
        options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off');
        [quadprog_fu, quadprog_fval] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
        quadprog_time = toc;
        
        %% cvx solver
        cvx_begin quiet 
            variable fu(n)
            minimize( fu'*A*fu-fu'*b)
            subject to
                fu-1<=0;
                -1*fu-1<=0;
                fu'*e == 0;
        cvx_end
        cvx_fu = fu;
        cvx_fval = fu'*A*fu-fu'*b;
        cvx_time = toc;
        
        assert(abs(cvx_fval-quadprog_fval)/abs(cvx_fval)<1e-3);
        
        if cvx_fval>quadprog_fval
            fu = quadprog_fu;
            fval = quadprog_fval;
            time = quadprog_time;
        else
            fu = cvx_fu;
            fval = cvx_fval;
            time = cvx_time;
        end
end
f = [fl;fu];

