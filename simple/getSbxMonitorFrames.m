function framet = getSbxMonitorFrames(nidaq, timestamps, nframes)
% getSbxMonitorFrames gets the timing of monitor frames given a nidaq
% channel and nidaq timestamps that have been sorted.

    % Use simple thresholding to get frame onset times from the analog frame
    % signal recorded by the NiDAQ system:
    threshold = range(nidaq)/2;
    if threshold > 3 || threshold < 2
        disp(sprintf('Warning: TTL threshold is out of normal boundaries at %.1f', threshold));
    end

    ind = find(diff(nidaq > threshold) == 1); % Rising edge
    samplefreq = 1./diff(timestamps(1:2));
    ind(find((diff(ind)./samplefreq) < .01)) = [];
    framet = timestamps(ind);
    framet(1) = [];

    % Check if the pulse rate is close to double the number of frames
    % The new rig sends out pulses only on forward mirror motion
    if abs(length(framet)*2 - nframes) <= 2 % (TTL sometimes ends in up state)
        framet = interp1(1:2:length(framet)*2, framet, 0:length(framet)*2 - 1, 'linear', 'extrap');
        warning('Artificially adding pulses for flyback.')
    end

    % Check if pulses match frames
    if numel(framet) < nframes - 1 || numel(framet) > nframes
        w = warndlg(sprintf('Frame onsets measured by ephys, %i, do not match %i frames in movie', length(framet), nframes));
        disp(sprintf('Frame onsets measured by ephys, %i, do not match %i frames in movie', length(framet), nframes));
        framet = [];
    end

end

