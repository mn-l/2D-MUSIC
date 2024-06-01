function music_2d(received_data, params)
    % 计算协方差矩阵
    R = (received_data * received_data') / size(received_data, 2);

    % 特征值分解
    [E, D] = eig(R);
    eigenvalues = diag(D);
    [~, index] = sort(eigenvalues, 'descend');
    E = E(:, index);    

    % 分离噪声子空间
    if size(E, 2) < params.N_signals
        error('特征值/特征向量不足以分离信号和噪声子空间。');
    end
    noise_subspace = E(:, params.N_signals+1:end);

    % Setup parameters for phi and tau
    phi_list = linspace(-pi/2, pi/2, params.search_space_aoa)'; % aoa   [1000*1]
    tau_list = linspace(-5e-8, 5e-8, params.search_space_tof)'; % tof   [1000*1] 

    % phi_list = [pi/4]; % aoa   [1000*1] 
    
    [Phi, Tau] = meshgrid(phi_list, tau_list); 
    Phi = reshape(Phi, numel(Phi), 1); 
    Tau = reshape(Tau, numel(Tau), 1); %aoa [10e6*1] tof [10e6*1]

    d = params.antenna_distance * params.lambda;
    f_sub = params.Bandwidth / params.N_subcarriers;  % 子载波间隔频率
    delta_d_list = (0:d:(params.N_Tx - 1) * d)';  % [4*1]
    delta_f_list = (0:params.N_subcarriers-1)' * f_sub;   % [64*1]
    [d_list, f_list] = meshgrid(delta_d_list, delta_f_list);
    d_list = reshape(d_list, numel(d_list), 1); % [256*1]
    f_list = reshape(f_list, numel(f_list), 1); % [256*1]

    % Calculate Omega_tau matrix for 2D search over phi and tau
    aoa = d_list .* sin(Phi') / params.lambda; % 【256*1e6】
    % disp(aoa);
    tof = f_list .* Tau';
    Omega_tau = exp(1i * 2 * pi * (aoa - tof));
    sv_projection = abs(noise_subspace' * Omega_tau).^2;
    P_music = 1 ./ sum(sv_projection);
    P_MUSIC_max = max(P_music);
    P_MUSIC_dB = 10*log10(P_music/P_MUSIC_max);
    P_MUSIC_dB=P_music;
    P_music = reshape(P_MUSIC_dB, params.search_space_tof, params.search_space_aoa); 

    % 绘制热力图
    figure; % 创建新的图形窗口
    imagesc(phi_list*180/pi, tau_list*3e8, P_music); % 转置矩阵并转换为 dB 单位
    colorbar; % 显示颜色条
    xlabel('Angle (degrees)'); % x轴标签
    ylabel('Path Length (meters)'); % y轴标签
    title('P_{MUSIC} Spectral Density'); % 标题

    % 设置坐标轴以匹配 phi_list 和 tau_list 的范围
    set(gca, 'YDir', 'normal'); % 确保 Y 轴的方向是从低到高
    axis tight; % 调整坐标轴以紧密包围数据

    % 使用 islocalmax 寻找局部最大值
    local_max = islocalmax(P_music, 1) & islocalmax(P_music, 2);
    [peak_rows, peak_cols] = find(local_max);
    
    % 提取这些局部最大值对应的值
    peak_values = P_music(local_max);
    
    % 排序并提取最大的 params.N_signals 个峰值
    [~, sorted_indices] = sort(peak_values, 'descend');
    peak_rows = peak_rows(sorted_indices(1:params.N_signals));
    peak_cols = peak_cols(sorted_indices(1:params.N_signals));

    % 初始化输出变量
    peak_angles = zeros(params.N_signals, 1);
    peak_distances = zeros(params.N_signals, 1);

    % 在图中标注峰值
    hold on;
    for k = 1:params.N_signals
        angle = phi_list(peak_cols(k)) * 180 / pi;
        distance = tau_list(peak_rows(k)) * 3e8;
        peak_angles(k) = angle;
        peak_distances(k) = distance;

        plot(angle, distance, 'r.', 'MarkerSize', 15, 'LineWidth', 2);
    end
    hold off;

    % 输出角度和距离
    disp('Found peaks:');
    for k = 1:params.N_signals
        fprintf('Peak %d: Angle = %.2f degrees, Path Length = %.2f meters\n', k, peak_angles(k), peak_distances(k));
    end
end
