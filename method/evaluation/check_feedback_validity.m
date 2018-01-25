function [ok_flag, err_info] = check_feedback_validity(feedback_details)

body_part = feedback_details.body_part;
box_type = feedback_details.box_type;
box_conf = feedback_details.box_conf;
cur_pos = feedback_details.cur_pos;
source = feedback_details.source;
mark_flag = feedback_details.mark_flag;
last_update_time = feedback_details.last_update_time;


ok_flag = [true;true];
err_info = cell(2,1);
for k=1:2
    if box_type(k)~=0 && box_conf(k)>0 && cur_pos(k)~=0 && ...
            ~strcmp(source(k), 'U') && strcmp(mark_flag(k), 'Y') && last_update_time(k,1)~=0
        ok_flag(k) = true;
        err_info{k} = '';
    elseif box_type(k)==0 && box_conf(k)==0 && cur_pos(k)==0 && ...
            strcmp(source(k), 'U') && strcmp(mark_flag(k), 'N') && last_update_time(k,1)==0
        ok_flag(k) = true;
        err_info{k} = '';
    else
        ok_flag(k) = false;
        if k==1
            err_info1 = 'torso part: ';
        elseif k==2
            err_info1 = 'leg part: ';
        end
        
        switch mark_flag(k)
            case 'Y'
                if body_part(k)==0
                    err_info2 = 'invalid body_part ';
                elseif box_type(k)==0
                    err_info2 = 'invalid box_type';
                elseif box_conf(k)==0
                    err_info2 = 'invalid box_conf';
                elseif cur_pos(k)==0
                    err_info2 = 'invalid cur_pos';
                elseif strcmp(source(k), 'U')
                    err_info2 = 'invalid source';
                elseif last_update_time(k,1)==0
                    err_info2 = 'last_update_time';
                end
                
            case 'N'
                if body_part(k)>0
                    err_info2 = 'invalid body_part ';
                elseif box_type(k)~=0
                    err_info2 = 'invalid box_type';
                elseif box_conf(k)>0
                    err_info2 = 'invalid box_conf';
                elseif cur_pos(k)~=0
                    err_info2 = 'invalid cur_pos';
                elseif ~strcmp(source(k), 'U')
                    err_info2 = 'invalid source';
                elseif last_update_time(k,1)>0
                    err_info2 = 'last_update_time';
                end
        end
        err_info{k} = [err_info1 err_info2];
        break;
    end
end