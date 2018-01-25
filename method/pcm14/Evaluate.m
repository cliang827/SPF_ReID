clc
clear

load('.\result\pcm14\Score.mat');
load('.\method\pcm14\Score1','Score1');
load('.\method\pcm14\Score2','Score2');
N = 316;

groundtruth = repmat(1:316,316,1);
y0  = result_evaluation(Score_All,groundtruth);
y1  = result_evaluation(Score1,groundtruth);
y2  = result_evaluation(Score2,groundtruth);
y0 = y0(1:N); auc0 = sum(y0);
y1 = y1(1:N); auc1 = sum(y1);
y2 = y2(1:N); auc2 = sum(y2);
x = 1:N;

figure
plot(x,y0,'r','LineWidth',0.5);
hold on
plot(x,y1,'b','LineWidth',0.5);
hold on
plot(x,y2,'g','LineWidth',0.5);
axis([0,N,0,1]);
grid on
legend(sprintf('auc0=%.2f', auc0), sprintf('auc1=%.2f', auc1));
title('T =0.1 M =1');