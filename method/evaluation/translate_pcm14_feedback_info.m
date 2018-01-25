% translate_pcm14_feedback_info
load('.\result\pcm14\feedback_info_pcm14.mat');
% probe_id = ix_info_tab(1);
% query_times = ix_info_tab(2);
% repeat_times = ix_info_tab(3);
% repeat_times = 1;
% probe_id = 1;

feedback_info_pcm14 = feedback_info_origin{repeat_times, probe_id};


temp = cell(1,4);
%SimilarTorse
gallery_name = feedback_info_pcm14.SimilarTorse{1};
feedback_info = getappdata(0, 'feedback_info');
gallery_name_tab = feedback_stat(feedback_info);
[~, loc] = ismember(gallery_name, gallery_name_tab);
feedback_info.feedback_details{loc}.source(1) = 'M';
feedback_info.feedback_details{loc}.mark_flag(1) = 'Y';
feedback_info.feedback_details{loc}.birth_run(1) = 1;
feedback_info.feedback_details{loc}.body_part(1) = 1;
% feedback_info.feedback_details{loc}.box_type(1) = 1;
% feedback_info.feedback_details{loc}.box_conf(1) = 1;
% feedback_info.feedback_details{loc}.cur_pos(1) = 1;

feedback_info.feedback_details{loc}.source(2) = 'U';
feedback_info.feedback_details{loc}.mark_flag(2) = 'N';
feedback_info.feedback_details{loc}.birth_run(2) = 0;
feedback_info.feedback_details{loc}.body_part(2) = 0;
feedback_info.feedback_details{loc}.box_type(2) = 0;
feedback_info.feedback_details{loc}.box_conf(2) = 0;
feedback_info.feedback_details{loc}.cur_pos(2) = 0;
feedback_info.feedback_details{loc}.operator{2} = 'default';
feedback_info.feedback_details{loc}.last_update_time(2,:) = zeros(1,6);
temp{1} = feedback_info.feedback_details{loc};

%DissimilarTorse
gallery_name = feedback_info_pcm14.DissimilarTorse{1};
feedback_info = getappdata(0, 'feedback_info');
gallery_name_tab = feedback_stat(feedback_info);
[~, loc] = ismember(gallery_name, gallery_name_tab);
feedback_info.feedback_details{loc}.source(1) = 'M';
feedback_info.feedback_details{loc}.mark_flag(1) = 'Y';
feedback_info.feedback_details{loc}.birth_run(1) = 1;
feedback_info.feedback_details{loc}.body_part(1) = 1;
% feedback_info.feedback_details{loc}.box_type(1) = -1;
% feedback_info.feedback_details{loc}.box_conf(1) = 1;
% feedback_info.feedback_details{loc}.cur_pos(1) = -1;

feedback_info.feedback_details{loc}.source(2) = 'U';
feedback_info.feedback_details{loc}.mark_flag(2) = 'N';
feedback_info.feedback_details{loc}.birth_run(2) = 0;
feedback_info.feedback_details{loc}.body_part(2) = 0;
feedback_info.feedback_details{loc}.box_type(2) = 0;
feedback_info.feedback_details{loc}.box_conf(2) = 0;
feedback_info.feedback_details{loc}.cur_pos(2) = 0;
feedback_info.feedback_details{loc}.operator{2} = 'default';
feedback_info.feedback_details{loc}.last_update_time(2,:) = zeros(1,6);
temp{2} = feedback_info.feedback_details{loc};

%SimilarLeg
gallery_name = feedback_info_pcm14.SimilarLeg{1};
feedback_info = getappdata(0, 'feedback_info');
gallery_name_tab = feedback_stat(feedback_info);
[~, loc] = ismember(gallery_name, gallery_name_tab);
feedback_info.feedback_details{loc}.source(2) = 'M';
feedback_info.feedback_details{loc}.mark_flag(2) = 'Y';
feedback_info.feedback_details{loc}.birth_run(2) = 1;
feedback_info.feedback_details{loc}.body_part(2) = 2;
% feedback_info.feedback_details{loc}.box_type(2) = 1;
% feedback_info.feedback_details{loc}.box_conf(2) = 1;
% feedback_info.feedback_details{loc}.cur_pos(2) = 1;

feedback_info.feedback_details{loc}.source(1) = 'U';
feedback_info.feedback_details{loc}.mark_flag(1) = 'N';
feedback_info.feedback_details{loc}.birth_run(1) = 0;
feedback_info.feedback_details{loc}.body_part(1) = 0;
feedback_info.feedback_details{loc}.box_type(1) = 0;
feedback_info.feedback_details{loc}.box_conf(1) = 0;
feedback_info.feedback_details{loc}.cur_pos(1) = 0;  
feedback_info.feedback_details{loc}.operator{1} = 'default';
feedback_info.feedback_details{loc}.last_update_time(1,:) = zeros(1,6);
temp{3} = feedback_info.feedback_details{loc};

%DissimilarLeg
gallery_name = feedback_info_pcm14.DissimilarLeg{1};
feedback_info = getappdata(0, 'feedback_info');
gallery_name_tab = feedback_stat(feedback_info);
[~, loc] = ismember(gallery_name, gallery_name_tab);
feedback_info.feedback_details{loc}.source(2) = 'M';
feedback_info.feedback_details{loc}.mark_flag(2) = 'Y';
feedback_info.feedback_details{loc}.birth_run(2) = 1;
feedback_info.feedback_details{loc}.body_part(2) = 2;
% feedback_info.feedback_details{loc}.box_type(2) = -1;
% feedback_info.feedback_details{loc}.box_conf(2) = 1;
% feedback_info.feedback_details{loc}.cur_pos(2) = -1;

feedback_info.feedback_details{loc}.source(1) = 'U';
feedback_info.feedback_details{loc}.mark_flag(1) = 'N';
feedback_info.feedback_details{loc}.birth_run(1) = 0;
feedback_info.feedback_details{loc}.body_part(1) = 0;
feedback_info.feedback_details{loc}.box_type(1) = 0;
feedback_info.feedback_details{loc}.box_conf(1) = 0;
feedback_info.feedback_details{loc}.cur_pos(1) = 0;  
feedback_info.feedback_details{loc}.operator{1} = 'default';
feedback_info.feedback_details{loc}.last_update_time(1,:) = zeros(1,6);
temp{4} = feedback_info.feedback_details{loc};

feedback_info.feedback_details = temp;
