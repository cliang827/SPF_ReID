function show_gallery_info = identify_show_gallery_info(mode)

if nargin<1
    identify_groundtruth_rank = false;
    translate_V_flag = false;
    load_feedback_log_flag = false;
elseif strcmp(mode, 'query_mode')
    identify_groundtruth_rank = true;
    translate_V_flag = true;
    load_feedback_log_flag = true;
end

dir_info = getappdata(0, 'dir_info');
show_status = getappdata(0, 'show_status');
query_times = getappdata(0, 'query_times');
probe_name = getappdata(0, 'probe_name');
prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
feedback_info = getappdata(0, 'feedback_info');

% step 1: load feedback_log or filter feedback_info
log_dir = [dir_info.test_feedback_log_dir, probe_name, '.mat'];
if query_times == 1
    if load_feedback_log_flag
        if exist(log_dir, 'file')
            load(log_dir);
        end
    end
else
    
end

% step 2: translate feedback suggestion V
if translate_V_flag
    
    % step 2.1: generate feedback_suggest
    feedback_suggestive_mat = translate_V();
    ix = find(sum(feedback_suggestive_mat,2)>0);
    suggest_gallery_num = length(ix);

    feedback_suggest.operator = 'default';
    feedback_suggest.query_times = query_times;
    feedback_suggest.probe_info.probe_name = probe_name;
    feedback_suggest.probe_info.probe_id = getappdata(0, 'probe_id');
    feedback_suggest.feedback_details=cell(1, suggest_gallery_num);

    for i=1:suggest_gallery_num
        feedback_details.gallery_name = prbgal_name_tab{ix(i),2};
        load([dir_info.body_div_dir feedback_details.gallery_name '.mat']);
        feedback_details.box_rect = parse_body_div_mat(body_div_map);
        feedback_details.body_part = [0;0];
        feedback_details.box_type = [0;0];
        feedback_details.box_conf = [0;0];
        feedback_details.cur_pos = [0;0];
        feedback_details.birth_run = [0;0];              % 代表是哪一轮检索后产生的（出生轮次）
        feedback_details.source = ['U';'U'];             % 'S'代表算法Suggest,'M'代表用户主动选取,'U'代表未知,
        feedback_details.mark_flag = ['N';'N'];          % 'Y' 表示被用户采纳, 'N'表示未被用户采纳
        feedback_details.last_update_time = zeros(2,6);
        feedback_details.operator = 'default';

        for k=1:2
            if 1==feedback_suggestive_mat(ix(i),k) 
                feedback_details.body_part(k) = k;
                feedback_details.birth_run(k) = query_times;
                feedback_details.source(k) = 'S';
                feedback_details.last_update_time(k,:) = fix(clock);
            end
        end
        
        feedback_suggest.feedback_details{i} = feedback_details;
    end

    % step 2.2: update feedback_info with feedback_suggestion
    if ~isempty(feedback_info)
        assert(feedback_suggest.probe_info.probe_id == feedback_info.probe_info.probe_id);
        
        % filter out invalid gallery items in feedback_info
        [~, stat_info] = feedback_stat(feedback_info);
        for i=stat_info.gallery_num:-1:1
            mark_flag = feedback_info.feedback_details{i}.mark_flag;
            if strcmp(mark_flag(1),'N') && strcmp(mark_flag(2),'N')
                feedback_info.feedback_details(i)=[];
            end
        end

        % save feedback_info
        save(log_dir, 'feedback_info');
       
        % inject feedback_info into feedback_suggest
        [suggest_gallery_name_tab, stat_info] = feedback_stat(feedback_suggest);
        suggest_gallery_num = stat_info.gallery_num;
        [~, stat_info] = feedback_stat(feedback_info);
        gallery_num = stat_info.gallery_num;
        add_num = 0;
        for i=1:gallery_num
            [tf, loc] = ismember(feedback_info.feedback_details{i}.gallery_name, suggest_gallery_name_tab);
            if tf % 将feedback_info信息更新进new_feedback_suggest建议之中
                mark_flag = feedback_info.feedback_details{i}.mark_flag;
                for k=1:2
                    if strcmp(mark_flag(k),'Y')
                        feedback_suggest.feedback_details{loc}.body_part(k) = feedback_info.feedback_details{i}.body_part(k);
                        feedback_suggest.feedback_details{loc}.box_type(k) = feedback_info.feedback_details{i}.box_type(k);
                        feedback_suggest.feedback_details{loc}.box_conf(k) = feedback_info.feedback_details{i}.box_conf(k);
                        feedback_suggest.feedback_details{loc}.cur_pos(k) = feedback_info.feedback_details{i}.cur_pos(k);
                        feedback_suggest.feedback_details{loc}.birth_run(k) = feedback_info.feedback_details{i}.birth_run(k);
                        feedback_suggest.feedback_details{loc}.source(k) = feedback_info.feedback_details{i}.source(k);
                        feedback_suggest.feedback_details{loc}.mark_flag(k) = feedback_info.feedback_details{i}.mark_flag(k);
                        feedback_suggest.feedback_details{loc}.last_update_time(k,:) = feedback_info.feedback_details{i}.last_update_time(k,:);
                        feedback_suggest.feedback_details{loc}.operator = feedback_info.feedback_details{i}.operator;
                    end
                end
            else % 将feedback_info信息添加到new_feedback_suggest最后
                add_num = add_num + 1;
                feedback_suggest.feedback_details{suggest_gallery_num+add_num} = feedback_info.feedback_details{i};
            end
        end
    end
    feedback_info = feedback_suggest;
    setappdata(0, 'feedback_info', feedback_info);
