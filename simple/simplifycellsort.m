function simplifycellsort(mouse, date, run, saveraw, overwrite)
%SIMPLIFYCELLSORT Decrease the size of the cellsort file so that it may be
% copied to a home computer and read in easily.
    
    % Set optional arguments
    if nargin < 4, saveraw = false; end
    if nargin < 5, overwrite = false; end

    % Get the path to cellsort
    dirsf = sbxDir(mouse, date, run);
    dirs = dirsf.runs{1};
    params = get_params_variable();
    
    % Make the simpcell path and check if it exists if necessary
    spath = sprintf('%s\\%s_%s_%03i.simpcell', dirsf.date_mouse, mouse, date, run);
    if ~overwrite && exist(spath), return; end
    
    % Load cellsort file
    gd = load([dirs.path '\' dirs.sbx_name '.signals'], '-mat'); 
    
    % Load info file
    infopath = strrep(dirs.sbx, '.sbx', '.mat');
    info = load(infopath, '-mat');
    framerate = 30.98;
    if info.info.scanmode == 1
        framerate = 15.49;
    end
    
    % Prep the output
    dff = zeros(length(gd.cellsort) - 1, length(gd.cellsort(1).timecourse.dff_axon));
    f = zeros(length(gd.cellsort) - 1, length(gd.cellsort(1).timecourse.raw));
    centroid = zeros(length(gd.cellsort) - 1, 2);
    
   % Load the rotary encoder running data, if possible
    if ~isempty(dirs.quad)
        quadfile = load(dirs.quad);
        running = quadfile.quad_data;
    else
        running = [];
    end
    
    % Prep secondary output
    dff_noise = zeros(length(gd.cellsort), 1);
    dff_sigma = zeros(length(gd.cellsort), 1);
    edges = cell(length(gd.cellsort), 1);
    
    % Copy from cellsort
    for i = 1:length(gd.cellsort) - 1
        dff(i, :) = gd.cellsort(i).timecourse.dff_axon;
        raw(i, :) = gd.cellsort(i).timecourse.raw;
        centroid(i, 1) = gd.cellsort(i).centroid.x;
        centroid(i, 2) = gd.cellsort(i).centroid.y;
        
        % Find the edges of the cell
        e = edge(gd.cellsort(i).binmask, 'canny');
        [xs, ys] = find(e > 0);
        edges{i} = zeros(length(xs), 2, 'uint16');
        edges{i}(:, 1) = xs;
        edges{i}(:, 2) = ys;
        
        if sum(dff(i, :)) == 0
            fprintf('WARNING: Cell %i has a dff of all zeros')
        end
        
        % Occasionally, fitting the noise fails. Catch that.
        try
            [noise_, ~, sigma_] = dffnoise(gd.cellsort(i).timecourse.dff_axon);
        catch ME
            fprintf('Warning: dffnoise could not be determined due to problems with least-square fitting for cell %i\n', i);
            noise_ = -1;
            sigma_ = -1;
        end
        
        dff_noise(i, 1) = noise_;
        dff_sigma(i, 1) = sigma_;
    end
    
    % Calculate the maxes for future scaling
    raw_max = max(raw, [], 2);
    dff_max = max(dff, [], 2);
    
    % Calculate the values for dffsnr
    dff_median = median(dff, 2);
    % Make sure, if you want to calculate the correct values used by dffsnr
    % that you subtract the median and divide by THE MAX MINUS THE MEDIANss
    
    % Calculate the deconvolved DFF or load if already calculated
    if overwrite || ~exist([dirs.path '\' dirs.sbx_name '.decon'])
        display('Deconvolving signals...')
        
        decon = calc_constrained_foopsi(dff);
        deconvolved = decon.deconvInSpikes;

        save([dirs.path '\' dirs.sbx_name '.decon'], 'deconvolved');
    else
        decon = load([dirs.path '\' dirs.sbx_name '.decon'], '-mat');
        deconvolved = decon.deconvolved;
    end
    
    % Get the distance moved determined from registration
    brainmotion = registrationMovement(mouse, date, run);
    
    % Get the onsets from sbxOnsets
    if isempty(dirs.ml)
        display(sprintf('No stimuli found for %s %s run %i', mouse, date, run));
        ons = sbxLicking(mouse, date, run);
        licking = ons.licking;
        if saveraw
            save(spath, 'dff', 'raw', 'centroid', 'licking', 'brainmotion', 'raw_max', 'dff_max', 'dff_median', 'dff_noise', 'dff_sigma', 'deconvolved', 'running', 'framerate', 'edges');
        else
            save(spath, 'dff', 'centroid', 'licking', 'brainmotion', 'raw_max', 'dff_max', 'dff_median', 'dff_noise', 'dff_sigma', 'deconvolved', 'running', 'framerate', 'edges');
        end
    else
        ons = sbxOnsets(mouse, date, run);
        
        onsets = ons.onsets;
        licking = ons.licking;
        ensure = ons.ensure;
        quinine = ons.quinine;
        condition = ons.condition;
        trialerror = ons.trialerror;
        codes = struct('pavlovian', 1, 'plus', 3, 'minus', 4, 'neutral', 5, 'blank', 6);
        
        if saveraw
            save(spath, 'dff', 'raw', 'centroid', 'brainmotion', 'raw_max', 'dff_max', 'dff_median', 'dff_noise', 'dff_sigma', 'deconvolved', 'running', 'framerate', 'edges', 'onsets', 'licking', 'ensure', 'quinine', 'condition', 'trialerror', 'codes');
        else
            save(spath, 'dff', 'centroid', 'brainmotion', 'raw_max', 'dff_max', 'dff_median', 'dff_noise', 'dff_sigma', 'deconvolved', 'running', 'framerate', 'edges', 'onsets', 'licking', 'ensure', 'quinine', 'condition', 'trialerror', 'codes');
        end
    end
end

