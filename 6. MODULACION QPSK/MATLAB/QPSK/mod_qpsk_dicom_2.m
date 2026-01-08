clc; clear; close all;

%% ===============================
% 1. LECTURA DE IMAGEN DICOM
%% ===============================
img = dicomread('ray-x-hearth.dcm');      % Imagen DICOM
img = mat2gray(img);                % Normalizar [0 1]
[fil, col] = size(img);

% Convertir imagen a bits
img_uint8 = uint8(img * 255);
bits_img = de2bi(img_uint8(:), 8, 'left-msb');
bits_tx = double(bits_img(:)');             % Vector de bits

Nmax = 10000;
if length(bits_tx) > Nmax
    bits_tx = bits_tx(1:Nmax);
end

N = length(bits_tx);                % Número total de bits

%% ===============================
% 2. PARÁMETROS DEL SISTEMA BPSK
%% ===============================
Rb = 1000;              % Tasa de bits
Tb = 1/Rb;
Fs = 100*Rb;            % Frecuencia de muestreo
fc = 2000;              % Portadora

t = 0:1/Fs:Tb-1/Fs;     % Duración de 1 bit

%% ===============================
% 3. MODULACIÓN BPSK
%% ===============================
% Mapeo BPSK: 0 -> -1, 1 -> +1
symbols = 2*bits_tx - 1;

carrier = cos(2*pi*fc*t);

x = [];
for k = 1:length(symbols)
    x = [x symbols(k)*carrier];
end

%% ===============================
% 4. CURVA BER vs SNR EN CANAL AWGN
%% ===============================
SNR_dB = 0:2:14;        % Valores de SNR a evaluar
BER = zeros(size(SNR_dB));

for i = 1:length(SNR_dB)
    % Canal AWGN
    y = awgn(x, SNR_dB(i), 'measured');
    
    % Reorganizar señal recibida
    y_mat = reshape(y, length(t), []);
    
    % Demodulación coherente
    r = sum(y_mat .* carrier', 1);
    
    % Detección de bits
    bits_hat = r > 0;
    
    % Cálculo de BER
    BER(i) = sum(bits_tx ~= bits_hat) / N;
end

% Calcular BER teórico para BPSK
% Para comparación: BER teórico de BPSK = Q(sqrt(2*SNR))
SNR_lin = 10.^(SNR_dB/10);
BER_theoretical = 0.5 * erfc(sqrt(SNR_lin));

% Graficar curva BER vs SNR
figure('Position', [100, 100, 800, 600]);
semilogy(SNR_dB, BER, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'BER Simulado');
hold on;
semilogy(SNR_dB, BER_theoretical, 'r--', 'LineWidth', 2, 'DisplayName', 'BER Teórico BPSK');
grid on;

% Destacar puntos de 5, 10 y 15 dB (si están en el rango)
SNR_highlight = [5, 10, 15];
for s = 1:length(SNR_highlight)
    if SNR_highlight(s) <= max(SNR_dB) && SNR_highlight(s) >= min(SNR_dB)
        idx = find(SNR_dB == SNR_highlight(s));
        if ~isempty(idx)
            semilogy(SNR_dB(idx), BER(idx), 'ks', ...
                     'MarkerSize', 12, 'LineWidth', 2, ...
                     'MarkerFaceColor', 'g', ...
                     'DisplayName', sprintf('SNR = %d dB', SNR_highlight(s)));
        end
    end
end

title('Curva BER vs SNR para Modulación BPSK', 'FontSize', 14);
xlabel('SNR (dB)', 'FontSize', 12);
ylabel('Bit Error Rate (BER)', 'FontSize', 12);
legend('Location', 'southwest', 'FontSize', 10);
xlim([min(SNR_dB), max(SNR_dB)]);

% Agregar cuadro de texto con información
info_str = sprintf('Parámetros:\nRb = %d bps\nFs = %d Hz\nfc = %d Hz\nN = %d bits', ...
                   Rb, Fs, fc, N);
annotation('textbox', [0.15, 0.75, 0.2, 0.1], ...
           'String', info_str, ...
           'FontSize', 9, ...
           'BackgroundColor', 'white', ...
           'EdgeColor', 'black');

%% ===============================
% 5. CONSTELACIÓN BPSK
%% ===============================
% Tomar una muestra de símbolos para la constelación
num_symbols_plot = min(1000, length(symbols));
idx_plot = randperm(length(symbols), num_symbols_plot);

figure('Position', [100, 100, 800, 400]);

subplot(1,2,1);
scatter(symbols(idx_plot), zeros(1, num_symbols_plot), 30, 'filled', 'b');
grid on;
axis([-1.5 1.5 -0.1 0.1]);
title('Constelación BPSK (Transmitida)', 'FontSize', 12);
xlabel('In-phase (I)', 'FontSize', 10);
ylabel('Quadrature (Q)', 'FontSize', 10);

% Constelación recibida para SNR = 10 dB como ejemplo
SNR_example = 10;
y_example = awgn(x, SNR_example, 'measured');
y_mat_example = reshape(y_example, length(t), []);
r_example = sum(y_mat_example .* carrier', 1);
symbols_rx = r_example ./ max(abs(r_example)); % Normalizar

subplot(1,2,2);
scatter(symbols_rx(idx_plot), zeros(1, num_symbols_plot), 30, 'filled', 'r');
grid on;
axis([-1.5 1.5 -0.1 0.1]);
title(sprintf('Constelación BPSK (Recibida, SNR = %d dB)', SNR_example), 'FontSize', 12);
xlabel('In-phase (I)', 'FontSize', 10);
ylabel('Quadrature (Q)', 'FontSize', 10);

%% ===============================
% 6. TABLA DE RESULTADOS PARA SNR ESPECÍFICOS
%% ===============================
SNR_specific = [5, 10, 15];
BER_specific = zeros(size(SNR_specific));

fprintf('\n=== RESULTADOS BER vs SNR PARA BPSK ===\n');
fprintf('SNR (dB)\tBER\t\tErrores\n');
fprintf('------------------------------------\n');

for s = 1:length(SNR_specific)
    if SNR_specific(s) <= max(SNR_dB) && SNR_specific(s) >= min(SNR_dB)
        % Encontrar el índice más cercano
        [~, idx] = min(abs(SNR_dB - SNR_specific(s)));
        BER_specific(s) = BER(idx);
        errores = round(BER_specific(s) * N);
        fprintf('%d\t\t%.4e\t%d/%d\n', ...
                SNR_specific(s), BER_specific(s), errores, N);
    else
        % Si no está en el rango, simular específicamente
        y_temp = awgn(x, SNR_specific(s), 'measured');
        y_mat_temp = reshape(y_temp, length(t), []);
        r_temp = sum(y_mat_temp .* carrier', 1);
        bits_hat_temp = r_temp > 0;
        BER_specific(s) = sum(bits_tx ~= bits_hat_temp) / N;
        errores = round(BER_specific(s) * N);
        fprintf('%d\t\t%.4e\t%d/%d\n', ...
                SNR_specific(s), BER_specific(s), errores, N);
    end
end

% Mostrar resultados en una figura
figure('Position', [100, 100, 600, 300]);
bar_data = [BER_specific; 0.5*erfc(sqrt(10.^(SNR_specific/10)))];
bar(SNR_specific, bar_data');
xlabel('SNR (dB)', 'FontSize', 12);
ylabel('BER', 'FontSize', 12);
title('Comparación BER para SNR específicos', 'FontSize', 12);
legend({'BER Simulado', 'BER Teórico'}, 'Location', 'northeast');
grid on;
set(gca, 'YScale', 'log');
ylim([1e-6, 1]);

%% ===============================
% 7. GRÁFICA ADICIONAL: SEÑAL EN TIEMPO
%% ===============================
figure('Position', [100, 100, 1000, 400]);

% Señal modulada (primeros 10 bits)
t_plot = (0:10*length(t)-1)/Fs;
x_plot = x(1:10*length(t));

subplot(2,1,1);
plot(t_plot*1000, x_plot, 'b', 'LineWidth', 1);
xlabel('Tiempo (ms)', 'FontSize', 10);
ylabel('Amplitud', 'FontSize', 10);
title('Señal BPSK Modulada (primeros 10 bits)', 'FontSize', 12);
grid on;

% Señal con ruido para SNR = 10 dB (primeros 10 bits)
y_plot = awgn(x_plot, 10, 'measured');

subplot(2,1,2);
plot(t_plot*1000, y_plot, 'r', 'LineWidth', 1);
xlabel('Tiempo (ms)', 'FontSize', 10);
ylabel('Amplitud', 'FontSize', 10);
title('Señal BPSK con Ruido (SNR = 10 dB)', 'FontSize', 12);
grid on;