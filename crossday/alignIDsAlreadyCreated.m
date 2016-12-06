function out = alignIDsAlreadyCreated(mouse)
%ALIGNIDSALREADYCREATED Checks if an ID file has been created for any of
%   the dates of the mouse. If so, it will try not to make a new ID file.
%   This is so that you don't have two IDs assigned to the same ROI.

    out = 0;
    dates = sbxDates(mouse);
    
    for i = 1:length(dates)
        if exist(alignIDPath(mouse, dates(i)), 'file')
            out = 1;
        end
    end
end

