

function varargout = reid_feedback(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @reid_feedback_OpeningFcn, ...
                   'gui_OutputFcn',  @reid_feedback_OutputFcn, ...
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



function reid_feedback_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;   
guidata(hObject, handles);

para_init;

% 禁用query, previous, next， finish按钮
set(handles.query,'enable','off');
set(handles.previous,'enable','off');
set(handles.next,'enable','off');
set(handles.jump, 'enable', 'off');

% 设置probe坐标轴
set(handles.axes_probe,'xTick',[]);
set(handles.axes_probe,'yTick',[]);
set(handles.axes_probe,'box','on');
% 设置truth坐标轴
set(handles.axes_groundtruth,'xTick',[]);
set(handles.axes_groundtruth,'yTick',[]);
set(handles.axes_groundtruth,'box','on');
%处理1-20个坐标轴
for i=1:20
    axes_i = findobj(0,'Tag',['axes' num2str(i)]);
    set(axes_i,'xTick',[]);
    set(axes_i,'yTick',[]);
    set(axes_i,'box','on');
    setappdata(0, ['axes' num2str(i)], axes_i);
end

% 设置radio button
setappdata(0, 'show_status', 'show our result');
set(handles.rb_ours,'value',1);
set(handles.rb_feedback,'value',0);
set(handles.rb_cvpr13,'value',0);
set(handles.rb_pcm14,'value',0);



function varargout = reid_feedback_OutputFcn(hObject, eventdata, handles)  
clc   
varargout{1} = handles.output;      


%% load data
function load_Callback(hObject, eventdata, handles)  

% step 1: select probe image
image_format = getappdata(0, 'image_format');
dir_info = getappdata(0, 'dir_info');
[probe_name, probe_path]=uigetfile(...
    {['*.' image_format],['ImageFiles(*.' image_format ')'];...
     '*.*','AllFiles(*.*)'},'Pick an image',  dir_info.probe_dir);

if isequal(probe_name,0)||isequal(probe_path,0),
    return;
end

% step 2: show probe image
st_text_probe_handle = findobj(0,'Tag','st_text_probe');
set(st_text_probe_handle, 'Visible', 'on');

probe_image = imread([probe_path probe_name]);    %用imread读入图片
axes(handles.axes_probe);                         %用axes命令设定当前操作的坐标轴是 axes_probe
imshow(probe_image);                              %用imshow在 axes1 上显示

probe_name = strrep(probe_name, ['.' image_format], '');
setappdata(0, 'probe_name', probe_name);          %保存probe_name的信息
setappdata(0, 'query_times', 0);
setappdata(0, 'feedback_info', []);
set(handles.query,'enable','on'); 

% step 3: show groundtruth image
st_text_groundtruth_handle = findobj(0,'Tag','st_text_groundtruth');
set(st_text_groundtruth_handle, 'Visible', 'on');

prbgal_name_tab = getappdata(0, 'prbgal_name_tab');
[~, probe_id] = ismember(probe_name, prbgal_name_tab(:,1));
setappdata(0, 'probe_id', probe_id);
assert(probe_id>0);

groundtruth_gallery_name = prbgal_name_tab{probe_id,2};
setappdata(0, 'groundtruth_gallery_name', groundtruth_gallery_name);                            % 保存probe_name的信息 
groundtruth_gallery = imread([dir_info.gallery_dir groundtruth_gallery_name '.' image_format]); % 用imread读入图片
axes(handles.axes_groundtruth);                                                                 % 用axes命令设定当前操作的坐标轴是 axes_probe
imshow(groundtruth_gallery);                                                                    % 用imshow在 axes1 上显示

curr_groundtruth_rank_handle = findobj(0,'Tag','textgroundtruth_rank_c');
set(curr_groundtruth_rank_handle, 'String', '');

% step 4: clear
clear_reid_result();

%% Query
function query_Callback(hObject, eventdata, handles) 

% step 1: set page_id and query_times
page_id = 1;
setappdata(0, 'page_id', page_id);

query_times = 1+getappdata(0, 'query_times');
setappdata(0, 'query_times', query_times);

% step 2: Solve f and V for ranking
% 算法调试
ctrl_para.DEBUG_FLAG = false;
ctrl_para.SHOW_DETAILS = false;
% solve_fV(ctrl_para);
solve_fV_test5(ctrl_para);   

% step 3: show reid results
identify_show_gallery_info2('query_mode');
show_reid_results('default_mode');

% --- Executes during object creation, after setting all properties.
function et_page_id_CreateFcn(hObject, eventdata, handles)
% hObject    handle to et_page_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in jump.
function jump_Callback(hObject, eventdata, handles)
% hObject    handle to jump (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% step 1: identify page_id
et_page_id_handle = findobj(0, 'Tag', 'et_page_id');
jump_page_id = str2double(get(et_page_id_handle, 'String'));

% step 2: show gallery
last_page_id = getappdata(0, 'last_page_id');
if jump_page_id>=1 && jump_page_id<=last_page_id
    setappdata(0, 'page_id', jump_page_id);              %保存当前页数

    identify_show_gallery_info2('default_mode');
    show_reid_results('default_mode');
else
    page_id = getappdata(0, 'page_id');
    set(et_page_id_handle, 'String', num2str(page_id));
end

%% next按钮======================================================================
function next_Callback(hObject, eventdata, handles)
% step 1: identify page_id
page_id = getappdata(0,'page_id');              %页面计数变量
page_id = page_id + 1;                          %单击一次next，页数+1
setappdata(0, 'page_id', page_id);              %保存当前页数

% step 2: show gallery
identify_show_gallery_info2('default_mode');
show_reid_results('default_mode');


%previous按钮======================================================================
function previous_Callback(hObject, eventdata, handles)
% step 1: identify page_id
page_id = getappdata(0,'page_id');              %页面计数变量
page_id = page_id - 1;                          %单击一次next，页数+1
setappdata(0, 'page_id', page_id);              %保存当前页数

% step 2: show gallery
identify_show_gallery_info2('default_mode');
show_reid_results('default_mode');


% --- Executes on button press in rb_ours.
function rb_ours_Callback(hObject, eventdata, handles)
% hObject    handle to rb_ours (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_ours
show_status = getappdata(0, 'show_status');
if ~strcmp(show_status, 'show our result')
%     setappdata(0, 'query_times', 1);
    setappdata(0, 'show_status', 'show our result');
    setappdata(0, 'page_id', 1); 
    
    identify_show_gallery_info2('default_mode');
    show_reid_results('default_mode');

    set(handles.rb_ours,'value',1);
    set(handles.rb_feedback,'value',0);
    set(handles.rb_cvpr13,'value',0);
    set(handles.rb_pcm14,'value',0);
end


% --- Executes on button press in rb_feedback.
function rb_feedback_Callback(hObject, eventdata, handles)
% hObject    handle to rb_feedback (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_feedback
show_status = getappdata(0, 'show_status');
if ~strcmp(show_status, 'show feedback result')
%     setappdata(0, 'query_times', 1);
    setappdata(0, 'show_status', 'show feedback result');
    setappdata(0, 'page_id', 1); 
    
    identify_show_gallery_info2('default_mode');
    show_reid_results('default_mode');

    set(handles.rb_ours,'value',0);
    set(handles.rb_feedback,'value',1);
    set(handles.rb_cvpr13,'value',0);
    set(handles.rb_pcm14,'value',0);
end


% --- Executes on button press in rb_cvpr13.
function rb_cvpr13_Callback(hObject, eventdata, handles)
% hObject    handle to rb_cvpr13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_cvpr13
setappdata(0, 'show_status', 'show cvpr13 result');

set(handles.rb_ours,'value',0);
set(handles.rb_feedback,'value',0);
set(handles.rb_cvpr13,'value',1);
set(handles.rb_pcm14,'value',0);


% --- Executes on button press in rb_pcm14.
function rb_pcm14_Callback(hObject, eventdata, handles)
% hObject    handle to rb_pcm14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_pcm14
setappdata(0, 'show_status', 'show pcm14 result');

set(handles.rb_ours,'value',0);
set(handles.rb_feedback,'value',0);
set(handles.rb_cvpr13,'value',0);
set(handles.rb_pcm14,'value',1);



function et_page_id_Callback(hObject, eventdata, handles)
% hObject    handle to et_page_id (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of et_page_id as text
%        str2double(get(hObject,'String')) returns contents of et_page_id as a double


% --- Executes when entered data in editable cell(s) in uitable.
function uitable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when selected cell(s) is changed in uitable.
function uitable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to uitable (see GCBO)
% eventdata  structure with the following fields (see UITABLE)
% Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
image_num_per_page = getappdata(0,'image_num_per_page');
show_gallery_info = getappdata(0, 'show_gallery_info');
if ~isempty(eventdata.Indices)
    feedback_gallery_rank = str2double(show_gallery_info.uitable_data{eventdata.Indices(1),6});
    feedback_gallery_page_id = str2double(show_gallery_info.uitable_data{eventdata.Indices(1),7});
    feedback_gallery_picture_id = feedback_gallery_rank - (feedback_gallery_page_id-1)*image_num_per_page;
    feedback_gallery_name = show_gallery_info.uitable_data{eventdata.Indices(1),1};
    picture(feedback_gallery_picture_id,'uitable',feedback_gallery_name,feedback_gallery_page_id);
end
