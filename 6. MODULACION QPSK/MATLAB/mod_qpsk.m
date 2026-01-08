clc; clear; close all;

% Parámetros
N = 2000;              % número de bits (par)
Rb = 1000;             % tasa de bits
Tb = 1/Rb;
Fs = 100*Rb;           % frecuencia de muestreo
fc = 2000;             % frecuencia portadora

t = 0:1/Fs:2*Tb-1/Fs;  % duración de símbolo (2 bits)

% Generación de bits
bits = randi([0 1], 1, N);

% Agrupar bits de dos en dos
bits_reshape = reshape(bits, 2, []);

% Mapeo QPSK (Gray)
I = 2*bits_reshape(1,:) - 1;
Q = 2*bits_reshape(2,:) - 1;

% Portadoras
carrier_I = cos(2*pi*fc*t);
carrier_Q = sin(2*pi*fc*t);

% Modulación QPSK
x = [];
for k = 1:length(I)
    x = [x I(k)*carrier_I - Q(k)*carrier_Q];
end

% Señal modulada
figure;
plot(x(1:2000));
title('Señal QPSK (primeros símbolos)');
xlabel('Muestras');
ylabel('Amplitud');

%% 4.2 Canal AWGN y Demodulación Coherente
EbN0_dB = 0:2:12;
BER = zeros(size(EbN0_dB));

for i = 1:length(EbN0_dB)

    % Canal AWGN
    y = awgn(x, EbN0_dB(i), 'measured');

    % Reorganizar señal recibida
    y_mat = reshape(y, length(t), []);

    % Demodulación coherente
    I_hat = sum(y_mat .* carrier_I', 1);
    Q_hat = -sum(y_mat .* carrier_Q', 1);

    % Decisiones
    bits_I = I_hat > 0;
    bits_Q = Q_hat > 0;

    bits_hat = reshape([bits_I; bits_Q], 1, []);

    % BER
    BER(i) = sum(bits ~= bits_hat) / N;
end

% Curva BER
figure;
semilogy(EbN0_dB, BER, '-o');
grid on;
title('Curva BER de QPSK en canal AWGN');
xlabel('Eb/N0 (dB)');
ylabel('BER');

%% 4.3 Diagrama de Constelación QPSK
figure;
scatter(I, Q, 'filled');
grid on;
axis equal;
title('Constelación QPSK');
xlabel('In-phase (I)');
ylabel('Quadrature (Q)');
