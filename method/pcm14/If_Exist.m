function a  = If_Exist(x,M)
a = 0;
for i = 1:size(M,1)
    
    if x ==M(i,1)
        a =1;
        break;
    end
end