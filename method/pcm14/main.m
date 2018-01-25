clear all
clc;
% close all;
ScorePath  = '..\..\Score\';
MultiInter = 1;
FBData = '..\FBData\test_feedback\';
load([ScorePath,'Score_Leg.mat']);
load([ScorePath,'Score_Torse.mat']);
load([ScorePath,'Score_g2g_leg.mat']);
load([ScorePath,'Score_g2g_torse.mat']);
if MultiInter==1
    load('Score.mat');
    Score_All = Score;
else
load([ScorePath,'Score_All.mat']);
end
load('All_Name.mat');
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
for tst =1:10
    tic
    for iProbe = 1:NumofProbe
        load([FBData,Picture{iProbe,1}(1:end-4),'.mat']);
        O = GetOF(feedback_info,NumofFeedBack,iProbe);
        %     MaxK1 = GetMaxCluster(Idx1,O,1);
        %     MaxK2 = GetMaxCluster(Idx2,O,2);
        parfor iGallery = 1:NumofGallery
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
        fprintf('the %d, %d,Score has done!\n',tst,iProbe); 
    end
    % Score = Score_All + a.*ScoreCS + (1-a).*ScoreNS;
    Score1 = Score_All + ScoreNS;
    Score = Score + Score1;
    toc
end
Score = Score./10;
save('Score','Score');

run 'Evaluate.m'


    
    

