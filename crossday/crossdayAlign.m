function crossdayAlign(mouse, date)
%ALIGNACROSSDAYS Aligns ROIs across days using overlap of pixels and
%   correlation between masks. Its output is a list of ROI IDs in each date
%   directory. ROI IDs are firstDateFoundROInumber

% ADD WAY TO MERGE OPEN ROIs
% Add correlations with non-unique and take max

    dir = sbxDir(mouse, date);
    path = sprintf('%s%s_%s_crossday-cell-preprocessing.mat', dir.date_mouse, mouse, date);
    if ~exist(path, 'file')
        disp('ERROR: Not preprocessed yet.');
        return
    end
    
    % Load in preprocessed masks, runs, traces, and overlaps
    prep = load(path, '-mat');
    
    % Double check if alignment worked
    for d = 1:length(prep.images)
        figure;
        imagesc(prep.images{d});
        colormap('gray');
    end
    
    question = 'Did alignment work? 1 for yes, 0 for no: ';
    didwork = input(question);
    if didwork == 0, disp('That sucks.'); return; end
    
    % TEMPORARY
    % Loop through and plot each option, uiwait and save the best value
    % Key- we're looping through day 1 and listing all matches for day 2
    % with a cell from day 1.
    
    % Count number of tests to be done
    ntest = sum(prep.finids < 0);
    
    close all;
    ntested = 1;
    ids = prep.finids(1:end);
    for i = 1:length(prep.finids)
        if prep.finids(i) < 0
            oorois = prep.matches{i}; % Overlapping ROIs
            mask1 = prep.dbinmasks(:, :, i); % Full-size mask of check day
            
            for o = 1:length(oorois)
                if sum(oorois(o) == ids) > 0
                    disp(sprintf('WARNING: ROI %i has already been defined. You cannot chose it.', o));
                end
                
                idpos = find(prep.uids == oorois(o));
                oodate = (oorois(o) - mod(oorois(o), 1000))/1000;
                datepos = find(prep.imdates == oodate);
                
                orn = prep.orange(:, idpos);
                orn = [max(orn(1) - 20, 1) min(orn(2) + 20, size(mask1, 1)) ...
                    max(orn(3) - 20, 1) min(orn(4) + 20, size(mask1, 2))];
                
                adim1 = prep.images{end}(orn(1):orn(2), orn(3):orn(4));
                adim2 = prep.images{datepos}(orn(1):orn(2), orn(3):orn(4));
                
                adbmask1 = logical(mask1(orn(1):orn(2), orn(3):orn(4)));
                adbmask2 = logical(prep.binmasks(orn(1):orn(2), orn(3):orn(4), idpos));
                
                admask1 = prep.dmasks(orn(1):orn(2), orn(3):orn(4), i);
                admask2 = prep.masks(orn(1):orn(2), orn(3):orn(4), idpos);
                
                allpix = sum(sum(adbmask1)) + sum(sum(adbmask2));
                overlapfrac = prep.matchoverlaps{i}(o)/allpix;
                cc = prep.matchcorrs{i}(o);
                
                idcount = prep.uidcounts(idpos);
                
                plotPossibleOverlaps(prep.dtraces(:, i), prep.traces(:, idpos), ...
                    adim1, adim2, adim1, adbmask1, adbmask2, admask1, admask2, ...
                    sprintf('ROI: %i, overlap: %.1f, cc: %.2f, found %i times', ...
                    o, overlapfrac, cc, idcount), o);
            end
            
            question = sprintf('Step %i/%i: which of %i ROIs match, 0 for none? ', ntested, ntest, length(oorois));
            whichmatch = input(question);
            if whichmatch > 0
                ids(i) = oorois(whichmatch);
            else
                ids(i) = str2num(sprintf('%s%03i', date, i));
            end
            ntested = ntested + 1;
            close all;
        end
    end
    
    path = alignIDPath(mouse, date);
    fo = fopen(path, 'w');
    
    for i = 1:length(ids)
        fprintf(fo, '%9i\n', ids(i));
    end
    
    fclose(fo);
    

%     disp(sprintf('Found %i overlapping ROIS across %s and %s', size(matches, 2), date1, date2));
    
end
