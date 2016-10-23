function out = sbxAlignAffine(mouse, date, runs, returnimage, target, pmt)
    % REMEMBER: PMT is 0-indexed
    % If return image is set to false, sbxAlignAffine will only align the
    % image
    % Will align to a reference taken from the first refsize frames of the
    % first run
    % Depends on hardcoded location of ImageJ and on sbxDir and sbxRuns

    % Parameters ---------------------
    chunksize = 1000; % Parfor chunking
    refsize = 500; % Number of random samples for reference image
    tbin = 1; % Time to bin in seconds
    % --------------------------------
    
    % Correct inputs
    if nargin < 3 || isempty(runs), runs = []; end
    if nargin < 4 || isempty(returnimage), returnimage = true; end
    if nargin < 5 || isempty(target), target = []; end
    if nargin < 6 || isempty(pmt), pmt = 0; end
    if pmt > 1, pmt = 1; end
    if pmt < 0, pmt = 0; end
    
    if isempty(runs), runs = sbxRuns(mouse, date); end
    if length(runs) > 1, returnimage = false; end
    
    % Determine if output needs to be saved
    saveoutput = false;
    for r = 1:length(runs)
        % Get the path and info file
        path = sbxPath(mouse, date, runs(1), 'sbx');

        % Check for alignment file
        afalign = [path(1:end-4) '.alignaffine'];
        if ~exist(afalign, 'file'), saveoutput = true; end
    end
    
    % And set the target to be the first file in the list if necessary
    if saveoutput && isempty(target)
        if length(runs) > 1
            target = runs(1);
            disp(sprintf('WARNING: Target not set, one run given, aligning to run %i', target));
        else
            target = sbxRuns(mouse, date); 
            target = target(1); 
            disp(sprintf('WARNING: Target not set, one run given, aligning to run %i', target));
        end
    end
    
    % ===================================================================
    % Save all target files, the last will be the main target
    
    if saveoutput
        allruns = runs(runs ~= target);
        allruns = [allruns target];
        targetpaths = cell(1, length(allruns));
        targetrefs = cell(1, length(allruns));

        for r = 1:length(allruns)
            path = sbxPath(mouse, date, allruns(r), 'sbx');
            ref = sbxAlignTargetCore(path, pmt);
            targetrefs{r} = ref;

            [rpath, fname] = fileparts(path);
            regpath = [fileparts(rpath) '\reg_affine'];
            refname = [regpath '\' fname '_reg.tif'];
            targetpaths{r} = refname;
            writetiff(ref, refname, class(ref));
        end
        
        bigref = sbxAlignTargetCore(path, pmt, 1);
    
        % Get the cross-run transforms to apply later
        xruntform = sbxAlignAffineCoreTurboRegAcrossRuns(targetpaths, 2);
        %xruntrans = sbxAlignAffineCoreDFTAcrossRuns(bigtargets, xruntform);
    
        % =================================================================

        % Iterate over all runs
        for r = 1:length(runs)
            run = runs(r);

            % Get the path and info file
            path = sbxPath(mouse, date, run, 'sbx');
            afalign = [path(1:end-4) '.alignaffine'];
            if ~exist(afalign, 'file')
                info = sbxInfo(path);
                nframes = info.max_idx + 1;
                
                % Get the reference file
                indices = 1:length(allruns);
                allrunindex = indices(allruns == run);
                runrefname = targetpaths{allrunindex};

                % Sort out how many frames to bin based on framerate
                if info.scanmode == 1
                    binframes = max(1, round(15.49*tbin));
                else
                    binframes = max(1, round(30.98*tbin));
                end

                % Affine align using turboreg in ImageJ
                runchunksize = floor(chunksize/binframes)*binframes*binframes;
                nchunks = ceil(nframes/runchunksize);
                ootform = cell(1, nchunks);
                for c = 1:nchunks
                    ootform{c} = sbxAlignTurboRegCore(path, (c-1)*runchunksize+1,...
                        runchunksize, runrefname, binframes, pmt, targetrefs{allrunindex});
                end

                % Get the cross-run affine transform
                tform = cell(1, nframes);
                xtform = xruntform{allrunindex};
                
                % Put everything back in order and keep track of which indices
                % have values
                known = zeros(1, nframes);
                for c = 1:nchunks
                    for f = 1:length(ootform{c})
                        pos = (c - 1)*runchunksize + f;
                        if pos <= nframes
                            tform{pos} = ootform{c}{f};
                            if ~isempty(tform{pos})
                                tform{pos}.T = xtform.T*tform{pos}.T;
                                known(pos) = 1; 
                            end
                        end
                    end
                end
                indices = 1:nframes;
                indices(known < 1) = 0;
                known = indices(indices > 0);

                % Now fix interpolated registration with dft registration
                if binframes > 1
                    % Interpolate any missing frames
                    tform = interpolateTransform(tform, known);

                    % Affine align using turboreg in ImageJ
                    nchunks = ceil(nframes/chunksize);
                    ootform = cell(1, nchunks);
                    ootrans = cell(1, nchunks);
                    for c = 1:nchunks, ootform{c} = tform((c-1)*chunksize+1:min(nframes, c*chunksize)); end

                    % Get the current parallel pool or initailize
                    openParallel();

                    parfor c = 1:nchunks
                        ootrans{c} = sbxAlignAffinePlusDFT(path, (c-1)*chunksize+1, chunksize, bigref, ootform{c}, pmt);
                    end

                    trans = zeros(nframes, 4);
                    for c = 1:nchunks
                        pos = (c - 1)*chunksize + 1;
                        upos = min(c*chunksize, nframes);
                        trans(pos:upos, :) = ootrans{c};
                    end
                end

                save(afalign, 'tform', 'trans');
            end
        end
    end
        
    if returnimage
        path = sbxPath(mouse, date, runs, 'sbx');
        afalign = [path(1:end-4) '.alignaffine'];
        alignment = load(afalign, '-mat');

        info = sbxInfo(path);
        nframes = info.max_idx + 1;

        nchunks = ceil(nframes/chunksize);
        tform = cell(1, nchunks);
        trans = cell(1, nchunks);
        outchunk = cell(1, nchunks);
        
        for c = 1:nchunks
            pos = (c - 1)*chunksize + 1;
            upos = min(c*chunksize, nframes);
            tform{c} = alignment.tform(pos:upos);
            trans{c} = alignment.trans(pos:upos, :);
        end
        
        % Get the current parallel pool or initailize
        openParallel();

        parfor c = 1:nchunks
            pos = (c - 1)*chunksize + 1;
            outchunk{c} = sbxAlignAffineApplyAffineDFT(path, pos, chunksize, ...
                tform{c}, trans{c}, pmt);
        end
        
        out = zeros(info.sz(1), info.sz(2), nframes);
        for c = 1:nchunks
            pos = (c - 1)*chunksize + 1;
            upos = min(c*chunksize, nframes);
            out(:, :, pos:upos) = outchunk{c};
        end
    end
end

