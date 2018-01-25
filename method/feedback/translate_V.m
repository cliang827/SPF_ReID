function [feedback_suggest_mat, feedback_info] = translate_V(feedback_info, translate_method)

V = getappdata(0, 'V');
feedback_num = getappdata(0, 'fbppr');
prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
query_times = getappdata(0, 'query_times');

if query_times>1 && strcmp('overlap-without-others', translate_method)
    translate_method = 'overlap';
end    

feedback_invalid_mat = zeros(size(V));
feedback_suggest_mat = zeros(size(V));
[~, ix] = sort(V, 'descend');
switch translate_method
    case 'non-overlap' 
        % purpose: always generate feedback_num suggest galleries that  
        %          not included in the feedback_info 
        
        % step 1: feedback_invalid_mat
        [~, stat_info] = feedback_stat(feedback_info);
        for i=1:stat_info.gallery_num
            gallery_name = feedback_info.feedback_details{i}.gallery_name;
            mark_flag = feedback_info.feedback_details{i}.mark_flag;
            [~, loc] = ismember(gallery_name, prbgal_name_tab(:,2));
            for k=1:2
                if strcmp('Y', mark_flag(k))
                    feedback_invalid_mat(loc, k) = 1;
                end
            end
        end
        assert(sum(feedback_invalid_mat(:))==stat_info.box_num);
        
        % step 2: feedback_suggest_mat
        for k=1:2
            invalid_ix = feedback_invalid_mat(ix(:,k),k);
            valid_ix = ix(invalid_ix==0,k);

            if length(valid_ix)>feedback_num
                feedback_suggest_mat(valid_ix(1:feedback_num),k) = 1;
            else
                feedback_suggest_mat(valid_ix(1:end),k) = 1;
            end
        end
        
    case 'overlap'
        % purpose: generate galleries that not labeled by feedback_info,
        %          which means actual number of suggest galleries may < feedback_num
        for k=1:2
            feedback_suggest_mat(ix(1:feedback_num,k),k) = 1;
        end

    case 'overlap-without-others'
        for k=1:2
            feedback_suggest_mat(ix(1:feedback_num,k),k) = 1;
        end
        
        [~, stat_info] = feedback_stat(feedback_info);
        for i=stat_info.gallery_num:-1:1
            mark_flag = feedback_info.feedback_details{i}.mark_flag;
            gallery_name = feedback_info.feedback_details{i}.gallery_name;
            [~, loc] = ismember(gallery_name, prbgal_name_tab(:,2));
            erase_flag = true;
            for k=1:2
                if strcmp('Y', mark_flag(k)) && feedback_suggest_mat(loc, k)
                    erase_flag = false;
                    continue;
                elseif strcmp('Y', mark_flag(k)) 
                    mark_flag(k) = 'N';
                    feedback_info.feedback_details{i}.body_part(k) = 0;
                    feedback_info.feedback_details{i}.box_type(k) = 0;
                    feedback_info.feedback_details{i}.box_conf(k) = 0;
                    feedback_info.feedback_details{i}.cur_pos(k) = 0;
                    feedback_info.feedback_details{i}.birth_run(k) = 0;              % 代表是哪一轮检索后产生的（出生轮次）
                    feedback_info.feedback_details{i}.source(k) = 'U';
                    feedback_info.feedback_details{i}.mark_flag(k) = 'N';
                    feedback_info.feedback_details{i}.last_update_time(k,:) = zeros(1,6);
                    feedback_info.feedback_details{i}.operator{k} = 'default';
                end
            end
            
            if erase_flag
                feedback_info.feedback_details(i) = [];
            end
        end 
        
    otherwise
        error('lack of translate_method!');
end


        


