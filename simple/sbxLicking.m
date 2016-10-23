function out = sbxLicking(mouse, date, run, ttlv, miniti)
    % Return the onset times and codes of monkeylogic stimuli for a
    % particular mouse, date, and run.
    
% Check if already created
dirsf = sbxDirs(mouse, date, run);
dirs = dirsf.runs{1};
spath = [dirs.path '\' dirs.sbx_name '.onsets'];
if exist(spath)
    out = load(spath, '-mat');
    return
end

% Check if this is a spontaneous run or not
if ~isempty(dirs.ml)
    out = sbxOnsets(mouse, date, run, ttlv, miniti);
    return
end

% Set the TTL voltage threshold for measuring stimulus onsets
if nargin == 3
    ttlv = 1.0;
    miniti = 5;
end

% Load nidaq data
nidaq = sbxLoad(mouse, date, run, 'ephys');
global info
nframes = info.max_idx + 1;

% Get the appropriate nidaq channels
rig = get_rig_name();
ch = get_ch_values_nidaq(rig);

% Sort Nidaq data
[nidaq.timeStamps, time_idx] = sort(nidaq.timeStamps);
for i = 1:size(nidaq.data, 2)
	nidaq.data(:, i) = nidaq.data(time_idx, i);
end
    
% Get the timing of monitor frames
onset2p = getSbxMonitorFrames(nidaq.data(:, ch.twoP), nidaq.timeStamps, nframes);

% Get the time onsets of licking, ensure, and quinine
lickingt = sbxTTLOnsets(nidaq.data(:, ch.licking), nidaq.timeStamps, 0.050);

% Convert to trial onsets
licking = localTimesToOnsets(onset2p, lickingt);

% And save
save(spath, 'licking');

out = struct('licking', licking);
end

function out = localTimesToOnsets(time2p, timestim)
    % Convert an array of times to an array of frame onsets
    if length(time2p) < 2^16 - 1
        out = zeros(length(timestim), 1, 'uint16');
    else
        out = zeros(length(timestim), 1, 'uint32');
    end
    
    last = 1;
    toomany = 0;
    for i=1:length(timestim)
        last = (last - 1) + find(time2p(last:end) > timestim(i), 1);
        if ~isempty(last)
            out(i) = last;
        else
            toomany = toomany + 1;
            out(i) = -1;
        end
    end
    
    if toomany > 0
        out = out(1:end - toomany);
    end
end