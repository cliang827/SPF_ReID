function [last_update_time_mask, source, mark_flag, birth_run, body_part, box_type, box_conf, cur_pos] = translate_dist_as_feedback(dist_mat)

m = size(dist_mat, 2);
sim_mat = exp(-1*dist_mat);
min_sim = min(sim_mat, [], 2);
max_sim = max(sim_mat, [], 2);

%% step 1: cur_pos
% [min:x:max] -> [-1:y:1]
max_plus_min = repmat(max_sim+min_sim, 1, m);
max_minus_min = repmat(max_sim-min_sim, 1, m);
cur_pos = (max_plus_min-2*sim_mat)./(max_minus_min);
beta = 1e-9;    % suggest: 0-0.1
cur_pos(abs(cur_pos)<=beta) = 0;

%% step 2: box_conf
conf = zeros(size(cur_pos));
conf(cur_pos>beta) = (cur_pos(cur_pos>beta)-beta)/(1-beta);
conf(cur_pos<-beta) = (cur_pos(cur_pos<-beta)+beta)/(1-beta);
box_conf = abs(conf);

%% step 3: box_type
box_type = sign(conf);

%% step 4: body_part
body_part = abs(box_type).*repmat([1;2], 1, m);



%% step 5: birth_run
birth_run = zeros(size(body_part));
birth_run(body_part>0) = 1;

%% step 6: source
source = cell(size(body_part));
source(body_part>0) = {'M'};
source(body_part==0) = {'U'};

%% step 7: mark_flag
mark_flag = cell(size(body_part));
mark_flag(body_part>0) = {'Y'};
mark_flag(body_part==0) = {'N'};

%% step 8: last_update_time_mask
last_update_time_mask = zeros(size(body_part));
last_update_time_mask(body_part>0) = 1;

% for k=1:2
%     for mm=1:m
%         if body_part(k,mm)>0 && strcmp(mark_flag{k,mm}, 'Y')
%             assert(box_type(k,mm)~=0);
%         end
%     end
% end