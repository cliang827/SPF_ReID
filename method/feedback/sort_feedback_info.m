function feedback_info = sort_feedback_info(feedback_info, gallery_name_list, sorted_gallery_id_list)
% note: sort feedback_details in accordance to the descend ranking of reid score
% save('.\temp\sort_feedback_details.mat', 'feedback_info', 'gallery_name_list', 'sorted_gallery_id_list');

% clear
% clc
% load('.\temp\sort_feedback_info.mat');

gallery_name_tab = feedback_stat(feedback_info);
sorted_gallery_name_list = gallery_name_list(sorted_gallery_id_list);

[~, ia, ib] = intersect(gallery_name_tab, sorted_gallery_name_list);
[~, sorted_id] = sort(ib, 'ascend');

% feedback_info.gallery_name_tab = feedback_info.gallery_name_tab(ia(sorted_id));
feedback_info.feedback_details = feedback_info.feedback_details(ia(sorted_id));