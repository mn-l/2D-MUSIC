function received_data = receive_data_simulation(params, delays, angles)

    f_sub = params.Bandwidth / params.N_subcarriers;  % 子载波间隔频率
    delta_f_list = (0:params.N_subcarriers-1)' * f_sub;  % 根据子载波间隔频率计算序列
    
    d = params.antenna_distance * params.lambda;
    delta_d_list = (0:d:(params.N_Tx - 1) * d)'; 
    theta = angles * pi / 180;
    
    transmitted_data = randn(1, params.packet_length);
    signal_from_paths = zeros(params.N_subcarriers, params.N_Tx, params.packet_length, params.N_signals);

    for i = 1:params.N_signals
        %tof
        tof = delta_f_list * delays(i);
        %aoa
        aoa = delta_d_list * sin(theta(i)') / params.lambda;
        
        %merge
        tmp1 = exp(-1i * 2 * pi * tof);
        tmp2 = exp(-1i * 2 * pi * aoa);
        tmp = zeros(params.N_subcarriers, params.N_Tx, params.packet_length);
        for j = 1:params.packet_length
            tmp(:, :, j) = tmp1 * tmp2' * transmitted_data(j);
        end
        tmp = awgn(tmp, params.SNR, "measured");
        signal_from_paths(:, :, :, i) = tmp;
        if i ~= 1
            signal_from_paths = signal_from_paths * 0.3;
        end
    end
    received_data = sum(signal_from_paths, 4);
    

    %Add path delay

    t_pdd = (100e-9 - 10e-9).*rand + 10e-9;
    t_pdd = 0;

    for i = 1:params.N_subcarriers
        received_data(i, :, :) = exp(-1i * 2 * pi * delta_f_list(i) * t_pdd) * received_data(i, :, :);
    end

end


