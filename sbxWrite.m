function sbxWrite(path, data, info, force)
%SBXWRITE Writes an sbx file and the appropriate info file

    % NOTE: Pass data of type [width height], [width height time], [width
    % height time channel] or [channel width height time]. We will guess,
    % but we may make mistakes otherwise

    % Make sure that filename is formatted correctly
    if ~strcmp(path(end-3:end), '.sbx'), path = [path '.sbx']; end
    infopath = [path(1:end - 4) '.mat'];
    
    if nargin < 4, force = false; end

    % Handle channels
    dsizes = size(data);
    if length(dsizes) == 2
        data = reshape(data, [1 dsizes 1]);
    elseif length(dsizes) == 3 && dsizes(1) < 3
        data = reshape(data, [dsizes 1]);
    elseif length(dsizes) == 3
        data = reshape(data, [1 dsizes]);
    elseif dsizes(4) < 3 && dsizes(1) > 2 && dsizes(2) > 2 && dsizes(3) > 2
        data = permute(data, [4 1 2 3]);
    elseif dsizes(3) < 3 && dsizes(1) > 2 && dsizes(2) > 2 && dsizes(4) > 2
        data = permute(data, [3 1 2 4]);
    end
    dsizes = size(data); 
    
    % Set the info correctly, if necessary
    info.max_idx = dsizes(4) - 1;
    info.recordsPerBuffer = dsizes(2);
    info.sz = [dsizes(2), dsizes(3)];
    info.channels = 2;
    if dsizes(1) == 2, info.channels = 1; end
    
    % To match scanbox, we will invert rows and columns
    data = permute(data, [1 3 2 4]);
    data = reshape(data, [1 prod(dsizes)]);
    
    % Make sure that it is uint16, otherwise scale
    if ~isa(data, 'uint16')
        mn = min(data);
        mx = max(data);
        if mn < 0 || mn > 65535 || mx < 2 || mx > 65535
            data = data - mn;
            multiplier = 65535.0/(mx - mn);
            data = data*multiplier;
            data = uint16(data);
            disp('WARNING: Scaling data and converting to uint16');
        else
            data = uint16(data);
        end
    end
    
    % Finally, invert (for unknown reasons)
    data = intmax('uint16') - data;
    
    % Open file
    if exist(path, 'file') > 0 && ~force
        disp('ERROR: File already exists');
        return
    end
    
    % Save the info file and primary file
    save(infopath, 'info');
    
    fo = fopen(path, 'w');
    fwrite(fo, data, 'uint16');
    fclose(fo);

end

