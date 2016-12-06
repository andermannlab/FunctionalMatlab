function cellsort = sbxPullSignalsCoreDFF(cellsort, fps)

    fr_number = length(cellsort(1).timecourse.raw);
    nROIs = size(cellsort,2);

    %% Now calculate dFF using axon method

    % Calculate f0 for each timecourse using a moving window of time window
    % prior to each frame
    f0_vector = zeros(nROIs, fr_number);
    time_window = 32; % moving window of X seconds - calculate f0 at time window prior to each frame - used to be 32
    percentile = 10; % used to be 30
    time_window_frame = round(time_window*fps);

    % create temporary traces variable that allows you to do the prctile
    % quickly
    traces_f = nan(nROIs,length(cellsort(1).timecourse.subtracted));
    for curr_ROI = 1:nROIs
        traces_f(curr_ROI,:) = cellsort(curr_ROI).timecourse.subtracted;
    end

    openParallel();
    pool_siz = 8;

    % how many ROIs per core
    nROIs_per_core = ceil(nROIs/pool_siz);
    ROI_vec = 1:nROIs_per_core.*pool_siz;
    ROI_blocks = unshuffle_array(ROI_vec,nROIs_per_core);
    ROI_start_points = ROI_blocks(:,1);   
    parfor curr_ROI_ind = 1:pool_siz
        ROIs_to_use = ROI_blocks(curr_ROI_ind,:)
        ROIs_to_use(ROIs_to_use > nROIs) = [];
        % pre-allocate
        f0_vector_cell{curr_ROI_ind} = nan(length(ROIs_to_use),fr_number);
        for i = 1:fr_number
            if i <= time_window_frame
                frames = traces_f(ROIs_to_use,1:time_window_frame);
                f0 = prctile(frames,percentile,2);
            else
                frames = traces_f(ROIs_to_use,i - time_window_frame:i-1);
                f0 = prctile(frames,percentile,2);
            end
            f0_vector_cell{curr_ROI_ind}(:,i) = f0;
        end
    end

    % Reshape into correct structure
    for curr_ROI_ind = 1:pool_siz
        ROIs_to_use = ROI_blocks(curr_ROI_ind,:);
        ROIs_to_use(ROIs_to_use > nROIs) = [];
        f0_vector(ROIs_to_use,:) = f0_vector_cell{curr_ROI_ind};
    end

    traces_dff = (traces_f-f0_vector)./ f0_vector;

    % Stick back into cellsort variable
    for curr_ROI = 1:nROIs
        cellsort(curr_ROI).timecourse.f0_axon = f0_vector(curr_ROI,:);
        cellsort(curr_ROI).timecourse.dff_axon = traces_dff(curr_ROI,:);
        cellsort(curr_ROI).timecourse.dff_axon_norm = cellsort(curr_ROI).timecourse.dff_axon ./ max(cellsort(curr_ROI).timecourse.dff_axon);
    end    
end

