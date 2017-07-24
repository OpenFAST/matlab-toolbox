function ConvertFAST8_16to17(oldFSTName, newDir)
%function ConvertFAST8_16to17(oldFSTName, newDir)
% by Bonnie Jonkman
%
%Conversion of FAST v 8.16.x files to FAST v8.17.x
%--------------------------------------------------------------------------
% Required inputs:
%  oldFSTName - the name of the old (v8) primary FAST input file,
%               including full path name
%  newDir     - the new directory that will contain converted input files
%               (FAST 8.17.0);
%               No other input files will be copied or moved.
%
% File requirements/assumptions for oldFSTName:
% 1) Comment lines are assumed to start with any of the following four
%      indicators (not including the quotes here):  "#", "!", "=", "--"
%    (Header lines do not need to meet this requirement.)
% 2) If the line is not a comment, it is assumed to be of the form:
%      value [,Array values] <old values> label descr
%    (String values cannot contain old values between the value and label.)
% 3) There MUST be space between quoted strings and the variable name
%
% NOTE that Fortran allows input arrays to be separated by either spaces
% or commas, but this toolbox currently requires them to be commas
%.........................................................................
%bjj: + perhaps we need to put an indication of whether we can allow old
%       values or if array values are indicated by spaces instead of just
%       commas

%% let's get the directory that contains the template files

thisFile    = which('ConvertFAST8_16to17');
thisDir     = fileparts(thisFile);
templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldFSTName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newFSTname    = [newDir filesep baseFileName];

if strcmpi(oldDir,newDir)
    disp('ConvertFAST8_16to17 Warning:New FAST input file is overwriting old file.')
end


    %----------------------------------------------------------------------
    % Load in old model data from the primary FAST and AeroDyn15 input files:
    %----------------------------------------------------------------------
    % primary file:

    fprintf( '%s\n', '****************************************************');
    fprintf( '%s\n', ['Converting ' baseFileName ':'] );
    fprintf( '%s\n', [' old name: ' oldFSTName ] );
    fprintf( '%s\n', [' new name: ' newFSTname ] );
    fprintf( '%s\n', '****************************************************');

    
        %Primary FAST file
    inputfile = [oldDir filesep baseFileName];
    FP = FAST2Matlab(inputfile,2); %FP are Fast Parameters, specify 2 lines of header (FAST 8)
    
%%  %----------------------------------------------------------------------
    % Get AD Data and write new AD15 file:
    %----------------------------------------------------------------------
    CompAero = GetFASTPar(FP,'CompAero');
    if CompAero == 2
        FullADFile = GetFASTPar(FP,'AeroFile');
        [newADName]  = GetFullFileName( FullADFile, newDir ); % new path + name
        [FullADFile] = GetFullFileName( FullADFile, oldDir );
        ADPar = FAST2Matlab(FullADFile,2); % get AeroDyn data (2 header lines)

        [newADPath,ADRootname] = fileparts(newADName);
        if 7~=exist(newADPath,'dir')
           mkdir(newADPath)
        end
        [ADPar] = newInputs_AD_v15_04(ADPar);        
        
        template   = [templateDir filesep 'AD_Primary_v15.04.x.dat'];  %template for primary file
        Matlab2FAST(ADPar,template,newADName, 2); %contains 2 header lines
    end    

    


%%  %----------------------------------------------------------------------
    % Write new model data to the FAST input files:
    %----------------------------------------------------------------------
    template   = [templateDir filesep 'FAST_Primary_v8.17.x.dat'];  %template for primary file
    Matlab2FAST(FP,template,newFSTname, 2); %contains 2 header lines

return

end
