function out = sbxLoadSBX(mouse, date, run, varargin)
%UNTITLED14 Summary of this function goes here
%   Detailed explanation goes here

    dirsf = sbxDir(mouse, date, run);
    dirs = dirsf.runs{1};
    
    if nargin >= 4, varargin = varargin{1}; end

    if isempty(dirs.sbx)
        out = [];
        disp('Warning, sbx file not found.');
        return;
    end
    
    align_path = [dirs.sbx(1:end - 4) '.align'];
    if exist(align_path)
        if nargin == 3
            out = sbxReadReg(dirs.sbx, 1, 1, 1, 1);
        elseif length(varargin) == 1
            out = sbxReadReg(dirs.sbx, varargin{1});
        elseif length(varargin) == 2
            out = sbxReadReg(dirs.sbx, varargin{1}, varargin{2});
        elseif length(varargin) == 3
            out = sbxReadReg(dirs.sbx, varargin{1}, varargin{2}, varargin{3});
        elseif length(varargin) == 4
            out = sbxReadReg(dirs.sbx, varargin{1}, varargin{2}, varargin{3}, varargin{4});
        end
    else
        disp('Warning: not yet aligned.');
        if nargin == 3 || (nargin == 4 && isempty(varargin))
            out = sbxReadPMT(dirs.sbx, 1, 1, 1, 1);
        elseif length(varargin) == 1
            out = sbxReadPMT(dirs.sbx, varargin{1});
        elseif length(varargin) == 2
            out = sbxReadPMT(dirs.sbx, varargin{1}, varargin{2});
        elseif length(varargin) == 3
            out = sbxReadPMT(dirs.sbx, varargin{1}, varargin{2}, varargin{3});
        elseif length(varargin) == 4
            out = sbxReadPMT(dirs.sbx, varargin{1}, varargin{2}, varargin{3}, varargin{4});
        end
    end

end

