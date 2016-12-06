function out = sbxReadTiff(dir_path)
%SBXREADTIFF Reads a directory of tiffs, specified by dir_path, in order,
%   and makes them available for use in other sbx functions

    if exist(dir_path) ~= 7, out = []; return; end
    if dir_path(end) ~= '\', dir_path = [dir_path '\']; end

    % Get a list of tiff files in the directory
    count = 0;
    fs = {};
    pathfiles = dir(dir_path);
    for i = 1:length(pathfiles)
        if length(pathfiles(i).name) > 4 && strcmp(pathfiles(i).name(end-3:end), '.tif')
            count = count + 1;
            fs{count} = [dir_path pathfiles(i).name];
        end
    end
    fs = sort(fs);
    
    % Read in the tiff files
    len = 0;
    parts = cell(1, length(fs));
    for i = 1:length(fs)
        parts{i} = readtiff(fs{i});
        len = len + size(parts{i}, 3);
    end

    % Collect into a single file
    pos = 0;
    out = zeros(size(parts{1}, 1), size(parts{1}, 2), len, 'uint16');
    for i = 1:length(parts)
        out(:, :, pos+1:pos+size(parts{i}, 3)) = uint16(parts{i});
        pos = pos + size(parts{i}, 3);
    end
end

