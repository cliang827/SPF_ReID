function [ok_flag, err_info] = check_feedback_coverage(probe_name, gallery_name_tab_by_part, V_result_dir, fbppr)

ok_flag = true;
err_info.not_covered_gallery_id = cell(2,1);
err_info.not_covered_gallery_name = cell(2,1);
err_info.not_covered_gallery_num = [0;0];

prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
[~, loc] = ismember(probe_name, prbgal_name_tab(:,1));
V_file_name = [V_result_dir sprintf('%d_1_1.mat',loc)];
assert(logical(exist(V_file_name, 'file')));
load(V_file_name);

[~, ix] = sort(V, 'descend');
fb_num = sum(fbppr);
tmp_feedback_ix = zeros(2, fb_num);
for k=1:2
    
    gallery_name_set = prbgal_name_tab(ix(1:fb_num,k),2);
    [~, tmp_feedback_ix(k,:)] = ismember(gallery_name_set, gallery_name_tab_by_part{k});
%     assert(isempty(find(tmp_feedback_ix(k,:)==0, 1)));
    
    [tf_zero, loc_zero] = find(tmp_feedback_ix(k,:)==0);
    if ~isempty(tf_zero)
        ok_flag = false;
        err_info.not_covered_gallery_id{k,:} = ix(loc_zero,k);
        err_info.not_covered_gallery_name{k,:} = gallery_name_set(loc_zero)';
        err_info.not_covered_gallery_num(k) = sum(tf_zero);
    end
end