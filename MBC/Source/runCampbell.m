%
% by Bonnie Jonkman
% (c) 2016 National Renewable Energy Laboratory
% (c) 2018 Envision Energy, USA
%--------------------------------------------------------------------------

%% let's get the directory that contains the template files
templateDir = [ '..\..\ConvertFASTversions\TemplateFiles'];

IfWtemplate  = [templateDir filesep 'InflowWind.dat'];
SrvDtemplate = [templateDir filesep 'ServoDyn.dat'];
EDtemplate   = [templateDir filesep 'ElastoDyn.dat']; 
FASTtemplate = [templateDir filesep 'OpenFAST.dat']; 

VizTemplate = [templateDir filesep 'OpenFAST-Modes.viz'];
WriteVTKmodes = true;
WriteFASTfiles = true;

WriteVTKmodes = false;
% WriteFASTfiles = false;

%% Executable and base file:       
FASTexe = '..\..\bin\openFAST_Win32.exe';
FSTName = 'OpenFAST.fst';

VizFile = 'OpenFAST-Modes.viz';
%----------------------------------------------------------------------
%% Read data from original files (for modification):
[oldDir, baseName, ext ] = fileparts(FSTName);
if strcmp(oldDir,filesep)
    oldDir = ['.' filesep];
end

XLSname = [baseName '-CampbellData.xlsx']; % name for spreadsheet to write

FP = FAST2Matlab(FSTName,2); %FP are Fast Parameters, specify 2 lines of header (FAST 8)

[IfWP, InflowFile] = GetFASTPar_Subfile(FP, 'InflowFile', oldDir, oldDir);
[SrvP, ServoFile]  = GetFASTPar_Subfile(FP, 'ServoFile',  oldDir, oldDir);
[EP, EDFile] = GetFASTPar_Subfile(FP, 'EDFile', oldDir, oldDir);

CompElast = GetFASTPar(FP, 'CompElast');
CompInflow = GetFASTPar(FP, 'CompInflow');
CompServo = GetFASTPar(FP, 'CompServo');
CompAero = GetFASTPar(FP, 'CompAero');

TipRad = GetFASTPar(EP, 'TipRad');
HubRad = GetFASTPar(EP, 'HubRad');
BladeLen  = TipRad - HubRad;
TowerLen = GetFASTPar(EP, 'TowerHt');


if WriteVTKmodes
    VizP = FAST2Matlab(VizFile,2);
    WrVTK = 3;
else
    WrVTK = 0;
end

%----------------------------------------------------------------------
%% modify data, write new files (if necessary), and run

% RotSpeedAry = 0:2:14; %10; %0:2:14; %rpm
% 
% 
% WindSpeedAry = [];
% CompInflow = 0;
% CompAero = 0;


%% ED 5MW values:
WindSpeedAry =[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]; %(m/sec)
RotSpeedAry = [6.972, 7.183, 7.506, 7.942, 8.469, 9.156, 10.296, 11.431, 11.89, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1, 12.1]; %(rpm)
BldPitch1   = [0, 0, 0, 0, 0, 0, 0, 0, 0, 3.823, 6.602, 8.668, 10.45, 12.055, 13.536, 14.92, 16.226, 17.473, 18.699, 19.941, 21.177, 22.347, 23.469]; % (deg)
GenTqAry    = [0.606, 2.58, 5.611, 9.686, 14.62, 20.174, 25.51, 31.455, 40.014, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094, 43.094]*1000; %(N-m)

SimTime   = 5600; % time in seconds that the first linearization output will happen (maximum time to converge to steady-state solution)
RatedWindSpeed = 11.4;

%%
nPoints = max( length(RotSpeedAry), length(WindSpeedAry) );

FAST_linData = cell(nPoints,1); % raw data read from FAST's .lin files
getMatData   = cell(nPoints,1); % FAST .lin data converted to format that MBC can process
MBC_data     = cell(nPoints,1); % processed MBC3 data
CampbellData = cell(nPoints,1);

