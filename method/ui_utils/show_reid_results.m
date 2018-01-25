function show_reid_results(show_mode)  

% step 0: show_mode_switch
switch show_mode
    case 'picture_mode'
        show_mode_switch.show_page_info = false;
        show_mode_switch.update_button_status = false;
        show_mode_switch.feedback_info_in_table = true;
        show_mode_switch.show_gallery_images = false;
        
    case 'default_mode'
        show_mode_switch.show_page_info = true;
        show_mode_switch.update_button_status = true;
        show_mode_switch.feedback_info_in_table = true;
        show_mode_switch.show_gallery_images = true;
end


% step 1: show groundtruth rank
st_text_current_rank_handle = findobj(0,'Tag','st_text_current_rank');
set(st_text_current_rank_handle, 'Visible', 'on');
curr_groundtruth_rank_handle = findobj(0,'Tag','textgroundtruth_rank_c');
curr_groundtruth_rank = getappdata(0, 'curr_groundtruth_rank');
set(curr_groundtruth_rank_handle, 'String', num2str(curr_groundtruth_rank));

query_times = getappdata(0, 'query_times');
if query_times>1
    st_text_last_rank_handle = findobj(0,'Tag','st_text_last_rank');
    set(st_text_last_rank_handle, 'Visible', 'on');

    last_groundtruth_rank_handle = findobj(0,'Tag','textgroundtruth_rank_a');
    last_groundtruth_rank = getappdata(0, 'last_groundtruth_rank');
    set(last_groundtruth_rank_handle, 'String', num2str(last_groundtruth_rank));
end

% step 2: show page info
if show_mode_switch.show_page_info
    page_id = getappdata(0, 'page_id');
    et_page_id_handle = findobj(0, 'Tag', 'et_page_id');
    set(et_page_id_handle, 'String', num2str(page_id));

    last_page_id = getappdata(0, 'last_page_id');
    st_tot_page_num_handle = findobj(0, 'Tag', 'st_tot_page_num');
    set(st_tot_page_num_handle, 'String', num2str(last_page_id));
end

% step 3: update button status
show_gallery_info = getappdata(0, 'show_gallery_info');
if show_mode_switch.update_button_status
    page_status = getappdata(0, 'page_status');
    pb_previous_handle = findobj(0,'Tag','previous');
    pb_next_handle = findobj(0,'Tag','next');
    pb_jump_handle = findobj(0,'Tag', 'jump');
    switch page_status
        case 'sole'
            set(pb_previous_handle, 'enable', 'off');
            set(pb_next_handle, 'enable', 'off');
            set(pb_jump_handle, 'enable', 'off');
        case 'front'
            set(pb_previous_handle, 'enable', 'off');
            set(pb_next_handle, 'enable', 'on');
            set(pb_jump_handle, 'enable', 'on');
        case 'rear'
            set(pb_previous_handle, 'enable', 'on');
            set(pb_next_handle, 'enable', 'off');
            set(pb_jump_handle, 'enable', 'on');
        case 'mid'
            set(pb_previous_handle, 'enable', 'on');
            set(pb_next_handle, 'enable', 'on');
            set(pb_jump_handle, 'enable', 'on');
    end

    gallery_names = show_gallery_info.names;
    gallery_ranks = show_gallery_info.ranks;
    gallery_curr_scores = show_gallery_info.curr_scores;
    gallery_last_scores = show_gallery_info.last_scores;

    show_image_size = size(gallery_names, 1); % 待显示的图片数量
end

