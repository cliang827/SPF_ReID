function clear_reid_result()

% step1: clear groundtruth info
st_text_current_rank_handle = findobj(0,'Tag','st_text_current_rank');
set(st_text_current_rank_handle, 'Visible', 'off');
curr_groundtruth_rank_handle = findobj(0,'Tag','textgroundtruth_rank_a');
set(curr_groundtruth_rank_handle, 'String', '');

st_text_current_rank_handle = findobj(0,'Tag','st_text_last_rank');
set(st_text_current_rank_handle, 'Visible', 'off');
curr_groundtruth_rank_handle = findobj(0,'Tag','textgroundtruth_rank_c');
set(curr_groundtruth_rank_handle, 'String', '');

% step2: clear page info
setappdata(0, 'page_id', 0);

et_page_id_handle = findobj(0, 'Tag', 'et_page_id');
set(et_page_id_handle, 'String', '');

st_tot_page_num_handle = findobj(0, 'Tag', 'st_tot_page_num');
set(st_tot_page_num_handle, 'String', '');

% step3: clear button status
pb_previous_handle = findobj(0,'Tag','previous');
pb_next_handle = findobj(0,'Tag','next');
pb_jump_handle = findobj(0,'Tag', 'jump');

set(pb_previous_handle, 'enable', 'off');
set(pb_next_handle, 'enable', 'off');
set(pb_jump_handle, 'enable', 'off');

% step4: clear feedback info in table
uitable_handle = findobj(0,'Tag','uitable');
uitable_data = {'','','','','';'','','','','';'','','','','';'','','','','';'','','','',''};
set(uitable_handle, 'Data', uitable_data);

st_tot_feedback_gallery_num_handle = findobj(0,'Tag','st_tot_feedback_gallery_num');
st_tot_pos_box_num_handle = findobj(0,'Tag','st_tot_pos_box_num');
st_tot_neg_box_num_handle = findobj(0,'Tag','st_tot_neg_box_num');
set(st_tot_feedback_gallery_num_handle, 'String', '');
set(st_tot_pos_box_num_handle, 'String', '');
set(st_tot_neg_box_num_handle, 'String', '');

% step5: clear gallery images
image_num_per_page = getappdata(0,'image_num_per_page');
for i=1:image_num_per_page
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
end
