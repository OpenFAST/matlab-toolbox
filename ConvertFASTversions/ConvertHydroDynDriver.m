function ConvertHydroDynDriver(oldDriverName, newDir, templateDir)

    if nargin < 3
        thisFile    = which('ConvertHydroDynDriver');
        thisDir     = fileparts(thisFile);
        templateDir = strcat(thisDir,filesep, 'TemplateFiles' );
    end
    HDtemplate     = 'HydroDyn.dat';
    SeaTemplate    = 'seaState.dat';
    DriverTemplate = 'hd_driver.dat';

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

    
      % parameters from old HD and its driver:
    P = FAST2Matlab(oldDriverName,2); %P are HD driver Parameters, specify 2 lines of header
    [HDPar, newHDName] = GetFASTPar_Subfile(P, 'HDInputFile', oldDir, newDir, true);
    [SeaP,  newSeaName, err] = GetFASTPar_Subfile(P, 'SeaStateInputFile', oldDir, newDir, true);
    if (err)
        SeaStateInputFile = 'SeaState.dat';
        nD = length(P.Label);
        nD = nD + 1;
        P.Label{nD} = 'SeaStateInputFile';
        P.Val{nD}   = SeaStateInputFile;

        newSeaName = RebaseFile( SeaStateInputFile, newDir ); % new path + name
    end

        % convert to new format:
    [HDPar, SeaP] = newInputs_HD(HDPar, SeaP);


    %----------------------------------------------------------------------
    % write new module and driver files:
    %----------------------------------------------------------------------
    template   = [templateDir filesep HDtemplate];  %template for hd file
    Matlab2HD(HDPar,template,newHDName, 2); %contains 2 header lines

    template   = [templateDir filesep SeaTemplate];  %template for sea file
    Matlab2HD(SeaP,template,newSeaName, 2); %contains 2 header lines

%%
    template   = [templateDir filesep DriverTemplate];  %template for driver file
    Matlab2FAST(P, template, newDriverName, 2); %contains 2 header lines
    
end