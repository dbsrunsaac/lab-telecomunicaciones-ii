<<<<<<< HEAD
clc; clear; close all;
=======
clc; clear all; close all;
>>>>>>> 90e8e8153b93e01916d32aebc21b137b1ec1dbd4

%% ===============================
% 1. LECTURA DE IMAGEN DICOM
%% ===============================
img = dicomread('ray-x-hearth.dcm');      % Imagen DICOM
img = mat2gray(img);                % Normalizar [0 1]
[fil, col] = size(img);

<<<<<<< HEAD
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
=======
% Limitar tamaño a 2000 píxeles para procesamiento rápido
if numel(img) > 2000
    % Redimensionar manteniendo relación de aspecto
    factor = sqrt(2000 / numel(img));
    fil_nuevo = round(fil * factor);
    col_nuevo = round(col * factor);
    img = imresize(img, [fil_nuevo, col_nuevo]);
    [fil, col] = size(img);
    fprintf('Imagen redimensionada a %d x %d (%d píxeles)\n', fil, col, numel(img));
else
    fprintf('Imagen original: %d x %d (%d píxeles)\n', fil, col, numel(img));
end

% Convertir a vector y limitar a 2000 elementos exactos
imagen_vector = img(:);
if length(imagen_vector) > 2000
    imagen_vector = imagen_vector(1:2000);
    fprintf('Vector limitado a 2000 elementos para procesamiento\n');
end

N = length(imagen_vector);

% Umbralización para convertir a bits
umbral = graythresh(img);  % Método de Otsu para umbral óptimo
bits = double(imagen_vector > umbral)';

% Mostrar información de la imagen
figure('Position', [100 100 1200 400]);

subplot(1,3,1);
imshow(img, []);
title(sprintf('Imagen DICOM Original\nray-x-hearth.dcm\n%d x %d píxeles', fil, col));

subplot(1,3,2);
histogram(imagen_vector, 50);
title('Histograma de Valores Normalizados');
xlabel('Intensidad Normalizada [0,1]');
ylabel('Frecuencia');
grid on;
line([umbral umbral], ylim, 'Color', 'r', 'LineWidth', 2, 'LineStyle', '--');
text(umbral+0.02, max(ylim)*0.9, sprintf('Umbral = %.3f', umbral), ...
     'Color', 'r', 'FontSize', 10);

subplot(1,3,3);
stem(bits(1:min(50, N)), 'filled', 'MarkerSize', 5);
title('Secuencia de Bits Generada (Primeros 50)');
xlabel('Índice de Bit');
ylabel('Valor Binario');
ylim([-0.2 1.2]);
grid on;

%% ===============================
% 2. PARÁMETROS DE MODULACIÓN BPSK
%% ===============================
Rb = 1000;         % tasa de bits (bps)
Tb = 1/Rb;         % tiempo de bit
Fs = 100*Rb;       % frecuencia de muestreo (100 muestras por bit)
t = 0:1/Fs:Tb-1/Fs; % vector de tiempo por bit

% Mapeo BPSK: 0 → -1, 1 → +1
symbols = 2*bits - 1;

% Portadora
fc = 2000; % frecuencia portadora (2 kHz)
carrier = cos(2*pi*fc*t);

% Modulación BPSK
fprintf('\n=== MODULACIÓN BPSK ===\n');
fprintf('Número de bits: %d\n', N);
fprintf('Tasa de bits (Rb): %d bps\n', Rb);
fprintf('Frecuencia portadora (fc): %d Hz\n', fc);
fprintf('Frecuencia de muestreo (Fs): %d Hz\n', Fs);
fprintf('Duración total de señal: %.3f s\n\n', N*Tb);

