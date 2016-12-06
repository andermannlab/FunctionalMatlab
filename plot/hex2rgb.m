function rgb = hex2rgb(hex)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

    rgb = zeros(3, 1);
    if length(hex) == 6
        r = hex2dec(hex(1:2));
        g = hex2dec(hex(3:4));
        b = hex2dec(hex(5:6));
    elseif length(hex) == 7
        r = hex2dec(hex(2:3));
        g = hex2dec(hex(4:5));
        b = hex2dec(hex(6:7));
    end

    rgb(1) = r/255;
    rgb(2) = g/255;
    rgb(3) = b/255;
end

