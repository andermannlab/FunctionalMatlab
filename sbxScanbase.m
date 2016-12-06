function base = sbxScanbase()
%SBXSCANBASE Hard codes directories

    % Set base path depending on server
    if strcmp(hostname, 'Megatron')
        base = 'D:\twophoton_data\2photon\scan\';
    elseif strcmp(hostname, 'Atlas')
        base = 'E:\twophoton_data\2photon\raw\';
    elseif strcmp(hostname, 'BeastMode')
        base = 'S:\twophoton_data\2photon\scan\';
    elseif strcmp(hostname, 'Sweetness')
        base = 'D:\2p_data\scan\';
    end
end

