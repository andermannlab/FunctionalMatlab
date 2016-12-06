function [masks, binmasks, traces] = crossdayMasksTraces(mouse, date, rois)
%UNTITLED16 Summary of this function goes here
%   Detailed explanation goes here

    % Load the first file to get the masks and the size of a trace
    runs = sbxRuns(mouse, date);
    sig = sbxLoad(mouse, date, runs(1), 'signals');
    if nargin < 3 || isempty(rois), rois = 1:length(sig.cellsort)-1; end
    ncells = length(rois);
    
    % Compress the trace for faster loading
    [~, tr1] = simplifyTrace(sig.cellsort(rois(1)).timecourse.dff_axon);
    
    % Initialize masks and traces, ncells is the last row
    masks = zeros(size(sig.cellsort(1).mask, 1), ...
        size(sig.cellsort(1).mask, 2), ncells);
    binmasks = logical(zeros(size(sig.cellsort(1).binmask, 1), ...
        size(sig.cellsort(1).binmask, 2), ncells));
    traces = zeros(length(tr1)*length(runs), ncells);
    
    % Copy in the masks and the traces
    for j = 1:ncells
        i = rois(j);
        masks(:, :, j) = sig.cellsort(i).mask;
        binmasks(:, :, j) = sig.cellsort(i).binmask;
        [~, traces(1:length(tr1), j)] = simplifyTrace(sig.cellsort(i).timecourse.dff_axon);
    end
    
    % Add in the rest of the traces
    for j = 2:length(runs)
        pos = (j - 1)*length(tr1) + 1;
        epos = pos + length(tr1) - 1;
        try
            sig = sbxLoad(mouse, date, runs(j), 'simpcell');
            for i = 1:ncells
                k = rois(i);
                [~, traces(pos:epos, i)] = simplifyTrace(sig.dff(k, :));
            end
        catch Exception
            sig = sbxLoad(mouse, date, runs(j), 'signals');
            if ~isempty(sig)
                for i = 1:ncells
                    k = rois(i);
                    [~, traces(pos:epos, i)] = simplifyTrace(sig.cellsort(k).timecourse.dff_axon);
                end
            end
        end
    end

end

