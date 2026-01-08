clc; clear all, close all;

% Parámetros
N = 1000;          % número de bits
Rb = 1000;         % tasa de bits (bps)
Tb = 1/Rb;         % tiempo de bit
Fs = 100*Rb;       % frecuencia de muestreo
t = 0:1/Fs:Tb-1/Fs;

% Generar bits aleatorios
bits = randi([0 1], 1, N);

% Mapeo BPSK: 0 → -1, 1 → +1
symbols = 2*bits - 1;

% Portadora
fc = 2000;
carrier = cos(2*pi*fc*t);

% Modulación BPSK
x = [];
for k = 1:N
    x = [x symbols(k)*carrier];
end

% Graficar señal modulada
figure;
plot(x(1:2000));
title('Señal BPSK (primeros bits)');
xlabel('Muestras');
ylabel('Amplitud');

EbN0_dB = 0:2:12;
BER = zeros(size(EbN0_dB));

for i = 1:length(EbN0_dB)

    % Canal AWGN
    y = awgn(x, EbN0_dB(i), 'measured');

    % Reorganizar señal
    y_reshaped = reshape(y, length(t), N);

    % Demodulación coherente (correlador)
    decision = sum(y_reshaped .* carrier', 1);

    % Decisión
    bits_hat = decision > 0;

        % Cálculo de BER
    BER(i) = sum(bits ~= bits_hat)/N;
end

% Curva BER
figure;
semilogy(EbN0_dB, BER, '-o');
grid on;

title('Curva BER de BPSK en canal AWGN');
xlabel('Eb/N0 (dB)');
ylabel('BER');

figure;
scatter(symbols, zeros(1,N), 'filled');
grid on;
title('Constelación BPSK');
xlabel('In-phase');
ylabel('Quadrature');
