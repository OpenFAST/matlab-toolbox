function [mainFSTFiles] = writeLinearizationFiles(templateFilenameFST, simulationFolder, OP_file_or_struct, varargin)
% Write OpenFAST inputs files to run linearizations at some operating points.
%
% INPUTS:
%  - templateFilenameFST: path to an OpenFAST file used as template to create linearization files. 
%          This template file should point to a valid ElastoDyn file, and,
%          depending on the linearization type, valid AeroDyn, InflowWind and Servodyn files.
%  - simulationFolder:  folder where input files will be written. 
%          Folder where OpenFAST simulation are run for the linearization.
%          OpenFAST Input files will be created there.
%          Should contain all the necessary files for a OpenFAST simulation
%          Will be created if does not exists
%
%  - OP_file_or_struct: 
%          path to a csv file that contains information about the Operating points see function readOperatingPoints for more.
%       or structure with (depending on simulation) fields: RotorSpeed, {optional: WindSpeed, GeneratorTorque, BladePitch, TowerTopDispFA, Filename}
%
% OPTIONAL INPUTS:
%  - varargin is a set of ('key', value) pairs.
%            Look at `opts` below for the different options, and default values.
%
% OUTPUTS:
%  - mainFSTFiles: list of fullpath to the FST files generated
% 
%
% Inspired by script from Bonnie Jonkman
% (c) 2016 National Renewable Energy Laboratory
% (c) 2018 Envision Energy, USA

% --- Optional arguments
OptsFields={'writeVTKmodes','simTime','CompAero','CompInflow','CompServo','TrimGainPitch','TrimGainGenTorque','NLinTimes'};
opts=struct();
% Default values
opts.simTime           = 300  ; % time in seconds that the first linearization output will happen (maximum time to converge to steady-state solution).  Default value 300s
opts.TrimGainPitch     = 0.001; % [only for OpenFAST>2.3] Gain for Pitch trim (done around Max Torque)
opts.TrimGainGenTorque = 300  ; % [only for OpenFAST>2.3] Gain for GenTrq trim (done below Max Torque)
opts.writeVTKmodes     = false; % [only for OpenFAST>2.3] Export VTK for mode shape visualizations
opts.CompAero          = NaN  ; % Turn Aero   compputation on/off, overrides template file
opts.CompInflow        = NaN  ; % Turn Inflow computation on/off, overrides template file
opts.CompServo         = NaN  ; % Turn Servo  compuation on/off, overrides template file
opts.NLinTimes         = 36   ; % Number of linearization times
% Values input by users % NOTE: inputParser not available in Octave
if nargin >=4
    for iOpts = 1:length(OptsFields)
        i = find( strcmp( varargin, OptsFields{iOpts}) == 1);
        if ~isempty(i)
            opts.(OptsFields{iOpts}) = varargin{i + 1};
        end
    end
end

% --- Read operating points
[mainFSTFiles, OP] = getFullFilenamesOP(simulationFolder, OP_file_or_struct);

% --- Read Main FST template file
FP = FAST2Matlab(templateFilenameFST,2); % Fast Parameters, specify 2 lines of header (FAST 8)
[templateDir, baseName, ext ] = fileparts(templateFilenameFST);
if strcmp(templateDir,filesep)
    templateDir = ['.' filesep];
end
CompInflow = GetFASTPar(FP,'CompInflow');
CompServo  = GetFASTPar(FP,'CompServo') ;
CompAero   = GetFASTPar(FP,'CompAero')  ;
hasTrim  = any(strcmp(FP.Label,'TrimGain'));

% --- Handling template overrides from user inputs
if ~isnan(opts.CompAero)
    opts.CompAero=opts.CompAero;
else
    opts.CompAero=CompAero;
end
if ~isnan(opts.CompInflow)
    opts.CompInflow=opts.CompInflow;
else
    opts.CompInflow=CompInflow;
end
if ~isnan(opts.CompServo)
    opts.CompServo=opts.CompServo;
else
    opts.CompServo=CompServo;
end
fprintf('Linearization Options: \n')
opts


% --- Read sub template files
[paramED, templateFilenameED] = GetFASTPar_Subfile(FP, 'EDFile'    , templateDir, templateDir);
if opts.CompInflow
    [paramIW, templateFilenameIW] = GetFASTPar_Subfile(FP, 'InflowFile', templateDir, templateDir);
end
if opts.CompServo
    [paramSD, templateFilenameSD] = GetFASTPar_Subfile(FP, 'ServoFile' , templateDir, templateDir);
end
if opts.CompAero
    [paramAD, templateFilenameAD] = GetFASTPar_Subfile(FP, 'AeroFile'  , templateDir, templateDir);