% Modulación eficiente con operaciones matriciales
x = reshape(symbols' * carrier, 1, []);

% Graficar señal modulada
figure('Position', [100 100 1000 600]);
subplot(2,2,1);
plot((0:length(x)-1)/Fs, x);
title(['Señal BPSK Modulada - ', num2str(N), ' bits']);
xlabel('Tiempo (s)');
ylabel('Amplitud');
xlim([0 min(0.02, N*Tb)]); % Mostrar primeros 20 ms
grid on;

subplot(2,2,2);
[Pxx, F] = pwelch(x, [], [], [], Fs);
plot(F/1000, 10*log10(Pxx/max(Pxx)));
title('Densidad Espectral de Potencia');
xlabel('Frecuencia (kHz)');
ylabel('PSD Normalizada (dB)');
xlim([fc/1000-5, fc/1000+5]);
grid on;

subplot(2,2,3);
plot((0:199)/Fs, x(1:200));
title('Detalle: Primeros 2 Bits Modulados');
xlabel('Tiempo (s)');
ylabel('Amplitud');
grid on;

subplot(2,2,4);
const_ideal = unique(symbols);
scatter(const_ideal, zeros(size(const_ideal)), 200, 'filled');
title('Constelación BPSK Ideal');
xlabel('Componente en Fase (I)');
ylabel('Componente en Cuadratura (Q)');
xlim([-1.5 1.5]);
ylim([-0.1 0.1]);
grid on;

%% ===============================
% 3. SIMULACIÓN DE CANAL AWGN CON BER EVOLUTIVO
%% ===============================
EbN0_dB = 0:2:12;
BER_simulado = zeros(size(EbN0_dB));
BER_teorico = zeros(size(EbN0_dB));

% Pre-calcular BER teórico para comparación
EbN0_linear = 10.^(EbN0_dB/10);
BER_teorico = 0.5 * erfc(sqrt(EbN0_linear));

fprintf('\n=== SIMULACIÓN CANAL AWGN ===\n');
fprintf('Eb/N0 (dB) | BER Teórico   | BER Simulado  | Errores\n');
fprintf('-----------|---------------|---------------|---------\n');

% Figura para BER evolutivo
figure('Position', [100 100 1400 600]);

for i = 1:length(EbN0_dB)
    %% Canal AWGN
    SNR = EbN0_dB(i) + 10*log10(Rb/Fs); % Ajuste para relación señal-ruido
    y = awgn(x, SNR, 'measured');
    
    %% Demodulación coherente (correlador optimizado)
    y_reshaped = reshape(y, length(t), N);
    decision = sum(y_reshaped .* carrier', 1);
    
    %% Detección de bits
    bits_hat = decision > 0;
    
    %% Cálculo de BER
    errores = sum(bits ~= bits_hat);
    BER_simulado(i) = errores / N;
    
    fprintf('%9d dB | %13.2e | %13.2e | %7d\n', ...
            EbN0_dB(i), BER_teorico(i), BER_simulado(i), errores);
    
    %% Gráfica evolutiva del BER
    subplot(2,3,i);
    
    % Curva BER completa hasta el punto actual
    semilogy(EbN0_dB(1:i), BER_simulado(1:i), 'b-o', ...
             'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
    hold on;
    
    % Curva teórica
    semilogy(EbN0_dB(1:i), BER_teorico(1:i), 'r--', 'LineWidth', 1.5);
    
    % Punto actual destacado
    semilogy(EbN0_dB(i), BER_simulado(i), 'go', ...
             'MarkerSize', 12, 'MarkerFaceColor', 'g');
    
    grid on;
    xlabel('Eb/N0 (dB)');
    ylabel('BER');
    title(sprintf('Eb/N0 = %d dB\nBER = %.2e', EbN0_dB(i), BER_simulado(i)));
    
    if i == 1
        legend({'BER Simulado', 'BER Teórico', 'Punto Actual'}, ...
               'Location', 'best', 'FontSize', 8);
    end
    
    ylim([1e-6 1]);
    xlim([min(EbN0_dB)-1, max(EbN0_dB)+1]);
    
    % Líneas de referencia
    plot(xlim, [0.5 0.5], 'k:', 'LineWidth', 1);
    plot(xlim, [1e-3 1e-3], 'k:', 'LineWidth', 0.5);
    plot(xlim, [1e-5 1e-5], 'k:', 'LineWidth', 0.5);
    
    hold off;
    
    % Actualizar figura en tiempo real
    drawnow;
end

%% ===============================
% 4. GRÁFICAS FINALES Y RESULTADOS
%% ===============================
figure('Position', [100 100 1200 500]);

% Subplot 1: Curva BER final
subplot(1,2,1);
semilogy(EbN0_dB, BER_simulado, 'b-o', 'LineWidth', 2, ...
         'MarkerSize', 10, 'MarkerFaceColor', 'b');
hold on;
semilogy(EbN0_dB, BER_teorico, 'r--', 'LineWidth', 2);
grid on;

title('Curva BER - BPSK con Imagen DICOM', 'FontSize', 14);
xlabel('Eb/N0 (dB)', 'FontSize', 12);
ylabel('Bit Error Rate (BER)', 'FontSize', 12);
legend({'BER Simulado', 'BER Teórico: Q(√(2Eb/N0))'}, ...
       'Location', 'best', 'FontSize', 10);

% Anotaciones
text(2, 1e-1, sprintf('Bits totales: %d', N), ...
     'BackgroundColor', 'white', 'FontSize', 10);
text(2, 3e-2, sprintf('Rb = %d bps', Rb), ...
     'BackgroundColor', 'white', 'FontSize', 10);

ylim([min(BER_simulado(BER_simulado>0))/10 1]);
xlim([min(EbN0_dB)-1 max(EbN0_dB)+1]);

% Subplot 2: Constelaciones para diferentes Eb/N0
subplot(1,2,2);
hold on;
colores = parula(length(EbN0_dB)); % Paleta de colores

% Constelación ideal
scatter([-1, 1], [0, 0], 100, 'k', 'x', 'LineWidth', 2);

for i = [1, 4, 7]  % Mostrar solo algunos Eb/N0 para claridad
    if i <= length(EbN0_dB)
        % Demodular específicamente para esta Eb/N0
        SNR_i = EbN0_dB(i) + 10*log10(Rb/Fs);
        y_i = awgn(x, SNR_i, 'measured');
        y_i_reshaped = reshape(y_i, length(t), N);
        decision_i = sum(y_i_reshaped .* carrier', 1);
        
        % Muestrear puntos
        idx = 1:20:N;
        scatter(decision_i(idx), zeros(size(idx)), ...
                40, colores(i,:), 'filled', 'MarkerFaceAlpha', 0.6);
    end
end

grid on;
title('Constelaciones BPSK para Diferentes Eb/N0', 'FontSize', 14);
xlabel('Componente en Fase (I)', 'FontSize', 12);
ylabel('Componente en Cuadratura (Q)', 'FontSize', 12);

% Leyenda personalizada
h = zeros(4,1);
h(1) = plot(NaN, NaN, 'kx', 'LineWidth', 2, 'MarkerSize', 10);
h(2) = scatter(NaN, NaN, 40, colores(1,:), 'filled');
h(3) = scatter(NaN, NaN, 40, colores(4,:), 'filled');
h(4) = scatter(NaN, NaN, 40, colores(7,:), 'filled');
legend(h, {'Ideal', 'Eb/N0 = 0 dB', 'Eb/N0 = 6 dB', 'Eb/N0 = 12 dB'}, ...
       'Location', 'best', 'FontSize', 10);

%% ===============================
% 5. RECONSTRUCCIÓN DE IMAGEN
%% ===============================
% Seleccionar el mejor caso (Eb/N0 = 12 dB) para reconstrucción
fprintf('\n=== RECONSTRUCCIÓN DE IMAGEN ===\n');
EbN0_reconstruccion = 12; % dB
SNR_reconst = EbN0_reconstruccion + 10*log10(Rb/Fs);

% Paso por canal AWGN
y_reconst = awgn(x, SNR_reconst, 'measured');

% Demodulación
y_reconst_reshaped = reshape(y_reconst, length(t), N);
decision_reconst = sum(y_reconst_reshaped .* carrier', 1);
bits_reconst = decision_reconst > 0;

% Reconstruir imagen
imagen_reconst_vector = zeros(size(imagen_vector));
imagen_reconst_vector(bits_reconst == 1) = 1;  % Valor máximo normalizado
imagen_reconst_vector(bits_reconst == 0) = 0;  % Valor mínimo normalizado

% Intentar restaurar la forma original
try
    imagen_reconst = reshape(imagen_reconst_vector, fil, col);
catch
    % Si no puede redimensionarse, mostrar como vector
    imagen_reconst = imagen_reconst_vector;
    fprintf('Advertencia: No se pudo redimensionar a la forma original\n');
end

% Calcular métricas de calidad
BER_reconst = sum(bits ~= bits_reconst) / N;
PSNR_val = psnr(imagen_reconst, img, 1);
MSE_val = immse(imagen_reconst, img);

fprintf('Eb/N0 para reconstrucción: %d dB\n', EbN0_reconstruccion);
fprintf('BER en reconstrucción: %.2e\n', BER_reconst);
fprintf('PSNR: %.2f dB\n', PSNR_val);
fprintf('MSE: %.2e\n\n', MSE_val);

% Visualizar comparación
figure('Position', [100 100 1000 400]);

subplot(1,3,1);
imshow(img, []);
title('Imagen Original DICOM', 'FontSize', 12);
xlabel(sprintf('%d x %d píxeles', fil, col));

subplot(1,3,2);
imshow(imagen_reconst, []);
title(sprintf('Imagen Reconstruida\nEb/N0 = %d dB', EbN0_reconstruccion), ...
      'FontSize', 12);
xlabel(sprintf('BER = %.1e', BER_reconst));

subplot(1,3,3);
diferencia = abs(double(img) - double(imagen_reconst));
imshow(diferencia, []);
title('Mapa de Diferencias', 'FontSize', 12);
xlabel(sprintf('MSE = %.1e', MSE_val));
colorbar;

%% ===============================
% 6. RESUMEN FINAL
%% ===============================
fprintf('=== RESUMEN DE LA SIMULACIÓN BPSK ===\n');
fprintf('Imagen procesada: ray-x-hearth.dcm\n');
fprintf('Dimensiones originales: %d x %d\n', fil, col);
fprintf('Bits transmitidos: %d\n', N);
fprintf('Eficiencia espectral teórica: 1 bit/s/Hz\n');
fprintf('Ancho de banda requerido: %.1f Hz\n', Rb);
fprintf('\nResultados clave:\n');
fprintf('- Para Eb/N0 = 0 dB: BER = %.2e\n', BER_simulado(1));
fprintf('- Para Eb/N0 = 6 dB: BER = %.2e\n', BER_simulado(4));
fprintf('- Para Eb/N0 = 12 dB: BER = %.2e\n', BER_simulado(7));
fprintf('\nLa simulación confirma el rendimiento teórico de BPSK:\n');
fprintf('P_b = Q(√(2E_b/N_0)) = 0.5*erfc(√(E_b/N_0))\n');
>>>>>>> 90e8e8153b93e01916d32aebc21b137b1ec1dbd4