%%
for i_case = nPoints:-1:1

    if (CompAero > 0)
        wkSheetName = [ num2str(WindSpeedAry(i_case)), ' mps' ];        
    else
        wkSheetName = [ num2str(RotSpeedAry(i_case)), ' RPM' ];
    end
    if ( RotSpeedAry(i_case) == 0 )
        NLinTimes = 1;
    else
        NLinTimes = 36;
    end        
    
    newFASTbase = [ baseName, '-', strrep(wkSheetName,' ','') ];
    newFSTName = [ newFASTbase ext ];
    FileNames = strcat( strrep(newFSTName, '.fst','.'), strrep( cellstr(num2str( (1:NLinTimes)' )), ' ', ''), '.lin' );
        
        
    if WriteFASTfiles
        if (WindSpeedAry(i_case) > RatedWindSpeed && CompAero > 0)
            GenTq    = 43094;
            TrimCase = 3;
%             TrimGain = .1 / (RotSpeedAry(i_case) * pi/30); %-> convert RotSpeed to rad/s
%             TrimGain = TrimGain*0.1
            TrimGain = 0.001;
        else
            GenTq = GenTqAry(i_case);        
            TrimCase = 2;
%             TrimGain = 3340 / (RotSpeedAry(i_case) * pi/30); %-> convert RotSpeed to rad/s
            TrimGain = 300;
        end

        
        % InflowWind
        if CompInflow > 0
            IfWP_mod = SetFASTPar(IfWP,'HWindSpeed',WindSpeedAry(i_case));      
            Matlab2FAST(IfWP_mod,IfWtemplate,  InflowFile, 2); %contains 2 header lines
        end

        
        % ServoDyn
        if CompServo > 0 
            SrvP_mod = SetFASTPar(SrvP,'VS_RtTq',GenTq);
            Matlab2FAST(SrvP_mod,SrvDtemplate, ServoFile,  2); %contains 2 header lines
        end
        
        
        % ElastoDyn
        EP_mod   = SetFASTPar(EP, 'RotSpeed',RotSpeedAry(i_case));

        if CompInflow > 0
            EP_mod   = SetFASTPar(EP_mod,'BlPitch(1)',BldPitch1(i_case));       
            EP_mod   = SetFASTPar(EP_mod,'BlPitch(2)',BldPitch1(i_case));       
            EP_mod   = SetFASTPar(EP_mod,'BlPitch(3)',BldPitch1(i_case));
        end

        Matlab2FAST(EP_mod, EDtemplate, EDFile,    2); %contains 2 header lines
        
        FP_mod = SetFASTPar(FP,'TMax',SimTime);
        FP_mod = SetFASTPar(FP_mod,'Linearize','true');
        FP_mod = SetFASTPar(FP_mod,'CalcSteady','true');
        FP_mod = SetFASTPar(FP_mod,'NLinTimes',NLinTimes);
        FP_mod = SetFASTPar(FP_mod,'TrimCase', TrimCase);
        FP_mod = SetFASTPar(FP_mod,'TrimGain', TrimGain); 
        FP_mod = SetFASTPar(FP_mod,'TrimTol', 1e-3);
        FP_mod = SetFASTPar(FP_mod,'Twr_Kdmp', 0);
        FP_mod = SetFASTPar(FP_mod,'Bld_Kdmp', 0);
        FP_mod = SetFASTPar(FP_mod,'OutFmt','"ES20.12E3"'); % make sure we get enough digits of precision
        FP_mod = SetFASTPar(FP_mod,'WrVTK',WrVTK);
        Matlab2FAST(FP_mod,FASTtemplate, newFSTName, 2); %contains 2 header lines

            %% Run FAST with new input files
        status = system([FASTexe ' ' newFSTName]);
    
        if status ~= 0 % check that we have some output here
            break
        end
        
    end
    
    %% Analyze results from .lin files (azimuth average)

    if WriteVTKmodes
        ModesVizName = [newFASTbase '.ModeShapeVTK' ];
        [MBC_data{i_case}, getMatData{i_case}, FAST_linData{i_case}] = fx_mbc3( FileNames, ModesVizName ); 

        VizP = SetFASTPar(VizP,'CheckpointRoot',strrep(newFSTName,'.fst', '.ModeShapeVTK'));
        VizP = SetFASTPar(VizP,'MatlabFileName',ModesVizName);
        Matlab2FAST(VizP,VizTemplate, VizFile, 2); %contains 2 header lines
        
        system( [FASTexe ' -VTKLin ' VizFile]);
        system(['copy fort.51 ' strrep( newFSTName, '.fst','.viz.51' )]);
    else
        [MBC_data{i_case}, getMatData{i_case}, FAST_linData{i_case}] = fx_mbc3( FileNames ); 
    end
    [CampbellData{i_case}] = campbell_diagram_data(MBC_data{i_case}, BladeLen, TowerLen, [], strrep(newFSTName,'.fst','.MBD.sum'));       
    
    % write results at this RPM/WindSpeed to Excel worksheet
    try
        xlswrite(XLSname, CampbellData{i_case}.ModesTable, wkSheetName); % create a worksheet with these modes
    catch
        disp(['warning::could not write Campbell data in Excel worksheet for ' wkSheetName]);
    end
    

end


%%
% [modeID_table, modesDesc] = IdentifyModes(CampbellData);
[modeID_table, modesDesc] = CampbellMatchModeNames(CampbellData);

%%
opTable = cell(3,nPoints+1);
opTable{1,1} = 'Operating Points';
opTable{2,1} = 'Wind Speed (mps)';
opTable{3,1} = 'Rotor Speed (rpm)';
for i=1:nPoints
    opTable{2,i+1} = CampbellData{i}.WindSpeed;
    opTable{3,i+1} = CampbellData{i}.RotSpeed_rpm;
end

%%
thisTable = cell(length(modesDesc)+2,nPoints+1);
thisTable{1,1} = 'Mode Number Table';
if (CompAero > 0)
    thisTable{2,1} = 'Wind Speed (mps)';
    thisTable(2,2:end) = num2cell(WindSpeedAry);
    wkSheetName = 'WS_ModesID';
else
    thisTable{2,1} = 'Rotor Speed (rpm)';
    thisTable(2,2:end) = num2cell(RotSpeedAry);
    wkSheetName = 'ModesID';
end
%%
for i = 1:length(modesDesc)
    thisTable(i+2,1) = modesDesc(i);
end
thisTable(3:end,2:end) = num2cell(modeID_table);

try
    xlswrite(XLSname, thisTable, wkSheetName); % create a worksheet with these modes
    xlswrite(XLSname, opTable, 'OP'); % create a worksheet with these operating points
catch
    disp(['warning::could not write modes identification data in Excel worksheet for ' wkSheetName]);
end


%%
[num,txt,CampbellPlotData] = Plot_CampbellData(XLSname,wkSheetName);
