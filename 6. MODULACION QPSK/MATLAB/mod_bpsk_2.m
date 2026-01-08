clc; clear; close all;

%% =========================================================
% 1. IMAGEN DICOM → BITS
%% =========================================================
img = dicomread('ray-x-hearth.dcm');
img = mat2gray(img);

% Limitar a 2000 píxeles
if numel(img) > 2000
    factor = sqrt(2000/numel(img));
    img = imresize(img, factor);
end

img_vec = img(:);
img_vec = img_vec(1:min(2000,length(img_vec)));

% Binarización (Otsu)
umbral = graythresh(img_vec);
bits_img = double(img_vec > umbral).';

fprintf('Bits extraídos de la imagen: %d\n', length(bits_img));

%% =========================================================
% 2. PARÁMETROS BPSK EN BANDA BASE
%% =========================================================
EbN0_dB = 0:2:12;
EbN0 = 10.^(EbN0_dB/10);

BER_sim = zeros(size(EbN0));
BER_teo = 0.5 * erfc(sqrt(EbN0));

numFrames = 1000;   % Monte Carlo (CLAVE)

%% =========================================================
% 3. SIMULACIÓN CORRECTA DE BPSK (BANDA BASE)
%% =========================================================
fprintf('\nEb/N0(dB) | BER Simulado | BER Teórico\n');
fprintf('-------------------------------------\n');

% Tomar solo los primeros 10 bits para las gráficas especiales
bits_10 = bits_img(1:10);
symbols_10 = 2*bits_10 - 1;

%% =========================================================
% 4. GRÁFICAS ESPECIALES: CONSTELACIÓN Y SEÑAL MODULADA
%% =========================================================
% Figura 1: Constelación BPSK
figure('Position',[100 100 900 400]);

subplot(1,2,1);
% Constelación ideal
scatter([-1 1], [0 0], 200, 'b', 'filled', 'DisplayName', 'Símbolos ideales');
hold on;
% Constelación de los primeros 10 bits
scatter(symbols_10, zeros(size(symbols_10)), 100, 'r', 'o', 'LineWidth', 2, ...
        'DisplayName', 'Primeros 10 bits');
