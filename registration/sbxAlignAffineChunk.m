function out = sbxAlignAffineChunk(mouse, date, run, startframe, nframes, pmt)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    if nargin < 4, startframe = 1; end
    if nargin < 6, pmt = 0; end

    path = sbxPath(mouse, date, run, 'sbx');
    afalign = [path(1:end-4) '.alignaffine'];
    
    if ~exist(afalign, 'file'), sbxAlignAffine(mouse, date, run); end
    
    alignment = load(afalign, '-mat');

    info = sbxInfo(path);
    ntotalframes = info.max_idx + 1;
    if nargin < 5, nframes = ntotalframes - startframe + 1; end
    if startframe + nframes > ntotalframes
        nframes = ntotalframes - startframe + 1;
    end

    pos = startframe;
    upos = startframe - 1 + nframes;
    tform = alignment.tform(pos:upos);
    trans = alignment.trans(pos:upos, :);

    out = sbxAlignAffineApplyAffineDFT(path, startframe, nframes, ...
            tform, trans, pmt);
end

