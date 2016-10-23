function runs = sbxRuns(mouse, date)
%SBXRUNS List all runs in a folder
    
    % Initialize the base directory and scan directory
    % Get the base directory from sbxDir.
    
    searchdir = sbxMouseDateDir(mouse, date);
    matchstr = sprintf('%s_%s_run', date, mouse);
    runs = [];
    
    % Search for all directory titles that match a run
    fs = dir(searchdir);
    for i=1:length(fs)
        if fs(i).isdir
            if length(fs(i).name) > length(matchstr)
                if strcmp(fs(i).name(1:length(matchstr)), matchstr)
                    runnum = [];
                    j = length(matchstr) + 1;
                    while j <= length(fs(i).name) && isstrprop(fs(i).name(j), 'digit')
                        runnum = [runnum fs(i).name(j)];
                        j = j + 1;
                    end
                    runs = [runs str2num(runnum)];
                end
            end
        end
    end
    runs = sort(runs);
end

