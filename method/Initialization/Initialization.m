clear; clc;

% init
dataset = 'viper';
trial = 1;

%directory info
dir_info.dataset_dir = '..\..\..\database\re-id\';
dir_info.salubm_dir = '..\SalUBM_v20150406\result\';

dir_info.data_dir = '.\data\';
dir_info.probe_dir = [dir_info.data_dir 'probe\'];
dir_info.gallery_dir = [dir_info.data_dir 'gallery\'];
dir_info.body_div_dir = [dir_info.data_dir 'body_div\'];
dir_info.test_nv_feedback_dir = [dir_info.data_dir 'feedback\syan-20170914\'];
dir_info.test_v_feedback_dir = [dir_info.data_dir 'feedback\syan-v-20170914\'];
dir_info.test_feedback_dir = [dir_info.data_dir 'feedback\test_feedback\'];
dir_info.test_feedback_log_dir = [dir_info.data_dir 'feedback\test_feedback_log\'];

dir_info.feedback0_dir = '..\..\..\database\re-id\viper_feedback_20170209\default\';
dir_info.init_dir = [dir_info.data_dir 'init\'];
dir_info.ui_dir = [dir_info.data_dir 'ui\'];

image_format = 'bmp';
operator = 'default';

% set debug flag
debug_flag = struct(...
        'copy_files',                           false, ...
        'default',                              false  ...
        );

if debug_flag.copy_files
    
    % load reid_result
    load([dir_info.salubm_dir dataset '\trial_1\dim_4\model_ranking.mat']); 
    setappdata(0, 'all_reid_score', reid_score);
    [gallery_size_H0, probe_size_H0] = size(reid_score);
    
    % load dist mat
    load([dir_info.salubm_dir dataset '\trial_1\dim_4\model_dist.mat']);
    setappdata(0, 'p2g_dist', p2g_dist);
    setappdata(0, 'g2p_dist', g2p_dist);
    setappdata(0, 'g2g_dist', g2g_dist);

    % load file_name_map
    load([dir_info.salubm_dir dataset '\norm_data\norm_data.mat']);
    % load id (实际是在挑选一组测试集)
    load([dir_info.salubm_dir dataset '\trial_' num2str(trial) '\id.mat']);
%     id.prbgal(1:2:end) = 1; %only for temporally test
%     id.prbgal(2:2:end) = 2; %only for temporally test
    
    probe_files = file_name_map(id.prbgal==1,1);
    probe_index = find(id.prbgal==1);
    probe_size = length(probe_files);
    assert(probe_size==probe_size_H0);

    gallery_files = file_name_map(id.prbgal==2,1);
    gallery_index = find(id.prbgal==2);
    gallery_size = length(gallery_files);
    assert(gallery_size==gallery_size_H0);

    % build dataset
    if exist(dir_info.data_dir, 'dir')
        rmdir(dir_info.data_dir, 's');
    end
    mkdir(dir_info.data_dir);

    % copy probe files
    mkdir(dir_info.probe_dir);
    for i=1:probe_size
        slash_pos = strfind(probe_files{i}, '\');
        copyfile([dir_info.dataset_dir dataset '\' probe_files{i}], [dir_info.probe_dir probe_files{i}(slash_pos+1:end)]);
        probe_files{i}(1:slash_pos) = [];
        
        dot_pos = strfind(probe_files{i}, '.');
        probe_files{i}(dot_pos:end) = [];
    end

    % copy gallery files and body div files
    mkdir(dir_info.gallery_dir);
    mkdir(dir_info.body_div_dir);
    body_div_files = file_name_map(id.prbgal==2,2);
    for i=1:gallery_size
        slash_pos = strfind(gallery_files{i}, '\');
        copyfile([dir_info.dataset_dir dataset '\' gallery_files{i}], [dir_info.gallery_dir gallery_files{i}(slash_pos+1:end)]);
        gallery_files{i}(1:slash_pos) = [];


        copyfile([dir_info.salubm_dir dataset '\body_div\' strrep(body_div_files{i}, 'png', 'mat')], ...
            [dir_info.body_div_dir strrep(gallery_files{i}, 'bmp', 'mat')]);
        dot_pos = strfind(gallery_files{i}, '.');
        gallery_files{i}(dot_pos:end) = [];
    end
    
    % copy feedback files
    mkdir(dir_info.feedback_dir);
    for i=1:probe_size
        load([dir_info.feedback0_dir 'cam_a' '-' probe_files{i} '+' operator '.mat']);
        valid_gallery_files = gallery_files;
        valid_gallery_files(i) = []; % 把针对groundtruth自身的标记去除掉
        gallery_name_tab = feedback_stat(feedback_log);
        [c, valid_id] = intersect(gallery_name_tab, valid_gallery_files);
        feedback_log.feedback_details = feedback_log.feedback_details(valid_id);
        save([dir_info.feedback_dir 'cam_a' '-' probe_files{i} '+' operator '.mat'], 'feedback_log');
    end

    % save init result
    prbgal_name_tab = cat(2, probe_files, gallery_files);
    prbgal_id_tab = cat(1, probe_index, gallery_index)';
    setappdata(0, 'prbgal_name_tab', prbgal_name_tab);
    setappdata(0, 'prbgal_id_tab', prbgal_id_tab);

    mkdir(dir_info.init_dir);
    save([dir_info.init_dir 'init.mat'], 'dir_info', 'reid_score', 'prbgal_name_tab', 'prbgal_id_tab', 'image_format', 'operator', 'p2g_dist', 'g2p_dist', 'g2g_dist');
    
else

    load('.\data\init\init.mat');
    
    setappdata(0, 'dir_info', dir_info);
    setappdata(0, 'operator', operator);
    setappdata(0, 'all_reid_score', reid_score);
    setappdata(0, 'prbgal_name_tab', prbgal_name_tab);
    setappdata(0, 'prbgal_id_tab', prbgal_id_tab);
    setappdata(0, 'image_format', image_format);
    setappdata(0, 'p2g_dist', p2g_dist);
    setappdata(0, 'g2p_dist', g2p_dist);
    setappdata(0, 'g2g_dist', g2g_dist);
end


