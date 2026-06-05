
%   Descargamos el conjunto de datos Google Speech Commands v0.02, extrayendo un
%   subconjunto de comandos de voz, normaliza las muestras y calcula los 
%   Coeficientes Cepstrales en las Frecuencias de Mel (MFCC). Generando un 
%   archivo .mat con los datos particionados (entrenamiento, validación, prueba) 
%   listos para la CNN

clc; clear; close all;

%% Configuración de Parámetros y Rutas
CARPETA_PROYECTO = fullfile(pwd, 'datos');
CARPETA_DATASET  = fullfile(CARPETA_PROYECTO, 'speech_commands');
CARPETA_MFCC     = fullfile(CARPETA_PROYECTO, 'mfcc_procesados');

% Mapeo de comandos objetivo a etiquetas existentes en el dataset.
% Se utilizan equivalencias fonéticas o de intención temporal para
% comandos ausentes en el corpus original.
MAPA_COMANDOS = {
    'left',   'left';
    'right',  'right';
    'up',     'up';
    'down',   'down';
    'jump',   'go';     % Equivalencia por espectro corto/energico
    'action', 'yes';    % Equivalencia arbitraria
    'pause',  'stop';   % Equivalencia por intención
};

% Parámetros de extracción de características de audio
FS_OBJETIVO    = 16000;   % Frecuencia de muestreo (Hz)
DURACION_SEG   = 1.0;     % Normalización temporal de los clips (segundos)
N_MFCC         = 13;      % Número de coeficientes cepstrales
VENTANA_MS     = 25;      % Longitud de la ventana de análisis (ms)
PASO_MS        = 10;      % Desplazamiento temporal de la ventana (ms)
MUESTRAS_MAX   = 2000;    % Límite superior por clase (balanceo de datos)

%% Inicialización del Espacio de Trabajo
if ~exist(CARPETA_PROYECTO, 'dir'), mkdir(CARPETA_PROYECTO); end
if ~exist(CARPETA_MFCC,     'dir'), mkdir(CARPETA_MFCC);     end

%% Adquisición del Conjunto de Datos
url_dataset = 'http://download.tensorflow.org/data/speech_commands_v0.02.tar.gz';
archivo_gz  = fullfile(CARPETA_PROYECTO, 'speech_commands.tar.gz');

if ~exist(CARPETA_DATASET, 'dir')
    fprintf('Iniciando descarga del corpus de audio...\n');
    websave(archivo_gz, url_dataset);
    fprintf('Extrayendo archivos comprimidos...\n');
    untar(archivo_gz, CARPETA_DATASET);
else
    fprintf('Corpus de audio detectado localmente.\n');
end

%% Recopilación y Balanceo de Clases
fprintf('Procesando subconjunto de comandos...\n');

archivos_por_clase = struct();
etiquetas_objetivo = {};
rutas_audio        = {};

for i = 1:size(MAPA_COMANDOS, 1)
    nombre_objetivo = MAPA_COMANDOS{i, 1};
    nombre_dataset  = MAPA_COMANDOS{i, 2};
    carpeta_clase   = fullfile(CARPETA_DATASET, nombre_dataset);
    
    if ~exist(carpeta_clase, 'dir')
        warning('Directorio no encontrado: %s', carpeta_clase);
        continue;
    end
    
    wavs = dir(fullfile(carpeta_clase, '*.wav'));
    
    % Submuestreo aleatorio para evitar sesgo en el modelo
    n = min(length(wavs), MUESTRAS_MAX);
    idx = randperm(length(wavs), n);
    
    fprintf('  Clase: %-8s | Muestras: %d\n', nombre_objetivo, n);
    
    for j = 1:n
        rutas_audio{end+1}     = fullfile(carpeta_clase, wavs(idx(j)).name);
        etiquetas_objetivo{end+1} = nombre_objetivo;
    end
end

%% Extracción de Características (MFCC)
fprintf('\nIniciando extracción de coeficientes MFCC...\n');

ventana_muestras = round(VENTANA_MS/1000 * FS_OBJETIVO);
paso_muestras    = round(PASO_MS/1000    * FS_OBJETIVO);
n_muestras_clip  = round(DURACION_SEG    * FS_OBJETIVO);

% Vector de ventana requerido por versiones recientes de MATLAB (ej. R2024b)
ventana = hamming(ventana_muestras, 'periodic');

% Cálculo de dimensionalidad del tensor de características resultantes
n_frames = floor((n_muestras_clip - ventana_muestras) / paso_muestras) + 1;
n_total  = length(rutas_audio);

X_datos = zeros(N_MFCC, n_frames, 1, n_total, 'single');
Y_datos = categorical(etiquetas_objetivo);
errores = 0;

