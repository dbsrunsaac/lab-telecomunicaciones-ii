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
% 4. GRÁFICA ÚNICA BER vs Eb/N0
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