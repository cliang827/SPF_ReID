load('Aford_20-v2');
groundtruth = repmat(1:316,20,1);
X = (Aford_20==groundtruth);
B = sum(X);
[R,C] = find(X==1);


j=0;
for i=1:316
    if B(1,i)==1
        j=j+1;
       B(2,i) = R(j);
    end
end
IsGroundTruth =B;
F_M = X;

save('IsGroundTruth20','IsGroundTruth','F_M');
