function out = sbxJobMasterGetJobs(path)
%SBXJOBMASTERGETJOBS Get the list of all jobs
    
    if path(end) ~= '\', path = [path '\']; end

    fs = dir(path);
    if length(fs) < 3
        out = [];
    else
        count = 0;
        out = {};
        for i = 1:length(fs)
            if length(fs(i).name) > 4 && strcmp(fs(i).name(end-3:end), '.mat')
                count = count + 1;
                out{count} = [path fs(i).name];
            end
        end
    end
    
    out = sort(out);
end

