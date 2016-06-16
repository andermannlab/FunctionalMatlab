function im = sbxReadReg(path, k, N, pmt, optolevel)
%SBXREADREG Read an image and register. Exactly the same as sbxReadPMT
%   except that it immediately registers it with whole-pixel registration
%   afterwards.

    % Read in the info file, but avoid using global variables
    inf = sbxInfo(path);

    % Make sure to set N and pmt if unset
    if nargin < 3
        N = 1;
    end
    if nargin < 4
        pmt = 0;
    end

    % Read in the image file, passing along the variables
    im = sbxReadPMT(path, k, N, pmt);
    
    % Get the alignment matrix and apply a circular shift
    alignment_matrix = inf.aligned.T;
    for i = 1:size(im, 3)
        pos = i + k;
        im(:, :, i) = circshift(im(:, :, i), alignment_matrix(pos, :));
    end
end

