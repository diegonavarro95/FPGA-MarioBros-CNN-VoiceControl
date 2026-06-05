fprintf('=== Verificando toolboxes necesarios ===\n\n');

toolboxes_requeridos = {
    'Audio Toolbox',            'audioDatastore';
    'Deep Learning Toolbox',    'trainNetwork';
    'Signal Processing Toolbox','spectrogram';
    'Statistics and ML Toolbox','cvpartition';
};

toolboxes_hdl = {
    'Deep Learning HDL Toolbox', 'dlhdl.Workflow';
    'HDL Coder',                 'hdlcoder.WorkflowConfig';
};

todos_ok = true;

fprintf('--- Toolboxes principales ---\n');
for i = 1:size(toolboxes_requeridos, 1)
    nombre  = toolboxes_requeridos{i,1};
    funcion = toolboxes_requeridos{i,2};
    if exist(funcion, 'builtin') || exist(funcion, 'file') || ~isempty(which(funcion))
        fprintf('  [OK]  %s\n', nombre);
    else
        fprintf('  [FALTA] %s\n', nombre);
        todos_ok = false;
    end
end

fprintf('\n--- Toolboxes para conversion a VHDL ---\n');
for i = 1:size(toolboxes_hdl, 1)
    nombre  = toolboxes_hdl{i,1};
    clase   = toolboxes_hdl{i,2};
    try
        eval(clase);
        fprintf('  [OK]  %s\n', nombre);
    catch ME
        if contains(ME.message, 'Undefined') || contains(ME.message, 'not found')
            fprintf('  [FALTA] %s\n', nombre);
        else
            fprintf('  [OK]  %s\n', nombre);
        end
    end
end

fprintf('\n--- Version de MATLAB ---\n');
v = ver('matlab');
fprintf('  MATLAB %s (%s)\n', v.Version, v.Release);

fprintf('\n');
if todos_ok
    fprintf('✓ Verificacion finalizada con exito.\n');
else
    fprintf('! Faltan componentes por instalar.\n');
end
fprintf('\n');