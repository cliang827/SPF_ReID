function [f, fval, time] = solve_for_f(A,b,e, opt_solver)

n = length(b);
A = (A+A')/2;

switch opt_solver
    case 'cvx'
        %% cvx solver
        tic
        cvx_begin quiet 
            variable f(n)
            minimize( f'*A*f-f'*b)
            subject to
                f-1<=0;
                -1*f-1<=0;
                f'*e == 0;
        cvx_end
        fval = f'*A*f-f'*b;
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
        [f, fval] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
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
        [quadprog_f, quadprog_fval] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
        quadprog_time = toc;
        
        %% cvx solver
        cvx_begin quiet 
            variable f(n)
            minimize( f'*A*f-f'*b)
            subject to
                f-1<=0;
                -1*f-1<=0;
                f'*e == 0;
        cvx_end
        cvx_f = f;
        cvx_fval = f'*A*f-f'*b;
        cvx_time = toc;
        
        assert(abs(cvx_fval-quadprog_fval)/abs(cvx_fval)<1e-3);
        
        if cvx_fval>quadprog_fval
            f = quadprog_f;
            fval = quadprog_fval;
            time = quadprog_time;
        else
            f = cvx_f;
            fval = cvx_fval;
            time = cvx_time;
        end
end



