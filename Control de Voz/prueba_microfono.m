% PRUEBA_MICROFONO.M
%
% Descripción:
%   Captura 1 segundo de audio desde el micrófono del sistema (a 44.1 kHz), 
%   lo remuestrea a 16 kHz, aplica el pipeline de preprocesamiento EXACTO 
%   (VAD + Pre-énfasis + MFCC + Z-Score) y realiza inferencia en vivo.

clc; clear; close all;

%% 1. Cargar el modelo entrenado
ruta_modelo = fullfile(pwd, 'datos', 'modelos', 'cnn_mario.mat');
if ~exist(ruta_modelo, 'file')
    error('No se encuentra cnn_mario.mat. Asegúrate de haber entrenado la red.');
end

fprintf('Cargando el cerebro de la IA...\n');
load(ruta_modelo); % Carga: red, media_train, std_train, input_height, input_width

%% 2. Captura de Audio
FS_HARDWARE  = 44100; % Frecuencia estándar de la tarjeta de sonido
FS_OBJETIVO  = 16000; % Frecuencia objetivo de la CNN
DURACION_SEG = 1.0;

fprintf('\nPreparando micrófono...\n');
recObj = audiorecorder(FS_HARDWARE, 16, 1);

pause(1); 
disp('🔴 GRABANDO: ¡DI UN COMANDO AHORA! (1 segundo)...');
recordblocking(recObj, DURACION_SEG);
disp('🟩 GRABACIÓN TERMINADA. Procesando...');

audio_crudo = getaudiodata(recObj);

%% 3. Preprocesamiento (ESPEJO EXACTO DEL SCRIPT 2)
fprintf('Aplicando filtros y extrayendo MFCC...\n');

% Remuestreo
audio = resample(audio_crudo, FS_OBJETIVO, FS_HARDWARE);

% Normalización base
if max(abs(audio)) > 0
    audio = audio / max(abs(audio));
end

% --- FILTRO 1: VAD Y CENTRADO ---
win_len = round(FS_OBJETIVO * 0.05);
energia = audio.^2;
energia_suavizada = movmean(energia, win_len);
umbral = 0.02 * max(energia_suavizada);
activos = find(energia_suavizada > umbral);
n_muestras_clip = FS_OBJETIVO * DURACION_SEG;

if ~isempty(activos)
    inicio_voz = max(1, activos(1) - win_len);
    fin_voz    = min(length(audio), activos(end) + win_len);
    audio_voz  = audio(inicio_voz:fin_voz);
else
    audio_voz = audio;
end

% Dithering (ruido blanco en el fondo para evitar log(0)) y Centrado simétrico
audio_final = 1e-4 * randn(n_muestras_clip, 1); 
len_voz = length(audio_voz);

if len_voz >= n_muestras_clip
    mitad = round(len_voz / 2);
    mitad_clip = round(n_muestras_clip / 2);
    audio_final = audio_voz(mitad - mitad_clip + 1 : mitad + mitad_clip);
else
    inicio_pad = round((n_muestras_clip - len_voz) / 2) + 1;
    audio_final(inicio_pad : inicio_pad + len_voz - 1) = audio_voz;
end
audio = audio_final;

% --- FILTRO 2: PRE-ÉNFASIS ---
alpha = 0.97;
audio = filter([1 -alpha], 1, audio);

% --- EXTRACCIÓN MFCC ---
ventana_muestras = round(25/1000 * FS_OBJETIVO);
paso_muestras    = round(10/1000 * FS_OBJETIVO);
ventana = hamming(ventana_muestras, 'periodic');

coefs = mfcc(audio, FS_OBJETIVO, ...
             'Window',        ventana, ...
             'OverlapLength', ventana_muestras - paso_muestras, ...
             'NumCoeffs',     13, ...
             'LogEnergy',     'Ignore');
coefs = coefs';

% Alineación de dimensiones
X_input = zeros(input_height, input_width, 1, 1, 'single');
if size(coefs, 2) >= input_width
    X_input(:,:,1,1) = coefs(:, 1:input_width);
else
    X_input(:,1:size(coefs,2),1,1) = coefs;
end

% Normalización Z-Score (Filtro 3 / CMS Matemático)
mu = reshape(media_train, [], 1);
sg = reshape(std_train, [], 1);
X_n = (X_input - mu) ./ sg;

%% 4. Inferencia
[pred_class, scores] = classify(red, X_n);

%% 5. Resultados
fprintf('\n========================================\n');
fprintf('  COMANDO DETECTADO: >> %s <<\n', upper(string(pred_class)));
fprintf('========================================\n');

clases = red.Layers(end).Classes;
[sorted_scores, idx] = sort(scores, 'descend');

fprintf('\nNivel de confianza:\n');
for i = 1:3
    fprintf('  %s: %5.1f%%\n', string(clases(idx(i))), sorted_scores(i)*100);
end
fprintf('\n');