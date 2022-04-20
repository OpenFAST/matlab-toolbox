function ConvertFAST8_16to17(oldFSTName, newDir, templateDir)
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

if nargin < 3
    thisFile    = which('ConvertFAST8_16to17');
    thisDir     = fileparts(thisFile);
    templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

    ADtemplate   = 'AeroDyn15_Primary.dat';
    BDtemplate   = 'BeamDyn_Primary.inp';
    EDtemplate   = 'ElastoDyn_Primary.dat';
    SrvDtemplate = 'SrvD_Primary.dat';
    FASTtemplate = 'OpenFAST.fst';
    HDtemplate   = 'HydroDyn.dat';
    SEAtemplate  = 'seaState.dat';
    IfWtemplate  = 'InflowWind.dat';
else
    ADtemplate   = 'AeroDyn15.dat';
    BDtemplate   = 'BeamDyn.dat';
    EDtemplate   = 'ElastoDyn.dat';
    SrvDtemplate = 'ServoDyn.dat';
    FASTtemplate = 'enFAST.fst';
    HDtemplate   = 'HydroDyn.dat';
    SEAtemplate  = 'seaState.dat';
    IfWtemplate  = 'InflowWind.dat';
end
%%
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
    OutFileFmt = GetFASTPar(FP,'OutFileFmt');
    if (OutFileFmt==0)
        OutFileFmt = 4; %don't print both uncompressed .outb and .txt files
        FP = SetFASTPar(FP,'OutFileFmt',OutFileFmt);
    end
    
%%  %----------------------------------------------------------------------
    % Get AD Data and write new AD15 file:
    %----------------------------------------------------------------------
    CompAero = GetFASTPar(FP,'CompAero');
    if CompAero == 2
        [ADPar, newADName] = GetFASTPar_Subfile(FP, 'AeroFile', oldDir, newDir);
        ADPar = newInputs_AD_v15_04(ADPar);        
        
        template   = [templateDir filesep ADtemplate];  %template for primary file
        Matlab2FAST(ADPar,template,newADName, 2); %contains 2 header lines
    end    

%%  %----------------------------------------------------------------------
    % Get SrvD Data and write new ServoDyn file:
    %----------------------------------------------------------------------
    CompServo = GetFASTPar(FP,'CompServo');
    if CompServo == 1
        [SrvDPar, newSrvDName] = GetFASTPar_Subfile(FP, 'ServoFile', oldDir, newDir);
%         [SrvDPar] = SetFASTPar(SrvDPar,'UsePAM','false');


        template   = [templateDir filesep SrvDtemplate];  %template for primary file
        Matlab2FAST(SrvDPar, template, newSrvDName, 2); %contains 2 header lines
    end    
    
%%  %----------------------------------------------------------------------
    % Get HD Data and write new HydroDyn file:
    %----------------------------------------------------------------------
    CompHydro = GetFASTPar(FP,'CompHydro');
    if CompHydro == 1
        [HDPar, newHDName] = GetFASTPar_Subfile(FP, 'HydroFile', oldDir, newDir, true);
        [SeaP,  newSeaName, err] = GetFASTPar_Subfile(FP, 'SeaStFile', oldDir, newDir, true);
        if (err)
            SeaStateInputFile = '"SeaState.dat"';
            FP = SetFASTPar(FP, 'SeaStFile', SeaStateInputFile);
            newSeaName = RebaseFile( SeaStateInputFile, newDir ); % new path + name
        end

        FP = SetFASTPar(FP,'CompSeaSt', 1);

        % convert to new format:
        [HDPar, SeaP] = newInputs_HD(HDPar, SeaP);


        % write new module and driver files:
        template   = [templateDir filesep HDtemplate];  %template for hd file
        Matlab2HD(HDPar, template, newHDName, 2); %contains 2 header lines

        template   = [templateDir filesep SEAtemplate];  %template for seaState file
        Matlab2HD(SeaP, template, newSeaName, 2); %contains 2 header lines
    end    
    
    
%%  %----------------------------------------------------------------------
    % Get BD Data and write new BeamDyn file:
    %----------------------------------------------------------------------
    CompElast = GetFASTPar(FP,'CompElast');
    
    [EDPar, newEDName] = GetFASTPar_Subfile(FP, 'EDFile', oldDir, newDir);            
    NumBl = GetFASTPar(EDPar, 'NumBl');

    if CompElast == 1 % ElastoDyn
        
        for i = 1:NumBl
            varName = ['BldFile(' num2str(i) ')'];

            [BldFile] = GetFASTPar(EDPar, varName);            
            if isempty(BldFile)
                varName_alt = ['BldFile' num2str(i)];
                [BldFile] = GetFASTPar(EDPar, varName_alt);
                if ~isempty(BldFile)
                    EDPar = SetFASTPar(EDPar,varName,BldFile);
                end
            end
        end
        
        template   = [templateDir filesep EDtemplate];  %template for primary file
        Matlab2FAST(EDPar,template,newEDName, 2); %contains 2 header lines
        
    elseif CompElast == 2 % BeamDyn

        for i = 1:NumBl
            varName = ['BDBldFile(' num2str(i) ')'];
            
            [BDPar, newBDName] = GetFASTPar_Subfile(FP, varName, oldDir, newDir);            
            BDPar = newInputs_BD(BDPar);  

            template   = [templateDir filesep BDtemplate];  %template for primary file
            Matlab2FAST(BDPar,template,newBDName, 2); %contains 2 header lines
        end
        
    end    

%%  %----------------------------------------------------------------------
    % Get InflowWind Data and write new InflowWind file:
    %----------------------------------------------------------------------
    CompInflow = GetFASTPar(FP,'CompInflow');
    if CompInflow == 1
        [IfWPar, newIfWName] = GetFASTPar_Subfile(FP, 'InflowFile', oldDir, newDir);

            % if there are multiple instances of RefHt and PLExp, rename
            % them:
        RefHt_Uni = GetFASTPar(IfWPar,'RefHt_Uni');
        if isempty(RefHt_Uni)
            RefHt = GetFASTPar(IfWPar,'RefHt',2);
            if ~isempty(RefHt)
                IfWPar = SetFASTPar(IfWPar,'RefHt_Uni',RefHt);
                RefHt = GetFASTPar(IfWPar,'RefHt',3);
                IfWPar = SetFASTPar(IfWPar,'RefHt_Hawc',RefHt);
            end

            PLExp = GetFASTPar(IfWPar,'PLExp',2);
            if ~isempty(PLExp)
                IfWPar = SetFASTPar(IfWPar,'PLExp_Hawc',PLExp);
            end

            FileName_IfW2 = GetFASTPar(IfWPar,'Filename',2);
            if ~isempty(FileName_IfW2)
                IfWPar = SetFASTPar(IfWPar,'Filename_BTS',FileName_IfW2);
            end
        end
        
        template   = [templateDir filesep IfWtemplate];  %template for primary file
        Matlab2FAST(IfWPar, template, newIfWName, 2); %contains 2 header lines
    end    
    

%%  %----------------------------------------------------------------------
    % Write new model data to the FAST input files:
    %----------------------------------------------------------------------
    template   = [templateDir filesep FASTtemplate];  %template for primary file
    Matlab2FAST(FP,template,newFSTname, 2); %contains 2 header lines

return

end
