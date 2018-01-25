function [f, feedback_set, f_delta] = test_baseline_pcm14_v2(ctrl_para, feedback_info, groundtruth_feedback, ix_info_tab) %#ok<*STOUT,*INUSD>

probe_id = ix_info_tab(1);
query_times = ix_info_tab(2);

if query_times == 1
    f = ctrl_para.init_reid_score(:, probe_id);
    setappdata(0, 'curr_reid_score_for_pcm14', f);
    feedback_set = [];
    f_delta = zeros(size(f));
    return;
else
    f0 = getappdata(0, 'curr_reid_score_for_pcm14');
end


parse_nv_feedback_info_for_pcm14;
% assert(~isempty(feedback_set));
f_delta = pcm14_core_v2(ctrl_para,feedback_set);
% assert(~isempty(f_delta));

f = f0 + f_delta;
setappdata(0, 'curr_reid_score_for_pcm14', f);


