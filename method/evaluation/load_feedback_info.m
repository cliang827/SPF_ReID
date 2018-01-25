%% output: feedback info on ordinary galleries and groundtruth gallery
% 1. feedback_info_tab
% 2. groudntruth_feedback

switch ctrl_para.dev_env
    case 'linux'
        dir_info.test_feedback_dir = [dir_info.feedback_dir ctrl_para.feedback_agent '/'];
    case 'windows'
        dir_info.test_feedback_dir = [dir_info.feedback_dir ctrl_para.feedback_agent '\'];
end
rand_feedback_ix_for_pcm14_method = ctrl_para.baseline_pcm14.rand_feedback_ix_for_pcm14_method;
feedback_type = ctrl_para.feedback_type;
if strcmp('v', feedback_type)
    ctrl_para.tot_repeat_times = 1;
end
tot_repeat_times = ctrl_para.tot_repeat_times;
follow_pcm14_feedback_protocol_flag = ctrl_para.follow_pcm14_feedback_protocol_flag;
fbppr = ctrl_para.fbppr;
assert(fbppr(1)==0);
assert(sum(fbppr)<=30 && sum(fbppr)>0);   
tot_query_times = length(fbppr);
tot_feedback_pair = sum(fbppr);
birth_run_tab = [];
for i=2:tot_query_times
    birth_run_tab = cat(2, birth_run_tab, (i-1)*ones(1, fbppr(i)));
end

% rand('seed', tot_feedback_pair); %#ok<RAND>
dataset_size = size(ctrl_para.prbgal_name_tab,1);
feedback_info_tab = cell(1, dataset_size);
groundtruth_feedback = cell(1, dataset_size);
err_num = 1;
err_report = {'error_code', 'probe_id', 'probe_name', 'feedback_details_id', 'gallery_name', 'err_info', 'operator'};
% groundtruth_status = zeros(2+tot_repeat_times, dataset_size);
for i=1:dataset_size
    rand('seed', i); %#ok<RAND>
    
    % step 1: load groundtruth feedback info
    groundtruth_name = ctrl_para.prbgal_name_tab{i,2};
    groundtruth_feedback{i}.gallery_name = groundtruth_name;
    body_div_dir =[dir_info.body_div_dir groundtruth_feedback{i}.gallery_name, '.mat'];
    load(body_div_dir);
    groundtruth_feedback{i}.box_rect = parse_body_div_mat(body_div_map);
    groundtruth_feedback{i}.body_part = [1;2];
    groundtruth_feedback{i}.box_type = [1;1];
    groundtruth_feedback{i}.box_conf = [1;1];
    groundtruth_feedback{i}.cur_pos = [1;1];
    groundtruth_feedback{i}.birth_run = [0;0];
    groundtruth_feedback{i}.source = ['M';'M'];
    groundtruth_feedback{i}.mark_flag = ['Y';'Y'];
    groundtruth_feedback{i}.last_update_time = [fix(clock);fix(clock)];
    groundtruth_feedback{i}.operator = {'default';'default'};

    
    
    % step 2: load feedback info
    probe_name = ctrl_para.prbgal_name_tab{i,1};
    load([dir_info.test_feedback_dir probe_name '.mat']);
    
    % treat groundtruth in feedback_info
    switch ctrl_para.treat_groundtruth_in_feedback_info_method
        case 'let-it-be'
            % do nothing
        case 'clean-if-exist'
            gallery_name_tab = feedback_stat(feedback_info);
            [include_groundtruth_flag, groundtruth_loc] = ismember(groundtruth_name, gallery_name_tab);
            if include_groundtruth_flag
                feedback_info.feedback_details(groundtruth_loc) = [];
            end
        case 'add-if-lack'
            [gallery_name_tab, stat_info] = feedback_stat(feedback_info);
            [include_groundtruth_flag, groundtruth_loc] = ismember(groundtruth_name, gallery_name_tab);
            if include_groundtruth_flag
                feedback_info.feedback_details{groundtruth_loc} = groundtruth_feedback{i};
            else
                feedback_info.feedback_details{stat_info.gallery_num+1} = groundtruth_feedback{i};         
            end
        otherwise 
            error('please identify the manner to treat the groundtruth when loading feedback info!');
    end

    [gallery_name_tab, stat_info] = feedback_stat(feedback_info);
    feedback_num = stat_info.gallery_num;
    feedback_rec = zeros(2, feedback_num); % each row corresponds a body part
    gallery_name_tab_by_part = {gallery_name_tab, gallery_name_tab};
    for j=feedback_num:-1:1
        feedback_info.feedback_details{j}.birth_run = [0;0];
        gallery_name = feedback_info.feedback_details{j}.gallery_name;

        % identify gallery_name_tab_by_part
        mark_flag = feedback_info.feedback_details{j}.mark_flag;
        for k=1:2
            if strcmp('N', mark_flag(k))
                gallery_name_tab_by_part{k}(j) = [];
            end
        end
        
        % adjust box_conf
        box_type = feedback_info.feedback_details{j}.box_type;
        box_conf = feedback_info.feedback_details{j}.box_conf;
        for k=1:2
            if box_type(k)<0
                box_conf(k)=1;
            elseif box_type(k)>0
%                 box_conf(k)=1;
            end
        end
        feedback_info.feedback_details{j}.box_conf = box_conf;
        
        % check feedback details' valid
        if sum(fbppr)>0
            [ok_flag, err_info] = check_feedback_validity(feedback_info.feedback_details{j});
            if ok_flag(1) && ok_flag(2)
                body_part = feedback_info.feedback_details{j}.body_part;
                box_type = feedback_info.feedback_details{j}.box_type;
                feedback_rec(:,j) = body_part.*box_type;
            else
                operator = feedback_info.feedback_details{j}.operator;
                for k=1:2
                    if ~ok_flag(k)
                        err_num = err_num + 1;
                        err_report{err_num, 1} = 'validity';
                        err_report{err_num, 2} = i;
                        err_report{err_num, 3} = probe_name;
                        err_report{err_num, 4} = j;
                        err_report{err_num, 5} = gallery_name;
                        err_report{err_num, 6} = err_info{k};
                        err_report{err_num, 7} = operator{k};
                    end
                end
            end
        end
    end

    % check feedback details' coverage
    if strcmp(feedback_type, 'v') && sum(fbppr)>0
        exp_times = size(exp_para_set, 1);
        for j=1:exp_times
            V_result_dir = ['.\temp\' strrep(exp_name_set{j}, 'v', 'nv') '\details\'];
            [ok_flag, err_info] = check_feedback_coverage(probe_name, gallery_name_tab_by_part, V_result_dir, fbppr);

            if ~ok_flag
                err_num = err_num + 1;
                err_report{err_num, 1} = 'coverage';
                err_report{err_num, 2} = i;
                err_report{err_num, 3} = probe_name;
                err_report{err_num, 4} = err_info.not_covered_gallery_num;
                err_report{err_num, 5} = err_info.not_covered_gallery_name;
                err_report{err_num, 6} = 'coverage check failed';
                err_report{err_num, 7} = exp_name_set{j};
            end
        end
    end
    
    % check feedback details' repeatness
    if length(unique(gallery_name_tab))~=feedback_num
        err_num = err_num + 1;
        err_report{err_num, 1} = 'repeatness';
        err_report{err_num, 2} = i;
        err_report{err_num, 3} = probe_name;
        err_report{err_num, 6} = 'found repeat gallery names in feedback details';
        err_report{err_num, 7} = operator;
    end
    
    if err_num>1
        continue;
    end
    
    % step 3.1: generate rand_feedback_ix_for_pcm14
    assert(sum(mod(fbppr,2))==0);   % for fair comparision between ours and pcm14
    fbppp = fbppr/2;                % fbppp: feedback pair (pos + neg) per part    
                                    % fbppr: feedback pair (torso + leg) per run
    ctrl_para.fbppp = fbppp;
    rand_feedback_ix_for_pcm14 = cell(tot_repeat_times, tot_query_times);
    switch rand_feedback_ix_for_pcm14_method
        case 'allow-one-node-repreatness'
            for k=1:2
                valid_ix_pos = find(feedback_rec(k,:)>0);
                valid_ix_neg = find(feedback_rec(k,:)<0);

                valid_pos_num = length(valid_ix_pos);
                valid_neg_num = length(valid_ix_neg);

                assert(valid_pos_num*valid_neg_num>=sum(fbppp));
                for repeat_times=1:tot_repeat_times
                    part_feedback_pair_ix = randperm(valid_pos_num*valid_neg_num);

                    for query_times=1:tot_query_times
                        feedback_num = sum(fbppp(1:query_times));
                        if 0 == feedback_num
                            continue;
                        end
                        temp = part_feedback_pair_ix(1:feedback_num);
                        [pos_ix, neg_ix] = ind2sub([valid_pos_num, valid_neg_num], temp);
                        temp_ix = cat(1, k*ones(1, feedback_num), [valid_ix_pos(pos_ix); valid_ix_neg(neg_ix)]);
                        rand_feedback_ix_for_pcm14{repeat_times,query_times} = cat(2, rand_feedback_ix_for_pcm14{repeat_times,query_times},temp_ix);
                    end
                end
            end

        case 'forbid-node-repeatness'
            tot_fbppp_num = sum(fbppp);
            for k=1:2
                valid_ix_pos = find(feedback_rec(k,:)>0);
                valid_ix_neg = find(feedback_rec(k,:)<0);

                valid_pos_num = length(valid_ix_pos);
                valid_neg_num = length(valid_ix_neg);

                assert(tot_fbppp_num<=valid_pos_num && tot_fbppp_num<=valid_neg_num);

                for repeat_times=1:tot_repeat_times
                    pos_ix = valid_ix_pos(randperm(valid_pos_num));
                    neg_ix = valid_ix_neg(randperm(valid_neg_num));

                    for query_times=1:tot_query_times
                        feedback_pair_num = sum(fbppp(1:query_times));
                        if 0 == feedback_pair_num
                            continue;
                        end

                        temp_ix = cat(1, k*ones(1, feedback_pair_num), [pos_ix(1:feedback_pair_num); neg_ix(1:feedback_pair_num)]);
                        rand_feedback_ix_for_pcm14{repeat_times,query_times} = cat(2, rand_feedback_ix_for_pcm14{repeat_times,query_times},temp_ix);
                    end
                end
            end
    end

    % re-write rand_feedback_ix_for_pcm14 from plain format into stack format
    for repeat_times = 1:tot_repeat_times
        for query_times = 1:tot_query_times
            temp_plain = rand_feedback_ix_for_pcm14{repeat_times, query_times};
            if isempty(temp_plain)
                continue;
            end

            n = size(temp_plain,2)/2;
            temp_stack = zeros(2,n,2);
            for k=1:2
                temp_stack(:,:,k) = temp_plain(2:3, temp_plain(1,:)==k);
            end

            rand_feedback_ix_for_pcm14{repeat_times, query_times} = temp_stack;
        end
    end
    feedback_info.rand_feedback_ix_for_pcm14 = rand_feedback_ix_for_pcm14; 
    feedback_info.consider_groundtruth_flag_for_pcm14 = zeros(1, tot_repeat_times);


    % step 3.2: generate rand_feedback_ix
    switch feedback_type
        case 'nv'
            if strcmp('forbid-node-repeatness', rand_feedback_ix_for_pcm14_method) && ...
                    follow_pcm14_feedback_protocol_flag                     
                
                % copy rand_feedback_ix_for_pcm14 to rand_feedback_ix
                rand_feedback_ix_for_pcm14 = feedback_info.rand_feedback_ix_for_pcm14;
                rand_feedback_ix = cell(tot_repeat_times, tot_query_times, 2);
                
                for repeat_times = 1:tot_repeat_times
                    for query_times = 1:tot_query_times
                        temp = rand_feedback_ix_for_pcm14{repeat_times, query_times};
                        if isempty(temp)
                            continue;
                        else
                            for k=1:2
                                temp_k = temp(:,:,k);
                                rand_feedback_ix{repeat_times,query_times,k} = temp_k(:)';
                            end
                        end
                    end
                end
            else
                rand_feedback_ix = cell(tot_repeat_times, tot_query_times, 2);
                for k=1:2
                    valid_ix = find(feedback_rec(k,:)~=0);
                    valid_ix_num = length(valid_ix);
                    assert(valid_ix_num>=sum(fbppr));

                    for repeat_times=1:tot_repeat_times
                        new_ix = randperm(valid_ix_num);
                        new_valid_ix = valid_ix(new_ix);
                        for query_times=1:tot_query_times
                            rand_feedback_ix{repeat_times,query_times,k} = new_valid_ix(1:sum(fbppr(1:query_times)));
                        end
                    end
                end
            end
            feedback_info.rand_feedback_ix = rand_feedback_ix;
            
        case 'v'
            feedback_ix = cell(1, tot_query_times, 2);
            feedback_info.feedback_ix = feedback_ix;
            
            for k=1:2
                valid_ix = find(feedback_rec(k,:)~=0);
                valid_ix_num = length(valid_ix);
                assert(valid_ix_num>=sum(fbppr));
            end
    end

%     [tf, loc] = ismember(groundtruth_name, gallery_name_tab);
%     feedback_info.include_groundtruth_flag = include_groundtruth_flag;
%     feedback_info.select_groundtruth_flag = select_groundtruth_flag;
%     groundtruth_status(:,i) = [double(tf); loc; select_groundtruth_flag];
    feedback_info.consider_groundtruth_flag = zeros(1, tot_repeat_times);
    feedback_info.birth_run_tab = birth_run_tab;
    feedback_info_tab{i} = feedback_info;
    
    
end

if err_num>1
    save('.\temp\feedback_invalid_list.mat', 'err_report');
    error('invalid feedback found! see err_report in��.\\temp\\feedback_invalid_list.mat�� for details. \n');
end