for i = 1:n_total
    try
        [audio, fs] = audioread(rutas_audio{i});
        audio = audio(:,1); 
        
        % --- 1. Acondicionamiento base ---
        if fs ~= FS_OBJETIVO
            audio = resample(audio, FS_OBJETIVO, fs);
        end
        
        if max(abs(audio)) > 0
            audio = audio / max(abs(audio));
        end

        % --- 2. Filtro VAD (Recorte de silencio y centrado) ---
        % Calcular energía suavizada con una ventana de 50ms
        win_len = round(FS_OBJETIVO * 0.05);
        energia = audio.^2;
        energia_suavizada = movmean(energia, win_len);
        
        % Umbral adaptativo: 2% del pico máximo de energía
        umbral = 0.02 * max(energia_suavizada);
        activos = find(energia_suavizada > umbral);
        
        if ~isempty(activos)
            % Extraer solo la parte donde hay voz (dejando un pequeño margen de 50ms)
            inicio_voz = max(1, activos(1) - win_len);
            fin_voz    = min(length(audio), activos(end) + win_len);
            audio_voz  = audio(inicio_voz:fin_voz);
        else
            audio_voz = audio; % Falla segura: si el audio es rarísimo, usar todo
        end
        
        % --- 3. Centrar el audio en el lienzo de 1 segundo ---
        % La CNN exige entradas exactamente del mismo tamaño. 
        % En lugar de rellenar ceros al final, los ponemos a los lados (padding simétrico)
        audio_final = 1e-4 * randn(n_muestras_clip, 1);
        len_voz = length(audio_voz);
        
        if len_voz >= n_muestras_clip
            % Si la palabra es muy larga, recortamos simétricamente el centro
            mitad = round(len_voz / 2);
            mitad_clip = round(n_muestras_clip / 2);
            audio_final = audio_voz(mitad - mitad_clip + 1 : mitad + mitad_clip);
        else
            % Centrar la voz: calcular cuánto margen dejar a la izquierda
            inicio_pad = round((n_muestras_clip - len_voz) / 2) + 1;
            audio_final(inicio_pad : inicio_pad + len_voz - 1) = audio_voz;
        end
        
        audio = audio_final; % El audio ya está limpio, centrado y listo para el MFCC

        % Ecuación en diferencias: y[n] = x[n] - alpha * x[n-1]
        % Resalta altas frecuencias para diferenciar mejor consonantes.
        alpha = 0.97;
        audio = filter([1 -alpha], 1, audio);
        
        % Cálculo de MFCC actualizado
        coefs = mfcc(audio, FS_OBJETIVO, ...
                     'Window',          ventana, ...
                     'OverlapLength',   ventana_muestras - paso_muestras, ...
                     'NumCoeffs',       N_MFCC, ...
                     'LogEnergy',       'Ignore');
                     
        coefs = coefs';
        
        % Alineación de dimensiones
        if size(coefs, 2) >= n_frames
            X_datos(:,:,1,i) = coefs(:, 1:n_frames);
        else
            X_datos(:,1:size(coefs,2),1,i) = coefs;
        end
        
    catch ME
        % Acumulación de errores aislados sin interrumpir el flujo masivo
        errores = errores + 1;
    end
end

fprintf('Extracción finalizada. Fallos de lectura omitidos: %d\n', errores);

%% Partición del Conjunto de Datos (70% Entrenamiento, 15% Validación, 15% Prueba)
fprintf('Generando particiones de validación cruzada...\n');

cv = cvpartition(Y_datos, 'HoldOut', 0.30);
idx_train = training(cv);
idx_temp  = test(cv);

Y_temp = Y_datos(idx_temp);
cv2    = cvpartition(Y_temp, 'HoldOut', 0.50);

idx_val_local  = training(cv2);
idx_test_local = test(cv2);

idx_temp_list = find(idx_temp);
idx_val  = idx_temp_list(idx_val_local);
idx_test = idx_temp_list(idx_test_local);

XTrain = X_datos(:,:,:, idx_train);
YTrain = Y_datos(idx_train);
XVal   = X_datos(:,:,:, idx_val);
YVal   = Y_datos(idx_val);
XTest  = X_datos(:,:,:, idx_test);
YTest  = Y_datos(idx_test);

fprintf('  Entrenamiento : %d muestras\n', sum(idx_train));
fprintf('  Validación    : %d muestras\n', length(idx_val));
fprintf('  Prueba        : %d muestras\n', length(idx_test));

%% Serialización de Datos
ruta_mat = fullfile(CARPETA_MFCC, 'dataset_mario.mat');
save(ruta_mat, 'XTrain','YTrain','XVal','YVal','XTest','YTest', ...
     'N_MFCC','n_frames','FS_OBJETIVO', '-v7.3');
fprintf('\nExportación exitosa: %s\n', ruta_mat);

%% Visualización de Ejemplos
figure('Name','Representación MFCC por Clase','NumberTitle','off');
clases = categories(YTrain);
n_clases = length(clases);

for c = 1:n_clases
    idx_clase = find(YTrain == clases{c}, 1);
    subplot(2, 4, c);
    imagesc(XTrain(:,:,1,idx_clase));
    axis xy;
    colormap('jet');
    title(clases{c}, 'FontSize', 10);
    xlabel('Ventanas de tiempo (Frames)');
    ylabel('Coeficientes MFCC');
    colorbar;
end
sgtitle('Mapa de características acústicas (MFCC) por clase');
