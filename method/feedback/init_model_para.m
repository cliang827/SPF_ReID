function model_para = init_model_para(W, Y, f, V, FBL, query_times, ctrl_para)

% save('.\temp\init_model_para.mat', 'W', 'Y', 'f', 'V', 'FBL', 'query_times', 'ctrl_para');

% clear all
% clc
% load('.\temp\init_model_para.mat');

m = length(f);


alpha_list = zeros(m,2);
beta_list = zeros(1,2);
gamma_list = zeros(1,2);

model_type = ctrl_para.model_type;
norm_type = ctrl_para.norm_type;
max_para_adjust_times = ctrl_para.max_para_adjust_times;
alpha_order_range = ctrl_para.alpha_order_range; 
beta_order_range = ctrl_para.beta_order_range;
gamma_order_range = ctrl_para.gamma_order_range;

for k=1:2
    % step 0: V_tilde, W_tilde, P_tilde, Q_tilde, P
    Yk = Y(:,k);
    Wk = W(:,:,k);
    Vk = V(:,k);
    P = diag(sum(Wk,2));
    V_tilde = (1-Vk)*(1-Vk)';
    W_tilde = V_tilde.*Wk;
    P_tilde = diag(sum(W_tilde,2));
    Q_tilde = diag(sum(V_tilde,2));
    P_hat = sqrt(P)\P_tilde/sqrt(P);
    W_hat = sqrt(P)\W_tilde/sqrt(P);

    % step 1: alpha
    eta_alpha = order_map(alpha_order_range, max_para_adjust_times, FBL(:,k), 'alpha');
    assert(0~=(f-Yk)'*Q_tilde*(f-Yk));
    switch model_type
        case 'nspf'
            alpha_list(2:m,k) = eta_alpha*(f'*(P_hat-W_hat)*f)/((f-Yk)'*Q_tilde*(f-Yk));
        case 'spf'
            alpha_list(2:m,k) = eta_alpha*(f'*(P_tilde-W_tilde)*f)/((f-Yk)'*Q_tilde*(f-Yk));
    end

    % step 2: beta
    f_normalized = sqrt(P)\f;
    ff = repmat(f_normalized,[1 m])-repmat(f_normalized',[m 1]);
        
    alpha = alpha_list(:,k);
    alpha_fY = repmat(alpha.*(f-Yk).*(f-Yk), [1 m]) + ...
        repmat(alpha'.*(f-Yk)'.*(f-Yk)',[m 1]);
    L = Wk.*ff.*ff + alpha_fY;
    eta_beta = order_map(beta_order_range, max_para_adjust_times, query_times, 'beta');
    beta_list(k) = eta_beta*median(L(:));
    
    % step 3£ºgamma
    L_hat = L - beta_list(k);
    E1 = (1-Vk)'*L_hat*(1-Vk)/(m*m);
    eta_gamma = order_map(gamma_order_range, max_para_adjust_times, query_times, 'gamma');
    assert(0~=norm(Vk,norm_type));
    gamma_list(k) = eta_gamma*E1*m/norm(Vk,norm_type);
end

model_para.alpha_list = alpha_list;
model_para.beta_list = beta_list;
model_para.gamma_list = gamma_list;