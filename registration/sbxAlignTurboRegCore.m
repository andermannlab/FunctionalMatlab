function affine_transforms = sbxAlignTurboRegCore(mov_path, startframe, nframes, target_mov_path, binframes, pmt, dfttarget, highpass)
%SBXALIGNTURBOREGCORE aligns a file (given by path) using ImageJ's TurboReg
%   NOTE: hardcoded path to ImageJ.

    % Hardcoded path to ImageJ
    imageJ_path = 'C:\Program Files (x86)\ImageJ_OLD\ImageJ.exe';
    
    % Turn off default binning in time
    if nargin < 5, binframes = 1; end
    % Set the default PMT channel to green
    if nargin < 6, pmt = 0; end
    % Set default highpass filter to true
    if nargin < 8, highpass = true; end
    
    % Initialize output and read frames
    affine_transforms = cell(1, nframes);
    data = sbxReadPMT(mov_path, startframe - 1, nframes, pmt);
    
    % Get the standard edge removal and bin by 2
    edges = sbxRemoveEdges();
    data = data(edges(3):end-edges(4), edges(1):end-edges(2), :);
    data = binxy(data, 2);
    
    % If desired, align using dft to a target
    if ~isempty(dfttarget)
        c = class(data);
        upsample = 100;
        target_fft = fft2(double(dfttarget));
        for i = 1:size(data, 3)
            data_fft = fft2(double(data(:, :, i)));
            [~, reg] = dftregistration(target_fft, data_fft, upsample);
            data(:, :, i) = abs(ifft2(reg));
        end
    end
    
    % Bin if necessary
    if binframes > 1, data = bint(data, binframes); end
    [y, x, ~] = size(data);
    
    % Get the save location
    temp_dir = fileparts(target_mov_path);
    [~, temp_name, ~] = fileparts(mov_path);
    temp_name = sprintf('%s\\%s_%i_', temp_dir, temp_name, startframe);
    macro_temp_path = [temp_name 'macro.ijm'];
    output_temp_path = [temp_name 'output.txt'];
    finished_temp_path = [temp_name 'done.txt'];
    mov_temp_path = [temp_name 'temp.tif'];
    
    % Delete the finishing marker if necessary
    if exist(finished_temp_path), delete(finished_temp_path); end
    
    % Write the tiff of the images to be registered
    writetiff(data, mov_temp_path, class(data));
    
    % Get the sizes of the files
    szstr = sprintf('0 0 %i %i ', x - 1, y - 1);
    % Estimate targets the way turboreg does
    targets = [0.5*x 0.15*y 0.5*x 0.15*y 0.15*x 0.85*y 0.15*x 0.85*y ...
        0.85*x 0.85*y 0.85*x 0.85*y];
    targets = round(targets);
    targetstr = sprintf('%i ', targets);
    
    % Create the text for the ImageJ macro
    alignstr = sprintf('"-align -window data %s -window ref %s -affine %s -hideOutput"', ...
            szstr, szstr, targetstr);
    macro_text = ['setBatchMode(true); ' ...
        'fo = File.open("' output_temp_path '"); ' ...
        'open("' target_mov_path '"); ' ...
        'rename("ref"); '];
    
    % Subtract a blurred image if highpass is desired
    if highpass
        macro_text = [macro_text 'run("Duplicate...", "title=refg"); ' ...
        'run("Gaussian Blur...", "sigma=5"); ' ...
        'imageCalculator("Subtract create 32-bit", "ref", "refg"); ' ...
        'selectWindow("ref"); ' ...
        'close(); ' ...
        'selectWindow("refg"); ' ...
        'close(); ' ...
        'selectWindow("Result of ref"); ' ...
        'rename("ref"); '];
    end
        
    macro_text = [macro_text 'open("' mov_temp_path '"); ' ...
        'rename("stack"); ' ...
        'for (n = 1; n <= nSlices; n++) { ' ...
        ' 	selectWindow("stack"); ' ...
        ' 	setSlice(n); ' ...
        ' 	run("Duplicate...", "title=data"); '];
        
    if highpass
        macro_text = [macro_text 'run("Duplicate...", "title=datag"); ' ...
        'run("Gaussian Blur...", "sigma=5"); ' ...
        'imageCalculator("Subtract create 32-bit", "data", "datag"); ' ...
        'selectWindow("data"); ' ...
        'close(); ' ...
        'selectWindow("datag"); ' ...
        'close(); ' ...
        'selectWindow("Result of data"); ' ...
        'rename("data"); '];
    end
        
    macro_text = [macro_text ' 	run("TurboReg ", ' alignstr '); ' ...
        ' 	print(fo, getResult("sourceX", 0) + " " + getResult("sourceX", 1) ' ...
        '+ " " + getResult("sourceX", 2) + " " + getResult("sourceY", 0) + ' ...
        '" " + getResult("sourceY", 1) + " " + getResult("sourceY", 2)); ' ...
        ' 	selectWindow("data"); ' ...
        ' 	close(); ' ...
        '} ' ...
        'File.close(fo); ' ...
        'selectWindow("stack"); ' ...
        'close(); ' ...
        'selectWindow("ref"); ' ...
        'close(); ' ...
        'fp = File.open("' finished_temp_path '"); ' ...
        'print(fp, "a"); ' ...
        'File.close(fp); ' ...
        'setBatchMode(false); ' ...
        'eval("script", "System.exit(0);"); '];
    
    macro_text = strrep(macro_text, '\', '\\');
        
    % Save macro
    fo = fopen(macro_temp_path, 'wt');
    fprintf(fo, '%s', macro_text);
    fclose(fo);
    
    % Run Turboreg
    while ~exist(macro_temp_path), pause(1); end
    pause(5);
    status = system(sprintf('"%s" --headless -macro %s', imageJ_path, macro_temp_path));
    
    % Wait until the "done" file has been created and then clean up
    while ~exist(finished_temp_path), pause(1); end
    delete(macro_temp_path);
    delete(mov_temp_path);
    delete(finished_temp_path);
    
    % Read the output of the macro
    fo = fopen(output_temp_path, 'r');
    tform = fscanf(fo, '%f %f %f %f %f %f')';
    fclose(fo);
    delete(output_temp_path);
    tform = reshape(tform, 6, size(tform, 2)/6);
    
    % Convert to a transformation
    targetgeotransform = targets([3 4 7 8 11 12]);
    targetgeotransform = reshape(targetgeotransform, 2, 3)';
    
    midbin = floor(binframes/2);
    % Iterate over all times
    for i = 1:size(data, 3)
        ftform = reshape(tform(:, i), 3, 2);
        affine_transforms{i*binframes-midbin} = fitgeotrans(ftform, targetgeotransform, 'affine');
        %tmp2 = imtransform(tmp,tformA,'bicubic','XData',[1 size(tmp,1)],'YData',[1 size(tmp,2)],'size',size(tmp),'XYscale',1);
    end
end

