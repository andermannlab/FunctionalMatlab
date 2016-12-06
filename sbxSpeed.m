function speed = sbxSpeed(mouse, date, run)
%SBXSPEED Return the speed of a mouse running on a 3d printed wheel from
% date from the quadrature encoder
    
    speed = [];
    dirs = sbxDir(mouse, date, run);
    dirs = dirs.runs{1};
    
    if isempty(dirs.quad), return; end
    
    inf = sbxLoad(mouse, date, run, 'info');
    framerate = 30.98;
    if inf.scanmode == 0, framerate = framerate/2; end

    quadfile = load(dirs.quad);
    running = quadfile.quad_data;

    wheel_diameter = 14; % in cm
    wheel_tabs = 44; 
    wheel_circumference = wheel_diameter*pi;
    step_size = wheel_circumference/(wheel_tabs*2);

    instantaneous_speed = zeros(length(running), 1);
    if ~isempty(instantaneous_speed)
        instantaneous_speed(2:end) = diff(running);
        instantaneous_speed(2) = 0;
        instantaneous_speed = instantaneous_speed*step_size*framerate;
    end
    
    speed = conv(instantaneous_speed, ones(ceil(framerate), 1)/ceil(framerate), 'same')';
end