end


% --- Creating simulation folder
if ~exist(simulationFolder, 'dir');
    mkdir(simulationFolder)
end


% --- Safety and consistency checks
if ~isfield(OP,'RotorSpeed')
    error('RotorSpeed field needs to be provided in OP');
end

if (opts.CompInflow > 0) && ~isfield(OP,'WindSpeed')
    error('WindSpeed field needs to be provided in OP when CompInflow is true')
end
if opts.CompAero
    if length(paramAD.Label)==0
        error('Template AeroDyn file couldnt be read, but CompAero is >0: %s',templateFilenameAD)
    end
    if GetFASTPar(paramAD,'WakeMod')!=1 
        warning('WakeMod should be 1 for now when using linearization')
    end
    if GetFASTPar(paramAD,'AFAeroMod')!=1 
        warning('AFAeroMod should be 1 for now when using linearization')
    end
    if ~GetFASTPar(paramAD,'FrozenWake')
        warning('FrozenWake should be true for now when using linearization')
    end

    % Small attempt to reduce burden, we copy AeroDyn file if different folder is used. 
    % NOTE: not fully general, and this should be done for other module files as well..
    [~,base,ext] = fileparts(templateFilenameAD);
    fullPathAD = normpath([simulationFolder '/'  base ext]); 
    copyfile(templateFilenameAD, fullPathAD);

end
if opts.CompServo
    if length(paramSD.Label)==0
        error('Template ServoDyn file couldnt be read, but CompServo is >0: %s',templateFilenameSD)
    end
    if ~isfield(OP,'GeneratorTorque')
        error('GeneratorTorque field needs to be provided in OP when CompServo is true');
    end
    GenTrq= OP.GeneratorTorque;
    MaxTrq=max(GenTrq); % We'll use this to determine which trim to do 

    if ~ismember(GetFASTPar(paramSD,'PCMode'),[0])
        error('When CompServo is 1, the PCMode should be 0 or 1');
    end
    if ~ismember(GetFASTPar(paramSD,'VSContrl'),[0,1])
        error('When CompServo is 1, the VSContrl should be 0 or 1');
    end

else
    GenDOF = lower(GetFASTPar(paramED,'GenDOF'));
    if GenDOF(1)=='t'
        error('When CompServo is 0, the generator DOF should be turned off in ElastoDyn');
    end
end


