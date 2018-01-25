function [gamma, curr_image_handle] = show_feedback_box(curr_axes, img, body_rect, cursor_pos, show_yellow_box_flag)

if nargin<5
    show_yellow_box_flag = [true;true];
end

alpha = [0;0];  % alpha blending parameter
gamma = [0;0];  % confidence

beta = 0.05;    % suggest: 0-0.1
theta = 0.25;   % suggest: 0-1

[height, width, ~] = size(img);

for i=1:size(body_rect,1)
    
    if abs(cursor_pos(i))<=beta
        alpha(i) = 0;
        gamma(i) = 0;
    elseif cursor_pos(i)>beta
        alpha(i) = theta*(cursor_pos(i)-beta)/(1-beta);
        gamma(i) = alpha(i)/theta;
    elseif cursor_pos(i)<-1*beta
        alpha(i) = -1*theta*(cursor_pos(i)+beta)/(1-beta);
        gamma(i) = -1*alpha(i)/theta;
    end

    h1 = max(0, body_rect(i,2));
    h2 = min(height, body_rect(i,2) + body_rect(i,4));
    w1 = max(0, body_rect(i,1));
    w2 = min(width, body_rect(i,1) + body_rect(i,3));
    
    feedback_mask = img;
    
    if gamma(i)>0
        feedback_mask(h1:h2,w1:w2,2)=255;
        feedback_mask(h1:h2,w1:w2,1)=0;
        feedback_mask(h1:h2,w1:w2,3)=0;
    elseif gamma(i)<0
        feedback_mask(h1:h2,w1:w2,1)=255;
        feedback_mask(h1:h2,w1:w2,2:3)=0;
    else
        feedback_mask(h1:h2,w1:w2,1:2)=255;
        feedback_mask(h1:h2,w1:w2,3)=0;
    end

    img = uint8((1-abs(alpha(i)))*img + abs(alpha(i))*feedback_mask);
end

% axes(handles.axes1);                      % 确定当前操作的坐标轴
axes(curr_axes);
curr_image_handle = imshow(img);                              % 展示图片

for i=1:size(body_rect,1)
    if gamma(i)>0
        rectangle('Position',body_rect(i,:),'LineWidth',1,'LineStyle','-','EdgeColor','g');
    elseif gamma(i)<0
        rectangle('Position',body_rect(i,:),'LineWidth',1,'LineStyle','-','EdgeColor','r');
    elseif show_yellow_box_flag(i)
        rectangle('Position',body_rect(i,:),'LineWidth',1,'LineStyle','-','EdgeColor','y');
    end
end
