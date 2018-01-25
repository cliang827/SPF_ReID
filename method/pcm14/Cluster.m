function [Idx,Center,MIDX] = Cluster(number,K)
Cam2Torse = 'F:\Jlx\ViperDataOur\Picture\Feature\FeatureCam2Torse.mat';
Cam2Leg = 'F:\Jlx\ViperDataOur\Picture\Feature\FeatureCam2Leg.mat';
 if number==1
     load(Cam2Torse);
     F =[];
     for i =1:size(FeatureCam2Torse,1)
         F(i,:)= FeatureCam2Torse{i,2};
     end
     [Idx,Center,~,~,MIDX] = kmedoids(F,K); 
 elseif number==2
     load(Cam2Leg);
     F =[];
     for i =1:size(FeatureCam2Leg,1)
         F(i,:)= FeatureCam2Leg{i,2};
     end
     [Idx,Center,~,~,MIDX]  = kmedoids(F,K);
 else
     assert(0);
 end
end