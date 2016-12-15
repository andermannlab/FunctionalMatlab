function [xdaytform targetrefs] = crossdayAlignTargets(mouse, dates, runs, pmt)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

    % Default Parameters ---------------------
    refsize = 500; % Number of random samples for reference image
    highpass_sigma = 10; % Size of Gaussian blur to be subtracted from a 
        % downsampled version of your image
    refoffset = 1000; % Number of frames to offset from beginning
        % for the registration target
    % ----------------------------------------

    if nargin < 4, pmt = 0; end
    
    dirs = sbxDir(mouse, dates(1));
    xdaydir = dirs.mouse;

    targetpaths = cell(1, length(dates));
    targetrefs = cell(1, length(dates));
    
    for d = 1:length(dates)
        allruns = sbxRuns(mouse, dates(d));
        path = sbxPath(mouse, dates(d), allruns(1), 'sbx');
        [~, fname] = fileparts(path);
        regpath = [xdaydir '\reg_xday'];
        refname = [regpath '\' fname '_reg.tif'];
        
        dirs = sbxDir(mouse, dates(d));
        impath = sprintf('%s/reg_affine/%s_%6i_%03i_reg.tif', dirs.date_mouse, mouse, dates(d), allruns(1));
        found = 0;
        
        if exist(refname, 'file') 
            ref = readtiff(refname);
            found = 1;
        elseif exist(impath, 'file')
            dt = dir(impath);
            if dt.date > datetime(2016, 12, 5);
                found = 1;
                ref = readtiff(impath);
            end
        end
        
        if ~found
            ref = sbxAlignTargetCore(path, pmt, 1, refoffset, refsize, 1);
        end
            
        edges = sbxRemoveEdges();
        sz = sbxInfo(path);
        sz = sz.sz;
        edges(1:2) = edges(1:2)/sz(2);
        edges(3:4) = edges(3:4)/sz(1);
        maxedges = max(edges);
        edges(1:2) = round(maxedges*sz(2));
        edges(3:4) = round(maxedges*sz(1));
        
        fsref = zeros(size(ref, 1) + edges(3) + edges(4), ...
            size(ref, 2) + edges(1) + edges(2), class(ref));
        fsref(edges(3)+1:end-edges(4), edges(1)+1:end-edges(2)) = ref;
        
        targetrefs{d} = fsref;
        targetpaths{d} = refname;
        writetiff(ref, refname, class(ref));
    end

    % Get the cross-run transforms to apply later
    xdaytform = sbxAlignAffineCoreTurboRegAcrossRuns(targetpaths, 1, highpass_sigma);
    
    xfactor = sz(2)/(sz(2) - sum(edges(1:2)));
    yfactor = sz(1)/(sz(1) - sum(edges(3:4)));
    for d = 1:length(xdaytform)
        xdaytform{d}.T(3, 1) = xdaytform{d}.T(3, 1)*xfactor;
        xdaytform{d}.T(3, 2) = xdaytform{d}.T(3, 2)*yfactor;
    end
end