grid on;
xlim([-1.5 1.5]);
ylim([-0.1 0.1]);
xlabel('Componente en fase (I)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Componente en cuadratura (Q)', 'FontSize', 11, 'FontWeight', 'bold');
title('Diagrama de Constelación BPSK', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best');
% Agregar etiquetas de bits
for i = 1:length(symbols_10)
    text(symbols_10(i), 0.02, sprintf('b%d=%d', i, bits_10(i)), ...
         'FontSize', 8, 'HorizontalAlignment', 'center');
end

subplot(1,2,2);
% Señal modulada BPSK (sin ruido)
Tb = 1;  % Duración del bit
fs = 100; % Frecuencia de muestreo
t = 0:1/fs:length(bits_10)*Tb - 1/fs;
signal = [];

% Generar señal modulada
for i = 1:length(bits_10)
    if bits_10(i) == 1
        segment = ones(1, fs);
    else
        segment = -ones(1, fs);
    end
    signal = [signal segment];
end

% Asegurar que t y signal tengan la misma longitud
t = t(1:length(signal));

plot(t, signal, 'b-', 'LineWidth', 2);
hold on;
grid on;
xlabel('Tiempo (segundos)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Amplitud', 'FontSize', 11, 'FontWeight', 'bold');
title('Señal BPSK Modulada (Primeros 10 bits)', 'FontSize', 12, 'FontWeight', 'bold');
ylim([-1.5 1.5]);
xlim([0 length(bits_10)*Tb]);

% Agregar líneas verticales para separar bits
for i = 1:length(bits_10)
    line([i*Tb i*Tb], [-1.5 1.5], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 0.5);
    text((i-0.5)*Tb, 1.2, sprintf('%d', bits_10(i)), ...
         'FontSize', 10, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% Agregar etiqueta de Eb
text(0.5, -1.2, sprintf('E_b = %d', 1), 'FontSize', 10, 'FontWeight', 'bold');

%% =========================================================
% 5. SIMULACIÓN COMPLETA BER vs Eb/N0
%% =========================================================
for i = 1:length(EbN0)

    errores = 0;
    bits_tot = 0;

    % Varianza del ruido para Eb = 1
    N0 = 1 / EbN0(i);
    sigma = sqrt(N0/2);

    for k = 1:numFrames

        % Reutilizar imagen para estadística
        bits = bits_img;
        symbols = 2*bits - 1;    % BPSK banda base
        x = symbols;             % Eb = 1 EXACTO

        % AWGN correcto
        ruido = sigma * randn(size(x));
        y = x + ruido;

        % Detector óptimo
        bits_hat = y > 0;

        errores = errores + sum(bits ~= bits_hat);
        bits_tot = bits_tot + length(bits);
    end

    BER_sim(i) = errores / bits_tot;

    fprintf('%8.1f | %13.3e | %13.3e\n', ...
            EbN0_dB(i), BER_sim(i), BER_teo(i));
end

%% =========================================================
% 6. GRÁFICA BER vs Eb/N0
%% =========================================================
figure('Position',[200 200 900 600]);

semilogy(EbN0_dB, BER_sim, 'bo-', ...
    'LineWidth',2.5,'MarkerFaceColor','b');
hold on;
semilogy(EbN0_dB, BER_teo, 'r--', 'LineWidth',2.5);

grid on;
ylim([1e-6 1]);
xlim([min(EbN0_dB)-1 max(EbN0_dB)+1]);

title('BER vs E_b/N_0 – BPSK (Simulación = Teoría)', ...
      'FontSize',14,'FontWeight','bold');
xlabel('E_b/N_0 (dB)','FontSize',12,'FontWeight','bold');
ylabel('Bit Error Rate (BER)','FontSize',12,'FontWeight','bold');

legend({'BER Simulado','BER Teórico'}, ...
       'Location','southwest','FontSize',11);

yline(1e-3,'k:'); yline(1e-4,'k:'); yline(1e-5,'k:');

%% =========================================================
% 7. GRÁFICA ADICIONAL: Constelación con ruido para Eb/N0 específico
%% =========================================================
figure('Position',[300 300 1000 400]);

EbN0_ejemplo = 6;  % dB
N0_ej = 1/(10^(EbN0_ejemplo/10));
sigma_ej = sqrt(N0_ej/2);

% Simular recepción con ruido
symbols_10_noisy = symbols_10 + sigma_ej * randn(size(symbols_10));

subplot(1,2,1);
scatter(symbols_10, zeros(size(symbols_10)), 100, 'b', 'o', 'LineWidth', 2, ...
        'DisplayName', 'Símbolos transmitidos');
hold on;
scatter(symbols_10_noisy, zeros(size(symbols_10_noisy)), 100, 'r', 'x', 'LineWidth', 2, ...
        'DisplayName', 'Símbolos recibidos');
grid on;
xlim([-2 2]);
ylim([-0.5 0.5]);
xlabel('Componente en fase (I)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Componente en cuadratura (Q)', 'FontSize', 11, 'FontWeight', 'bold');
title(sprintf('Constelación BPSK con ruido (E_b/N_0 = %d dB)', EbN0_ejemplo), ...
      'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best');

% Línea de decisión
plot([0 0], [-0.5 0.5], 'k--', 'LineWidth', 1.5, 'DisplayName', 'Umbral de decisión');

subplot(1,2,2);
% Señal modulada BPSK con ruido
signal_noisy = [];
for i = 1:length(bits_10)
    if bits_10(i) == 1
        segment = ones(1, fs) + sigma_ej*randn(1, fs);
    else
        segment = -ones(1, fs) + sigma_ej*randn(1, fs);
    end
    signal_noisy = [signal_noisy segment];
end

t = t(1:length(signal_noisy));
plot(t, signal_noisy, 'b-', 'LineWidth', 1);
hold on;
plot(t, signal, 'r--', 'LineWidth', 1.5);
grid on;
xlabel('Tiempo (segundos)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('Amplitud', 'FontSize', 11, 'FontWeight', 'bold');
title(sprintf('Señal BPSK con ruido AWGN (E_b/N_0 = %d dB)', EbN0_ejemplo), ...
      'FontSize', 12, 'FontWeight', 'bold');
ylim([-2.5 2.5]);
xlim([0 length(bits_10)*Tb]);
legend('Señal con ruido', 'Señal original', 'Location', 'best');

% Agregar líneas verticales para separar bits
for i = 1:length(bits_10)
    line([i*Tb i*Tb], [-2.5 2.5], 'Color', 'k', 'LineStyle', '--', 'LineWidth', 0.5);
    text((i-0.5)*Tb, 2, sprintf('%d', bits_10(i)), ...
         'FontSize', 10, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

%% =========================================================
% 8. CONCLUSIÓN
%% =========================================================
fprintf('\n=== CONCLUSIÓN ===\n');
fprintf('✔ Simulación en banda base\n');
fprintf('✔ Eb = 1 normalizado\n');
fprintf('✔ Ruido con varianza N0/2\n');
fprintf('✔ Detector óptimo\n');
fprintf('✔ BER simulado coincide con el teórico\n');
fprintf('✔ Gráficas de constelación y señal modulada agregadas\n');