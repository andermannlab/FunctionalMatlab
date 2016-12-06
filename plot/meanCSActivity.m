function traces = meanCSActivity(mouse, date, tracetype)
%MEANCSACTIVITY calculates the mean activity for plus, minus, and neutral
%   and returns them as vectors of each type that can easily be
%   concatenated. Assumes training runs are 2, 3, and 4.

    % Basic parameters
    presecs = 1; % number of seconds prior to stimulus for dff
    secs = 8; % number of seconds of stimulus
    
    % Input tracetype can be deconvolved or dff
    if nargin < 3, tracetype = 'deconvolved'; end
    
    % Orders by tcodes, adds pavlovians to pluses
    tcodes = {'plus'; 'neutral'; 'minus'};
    n = zeros(1, length(tcodes));

    % Assumes that runs 2, 3, and 4 are training runs
    for r = 2:4
        %try
            % Open simpcell file
            sc = sbxLoad(mouse, date, r, 'simpcell');
            
            % Based on framerate, get number of frames
            prefrs = round(sc.framerate*presecs);
            frs = round(sc.framerate*secs);
            
            % Make output the correct size based on number of cells
            if ~exist('traces'), traces = zeros(length(tcodes), size(sc.dff, 1), frs+prefrs+1); end
            
            % Set pavlovians to be pluses
            sc.condition(sc.condition == sc.codes.pavlovian) = sc.codes.plus;
            
            % Iterate over plus, neutral, and minus
            for code = 1:length(tcodes)
                % Get the onsets of the stimuli
                ons = sc.onsets(sc.condition == sc.codes.(char(tcodes(code))));
                n(code) = n(code) + length(ons);
            
                % It is simple to average over deconvolved time
                if strcmp(tracetype, 'deconvolved')
                    for o = 1:length(ons)
                        pre = mean(sc.deconvolved(:, ons(o)-prefrs:ons(o)-1), 2)';
                        traces(code, :, :) = traces(code, :, :) + reshape(sc.deconvolved(:, ons(o)-prefrs:ons(o)+frs), 1, size(traces, 2), size(traces, 3));
                    end
                elseif strcmp(tracetype, 'dff')
                    for o = 1:length(ons)
                        pre = mean(sc.dff(:, ons(o)-prefrs:ons(o)-1), 2)';
                        post = sc.dff(:, ons(o)-prefrs:ons(o)+frs);
                        post = bsxfun(@minus, post, pre');
                        traces(code, :, :) = traces(code, :, :) + ...
                            reshape(post, 1, size(traces, 2), size(traces, 3));
                    end
                end
            end
        %catch
        %    disp(sprintf('WARNING: could not load run %i', r));
        %end
    end
            
    % Divide by the number of onsets to get an average
    for i = 1:length(tcodes), traces(i, :, :) = traces(i, :, :)/n(i); end

end

