function bwmask = sbxPupilCoreSearchAlternates(mouse, date)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    bwmask = [];
    runs = sbxRuns(mouse, date);
    for run = runs
        if isempty(bwmask)
            path = sbxPath(mouse, date, run, 'pmask');
            if ~isempty(path)
                bwmask = load(path, '-mat');
                bwmask = bwmask.bwmask;
            end
        end
    end
end

