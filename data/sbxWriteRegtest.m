function sbxWriteRegtest(path)
%SBXWRITEREGTEST writes a tiff with the first and last 500 frames of an sbx
%   movie to check registration and image

    % Check if the file has already been written
    savename = sprintf('%s_first_last_500_frames.tif', path(1:end - 4));
    if exist(savename), return; end
    
    % Find the total number of frames from info
    inf = sbxInfo(path);
    
    % Read the beginning and end
    first500 = sbxReadReg(path, 0, 500);
    last500 = sbxReadReg(path, inf.max_idx + 1 - 500, 500);
    
    % Combine and save
    combined = cat(3, first500, last500);
    writetiff(combined, savename, 'uint16');
end

