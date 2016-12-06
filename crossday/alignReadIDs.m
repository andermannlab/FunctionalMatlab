function ids = alignReadIDs(path)
%ALIGNREADIDS Read IDs from the specified path, turning the IDs into
%   integers for easier analysis.

    ids = [];
    
    fp = fopen(path, 'r');
    ids = fscanf(fp, '%9i');
    fclose(fp);
end

