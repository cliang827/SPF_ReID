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
gamma_init_order = 0;
delta = 0.5;
max_iter_times = 5;  

dataset = 'viper';
test_rank = 20;
switch dataset
    case 'viper'
        probe_num = 316;
        gallery_num = 316;
end

dir_name = sprintf('%s_%s_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f_%.3f', model_type, init_Y_method, init_V, norm_type, alpha_init_order, beta_init_order, gamma_init_order, delta, max_iter_times);
load(['.\temp\' dir_name  '\exp_report.mat']);

files = dir(['.\temp\' dir_name '\details\']);
assert(probe_num == length(files)-2);

f_iter_mat = zeros(gallery_num, max_iter_times, probe_num);
f_sat_iter_mat = zeros(probe_num, 3, max_iter_times);
f_spa_iter_mat = zeros(probe_num, max_iter_times);
v_sat_iter_mat = zeros(probe_num, 2, max_iter_times);
v_spa_iter_mat = zeros(probe_num, 2, max_iter_times);
J_val_mat = zeros(2, max_iter_times, probe_num);

for i=3:length(files)
    file_name = files(i).name;
    load(['.\temp\' dir_name '\details\' file_name]);
    
    for j=1:max_iter_times
        f = para_set{j}.f;
        V = para_set{j}.V;
        
        assert(length(f)==gallery_num);
        assert(size(V,1)==gallery_num);
       
        f_iter_mat(:,j,id) = f;
        f_sat_iter_mat(id,:,j) = [min(f), mean(f), max(f)];
        f_spa_iter_mat(id,j) = (sqrt(gallery_num)-norm(f,1)/norm(f,2))/(sqrt(gallery_num)-1);
        v_sat_iter_mat(id,:,j) = mean(V);
        v_spa_iter_mat(id,1,j) = (sqrt(gallery_num)-norm(V(:,1),1)/norm(V(:,1),2))/(sqrt(gallery_num)-1);
        v_spa_iter_mat(id,2,j) = (sqrt(gallery_num)-norm(V(:,2),1)/norm(V(:,2),2))/(sqrt(gallery_num)-1);
        J_val_mat(:,:,id) = J_val;
    end
end

groundtruth_rank = repmat(1:gallery_num, gallery_num, 1);
cmc_iter_mat = zeros(gallery_num, max_iter_times);
sat_iter_mat = zeros(2, max_iter_times);
spa_iter_mat = zeros(2, max_iter_times);
for j=1:max_iter_times
    cmc_iter_mat(:,j) = result_evaluation(squeeze(f_iter_mat(:,j,:)), groundtruth_rank);
    sat_iter_mat(:,j) = mean(squeeze(v_sat_iter_mat(:,:,j)))';
    spa_iter_mat(:,j) = mean(squeeze(v_spa_iter_mat(:,:,j)))';
end

figure
xtick_step = ceil(max_iter_times/5);

subplot(2,3,1);
plot(1:max_iter_times, cmc_iter_mat(test_rank,:),'--gs', 'LineWidth',2, 'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
plot(1:max_iter_times, cmc_MM2015(test_rank)*ones(1, max_iter_times),'b--', 'LineWidth',2); hold on;
% plot(1:max_iter_times, cmc_dist(test_rank,1)*ones(1, max_iter_times),'k-', 'LineWidth',2,  'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
% plot(1:max_iter_times, cmc_dist(test_rank,2)*ones(1, max_iter_times),'k--', 'LineWidth',2, 'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
plot(1:max_iter_times, cmc_dist(test_rank,3)*ones(1, max_iter_times),'k-.', 'LineWidth',2, 'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
legend('our result','MM2015 result','torso+leg result');
% legend('our result','MM2015 result','torso result','leg result','torso+leg result');
set(gca,'xtick',1:xtick_step:max_iter_times);
xlabel('iteration no.'); ylabel('CMC');
grid on;

subplot(2,3,2);
plot(1:max_iter_times, sat_iter_mat(1,:),'--gs', 'LineWidth',2, 'Marker', '+', 'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
plot(1:max_iter_times, sat_iter_mat(2,:),'--gs', 'LineWidth',2, 'Marker', '*', 'MarkerSize',10, 'MarkerEdgeColor','b'); hold on;
legend('torso','leg');
set(gca,'xtick',1:xtick_step:max_iter_times);
xlabel('iteration no.'); ylabel('V Saturation');
grid on;

subplot(2,3,3);
plot(1:max_iter_times, spa_iter_mat(1,:),'--gs', 'LineWidth',2, 'Marker', '+', 'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
plot(1:max_iter_times, spa_iter_mat(2,:),'--gs', 'LineWidth',2, 'Marker', '*', 'MarkerSize',10, 'MarkerEdgeColor','b'); hold on;
legend('torso','leg');
set(gca,'xtick',1:xtick_step:max_iter_times);
xlabel('iteration no.'); ylabel('V Sparseness');
grid on;

subplot(2,3,4);
J_iter_mat = mean(J_val_mat, 3);

plot(J_iter_mat(1, 1:max_iter_times), 'r-', 'Linewidth', 2, 'Visible', 'off'); hold on;
plot(J_iter_mat(2, 1:max_iter_times), 'b-', 'Linewidth', 2, 'Visible', 'off'); hold on;
plot(2:max_iter_times, J_iter_mat(2, 1:max_iter_times-1)-J_iter_mat(2, 2:max_iter_times), 'g--', 'Linewidth', 2); hold on;

plot(J_iter_mat(1, 1:max_iter_times), 'r--'); hold on;
plot(J_iter_mat(2, 1:max_iter_times), 'b-.'); hold on;

for i=1:max_iter_times
    plot([i i], [J_iter_mat(1, i), J_iter_mat(1, i)], 'rs', 'Linewidth', 2); hold on;
    plot([i i], [J_iter_mat(1, i), J_iter_mat(2, i)], 'r-', 'Linewidth', 2); hold on;

    plot([i i], [J_iter_mat(2, i), J_iter_mat(2, i)], 'bo', 'Linewidth', 2); hold on;
    if i<max_iter_times
        plot([i i+1], [J_iter_mat(2, i), J_iter_mat(1, i+1)], 'b-', 'Linewidth', 2); hold on;
    end
end

grid on;
xlim([0 max_iter_times+1]);
set(gca,'xtick',1:xtick_step:max_iter_times);
legend('V-step', 'f-step', 'Delta E(f)');

xlabel('iteration no.');
ylabel('E(f,V)');
% title('Alternative Optmization of E(f,V)')

subplot(2,3,5);
f_sat_iter_mat = squeeze(mean(f_sat_iter_mat));
plot(1:max_iter_times, f_sat_iter_mat(1,:),'--gs', 'LineWidth',2, 'Marker', '+', 'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
plot(1:max_iter_times, f_sat_iter_mat(2,:),'--gs', 'LineWidth',2, 'Marker', '*', 'MarkerSize',10, 'MarkerEdgeColor','b'); hold on;
plot(1:max_iter_times, f_sat_iter_mat(3,:),'--gs', 'LineWidth',2, 'Marker', '>', 'MarkerSize',10, 'MarkerEdgeColor','k'); hold on;
legend('f min', 'f mean', 'f max');
set(gca,'xtick',1:xtick_step:max_iter_times);
xlabel('iteration no.'); ylabel('f Saturation');
grid on;

subplot(2,3,6);
f_spa_iter_mat = mean(f_spa_iter_mat);
plot(1:max_iter_times, f_spa_iter_mat, '--gs', 'LineWidth',2, 'Marker', '+', 'MarkerSize',10, 'MarkerEdgeColor','r'); hold on;
set(gca,'xtick',1:xtick_step:max_iter_times);
xlabel('iteration no.'); ylabel('f Sparseness');
grid on;



