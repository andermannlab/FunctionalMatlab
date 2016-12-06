function [ox, oy] = simplifyTrace(tr, n)
%SIMPLIFYTRACE simplifies a trace for plotting. It makes the trace close to
% length n (but can be greater than n) by cutting the trace into blocks and
% finding the min and max in that block. Then, it saves only the xs, mins, 
% and maxes
    
    if nargin < 2
        n = 1000;
    end

    x = 1:length(tr);
    if length(tr) < n*3
        ox = x;
        oy = tr;
        return
    end
    
    % Because we get 2 points per n, we divide n by 2
    n = round(n/2);
    
    % Initialize the blocks over which we will iterate
    block = floor(length(tr)/n);
    newn = ceil(length(tr)/block);
    ox = zeros(2*newn, 1);
    oy = zeros(2*newn, 1);
    
    % Iterate to find the order of min and max
    for i=1:newn
        pos = (i - 1)*block + 1;
        epos = pos + block - 1;
        if epos > length(tr)
            epos = length(tr);
        end
        trblock = tr(pos:epos);
        xblock = x(pos:epos);
        mn = min(trblock);
        mx = max(trblock);
        pmn = find(trblock == mn, 1);
        pmx = find(trblock == mx, 1);
        if ~isnan(mn) && ~isnan(mx)
            if pmn < pmx
                ox(2*i - 1) = xblock(pmn);
                oy(2*i - 1) = mn;

                ox(2*i) = xblock(pmx);
                oy(2*i) = mx;
            else
                ox(2*i) = xblock(pmn);
                oy(2*i) = mn;

                ox(2*i - 1) = xblock(pmx);
                oy(2*i - 1) = mx;
            end
        end
    end
end

