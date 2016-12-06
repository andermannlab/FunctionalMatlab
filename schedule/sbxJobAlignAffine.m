function sbxJobAlignAffine(mouse, date, runs, target, pmt, priority)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

    if nargin < 3, runs = sbxRuns(mouse, date); end
    if nargin < 4, target = []; end
    if nargin < 5, pmt = 0; end
    if nargin < 6 || isempty(priority), priority = 'medium'; end
    
    priority = lower(priority);
    savepriority = 'med';
    if length(priority) == 3
        if strcmp(priority(1:3), 'low'), savepriority = 'low'; end
    else
        if strcmp(priority(1:4), 'high'), savepriority = 'high'; end
    end
    
    job = 'alignaffine';
    time = timestamp();
    user = getenv('username');
    
    save(sprintf('%sjobdb\\activejobs\\priority_%s\\%s_%s_%s_%s_%s.mat', sbxScanbase(), ...
        savepriority, time, user, job, mouse, date), 'mouse', 'date', 'runs', 'job', ...
        'time', 'user', 'priority', 'target', 'pmt');
end

