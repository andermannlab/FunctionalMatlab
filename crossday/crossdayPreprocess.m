
function crossdayPreprocess(mouse, date, verbose)
%ALIGNPREPROCESS Identify all unique ROIs that have been previously found
%   and correlate their masks with the masks of the current date. Save as a
%   big ugly matlab file.

    % Check if mouse date exists
    if ~sbxExists(mouse, date)
        disp('ERROR: Mouse and date do not exist');
        return;
    end
    
    if nargin < 3, verbose = 0; end

    % PARAMETERS FOR REMOVING OVERLAPS ------------------------------------
    sizediff = 8; % If one ROI is > sizediff larger than another, throw out
    overlapping_pixels = 2;
    minimum_correlation = 0.05;
    keep_correlation_min = 0.5; % If there is a single match greater than 
    % this value, keep it
    keep_correlation_diff = 0.6; % If there are two or more matches and one
    % is greater than the rest by this value, keep it
    keep_correlation_max = 0.9; % If there is one value greater than
    % this, keep it even if diffs are < 0.6
    % ---------------------------------------------------------------------

    
    % First, check if it is a new animal that can be easily dealt with
    newanimal = alignIDsAlreadyCreated(mouse);
    if newanimal < 1
        alignInitialIDs(mouse, date);
        return
    end

    % Find out which dates contain IDs (for correlation) and get IDs
    if verbose, disp('Finding previous dates'); end
    predates = [];
    ids = [];
    
    dates = sbxDates(mouse);
    for i = 1:length(dates)
        if exist(alignIDPath(mouse, dates(i)), 'file')
            predates(length(predates)+1) = dates(i);
            dids = alignReadIDs(alignIDPath(mouse, dates(i)));
            ids = [ids dids'];
        end
    end
    
    % Get a list of unique ROIs
    uids = unique(ids);
    allids = ids(1:end);
    
    % Convert unique dates back to ROIs on individual days
    if verbose, disp('ROI conversion back to days'); end
    dids = cell(1, length(predates));
    drois = cell(1, length(predates));
    for d = 1:length(predates), dids{d} = []; end
    for i = 1:length(uids)
        roin = mod(uids(i), 1000);
        dt = (uids(i) - roin)/1000;
        d = find(predates == dt);
        
        drois{d} = [drois{d} roin];
        dids{d} = [dids{d} uids(i)];
    end    
    
    % Returns images of each movie and the transform to get it to match to
    % the current date
    if verbose, disp('Aligning across days'); end
    [xdaytform, targets] = crossdayAlignTargets(mouse, [predates str2num(date)]);
    for d = 1:length(targets)
        figure;
        imagesc(imwarp(targets{d}, xdaytform{d}, 'OutputView', imref2d(size(targets{d}))));
        colormap('gray');
    end
    
    % Load in the primary day
    if verbose, disp('Loading in primary day'); end
    [dmasks, dbinmasks, dtraces] = crossdayMasksTraces(mouse, date, []);
    dmaskran = zeros(4, size(dtraces, 2));
    for i = 1:size(dtraces, 2)
        xpos = find(sum(dbinmasks(:, :, i), 1) > 0);
        ypos = find(sum(dbinmasks(:, :, i), 2) > 0);
        if isempty(xpos) || isempty(ypos)
            dmaskran(:, i) = [1 2 1 2];
        else
            dmaskran(:, i) = [ypos(1) ypos(end) xpos(1) xpos(end)];
        end
    end
    
    % For each day with unique ROI matches, read in the signals file, warp
    % the masks and warp the target image
    if verbose, disp('Reading all other days'); end
    masks = cell(1, length(predates));
    binmasks = cell(1, length(predates));
    traces = cell(1, length(predates));
    maxtracelen = size(dtraces, 1);
    
    for d = 1:length(predates)
        if ~isempty(drois{d})
            [masks{d} binmasks{d} traces{d}] = crossdayMasksTraces(mouse, predates(d), drois{d});
            if size(traces{d}, 1) > maxtracelen, maxtracelen = size(traces{d}, 1); end
            targets{d} = imwarp(targets{d}, xdaytform{d}, 'OutputView', imref2d(size(targets{d})));
            for r = 1:length(dids{d})
                masks{d}(:, :, r) = imwarp(masks{d}(:, :, r), xdaytform{d}, 'OutputView', imref2d(size(masks{d}(:, :, r))));
                binmasks{d}(:, :, r) = logical(imwarp(double(binmasks{d}(:, :, r)), xdaytform{d}, 'OutputView', imref2d(size(binmasks{d}(:, :, r)))));
            end
        end
    end
    
    % Simplify back into a single list of uids, this time only including
    % overlapping uids.
    if verbose, disp('Correlating ROIs'); end
    uids = zeros(1, length(uids)) - 1;
    omasks = zeros(size(masks{1}, 1), size(masks{1}, 2), length(uids));
    obinmasks = zeros(size(masks{1}, 1), size(masks{1}, 2), length(uids));
    omaskran = zeros(4, length(uids));
    otraces = zeros(maxtracelen, length(uids));
    
    matches = cell(1, size(dtraces, 2));
    matchcorrs = cell(1, size(dtraces, 2));
    matchoverlaps = cell(1, size(dtraces, 2));
    for i = 1:size(dtraces, 2), matches{i} = []; matchcorrs{i} = []; matchoverlaps{i} = []; end
    
    overlappingrois = 0;
    for d = 1:length(predates)
        for r = 1:length(dids{d})
            xpos = find(sum(binmasks{d}(:, :, r), 1) > 0);
            ypos = find(sum(binmasks{d}(:, :, r), 2) > 0);
            
            if ~isempty(xpos) && ~isempty(ypos)
                for dr = 1:size(dmaskran, 2)
                    % Check that the ROIs are even close to nearby
                    orange = [min(ypos(1), dmaskran(1, dr)) max(ypos(end), dmaskran(2, dr)) ...
                        min(xpos(1), dmaskran(3, dr)) max(xpos(end), dmaskran(4, dr))]; % Overlapping range
                    if orange(2) - orange(1) <= sizediff*(dmaskran(2, dr) - dmaskran(1, dr)) && ...
                        orange(4) - orange(3) <= sizediff*(dmaskran(4, dr) - dmaskran(3, dr))

                        % Do a bitwise-and on the bitmasks
                        opix = sum(sum(bitand(dbinmasks(orange(1):orange(2), orange(3):orange(4), dr), ...
                            binmasks{d}(orange(1):orange(2), orange(3):orange(4), r))));
                        if opix > overlapping_pixels
                            % Finally, check that the correlation of the masks
                            % is high enough

                            cc = corr2(dmasks(orange(1):orange(2), orange(3):orange(4), dr), ...
                                masks{d}(orange(1):orange(2), orange(3):orange(4), r));
                            if cc > minimum_correlation
                                % Save for human analysis
                                if sum(uids(1:overlappingrois) == dids{d}(r)) == 0
                                    overlappingrois = overlappingrois + 1;

                                    uids(overlappingrois) = dids{d}(r);
                                    omasks(:, :, overlappingrois) = masks{d}(:, :, r);
                                    obinmasks(:, :, overlappingrois) = binmasks{d}(:, :, r);
                                    omaskran(:, overlappingrois) = orange;
                                    otraces(1:size(traces{d}(:, r), 1), overlappingrois) = traces{d}(:, r);
                                end

                                matches{dr} = [matches{dr} dids{d}(r)];
                                matchcorrs{dr} = [matchcorrs{dr} cc];
                                matchoverlaps{dr} = [matchoverlaps{dr} opix];
                            end
                        end
                    end
                end
            end
        end
    end
    
    % Get the final IDs 
    if verbose, disp('Finalizing and saving'); end
    finids = zeros(1, size(dtraces, 2)) - 1;
    for dr = 1:length(finids)
        [sortcorrs, sortorder] = sort(matchcorrs{dr});
        
        if isempty(sortcorrs)
            finids(dr) = str2num(sprintf('%s%03i', date, dr));
        % Match single values greater than min
        elseif length(sortcorrs) == 1 && sortcorrs(1) > keep_correlation_min
            finids(dr) = matches{dr}(sortorder(1));
        % Match situations with a length > 1 and one value above max
        elseif length(sortcorrs) > 1 && sortcorrs(end) >= keep_correlation_max
            finids(dr) = matches{dr}(sortorder(end));
        % Match situations with length > 1 and one value diff above others
        elseif length(matches{dr}) > 1 && sortcorrs(end) - sortcorrs(end-1) >= keep_correlation_diff
            finids(dr) = matches{dr}(sortorder(end));
        end
    end
    
    % And save
    uids = uids(1:overlappingrois);
    masks = omasks(:, :, 1:overlappingrois);
    binmasks = obinmasks(:, :, 1:overlappingrois);
    orange = omaskran(:, 1:overlappingrois);
    traces = otraces(:, 1:overlappingrois);
    images = targets;
    imdates = predates;
    
    uidcounts = zeros(1, overlappingrois);
    for i = 1:length(uids)
        uidcounts(i) = sum(allids == uids(i));
    end
    
    dir = sbxDir(mouse, date);
    path = sprintf('%s%s_%s_crossday-cell-preprocessing.mat', dir.date_mouse, mouse, date);
    
    save(path, 'uids', 'masks', 'binmasks', 'orange', 'traces', 'images', ...
        'dmasks', 'dbinmasks', 'dtraces', 'matches', 'matchcorrs', ...
        'matchoverlaps', 'finids', 'imdates', 'uidcounts');
                    
            
