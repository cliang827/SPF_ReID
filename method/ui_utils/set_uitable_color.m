function uitable_data = set_uitable_color(uitable_data)

[m, n] = size(uitable_data);
for i=1:m
    if ~isempty(strfind(uitable_data{i,5}, 'N'))
        background_color = '#FFFF00'; % null
        text_color = '#0000FF';
    elseif ~isempty(strfind(uitable_data{i,3}, '+'))
        background_color = '#00FF00'; % pos
        text_color = '#000000';
    elseif ~isempty(strfind(uitable_data{i,3}, '-'))
        background_color = '#FF0000'; % neg
        text_color = '#FFFFFF';
    else
        error('error item status!');
    end

    for j=1:n
        
        switch j
            case 1
                width = '50px';
            case 2
                width = '24px';
            case 3
                width = '24px';
            case 4
                width = '24px';
            case 5
                width = '24px';
            case 6
                width = '28px';
            case 7
                width = '24px';
            case 8
                width = '24px';
        end
        
        uitable_data{i,j} = strcat(['<html><body bgcolor="' background_color '" text="' text_color '"width="' width '">'], uitable_data{i,j});
    end
end