% --- 
fprintf('Points:  %d\n',OP.nOP)
fprintf('Folder:  %s\n',simulationFolder)
fprintf('Writing input files...\n')
for iOP = OP.nOP:-1:1

    % --- Filenames and fullpaths for this operating point input files
    % NOTE: something nicer should be done with relpath compared to mainFST
    fullPathFST     = mainFSTFiles{iOP}                        ;  % Full filename of fst file
    [fdir, base,~]  = fileparts(fullPathFST)                   ; % Basename for subfiles
    fullBase        = normpath([simulationFolder '/'  base])   ; % Full basename for subfiles
    fullPathIW  = [fullBase '_IW.dat'];
    fullPathED  = [fullBase '_ED.dat'];
    fullPathSD  = [fullBase '_SrvD.dat'];
    filenameIW  = [base     '_IW.dat'];
    filenameED  = [base     '_ED.dat'];
    filenameSD  = [base     '_SrvD.dat'];

    % --- Figuring out the linearization times based on RPM. If we have trim, LinTime is not relevant
    Omega = OP.RotorSpeed(iOP)/60*2*pi;
    if abs(Omega)<0.001
        NLinTimes = 1;
        LinTimes = [opts.simTime];
        Tmax     = opts.simTime+1;
    else
        NLinTimes = opts.NLinTimes;
        T = 2*pi/Omega;
        LinTimes = linspace(opts.simTime,opts.simTime+T,NLinTimes+1);
        LinTimes = LinTimes(1:end-1);
        Tmax     = opts.simTime+1.01*T;
    end
    if hasTrim && opts.CompServo>0
        % Then we just simulate one period
        Tmax=T*1.01;
    end

    if hasTrim && opts.CompServo>0 
        %if (OP.WindSpeed(iOP) > RatedWindSpeed && CompAero > 0)
        % We trim using pitch if we are within 5% of Max Torque
        if (abs(OP.GeneratorTorque(iOP)-MaxTrq)/MaxTrq*100 < 5  && opts.CompAero > 0)
            TrimCase = 3; % Adjust Pitch to get desired RPM
            % TrimGain = .1 / (RotSpeed(iOP) * pi/30); %-> convert RotSpeed to rad/s
            % TrimGain = TrimGain*0.1
            TrimGain = opts.TrimGainPitch; 
        else
            TrimCase = 2; % Adjust GenTorque to get desired RPM
            % TrimGain = 3340 / (RotSpeed(iOP) * pi/30); %-> convert RotSpeed to rad/s
            TrimGain = opts.TrimGainGenTorque; 
        end
    end

    % Modify and write InflowWind file
    if opts.CompInflow > 0
        paramIW_mod = SetFASTPar(paramIW    ,'WindType'  ,1);
        paramIW_mod = SetFASTPar(paramIW_mod,'HWindSpeed',OP.WindSpeed(iOP));      
        Matlab2FAST(paramIW_mod, templateFilenameIW, fullPathIW, 2); %contains 2 header lines
    end
    % Modify and write AeroDyn file
    % ... burden put on user

    % Modify and write ServoDyn file
    if opts.CompServo > 0 
        paramSD_mod = SetFASTPar(paramSD,'VS_RtTq',OP.GeneratorTorque(iOP));
        Matlab2FAST(paramSD_mod, templateFilenameSD, fullPathSD, 2); %contains 2 header lines
    end
        
    % Modify and write ElastoDyn file
    paramED_mod = SetFASTPar(paramED    ,'RotSpeed',  OP.RotorSpeed(iOP));
    if isfield(OP,'BladePitch')
        paramED_mod = SetFASTPar(paramED_mod,'BlPitch(1)',OP.BladePitch(iOP));       
        paramED_mod = SetFASTPar(paramED_mod,'BlPitch(2)',OP.BladePitch(iOP));       
        paramED_mod = SetFASTPar(paramED_mod,'BlPitch(3)',OP.BladePitch(iOP));
    end
    if isfield(OP,'TowerTopDispFA')
        paramED_mod = SetFASTPar(paramED_mod,'TTDspFA',OP.TowerTopDispFA(iOP));
    end
    Matlab2FAST(paramED_mod, templateFilenameED, fullPathED, 2); %contains 2 header lines

    % Modify and write Main file
    FP_mod = SetFASTPar(FP    ,'EDFile'    ,['"' filenameED '"']);
    FP_mod = SetFASTPar(FP_mod,'InflowFile',['"' filenameIW '"']);
    FP_mod = SetFASTPar(FP_mod,'ServoFile' ,['"' filenameSD '"']);

    FP_mod = SetFASTPar(FP_mod,'TMax'      ,Tmax      );
    FP_mod = SetFASTPar(FP_mod,'Linearize' ,'true'    );
    FP_mod = SetFASTPar(FP_mod,'NLinTimes' ,NLinTimes );
    FP_mod = SetFASTPar(FP_mod,'CompAero'  ,opts.CompAero  );
    FP_mod = SetFASTPar(FP_mod,'CompServo' ,opts.CompServo );
    FP_mod = SetFASTPar(FP_mod,'CompInflow',opts.CompInflow);
    if hasTrim 
        if opts.CompServo>0 
            % New method
            FP_mod = SetFASTPar(FP_mod,'CalcSteady','true');
            FP_mod = SetFASTPar(FP_mod,'TrimCase', TrimCase);
            FP_mod = SetFASTPar(FP_mod,'TrimGain', TrimGain); 
            FP_mod = SetFASTPar(FP_mod,'TrimTol', 1e-3);
            FP_mod = SetFASTPar(FP_mod,'Twr_Kdmp', 0);
            FP_mod = SetFASTPar(FP_mod,'Bld_Kdmp', 0);
        else % TODO There might actually be an option to Trim without Servo
            FP_mod = SetFASTPar(FP_mod,'CalcSteady','false');
            FP_mod = SetFASTPar(FP_mod,'LinTimes',LinTimes);
        end
    else
        FP_mod = SetFASTPar(FP_mod,'LinTimes',LinTimes);
    end
    if hasTrim && opts.writeVTKmodes
        FP_mod = SetFASTPar(FP_mod,'WrVTK'     ,3                 );
        FP_mod = SetFASTPar(FP_mod,'VTK_type'  ,1                 );
        FP_mod = SetFASTPar(FP_mod,'VTK_fields','true'            );
    end
    FP_mod = SetFASTPar(FP_mod,'OutFmt','"ES20.12E3"'); % make sure we get enough digits of precision
    Matlab2FAST(FP_mod, templateFilenameFST, fullPathFST, 2); %contains 2 header lines
end % Loop on operating points

fprintf('Done. Make sure all the necessary inputs files to run an OpenFAST simulation are present\n in the folder %s\n',simulationFolder);
end

function s=normpath(s)
    s = strrep(strrep(s, '//','/'),'\','/');
end
