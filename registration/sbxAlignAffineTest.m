
function sbxAlignAffineTest(mouse, date, runs, pmt)
%SBXALIGNAFFINETEST Save test images of affine alignment
    
    % --------------------------------
    imagen = 500;
    average = 100;
    % --------------------------------

    if nargin < 3, runs = sbxRuns(mouse, date); end
    if nargin < 4, pmt = 0; end
    
    out = [];
    for r = 1:length(runs)
        path = sbxPath(mouse, date, runs(r), 'sbx');
        info = sbxInfo(path);
        nframes = info.max_idx + 1;
        
        chunk = sbxAlignAffineChunk(mouse, date, runs(r), 1, imagen, pmt);
        out = cat(3, out, bint(chunk, average));
        
        chunk = sbxAlignAffineChunk(mouse, date, runs(r), nframes - (imagen - 1), imagen, pmt);
        out = cat(3, out, bint(chunk, average));
    end
    
    [rpath, ~] = fileparts(path);
    regpath = [fileparts(rpath) '\reg_affine\x-run-reg-test.tif'];
    writetiff(out, regpath, class(out));
end

