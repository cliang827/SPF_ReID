function [cmc_result, auc_result, hist_result] = result_evaluation(reid_score, groundtruth)
% save('.\temp\result_evaluation.mat', 'reid_score', 'groundtruth');

% clc 
% clear all
% close all
% load('.\temp\result_evaluation.mat');


[dummy, ordered] = sort(reid_score, 'descend');  %每一列从大到小排序
match = (ordered == groundtruth);

% cmc result
cmc_result = cumsum(sum(match, 2)./size(match, 2));

% auc_result
auc_result = 0.5*(2*sum(cmc_result) - cmc_result(1) - cmc_result(end))/size(reid_score, 1);

% hist_result
[row col] = find(match);
hist_result = hist(row,1:length(row));






