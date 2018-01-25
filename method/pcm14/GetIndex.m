function index = GetIndex(name)
load('All_Name.mat');
for i=1:size(Picture,1)
    if strcmp(name,Picture{i,2}(1:end -4))
        index = i;
        break;
    end
end