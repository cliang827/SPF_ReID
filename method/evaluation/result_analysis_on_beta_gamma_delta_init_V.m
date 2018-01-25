close all
clear all
clc

addpath('C:\Program Files\MATLAB\R2015b\toolbox\matlab\graphics');

model_type = 'nspf';
init_Y_method = 'p2g';  
init_V = [0.01 0.99];
norm_type = 1;
alpha_init_order = -0.5;
beta_init_order = -2:1:2;
gamma_init_order = -3:1:3;
delta = [0 0.5 1];
max_iter_times = 5;

% model_type = 'nspf';
% init_Y_method = 'p2g';  
% init_V = [0.01 0.99];
% norm_type = 1;
% alpha_init_order = -1.5:0.5:3;
% beta_init_order = -3:1:3;
% gamma_init_order = -8;
% delta = [0 0.5 1];
% max_iter_times = 5;

V_num = length(init_V);
alpha_num = length(alpha_init_order);
beta_num = length(beta_init_order);
gamma_num = length(gamma_init_order);
delta_num = length(delta);
cmc_mat = zeros(gamma_num, beta_num, V_num, delta_num);
time_mat = zeros(gamma_num, beta_num, V_num, delta_num);
v_sat_mat = zeros(gamma_num, beta_num, V_num, delta_num, 2);
v_spa_mat = zeros(gamma_num, beta_num, V_num, delta_num, 2);


test_rank = 20;
redo_flag = false;

% step 0: load data
if ~exist('.\result\result_analysis_on_alpha_beta_gamma_delta_init_V.mat', 'file') || redo_flag
    for l=1:V_num
        for d = 1:delta_num
            for i = 1:gamma_num
                for j=1:beta_num
                    exp_name = sprintf('%s_%s_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f', ...
                        model_type, init_Y_method, init_V(l), norm_type, alpha_init_order, beta_init_order(j), gamma_init_order(i), delta(d), max_iter_times);
                    load(['.\temp_plus\temp\' exp_name '\exp_report.mat']);
%                         load(['.\temp\' exp_name '\exp_report.mat']);

% 新的版本
%                     cmc_mat(i,j,l,d) = cmc_result(test_rank);
%                     v_sat_mat(i,j,k,l,d,:) = v_saturation;
%                     v_spa_mat(i,j,k,l,d,:) = v_sparseness;
%                     time_mat(i,j,l,d) = run_time;
%                     fprintf(1, '%s [%f]: | v_sat=[%.2f%%, %.2f%%] | CMC@1=%.2f%%, CMC@2=%.2f%%, CMC@5=%.2f%%, CMC@10=%.2f%%, CMC@20=%.2f%%\n', ...
%                         exp_name, run_time, 100*v_saturation(1,1), 100*v_saturation(1,2), 100*cmc_result(1), 100*cmc_result(2), 100*cmc_result(5), 100*cmc_result(10), 100*cmc_result(20)); 

% 老的版本
                    cmc_mat(i,j,l,d) = cmc_result(test_rank);
                    v_sat_mat(i,j,l,d,:) = mean(v_saturation);
                    n = size(v_saturation,1);
                    v_spa_mat(i,j,l,d,1) = (sqrt(n)-norm(v_saturation(:,1),1)/norm(v_saturation(:,1),2))/(sqrt(n)-1);
                    v_spa_mat(i,j,l,d,2) = (sqrt(n)-norm(v_saturation(:,2),1)/norm(v_saturation(:,2),2))/(sqrt(n)-1);
                    time_mat(i,j,l,d) = run_time;
                    fprintf(1, '%s [%f]: | v_sat=[%.2f%%, %.2f%%] | CMC@1=%.2f%%, CMC@2=%.2f%%, CMC@5=%.2f%%, CMC@10=%.2f%%, CMC@20=%.2f%%\n', ...
                        exp_name, run_time, 100*mean(v_saturation(:,1)), 100*mean(v_saturation(:,2)), 100*cmc_result(1), 100*cmc_result(2), 100*cmc_result(5), 100*cmc_result(10), 100*cmc_result(20)); 
                end
            end
        end
    end
    save('.\result\result_analysis_on_beta_gamma_delta_init_V.mat', 'cmc_mat', 'v_sat_mat', 'time_mat', 'v_spa_mat');
else
    load('.\result\result_analysis_on_beta_gamma_delta_init_V.mat');
end

% step1: f (alpha)
hfig = figure(1);
for l=1:V_num
    for d = 1:delta_num
        h = subplot(V_num, delta_num, (l-1)*delta_num+d);
        [x, y] = meshgrid(beta_init_order, gamma_init_order);
        z = cmc_mat(:,:,l,d);
        mesh(x,y,z); hold on;
        title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        xlabel('beta init order');ylabel('gamma init order');zlabel(sprintf('CMC@%d',test_rank));
    end
end



% step2：V-saturation (beta/gamma)
hfig = figure(2);
for l=1:V_num
    for d = 1:delta_num
        h = subplot(V_num, delta_num, (l-1)*delta_num+d);
        [x,y] = meshgrid(beta_init_order, gamma_init_order);
        z_v_sat_torso = v_sat_mat(:,:,l,d,1);
        mesh(x,y,z_v_sat_torso); hold on;
        z_v_sat_leg = v_sat_mat(:,:,l,d,2);
        mesh(x,y,z_v_sat_leg);

        title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        xlabel('beta init order');ylabel('gamma init order');zlabel('Saturation');
    end
end



% step3: V-sparse (beta/gamma)
figure(3);
for l=1:V_num
    for d = 1:delta_num
        h = subplot(V_num, delta_num, (l-1)*delta_num+d);
        [x,y] = meshgrid(beta_init_order, gamma_init_order);
        z_sparse_torso = v_spa_mat(:,:,l,d,1);
        mesh(x,y,z_sparse_torso); hold on;
        z_sparse_leg = v_spa_mat(:,:,l,d,2);
        mesh(x,y,z_sparse_leg);
        title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        xlabel('beta init order');ylabel('gamma init order');zlabel('Sparse');

    end
end

% 图4：V-torso 与 V-leg的差异 （考察gamma的效果）
hfig = figure(4);
for l=1:V_num
    for d = 1:delta_num
        h = subplot(V_num, delta_num, (l-1)*delta_num+d);
        [x,y] = meshgrid(beta_init_order, gamma_init_order);

        z = v_spa_mat(:,:,l,d,1)-v_spa_mat(:,:,l,d,2);
        mesh(x,y,z); 
        title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        xlabel('beta init order');ylabel('gamma init order');zlabel(sprintf('Sparse Diff @ %d',test_rank));
    end
end


