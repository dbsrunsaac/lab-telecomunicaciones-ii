clc, close all;
data = out.pam_signal(:, 3)


% Longitud de los datos
N = length(data);
fprintf('Número de puntos: %d\n', N);

%% Asumir una frecuencia de muestreo
% Como no se especifica Fs, asumiremos valores y analizaremos
% Opción 1: Asumir Fs = 1 Hz (para ver frecuencias normalizadas)
Fs = 1;  % Hz
Ts = 1/Fs;  % Período de muestreo

% Vector de tiempo
t = (0:N-1)*Ts;

%% Calcular la FFT
X = fft(data);  % Transformada de Fourier

% Magnitud y fase
magnitud = abs(X);
fase = angle(X);

% Frecuencias correspondientes (dos lados)
f = (0:N-1)*(Fs/N);

%% Espectro de un lado (para frecuencias positivas)
if mod(N,2) == 0
    % N par
    P1 = magnitud(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    f1 = f(1:N/2+1);
else
    % N impar
    P1 = magnitud(1:(N+1)/2);
    P1(2:end) = 2*P1(2:end);
    f1 = f(1:(N+1)/2);
end

%% Normalizar magnitudes
P1_norm = P1/N;

%% Análisis detallado de los componentes
% Encontrar picos significativos (umbral: 5% del máximo)
umbral = 0.05 * max(P1_norm);
indices_picos = find(P1_norm > umbral);
frecuencias_picos = f1(indices_picos);
magnitudes_picos = P1_norm(indices_picos);

% Ordenar por magnitud descendente
[magnitudes_ordenadas, idx_orden] = sort(magnitudes_picos, 'descend');
frecuencias_ordenadas = frecuencias_picos(idx_orden);

%% Visualización
figure('Position', [100, 100, 1200, 800])

% 1. Señal en tiempo
subplot(3, 2, 1)
stem(t, data, 'b', 'LineWidth', 1.5, 'MarkerSize', 6)
title('Señal en dominio del tiempo')
xlabel('Tiempo (s)')
ylabel('Amplitud')
grid on
xlim([0 t(end)])

% 2. Magnitud del espectro (dos lados)
subplot(3, 2, 2)
stem(f, magnitud/N, 'r', 'LineWidth', 1.5, 'MarkerSize', 4)
title('Espectro de magnitud (dos lados)')
xlabel('Frecuencia (Hz)')
ylabel('|X(f)|')
grid on
xlim([0 Fs])

% 3. Espectro de un lado
subplot(3, 2, 3)
stem(f1, P1_norm, 'g', 'LineWidth', 1.5, 'MarkerSize', 6)
title('Espectro de magnitud (un lado)')
xlabel('Frecuencia (Hz)')
ylabel('|X(f)|')
grid on
hold on
% Marcar picos significativos
stem(frecuencias_ordenadas, magnitudes_ordenadas, 'r', 'LineWidth', 2, 'MarkerSize', 8)
xlim([0 Fs/2])

% 4. Fase
subplot(3, 2, 4)
stem(f1, fase(1:length(f1)), 'm', 'LineWidth', 1.5, 'MarkerSize', 4)
title('Espectro de fase')
xlabel('Frecuencia (Hz)')
ylabel('Fase (rad)')
grid on

% 5. Parte real e imaginaria
subplot(3, 2, 5)
stem(f1, real(X(1:length(f1)))/N, 'b', 'LineWidth', 1.5, 'MarkerSize', 4)
hold on
stem(f1, imag(X(1:length(f1)))/N, 'r', 'LineWidth', 1.5, 'MarkerSize', 4)
title('Parte real e imaginaria (normalizado)')
xlabel('Frecuencia (Hz)')
ylabel('Amplitud')
legend('Real', 'Imaginaria')
grid on

% 6. Representación polar (para frecuencias principales)
subplot(3, 2, 6)
polarplot(fase(indices_picos), magnitudes_picos, 'bo', 'MarkerSize', 10, 'LineWidth', 2)
title('Representación polar de componentes principales')
grid on

%% Mostrar información en consola
fprintf('\n=== RESULTADOS DEL ANÁLISIS FFT ===\n');
fprintf('Número de muestras: %d\n', N);
fprintf('Frecuencia de muestreo asumida: %.1f Hz\n', Fs);
fprintf('Resolución en frecuencia: %.4f Hz\n', Fs/N);
fprintf('Frecuencia máxima analizable (Nyquist): %.1f Hz\n\n', Fs/2);

fprintf('Componentes de frecuencia significativos:\n');
fprintf('%-15s %-15s %-15s\n', 'Frecuencia (Hz)', 'Magnitud', 'Fase (rad)');
fprintf('%s\n', repmat('-', 50, 1));

for i = 1:length(frecuencias_ordenadas)
    idx = indices_picos(idx_orden(i));
    fprintf('%-15.4f %-15.4f %-15.4f\n', ...
        frecuencias_ordenadas(i), ...
        magnitudes_ordenadas(i), ...
        fase(idx));
end

%% Análisis adicional: interpretación de los datos
fprintf('\n=== INTERPRETACIÓN ===\n');
fprintf('Los datos muestran un patrón periódico:\n');
fprintf('Patrón aproximado: [0, 0, 1, 1, 0, 0, -1, -1, 0, 0, 1, 1, ...]\n');

% Calcular período aproximado desde los datos
% Buscar patrones repetitivos
for periodo = 2:floor(N/2)
    es_periodico = true;
    for k = 1:min(periodo, N-periodo)
        if abs(data(k) - data(k+periodo)) > 0.01
            es_periodico = false;
            break;
        end
    end
    if es_periodico
        fprintf('Posible período detectado: %d muestras\n', periodo);
        fprintf('Frecuencia fundamental: %.4f Hz\n', Fs/periodo);
        break;
    end
end

%% Versión alternativa con diferentes Fs para comparación
figure('Name', 'Comparación con diferentes Fs', 'Position', [200, 200, 1000, 600]);

% Probar con diferentes Fs
Fs_opciones = [1, 1000, 10000];
colores = {'b', 'r', 'g'};

for idx = 1:length(Fs_opciones)
    Fs_actual = Fs_opciones(idx);
    
    % Recalcular frecuencias
    f_actual = (0:N-1)*(Fs_actual/N);
    
    % Espectro de un lado
    if mod(N,2) == 0
        f1_actual = f_actual(1:N/2+1);
        P1_actual = magnitud(1:N/2+1)/N;
        P1_actual(2:end-1) = 2*P1_actual(2:end-1);
    else
        f1_actual = f_actual(1:(N+1)/2);
        P1_actual = magnitud(1:(N+1)/2)/N;
        P1_actual(2:end) = 2*P1_actual(2:end);
    end
    
    subplot(2, 2, idx)
    stem(f1_actual, P1_actual, colores{idx}, 'LineWidth', 1.5)
    title(sprintf('Fs = %.0f Hz', Fs_actual))
    xlabel('Frecuencia (Hz)')
    ylabel('|X(f)|')
    grid on
    xlim([0 Fs_actual/2])
end

% Señal reconstruida con componentes principales
subplot(2, 2, 4)
% Usar solo los primeros 3 componentes para reconstrucción
num_componentes = min(3, length(frecuencias_ordenadas));
senal_reconstruida = zeros(size(t));

for i = 1:num_componentes
    freq = frecuencias_ordenadas(i);
    mag = magnitudes_ordenadas(i);
    phase = fase(indices_picos(idx_orden(i)));
    senal_reconstruida = senal_reconstruida + mag * cos(2*pi*freq*t + phase);
end

plot(t, data, 'b-', 'LineWidth', 1.5)
hold on
plot(t, senal_reconstruida, 'r--', 'LineWidth', 2)
title('Comparación: Original vs Reconstruida')
xlabel('Tiempo (s)')
ylabel('Amplitud')
legend('Original', sprintf('Reconstruida (%d comp.)', num_componentes))
grid on