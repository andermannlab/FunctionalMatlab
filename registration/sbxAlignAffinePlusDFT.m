function translation = sbxAlignAffinePlusDFT(mov_path, startframe, nframes, ref, tform, pmt)

    % Parameters -----------------------
    upsample = 100;
    cut_borders = 0.15;
    % ----------------------------------

    % Set PMT to green if dual channel or single channel
    if nargin < 6, pmt = 0; end
    
    % Read in data
    data = sbxReadPMT(mov_path, startframe - 1, nframes, pmt);
    translation = zeros(size(data, 3), 4);
    
    edges = sbxRemoveEdges();
    data = data(edges(3):end-edges(4), edges(1):end-edges(2), :);
    
    % Reduce size for DFT registration
    red = floor(size(data)*cut_borders);
    ref = ref(red(1):end-red(1), red(2):end-red(2));
    
    target_fft = fft2(double(ref));
    blank_affine = [1 0 0; 0 1 0; 0 0 1];
    
    for i = 1:size(data, 3)
        data_affine = imwarp(data(:, :, i), tform{i}, 'OutputView', imref2d(size(data(:, :, i))));
        data_affine = data_affine(red(1):end-red(1), red(2):end-red(2));
        data_fft = fft2(double(data_affine));
        [dftoutput, ~] = dftregistration(target_fft, data_fft, upsample);
        translation(i, :) = dftoutput;
    end
end