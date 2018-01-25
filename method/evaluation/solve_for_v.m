function [v, fval, time, sparseness] = solve_for_v(A,b,c,e, expected_feedback_num, opt_solver)

A = (A+A')/2;
m = length(b);
sigma = 1e-9; % 避免v==1，导致求f时出现A矩阵非正定的情况
sparseness_threshold = 0.5;

switch opt_solver
    case 'cvx'
        %% cvx solver
        tic
        cvx_begin quiet 
            variable v(m)
            minimize( v'*A*v-v'*b)
            subject to
                -1*v <= 0;
                v-1 <= -1*sigma; 
                v'*c == 0;
                v'*e == expected_feedback_num;
        cvx_end
        fval = v'*A*v-v'*b;
        time = toc;
        sparseness = (sqrt(m)-norm(v,1)/norm(v,2))/(sqrt(m)-1);
        assert(sparseness>sparseness_threshold);
        
    case 'quadprog'
        %% matlab solver
        tic
        H = 2*A;
        z = -b;
        Aeq = cat(2,c,e)';
        beq = [0;expected_feedback_num];
        lb = zeros(m,1);
        ub = ones(m,1)-sigma;
        options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off');
        [v, fval] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
        time = toc;
        sparseness = (sqrt(m)-norm(v,1)/norm(v,2))/(sqrt(m)-1);
        assert(sparseness>sparseness_threshold);
        
    case 'test' 
        %% matlab solver
        tic
        H = 2*A;
        z = -b;
        Aeq = cat(2,c,e)';
        beq = [0;expected_feedback_num];
        lb = zeros(m,1);
        ub = ones(m,1)-sigma;
        options = optimoptions('quadprog','Algorithm','interior-point-convex','Display','off');
        [quadprog_v, quadprog_fval] = quadprog(H,z,[],[],Aeq,beq,lb,ub,[],options);
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
                v-1 <= -1*sigma;
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
            sparseness = quadprog_sparseness;
            fval = quadprog_fval;
            time = quadprog_time;
        else
            v = cvx_v;
            sparseness = quadprog_sparseness;
            fval = cvx_fval;
            time = cvx_time;
        end
end



