clc; clear; close all;

% =========================================================================
% 1. CARGA DEL MODELO CNN
% =========================================================================
if ~exist('cnn_mario.mat', 'file')
    error('No se encuentra cnn_mario.mat en el directorio actual.');
end
load('cnn_mario.mat');

% =========================================================================
% 2. COMUNICACIÓN SERIAL (Nexys Video)
% =========================================================================
s = serialport("COM7", 115200);

% =========================================================================
% 3. INTERFAZ GRÁFICA Y MÁQUINA DE ESTADOS (MULTIPLEXOR)
% =========================================================================
% Estados: 1 = VOZ (CNN), 2 = TECLADO (MATLAB), 3 = NEXYS (Hardware)
estado_inicial.modo = 2; % Iniciamos en modo teclado por defecto

fig = figure('Name', 'Control Multiplexado Mario', ...
             'NumberTitle', 'off', ...
             'MenuBar', 'none', ...
             'ToolBar', 'none', ...
             'Color', [0.1 0.1 0.1], ... % Fondo oscuro
             'KeyPressFcn', @(src, e) kD(src, e, s), ...
             'KeyReleaseFcn', @(src, e) kU(src, e, s));

% Texto de interfaz para mostrar el modo actual
ui_texto = uicontrol('Style', 'text', 'String', 'CARGANDO...', ...
          'Units', 'normalized', 'Position', [0.05 0.3 0.9 0.4], ...
          'FontSize', 16, 'FontWeight', 'bold', ...
          'ForegroundColor', [0 1 0], 'BackgroundColor', [0.1 0.1 0.1]);

% Guardamos el estado y el handle del texto dentro de la figura
estado_inicial.hTexto = ui_texto;
fig.UserData = estado_inicial;

actualizar_interfaz(fig);

% =========================================================================
% 4. CONFIGURACIÓN DEL MICRÓFONO
% =========================================================================
adr = audioDeviceReader('SampleRate', 16000, ...
                         'SamplesPerFrame', 16000, ...
                         'Device', 'Microphone Array (AMD Audio Device)');
setup(adr);

disp('--> Sistema Listo. Da clic en la ventana oscura y usa 1, 2 o 3 para cambiar de modo.');

% =========================================================================
% 5. BUCLE PRINCIPAL (Procesamiento de Audio Selectivo)
% =========================================================================
while ishandle(fig)
    % Leemos el audio para vaciar el buffer, sin importar el modo
    audio = adr();
    
    % Extraemos el estado actual
    estado_actual = fig.UserData;
    
    % SOLO procesamos la red neuronal si estamos en MODO VOZ (1)
    if estado_actual.modo == 1
        
        if max(abs(audio)) > 0
            audio = audio / max(abs(audio));
        end
        
        % VAD (Voice Activity Detection)
        win_len = 800;
        energia = movmean(audio.^2, win_len);
        activos = find(energia > 0.02 * max(energia));
        
        if ~isempty(activos)
            audio_voz = audio(max(1, activos(1) - win_len) : min(length(audio), activos(end) + win_len));
        else
            audio_voz = audio;
        end
        
        % Centrado
        audio_final = 1e-4 * randn(16000, 1);
        len_voz = length(audio_voz);
        
        if len_voz >= 16000
            audio_final = audio_voz(round(len_voz/2) - 7999 : round(len_voz/2) + 8000);
        else
            inicio_pad = round((16000 - len_voz) / 2) + 1;
            audio_final(inicio_pad : inicio_pad + len_voz - 1) = audio_voz;
        end
        
        % Pre-énfasis y MFCC
        audio_procesado = filter([1 -0.97], 1, audio_final);
        coefs = mfcc(audio_procesado, 16000, ...
                     'Window', hamming(400, 'periodic'), ...
                     'OverlapLength', 240, ...
                     'NumCoeffs', 13, ...
                     'LogEnergy', 'Ignore')';
                     
        % Inferencia CNN
        X_input = zeros(input_height, input_width, 1, 1, 'single');
        lim = min(size(coefs, 2), input_width);
        X_input(:, 1:lim, 1, 1) = coefs(:, 1:lim);
        
        X_n = (X_input - reshape(media_train, [], 1)) ./ reshape(std_train, [], 1);
        [pred, scores] = classify(red, X_n);
        max_score = max(scores);
        
        % Envío Serial Exclusivo para Voz
        if max_score > 0.85
            comando_voz = string(pred);
            fprintf('  [VOZ] %s (%.1f%%)\n', upper(comando_voz), max_score * 100);
            
            switch comando_voz
                case "right", write(s, "r", "char");
                case "left",  write(s, "l", "char");
                case "stop",  write(s, "s", "char");
                case "up",    write(s, "j", "char");
            end
        end
    end
    
    drawnow;
end

disp('--> Simulación finalizada al cerrar la ventana.');

% =========================================================================
% FUNCIONES DE CONTROL (CALLBACKS)
% =========================================================================

function actualizar_interfaz(fig)
    estado = fig.UserData;
    txt = estado.hTexto;
    
    instrucciones = sprintf('\n\n[1] MODO VOZ  |  [2] MODO TECLADO PC  |  [3] MODO NEXYS HARDWARE');
    
    switch estado.modo
        case 1
            txt.String = ['CONTROL ACTIVO: RED NEURONAL (VOZ)' instrucciones];
            txt.ForegroundColor = [0 1 1]; % Cyan
        case 2
            txt.String = ['CONTROL ACTIVO: TECLADO (A, D, ESPACIO, SHIFT)' instrucciones];
            txt.ForegroundColor = [0 1 0]; % Verde
        case 3
            txt.String = ['CONTROL ACTIVO: NEXYS VIDEO (BOTONES FÍSICOS)' instrucciones];
            txt.ForegroundColor = [1 0.5 0]; % Naranja
    end
end

function kD(src, e, s)
    estado = src.UserData;
    
    % --- SELECTOR DE MODO ---
    if strcmp(e.Key, '1') && estado.modo ~= 1
        estado.modo = 1; src.UserData = estado; actualizar_interfaz(src);
        disp('>> CAMBIO DE MODO: VOZ');
        write(s, "s", "char"); % Detiene a Mario por seguridad al cambiar
        return;
    elseif strcmp(e.Key, '2') && estado.modo ~= 2
        estado.modo = 2; src.UserData = estado; actualizar_interfaz(src);
        disp('>> CAMBIO DE MODO: TECLADO');
        write(s, "s", "char"); 
        return;
    elseif strcmp(e.Key, '3') && estado.modo ~= 3
        estado.modo = 3; src.UserData = estado; actualizar_interfaz(src);
        disp('>> CAMBIO DE MODO: NEXYS (Puerto Serial Silenciado)');
        write(s, "s", "char"); 
        return;
    end

    % --- CONTROL DE TECLADO (Solo funciona si el modo es 2) ---
    if estado.modo == 2
        switch e.Key
            case 'd'
                write(s, "r", "char");
            case 'a'
                write(s, "l", "char");
            case 'space'
                write(s, "j", "char");
            case 'shift'
                write(s, "c", "char");
        end
    end
end

function kU(src, e, s)
    estado = src.UserData;
    
    % --- LIBERACIÓN DE TECLAS (Solo funciona si el modo es 2) ---
    if estado.modo == 2
        switch e.Key
            case {'a', 'd'}
                write(s, "s", "char");
            case 'shift'
                write(s, "x", "char");
        end
    end
end