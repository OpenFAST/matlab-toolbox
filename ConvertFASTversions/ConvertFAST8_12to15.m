function ConvertFAST8_12to15(oldFSTName, newDir)
%function ConvertFAST8_12to15(oldFSTName, newDir)
% by Bonnie Jonkman
%
%Conversion of FAST v 8.12.x files to FAST v8.14.x
%  based on "Demonstration of fast file manipuation" by Paul Fleming
% (c) 2016 National Renewable Energy Laboratory
%--------------------------------------------------------------------------
% Required inputs:
%  oldFSTName - the name of the old (v8) primary FAST input file,
%               including full path name
%  newDir     - the new directory that will contain converted input files
%               (FAST 8.14.0);
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

thisFile    = which('ConvertFAST8_12to15');
thisDir     = fileparts(thisFile);
templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldFSTName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newFSTname    = [newDir filesep baseFileName];

if strcmpi(oldDir,newDir)
    disp('ConvertFAST8_12to15 Warning:New FAST input file is overwriting old file.')
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
    % Get old SrvD Data:
    %----------------------------------------------------------------------
    CompServo = GetFastPar(FP,'CompServo');
    if CompServo == 1
        FullSrvDFile = GetFastPar(FP,'ServoFile');
        FullSrvDFile = strrep(FullSrvDFile,'"',''); %let's remove the quotes so we can actually use this file name
        [newSrvDName]  = GetFullFileName( FullSrvDFile, newDir ); % new path + name
        [FullSrvDFile] = GetFullFileName( FullSrvDFile, oldDir );
        SrvDPar = Fast2Matlab(FullSrvDFile,2); % get ServoDyn data (3 header lines)

%%  %----------------------------------------------------------------------
    % Get old TMD Data:
    %----------------------------------------------------------------------
        CompNTMD = GetFastPar(SrvDPar,'CompNTMD');
        if strcmpi(CompNTMD,'true') || strcmpi(CompNTMD,'t')
            FullNTMDFile = GetFastPar(SrvDPar,'NTMDfile');
            FullNTMDFile = strrep(FullNTMDFile,'"',''); %let's remove the quotes so we can actually use this file name
            new_SrvD_dir = fileparts( newSrvDName );
            [newNTMDName] = GetFullFileName( FullNTMDFile, new_SrvD_dir ); % new path + name
            old_SrvD_dir = fileparts( FullSrvDFile );
            [FullNTMDFile] = GetFullFileName( FullNTMDFile, old_SrvD_dir );
            NTMDPar = Fast2Matlab(FullNTMDFile,2); % get ElastoDyn data (3 header lines)
        end

    end


%%  %----------------------------------------------------------------------
    % Write new model data to the ServoDyn input files:
    %----------------------------------------------------------------------
    if CompServo == 1
        template = [templateDir filesep 'SrvD_Primary_v1.05.x.dat'];  %template for primary SrvD file
        Matlab2FAST(SrvDPar,template,newSrvDName, 2); %contains 2 header lines

        if strcmpi(CompNTMD,'true') || strcmpi(CompNTMD,'t')
            template = [templateDir filesep 'SrvD_TMD_v1.01.x.dat'];  %template for TMD file
            Matlab2FAST(NTMDPar,template,newNTMDName, 2); %contains 2 header lines
        end
    end


%%  %----------------------------------------------------------------------
    % Write new model data to the FAST input files:
    %----------------------------------------------------------------------
    template   = [templateDir filesep 'FAST_Primary_v8.15.x.dat'];  %template for primary file
    Matlab2FAST(FP,template,newFSTname, 2); %contains 2 header lines

return

end
