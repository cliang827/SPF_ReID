% parse_feeback_info_for_pcm14 
% change index in feedback_info to that of prbgal_name_tab
[~, stat_info] = feedback_stat(feedback_info);
mark_flag_temp = zeros(2, stat_info.gallery_num);
for i=1:stat_info.gallery_num
    box_type = feedback_info.feedback_details{i}.box_type;
    mark_flag_temp(:,i) = box_type;
end

feedback_set_temp = [];
for k=1:2
    pos_ix = find(mark_flag_temp(k,:)==1);
    neg_ix = find(mark_flag_temp(k,:)==-1);
    
    pos_num = length(pos_ix);
    neg_num = length(neg_ix);
    
    if 0==pos_num || 0==neg_num
        continue;
    end
    
    temp = zeros(3, pos_num*neg_num);
    ix = 0;
    for i=1:pos_num
        for j=1:neg_num
            ix = ix + 1;
            temp(:,ix) = [k;pos_ix(i);neg_ix(j)];
        end
    end
    feedback_set_temp = cat(2, feedback_set_temp, temp);
end

feedback_set = feedback_set_temp;
part_feedback_pair_num = size(feedback_set_temp, 2);
for i=2:3
    for j = 1:part_feedback_pair_num
        gallery_name = feedback_info.feedback_details{feedback_set(i,j)}.gallery_name;
        [~, loc] = ismember(gallery_name, prbgal_name_tab(:,2));
        feedback_set(i,j) = loc;        
    end
end
