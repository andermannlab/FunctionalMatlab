function cellsort = sbxPullSignalsCoreDFT(path, icaguidata, weighted_neuropil)
%UNTITLED12 Summary of this function goes here
%   Detailed explanation goes here

    chunksize = 1000; % Parfor chunking
    
    if nargin < 3, weighted_neuropil = false;

    % Get original file size
    info = sbxInfo(path);
    fsz = info.sz;
    nframes = info.max_idx + 1;

    % Initialize cellsort mask variable and protect against empty masks
    cellsort = icaguidata.icaStructForMovie;
    for i = 1:length(cellsort)
        if isempty(cellsort(i).mask)
            cellsort(i).mask = zeros(size(cellsort(1).mask));
        end
        
        % Edge removal values from remove_edges_mov.m
        cols_remove = 32;
        rows_remove = 10;
        if i == 1
            col_buffer = zeros(size(cellsort(i).mask, 1), cols_remove);
            xsize = size(cellsort(i).mask, 2) + 2*cols_remove;
            row_buffer = zeros(rows_remove, xsize);
        end
        
        % Buffer back in both dimensions and spatially upsample
        cellsort(i).mask = [col_buffer cellsort(i).mask col_buffer];
        cellsort(i).mask = [row_buffer; cellsort(i).mask; row_buffer];
        cellsort(i).mask = imresize(cellsort(i).mask, fsz, 'nearest');
    end
    
    cellsort = get_ROI_cellbody_masks_plus_neuropil(cellsort);

    % Update nROIs to include last ROI which is just neuropil
    nrois = length(cellsort);
    mask = zeros(fsz);
    for i = 1:nrois, mask = mask + i.*(cellsort(i).binmask); end

    nchunks = ceil(nframes/chunksize);
    csignal = cell(1, nchunks);
    cneuropil = cell(1, nchunks);
    
    openParallel();
    for c = 1:nchunks
        data = sbxAlignDFTChunkPath(path, (c-1)*chunksize+1, chunksize);
        data = reshape(data, fsz(1)*fsz(2), size(data, 3));
        
        signals = zeros(size(data, 2), nrois);
        neuropil = zeros(size(data, 2), nrois);
        for j = 1:nrois
            signals(:, j) = mean(data(cellsort(j).binmask == 1, :));
            
            if sum(sum(cellsort(j).neuropil == 1)) > 0
                neuropil(:, j) = median(double(data(cellsort(j).neuropil == 1, :)));
            end
        end
        
        csignal{c} = signals;
        cneuropil{c} = neuropil;
    end
    
    signal = zeros(nframes, nrois);
    neuropil = zeros(nframes, nrois);
    for c = 1:nchunks
        lpos = (c - 1)*chunksize + 1;
        upos = min(c*chunksize, nframes);
        upos = min(upos, lpos + size(csignal{c}, 1) - 1);
        
        signal(lpos:upos, :) = csignal{c};
        neuropil(lpos:upos, :) = cneuropil{c};
    end

	% Neuropil subtraction
    signalsub = (signal - neuropil);
    median_sig = nanmedian(signal, 1);
    signalsub = bsxfun(@plus, signalsub, nanmedian(signal, 1));

    % Now put into cellsort format
    for r = 1:nrois
        cellsort(r).timecourse.raw = signal(:, r)';
        cellsort(r).timecourse.neuropil = neuropil(:, r)';
        try 
            if weighted_neuropil
                % Get weight to scale npil to maximize skewness of subtracted trace
                subfun = @(x) -1*skewness(cellsort(r).timecourse.raw - ...
                    (x*cellsort(r).timecourse.neuropil));
                w = fminsearch(subfun, 1);
                w(w < 0) = 0; % can't be less than 0 or greater than 2
                w(w > 2) = 2;
                cellsort(r).timecourse.subtracted = (cellsort(r).timecourse.raw - ...
                    (w.*cellsort(r).timecourse.neuropil)) + nanmedian(cellsort(r).timecourse.raw);
                cellsort(r).npil_weight = w;
            else
                cellsort(r).timecourse.subtracted = signalsub(:, r)';
                cellsort(r).npil_weight = 1;
            end
        catch err
            cellsort(r).timecourse.subtracted = signalsub(:, r)';
            cellsort(r).npil_weight = 1;
        end
    end
end