% step 4: show feedback info in table
if show_mode_switch.feedback_info_in_table
    uitable_handle = findobj(0,'Tag','uitable');
    st_tot_feedback_gallery_num_handle = findobj(0,'Tag','st_tot_feedback_gallery_num');
    st_tot_pos_box_num_handle = findobj(0,'Tag','st_tot_pos_box_num');
    st_tot_neg_box_num_handle = findobj(0,'Tag','st_tot_neg_box_num');
    st_tot_sug_box_num_handle = findobj(0,'Tag','st_tot_sug_box_num');

    uitable_data = show_gallery_info.uitable_data;
    gallery_num = show_gallery_info.stat_info.gallery_num;
    pos_box_num = show_gallery_info.stat_info.pos_box_num;
    neg_box_num = show_gallery_info.stat_info.neg_box_num;
    sug_pos_num = show_gallery_info.stat_info.sug_pos_num;
    sug_neg_num = show_gallery_info.stat_info.sug_neg_num;

    if isempty(uitable_data)
        uitable_data = {'','','','','','','','';'','','','','','','','';'','','','','','','',''};
    else
        uitable_data = set_uitable_color(uitable_data);
    end
    
    set(uitable_handle, 'Data', uitable_data);
    set(st_tot_feedback_gallery_num_handle, 'String', num2str(gallery_num));
    set(st_tot_pos_box_num_handle, 'String', num2str(pos_box_num));
    set(st_tot_neg_box_num_handle, 'String', num2str(neg_box_num));
    set(st_tot_sug_box_num_handle, 'String', sprintf('[%d/%d]', sug_pos_num, sug_neg_num));
end

% step 5: show gallery images
dir_info = getappdata(0, 'dir_info');
if show_mode_switch.show_gallery_images
    image_num_per_page = getappdata(0,'image_num_per_page');
    num = max(show_image_size, image_num_per_page);
    for i=1:num

        if i>show_image_size % 对于剩余的显示位置，用“空”信息去填充
            curr_axes_handle = getappdata(0,['axes' num2str(i)]);                  % 准备当前显示图片的坐标轴，1-20
            cla(curr_axes_handle)

            % show its rank
            curr_textrank_handle = findobj(0,'Tag',['textrank' num2str(i)]);
            set(curr_textrank_handle, 'String', '');   

            % show its current score
            curr_score_handle = findobj(0,'Tag',['text' num2str(i) 'c']);
            set(curr_score_handle, 'String', '');

            % show its last score
            last_score_handle = findobj(0,'Tag',['text' num2str(i) 'a']);
            set(last_score_handle, 'String', '');

            % hidden static text
            st_cs_handle = findobj(0,'Tag',['st_cs' num2str(i)]);
            set(st_cs_handle, 'Visible', 'off');

            st_ls_handle = findobj(0,'Tag',['st_ls' num2str(i)]);
            set(st_ls_handle, 'Visible', 'off');
            continue;
        end

        % show gallery image
        curr_axes_handle = getappdata(0,['axes' num2str(i)]);                  % 准备当前显示图片的坐标轴，1-20
        axes(curr_axes_handle); 

        image_format = getappdata(0, 'image_format');
        gallery_image = imread([dir_info.gallery_dir gallery_names{i} '.' image_format]);    % 读入gallery图片并显示，显示rank前20

        curr_image_handle = show_gallery_image2(gallery_image, gallery_names{i}, curr_axes_handle);
        set(curr_image_handle, 'ButtonDownFcn', sprintf('picture(%d, ''axes'')',i));        % 单击每张图片，打开标注小窗口

        % 需要传入标注小窗口的数据
        setappdata(0, ['picture_' num2str(i) '_gallery_name'], gallery_names{i});  

        % show its rank
        curr_textrank_handle = findobj(0,'Tag',['textrank' num2str(i)]);
        set(curr_textrank_handle, 'visible', 'on');
        set(curr_textrank_handle, 'String',['rank ' num2str(gallery_ranks(i))]);

        % show its current score
        st_cs_handle = findobj(0,'Tag',['st_cs' num2str(i)]);
        set(st_cs_handle, 'Visible', 'on');

        curr_score_handle = findobj(0,'Tag',['text' num2str(i) 'c']);
        set(curr_score_handle, 'String',num2str(gallery_curr_scores(i)));

        st_ls_handle = findobj(0,'Tag',['st_ls' num2str(i)]);
        set(st_ls_handle, 'Visible', 'off');

        % show its last score (for feedback session)
        if query_times>1
            st_ls_handle = findobj(0,'Tag',['st_ls' num2str(i)]);
            set(st_ls_handle, 'Visible', 'on');

            last_score_handle = findobj(0,'Tag',['text' num2str(i) 'a']);
            set(last_score_handle, 'String',num2str(gallery_last_scores(i)));
        end
    end
end





