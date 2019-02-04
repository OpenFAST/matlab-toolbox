function ConvertFAST8_9to10(oldFSTName, newDir)
%function ConvertFAST8_9to10(oldFSTName, newDir)
% by Bonnie Jonkman
%
%Conversion of FAST v 8.9.x files to FAST v8.10.x
%  based on "Demonstration of fast file manipuation" by Paul Fleming
% (c) 2015 National Renewable Energy Laboratory
%--------------------------------------------------------------------------
% Required inputs:
%  oldFSTName - the name of the old (v8) primary FAST input file,
%               including full path name
%  newDir     - the new directory that will contain converted input files
%               (FAST 8.10.0, ServoDyn); It does NOT convert the MAP input files
%               no other input files will be copied or moved.
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

thisFile    = which('ConvertFAST8_9to10');
thisDir     = fileparts(thisFile);
templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldFSTName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newFSTname    = [newDir filesep baseFileName];

if strcmpi(oldDir,newDir)
    disp('ConvertFAST8_9to10 Warning:New FAST input file is overwriting old file.')
end


    %----------------------------------------------------------------------
    % Load in old model data from the primary FAST and ServoDyn input files:
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
    % Write new model data to the FAST input files:
    %----------------------------------------------------------------------
        % FAST
    template   = [templateDir filesep 'FAST_Primary_v8.08.x.dat'];  %template for primary file
    Matlab2FAST(FP,template,newFSTname, 2); %contains 2 header lines


%%  %----------------------------------------------------------------------
    % Write new model data to the ServoDyn input file:
    %----------------------------------------------------------------------
   
    CompServo = GetFASTPar(FP,'CompServo');    
    
    if CompServo == 1 % use ServoDyn in this model
            % Name of (old) ServoDyn input file:  
        ServoFile = GetFASTPar(FP,'ServoFile');    
        ServoFile = strrep(ServoFile,'"',''); %let's remove the quotes so we can actually use this file name
        [oldSrvDName] = GetFullFileName( ServoFile, oldDir );
        
            % Get name of new ServoDyn input file:  
        [newSrvDName] = GetFullFileName( ServoFile, newDir );        

            % get ServoDyn data and convert it to new version:
        SrvDP = FAST2Matlab(oldSrvDName,2); 
        [SrvDP] = newInputs_SrvD_v1_02(SrvDP);            
        
            % write new ServoDyn file
        template   = [templateDir filesep 'SrvD_Primary_v1.02.x.dat'];  %template for SrvD file        
        Matlab2FAST(SrvDP, template, newSrvDName, 2); %contains 2 header lines                
    end
    
    
return

end
