feedback_info = getappdata(0, 'feedback_info');
feedback_num = length(feedback_info.feedback_details);
for i=feedback_num:-1:1
    mark_flag = feedback_info.feedback_details{i}.mark_flag;
    if strcmp('N', mark_flag(1)) && strcmp('N', mark_flag(2))
        feedback_info.feedback_details(i)=[];
        continue;
    end
    
%     gallery_name = feedback_info.feedback_details{1,i}.gallery_name;
    last_update_time = feedback_info.feedback_details{1,i}.last_update_time;
    source = feedback_info.feedback_details{1,i}.source;
    birth_run = feedback_info.feedback_details{1,i}.birth_run;
    box_rect = feedback_info.feedback_details{1,i}.box_rect;
    body_part = feedback_info.feedback_details{1,i}.body_part;
    box_type = feedback_info.feedback_details{1,i}.box_type;
    box_conf = feedback_info.feedback_details{1,i}.box_conf;
    cur_pos = feedback_info.feedback_details{1,i}.cur_pos;
%     operator = feedback_info.feedback_details{1,i}.operator;
    
    for k=1:2
        switch mark_flag(k)
            case 'Y'
                assert(last_update_time(k,1)~=0);
                assert(strcmp('U', source(k))==0);
                assert(birth_run(k)<query_times);
                assert(box_rect(k,1)~=0);
                assert(body_part(k)~=0);
                assert(box_type(k)~=0);
                assert(box_conf(k)~=0);
                assert(cur_pos(k)~=0);
                
            case 'N'
                last_update_time(k,:) = zeros(1,6);
                source(k) = 'U';
                birth_run(k) = 0;
                assert(box_rect(k,1)~=0);
                body_part(k) = 0;
                box_type(k) = 0;
                box_conf(k) = 0;
                cur_pos(k) = 0;
        end
    end
end