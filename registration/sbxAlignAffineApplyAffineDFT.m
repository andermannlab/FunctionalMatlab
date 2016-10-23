function data = sbxAlignAffineApplyAffineDFT(path, startframe, nframes, tform, dft, pmt, removeedges)
%SBXALIGNAFFINEAPPLYAFFINEDFT Applies a transform, tform, and a dft
%   translation, dft, to a set of frames begining with startframe. NOTE:
%   startframe is 1-index unlike sbxReadPMT.
%   Input:
%       path - path to .sbx file, .sbx automatically appended if not there
%       startframe - first frame to read, 1-indexed
%       nframes - number of frames to read
%       tform - a cell array of affine2d transforms to apply first
%       dft - a vector of size(nframes, 4) of dft registration to apply
%       pmt - which color to read, 0 if only one color, 1 if two colors
%           and red
%       [removeedges] - remove the edges before returning, T/F
%   Output:
%       data - an array of size(height, width, min(nframes, max possible))
%           of data that has been registered with affine and dft transforms

    if nargin < 7, removeedges = false; end

    data = sbxReadPMT(path, startframe - 1, nframes, pmt);
    c = class(data);
    
    if removeedges
        % Get the standard edge removal and bin by 2
        edges = sbxRemoveEdges();
        data = data(edges(3):end-edges(4), edges(1):end-edges(2), :);
    end
    
    [nr, nc] = size(fft2(double(data(:, :, 1))));
    Nr = ifftshift([-fix(nr/2):ceil(nr/2)-1]);
    Nc = ifftshift([-fix(nc/2):ceil(nc/2)-1]);
    [Nc, Nr] = meshgrid(Nc, Nr);
    
    for j = 1:size(data, 3)
        data(:, :, j) = imwarp(data(:, :, j), tform{j}, 'OutputView', imref2d(size(data(:, :, j))));
        
        row_shift = dft(j, 3);
        col_shift = dft(j, 4);
        diffphase = dft(j, 2);
        
        fftslice = fft2(double(data(:, :, j)));
        frame = fftslice.*exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
       	frame = frame*exp(1i*diffphase);
        data(:, :, j) = cast(abs(ifft2(frame)), c);   
    end
end

