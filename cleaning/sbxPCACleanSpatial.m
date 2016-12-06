function sbxPCACleanSpatial(path, pcs, pmt)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
    
    % ------------------------------------
    % Parameters
    downsample_xy = 2;
    chunksize = 1000; % Parfor chunking
    % ------------------------------------
    
    % Make sure that scaling works correctly and correct inputs
    if nargin < 2, pcs = 4000; end
    if nargin < 3, pmt = 0; end
    
    % Save the edge sizes for removal
    edges = sbxRemoveEdges();
    
    % Open whole file and bin
    info = sbxInfo(path);
    nframes = info.max_idx + 1;
    
    tic;
    nchunks = ceil(nframes/chunksize);
    cout = cell(1, nchunks);
    openParallel();

    parfor c = 1:nchunks
        chunk = sbxAlignAffineChunkPath(path, (c-1)*chunksize+1, chunksize, pmt);
        chunk = chunk(edges(3):end-edges(4), edges(1):end-edges(2), :);
        cout{c} = binxy(chunk, downsample_xy);
    end

    f = 0;
    mov = zeros(size(cout{1}, 1), size(cout{1}, 2), nframes);
    for c = 1:nchunks
        mov(:, :, f+1:f+size(cout{c}, 3)) = cout{c};
        f = f + size(cout{c}, 3);
    end
    clearvars('cout');
    
%    mov = double(sbxReadPMT([path(1:end-4) '_aligned.sbx']));
    [y, x, nframes] = size(mov);
    mov = reshape(mov, y*x, nframes);
    
    % Run PCA cleaning and reduce principal components immediately
    % Added
    movwmean = mean(mov, 2);
    mov_whitened = mov - movwmean*ones(1, nframes);
    mov_whitened = double(mov_whitened);
    disp('Actual cleaning');
    [eigenvectors, ~] = eig(mov_whitened'*mov_whitened, 'vector');
    eigenvectors = mov_whitened*eigenvectors;

    % Select which principal components to use
    eigenvectors = eigenvectors(:, end-pcs+1:end);
    eigenvectors = eigenvectors*10^(-3); % -6 this is just for the convenience of normalization
    for i = 1:pcs
        sq = (eigenvectors(:, i)'*eigenvectors(:, i))^0.5;
        eigenvectors(:, i) = eigenvectors(:, i)/sq;
    end

    matrix_weight = eigenvectors'*mov_whitened;
    clearvars('mov_whitened');
    out = eigenvectors*matrix_weight + movwmean*ones(1, nframes);
    clearvars('eigenvectors', 'matrix_weight');
    out = reshape(out, y, x, nframes);
    
    % Rescale to full size
    out = uint16(imresize(out, downsample_xy));

    % Convert back to the original size
    sz = size(out);
    fsout = zeros(info.sz(1), info.sz(2), sz(3), 'uint16');
    fsout(edges(3):edges(3)+sz(1)-1, edges(1):edges(1)+sz(2)-1, :) = out;
    clearvars('out');
    
    timeinsec = toc;
    disp(sprintf('Cleaning took %f minutes', timeinsec/60));

    sbxWrite([path(1:end-4) '_clean'], fsout, info);
end

