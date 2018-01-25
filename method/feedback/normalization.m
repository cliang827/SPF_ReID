function f = normalization(f, range, center)
% purpose: normalize f into range=[-1,1] and center at center=0

if nargin==1
    range = [-1 1];
    center = 0;
end
    

f = f - mean(f);
f1 = abs(max(f));
f2 = abs(min(f));
sigma = 1/max(f1, f2);
f = f*sigma;

assert(max(f)<=range(2) && min(f)>=range(1) && norm(mean(f)-center)<1e-6)




