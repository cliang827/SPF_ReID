function eta = order_map(order_range, max_para_adjust_times, dur_times, para_name)
%ע�ͣ�ͨ������alpha��gamma��ӳ�亯�����������Ż�Ŀ�������
%      ����alpha, dur_times�Ƿ��������ĳ���ʱ��
%      ����gamma, dur_times�ǲ�ѯ���ִ�


base = 10;
slope = (order_range(2)-order_range(1))/(max_para_adjust_times-1);
if strcmp('alpha', para_name)       % ����alpha: ���ŵ����������ӣ�bais��Ȩ�ؼӴ�,������÷�Ҫ���û���ע���
    order = min(order_range(2), order_range(1)+slope*dur_times);
elseif strcmp('beta', para_name)
    order = order_range(1);
elseif strcmp('gamma', para_name)   % ����gamma: ���ŵ����������ӣ�-sparse��Ȩ�ؼ�С������С����������ģ
    order = max(order_range(2), order_range(1)+slope*(dur_times-1));
end
eta = base.^order;
