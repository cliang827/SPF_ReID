clear
close all
clc

addpath(genpath(fullfile([pwd '\method'])));
Initialization2;
Score_Torse = exp(-g2p_dist(:,:,1));
Score_Leg =exp(-g2p_dist(:,:,2));
Score_g2g_torse = exp(-g2g_dist(:,:,1));
Score_g2g_leg = exp(-g2g_dist(:,:,2));
Score = reid_score;
Score_All = Score;
Picture = prbgal_name_tab;
groundtruth = repmat(1:316,316,1);
FBData = '.\data\viper\feedback\mmap\';
Conf = zeros(4, 316);

NumofGallery = 316;
NumofFeedBack = 1; %使用的反馈的数据的对数
NumofProbe = 316;
Part = 1;%使用上半身
T = 0.1;%近邻相似阈值
K = 8;   %聚类类数
a = 0.3; %融合系数

ScoreNS = zeros(316,316);
Score = zeros(316,316);
% ScoreCS = zeros(316,316);
% [Idx1,C1,MIDX1] = Cluster(1,K);
% [Idx2,C2,MIDX2] = Cluster(2,K); 

start_times = 1;
repeat_times = 1000;
feedback_info_origin = cell(1, NumofProbe);
debug_flag = false;

for tst =start_times:start_times+repeat_times-1
    rand('seed', tst); %#ok<RAND>
    
    tic
    for iProbe = 1:NumofProbe
        if iProbe == 316
            stop = 1;
        end
        
        if debug_flag
            load(sprintf('.\\result\\pcm14\\details\\run_%d.mat', tst));
            O = feedback_info_origin{iProbe};
        else
            load([FBData,Picture{iProbe,1},'.mat']);
            [O, Conf(:,iProbe)] = GetOF2(feedback_info,NumofFeedBack,iProbe);
            feedback_info_origin{iProbe} = O;
        end
        
        
        
        %     MaxK1 = GetMaxCluster(Idx1,O,1);
        %     MaxK2 = GetMaxCluster(Idx2,O,2);
        for iGallery = 1:NumofGallery
        %     MIDX1;
        %     MIDX2;
            O;
            %%计算近邻得分

            for i=1:NumofFeedBack
                if Part==1
                    S_gallery = O.SimilarTorse{i,2};
                    DS_gallery = O.DissimilarTorse{i,2};
                    Score1_S  = Score_g2g_torse(S_gallery,iGallery);
                    Score1_DS  = Score_g2g_torse(DS_gallery,iGallery);
                    S = (Score1_S - Score1_DS)*Idicate(Score1_S,Score1_DS,T);
                    ScoreNS(iGallery,iProbe) = ScoreNS(iGallery,iProbe) + S;

                    S_gallery = O.SimilarLeg{i,2};
                    DS_gallery = O.DissimilarLeg{i,2};
                    Score2_S  = Score_g2g_leg(S_gallery,iGallery);
                    Score2_DS  = Score_g2g_leg(DS_gallery,iGallery);
                    S = (Score2_S - Score2_DS)*Idicate(Score2_S,Score2_DS,T);
                    ScoreNS(iGallery,iProbe) = ScoreNS(iGallery,iProbe) + S;
                end
            end
        end
%         if mod(iProbe,50)==0
%             fprintf('the %d, %d,Score has done!\n',tst,iProbe); 
%         end
    end
    % Score = Score_All + a.*ScoreCS + (1-a).*ScoreNS;
    Score1 = Score_All + ScoreNS;
    
    cmc_result  = result_evaluation(Score1,groundtruth);
    auc_result = 0.5*(2*sum(cmc_result) - cmc_result(1) - cmc_result(end))/length(cmc_result);
    
    
    Score = Score + Score1;
    
    ave_conf = mean(Conf,2);
    fprintf(1, 'Exp %d: auc = %.2f%%, conf=%.2f%%[%.2f%%;%.2f%%|%.2f%%;%.2f%%], time=%.2f\n', ...
        tst, 100*auc_result, 100*mean(ave_conf), 100*ave_conf(1), 100*ave_conf(2), 100*ave_conf(3), 100*ave_conf(4), toc);

    reid_score = Score1;
    
%     save(sprintf('.\\result\\pcm14\\details\\run_%d.mat', tst), 'reid_score', 'ave_conf', 'cmc_result', 'auc_result', 'feedback_info_origin');
end
Score = Score./repeat_times;


%%
N = 316;


y0  = result_evaluation(Score_All,groundtruth);
y1  = result_evaluation(Score,groundtruth);

auc0 = 0.5*(2*sum(y0) - y0(1) - y0(end))/N;
auc1 = 0.5*(2*sum(y1) - y1(1) - y1(end))/N;

x = 1:N;

figure
plot(x,y0,'r','LineWidth',0.5);
hold on
plot(x,y1,'b','LineWidth',0.5);
hold on
axis([0,N,0,1]);
grid on
legend(sprintf('auc0=%.2f%%', 100*auc0), sprintf('auc1=%.2f%%', 100*auc1));
title('T =0.1 M =1');


    
    

