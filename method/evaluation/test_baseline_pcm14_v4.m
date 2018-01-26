function [f, feedback_set, f_delta] = test_baseline_pcm14_v4(ctrl_para, feedback_info_for_pcm14, groundtruth_feedback, ix_info_tab, proc_handle) %#ok<*STOUT,*INUSD>

probe_id = ix_info_tab(1);
query_times = ix_info_tab(2);
repeat_times = ix_info_tab(3);

if query_times == 1

    f = ctrl_para.init_reid_score(:, probe_id);
    f_delta = zeros(size(f));
    feedback_set = [];
    
    if isappdata(proc_handle, 'curr_reid_score_for_pcm14')
        rmappdata(proc_handle, 'curr_reid_score_for_pcm14');
    end
    setappdata(proc_handle, 'curr_reid_score_for_pcm14', f);
    
    
    if isappdata(proc_handle, 'feedback_info_for_pcm14')
        rmappdata(proc_handle, 'feedback_info_for_pcm14');
    end
    setappdata(proc_handle, 'feedback_info_for_pcm14', feedback_info_for_pcm14);
    
    return;
else
    f0 = getappdata(proc_handle, 'curr_reid_score_for_pcm14');
    if isappdata(proc_handle, 'feedback_info_for_pcm14')
        feedback_info_for_pcm14 = getappdata(proc_handle, 'feedback_info_for_pcm14');
    else
        error('no app data!');
    end

    % change feedback_info into feedback_set
    parse_nv_feedback_info_for_pcm14_v3;
    % assert(~isempty(feedback_set));

    % core pcm14 algorithm
    f_delta = pcm14_core_v3(ctrl_para, feedback_set);
    % assert(~isempty(f_delta));
    setappdata(proc_handle, 'f_delta', f_delta);

    f = f0 + f_delta;
    setappdata(proc_handle, 'curr_reid_score_for_pcm14', f);
end





