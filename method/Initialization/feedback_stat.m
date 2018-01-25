function [gallery_name_tab, stat_info] = feedback_stat(feedback_info)
% purpose����feedback_info.feedback_details�лָ�gallery_name_tab��stat_info��������

if isempty(feedback_info)
    gallery_name_tab = [];
    stat_info.gallery_num = 0;      % �Ѿ����+���ڽ����gallery����
    stat_info.pos_box_num = 0;      % ��ǵ�����box����
    stat_info.neg_box_num = 0;      % ��ǵĸ���box����
    stat_info.box_num = 0;          % ��ǵ�box+�����box�ĸ���
    return;
end

n = length(feedback_info.feedback_details);
stat_info.gallery_num = n;      % �Ѿ����+���ڽ����gallery����
stat_info.pos_box_num = 0;      % ��ǵ�����box����
stat_info.neg_box_num = 0;      % ��ǵĸ���box����
stat_info.box_num = 0;          % ��ǵ�box+�����box�ĸ���

gallery_name_tab = cell(n,1);
for i=1:n

    gallery_name = feedback_info.feedback_details{i}.gallery_name;
    gallery_name_tab{i} = gallery_name;

    
    stat_info.pos_box_num = stat_info.pos_box_num + sum(feedback_info.feedback_details{i}.box_type==1);
    stat_info.neg_box_num = stat_info.neg_box_num + sum(feedback_info.feedback_details{i}.box_type==-1);
    stat_info.box_num = stat_info.box_num + sum(feedback_info.feedback_details{i}.body_part>0);
end
% assert(stat_info.box_num == (stat_info.pos_box_num+stat_info.neg_box_num));