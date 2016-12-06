function out = sbxMouseDateDir(mouse, date)
%SBXMOUSEDATEDIR Gets the directory of the mouse and date, accounting for 
%   the fact that you may have added extra text

    scanbase = sbxScanbase();
    
    % Prepare the output
    out = [];
    
    % Get the mouse directory
    mousedir = sprintf('%s%s', scanbase, mouse);
    matchstr = sprintf('%s_%s', date, mouse);
    
    if exist(sprintf('%s\\%s', mousedir, matchstr), 'file') > 0
        out = sprintf('%s\\%s\\', mousedir, matchstr);
        return
    end
    
    fs = dir(mousedir);
    for i=1:length(fs)
        if fs(i).isdir
            if length(fs(i).name) > length(matchstr)
                if strcmp(fs(i).name(1:length(matchstr)), matchstr)
                    out = sprintf('%s\\%s\\', mousedir, fs(i).name);
                end
            end
        end
    end
end

