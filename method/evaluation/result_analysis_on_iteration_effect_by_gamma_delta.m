clc
clear
close all

cd('D:\work\code\test\SalUBM_Feedback - score - yu - mver');
addpath('.\method\evaluation\');
addpath('.\method\feedback\');
addpath('.\method\Initialization\');

model_type = 'nspf'; 
init_Y_method = 'p2g';  
init_V = 0.99;
norm_type = 2;
alpha_init_order = -0.5;
beta_init_order = 0;
gamma_init_order = -3:1:3;
delta = 0:0.1:0.9;
max_iter_times = 20;  

dataset = 'viper';
test_rank = 20;
switch dataset
    case 'viper'
        probe_num = 316;
        gallery_num = 316;
end


gamma_num = length(gamma_init_order);
delta_num = length(delta);
best_cmc_mat = zeros(gamma_num, delta_num);
better_num_mat = zeros(gamma_num, delta_num);
redo_flag = false;

if ~exist('.\result\result_analysis_on_iteration_effect_by_gamma_delta.mat', 'file') || redo_flag
    for ii=1:gamma_num
        for jj=1:delta_num
            dir_name = sprintf('%s_%s_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f', model_type, init_Y_method, init_V, norm_type, alpha_init_order, beta_init_order, gamma_init_order(ii), delta(jj), max_iter_times);
            load(['.\temp\' dir_name  '\exp_report.mat']);

            files = dir(['.\temp\' dir_name '\details\']);
            assert(probe_num == length(files)-2);

            f_iter_mat = zeros(gallery_num, max_iter_times, probe_num);
            f_sat_iter_mat = zeros(probe_num, 3, max_iter_times);
            f_spa_iter_mat = zeros(probe_num, max_iter_times);
            v_sat_iter_mat = zeros(probe_num, 2, max_iter_times);
            v_spa_iter_mat = zeros(probe_num, 2, max_iter_times);
            J_val_mat = zeros(2, max_iter_times, probe_num);

            for m=3:length(files)
                file_name = files(m).name;
                load(['.\temp\' dir_name '\details\' file_name]);

                for n=1:max_iter_times
                    f = para_set{n}.f;
                    V = para_set{n}.V;

                    assert(length(f)==gallery_num);
                    assert(size(V,1)==gallery_num);

                    f_iter_mat(:,n,id) = f;
                    f_sat_iter_mat(id,:,n) = [min(f), mean(f), max(f)];
                    f_spa_iter_mat(id,n) = (sqrt(gallery_num)-norm(f,1)/norm(f,2))/(sqrt(gallery_num)-1);
                    v_sat_iter_mat(id,:,n) = mean(V);
                    v_spa_iter_mat(id,1,n) = (sqrt(gallery_num)-norm(V(:,1),1)/norm(V(:,1),2))/(sqrt(gallery_num)-1);
                    v_spa_iter_mat(id,2,n) = (sqrt(gallery_num)-norm(V(:,2),1)/norm(V(:,2),2))/(sqrt(gallery_num)-1);
                    J_val_mat(:,:,id) = J_val;
                end
            end

            groundtruth_rank = repmat(1:gallery_num, gallery_num, 1);
            cmc_iter_mat = zeros(gallery_num, max_iter_times);
            sat_iter_mat = zeros(2, max_iter_times);
            spa_iter_mat = zeros(2, max_iter_times);
            for n=1:max_iter_times
                cmc_iter_mat(:,n) = result_evaluation(squeeze(f_iter_mat(:,n,:)), groundtruth_rank);
                sat_iter_mat(:,n) = mean(squeeze(v_sat_iter_mat(:,:,n)))';
                spa_iter_mat(:,n) = mean(squeeze(v_spa_iter_mat(:,:,n)))';
            end

            best_cmc_mat(ii,jj) = max(cmc_iter_mat(test_rank,:));
            better_num_mat(ii,jj) = sum(cmc_iter_mat(test_rank,:)>cmc_MM2015(test_rank));
        end
    end
    save('.\result\result_analysis_on_iteration_effect_by_gamma_delta.mat', 'best_cmc_mat', 'cmc_MM2015', 'cmc_dist', 'better_num_mat');
else
    load('.\result\result_analysis_on_iteration_effect_by_gamma_delta.mat');
end

hfig = figure(1);
subplot(1,2,1);
[x, y] = meshgrid(delta, gamma_init_order);
z = best_cmc_mat;
mesh(x,y,z); hold on; 

z_MM2015 = cmc_MM2015(test_rank)*ones(size(best_cmc_mat));
mesh(x,y,z_MM2015); hold on; 

z_dist = cmc_dist(test_rank,3)*ones(size(best_cmc_mat));
mesh(x,y,z_dist); hold on; 

title('best cmc by gamma and delta');
xlabel('delta');ylabel('gamma init order');zlabel('best cmc');


subplot(1,2,2);
[x, y] = meshgrid(delta, gamma_init_order);
z = better_num_mat;
mesh(x,y,z); hold on; 

title('better num by gamma and delta');
xlabel('delta');ylabel('gamma init order');zlabel('better num');


