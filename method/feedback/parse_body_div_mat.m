function body_rect = parse_body_div_mat(body_div_map)
% 根据body div mat结果，分配上下矩形框的尺寸

[height width] = size(body_div_map);
type_code = max(body_div_map, [], 2);

torso_part_start = find(type_code==1, 1, 'first');
torso_part_height = length(find(type_code==1));

leg_part_start = find(type_code==2, 1, 'first');
leg_part_height = length(find(type_code==2));

torso_rect = [3, torso_part_start-1, width-5, torso_part_height];
leg_rect = [3, leg_part_start+1, width-5, leg_part_height-1];

body_rect = cat(1, torso_rect, leg_rect);