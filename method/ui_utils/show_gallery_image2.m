function curr_image_handle = show_gallery_image2(gallery_image, picture_name, curr_axes)

feedback_info = getappdata(0, 'feedback_info');
gallery_name_tab = feedback_stat(feedback_info);

[tf, loc] = ismember(picture_name, gallery_name_tab);
if tf
    box_rect = feedback_info.feedback_details{loc}.box_rect;
    cur_pos = feedback_info.feedback_details{loc}.cur_pos;
    body_part = feedback_info.feedback_details{loc}.body_part;
    
    ix_mask = logical(body_part);
    box_rect = box_rect(ix_mask,:);
    cur_pos = cur_pos(ix_mask);
    
    [~, curr_image_handle] = show_feedback_box(curr_axes, gallery_image, box_rect, cur_pos);
else
    axes(curr_axes);
    curr_image_handle = imshow(gallery_image);                              % չʾͼƬ
end









