function eta = order_map(order_range, max_para_adjust_times, dur_times, para_name)
%注释：通过绘制alpha和gamma的映射函数，来调整优化目标的性质
%      对于alpha, dur_times是反馈样本的持续时间
%      对于gamma, dur_times是查询的轮次


base = 10;
slope = (order_range(2)-order_range(1))/(max_para_adjust_times-1);
if strcmp('alpha', para_name)       % 对于alpha: 随着迭代次数增加，bais项权重加大,即排序得分要与用户标注相符
    order = min(order_range(2), order_range(1)+slope*dur_times);
elseif strcmp('beta', para_name)
    order = order_range(1);
elseif strcmp('gamma', para_name)   % 对于gamma: 随着迭代次数增加，-sparse项权重减小，逐步缩小建议样本规模
    order = max(order_range(2), order_range(1)+slope*(dur_times-1));
end
eta = base.^order;
