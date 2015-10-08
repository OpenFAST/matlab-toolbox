function ConvertFAST7to8(oldFSTName, newDir, YawManRat, PitManRat, usedBladedDLL)
%function ConvertFAST7to8(oldFSTName, newDir, YawManRat, PitManRat, usedBladedDLL)
% by Bonnie Jonkman, National Renewable Energy Laboratory
%
%Conversion of FAST v 7.x files to FAST v8.12.x
%  based on "Demonstration of fast file manipuation" by Paul Fleming
% (c) 2011, 2013-2015 National Renewable Energy Laboratory
%--------------------------------------------------------------------------
% Required inputs:
%  oldFSTName - the name of the old (v6 or 7) primary FAST input file,
%               including full path name
%  newDir     - the new directory that will contain converted input files 
%               (FAST 8.12.x, ElastoDyn (primary, blade, and tower files), 
%               ServoDyn; AeroDyn and HydroDyn input files will not be 
%               copied or moved.
% Optional inputs:
%  YawManRat     - the new yaw maneuver rate, calculated from the old 
%                  output values (see CalculateYawAndPitchRates.m)
%  PitManRat     - an array of new pitch maneuver rates, calculated from  
%                  the old output values (see CalculateYawAndPitchRates.m)
%  usedBladedDLL - a logical determining if this input file was for FAST 
%                  compiled with the BladedDLLInterface.f90 source file
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

if nargin < 5
    usedBladedDLL = false;
end

thisFile    = which('ConvertFAST7to8');
thisDir     = fileparts(thisFile);
templateDir = strcat(thisDir,filesep, 'TemplateFiles');

FAST_template = strcat(templateDir,filesep,'FAST_Primary_v8.12.x.dat');
ED_template   = strcat(templateDir,filesep,'ED_Primary_v1.03.x.dat');
SrvD_template = strcat(templateDir,filesep,'SrvD_Primary_v1.03.x.dat');
IfW_template  = strcat(templateDir,filesep,'IfW_v3.01.x.dat');
templateDir   = strcat(templateDir,filesep,'v8.00.x');

XLS_file    = strcat(templateDir, filesep,'OutListParameters.xlsx');

addpath( strcat(thisDir,filesep, 'InputConversions') ); %directory containing the conversions...


[~, ~, ~, ServoDyn_Channels ] = GetOutListParameters( XLS_file, 'ServoDyn' );
[~, ~, ~, ElastoDyn_Channels] = GetOutListParameters( XLS_file, 'ElastoDyn');

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldFSTName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newFSTname    = [newDir filesep baseFileName];
EDFile        = [baseName '_ElastoDyn.dat'];
SrvDFile      = [baseName '_ServoDyn.dat'];

if strcmpi(oldDir,newDir)
    error('ConvertFAST7to8:New FAST input file cannot be written in same directory as old file.')
end
        
        
    %----------------------------------------------------------------------
    % Load in old model data from the primary FAST and platform input files:
    %----------------------------------------------------------------------
    % primary file:
    
    fprintf( '%s\n', '****************************************************');
    fprintf( '%s\n', ['Converting ' baseFileName ':'] );
    fprintf( '%s\n', [' old name: ' oldFSTName ] );
    fprintf( '%s\n', [' new name: ' newFSTname ] );
    fprintf( '%s\n', '****************************************************');
    
    inputfile = [oldDir filesep baseFileName];      
    FP = Fast2Matlab(inputfile,4); %FP are Fast Parameters, specify 4 lines of header
   
    %----------------------------------------------------------------------
    % Get blade and tower data, too...
    %----------------------------------------------------------------------
    % Tower file: (we'll modify this later)
    TwrFile = GetFastPar(FP,'TwrFile');    
    TwrFile = strrep(TwrFile,'"',''); %let's remove the quotes so we can actually use this file name
    [OldTwrFile, TwrWasRelative] = GetFullFileName( TwrFile, oldDir );
    TP = Fast2Matlab(OldTwrFile,3); %get the old tower parameters with 3 header lines
    
    % Blade files: (we'll modify this later)
    NumBl = GetFastPar(FP,'NumBl');
    BldFile        = cell(1,NumBl);
    BldWasRelative = true(1,NumBl);
    for k=1:NumBl
        BldFile{k} = GetFastPar(FP,['BldFile(' num2str(k) ')']);
        BldFile{k} = strrep(BldFile{k},'"',''); %let's remove the quotes so we can actually use this file name

        [OldBldFile, BldWasRelative(k)] = GetFullFileName( BldFile{k}, oldDir );
        BP{k} = Fast2Matlab(OldBldFile,3); %get the old blade parameters with 3 header lines
    end
    
    %----------------------------------------------------------------------
    % Add fields for FAST/ElastoDyn/ServoDyn and convert old ones as necessary
    %----------------------------------------------------------------------

    %....................................
    [FP] = newInputs_ED_v1_00(FP,oldDir);
    [FP] = newInputs_ED_v1_01(FP);
    %....................................  
    if usedBladedDLL
        [FP] = newInputs_SrvD_v1_01(FP,usedBladedDLL);
    end
    [FP] = newInputs_SrvD_v1_02(FP);
    %....................................  
    
    
%     FP = SetFastPar(FP,'ADAMSPrep',1);          % Adams isn't available in this version
%     FP = SetFastPar(FP,'AnalMode', 1);          % Linearization isn't available in this version
%     FP = SetFastPar(FP,'CompNoise','False');    % Noise isn't available in this version

% FP = SetFastPar(FP,'Echo','True');      % For preliminary testing purposes...
    
    DT_Out = GetFastPar(FP,'DT') * GetFastPar(FP,'DecFact');
    
    if ~TwrWasRelative
        disp( ['WARNING: FAST tower file (' TwrFile ') is not a relative name. New tower file will be located here: '] )
        [~, TwrRoot, ext] = fileparts( TwrFile );
        TwrFile = [TwrRoot ext];
        disp( [newDir filesep TwrFile] )
        SetFastPar(FP,'TwrFile', [ '"' TwrFile '"' ]);
    end
    
    
    for k=1:NumBl
        if ~BldWasRelative(k)
            disp( ['WARNING: FAST blade file (' BldFile{k} ') is not a relative name. New tower file will be located here: '] )

            [~, BldFile{k}, ext] = fileparts( BldFile{k} );
            BldFile{k} = [BldFile{k} ext];
            disp( [newDir filesep BldFile{k}] );

            SetFastPar(FP,['BldFile(' num2str(k) ')'], [ '"' BldFile{k} '"' ]);
        end    
    end
    
        % add a new CompUserPtfmLd line
    PtfmModel = GetFastPar(FP,'PtfmModel');
    if PtfmModel > 0
        Platform = 'True';
    else
        Platform = 'False';
    end
    
        % TwrLdMod is now CompUserTwrLd (TwrLdMod may or may not have existed)    
    CompUserTwrLd = 'False';
    TwrLdMod = GetFastPar(FP,'TwrLdMod');
    if isnumeric(TwrLdMod)
        if TwrLdMod == 2
            CompUserTwrLd = 'True';
        end        
    end        
        
    NewFieldVals = {'EDFile',        [ '"' EDFile '"' ];
                    'CompServo',     'True';
                    'SrvDFile',      [ '"' SrvDFile '"' ];
                    'DT_Out',        DT_Out;
                    'OutFile',       1;
                    'AbortLevel',    'FATAL';
                    'InterpOrder',   0;
                    'NumCrctn',      0;
                    'DT_UJac',       99999;
                    'UJacSclFact',   1000000;
                    'CompUserPtfmLd',Platform; 
                    'CompUserTwrLd', CompUserTwrLd;
                    'CompMAP',       'False';
                    'MAPFile',       '"unused"'; 
                    'CompSub',       'False';
                    'SDFile',        '"unused"'; 
                    'CompHydro',     'False';
                    'HDFile',        '"unused"';      };                   
        % set the rates based on values from CalculateYawAndPitchRates.m
    if ( nargin > 2 )
        if YawManRat ~= 0.0
            NewFieldVals = [ NewFieldVals;
                      {'YawManRat',      YawManRat; } ];
        end
        if nargin > 3
            for n=1:length(PitManRat)
                if PitManRat(n) ~= 0.0
                    NewFieldVals = [ NewFieldVals;
                                  {['PitManRat(' num2str(n) ')'],   PitManRat(n); } ];
                end  
            end
        end
    end
    
                                    
    n = length(FP.Label);
    for k = 1:size(NewFieldVals,1)
        n = n + 1;
        FP.Label{n} = NewFieldVals{k,1};
        FP.Val{n}   = NewFieldVals{k,2};
    end
    
    
        % Change AeroCent from the blade file table to PitchAxis
    for k=1:NumBl
        indx = find(strcmpi('AeroCent',BP{k}.BldPropHdr));
        if isempty(indx)
            disp('Warning: AeroCent not found in blade properties table.')
        else        
            PitchAxis = 0.5 - BP{k}.BldProp(:,indx);  
            BP{k}.BldPropHdr = [BP{k}.BldPropHdr; 'PitchAxis'];
            BP{k}.BldProp    = [BP{k}.BldProp PitchAxis];
        end
    end
        % Get the variables from OutList and figure out which modules they need to go in

    [OutList, OutListComments] = GetOutListVars(FP.OutList, FP.OutListComments);
    numOuts = length(OutList);    
    ED_Channel = false(numOuts,1);
    SD_Channel = false(numOuts,1);
    
    if numOuts > 0
        
        % we'll see which of the modules these match
        for ch=1:numOuts
            ED_Channel(ch) = any( strcmpi(OutList{ch},ElastoDyn_Channels ) ); 
            SD_Channel(ch) = any( strcmpi(OutList{ch},ServoDyn_Channels  ) );
            
            if ~(ED_Channel(ch) || SD_Channel(ch))
                disp( ['WARNING: output channel ' OutList{ch} ' is no longer valid.']);
            end
        end %
                               
    else
        disp('WARNING: there are no outputs to be generated.')
    end
               
    %----------------------------------------------------------------------
    % Convert AeroDyn data:
    %----------------------------------------------------------------------
    AeroFile = GetFastPar(FP,'AeroFile');                                   
    AeroFile = strrep(AeroFile,'"',''); %let's remove the quotes so we can actually use this file name    
    [FullAeroFile,ADWasRelative] = GetFullFileName( AeroFile, oldDir ); % old path + name
    ADPar = Fast2Matlab(FullAeroFile,2); % get AeroDyn data (2 header lines [2nd one is actually SI input])        
       
       
    if (~ADWasRelative)
        disp( ['WARNING: AeroDyn file (' AeroFile ') is not a relative name. New AeroDyn will be located here: '] )
        [~, AeroRoot, ext] = fileparts( AeroFile );
        AeroFile = [AeroRoot ext];
        disp( [newDir filesep AeroFile] );
        FP = SetFastPar(FP,'AeroFile',['"' AeroFile '"']);
    end
            
    % convert everything to latest FAST version:
    [FP] = newInputs_FAST_v8_05(FP);
    [FP,InflowFile] = newInputs_FAST_v8_12(FP, newDir);
    
    %----------------------------------------------------------------------
    % Create InflowWind data:
    %----------------------------------------------------------------------        
     [IfWP] = newInputs_IfW_v3_00(ADPar, FP);        
                         
        %....................................
        % fix the headers for the new files:
        %....................................
        
    %LINEs 3 and 4 of the old header should now be line 2, but we'll remove
    %the part that says "Compatible with FAST v7.02.00." if it's there:    
    FP.HdrLines{2} = [FP.HdrLines{3} ' ' strrep(FP.HdrLines{4}, 'Compatible with FAST v7.02.00.','') ];      
    
    % line 3 of the old blade and tower files should now be line 2:
    TP.HdrLines{2} = TP.HdrLines{3};      
    for k=1:NumBl
        BP{k}.HdrLines{2} = BP{k}.HdrLines{3};      
    end
    
        %....................................

    
    
%%  %----------------------------------------------------------------------
    % Write new model data to the FAST, ElastoDyn, and ServoDyn input files:
    %----------------------------------------------------------------------

        % FAST
    outputFile = newFSTname; 
    Matlab2FAST(FP,FAST_template,outputFile, 2); %contains 2 header lines

    
        % AeroDyn
    [~, err1] = GetFastPar(ADPar,'TwrShadow');
    if err1
        ADtemplate   = [templateDir filesep 'AD_Primary_v14.04.x.dat'];  %template for AD file without NEWTOWER        
    else
        ADtemplate   = [templateDir filesep 'AD_Primary_v14.04.x_NT.dat'];  %template for AD file with NEWTOWER        
    end
    outputFile = [newDir filesep AeroFile];
    Matlab2FAST(ADPar, ADtemplate, outputFile, 2); %contains 2 header lines            
    
    
        % InflowWind
    outputFile = [newDir filesep InflowFile];
    Matlab2FAST(IfWP, IfW_template, outputFile, 3); %contains 3 header lines            
    
    
        % ServoDyn
    outputFile = [newDir filesep SrvDFile];
    FP.OutList         = OutList(SD_Channel);
    FP.OutListComments = OutListComments(SD_Channel);
    Matlab2FAST(FP,SrvD_template,outputFile, 2); %contains 2 header lines

        % ElastoDyn (primary)
    outputFile = [newDir filesep EDFile];
    FP.OutList         = OutList(ED_Channel);
    FP.OutListComments = OutListComments(ED_Channel);
    Matlab2FAST(FP,ED_template,outputFile, 2); %contains 2 header lines
        
        % ElastoDyn (tower)
    template   = [templateDir filesep 'ED_Tower.dat'];  %template for ElastoDyn tower file
    outputFile = [newDir filesep TwrFile];
    Matlab2FAST(TP,template,outputFile, 2); %contains 2 header lines
        
        % ElastoDyn (blade)
    for k=1:NumBl
        template   = [templateDir filesep 'ED_Blade.dat'];  %template for ElastoDyn blade file
        outputFile = [newDir filesep BldFile{k}];
        Matlab2FAST(BP{k},template,outputFile, 2); %contains 2 header lines
    end
        
end
