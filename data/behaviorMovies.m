function [orientations, codes, sz] = behaviorMovies(ml)
%BEHAVIORMOVIES Summarize the blocks, movies, and timing files used given a
%   monkeylogic file. behaviorSummary depends on behaviorMovies

    % Translate weird timing file names into useful ones
    timing_translation = struct(...
        'pavlovian', 'Pavlovian_CSp_2s.m', ...
        'plus', 'CSp_cond_2s_end.m', ...
        'minus', 'CSm_cond_2s_end.m', ...
        'neutral', 'CSn_cond_2s_end.m', ...
        'blank', 'Blank_2s.m', ...
        'rewardedBlank', 'Blank_2s_reward.m', ...
        'monitorOff', 'monitorOff.m' ...
    );

    % Translate weird movie names into useful ones
    movie_shown = struct(...
        'fullframe0', 'Mov(CSp_primetime,0,0)', ...
        'fullframe135', 'Mov(CSn_primetime,0,0)', ...
        'fullframe270', 'Mov(CSm_primetime,0,0)', ...
        'monitorOff', 'pic(black_55,0,0)' ...
    );

    movie_size = struct(...
        'fullframe0', 'full-frame', ...
        'fullframe135', 'full-frame', ...
        'fullframe270', 'full-frame', ...
        'monitorOff', 'off' ...
    );

    movie_orientation = struct(...
        'fullframe0', '0', ...
        'fullframe135', '135', ...
        'fullframe270', '270', ...
        'monitorOff', 'off' ...
    );

    % Keep track of blocks used, codes used, and movies used
    blocks_used = unique(ml.ConditionNumber);
    codes = struct();
    movies = struct();
    
    % Search through all blocks, movies, and codes used to initially
    % describe the run. We will later go through the success of the animal
    for i=1:length(blocks_used)
        % Match the timing file
        blocktime = ml.TimingFileByCond(blocks_used(i));
        match = getMatch(timing_translation, blocktime);
        if isempty(match)
            disp('ERROR! Monkeylogic used unprepared timing file!');
            return
        end
        
        % Add to the codes field
        if ~isfield(codes, match)
            codes = setfield(codes, match, [blocks_used(i)]);
        else
            codes = setfield(codes, match, [getfield(codes, match) blocks_used(i)]);
        end
        
        % Find the name of the movie
        movname = ml.TaskObject(blocks_used(i));
        if strcmp(movname, 'pic(blank_55,0,0)')
            movname = ml.TaskObject(blocks_used(i), 2);
        end
        movname = movname{1};
        
        if ~isempty(movname)
            match = getMatch(movie_shown, movname);
            if isempty(match)
                disp(sprintf('ERROR! Monkeylogic played an unknown movie, %s!', movname));
                return
            end
            
            % Add to the movies field
            if ~isfield(movies, match)
                movies = setfield(movies, match, [blocks_used(i)]);
            else
                movies = setfield(movies, match, [getfield(movies, match) blocks_used(i)]);
            end
        end
    end
    
    % Set output
    sz = [];
    orientations = struct();
    
    % Now match codes with movies
    fields = fieldnames(codes);
    for i = 1:length(fields)
        code = getfield(codes, fields{i});
        match = getNumericMatch(movies, code);
        if isempty(match)
            orientations = setfield(orientations, fields{i}, 'none');
        else
            if isempty(sz)
                sz = getfield(movie_size, match);
            elseif ~strcmp(sz, getfield(movie_size, match))
                disp('Warning: movie sizes do not match!');
            end
            
            orientations = setfield(orientations, fields{i}, getfield(movie_orientation, match));
        end
    end
end

function match = getMatch(keyvals, strmatch)
    % Get the matching key from a struct in which str matches the val
    match = [];
    
    % Iterate over all members of the struct
    keys = fieldnames(keyvals);
    for ii = 1:length(keys)
        if strcmp(strmatch, getfield(keyvals, keys{ii}))
            match = keys{ii};
        end
    end
end

function match = getNumericMatch(keyvals, intmatch)
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