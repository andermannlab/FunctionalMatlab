function sbxPCAIdentifyPCs(mouse, date, runs, pcs, pmt)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
    
    % ------------------------------------
    % Parameters
    downsample_t = 4;
    downsample_xy = 2;
    chunksize = 1000; % Parfor chunking
    % ------------------------------------
    
    % Make sure that scaling works correctly and correct inputs
    if nargin < 3, runs = sbxRuns(mouse, date); end
    if nargin < 4, pcs = 2000; end
    if nargin < 5, pmt = 0; end
    
    chunksize = ceil(chunksize/downsample_t)*downsample_t;
    if length(runs) > 1 && length(pcs) == 1, pcs = zeros(1, length(runs)) + pcs; end
    
    % Save the edge sizes for removal
    edges = sbxRemoveEdges();
    
    for r = 1:length(runs)
        % Open whole file and bin
        path = sbxPath(mouse, date, runs(r), 'sbx');
        info = sbxInfo(path);
        nframes = info.max_idx + 1;
        
        nchunks = ceil(nframes/chunksize);
        cout = cell(1, nchunks);
        openParallel();

        parfor c = 1:nchunks
            chunk = sbxAlignAffineChunk(mouse, date, runs(r), (c-1)*chunksize+1, chunksize, pmt);
            chunk = chunk(edges(3):end-edges(4), edges(1):end-edges(2), :);
            cout{c} = binxy(chunk, downsample_xy);
        end
        
        f = 0;
        mov_unbin = zeros(size(cout{1}, 1), size(cout{1}, 2), nframes);
        for c = 1:nchunks
            mov_unbin(:, :, f+1:f+size(cout{c}, 3)) = cout{c};
            f = f + size(cout{c}, 3);
        end
        clearvars('cout');
        
        % Get the mean and max for PCA cleaning
        mov_bin = bint(mov_unbin, downsample_t);
        framemean = squeeze(mean(mean(mov_unbin, 1), 2))';
        framemax = squeeze(max(max(max(mov_unbin))));
        
        % Generate a TIFF containing eigenvalues
        [y, x, bframes] = size(mov_bin);
        mov_bin = reshape(mov_bin, y*x, bframes);
        framemeansbinned = mean(mov_bin, 1);

        % Run PCA cleaning and reduce principal components immediately
        [eigenvectors, ~, eigenvalues, ~, ~] = pca(mov_bin);
        npcs = min(bframes, 8000);
        eigenvectors = eigenvectors(:, 1:npcs);
        eigenvalues = eigenvalues(1:npcs);

        % Generate the spatial weights of PC
        Sinv = inv(diag(eigenvalues));
        meansubtracted = mov_bin - ones(y*x, 1)*framemeansbinned;
        spatialweights = meansubtracted*eigenvectors*Sinv;

        % Write a tiff with the spatial weights for display
        last_pc_above_noise = 400;
        displayweights = reshape(spatialweights, y, x ,npcs);
        displayweights(1:15, 1:15, last_pc_above_noise+1) = ...
            max(max(displayweights(:, :, last_pc_above_noise+1)));
        
        dirs = sbxDir(mouse, date, runs(r));
        dir = dirs.runs{1};
        writetiff(displayweights, [dir.base '_PCs']);
        clearvars('displayweights', 'spatialweights', 'mov_bin', 'Sinv');
        
        % Select which principal components to use
        usepcs = 1:pcs(r);
        
        % Upsample eigenvectors
        eigenvectors = eigenvectors(:, usepcs);
        upsampled_eigenvectors = nan(bframes*downsample_t, size(eigenvectors, 2));
        for i = 1:size(eigenvectors, 2)
            upsampled_eigenvectors(:, i) = interp1((1:downsample_t:bframes*downsample_t)', ...
                eigenvectors(:, i), 1:bframes*downsample_t');
        end
        eigenvectors = upsampled_eigenvectors;
        
        % Remove nans
        for i = 1:size(eigenvectors, 2)
            eigenvectors(end-downsample_t+1:end, i) = eigenvectors(end-downsample_t+1, i);
        end
        
        mov_unbin = reshape(mov_unbin, y*x, nframes);
        mov_unbin = mov_unbin - ones(y*x, 1)*framemean;
        mov_unbin = eigenvectors'*mov_unbin';
        cleaned = (eigenvectors*mov_unbin) + repmat(framemean', 1, y*x);
        clearvars('mov_unbin');

        cleaned = reshape(cleaned, nframes, y, x);
        out = zeros(y, x, nframes);
        for i = 1:nframes
            A = squeeze(cleaned(i, :, :));
            out(:, :, i) = A - min(A(:));
        end
        clearvars('cleaned');

        % Account for differences in maxima in cleaned and original
        max_cleaned = max(max(max(out)));
        rescale_factor = framemax/max_cleaned;
        out = uint16(imresize(out.*rescale_factor, downsample_xy));

        sbxWrite([path 'clean'], out, info);
    end
end

