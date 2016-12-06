function sbxJobMaster()
%SBXJOBMASTER Run all jobs that have been added with sbxJob

    scanbase = sbxScanbase();
    db = [scanbase 'jobdb\'];
    jobs = [db 'activejobs\'];
    
    user = getenv('username');
    time = timestamp();
    remaining_high = sbxJobMasterGetJobs([jobs 'priority_high']);
    remaining_med = sbxJobMasterGetJobs([jobs 'priority_med']);
    remaining_low = sbxJobMasterGetJobs([jobs 'priority_low']);
    remaining = length(remaining_high) + length(remaining_med) + length(remaining_low);
    
    % Check if another user is actively running
    if exist([db 'master.mat'], 'file')
        master = load([db 'master.mat']);
        
        if strcmp(master.user, user)
            delete([db 'master.mat']);
        else
            disp(sprintf(['Another user, %s, is already running the master. ' ...
                'It last checked in with %i remaining jobs at %s.'], master.user, ...
                master.remaining, master.time));
            return;
        end
    end
    
    save([db 'master.mat'], 'user', 'time', 'remaining');
    
    while remaining > 0
        % Get the next job
        if ~isempty(remaining_high)
            jobp = remaining_high(1);
        elseif ~isempty(remaining_med)
            jobp = remaining_med(1);
        else
            jobp = remaining_low(1);
        end
        jobp = jobp{1};
        
        % Open the job and move it to the active directory
        job = load(jobp);
        [~, fname, ~] = fileparts(jobp);
        movefile(jobp, [db 'now\' fname '.mat']);
        
        tic;
        switch job.job
            case 'preprocess'
                disp(sprintf('\n\n\n\n-----\nPreprocessing mouse %s on date %s', job.mouse, job.date));
                try 
                    sbxPreprocess(job.mouse, job.date, job.runs, job.target, job.pmt);
                    movefile([db 'now\' fname '.mat'], [db 'completedjobs\' fname '.mat']);
                catch
                    movefile([db 'now\' fname '.mat'], [db 'errorjobs\' fname '.mat']);
                    disp(['Error on job ' fname]);
                end
            case 'traces'
                disp(sprintf('\n\n\n\n-----\nExtracting traces from mouse %s on date %s', job.mouse, job.date));
                try 
                    sbxPullSignals(job.mouse, job.date, job.runs);
                    movefile([db 'now\' fname '.mat'], [db 'completedjobs\' fname '.mat']);
                catch
                    movefile([db 'now\' fname '.mat'], [db 'errorjobs\' fname '.mat']);
                    disp(['Error on job ' fname]);
                end
            case 'alignaffine'
                disp(sprintf('\n\n\n\n-----\nAffine aligning mouse %s on date %s', job.mouse, job.date));
                try 
                    sbxAlignAffine(job.mouse, job.date, job.runs, job.target, job.pmt);
                    movefile([db 'now\' fname '.mat'], [db 'completedjobs\' fname '.mat']);
                catch
                    movefile([db 'now\' fname '.mat'], [db 'errorjobs\' fname '.mat']);
                    disp(['Error on job ' fname]);
                end
        end
        joblength = toc;
        disp(sprintf('The job took %f minutes', joblength/60));
        close all;
            
        % Get the remaining jobs
        remaining_high = sbxJobMasterGetJobs([jobs 'priority_high']);
        remaining_med = sbxJobMasterGetJobs([jobs 'priority_med']);
        remaining_low = sbxJobMasterGetJobs([jobs 'priority_low']);
        remaining = length(remaining_high) + length(remaining_med) + length(remaining_low);
        time = timestamp();
        save([db 'master.mat'], 'user', 'time', 'remaining');
    end
    
    delete([db 'master.mat']);
end

