function dirs = sbxDir(mouse, date, runs, target)
% Set pathnames for scanbox for easy access

% If date is an integer, convert to string
if ~ischar(date), date = num2str(date); end

% If runs are not set, get all runs from the day
% If runs are set, check if runs is integer, if so, set to array
if nargin < 3
    runs = sbxRuns(mouse, date);
elseif isinteger(runs)
    runs = [runs];
end

% Set target to first run if unset
if nargin < 4
    target = runs(1);
end

base = sbxScanbase();
dirs.scan_base = base;

% Set the information outside of runs
dirs.mouse = sprintf('%s%s', base, mouse);
dirs.date_mouse = sbxMouseDateDir(mouse, date);

if isempty(dirs.date_mouse)
    msgID = 'SBXDIR:BadMouseNameDate';
    msg = 'Mouse and date not found.';
    baseException = MException(msgID, msg);
    throw(baseException);
end

if isempty(runs)
    msgID = 'SBXDIR:BadRun';
    msg = 'No runs found for mouse and date.';
    baseException = MException(msgID, msg);
    throw(baseException);
end

% Set the information per run
for i = 1:length(runs)
    % run.path path to run directory
    dirs.runs{i}.path = sbxRunDir(mouse, date, runs(i));
    
    % run.number is the integer number for the run
    dirs.runs{i}.number = runs(i);
    
    %run.date_mouse_run
    date_mouse_run = sbxRunDir(mouse, date, runs(i));
    slashes = strfind(date_mouse_run, '\');
    if isempty(slashes)
        dirs.runs{i}.date_mouse_run = [];
    else
        dirs.runs{i}.date_mouse_run = date_mouse_run(slashes(end-1)+1:end-1);
    end
    
    %run.sbx 2p file and filename without file extension or path
    sbxname = dir(sprintf('%s*.sbx', dirs.runs{i}.path));
    if ~isempty(sbxname)
        if length(sbxname) > 1
            minlen = -1;
            minpos = -1;
            for s = 1:length(sbxname)
                if minpos == -1 || length(sbxname(s).name) < minlen
                    minlen = length(sbxname(s).name);
                    minpos = s;
                end
            end
            sbxname = sbxname(minpos);
        end
        
        dirs.runs{i}.sbx = sprintf('%s%s', dirs.runs{i}.path, sbxname.name);
        dirs.runs{i}.sbx_name = sbxname.name(1:end-4);
    
        % run.base is the basename of files without any .
        dirs.runs{i}.base = sprintf('%s%s', dirs.runs{i}.path, sbxname.name(1:end-4));
    else
        dirs.runs{i}.sbx = [];
        dirs.runs{i}.sbx_name = [];
        dirs.runs{i}.base = [];
    end
    
    %run.nidaq and run.ephys (.ephys file from 2p or .nidaq .mat file)
    nidname = dir(sprintf('%s*.nidaq', dirs.runs{i}.path));
    ephname = dir(sprintf('%s*.ephys', dirs.runs{i}.path));
    if ~isempty(ephname)
        dirs.runs{i}.nidaq = sprintf('%s%s', dirs.runs{i}.path, ephname.name);
    elseif ~isempty(nidname)
        dirs.runs{i}.nidaq = sprintf('%s%s', dirs.runs{i}.path, nidname.name);
    else
        dirs.runs{i}.nidaq = [];
    end
    
    %runs.ptb (psychtoolbox .mat file coded as .ptb)
    ptbname = dir(sprintf('%s*.ptb', dirs.runs{i}.path));
    if ~isempty(ptbname)
        dirs.runs{i}.ptb = sprintf('%s%s', dirs.runs{i}.path, ptbname.name);
    else
        dirs.runs{i}.ptb = [];
    end
    
    %runs.ml (monkeylogic bhv file)
    mlname = dir(sprintf('%s*.bhv', dirs.runs{i}.path));
    if ~isempty(mlname)
        dirs.runs{i}.ml = sprintf('%s%s', dirs.runs{i}.path, mlname.name);
    else
        dirs.runs{i}.ml = [];
    end
    
    %runs.quad is running encoder, saved as .quad although not quadrature
    quadname = dir(sprintf('%s*quadrature*.mat', dirs.runs{i}.path));
    if ~isempty(quadname)
        dirs.runs{i}.quad = sprintf('%s%s', dirs.runs{i}.path, quadname.name);
    else
        dirs.runs{i}.quad = [];
    end
    
    %runs.target is a target file for registration
    if isempty(target)
        dirs.runs{i}.target = [];
    else
        tarname = dir(sprintf('%s*.sbx', sbxRunDir(mouse, date, target)));
        if ~isempty(tarname)
            dirs.runs{i}.target = sprintf('%s%s', dirs.runs{i}.path, tarname.name);
        else
            dirs.runs{i}.target = [];
        end
    end
end



