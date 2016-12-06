function [pool, sz] = openParallel()
%OPENPARALLEL opens a Matlab pool using the correct conventions for each
%   Matlab version
    
    % Test if gcp opens a pool
    pool = gcp('nocreate');
    if isempty(pool)
        if strcmp(version('-release'), '2015a') || strcmp(version('-release'),'2015b')
            pool = parpool;
            sz = pool.NumWorkers - 4;
        else
            if matlabpool('size') == 0
               matlabpool open;
            end
            sz = matlabpool('size');
        end
    else
        sz = pool.NumWorkers - 4;
    end
end

