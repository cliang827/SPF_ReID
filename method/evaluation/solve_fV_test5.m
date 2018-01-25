function [f, V, model_para, J_val, iter_fVs] = solve_fV_test5(ctrl_para, feedback_info, groundtruth_feedback, ix_info_tab) %#ok<*STOUT,*INUSD>

DEBUG_FLAG = ctrl_para.DEBUG_FLAG;
SHOW_DETAILS = ctrl_para.SHOW_DETAILS;


if DEBUG_FLAG
    init_debug_solve_fV3;
else
    init_solve_fV3;
end

% step 1: init SPF model parameters
model_para = init_model_para(W, Y0, f0, V0, FBL, query_times, ctrl_para);

%% step 2: alternative optimization between f and V
V = V0;
Y = Y0;
f = f0;

J_val = zeros(2, outer_loop_max_iter_times);
time_rec = zeros(2, outer_loop_max_iter_times);
iter_fVs = cell(1, outer_loop_max_iter_times);

if SHOW_DETAILS
    if query_times==1
        fprintf(1, '\n\t query_times = %d\n', query_times);
    else
        fprintf(1, '\t query_times = %d\n', query_times);
    end
end

%% core solve_fV algorithm
iter_times = 0;
while 1
    iter_times = iter_times + 1;
    
    %% f-step
    if DEBUG_FLAG && SHOW_DETAILS
        tic
    elseif ~DEBUG_FLAG
        str=['Iteration no.',num2str(iter_times), ' -f'];
        waitbar(min(1,iter_times/waitbar_step),hwait,str);
    end
    
    if 1<query_times % in the init query, jump f-step
        f = solve_for_f2(V, W, Y, model_para, ctrl_para);
    end
    J_val(1, iter_times) = J_func(f, V, W, Y, model_para, ctrl_para);
    
    if DEBUG_FLAG && SHOW_DETAILS
        time_rec(1, iter_times) = toc;
        fprintf(1, '\t\t%02d-f,\t J(f)=%+5.3e,\t Time=%5.3f\n', iter_times, J_val(1, iter_times), time_rec(1, iter_times));
    end    

    %% V-step
    if DEBUG_FLAG && SHOW_DETAILS
        tic
    elseif ~DEBUG_FLAG
        str=['Iteration no.',num2str(iter_times), ' -V'];
        waitbar(min(1,iter_times/waitbar_step),hwait,str);
    end

    V = solve_for_V2(f, V, W, Y, FBL, model_para, ctrl_para);
    J_val(2, iter_times) = J_func(f, V, W, Y, model_para, ctrl_para);

    if DEBUG_FLAG && SHOW_DETAILS
        time_rec(2, iter_times) = toc;
        [~, ix]=sort(V, 'descend');
        fprintf(1, '\t\t%02d-V,\t J(V)=%+5.3e,\t Time=%5.3f | (%d,%d,%d,%d,%d)-(%d,%d,%d,%d,%d)\n\n',...
            iter_times, J_val(2, iter_times), time_rec(2, iter_times), ix(1:5,1), ix(1:5,2));
    end
   
    %% break check
    iter_fVs{iter_times}.f = f(2:end);
    iter_fVs{iter_times}.V = V(2:end,:);
    if abs(J_val(1,iter_times)-J_val(2,iter_times))/abs(J_val(2,iter_times))<epsilon_J || iter_times>=outer_loop_max_iter_times || 1==query_times
        break;
    end
end

J_val = J_val(:,1:iter_times);
iter_fVs = iter_fVs(1, 1:iter_times);

f(1) = [];
V(1,:) = [];

if ~DEBUG_FLAG
    waitbar(1,hwait,str);
    close(hwait);
end

%% result feedback: f->curr_reid_score, V->feedback suggestion
if 1==query_times
    last_reid_score = [];
else
    last_reid_score = getappdata(0, 'curr_reid_score');
end
setappdata(0, 'curr_reid_score', f);
setappdata(0, 'last_reid_score', last_reid_score);
setappdata(0, 'V', V);

