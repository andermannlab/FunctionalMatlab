function out = sbxLoad(mouse, date, run, type, varargin)
    if nargin < 4
        disp('Remember to call with mouse, date, run, and type of file.');
        return
    end

    % Load files from scanbox directories
    dirsf = sbxDir(mouse, date, run);
    dirs = dirsf.runs{1};
    params = get_params_variable();
    
    base = dirsf.scan_base;
    searchdir = sprintf('%s%s\\%s_%s\\%s_%s_run%i\\', base, mouse, date, ... 
        mouse, date, mouse, run);
    
    
    
    % Prepare for not finding the correct output
    out = [];
    
    if strcmp(type, 'sbx')
        if isempty(dirs.sbx)
            out = [];
            disp('Warning, sbx file not found.');
            return;
        end
        
        out = sbxLoadSBX(mouse, date, run, varargin);
    elseif strcmp(type, 'info')
        if isempty(dirs.sbx)
            out = [];
            disp('Warning, sbx file not found.');
            return;
        end
        
        out = sbxInfo(dirs.sbx(1:end - 4));
    elseif strcmp(type, 'stim')
        f2p = load([dirs.path '\' dirs.sbx_name '.f2p'], '-mat');
        f2p = f2p.frame_2p_metadata;
        stim = get_Stim_Master_sbx(dirs, f2p, [], [], params);
        out = stim;
    elseif strcmp(type, 'simpcell')
        out = load([dirsf.date_mouse '\' dirs.sbx_name '.simpcell'], '-mat');
    elseif strcmp(type, 'bhv')
        if ~isempty(dirs.ml)
            out = bhv_read(dirs.ml);
        else
            disp(sprintf('BHV file not found for %s on %s run %i', mouse, date, run));
        end
    elseif strcmp(type, 'oriim')
        path = sprintf('%s\\dFF_images\\%s_%s_run%i_ori_raw_30hz2_1pre2post.tif', dirs.path, date, mouse, run);
        try
            out = readtiff(path);
        catch Exception
            disp(sprintf('ERROR: File could not be found at %s', path));
        end
    elseif strcmp(type, 'ephys')
        if isempty(dirs.nidaq)
            disp(sprintf('Nidaq data not found for %s on %s run %i', mouse, date, run));
            return
        end
        
        global info
        load([dirs.nidaq(1:end - 6) '.mat']);
        
        if(info.scanmode==0)
            info.recordsPerBuffer = info.recordsPerBuffer*2;
        end

        switch info.channels
            case 1
                info.nchan = 2;      % both PMT0 & 1
                factor = 1;
            case 2
                info.nchan = 1;      % PMT 0
                factor = 2;
            case 3
                info.nchan = 1;      % PMT 1
                factor = 2;
        end
        
        if ~isempty(dirs.sbx)
            d = dir(dirs.sbx);
            info.max_idx =  d.bytes/info.recordsPerBuffer/info.sz(2)*factor/4 - 1;
        else
            if info.abort_bit > 0
                error('File was aborted, there is no sbx file, and the number of frames is unknown.');
            else
                info.max_idx = info.config.frames - 1;
            end
        end
        info.nsamples = (info.sz(2) * info.recordsPerBuffer * 2 * info.nchan);   % bytes per record 
        
        out = process_ephys_files(dirs.nidaq);
    else
        fs = dir(searchdir);
        if isempty(fs)
            disp(sprintf('Warning: mouse %s , date %s, run %i not found', mouse, date, run));
            return
        end

        path = '';

        for i=1:length(fs)
            [~, ~, ext] = fileparts(fs(i).name);
            if strcmp(ext, sprintf('.%s', type))
                path = sprintf('%s%s', searchdir, fs(i).name);
                disp(sprintf('Found file at %s', path));
            end
        end

        out = load(path, '-mat');
    end
end