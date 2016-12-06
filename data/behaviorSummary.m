function [orientations, success, codes, sz] = behaviorSummary(mouse, date, run, noprint)
%BEHAVIORSUMMARY summarizes the number of stimulus presentations of each
%   type and the mouse's success for each stimulus. Depends on
%   behaviorMovies

    % Recurse over all runs if necessary
    if nargin < 3, run = sbxRuns(mouse, date); end
    
    % Recurse if run is a vector
    if isvector(run) && length(run) > 1
        for j = 1:length(run)
            behaviorSummary(mouse, date, run(j));
        end
        return;
    end

    % Load monkeylogic file if possible
    ml = sbxLoad(mouse, date, run, 'bhv');
    if isempty(ml)
        return;
    end
    
    % Summarize the movies
    [orientations, codes, sz] = behaviorMovies(ml);
    
    % Write the orientation information to a string
    oridescription = ['Ori:   '];
    fields = fieldnames(orientations);
    for i = 1:length(fields)
        oridescription = [oridescription sprintf('%s:\t%5s\t', fields{i}, getfield(orientations, fields{i}))];
    end        
    
    % Find the trial conditions and error codes
    conditions = uint8(ml.ConditionNumber);
    trialerror = uint8(ml.TrialError);
    
    % Append the success rates
    success = struct();
    present = struct();
    for i = 1:length(conditions)
        trialname = getMatch(codes, conditions(i));
        if ~isfield(success, trialname), success = setfield(success, trialname, 0); end
        if ~isfield(present, trialname), present = setfield(present, trialname, 0); end
        
        present = setfield(present, trialname, getfield(present, trialname) + 1);
        if mod(trialerror(i), 2) == 0
            success = setfield(success, trialname, getfield(success, trialname) + 1);
        end
    end
    
    predescription = ['Shown: '];
    sucdescription = ['Perf:  '];
    for i = 1:length(fields)
        consuccess = getfield(success, fields{i});
        conpresent = getfield(present, fields{i});
        success = setfield(success, fields{i}, consuccess/conpresent);
        predescription = [predescription sprintf('%s:\t%5i\t', fields{i}, conpresent)];
        sucdescription = [sucdescription sprintf('%s:\t%3.1f\t', fields{i}, 100*getfield(success, fields{i}))];
    end
    
    % Calculating d'
    % Get hits
%    dphits = (success.pavlovian + success.plus)/(present.pavlovian + present.plus)
 %   (success.neutral + success.minus)/(present.neutral + present.minus)
%    dpfalsealarms = 1 - (success.neutral + success.minus)/(present.neutral + present.minus)
%    dp = norminv(dphits) - norminv(dpfalsealarms);
    dp = -1;
    
%   formulas: Stanislaw, H., & Todorov, N. (1999). Calculation of signal 
%   detection theory measures. Behavior research methods, instruments, & 
%   computers, 31(1), 137-149.
    
    % Display the output
    if nargin < 4 || ~noprint
        disp(sprintf('%s\t%s\tRun %i\t%.3f', date, mouse, run, dp));
        disp(oridescription);
        disp(predescription);
        disp(sucdescription);
    end
end

function match = getMatch(keyvals, intmatch)
    % Get the matching key from a struct in which str matches the val
    match = [];
    
    % Iterate over all members of the struct
    keys = fieldnames(keyvals);
    for ii = 1:length(keys)
        if sum(getfield(keyvals, keys{ii}) == intmatch)
            match = keys{ii};
        end
    end
end

