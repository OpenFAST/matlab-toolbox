function ConvertAeroDynDriver(oldDriverName, newDir, templateDir)

    if nargin < 3
        thisFile    = which('ConvertAeroDynDriver');
        thisDir     = fileparts(thisFile);
        templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

        ModTemplate   = 'AeroDyn15_Primary.dat';
    else
        ModTemplate     = 'AeroDyn15_Primary.dat';
    end

    %%
            % Primary input file:

    [oldDir, baseName, ext ] = fileparts(oldDriverName);
    baseFileName  = strcat(baseName,ext);                 %base driver file name
    newDriverName    = [newDir filesep baseFileName];


    %----------------------------------------------------------------------
    % Load in old model data from the input files:
    %----------------------------------------------------------------------
    % primary file:

    fprintf( '%s\n', '****************************************************');
    fprintf( '%s\n', ['Converting ' baseFileName ':'] );
    fprintf( '%s\n', [' old name: ' oldDriverName ] );
    fprintf( '%s\n', [' new name: ' newDriverName ] );
    fprintf( '%s\n', '****************************************************');

    
      % parameters from old AD and its driver:
    P = FAST2Matlab(oldDriverName,2); %P are driver parameters, specify 2 lines of header
    [ModPar, newModName] = GetFASTPar_Subfile(P, 'AD_InputFile', oldDir, newDir);
    
        % convert to new format:
    [ModPar] = newInputs_AD_v15_04(ModPar);
%%
        % write new files:
    template   = [templateDir filesep ModTemplate];  %template for module file
    Matlab2FAST(ModPar,template,newModName, 2); %contains 2 header lines
%%
%     template   = [templateDir filesep DriverTemplate];  %template for driver file
%     Matlab2FAST(P, template, newDriverName, 2); %contains 2 header lines
    
end