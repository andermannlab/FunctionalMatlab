function tform = interpolateTransform(tform, known, cutextremes)
% INTERPOLATETRANSFORM interpolates a transformation from known values

    if nargin < 3, cutextremes = false;

    if cutextremes
        % Extract values to throw out extremes
        vals = zeros(6, length(known));
        for i = 1:3
            for j = 1:2
                for t = 1:length(known)
                    if known(t) < 0

                    elseif isempty(tform{known(t)})
                        known(t) = -1;
                    else
                        vals((i-1)*2 + i, t) = tform{known(t)}.T(i, j);
                    end
                end
            end
        end

        % Throw out extremes
        mn = mean(vals, 2);
        stdev = std(vals, [], 2);
        irange = 1:length(known);
        for i = [3 6]
            skip = irange(vals(i, :) > mn(i) + 5*std(i));
            known(skip) = -1;
        end
        vals = vals(:, known > -1);
        known = known(known > -1);
    end
    
    % Fill in the end with the same values
    for i = known(end):length(tform), tform{i} = tform{known(end)}; end
    for i = 1:known(1)-1, tform{i} = tform{known(1)}; end
    
    % Interpolate
    for i = 2:length(known)
        for k = known(i-1)+1:known(i)-1
            tform{k} = tform{known(i)};
            
            for m = 1:3
                for n = 1:2
                    x = [known(i-1) known(i)];
                    y = [tform{known(i-1)}.T(m, n) tform{known(i)}.T(m, n)];
                    tform{k}.T(m, n) = interp1(x, y, k);
                end
            end
        end
    end
end