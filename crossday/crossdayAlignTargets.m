function [xdaytform targetrefs] = crossdayAlignTargets(mouse, dates, runs, pmt)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

    % Default Parameters ---------------------
    refsize = 500; % Number of random samples for reference image
    highpass_sigma = 5*2; % Size of Gaussian blur to be subtracted from a 
        % downsampled version of your image
    refoffset = 500; % Number of frames to offset from beginning
        % for the registration target
    % ----------------------------------------

    if nargin < 4, pmt = 0; end
    
    dir = sbxDir(mouse, dates(1));
    xdaydir = dir.mouse;

    targetpaths = cell(1, length(dates));
    targetrefs = cell(1, length(dates));

    edges = sbxRemoveEdges();
    
    for d = 1:length(dates)
        allruns = sbxRuns(mouse, dates(d));
        path = sbxPath(mouse, dates(d), allruns(1), 'sbx');
        ref = sbxAlignTargetCore(path, pmt, 1, refoffset, refsize);
        fsref = zeros(size(ref, 1) + edges(3) + edges(4) - 1, ...
            size(ref, 2) + edges(1) + edges(2) - 1, class(ref));
        fsref(edges(3):end-edges(4), edges(1):end-edges(2)) = ref;
        
        targetrefs{d} = fsref;
        
        [~, fname] = fileparts(path);
        regpath = [xdaydir '\reg_xday'];
        refname = [regpath '\' fname '_reg.tif'];
        targetpaths{d} = refname;
        writetiff(ref, refname, class(ref));
    end

    % Get the cross-run transforms to apply later
    xdaytform = sbxAlignAffineCoreTurboRegAcrossRuns(targetpaths, 1, highpass_sigma);
end

