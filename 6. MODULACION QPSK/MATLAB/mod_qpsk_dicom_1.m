clc; clear; close all;

%% ===============================
% 1. LECTURA DE IMAGEN DICOM
%% ===============================
img = dicomread('ray-x-hearth.dcm');
img = mat2gray(img);
[fil, col] = size(img);

% Convertir imagen a bits
img_uint8 = uint8(img * 255);
bits_img = de2bi(img_uint8(:), 8, 'left-msb');
bits_tx = double(bits_img(:)');

% Limitar número de bits
Nmax = 10000;
if length(bits_tx) > Nmax
    bits_tx = bits_tx(1:Nmax);
end
N = length(bits_tx);

%% ===============================
% 2. PARÁMETROS DEL SISTEMA BPSK
%% ===============================
Rb = 1000;
Tb = 1/Rb;
Fs = 100*Rb;
fc = 2000;

t = 0:1/Fs:Tb-1/Fs;

%% ===============================
% 3. MODULACIÓN BPSK
%% ===============================
symbols = 2*bits_tx - 1;
carrier = cos(2*pi*fc*t);

% Modulación (vectorizada)
x = kron(symbols, carrier);

%% ===============================
% 4. CURVA BER EN CANAL AWGN
%% ===============================
EbN0_dB = 0:2:14;
BER = zeros(size(EbN0_dB));

for i = 1:length(EbN0_dB)

    % Canal AWGN
    y = awgn(x, EbN0_dB(i), 'measured');
    y_mat = reshape(y, length(t), []);

    % Demodulación coherente
    r = sum(y_mat .* carrier', 1);
    bits_hat = r > 0;

    % BER
    BER(i) = sum(bits_tx ~= bits_hat) / N;
end

%% ===============================
% 5. CONSTELACIÓN BPSK
%% ===============================
figure;
scatter(symbols, zeros(size(symbols)), 'filled');
grid on; axis equal;
xlabel('In-phase');
ylabel('Quadrature');
title('Constelación BPSK');

%% ===============================
% 6. ANÁLISIS POR SNR (SIN PLOTEO DE IMÁGENES)
%% ===============================
SNR_values = [5 10 15];

for s = 1:length(SNR_values)

    % Canal AWGN
    y = awgn(x, SNR_values(s), 'measured');
    y_mat = reshape(y, length(t), []);

    % Demodulación
    r = sum(y_mat .* carrier', 1);
    bits_rx = r > 0;

    % Reconstrucción parcial (NO se grafica)
    bits_rx = bits_rx(1:N);
    img_rx_bits = reshape(bits_rx, [], 8);
    img_rx_uint8 = uint8(bi2de(img_rx_bits, 'left-msb'));

end

%% ===============================
% 7. GRÁFICA BER VS SNR
%% ===============================
figure;
semilogy(EbN0_dB, BER, '-o','LineWidth',1.5);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('Curva BER vs SNR para modulación BPSK en canal AWGN');
