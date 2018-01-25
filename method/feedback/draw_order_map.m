clc
clear all
close all

max_iter_times = 10;
max_para_adjust_times = 4;    
para_name = {'alpha', 'beta', 'gamma'};
line_type = {'bs--', 'r^-', 'go-.'};
init_order = [-1;0;1];
order_range = [ 0 max_para_adjust_times-1;...
                0 1;...
                0 1-max_para_adjust_times];
para_order = repmat(init_order, [1 2]) + order_range;
para_order_max = max(para_order(:));
para_order_min = min(para_order(:));
eta_tab = zeros(3, max_iter_times);


figure 
for i=1:3
    for iter_times = 1:max_iter_times
        eta_tab(i,iter_times) = log10(order_map(para_order(i,:), max_para_adjust_times, iter_times, para_name{i}));
    end
    
    plot(eta_tab(i,:), line_type{i}, 'linewidth', 2); hold on;
end
set(gca,'YLim',[para_order_min-0.5 para_order_max+1.5]);%X轴的数据显示范围
set(gca,'XTickLabel',1:1:max_iter_times);%给坐标加标签 
grid on;

str1 = '$$o_{\alpha}\left( t \right)$$';
str2 = '$$o_{\beta}\left( t \right)$$';
str3 = '$$o_{\gamma}\left( t \right)$$';
h = legend(str1,str2,str3, 'Location','NorthWest');
set(h,'Interpreter','latex')
% legend('initial alpha order', 'initial beta order', 'initial gamma order');
xlabel('feedback times t');
ylabel('order function o(t)')

