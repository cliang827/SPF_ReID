function varargout = picture(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @picture_OpeningFcn, ...
                   'gui_OutputFcn',  @picture_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before picture is made visible.
function picture_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for picture
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes picture wait for user response (see UIRESUME)
% uiwait(handles.picture);
handles.src = varargin{2};
switch handles.src
    case 'axes'
        assert(varargin{1}>=1 && varargin{1}<=20);
        handles.id = varargin{1};
        picture_name = getappdata(0,['picture_' num2str(handles.id) '_gallery_name']);    % 读出图片
    case 'uitable'
        if varargin{4}==1
            handles.id = varargin{1};
        end
        picture_name = varargin{3};
end
setappdata(hObject, 'picture_name', picture_name);
probe_name = getappdata(0, 'probe_name');


dir_info = getappdata(0,'dir_info');
image_format = getappdata(0, 'image_format');
gallery_image = imread([dir_info.gallery_dir picture_name '.' image_format]);
setappdata(hObject, 'gallery_image', gallery_image);
probe_image = imread([dir_info.probe_dir probe_name '.' image_format]);
arrow_image = imread([dir_info.ui_dir 'arrow.png']);

axes(handles.axes_probe);
imshow(probe_image);

axes(handles.axes_arrow_torso);
imshow(arrow_image);

axes(handles.axes_arrow_leg);
imshow(arrow_image);

%% load body div
body_div_dir =[dir_info.body_div_dir strrep(picture_name, image_format, 'mat')];
load(body_div_dir);
two_box_rect = parse_body_div_mat(body_div_map);
setappdata(hObject, 'two_box_rect', two_box_rect);

%% check feedback info
last_feedback = [];
box_rect = two_box_rect;
cur_pos = [0;0];
% ix_mask = [false;false];
show_yellow_box_flag = [false;false];
feedback_info = getappdata(0, 'feedback_info');
gallery_name_tab = feedback_stat(feedback_info);
[tf, loc] = ismember(picture_name, gallery_name_tab);
if tf
    last_feedback = feedback_info.feedback_details{loc};
    
    box_rect = last_feedback.box_rect;
    cur_pos = last_feedback.cur_pos;
    source = last_feedback.source;
    
    for k=1:2
        if strcmp('S', source(k))
            show_yellow_box_flag(k) = true;
        end
    end
end
setappdata(hObject, 'cur_pos', cur_pos);
setappdata(hObject, 'last_feedback', last_feedback);
setappdata(hObject, 'show_yellow_box_flag', show_yellow_box_flag);

conf = show_feedback_box(handles.axes_gallery, gallery_image, box_rect, cur_pos, show_yellow_box_flag);
setappdata(hObject, 'conf', conf);

set(handles.slider1_torso, 'Value', cur_pos(1));
set(handles.slider1_leg, 'Value', cur_pos(2));

set(handles.st1_torso, 'String', sprintf('%.2f', conf(1))); 
set(handles.st1_leg, 'String', sprintf('%.2f', conf(2))); 

guidata(hObject,handles);

% --- Outputs from this function are returned to the command line.
function varargout = picture_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on slider movement.
function slider1_torso_Callback(hObject, eventdata, handles)
cur_pos = getappdata(handles.picture, 'cur_pos');
cur_pos(1) = get(hObject,'Value');
setappdata(handles.picture, 'cur_pos', cur_pos);

gallery_image = getappdata(handles.picture, 'gallery_image');
box_rect = getappdata(handles.picture, 'two_box_rect');

show_yellow_box_flag = getappdata(handles.picture, 'show_yellow_box_flag');
conf = show_feedback_box(handles.axes_gallery, gallery_image, box_rect, cur_pos, show_yellow_box_flag);
setappdata(handles.picture, 'conf', conf);

set(handles.st1_torso, 'String', sprintf('%.2f', conf(1))); 
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function slider1_torso_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on slider movement.
function slider1_leg_Callback(hObject, eventdata, handles)
cur_pos = getappdata(handles.picture, 'cur_pos');
cur_pos(2) = get(hObject,'Value');
setappdata(handles.picture, 'cur_pos', cur_pos);

gallery_image = getappdata(handles.picture, 'gallery_image');
box_rect = getappdata(handles.picture, 'two_box_rect');

show_yellow_box_flag = getappdata(handles.picture, 'show_yellow_box_flag');
conf = show_feedback_box(handles.axes_gallery, gallery_image, box_rect, cur_pos, show_yellow_box_flag);
setappdata(handles.picture, 'conf', conf);

set(handles.st1_leg, 'String', sprintf('%.2f', conf(2)));
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function slider1_leg_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in pb_save.
function pb_save_Callback(hObject, eventdata, handles)
%% 整理标记结果
last_feedback = getappdata(handles.picture, 'last_feedback');
conf = getappdata(handles.picture, 'conf');
cur_pos = getappdata(handles.picture, 'cur_pos');
query_times = getappdata(0, 'query_times');
picture_name = getappdata(handles.picture, 'picture_name');
operator = getappdata(0, 'operator');
feedback_details = [];
if isempty(last_feedback)       % 初始加载的是一张干净图片，既不是来源于推荐，又不是来源于日志
    if 0~=conf(1) || 0~=conf(2) % 对图像用户进行了反馈
        feedback_details.gallery_name = picture_name;
        feedback_details.box_rect = getappdata(handles.picture, 'two_box_rect');
        feedback_details.box_type = sign(conf);
        feedback_details.box_conf = abs(conf);
        feedback_details.cur_pos = cur_pos;
        feedback_details.body_part = [0;0];
        feedback_details.birth_run = [0;0];
        feedback_details.source = ['U';'U'];
        feedback_details.mark_flag = ['N';'N'];
        feedback_details.last_update_time = zeros(2,6);
        feedback_details.operator = {'default';'default'};
        
        for k=1:2
            if 0~=conf(k) % 第i个身体区域存在改动
                feedback_details.body_part(k) = k;
                feedback_details.birth_run(k) = query_times;                 % 代表是哪一轮检索后产生的（出生轮次）
                feedback_details.source(k) = 'M';                            % 'S'代表算法Suggest,'M'代表用户主动选取,'U'代表未知,
                feedback_details.mark_flag(k) = 'Y';                         % 'Y' 表示被用户采纳, 'N'表示未被用户采纳
                feedback_details.last_update_time(k,:) = fix(clock);         % 更新时间
                feedback_details.operator{k} = operator;
            end
        end
    end
else % 之前加载的图片本身就有标记，可能是来源于系统推荐'S'或者之前用户的标记'M'
    last_cur_pos = last_feedback.cur_pos;
    feedback_details = last_feedback;
    for k=1:2
        if cur_pos(k)~=last_cur_pos(k) % 第k个身体区域存在改动
            
            
            if 0==conf(k) 
                feedback_details.box_type(k) = 0;
                feedback_details.box_conf(k) = 0;
                feedback_details.cur_pos(k) = 0;   
                feedback_details.birth_run(k) = 0;
                feedback_details.last_update_time(k,:) = zeros(1,6);
                feedback_details.operator{k} = 'default';
                feedback_details.mark_flag(k) = 'N';
                if strcmp('M', feedback_details.source(k))
                    feedback_details.source(k) = 'U';
                    feedback_details.body_part(k) = 0;
                else
                    feedback_details.body_part(k) = k;
                end
            else
                feedback_details.box_type(k) = sign(conf(k));
                feedback_details.box_conf(k) = abs(conf(k));
                feedback_details.cur_pos(k) = cur_pos(k);   
                feedback_details.body_part(k) =k*double(logical(conf(k)));
                feedback_details.birth_run(k) = query_times;
                feedback_details.last_update_time(k,:) = fix(clock);
                feedback_details.operator{k} = operator;
                feedback_details.mark_flag(k) = 'Y';
                if strcmp('U', feedback_details.source(k))
                    feedback_details.source(k) = 'M';
                end
            end
        end
    end

    if strcmp(feedback_details.mark_flag(1),'N') && ...
            strcmp(feedback_details.mark_flag(2),'N') && ...
            ~ismember('S', feedback_details.source)
        % 对于无合法标记，且又不包含建议反馈，则干掉
        feedback_details = [];
    end
end

%% 更新feedback_info
if ~isempty(feedback_details)   % 存在有效的标注
    
    feedback_info = getappdata(0, 'feedback_info');
    if ~isempty(feedback_info) 
        gallery_name_tab = feedback_stat(feedback_info);
        [tf, loc] = ismember(picture_name, gallery_name_tab);
        if tf
            assert(strcmp(picture_name, feedback_info.feedback_details{loc}.gallery_name));
            feedback_info.feedback_details{loc} = feedback_details;
        else
            n = length(gallery_name_tab);
            feedback_info.feedback_details{n+1} = feedback_details;
        end
    else
        feedback_info.probe_info.probe_name = getappdata(0, 'probe_name');
        feedback_info.probe_info.probe_id = getappdata(0, 'probe_id');
        feedback_info.feedback_details = feedback_details;
    end
    setappdata(0, 'feedback_info', feedback_info);
    
else % 无有效的反馈标注
    feedback_info = getappdata(0, 'feedback_info');
    if ~isempty(feedback_info) % 之前的标注不为空，则涉及到调整相关的标记信息
        gallery_name_tab = feedback_stat(feedback_info);
        [tf, loc] = ismember(picture_name, gallery_name_tab);
        if tf
            assert(strcmp(picture_name, feedback_info.feedback_details{loc}.gallery_name));
            feedback_info.feedback_details(loc) = [];
            setappdata(0, 'feedback_info', feedback_info);
        end
    end
end

%% result show
if isfield(handles,'id')
    curr_axes = getappdata(0,['axes' num2str(handles.id)]);  %获得当前要操作的坐标轴，即主界面上的坐标轴
    gallery_image = getappdata(handles.picture, 'gallery_image');
    box_rect = getappdata(handles.picture, 'two_box_rect');
    cur_pos = getappdata(handles.picture, 'cur_pos');

    show_yellow_box_flag = getappdata(handles.picture, 'show_yellow_box_flag');
    [~, curr_image_handle] = show_feedback_box(curr_axes, gallery_image, box_rect, cur_pos, show_yellow_box_flag); %重绘图片

    set(curr_image_handle, 'ButtonDownFcn', sprintf('picture(%d, ''axes'')',handles.id));      % 单击每张图片，打开标注小窗口
end
close(handles.picture); %画框结束，关闭子界面

identify_show_gallery_info2('default_mode');
show_reid_results('picture_mode');

% --- Executes on button press in pb1_init.
function pb1_init_Callback(hObject, eventdata, handles)
switch handles.src 
    case 'axes'
        curr_axes = getappdata(0,['axes' num2str(handles.id)]);  %获得当前要操作的坐标轴，即主界面上的坐标轴
        set(curr_axes, 'ButtonDownFcn', sprintf('picture(%d)',handles.id));      % 单击每张图片，打开标注小窗口
    case 'uitable'
        if isfield(handles, 'id')
            curr_axes = getappdata(0,['axes' num2str(handles.id)]);  %获得当前要操作的坐标轴，即主界面上的坐标轴
            set(curr_axes, 'ButtonDownFcn', sprintf('picture(%d)',handles.id));      % 单击每张图片，打开标注小窗口
        end
end
close(handles.picture);

% --- Executes on button press in pb1_cancel.
function pb1_cancel_Callback(hObject, eventdata, handles)
switch handles.src 
    case 'axes'
        curr_axes = getappdata(0,['axes' num2str(handles.id)]);  %获得当前要操作的坐标轴，即主界面上的坐标轴
        set(curr_axes, 'ButtonDownFcn', sprintf('picture(%d)',handles.id));      % 单击每张图片，打开标注小窗口
    case 'uitable'
        if isfield(handles, 'id')
            curr_axes = getappdata(0,['axes' num2str(handles.id)]);  %获得当前要操作的坐标轴，即主界面上的坐标轴
            set(curr_axes, 'ButtonDownFcn', sprintf('picture(%d)',handles.id));      % 单击每张图片，打开标注小窗口
        end
end
close(handles.picture);

% --- Executes on button press in pb1_torso_zero.
function pb1_torso_zero_Callback(hObject, eventdata, handles)
set(handles.slider1_torso,'Value',0);
set(handles.st1_torso, 'String', sprintf('%.2f', 0)); 

cur_pos = getappdata(handles.picture, 'cur_pos');
cur_pos(1) = 0;
setappdata(handles.picture, 'cur_pos', cur_pos);

gallery_image = getappdata(handles.picture, 'gallery_image');
box_rect = getappdata(handles.picture, 'two_box_rect');


show_yellow_box_flag = getappdata(handles.picture, 'show_yellow_box_flag');
conf = show_feedback_box(handles.axes_gallery, gallery_image, box_rect, cur_pos, show_yellow_box_flag);
setappdata(handles.picture, 'conf', conf);

guidata(hObject,handles);

% --- Executes on button press in pb1_leg_zero.
function pb1_leg_zero_Callback(hObject, eventdata, handles)
set(handles.slider1_leg,'Value',0);
set(handles.st1_leg, 'String', sprintf('%.2f', 0)); 
cur_pos = getappdata(handles.picture, 'cur_pos');
cur_pos(2) = 0;
setappdata(handles.picture, 'cur_pos', cur_pos);

gallery_image = getappdata(handles.picture, 'gallery_image');
box_rect = getappdata(handles.picture, 'two_box_rect');

show_yellow_box_flag = getappdata(handles.picture, 'show_yellow_box_flag');
conf = show_feedback_box(handles.axes_gallery, gallery_image, box_rect, cur_pos, show_yellow_box_flag);
setappdata(handles.picture, 'conf', conf);
guidata(hObject,handles);


% --- Executes on mouse press over axes background.
function axes_gallery_ButtonDownFcn(hObject, eventdata, handles)
function picture_WindowButtonDownFcn(hObject, eventdata, handles)  
function picture_WindowButtonMotionFcn(hObject, eventdata, handles)
function picture_WindowButtonUpFcn(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function picture_CreateFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object deletion, before destroying properties.
function picture_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on mouse press over figure background.
function picture_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when picture is resized.
function picture_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on picture or any of its controls.
function picture_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key release with focus on picture or any of its controls.
function picture_WindowKeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on scroll wheel click while the figure is in focus.
function picture_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key press with focus on picture and none of its controls.
function picture_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on key release with focus on picture and none of its controls.
function picture_KeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close picture.
function picture_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to picture (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);
