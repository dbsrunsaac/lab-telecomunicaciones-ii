clc; clear all; close all;

%% ===============================
% 1. LECTURA DE IMAGEN DICOM
%% ===============================
img = dicomread('ray-x-hearth.dcm');      % Imagen DICOM
img = mat2gray(img);                % Normalizar [0 1]
[fil, col] = size(img);

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