end

% step 4: identify groundtruth rank
curr_reid_score = getappdata(0,'curr_reid_score');
[~, sorted_gallery_id_list] = sort(curr_reid_score, 'descend');
if identify_groundtruth_rank
    probe_id = getappdata(0, 'probe_id');
    curr_groundtruth_rank = find(sorted_gallery_id_list==probe_id, 1);

    if query_times>1
        last_groundtruth_rank = getappdata(0, 'curr_groundtruth_rank');
    else
        last_groundtruth_rank = [];
    end
    setappdata(0, 'last_groundtruth_rank', last_groundtruth_rank);
    setappdata(0, 'curr_groundtruth_rank', curr_groundtruth_rank);
end

% step 5: identify tot_image_num, page_status, start_rank_id, show_image_num
% step 5.1: tot_image_num
switch show_status
    case 'show our result'
        tot_image_num = size(prbgal_name_tab, 1);
    case 'show feedback result'
        [~, stat_info] = feedback_stat(feedback_info);
        tot_image_num = stat_info.gallery_num;
end

% step 5.2: last_page_id
image_num_per_page = getappdata(0,'image_num_per_page');
last_page_id = max(1, ceil(tot_image_num/image_num_per_page));
setappdata(0, 'last_page_id', last_page_id);

% step 5.3: page_status
page_id = getappdata(0, 'page_id');
if 1 == last_page_id
    page_status = 'sole';
elseif page_id == 1 
    page_status = 'front';
elseif page_id == last_page_id
    page_status = 'rear';
else
    page_status = 'mid';
end
setappdata(0, 'page_status', page_status);

% step 5.4: show_image_num
start_rank_id = (page_id-1)*image_num_per_page+1;
if page_id<last_page_id
    show_image_num = min(tot_image_num, image_num_per_page);
else
    show_image_num = tot_image_num - (last_page_id-1)*image_num_per_page;
end

% step 6: fill show_gallery_info
% show_gallery_info.ranks
% show_gallery_info.names
% show_gallery_info.curr_scores
% show_gallery_info.last_scores
curr_reid_score = getappdata(0, 'curr_reid_score');
last_reid_score = getappdata(0, 'last_reid_score');
feedback_info = sort_feedback_info(feedback_info, prbgal_name_tab(:,2), sorted_gallery_id_list);
setappdata(0, 'feedback_info', feedback_info);
switch show_status
    case 'show our result'
        show_gallery_info.ranks = (start_rank_id:start_rank_id+show_image_num-1)';
        show_id_list = sorted_gallery_id_list(show_gallery_info.ranks);
        show_gallery_info.names = prbgal_name_tab(show_id_list,2);
        
        if query_times==1
            show_gallery_info.curr_scores = curr_reid_score(show_id_list);
            show_gallery_info.last_scores = [];
        else
            show_gallery_info.curr_scores = curr_reid_score(show_id_list);
            show_gallery_info.last_scores = last_reid_score(show_id_list);
        end
        
        
    case 'show feedback result'
        show_gallery_info.names = cell(show_image_num, 1);
        show_gallery_info.ranks = zeros(show_image_num, 1);
        show_id_list = zeros(show_image_num, 1);
        
        for i=1:show_image_num
            show_gallery_info.names{i} = feedback_info.feedback_details{start_rank_id+i-1}.gallery_name;
            [~, loc] = ismember(show_gallery_info.names{i}, prbgal_name_tab(:,2));
            show_id_list(i) = loc;
            show_gallery_info.ranks(i) = find(sorted_gallery_id_list==loc, 1);
        end
        if query_times==1
            show_gallery_info.curr_scores = curr_reid_score(show_id_list);
            show_gallery_info.last_scores = [];
        else
            show_gallery_info.curr_scores = curr_reid_score(show_id_list);
            show_gallery_info.last_scores = last_reid_score(show_id_list);
        end
