function [corder, varargout] = organizeByCSActivity(mouse, date, tracetype)
%organizeSpontByCS This function orders cells by how active they were in
%   the stimulus run, sorted by plus, then neutral, then minus. They can be
%   ordered based off the deconvolved signal or grouped by the absolute 
%   magnitude of the dff and orderd by magnitude of dff. Tracetype can be
%   deconvolved or dff. Optional output cuts lists borders between groups.

    % Basic parameters
    presecs = 1; % number of seconds prior to stimulus for dff
    secs = 2; % number of seconds of stimulus
    
    % Input tracetype can be deconvolved or dff
    if nargin < 3, tracetype = 'dff'; end
    
    % Orders by tcodes, adds pavlovians to pluses
    tcodes = {'plus'; 'neutral'; 'minus'};
    n = zeros(1, length(tcodes));

    % Assumes that runs 2, 3, and 4 are training runs
    for r = 2:4
        try
            % Open simpcell file
            sc = sbxLoad(mouse, date, r, 'simpcell');
            
            % Make output the correct size based on number of cells
            if ~exist('vals'), vals = zeros(length(tcodes), size(sc.dff, 1)); end
            
            % Set pavlovians to be pluses
            sc.condition(sc.condition == sc.codes.pavlovian) = sc.codes.plus;
            frs = round(sc.framerate*secs);
            prefrs = round(sc.framerate*presecs);
            
            % Iterate over plus, neutral, and minus
            for code = 1:length(tcodes)
                % Get the onsets of the stimuli
                ons = sc.onsets(sc.condition == sc.codes.(char(tcodes(code))));
                n(code) = n(code) + length(ons);
            
                % It is simple to average over deconvolved time
                if strcmp(tracetype, 'deconvolved')
                    for o = 1:length(ons)
                        pre = mean(sc.deconvolved(:, ons(o)-prefrs:ons(o)-1), 2)';
                        post = mean(sc.deconvolved(:, ons(o):ons(o)+frs), 2)';
                        vals(code, :) = vals(code, :) + (post - pre);
                    end
                elseif strcmp(tracetype, 'dff')
                    for o = 1:length(ons)
                        pre = mean(sc.dff(:, ons(o)-prefrs:ons(o)-1), 2)';
                        post = mean(sc.dff(:, ons(o):ons(o)+frs), 2)';
                        vals(code, :) = vals(code, :) + (post - pre);
                    end
                else % For raw data - calculate dff
                    % Or get the dff for each onset and add
                    for o = 1:length(ons)
                        pre = sum(sc.raw(:, ons(o)-prefrs:ons(o)-1), 2)';
                        post = sum(sc.raw(:, ons(o):ons(o)+frs), 2)';
                        vals(code, :) = vals(code, :) + (post - pre)./pre;
                    end
                end
            end
        catch
            disp(sprintf('WARNING: could not load run %i', r));
        end
    end
    
    % Divide by the number of onsets to get an average
    for i = 1:length(tcodes), vals(i) = vals(i)/n(i); end
    
    % Group by absolute value of the maximum dff
    groups = zeros(1, size(vals, 2));
    gmax = zeros(1, size(vals, 2));
    for c = 1:size(vals, 2)
        [~, ix] = max(abs(vals(:, c)));
        gmax(c) = vals(ix, c);
        groups(c) = ix;
    end
    
    % And sort within group
    off = 0;
    corder = zeros(1, size(vals, 2));
    cuts = zeros(1, length(tcodes));
    for g = 1:length(tcodes)
        [~, si] = sort(gmax(groups == g));
        si = flip(si);
        pos = 1:length(groups);
        pos = pos(groups == g);
        corder(1+off:length(si)+off) = pos(si);
        cuts(g) = off;
        off = off + length(si);
    end
    
    % Optionally list the borders between groups
    if nargout > 1
        varargout{1} = cuts;
    end
end

