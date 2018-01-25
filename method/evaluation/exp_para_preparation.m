function [test_para_tab, para_name_tab, test_name_tab] = exp_para_preparation(test_para_list, ctrl_para)

erase_flag = ctrl_para.ERASE_TESTED_EXP;
fig_flag = ctrl_para.DRAW_FIG;
details_flag = ctrl_para.SAVE_DETAILS;

alpha_range = ctrl_para.alpha_range; 
beta_range =  ctrl_para.beta_range;     % betaֵԽ��VԽϡ��
gamma_range = ctrl_para.gamma_range;

fbppr = ctrl_para.fbppr;
feedback_type = ctrl_para.feedback_type;


exp_para_set_file_dir = [];
switch ctrl_para.dev_env
    case 'linux'
        exp_para_set_file_dir = './temp/exp_para_set.mat';
    case 'windows'
        exp_para_set_file_dir = '.\temp\exp_para_set.mat';
end



if ~exist(exp_para_set_file_dir,'file')
    
    exp_para_list.model_type = {'nspf', 'spf'};
    exp_para_list.init_Y_method = {'p2g'};  
    exp_para_list.norm_type = [1 2];
    exp_para_list.alpha_init_order = -3:0.5:3;
    exp_para_list.beta_init_order = -3:0.5:3;
    exp_para_list.gamma_init_order = [-8 -3:0.5:3];
    exp_para_list.update_ratio = 0:0.1:1;
    

    len_list = [];
    len_list = cat(1, len_list, length(exp_para_list.model_type));
    len_list = cat(1, len_list, length(exp_para_list.init_Y_method));
    len_list = cat(1, len_list, length(exp_para_list.norm_type));
    len_list = cat(1, len_list, length(exp_para_list.alpha_init_order));
    len_list = cat(1, len_list, length(exp_para_list.beta_init_order));
    len_list = cat(1, len_list, length(exp_para_list.gamma_init_order));
    len_list = cat(1, len_list, length(exp_para_list.update_ratio));
    len_list_len = length(len_list);
    
    tot_exp_num = prod(len_list);
    exp_para_ix_tab = zeros(tot_exp_num, len_list_len);
    
    for i=1:len_list_len 
        ele_rep_times = tot_exp_num/prod(len_list(1:i));
        whole_rep_times = prod(len_list(1:i-1));
        
        temp = repmat(1:len_list(i),[ele_rep_times,1]);
        temp = reshape(temp, [len_list(i)*ele_rep_times 1]);
        temp = repmat(temp, [1 whole_rep_times]);
        temp = reshape(temp, [tot_exp_num 1]);
        exp_para_ix_tab(:,i) = temp;
    end
    
    save(exp_para_set_file_dir, '-v7.3', 'exp_para_list', 'exp_para_ix_tab');
end

load(exp_para_set_file_dir);
para_name_tab = fieldnames(exp_para_list);
field_num = length(para_name_tab);
invalid_ix_tab = zeros(size(exp_para_ix_tab, 1), 1);
for i=1:length(para_name_tab)
    test_field = test_para_list.(para_name_tab{i});
    exp_field = exp_para_list.(para_name_tab{i});
    if isa(class(test_field), 'double')
        test_field = int32(1e3*test_field);
        exp_field = int32(1e3*exp_field);
    end
    
    if ~all(ismember(test_field, exp_field))
        error('new test parameter value of %s', para_name_tab{i});
    else
        [~, invalid_ix] = setdiff(exp_field,test_field);
        for j=1:length(invalid_ix)
            invalid_ix_tab(exp_para_ix_tab(:,i)==invalid_ix(j))=1;
        end
    end
end

exp_para_ix_tab(invalid_ix_tab==1,:)=[];
test_times = size(exp_para_ix_tab, 1);
test_para_tab = cell(test_times, field_num);
test_name_tab = cell(test_times, 1);
tested_ix_tab = zeros(test_times, 1);
for i=1:test_times
    for j=1:field_num
        para_set = exp_para_list.(para_name_tab{j});
        para_value = para_set(exp_para_ix_tab(i,j));
        switch class(para_value)
            case 'cell'
                test_para_tab(i,j) = para_value;
                if isempty(test_name_tab{i})
                    test_name_tab{i} = char(para_value);
                else
                    test_name_tab{i} = sprintf('%s_%s', test_name_tab{i}, char(para_value));
                end
            case 'double'
                if strcmp(para_name_tab{j}, 'alpha_init_order')
                    test_para_tab{i,j} = para_value + alpha_range;
                elseif strcmp(para_name_tab{j}, 'beta_init_order')
                    test_para_tab{i,j} = para_value + beta_range;
                elseif strcmp(para_name_tab{j}, 'gamma_init_order')
                    test_para_tab{i,j} = para_value + gamma_range;
                else
                    test_para_tab{i,j} = para_value;
                end
                test_name_tab{i} = sprintf('%s_%.3f', test_name_tab{i}, para_value);
        end
    end
    
    if ~isempty(fbppr)
        test_name_tab{i} = [test_name_tab{i}  '_' feedback_type '_' mat2str(fbppr)];
    end
    
    test_exp_name_dir = [];
    test_exp_details_dir = [];
    test_exp_figs_dir = [];
    switch ctrl_para.dev_env
        case 'linux'
            test_exp_name_dir = ['./temp/' test_name_tab{i}];
            test_exp_name_dir_ = [test_exp_name_dir '/'];
            test_exp_details_dir_ = [test_exp_name_dir_ 'details/'];
            test_exp_figs_dir_ = [test_exp_name_dir_ 'figs/'];
        case 'windows'
            test_exp_name_dir = ['.\temp\' test_name_tab{i}];
            test_exp_name_dir_ = [test_exp_name_dir '\'];
            test_exp_details_dir_ = [test_exp_name_dir_ 'details\'];
            test_exp_figs_dir_ = [test_exp_name_dir_ 'figs\'];
    end
    
    if exist(test_exp_name_dir, 'dir')
        if erase_flag
            rmdir(test_exp_name_dir_, 's');
            mkdir(test_exp_name_dir_);
        else
            tested_ix_tab(i) = 1;
        end
    else
        if ~exist(test_exp_name_dir, 'dir')
            mkdir(test_exp_name_dir_);
        else
            delete([test_exp_name_dir_ '*.mat']);
        end
    end

    if details_flag
        if ~exist(test_exp_details_dir_, 'dir')
            mkdir(test_exp_details_dir_);
        else
            delete([test_exp_details_dir_ '*.mat']);
        end
    end
        
    if fig_flag 
        if ~exist(test_exp_figs_dir_, 'dir')
            mkdir(test_exp_figs_dir_);
        else
            delete([test_exp_figs_dir_ '*.fig']);
        end
    end
end

para_name_tab{strcmp(para_name_tab , 'alpha_init_order')}='alpha_order_range';
para_name_tab{strcmp(para_name_tab , 'beta_init_order')}='beta_order_range';
para_name_tab{strcmp(para_name_tab , 'gamma_init_order')}='gamma_order_range';
 
if ~erase_flag
    test_para_tab(tested_ix_tab==1,:) = [];
    test_name_tab(tested_ix_tab==1,:) = [];
end




