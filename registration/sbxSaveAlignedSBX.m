function sbxSaveAlignedSBX(path, pmt)
%SBXSAVEALIGNEDSBX Save an aligned copy of the sbx file so that future
%   reading and writing is dramatically sped up. Saved as path_reg.sbx

    if nargin < 2, pmt = 0; end

    chunksize = 1000; % Parfor chunking
    
    % Get original file size
    afalign = [path(1:end-4) '.alignaffine'];
    spath = sprintf('%s_reg-%i.sbxreg', path(1:end-4), pmt);
    
    if exist(spath, 'file'), return; end
    
    alignment = load(afalign, '-mat');
    info = sbxInfo(path);
    nframes = info.max_idx + 1;

    nchunks = ceil(nframes/chunksize);
    tform = cell(1, nchunks);
    trans = cell(1, nchunks);
    outchunk = cell(1, nchunks);

    for c = 1:nchunks
        pos = (c - 1)*chunksize + 1;
        upos = min(c*chunksize, nframes);
        tform{c} = alignment.tform(pos:upos);
        trans{c} = alignment.trans(pos:upos, :);
    end

    % Get the current parallel pool or initailize
    openParallel();

    parfor c = 1:nchunks
        pos = (c - 1)*chunksize + 1;
        outchunk{c} = sbxAlignAffineApplyAffineDFT(path, pos, chunksize, ...
            tform{c}, trans{c}, pmt);
    end

    out = zeros(info.sz(1), info.sz(2), nframes, 'uint16');
    for c = 1:nchunks
        pos = (c - 1)*chunksize + 1;
        upos = min(c*chunksize, nframes);
        out(:, :, pos:upos) = outchunk{c};
    end
    
    sbxWrite(spath, out, info, false, true);
end

