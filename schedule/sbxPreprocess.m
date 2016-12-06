function sbxPreprocess(mouse, date, runs, target, pcs, pmt)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    chunksize = 1000;
    downsample_t = 5;
    downsample_xy = 2;
    
    chunksize = ceil(chunksize/downsample_t)*downsample_t;

    if nargin < 3 || isempty(runs), runs = sbxRuns(mouse, date); end
    if nargin < 4 || isempty(target), target = []; end
    if nargin < 5 || isempty(pcs), pcs = []; end
    if nargin < 6 || isempty(pmt), pmt = 0; end

    sbxAlignAffine(mouse, date, runs, target, pmt);
    sbxAlignAffineTest(mouse, date, runs, pmt);
    
    % Get the ICA GUI data (icaguidata)
    edges = sbxRemoveEdges();
    comb = cell(1, length(runs));
    totallen = 0;
    openParallel();
    for r = 1:length(runs)
        path = sbxPath(mouse, date, runs(r), 'sbx');
        
        %if ~isempty(pcs), sbxPCACleanNoDS(path, pcs, pmt); end
        
        info = sbxInfo(path);
        nframes = info.max_idx + 1;
        nchunks = ceil(nframes/chunksize);
        mov = cell(1, nchunks);
        
        parfor c = 1:nchunks
            frames = sbxAlignAffineChunk(mouse, date, runs(r), ...
                (c-1)*chunksize + 1, chunksize, pmt);
            frames = frames(edges(3):end-edges(4), edges(1):end-edges(2), :);
            frames = binxy(frames, downsample_xy);
            mov{c} = bint(frames, downsample_t);
        end
        
        comb{r} = mov;
        totallen = totallen + floor(nframes/downsample_t);
    end
    
    out = zeros(size(comb{1}{1}, 1), size(comb{1}{1}, 2), totallen);
    f = 0;
    for r = 1:length(runs)
        for c = 1:length(comb{r})
            out(:, :, f+1:f+size(comb{r}{c}, 3)) = comb{r}{c};
            f = f + size(comb{r}{c}, 3);
        end
    end
    
    [root, file, ~] = fileparts(path);
    sbxPreprocessICAGUIData([root '\' file], out);
end

