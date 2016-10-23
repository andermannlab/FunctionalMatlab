function [onsets, offsets] = sbxTTLOnsets(ttl, timestamps, mininterval, ttlv)
%sbxTTLOnsets Convert a TTL signal recorded by a nidaq into a series of
%   onsets with a minimum interval of mininterval and a threshold voltage
%   of ttlv

    % Assume an interval of at least 50 ms and TTL threshold voltage of 2.0
    if nargin < 3
        mininterval = 0.050;
    end
    if nargin < 4
        ttlv = 2.0;
    end
    
    % Threshold the stimuli
    ind = find(diff(ttl > ttlv) == 1);
    samplefreq = 1./diff(timestamps(1:2));
    ind(find((diff(ind)./samplefreq) < .01)) = [];
    onsets = timestamps(ind);
    
    % Eliminate onsets faster than mininterval
    diff_ind = diff([-1*mininterval ;onsets]);
    ind_error = find(diff_ind < mininterval);
    onsets(ind_error) = [];

    % Remove onsets if pulse begins high
    ind2 = find(diff(ttl > ttlv) == -1);
    ind2(find((diff(ind2)./samplefreq) < .01)) = [];
    if ~isempty(ind) && ~isempty(ind2) && ind2(1) < ind(1)
        ind2(1) = [];
    end
    
    % Calculate offests if need be
    offsets = timestamps(ind2);
    diff_ind2 = diff([-1*mininterval ;offsets]);
    ind_error2 = find(diff_ind2 < mininterval);
    offsets(ind_error2) = [];

end

