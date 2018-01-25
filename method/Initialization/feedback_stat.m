function [gallery_name_tab, stat_info] = feedback_stat(feedback_info)
% purpose：从feedback_info.feedback_details中恢复gallery_name_tab和stat_info两个数据

if isempty(feedback_info)
    gallery_name_tab = [];
    stat_info.gallery_num = 0;      % 已经标记+正在建议的gallery个数
    stat_info.pos_box_num = 0;      % 标记的正性box个数
    stat_info.neg_box_num = 0;      % 标记的负性box个数
    stat_info.box_num = 0;          % 标记的box+建议的box的个数
    return;
end

n = length(feedback_info.feedback_details);
stat_info.gallery_num = n;      % 已经标记+正在建议的gallery个数
stat_info.pos_box_num = 0;      % 标记的正性box个数
stat_info.neg_box_num = 0;      % 标记的负性box个数
stat_info.box_num = 0;          % 标记的box+建议的box的个数

gallery_name_tab = cell(n,1);
for i=1:n

    gallery_name = feedback_info.feedback_details{i}.gallery_name;
    gallery_name_tab{i} = gallery_name;

    
    stat_info.pos_box_num = stat_info.pos_box_num + sum(feedback_info.feedback_details{i}.box_type==1);
    stat_info.neg_box_num = stat_info.neg_box_num + sum(feedback_info.feedback_details{i}.box_type==-1);
    stat_info.box_num = stat_info.box_num + sum(feedback_info.feedback_details{i}.body_part>0);
end
% assert(stat_info.box_num == (stat_info.pos_box_num+stat_info.neg_box_num));