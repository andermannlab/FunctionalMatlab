function sbxPullSignals(mouse, date, runs, use_cleaned)
%SBXPULLSIGNALS After an icamasks file has been created, pull signals and 
%   run simplifycellsort

    % Usually run on all runs in a single folder with the first as a target
    if nargin < 3, runs = sbxRuns(mouse, date); end
    if nargin < 4, target = runs(1); end
    if nargin < 5, use_cleaned = true; end
    
    % Get the necessary directories
    dir = sbxDir(mouse, date, runs);
    %ica = sprintf('%s.ica', dir.runs{end}.sbx(1:end-4));
    icamasks = sprintf('%s.icamasks', dir.runs{end}.sbx(1:end-4));
    
    % Load in necessary files
    %load(ica, '-mat');
    load(icamasks, '-mat');

    % Get masks and pull signals
    for i = 1:length(runs)
        run = runs(i);
        disp(sprintf('Pulling signals from run %03i', run));
        
        % Check if signals file already exists
        sigfile = sprintf('%s.signals', dir.runs{i}.sbx(1:end-4));
        if ~exist(sigfile)
            path = sbxPath(mouse, date, run, 'sbx');
            info = sbxInfo(path);
            if info.scanmode == 0, freq = 30.98; else freq = 15.49; end
            
            cleanpath = sbxPath(mouse, date, run, 'clean');
            if isempty(cleanpath) || ~use_cleaned
                disp('Using uncleaned data');
                
                useaffine = true;
                alpath = [path(1:end-4) '.align'];
                afpath = [path(1:end-4) '.alignaffine'];
                if ~exist(afpath, 'file') && exist(alpath, 'file'), useaffine = false; end
                if str2num(date) < 161022, useaffine = false; end
                if str2num(date) == 161017, useaffine = true; end
                if str2num(date) == 161021, useaffine = true; end
                if isfield(icaguidata, 'alignment_type') && strcmp(icaguidata.alignment_type, 'affine')
                    useaffine = true;
                end
                
                if useaffine
                    cellsort = sbxPullSignalsCoreUncleaned(path, icaguidata);
                else
                    cellsort = sbxPullSignalsCoreDFT(path, icaguidata);
                end
            else
                disp('Using PCA cleaned data');
                cellsort = sbxPullSignalsCore(cleanpath, icaguidata);
            end

            % Remove those ROI with signal in neuropil that matches signal in ROI
            cellsort = sbxPullSignalsCoreCheckNeuropilCorrelation(cellsort);

            % GET DFF Traces
            cellsort = sbxPullSignalsCoreDFF(cellsort, freq);
            
            % Save signals in DFF values
            save(sigfile, 'cellsort', '-v7.3');
        end

        % Save a simplified data
        simplifycellsort(mouse, date, run)
    end
end

