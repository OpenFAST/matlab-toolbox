function ConvertFAST8_0to3(oldFSTName, newDir, usedBladedDLL)
%function ConvertFAST8_0to3(oldFSTName, newDir)
% by Bonnie Jonkman
%
%Conversion of FAST v 8.0.x files to FAST v8.3.x
%  based on "Demonstration of fast file manipuation" by Paul Fleming
% (c) 2011, 2013 National Renewable Energy Laboratory
%--------------------------------------------------------------------------
% Required inputs:
%  oldFSTName - the name of the old (v8) primary FAST input file,
%               including full path name
%  newDir     - the new directory that will contain converted input files 
%               (FAST 8.3.0, ElastoDyn (primary, blade, and tower files), 
%               ServoDyn; AeroDyn and HydroDyn input files will not be 
%               copied or moved.
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

thisFile    = which('ConvertFAST8_0to1');
thisDir     = fileparts(thisFile);
templateDir = strcat(thisDir,filesep, 'TemplateFiles');

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldFSTName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newFSTname    = [newDir filesep baseFileName];

if strcmpi(oldDir,newDir)
    disp('ConvertFAST8_0to1 Warning:New FAST input file is overwriting old file.')
end        
        
if nargin < 3
    usedBladedDLL = false;
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

    
    
        % Primary SrvD file
    SrvDFile = GetFastPar(FP,'SrvDFile');
    SrvDFile = strrep(SrvDFile,'"',''); %let's remove the quotes so we can actually use this file name   
    [OldSrvDFile, FileWasRelative] = GetFullFileName( SrvDFile, oldDir );       
    SrvDP = Fast2Matlab(OldSrvDFile,2); %SrvDP are ServoDyn parameters
    
    newSrvDname = [newDir filesep SrvDFile];   
    
    if ~FileWasRelative
        disp( ['WARNING: ServoDyn file (' SrvDFile ') is not a relative name. New ServoDyn file will be located here: '] )
        [~, SrvDRoot, ext] = fileparts( SrvDFile );
        SrvDFile = [SrvDRoot ext];
        disp( [newDir filesep SrvDFile] )
        SetFastPar(FP,'SrvDFile', [ '"' SrvDFile '"' ]);
    end
    
    if usedBladedDLL
        [SrvDP] = newInputs_SrvD_v1_01(SrvDP,usedBladedDLL);
    end
    
        % Primary ED file
    EDFile = GetFastPar(FP,'EDFile');
    EDFile = strrep(EDFile,'"',''); %let's remove the quotes so we can actually use this file name   
    [OldEDFile, FileWasRelative] = GetFullFileName( EDFile, oldDir );       
    EDP = Fast2Matlab(OldEDFile,2); %EDP are ElastoDyn parameters
    
    newEDname = [newDir filesep EDFile];   
    
    if ~FileWasRelative
        disp( ['WARNING: ElastoDyn file (' EDFile ') is not a relative name. New ElastoDyn file will be located here: '] )
        [~, EDRoot, ext] = fileparts( EDFile );
        EDFile = [EDRoot ext];
        disp( [newDir filesep EDFile] )
        SetFastPar(FP,'EDFile', [ '"' EDFile '"' ]);
    end    
    
    EDP = newInputs_ED_v1_01(EDP);
   
                 
            
%....................................
% TO DO           
%....................................
%modify control settings (i.e., "none", "simple",etc...)
% if this was compiled with BladedDLLInterface.f90:
%    PCMode { if 1 => 5 }
%    VSContrl { if 2 => 5 }
%    HSSBrMode { if 2 => 5 }
%    YCMode { if 2 => 5 }
    
%%  %----------------------------------------------------------------------
    % Write new model data to the FAST and ServoDyn input files:
    %----------------------------------------------------------------------
        % FAST
    template   = [templateDir filesep 'FAST_Primary_v8.03.x.dat'];  %template for primary file    
    Matlab2FAST(FP,template,newFSTname, 2); %contains 2 header lines

        % ServoDyn
    template   = [templateDir filesep 'SrvD_Primary_v1.01.x.dat'];  %template for ServoDyn primary file
    Matlab2FAST(SrvDP,template,newSrvDname, 2); %contains 2 header lines

        % ElastoDyn
    template   = [templateDir filesep 'ED_Primary_v1.01.x.dat'];  %template for ElastoDyn primary file
    Matlab2FAST(EDP,template,newEDname, 2); %contains 2 header lines
    
    
    
end
