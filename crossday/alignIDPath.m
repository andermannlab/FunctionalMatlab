function path = alignIDPath(mouse, date)
%ALIGNIDPATH Get the path to the id alignment file. This outside of sbxPath
%   because run is not required.

    if ~ischar(date), date = num2str(date); end
    
    path = [];
    dir = sbxDir(mouse, date);
    path = sprintf('%s%s_%s_crossday-cell-ids.txt', dir.date_mouse, mouse, date);
end

