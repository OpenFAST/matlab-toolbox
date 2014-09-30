function ConvertFAST8_8to9(oldFSTName, newDir)
%function ConvertFAST8_8to9(oldFSTName, newDir)
% by Bonnie Jonkman
%
%Conversion of FAST v 8.8.x files to FAST v8.9.x
%  based on "Demonstration of fast file manipuation" by Paul Fleming
% (c) 2011, 2013-2014 National Renewable Energy Laboratory
%--------------------------------------------------------------------------
% Required inputs:
%  oldFSTName - the name of the old (v8) primary FAST input file,
%               including full path name
%  newDir     - the new directory that will contain converted input files
%               (FAST 8.9.0, HydroDyn, SubDyn); 
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

thisFile    = which('ConvertFAST8_8to9');
thisDir     = fileparts(thisFile);
templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldFSTName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newFSTname    = [newDir filesep baseFileName];

if strcmpi(oldDir,newDir)
    disp('ConvertFAST8_3to8 Warning:New FAST input file is overwriting old file.')
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
    FP = Fast2Matlab(inputfile,2); %FP are Fast Parameters, specify 2 lines of header (FAST 8)

%%  %----------------------------------------------------------------------
    % Write new model data to the FAST input files:
    %----------------------------------------------------------------------
        % FAST
    template   = [templateDir filesep 'FAST_Primary_v8.08.x.dat'];  %template for primary file
    Matlab2FAST(FP,template,newFSTname, 2); %contains 2 header lines

    
%%  %----------------------------------------------------------------------
    % Write new model data to the HydroDyn input file:
    %----------------------------------------------------------------------
   
    CompHydro = GetFastPar(FP,'CompHydro');    
    
    if CompHydro == 1 % use HydroDyn in this model
            % Name of (old) HydroDyn input file:  
        HydroFile = GetFastPar(FP,'HydroFile');    
        HydroFile = strrep(HydroFile,'"',''); %let's remove the quotes so we can actually use this file name
        [oldHDName] = GetFullFileName( HydroFile, oldDir );
        
            % Get directory where new HydroDyn input file needs to be located:  
        [newHDName] = GetFullFileName( HydroFile, newDir );        
        [newHDDir] = fileparts(newHDName);
        
            % template file
        template   = [templateDir filesep 'HDv2.02.00.dat'];  %template for HD file        
            
            % now convert the file:
        ConvertHDto2_02_00(oldHDName, newHDDir, template);
    end

    
%%  %----------------------------------------------------------------------
    % Write new model data to the SubDyn input file:
    %----------------------------------------------------------------------
   
    CompSub = GetFastPar(FP,'CompSub');    
    
    if CompSub == 1 % use SubDyn in this model
            % Name of (old) HydroDyn input file:  
        SubFile = GetFastPar(FP,'SubFile');    
        SubFile = strrep(SubFile,'"',''); %let's remove the quotes so we can actually use this file name
        [oldSDName] = GetFullFileName( SubFile, oldDir );
        
            % Get directory where new SubDyn input file needs to be located:  
        [newSDName] = GetFullFileName( SubFile, newDir );        
        [newSDDir] = fileparts(newSDName);
        
            % template file
        template   = [templateDir filesep 'SDv1.01.x.dat'];  %template for SD file        
            
            % now convert the file:
        ConvertSDto1_01_00(oldSDName, newSDDir, template);
    end
    
    
return

end
