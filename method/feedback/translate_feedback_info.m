function [Y, V, FBL] = translate_feedback_info(Y, V, query_times, prbgal_name_tab, feedback_info)
n = size(prbgal_name_tab,1);
FBL = zeros(n,2); % 记录反馈图像历经的轮次 FeedBackLife

feedback_num = length(feedback_info.feedback_details);
for i=1:feedback_num
    mark_flag = feedback_info.feedback_details{i}.mark_flag;
    if strcmp(mark_flag(1), 'N') && strcmp(mark_flag(2), 'N')
        continue; 
    end
    
    gallery_name = feedback_info.feedback_details{i}.gallery_name;
    body_part = feedback_info.feedback_details{i}.body_part;
    box_type = feedback_info.feedback_details{i}.box_type;
    box_conf = feedback_info.feedback_details{i}.box_conf;
    birth_run = feedback_info.feedback_details{i}.birth_run;

    [~, loc] = ismember(gallery_name, prbgal_name_tab(:,2));
    for k=1:2
        if body_part(k)>0 && strcmp(mark_flag(k), 'Y')
            assert(box_type(k)~=0);
            
            FBL(loc, k) = query_times - birth_run(k);
            Y(1+loc, k) = box_type(k)*box_conf(k);
            V(1+loc, k) = 0;
        end
    end
end



