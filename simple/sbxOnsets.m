function out = sbxOnsets(mouse, date, run, ttlv, miniti)
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

    % Set the TTL voltage threshold for measuring stimulus onsets
    if nargin == 3
        ttlv = 1.0;
        miniti = 5;
    end

    % Check if this is a spontaneous run or not
    if isempty(dirs.ml) 
        out = sbxLicking(mouse, date, run, ttlv, miniti);
        return
    end

    % Load nidaq data
    nidaq = sbxLoad(mouse, date, run, 'ephys');
    global info
    nframes = info.max_idx + 1;

    % Get the appropriate nidaq channels
    rig = get_rig_name();
    ch = get_ch_values_nidaq(rig);

    % Load in the monkeylogic file
    ml = bhv_read(dirs.ml);

    % Sort Nidaq data
    [nidaq.timeStamps, time_idx] = sort(nidaq.timeStamps);
    for i = 1:size(nidaq.data, 2)
        nidaq.data(:, i) = nidaq.data(time_idx, i);
    end

    % Get the timing of monitor frames
    onset2p = getSbxMonitorFrames(nidaq.data(:, ch.twoP), nidaq.timeStamps, nframes);

    % Get the timing of visual stimuli
    onsetst = sbxTTLOnsets(nidaq.data(:,ch.OTB_visstim), nidaq.timeStamps, miniti, ttlv);
    % Convert to onsets
    onsets = localTimesToOnsets(onset2p, onsetst);

    % Check that the number found is correct
    if length(onsetst) ~= length(ml.ConditionNumber)
        if length(onset2p) - onsets(end) < 1.5*median(diff(onsets))
            disp(sprintf('Warning: the number of stimuli %i presented does not match the number recorded, %i. \nHowever, it appears that the stimulus just ran through the end so we will allow it through.', length(ml.ConditionNumber), length(onsetst)));
        else
            warndlg(sprintf(...
                'There is an error in the number of monkeylogic stimuli presented, %i, and the number detected by the nidaq card, %i.',...
                length(ml.ConditionNumber), length(onsetst)));
            return
        end
    end

    % Get the time onsets of licking, ensure, and quinine
    lickingt = sbxTTLOnsets(nidaq.data(:, ch.licking), nidaq.timeStamps, 0.050);
    ensuret = sbxTTLOnsets(nidaq.data(:, ch.ensure), nidaq.timeStamps, 0.050);
    quininet = sbxTTLOnsets(nidaq.data(:, ch.quinine), nidaq.timeStamps, 0.050);

    % Convert to trial onsets
    licking = localTimesToOnsets(onset2p, lickingt);
    ensure = trializeOnsets(onsets, localTimesToOnsets(onset2p, ensuret));
    quinine = trializeOnsets(onsets, localTimesToOnsets(onset2p, quininet));

    % Get key data from ML
    condition = uint8(ml.ConditionNumber);
    trialerror = uint8(ml.TrialError);

    % Save the types associated with each trial number
    codes = struct('pavlovian', 1, 'plus', 3, 'minus', 4, 'neutral', 5, 'blank', 6);

    % And save
    save(spath, 'onsets', 'licking', 'ensure', 'quinine', 'condition', 'trialerror', 'codes');

    out = struct('onsets', onsets, 'licking', licking, 'ensure', ensure, 'quinine', quinine, 'condition', condition, 'trialerror', trialerror, 'codes', codes);
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

function out = trializeOnsets(trial, stim)
    % Convert an array of quinine or ensure onsets to be within each trial
    if max(stim) < 2^16 - 1
        out = zeros(length(trial), 1, 'uint16');
    else
        out = zeros(length(trial), 1, 'uint32');
    end

    last = 1;
    for i=1:length(stim)
        last = (last - 1) + find(trial(last:end) > stim(i), 1);
        out(last-1) = stim(i);
    end
end