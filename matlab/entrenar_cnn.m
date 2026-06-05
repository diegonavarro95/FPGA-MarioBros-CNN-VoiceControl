% ENTRENAR_CNN.M
%
% Descripción:
%   Carga los coeficientes MFCC preprocesados, define una arquitectura de Red
%   Neuronal Convolucional (CNN) optimizada para la síntesis en hardware
%   (HDL Coder), entrena el modelo y evalúa su rendimiento mediante una matriz
%   de confusión. Exporta el modelo entrenado junto con los estadísticos de
%   normalización.

clc; clear; close all;

%% 1. Carga de Datos Preprocesados
ruta_mat = fullfile(pwd, 'datos', 'mfcc_procesados', 'dataset_mario.mat');
if ~exist(ruta_mat, 'file')
    error('Archivo dataset_mario.mat no encontrado. Ejecutar preparar_dataset.m previamente.');
end

load(ruta_mat);
n_clases     = numel(categories(YTrain));
input_height = size(XTrain, 1);   % Dimensión frecuencial (N_MFCC)
input_width  = size(XTrain, 2);   % Dimensión temporal (frames)

%% 2. Normalización Z-Score de las Características
X_flat      = reshape(XTrain, size(XTrain,1), []);   % [13 x (frames*1*N)]
media_train = mean(X_flat, 2);                       % [13 x 1]
std_train   = std(X_flat, 0, 2) + 1e-8;

% Reshape a [13 x 1 x 1 x 1] para broadcasting correcto con [13 x frames x 1 x N]
mu_4d  = reshape(media_train, size(XTrain,1), 1, 1, 1);
sg_4d  = reshape(std_train,   size(XTrain,1), 1, 1, 1);

XTrain_n = (XTrain - mu_4d) ./ sg_4d;
XVal_n   = (XVal   - mu_4d) ./ sg_4d;
XTest_n  = (XTest  - mu_4d) ./ sg_4d;

%% 3. Definición de la Arquitectura CNN (Time-Aware para Audio)
% Usamos filtros asimétricos (rectangulares) para capturar mayor contexto temporal.

capas = [
    % Capa de Entrada
    imageInputLayer([input_height input_width 1], 'Name', 'entrada', 'Normalization', 'none')

    % Bloque Convolucional 1: Filtro ancho para capturar transiciones fonéticas largas
    convolution2dLayer([3 7], 16, 'Padding', 'same', 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bn1')
    reluLayer('Name', 'relu1')
    maxPooling2dLayer([2 2], 'Stride', 2, 'Name', 'pool1')

    % Bloque Convolucional 2: Filtro medio para sílabas
    convolution2dLayer([3 5], 32, 'Padding', 'same', 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bn2')
    reluLayer('Name', 'relu2')
    maxPooling2dLayer([2 2], 'Stride', 2, 'Name', 'pool2')

    % Bloque Convolucional 3: Filtro cuadrado para detalles finos
    convolution2dLayer([3 3], 64, 'Padding', 'same', 'Name', 'conv3')
    batchNormalizationLayer('Name', 'bn3')
    reluLayer('Name', 'relu3')

    % Clasificador Denso
    globalAveragePooling2dLayer('Name', 'gap')
    fullyConnectedLayer(64,  'Name', 'fc1')
    reluLayer('Name', 'relu_fc1')
    fullyConnectedLayer(n_clases, 'Name', 'fc_out')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'salida')
];

% Análisis estático de la topología de red
lgraph = layerGraph(capas);
analyzeNetwork(lgraph);

%% 4. Configuración de Hiperparámetros de Entrenamiento
opciones = trainingOptions('adam', ...
    'InitialLearnRate',    5e-4,        ... 
    'LearnRateSchedule',   'piecewise', ...
    'LearnRateDropFactor', 0.5,         ...
    'LearnRateDropPeriod', 10,          ... 
    'L2Regularization',    0.001,       ... % NUEVO: Fuerza a los pesos a mantenerse pequeños (evita overfitting)
    'MaxEpochs',           35,          ... % Un poco más de tiempo para asimilar el contexto temporal
    'MiniBatchSize',       128,         ...
    'ValidationData',      {XVal_n, YVal}, ...
    'ValidationFrequency', 50,          ...
    'ValidationPatience',  8,           ... 
    'Shuffle',             'every-epoch', ...
    'Verbose',             false,       ...
    'Plots',               'training-progress');

%% 5. Proceso de Entrenamiento
tic;
[red, info] = trainNetwork(XTrain_n, YTrain, capas, opciones);
t_entrenamiento = toc;

%% 6. Evaluación de Rendimiento en Conjunto de Prueba (Test Set)
YPred = classify(red, XTest_n, 'MiniBatchSize', 128);
acc   = mean(YPred == YTest) * 100;

% Visualización de Resultados: Matriz de Confusión
figure('Name', 'Matriz de Confusion', 'NumberTitle', 'off');
confusionchart(YTest, YPred, ...
    'Title',           sprintf('Evaluación del Modelo - Precisión Global: %.1f%%', acc), ...
    'RowSummary',      'row-normalized', ...
    'ColumnSummary',   'column-normalized');

%% 7. Serialización del Modelo Entrenado
carpeta_salida = fullfile(pwd, 'datos', 'modelos');
if ~exist(carpeta_salida, 'dir'), mkdir(carpeta_salida); end

ruta_modelo = fullfile(carpeta_salida, 'cnn_mario.mat');
save(ruta_modelo, 'red', 'media_train', 'std_train', ...
     'input_height', 'input_width', 'n_clases', 'info', '-v7.3');
