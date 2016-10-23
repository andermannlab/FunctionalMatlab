function frame = sbxAlignTargetCore(path, pmt, bin)
%SBXALIGNTARGETCORE Aligns an sbx target file given by path. Assumes that
%	the used pmt is 0 or green

    % Parameters --------------------------
    refsize = 500; % How many frames (500)
    upsample = 100; % Upsampling for alignment
    % -------------------------------------

    if nargin < 2, pmt = 0; end
    if nargin < 3, bin = 2; end
    
    % Open first refsize frames of target file
    ref = sbxReadPMT(path, 0, refsize, pmt);
    c = class(ref);
    
    % Get the standard edge removal 
    edges = sbxRemoveEdges();
    ref = ref(edges(3):end-edges(4), edges(1):end-edges(2), :);
    
    % Bin, if necessary
    if bin > 1, ref = binxy(ref, bin); end
    
    % First, unaligned reference
    fref = squeeze(mean(ref, 3));
    
    % Align reference files
    target_fft = fft2(double(fref));
    for i = 1:size(ref, 3)
        data_fft = fft2(double(ref(:, :, i)));
        [~, reg] = dftregistration(target_fft, data_fft, upsample);
        ref(:, :, i) = abs(ifft2(reg));
    end
    
    % Compress the aligned reference files and convert back to original
    % class
    frame = squeeze(mean(ref, 3));
    frame = cast(frame, c);
end

