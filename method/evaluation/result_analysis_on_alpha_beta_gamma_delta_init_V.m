close all
clear all
clc

userpath('D:\work\code\test\SalUBM_Feedback - score - yu - mver');
addpath('C:\Program Files\MATLAB\R2015b\toolbox\matlab\graphics');

model_type = 'nspf';
init_Y_method = 'p2g';  
init_V = [0.01 0.99];
norm_type = 1;
alpha_init_order = -1:0.5:1;
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
cmc_mat = zeros(gamma_num, beta_num, alpha_num, V_num, delta_num);
time_mat = zeros(gamma_num, beta_num, alpha_num, V_num, delta_num);
v_sat_mat = zeros(gamma_num, beta_num, alpha_num, V_num, delta_num, 2);
v_spa_mat = zeros(gamma_num, beta_num, alpha_num, V_num, delta_num, 2);
best_f = zeros(1,6);

test_rank = 20;
redo_flag = false;
    

% step 0: load data
if ~exist('.\result\result_analysis_on_alpha_beta_gamma_delta_init_V.mat', 'file') || redo_flag
    for l=1:V_num
        for d = 1:delta_num
            for i = 1:gamma_num
                for j=1:beta_num
                    for k=1:alpha_num
                        exp_name = sprintf('%s_%s_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f', ...
                            model_type, init_Y_method, init_V(l), norm_type, alpha_init_order(k), beta_init_order(j), gamma_init_order(i), delta(d), max_iter_times);
                        load(['.\temp_plus\temp\' exp_name '\exp_report.mat']);
%                         load(['.\temp\' exp_name '\exp_report.mat']);\

% 新的版本
%                        cmc_mat(i,j,k,l,d) = cmc_result(test_rank);
%                         v_sat_mat(i,j,k,l,d,:) = v_saturation;
%                         v_spa_mat(i,j,k,l,d,:) = v_sparseness;
%                         time_mat(i,j,k,l,d) = run_time;
%                         fprintf(1, '%s [%f]: | v_sat=[%.2f%%, %.2f%%] | CMC@1=%.2f%%, CMC@2=%.2f%%, CMC@5=%.2f%%, CMC@10=%.2f%%, CMC@20=%.2f%%\n', ...
%                             exp_name, run_time, 100*v_saturation(:,1), 100*v_saturation(:,2), 100*cmc_result(1), 100*cmc_result(2), 100*cmc_result(5), 100*cmc_result(10), 100*cmc_result(20));

% 老的版本
                        v_sat_mat(i,j,k,l,d,:) = mean(v_saturation);
                        n = size(v_saturation,1);
                        v_spa_mat(i,j,k,l,d,1) = (sqrt(n)-norm(v_saturation(:,1),1)/norm(v_saturation(:,1),2))/(sqrt(n)-1);
                        v_spa_mat(i,j,k,l,d,2) = (sqrt(n)-norm(v_saturation(:,2),1)/norm(v_saturation(:,2),2))/(sqrt(n)-1);
                        time_mat(i,j,k,l,d) = run_time;
                        fprintf(1, '%s [%f]: | v_sat=[%.2f%%, %.2f%%] | CMC@1=%.2f%%, CMC@2=%.2f%%, CMC@5=%.2f%%, CMC@10=%.2f%%, CMC@20=%.2f%%\n', ...
                            exp_name, run_time, 100*mean(v_saturation(:,1)), 100*mean(v_saturation(:,2)), 100*cmc_result(1), 100*cmc_result(2), 100*cmc_result(5), 100*cmc_result(10), 100*cmc_result(20)); 
                        
                        if cmc_result(20)>best_f(1)
                            best_f(1) = cmc_result(20);
                            best_f(2:6) = [init_V(l), delta(d), alpha_init_order(k), beta_init_order(j), gamma_init_order(i)];
                        end
                    end
                end
            end
        end
    end
    save('.\result\result_analysis_on_alpha_beta_gamma_delta_init_V.mat', 'cmc_mat', 'v_sat_mat', 'time_mat', 'v_spa_mat');
else
    load('.\result\result_analysis_on_alpha_beta_gamma_delta_init_V.mat');
end


% step1: f (alpha)
hfig = figure(1);
for l=1:V_num
    for d = 1:delta_num+1
        
        h = subplot(V_num, delta_num+1, (l-1)*(delta_num+1)+d);
        if d>delta_num
            cmp_result = double(cmc_mat(:,:,:,l,d-3)>cmc_mat(:,:,:,l,d-1));
            xslice = [];        %beta_init_order; -2:1:2;
            yslice = [];        %gamma_init_order; -3:1:3;
            zslice = -1:0.5:1;  %alpha_init_order; -1:0.5:1;
            slice(x,y,z,cmp_result,xslice,yslice,zslice, 'nearest');
            colorbar('hsv');
            title(sprintf('init V=%.3f', init_V(l)));
        else
            [x,y,z] = meshgrid(beta_init_order, gamma_init_order,alpha_init_order);
            xslice = [];        %beta_init_order; -2:1:2;
            yslice = [];        %gamma_init_order; -3:1:3;
            zslice = -1:0.5:1;  %alpha_init_order; -1:0.5:1;
            slice(x,y,z,cmc_mat(:,:,:,l,d),xslice,yslice,zslice, 'nearest');
            caxis([0.5 0.7]);
            colorbar('hsv');
            title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        end
        
        xlabel('beta init order');ylabel('gamma init order');zlabel('alpha init order');
    end
end
saveas(hfig,'.\result\f.fig');


% step2：V-saturation (beta/gamma)
hfig = figure(2);
for l=1:V_num
    for d = 1:delta_num
        h = subplot(V_num, delta_num, (l-1)*delta_num+d);
        v_sat = 0.5*(v_sat_mat(:,:,:,l,d,1) + v_sat_mat(:,:,:,l,d,2));
        
        [x,y,z] = meshgrid(beta_init_order, gamma_init_order,alpha_init_order);
        xslice = -2:2:2;    %beta_init_order; -2:1:2;
        yslice = [];    %gamma_init_order; -3:1:3;
        zslice = [];        %alpha_init_order; -1:0.5:1;
        slice(x,y,z,v_sat,xslice,yslice,zslice);
        colorbar;
        title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        xlabel('beta init order');ylabel('gamma init order');zlabel('alpha init order');

    end
end
saveas(hfig,'.\result\V-saturation.fig');

% step3: V-sparse (beta/gamma)
hfig = figure(3);
for l=1:V_num
    for d = 1:delta_num
        h = subplot(V_num, delta_num, (l-1)*delta_num+d);
        v_sparse = 0.5*(v_spa_mat(:,:,:,l,d,1) + v_spa_mat(:,:,:,l,d,2));
        
        [x,y,z] = meshgrid(beta_init_order, gamma_init_order,alpha_init_order);
        xslice = -2:2:2;    %beta_init_order; -2:1:2;
        yslice = [];    %gamma_init_order; -3:1:3;
        zslice = [];        %alpha_init_order; -1:0.5:1;
        slice(x,y,z,v_sparse,xslice,yslice,zslice);
        colorbar;
        title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        xlabel('beta init order');ylabel('gamma init order');zlabel('alpha init order');

    end
end
saveas(hfig,'.\result\V-sparse.fig');


% step4：V-sparse diff (beta/gamma)
hfig = figure(4);
for l=1:V_num
    for d = 1:delta_num
        h = subplot(V_num, delta_num, (l-1)*delta_num+d);
        sprse_diff = v_spa_mat(:,:,:,l,d,1)-v_spa_mat(:,:,:,l,d,2);

        [x,y,z] = meshgrid(beta_init_order, gamma_init_order,alpha_init_order);
        xslice = [];    %beta_init_order; -2:1:2;
        yslice = -3:2:3;    %gamma_init_order; -3:1:3;
        zslice = [];        %alpha_init_order; -1:0.5:1;
        slice(x,y,z,sprse_diff,xslice,yslice,zslice);
        colorbar;
        
        title(sprintf('init V=%.3f, delta = %.3f', init_V(l), delta(d)));
        xlabel('beta init order');ylabel('gamma init order');zlabel('alpha init order');
        
    end
end
saveas(hfig,'.\result\V-sparse-diff.fig');

