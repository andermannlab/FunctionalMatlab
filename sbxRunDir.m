function out = sbxRunDir(mouse, date, run)
%SBXRUNDIR Get the path to a run folder, accounting for extra text after
%   the key phrases

    
    if ~isinteger(run) && ~isfloat(run), run = str2num(run); end
    % Prepare the output
    out = [];
    
    % Get the mouse directory
    mousedir = sbxMouseDateDir(mouse, date);
    if isempty(mousedir), return; end
    
    matchstr = sprintf('%s_%s_run%i', date, mouse, run);
    
    % Check if the base path exists
    if exist(sprintf('%s%s', mousedir, matchstr), 'file') > 0
        out = sprintf('%s%s\\', mousedir, matchstr);
        return
    end
    
    % Otherwise, search for a match
    fs = dir(mousedir);
    for i=1:length(fs)
        if fs(i).isdir
            if length(fs(i).name) > length(matchstr)
                if strcmp(fs(i).name(1:length(matchstr)), matchstr)
                    if ~isstrprop(fs(i).name(length(matchstr)+1), 'digit')
                    	out = sprintf('%s%s\\', mousedir, fs(i).name);
                    end
                end
            end
        end
    end
end

