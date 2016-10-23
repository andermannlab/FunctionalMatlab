function [out, varargout] = sbxLoad(mouse, date, run, type, varargin)
% SBXLOAD loads any type of important file of the scanbox format. Has
% minimal path assumptions, but depends on sbxDir.

    out = [];

    if nargin < 4
        disp('ERROR: Call with mouse, date, run, and type of file.');
        return
    end
    
    % Get the file path
    path = sbxPath(mouse, date, run, type);
    
    % Share the results
    if isempty(path)
        disp('WARNING: File not found');
        return;
    else
        %disp(sprintf('File type %s found at %s.', type, path));
    end
    
    dirsf = sbxDir(mouse, date, run);
    dirs = dirsf.runs{1};
    
    % Read the necessary filetypes differently
    switch type
        case 'sbx'
            out = sbxLoadSBX(mouse, date, run, varargin);
        case 'info'
            out = sbxInfo(path);
        case 'stim'
            f2p = load(path, '-mat');
            f2p = f2p.frame_2p_metadata;
            
            params = get_params_variable();
            out = get_Stim_Master_sbx(dirs, f2p, [], [], params);
        case 'bhv'
            out = bhv_read(dirs.ml);
        case 'ephys'
            inf = sbxInfo(dirs.sbx(1:end - 4));
            out = process_ephys_files(dirs.nidaq);
        otherwise
            if exist(path, 'file')
                out = load(path, '-mat');
            end
    end
end