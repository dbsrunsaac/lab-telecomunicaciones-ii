clc; clear; close all;
N = 20; % Número de bits
Rb = 1000; % Tasa de bits
fc = 10e3; % Frecuencia de portadora
fs = 100e3; % Frecuencia de muestreo

% Generar señal binaria
data = randi([0 1], 1, N);
t = 0:1/fs:N/Rb - 1/fs;
b = repelem(data, fs/Rb);
% Señal portadora
carrier = cos(2*pi*fc*t);
% Modulación ASK
ask = b .* carrier;
% Graficar
subplot(3,1,1); stairs(data); title('Datos binarios');
subplot(3,1,2); plot(t, ask); title('Señal ASK');
subplot(3,1,3); pwelch(ask,[],[],[],fs,'twosided');
title('Espectro de ASK');
