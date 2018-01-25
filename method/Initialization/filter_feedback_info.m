function feedback_info = filter_feedback_info(feedback_info, valid_id)

% feedback_info.gallery_name_tab = feedback_info.gallery_name_tab(valid_id);
feedback_info.info_details = feedback_info.info_details(valid_id);
feedback_info.stat_info.gallery_num = length(valid_id);
feedback_info.stat_info.pos_box_num = 0;
feedback_info.stat_info.neg_box_num = 0;
for i=1:length(valid_id)
    box_type = feedback_info.info_details{i}.box_type;
    feedback_info.stat_info.pos_box_num = feedback_info.stat_info.pos_box_num + sum(box_type>0);
    feedback_info.stat_info.neg_box_num = feedback_info.stat_info.neg_box_num + sum(box_type<0);
end
