Score = load('Score1.mat');
[~,Ind] = sort(Score1,'descend');
Aford_20 = Ind(1:20,:);
save('Aford_20','Aford_20');

