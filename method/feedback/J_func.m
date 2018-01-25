function [J, item_smooth, item_bias, item_pace, item_sparse] = J_func(f, V, W, Y, para_set, ctrl_para)

norm_type = ctrl_para.norm_type;
model_type = ctrl_para.model_type;

alpha_list = para_set.alpha_list;
beta_list = para_set.beta_list;
gamma_list = para_set.gamma_list;

item_smooth = 0;
item_bias = 0;
item_pace = 0;
item_sparse = 0;

m = size(f,1);

for k=1:2
    V_tilde = (1-V(:,k))*(1-V(:,k))';
    W_tilde = V_tilde.*W(:,:,k);
    P_tilde = diag(sum(W_tilde,2));
    Q_tilde = diag(sum(V_tilde,2));
    P = diag(sum(W(:,:,k),2));
    
    switch model_type
        case 'nspf'
            R = P\P_tilde-sqrt(P)\W_tilde/sqrt(P);
        case 'spf'
            R = P_tilde-W_tilde;
    end

    alpha = diag(alpha_list(:,k));
    beta = beta_list(k);
    gamma = gamma_list(k);
    
    item_smooth = item_smooth + 2*f'*R*f/(m*m);
    item_bias = item_bias + 2*(f-Y(:,k))'*(alpha*Q_tilde)*(f-Y(:,k))/(m*m);
    item_pace = item_pace + ones(1,m)*(beta*V_tilde)*ones(m,1)/(m*m);
    item_sparse = item_sparse + gamma*norm(V(:,k),norm_type)/m; 
end

J = item_smooth+item_bias-item_pace-item_sparse;
