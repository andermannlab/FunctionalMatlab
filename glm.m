function out = glm(neuralsignal, relatedEvent, settings)

    % neuralsignal is times, cells

    out = struct;

    if nargin < 3
        settings.inputsamplerate = round(30.7692./3); % fps ./ ds_value
        settings.time = [-3000 3000]; % window of time to analyze
        settings.runstats = 1;
        settings.removeOnset = 0; % remove the first 20ms of the trial  if desired
    end

    if ~isfield(settings, 'inputsamplerate'), settings.inputsamplerate = 15.49; end
    if ~isfield(settings, 'runstats'), settings.runstats = 0; end
    if ~isfield(settings, 'time'), settings.time = [-250 500]; end
    if ~isfield(settings, 'removeOnset'), settings.removeOnset = 200; end

    thirdD = size(relatedEvent, 3);

    %%

    convFact  = settings.inputsamplerate./1000;
    nrTimeSamples = round(diff(settings.time.*convFact)) + 1;
    onsetSamplesRemove = ceil(settings.removeOnset.*convFact);
    neuralsignal(1:onsetSamplesRemove, :) = NaN;

    %% padding

    nrPadding = nrTimeSamples - onsetSamplesRemove;
    neuralsignal = cat(1, single(neuralsignal), NaN(nrPadding, size(neuralsignal, 2), 'single'));
    relatedEvent = cat(1, single(relatedEvent), zeros(nrPadding, size(neuralsignal, 2), thirdD, 'single'));

    %%

    neuralsignal = neuralsignal(:);
    nrDataSamples = length(neuralsignal);

    % create design matrix X
    for j = 1:thirdD
        X{j} = zeros(nrDataSamples + nrTimeSamples, nrTimeSamples, 'single');  %#ok<*AGROW>
        rEvent = reshape(relatedEvent(:,:,j), nrDataSamples, 1);

        for i = 1:nrTimeSamples
            X{j}(i:nrDataSamples-1+i,i) = rEvent;
        end

        X{j}(1:ceil(nrTimeSamples/2)-1,:) = [];
        X{j}(end-floor(nrTimeSamples/2):end,:) = [];
    end

    X = cat(2, X{:}, ones(nrDataSamples, 1, 'single'));

    %%

    remove = isnan(neuralsignal);
    X(remove, :) = []; % linear regression can't have NaN's in it, remove them all. That's good.
    neuralsignal(remove) = [];

    tic
    % thregress is my regression function.
    % if only beta is requested, funtion does nothing else but beta = X\neuralsignal;
    if settings.runstats == 0
        beta = thregress(single(X), single(neuralsignal)); % this is the all important line
    else
        [beta,F,p,Fcols,pCols] = thregress(single(X), single(neuralsignal)); % this is the all important line
    end

    out.timeRegression = toc;
    out.kernel = NaN(nrTimeSamples, thirdD);
    for j = 1:thirdD
        out.kernel(:, j) = beta((j-1)*nrTimeSamples+1:j*nrTimeSamples);
    end
    out.constant = beta(end);
    out.time = linspace(settings.time(1),settings.time(2),nrTimeSamples);

    if ~isempty(who('F'))
        Ninputs = size(out.kernel,2);
        out.F = reshape(F,length(F)/Ninputs,Ninputs);
        out.p = reshape(p,length(p)/Ninputs,Ninputs);
        out.Fcols = Fcols;
        out.pCols = pCols;
    end
end