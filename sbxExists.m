function tf = sbxExists(mouse, date, run)
%SBXEXISTS Check if mouse, optional date, and optional run exists

    tf = 0;
    if nargin < 1
        disp('ERROR: Requires at least mouse (optional date and run)');
        return
    end

    % Get the base path
    base = sbxScanbase();
    dirs.scan_base = base;

    % Check if mouse exists
    mousedir = sprintf('%s%s', base, mouse);
    if exist(mousedir) ~= 7, return; end
    
    if nargin >= 2
        mdd = sbxMouseDateDir(mouse, date);
        if isempty(mdd), return; end
        
        if nargin == 3
            rd = sbxRunDir(mouse, date, run);
            if isempty(rd), return; end
        end
    end
    
    tf = 1;
end

