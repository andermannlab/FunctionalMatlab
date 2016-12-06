function out = sbxDates(mouse)
%SBXDATES List all dates of recordings for mouse mouse

    mousedir = sprintf('%s%s', sbxScanbase(), mouse);
    pattern = ['^\d{6}_' mouse '.*'];
    
    %out = {};
    out = [];
    
    fs = dir(mousedir);
    for i=1:length(fs)
        if fs(i).isdir
            if regexp(fs(i).name, pattern)
                %out{length(out)+1} = fs(i).name;
                date = str2num(fs(i).name(1:6));
                if ~isempty(sbxRuns(mouse, date))
                    out(length(out)+1) = date;
                end
            end
        end
    end
    
    out = sort(out);
end

