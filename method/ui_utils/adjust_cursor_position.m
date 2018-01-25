function adjust_cursor_position(cur_pos, conf)

set(handles.slider1_torso, 'Value', cur_pos(1));
set(handles.slider1_leg, 'Value', cur_pos(2));

set(handles.st1_torso, 'String', sprintf('%.2f', conf(1))); 
set(handles.st1_leg, 'String', sprintf('%.2f', conf(2))); 
