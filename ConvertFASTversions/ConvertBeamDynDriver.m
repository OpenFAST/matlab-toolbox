function ConvertBeamDynDriver(oldDriverName, newDir, templateDir)

    if nargin < 3
        thisFile    = which('ConvertBeamDynDriver');
        thisDir     = fileparts(thisFile);
        templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

        BDtemplate   = 'BeamDyn_Primary.inp';
        DriverTemplate = 'bd_driver.inp';
    else
        BDtemplate     = 'BeamDyn_Primary.inp';
        DriverTemplate = 'bd_driver.inp';
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

    
      % parameters from old BD and its driver:
    P = FAST2Matlab(oldDriverName,2); %P are BD driver Parameters, specify 2 lines of header
    [BDPar, newBDName] = GetFASTPar_Subfile(P, 'InputFile', oldDir, newDir);
    
        % convert to new format:
    [BDPar, P] = newInputs_BD(BDPar, P);
%%
        % write new files:
    template   = [templateDir filesep BDtemplate];  %template for bd file
    Matlab2FAST(BDPar,template,newBDName, 2); %contains 2 header lines
%%
    template   = [templateDir filesep DriverTemplate];  %template for driver file
    Matlab2FAST(P, template, newDriverName, 2); %contains 2 header lines
    
end