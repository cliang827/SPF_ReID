clear
clc

Initialization2;

agent_name = 'mm15';
src_dir = [dir_info.data_dir 'agent\' agent_name '.mat'];
dst_dir = [dir_info.feedback_dir agent_name '\'];

load(src_dir);
[probe_num, gallery_num, part_num] = size(p2g_dist);
p2g_mat = zeros(probe_num, gallery_num, part_num);
switch agent_name
    case 'mm15'
        for part_id = 1:part_num
            p2g_mat(:,:,part_id) = (p2g_dist(:,:,part_id)+g2p_dist(:,:,part_id)')/2;
        end
    case 'cvpr13'
        
    case 'cvpr10'
end

feedback_info.operator = agent_name;
feedback_info.query_times = 1;

for probe_id=1:probe_num
    feedback_info.probe_info.probe_name = prbgal_name_tab{probe_id,1};
    feedback_info.probe_info.probe_id = probe_id;
    
    [last_update_time_mask, source, mark_flag, birth_run, body_part, box_type, box_conf, cur_pos] = ...
        translate_dist_as_feedback(squeeze(p2g_mat(probe_id,:,:))');
    feedback_info.feedback_details = cell(1,gallery_num);
    for gallery_id=1:gallery_num
        feedback_info.feedback_details{1,gallery_id}.gallery_name = ...
            prbgal_name_tab{gallery_id,2};
        
        feedback_info.feedback_details{1,gallery_id}.last_update_time = ...
            repmat(fix(clock), 2, 1).*repmat(last_update_time_mask(:,gallery_id), 1, 6);
        
        feedback_info.feedback_details{1,gallery_id}.source = cell2mat(source(:, gallery_id)); 
        feedback_info.feedback_details{1,gallery_id}.mark_flag = cell2mat(mark_flag(:, gallery_id)); 
        feedback_info.feedback_details{1,gallery_id}.birth_run = birth_run(:, gallery_id);
        
        load([dir_info.body_div_dir prbgal_name_tab{gallery_id,2} '.mat']);
        feedback_info.feedback_details{1,gallery_id}.box_rect = parse_body_div_mat(body_div_map);
        
        feedback_info.feedback_details{1,gallery_id}.body_part = body_part(:, gallery_id);
        feedback_info.feedback_details{1,gallery_id}.box_type = box_type(:, gallery_id);
        feedback_info.feedback_details{1,gallery_id}.box_conf = box_conf(:, gallery_id);
        feedback_info.feedback_details{1,gallery_id}.cur_pos = cur_pos(:, gallery_id);    
        
        feedback_info.feedback_details{1,gallery_id}.operator = agent_name;
    end
    save([dst_dir feedback_info.probe_info.probe_name '.mat'], 'feedback_info');
end






