function cellsort = sbxPullSignalsCoreCheckNeuropilCorrelation(cellsort)
% if the neuropil signal and the raw signal are highly correlated then instead of subtracting
% the neuropil and getting no signal - just use the raw
    threshold = 0.99;
    ROI_use_raw = [];
    for i = 1:length(cellsort)
        correlation = corrcoef(cellsort(i).timecourse.raw, cellsort(i).timecourse.neuropil);
        correlation = correlation(1, 2);
        if correlation > threshold
            cellsort(i).timecourse.subtracted = cellsort(i).timecourse.raw;
            ROI_use_raw = [ROI_use_raw i];
        end
    end
    if ~isempty(ROI_use_raw)
        warning(['ROI number ' num2str(ROI_use_raw) ' has parts of ROI in neuropil so just using raw instead of subtracted'])
    end
end