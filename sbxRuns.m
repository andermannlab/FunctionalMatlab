function runs = sbxRuns(mouse, date)
%SBXRUNS List all runs in a folder
    
    % Initialize the base directory and scan directory
    base = 'D:\twophoton_data\2photon\scan\';
    searchdir = sprintf('%s%s\\%s_%s\\', base, mouse, date, mouse);
    matchstr = sprintf('%s_%s_run', date, mouse);
    runs = [];
    
    % Search for all directory titles that match a run
    fs = dir(searchdir);
    for i=1:length(fs)
        if fs(i).isdir
            if length(fs(i).name) > length(matchstr)
                if strcmp(fs(i).name(1:length(matchstr)), matchstr)
                    runs = [runs str2num(fs(i).name(length(matchstr) + 1:end))];
                end
            end
        end
    end
end

