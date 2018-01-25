
% init
% operator = questdlg('Who are you?', 'Operator login', ...
%     'Long-Xiang Jiang', 'Liang Hu', 'Su Yan', 'Long-Xiang Jiang');
% assert(~isempty(operator));
operator = 'default';
dataset = 'viper';
base_method = 'pcm14';

switch dataset
    case 'viper'
        image_format = 'bmp';
    otherwise 
        error('wrong image format!');
end

dir_info.ui_dir = './data/ui/';
dir_info.data_dir = ['./data/' dataset '/'];
dir_info.probe_dir = [dir_info.data_dir 'probe/'];
dir_info.gallery_dir = [dir_info.data_dir 'gallery/'];
dir_info.body_div_dir = [dir_info.data_dir 'body_div/'];
dir_info.feedback_dir = [dir_info.data_dir 'feedback/'];
dir_info.feedback_log_dir = [dir_info.feedback_dir 'log/'];
dir_info.init_dir = [dir_info.data_dir 'init/' base_method '.mat']; 
load(dir_info.init_dir);

% dir_info.ui_dir = strrep(dir_info.ui_dir, '/', '\');
% dir_info.data_dir = strrep(dir_info.data_dir, '/', '\');
% dir_info.probe_dir = strrep(dir_info.probe_dir, '/', '\');
% dir_info.gallery_dir = strrep(dir_info.gallery_dir, '/', '\');
% dir_info.body_div_dir = strrep(dir_info.body_div_dir, '/', '\');
% dir_info.feedback_dir = strrep(dir_info.feedback_dir, '/', '\');
% dir_info.feedback_log_dir = strrep(dir_info.feedback_log_dir, '/', '\');
% dir_info.init_dir = strrep(dir_info.init_dir, '/', '\');

setappdata(0, 'dir_info', dir_info);
setappdata(0, 'operator', operator);
setappdata(0, 'all_reid_score', reid_score);
setappdata(0, 'prbgal_name_tab', prbgal_name_tab);
% setappdata(0, 'prbgal_id_tab', prbgal_id_tab);
setappdata(0, 'image_format', image_format);
setappdata(0, 'p2g_dist', p2g_dist);
setappdata(0, 'g2p_dist', g2p_dist);
setappdata(0, 'g2g_dist', g2g_dist);


% save([dir_info.init_dir 'init.mat'], 'dir_info', 'reid_score', 'prbgal_name_tab', 'prbgal_id_tab', 'image_format', 'operator', 'p2g_dist', 'g2p_dist', 'g2g_dist');