end

% step 7: fill uitable data
[~, stat_info] = feedback_stat(feedback_info);
show_gallery_info.stat_info = stat_info;
uitable_data = cell(stat_info.box_num, 8);
% 表格第1列ID：存放用户反馈图像的名称
% 表格第2列Part(PT)：存放用户反馈的身体区域
% 表格第3列Label(LA)：存放用户反馈的极性（相似/不相似）
% 表格第4列Soiurce(SR)：存放样本的来源（'S'算法自动产生/'M'人工主动选择）
% 表格第5列Mark(MK)：存放样本的反馈状态（是/否）
% 表格第6列Rank(RK)：存放用户反馈的图像在当前排序列表中的位置
% 表格第7列Page(PG)：存放用户反馈的图像在检索结果的第几页。用于快速定位。
% 表格第8列Run(RU)：存放样本的建议反馈轮次，即在第几轮检索时被建议
feedback_gallery_rank  = zeros(stat_info.box_num,1);
item_num = 1;
for i=1:stat_info.gallery_num

    for j=1:2
        if 0==feedback_info.feedback_details{i}.body_part(j)
            continue;
        end
        
        % 表格第1列(ID)：存放用户反馈图像的名称
        uitable_data{item_num,1} = feedback_info.feedback_details{i}.gallery_name;

        % 表格第2列(PT)：存放用户反馈的身体区域
        switch feedback_info.feedback_details{i}.body_part(j)
            case 1
                uitable_data{item_num,2} = 'T';
            case 2
                uitable_data{item_num,2} = 'L';
        end

        % 表格第3列(LA)：存放用户反馈的极性（相似/不相似）
        switch feedback_info.feedback_details{i}.box_type(j)
            case 0
                uitable_data{item_num,3} = '?';
            case 1
                uitable_data{item_num,3} = '+';
            case -1
                uitable_data{item_num,3} = '-';
        end

        
        % 表格第4列(SR)：存放样本的来源（'S'算法自动建议/'M'人工主动选择）
        uitable_data{item_num,4} = sprintf('%s', feedback_info.feedback_details{i}.source(j));

        % 表格第5列(MK)：存放样本的反馈状态（是/否）
        uitable_data{item_num,5} = sprintf('%s', feedback_info.feedback_details{i}.mark_flag(j));
        
        % 表格第6列(RK)：存放用户反馈的图像在当前排序列表中的位置
        [~, loc] = ismember(uitable_data{item_num,1}, prbgal_name_tab(:,2));
        [~, feedback_gallery_rank(item_num)] = ismember(loc, sorted_gallery_id_list);
        uitable_data{item_num,6} = sprintf('%d', feedback_gallery_rank(item_num));

        % 表格第7列(PG)：存放用户反馈的图像在检索结果的第几页
        feedback_gallery_page = ceil(feedback_gallery_rank(item_num)/image_num_per_page);
        uitable_data{item_num,7} = sprintf('%d', feedback_gallery_page);

        % 表格第8列(RU)：存放样本的建议反馈轮次，即在第几轮检索时被建议
        uitable_data{item_num,8} = sprintf('%d', feedback_info.feedback_details{i}.birth_run(j));
  
        item_num = item_num + 1;
    end
end
[~, sorted_feedback_gallery_id] = sort(feedback_gallery_rank);
uitable_data = uitable_data(sorted_feedback_gallery_id,:);
show_gallery_info.uitable_data = uitable_data;
setappdata(0, 'show_gallery_info', show_gallery_info);

