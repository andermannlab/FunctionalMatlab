function status = alignInitialIDs(mouse, date, force)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
    
    status = 1;
    if nargin < 2
        dates = sbxDates(mouse);
        date = dates(1);
    end

    if ~ischar(date), date = num2str(date); end
    
    % You can force having a second initializing day for a mouse, but it
    % should be avoided if at all possible
    if nargin < 3, force = 0; end

    if alignIDsAlreadyCreated(mouse) > 0 && force == 0
        disp('ERROR: ID file has already been created. You must force creation of another.');
        status = 0;
        return
    end
    
    run = sbxRuns(mouse, date);
    run = run(1);
    
    if exist(sbxPath(mouse, date, run, 'simpcell'), 'file')
        sc = sbxLoad(mouse, date, run, 'simpcell');
        ncells = size(sc.dff, 1);
    else
        sig = sbxLoad(mouse, date, run, 'signals');
        ncells = length(sig.cellsort) - 1;
    end

    path = alignIDPath(mouse, date);
    fo = fopen(path, 'w');
    
    for i = 1:ncells
        fprintf(fo, '%s%03i\n', date, i);
    end
    
    fclose(fo);
end

