function ConvertHDto2_00_03(oldHDName, newDir, template)
%function ConvertHDv2_00_00to2_00_03(oldHDName, newDir)
% Feb 6 2014 Greg Hayman
% based on work by Bonnie Jonkman
%
%Conversion of HydroDyn input files to HydroDyn v2.00.03 files
%  based on "Demonstration of fast file manipuation" by Paul Fleming
% (c) 2011, 2013 National Renewable Energy Laboratory
%--------------------------------------------------------------------------
% Required inputs:
%  oldHDName - the name of the old HydroDyn input file,
%               including full path name
%  newDir     - the new directory that will contain converted input file 
%  template   - a template HydroDyn input file which the conversion is based on.            
%
% File requirements/assumptions for oldHDName: 
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

thisFile    = which('ConvertHD2_00_00to2_00_03');
thisDir     = fileparts(thisFile);
%templateDir = strcat(thisDir,filesep, 'TemplateFiles', filesep, 'HDv2.00.03');

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldHDName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newHDname    = [newDir filesep baseFileName];

if strcmpi(oldDir,newDir)
    disp('ConvertHDv2 Warning:New HydroDyn input file is overwriting old file.')
end        
        

    %----------------------------------------------------------------------
    % Load in old model data from the HydroDyn input file:
    %----------------------------------------------------------------------
    
    
    fprintf( '%s\n', '****************************************************');
    fprintf( '%s\n', ['Converting ' baseFileName ':'] );
    fprintf( '%s\n', [' old name: ' oldHDName ] );
    fprintf( '%s\n', [' new name: ' newHDname ] );
    fprintf( '%s\n', '****************************************************');
    
    
        %HydroDyn file
    inputfile = [oldDir filesep baseFileName];      
    HDpar = HD2Matlab(inputfile, 2); %HDpar are HydroDyn Parameters
    
        % convert to HydroDyn v2.00.003:
    HDpar = newInputs_HD_v2_00_03(HDpar);
           
%%  %----------------------------------------------------------------------
    % Write new  data to the new HydroDyn input file:
    %----------------------------------------------------------------------
       
    %template   = [templateDir filesep 'HDv2.00.03.dat'];  %template for HydroDyn file    
    Matlab2HD(HDpar,template,newHDname, 2); %contains 2 header lines
    
return    
    
end
