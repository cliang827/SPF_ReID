function feedback_label = read_feedback_label(probe_id)

prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
p2g_dist = getappdata(0, 'p2g_dist');

[probe_num gallery_num body_div_num] = size(p2g_dist);
feedback_label = zeros(gallery_num, body_div_num);

probe_name = prbgal_name_tab{probe_id,1};
load(['.\data\feedback\cam_a_' probe_name, '.mat']);

label_num = length(feedback_info.info_details);
for j=1:label_num
    gallery_name = feedback_info.info_details{1,j}.gallery_name;
    body_part = feedback_info.info_details{1,j}.body_part;
    box_type = feedback_info.info_details{1,j}.box_type;
    box_conf = feedback_info.info_details{1,j}.box_conf;
    [tf loc] = ismember(gallery_name, prbgal_name_tab(:,2));
    feedback_label(loc, body_part) = box_type.*box_conf;
end



