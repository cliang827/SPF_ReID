function curr_image_handle = show_gallery_image(gallery_image, picture_name, curr_axes)

probe_name = getappdata(0, 'probe_name');
result_dir = ['.\data\feedback\cam_a-', probe_name, '+default.mat'];

if ~exist(result_dir, 'file') % �û�û�б�ע���ļ���
    axes(curr_axes);
    curr_image_handle = imshow(gallery_image);                              % չʾͼƬ
    return;
end

load(result_dir);
feedback_gallery_name_tab = feedback_stat(feedback_info);
[tf, loc] = ismember(picture_name, feedback_gallery_name_tab);
if ~tf % ��ע�ļ���û�и÷�ͼ��
    axes(curr_axes);
    curr_image_handle = imshow(gallery_image);                              % չʾͼƬ
    return;
end

assert(strcmp(feedback_info.info_details{loc}.gallery_name, picture_name));
box_rect = feedback_info.info_details{loc}.box_rect;
cur_pos  = feedback_info.info_details{loc}.cur_pos;

[~, curr_image_handle] = show_feedback_box(curr_axes, gallery_image, box_rect, cur_pos);



