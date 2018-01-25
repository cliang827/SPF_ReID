function K = GetMaxCluster(Idx,O,number)
Y = [];
I = [];
if number==1
 for i =1:size(O.SimilarTorse,1)
     Y(i,1) =O.SimilarTorse{i,2};
 end
elseif number==2
 for i =1:size(O.SimilarLeg,1)
     Y(i,1) =O.SimilarLeg{i,2};
 end
end
for j=1:size(Y,1)
    I(j,1) = Idx(Y(j,1),1);
end
K = mode(I);