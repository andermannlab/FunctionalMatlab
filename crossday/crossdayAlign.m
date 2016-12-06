function crossdayAlign(mouse, date)
%ALIGNACROSSDAYS Aligns ROIs across days using overlap of pixels and
%   correlation between masks. Its output is a list of ROI IDs in each date
%   directory. ROI IDs are firstDateFoundROInumber

    dir = sbxDir(mouse, date);
    path = sprintf('%s%s_%s_crossday-cell-preprocessing.mat', dir.date_mouse, mouse, date);
    if ~exist(path, 'file')
        disp('ERROR: Not preprocessed yet.');
        return
    end
    
    % Load in preprocessed masks, runs, traces, and overlaps
    prep = load(path, '-mat');
    
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
                
                plotPossibleOverlaps(prep.dtraces(:, i), prep.traces(:, idpos), ...
                    adim1, adim2, adim1, adbmask1, adbmask2, admask1, admask2, ...
                    sprintf('ROI: %i, overlap: %.1f, cc: %.2f', ...
                    o, overlapfrac, cc), o);
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
    
%     % Now fix up matches
%     omatches = matches; % Save just in case of programming errors
%     matches = omatches(:, omatches(2, :) > 0);
%     
%     % Check for duplicates
%     [n, bin] = histc(matches(2, :), unique(matches(2, :)));
%     multiples = find(n > 1);
%     index = find(ismember(bin, multiples));
%     
%     if ~isempty(index)
%         disp('You have matched the same ROI multiple times.');
%         for i=1:length(index)
%             % Double-check that we haven't already dealt with it
%             if index(i) > 0
%                 allindices = find(matches(2, :) == matches(2, index(i)));
%                 ind1 = matches(1, allindices);
%                 ind2 = matches(2, allindices);
%                 
%                 imask2 = masks2warped(:, :, ind2(1));
%                 [dim2, c21, c22] = imForDisplay(cim2, imask2);
%            
%                 for j=1:length(allindices)
%                     index(j) = 0;
%                     
%                     imask1 = masks1(:, :, ind1(j));
%                     [dim1, c11, c12] = imForDisplay(im1, imask1);
%                     %overlap_in_pixels = overlappix(ind1(j)
%                     [imm, smask1, smask2] = matchImsForDisplay(im1, im2, imask1, imask2, c11, c12, c21, c22);
%                     plotPossibleOverlaps(traces1(:, ind1(j)), traces2(:, ind2(j)), ...
%                         dim1, dim2, imm, smask1, smask2, ['ROI ', num2str(j), ' overlap ', ...
%                         num2str(overlappix(ind1(j), ind2(j))/sum(sum(imask2)))]);
%                 end
%                 
%                 whichmatch = input(['Which of ', num2str(length(allindices)), ...
%                 ' ROI matches, 0 for none? ']);
%                 for j=1:length(allindices)
%                     index(index == allindices(j)) = 0;
%                     if j ~= whichmatch
%                         matches(:, allindices(j)) = 0;
%                     end
%                 end
%                 close all;
%             end
%         end
%     end
%     
%     % Now refix up matches
%     omatches = matches; % Save just in case of programming errors
%     matches = omatches(:, omatches(2, :) > 0);
%     
%     % Recheck for duplicates
%     [n, bin] = histc(matches(2, :), unique(matches(2, :)));
%     multiples = find(n > 1);
%     index = find(ismember(bin, multiples));
%     
%     % Get dirs to figure out where to save
%     dirs1 = sbxDirs(mouse, date1, run1);
%     dirs2 = sbxDirs(mouse, date2, run2);
%     
%     columns = [str2num(date1), str2num(date2)];
%     savename = sprintf('%s\\%s_%s-ind_to_%s_roimatch.mat', dirs1.date_mouse, mouse, date1, date2);
%     save(savename, 'matches', 'columns');
%     
%     switchmatch = zeros(size(matches));
%     [switchmatch(1, :), sortidx] = sort(matches(2, :));
%     switchmatch(2, :) = matches(1, sortidx);
%     
%     matches = switchmatch;
%     columns = [str2num(date2), str2num(date1)];
%     savename = sprintf('%s\\%s_%s-ind_to_%s_roimatch.mat', dirs2.date_mouse, mouse, date2, date1);
%     save(savename, 'matches', 'columns');
%     
%     disp(sprintf('Found %i overlapping ROIS across %s and %s', size(matches, 2), date1, date2));
    
end
