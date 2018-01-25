function a = Str_Exist(str,Cell)
a = 0;
for i =1:size(Cell,1)
    if strcmp(str,Cell{i,1})
        a =i;
        break;
    end
end