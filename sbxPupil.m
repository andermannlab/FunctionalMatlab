function out = sbxPupil(mouse, date, run, lowpass)
%UNTITLED11 Summary of this function goes here
%   Detailed explanation goes here
    
    % Lowpass filter by default
    if nargin < 4, lowpass = true; end

    % Prepare the output
    out = [];
    
    % Load file
    ppath = sbxPath(mouse, date, run, 'pdiam');
    if ~isempty(ppath)
        out = sbxLoad(mouse, date, run, 'pdiam');
        out = out.pupil;
        return;
    end
    
    % Load the file if possible
    test = sbxPath(mouse, date, run, 'pupil');
    if isempty(test), return; end
    e = sbxLoad(mouse, date, run, 'pupil');
    
    if ~isfield(e, 'data'), return; end
    
    % Get the best image for determining the outline and get the mask
    av = mean(e.data, 4);
    av = av - min(min(av));
    av = av/max(max(av));
    
    mx = double(max(e.data, [], 4));
    mx = mx - min(min(mx));
    mx = mx/max(max(mx));
    
    % Combine average and max to find the mask
    both = (av + mx)/2;
    
    % Search for a mask in another directory from the same day
    bwmask = sbxPupilCoreSearchAlternates(mouse, date);
    if ~isempty(bwmask)
        temp = figure;
        subplot(1, 2, 1);
        imagesc(both);
        colormap('Gray');
        subplot(1, 2, 2);
        imagesc(both.*bwmask);
        colormap('Gray');
        button = questdlg('Does the previous mask overlap with the pupil?', ...
            'No', 'Yes');
        if strcmp(button, 'No')
            bwmask = [];
        end
        close(temp);
    end
    
    if isempty(bwmask)
        uiwait(msgbox('Click in an outline around the visible eyeball. Double click within to finish.'));
        figure;
        bwmask = roipoly(both);
    end
    
    % Apply the mask and sum
    masked = bsxfun(@times, bwmask, double(squeeze(e.data)));
    out = squeeze(sum(sum(masked, 2), 1));
    
    % Find deviations that are too large
    stdev = std(out);
    bl = medfilt1(out, 100);
    out(out > bl + 2*stdev) = -1;
    out(out < bl - 2*stdev) = -1;
    
    % Fix beginning
    out(1) = out(2); % Fix errors on first frame
    if sum(out(1:3) == -1) > 0
        epos = 3 + find(out(4:end) > -1, 1) - 2;
        out(1:epos) = out(epos + 2);
    end
    
    % Interpolate across -1 regions
    npos = 3 + find(out(4:end - 4) == -1, 1);
    while ~isempty(npos)
        epos = npos + find(out(npos:end - 4) > -1, 1) - 2;
        
        if isempty(epos)
            out(npos - 2:end) = out(npos - 3);
        else
            while epos + 5 < length(out) && ~isempty(find(out(epos+1:epos+5) == -1, 1))
                epos = epos + find(out(epos+3:end - 4) > -1, 1) + 2;
                if isempty(epos), epos = length(out); end
            end
            
            % No idea what this does- fixing error
            if epos + 3 > length(out), epos = length(out) - 3; end
            
            binterp = out(npos - 3);
            einterp = out(epos + 3);
            
            ninterp = (epos + 2) - (npos - 2) + 1;
            newdata = interp1([0 ninterp + 1], [binterp einterp], 1:ninterp);
            out(npos - 2:epos + 2) = newdata';
        end
        
        npos = npos + find(out(npos:end - 4) == -1, 1) - 1;
    end
    
    % Lowpass filter if necessary
    if lowpass
        inf = sbxLoad(mouse, date, run, 'info');
        if inf.scanmode == 1, freq = 15.49; else freq = 30.98; end
        
        d = designfilt('lowpassiir', ...
        'PassbandFrequency',1, 'StopbandFrequency',3, ...
        'PassbandRipple',0.2, 'StopbandAttenuation',60, ...
        'SampleRate', freq);
        
        out = filtfilt(d, out);
    end
    
    pupil = out; %#ok<NASGU>
    save(sbxPath(mouse, date, run, 'pdiam', true), 'pupil');
    save(sbxPath(mouse, date, run, 'pmask', true), 'bwmask');
end
