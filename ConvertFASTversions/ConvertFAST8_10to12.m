function ConvertFAST8_10to12(oldFSTName, newDir, createAD15)
%function ConvertFAST8_10to12(oldFSTName, newDir)
% by Bonnie Jonkman
%
%Conversion of FAST v 8.10.x files to FAST v8.12.x
%  based on "Demonstration of fast file manipuation" by Paul Fleming
% (c) 2015 National Renewable Energy Laboratory
%--------------------------------------------------------------------------
% Required inputs:
%  oldFSTName - the name of the old (v8) primary FAST input file,
%               including full path name
%  newDir     - the new directory that will contain converted input files
%               (FAST 8.12.0);
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

thisFile    = which('ConvertFAST8_10to12');
thisDir     = fileparts(thisFile);
templateDir = strcat(thisDir,filesep, 'TemplateFiles' );

        % Primary input file:

[oldDir, baseName, ext ] = fileparts(oldFSTName);
baseFileName  = strcat(baseName,ext);                 %base FAST file name
newFSTname    = [newDir filesep baseFileName];

if strcmpi(oldDir,newDir)
    disp('ConvertFAST8_10to12 Warning:New FAST input file is overwriting old file.')
end

if nargin < 3
    createAD15 = false;
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
    % Get old ED Data:
    %----------------------------------------------------------------------
    FullEDFile = GetFastPar(FP,'EDFile');
    FullEDFile = strrep(FullEDFile,'"',''); %let's remove the quotes so we can actually use this file name
    [newEDName]  = GetFullFileName( FullEDFile, newDir ); % new path + name
    [FullEDFile] = GetFullFileName( FullEDFile, oldDir );
    EDPar = Fast2Matlab(FullEDFile,3); % get ElastoDyn data (3 header lines)
    

%%  %----------------------------------------------------------------------
    % Get old SrvD Data:
    %----------------------------------------------------------------------
    FullSrvDFile = GetFastPar(FP,'ServoFile');
    FullSrvDFile = strrep(FullSrvDFile,'"',''); %let's remove the quotes so we can actually use this file name
    [newSrvDName]  = GetFullFileName( FullSrvDFile, newDir ); % new path + name
    [FullSrvDFile] = GetFullFileName( FullSrvDFile, oldDir );
    SrvDPar = Fast2Matlab(FullSrvDFile,3); % get ElastoDyn data (3 header lines)
    
    
%%  %----------------------------------------------------------------------
    % Get old AD Data:
    %----------------------------------------------------------------------
    CompAero = GetFastPar(FP,'CompAero'); 
% In FAST v8.10, we read the AeroDyn input file for ElastoDyn, so we have to
% convert it to the new format regardless of CompAero          
    AeroFile = GetFastPar(FP,'AeroFile');                                   
    FullAeroFile = strrep(AeroFile,'"',''); %let's remove the quotes so we can actually use this file name    
    [newADName]    = GetFullFileName( FullAeroFile, newDir ); % new path + name
    [FullAeroFile] = GetFullFileName( FullAeroFile, oldDir ); % old path + name
    ADPar = Fast2Matlab(FullAeroFile,2); % get AeroDyn data (2 header lines [2nd one is actually SI input])        
    
%%  %----------------------------------------------------------------------
    % Write new model data to the AeroDyn input file:
    %----------------------------------------------------------------------               
    if (createAD15)
        [newADPath,ADRootname] = fileparts(newADName);
        [ADPar, newADBladeName] = newInputs_AD_v15(ADPar, ADRootname);
                
        % write new blade files:
        [newADBladeName] = GetFullFileName( newADBladeName, newADPath ); % new path + name
        template = [templateDir filesep 'AD_Blade_v15.00.x.dat'];
        Matlab2FAST(ADPar, template, newADBladeName, 2); %contains 2 header lines            
        
        template = [templateDir filesep 'AD_Primary_v15.00.x.dat']; 
        newADName = strrep(newADName,'AeroDyn','AeroDyn15');
        newADName = strrep(newADName,'AD','AD15');
        
    else
    
        [~, err1] = GetFastPar(ADPar,'TwrShadow');

        if err1
            template   = [templateDir filesep 'AD_Primary_v14.04.x.dat'];  %template for AD file without NEWTOWER        
        else
            template   = [templateDir filesep 'AD_Primary_v14.04.x_NT.dat'];  %template for AD file with NEWTOWER        
        end
    end
    Matlab2FAST(ADPar, template, newADName, 2); %contains 2 header lines            

    
%%  %----------------------------------------------------------------------
    % Write new model data to the InflowWind input file:
    %----------------------------------------------------------------------        
    [InflowFile, err1] = GetFastPar(FP,'InflowFile');  
    if (err1)
        CompInflow = CompAero;
        
        if CompInflow
            % get name of new file:
            InflowFile = strrep(AeroFile,'AeroDyn','InflowWind');
            if strcmp( AeroFile, InflowFile )
                InflowFile = strrep(AeroFile,'.','_InflowWind.');
                if strcmp( AeroFile, InflowFile )
                    InflowFile = [ AeroFile '_InflowWind' ];
                end
            end   
        else
            InflowFile = '"unused"';            
        end
        
        % add some new fields to the primary FAST data type
        n=length(FP.Label);
        
        n = n + 1;
        FP.Label{n} = 'CompInflow';
        FP.Val{n}   = CompAero;

        n = n + 1;
        FP.Label{n} = 'InflowFile';
        FP.Val{n}   = InflowFile;        
        
        
    else
        [CompInflow] = GetFastPar(FP,'CompInflow');        
    end
    
        %.............        

    if CompInflow == 1 % use InflowWind in this model        

        % get values to put into new file:
        InflowFileNoQuotes = strrep(InflowFile,'"',''); %let's remove the quotes so we can actually use this file name                                    
        [newIfWname] = GetFullFileName( InflowFileNoQuotes, newDir ); % Get name of new InflowWind input file   
        [IfWP, err2] = newInputs_IfW_v3_00(ADPar, EDPar);        
        
        if (err2) % try to read the data from the InflowWind file instead
            [oldIfWName] = GetFullFileName( InflowFileNoQuotes, oldDir );
            IfWP = Fast2Matlab(oldIfWName,3); % 3 header lines   
        end
                    
            % write new InflowWind file
        template = [templateDir filesep 'IfW_v3.01.x.dat'];  %template for new IfW file       
        Matlab2FAST(IfWP, template, newIfWname, 3); %contains 3 header lines            
        
    end
    
%%  %----------------------------------------------------------------------
    % Write new model data to the ElastoDyn input files:
    %----------------------------------------------------------------------
    template = [templateDir filesep 'ED_Primary_v1.03.x.dat'];  %template for primary file
    Matlab2FAST(EDPar,template,newEDName, 2); %contains 2 header lines
    
    
%%  %----------------------------------------------------------------------
    % Write new model data to the ServoDyn input files:
    %----------------------------------------------------------------------
    template = [templateDir filesep 'SrvD_Primary_v1.03.x.dat'];  %template for primary file
    Matlab2FAST(SrvDPar,template,newSrvDName, 2); %contains 2 header lines
    
    
%%  %----------------------------------------------------------------------
    % Write new model data to the FAST input files:
    %----------------------------------------------------------------------
    template   = [templateDir filesep 'FAST_Primary_v8.12.x.dat'];  %template for primary file
    Matlab2FAST(FP,template,newFSTname, 2); %contains 2 header lines


    
return

end
