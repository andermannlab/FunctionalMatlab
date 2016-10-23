function out = sbxAlignAffineChunkPath(path, startframe, nframes, pmt)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    if nargin < 2, startframe = 1; end
    if nargin < 4, pmt = 0; end

    afalign = [path(1:end-4) '.alignaffine'];
    
    if ~exist(afalign, 'file'), out = []; return; end
    
    alignment = load(afalign, '-mat');

    info = sbxInfo(path);
    ntotalframes = info.max_idx + 1;
    if nargin < 3, nframes = ntotalframes - startframe + 1; end
    if startframe + nframes > ntotalframes
        nframes = ntotalframes - startframe + 1;
    end

    pos = startframe;
    upos = startframe - 1 + nframes;
    tform = alignment.tform(pos:upos);
    trans = alignment.trans(pos:upos, :);

    out = sbxAlignAffineApplyAffineDFT(path, startframe - 1, nframes, ...
            tform, trans, pmt);
end

