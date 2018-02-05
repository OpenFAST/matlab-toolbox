function [enFASTdataStruct]=ReadEnFASThdf5(FileName)
%[enFASTdataStruct] = ReadEnFASThdf5(FileName)
% Author: Andy Platt, Envision Energy
% (c) 2018, Envision Energy
%
%  Input:
%     FileName          - string: contains file name to open
%
%  Output:
%     enFASTdataStruct  - structure containing all read data from the file
%
%  where the enFASTdataStruct contains the following (similar structure as in file):
%
%     Model             - information on the model
%        Primary_enFAST_input_file  - Name of the primary input file used in this simulation
%        enFAST_output_file         - Name of the output file originally generated
%        ModelDesc                  - First line of primary input file
%     SimResults        - Simulation results
%        ChanNames                  - Names of channels
%        ChanUnits                  - Units for each channel
%        TDC                        - the time domain data results (includes time column)
%        Time                       - the timesteps of results
%     Simulation        - The setup of the simulation
%        enFAST_run_info            - Info enFAST prints at run.
%        SimExecutionDate           - Date simulation was run
%        SimExecutionTime           - Time simulation was run
%        enFAST_version             - Version info for enFAST (includes compile info)
%        Primary_enFAST_input_file  - Name of the primary input file used in this simulation (same as Model.Primary_enFAST_input_file)
%        enFAST_output_file         - Name of the output file originally generated (same as Model.enFAST_output_file)
%        ModelDesc                  - Model description (same as Model.ModelDesc)
%        SimDT                      - Timestep used in the simulation calculations
%        SimDurationPlanned         - Planned time for the simulation
%        SimDurationActual          - Acutal amount of time simulated.  If it matcheds the SimDurationPlanned, the simulation completed as expected
%        enFAST_Module_Info         - Structure containing Name, Ver, and Date for each module
%     Statistics        - Calculated statistics for each channel
%        ChanMaxTStep               - Timestep of maximum value of channel
%        ChanMaxVal                 - Maximum value of channel
%        ChanMean                   - Mean value of channel
%        ChanMinTStep               - Timestep of minimum value of channel
%        ChanMinVal                 - Timestep of minimujm value of channel
%        ChanStDev                  - Standard deviation of channel
%
%
%  Compatibility with ReadFASTbinary.m:
%  The equavalent of the ReadFASTbinary.m outputs are:
%
%     Channels     = enFASTdataStruct.SimResults.TDC;
%     ChannelNames = enFASTdataStruct.SimResults.ChanNames;
%     ChannelUnits = enFASTdataStruct.SimResults.ChanUnits;
%     FieID        = 0;    % Not produced.
%     DescStr      = enFASTdataStruct.DescStr;
%
%

%% Check the file
if exist(FileName, 'file') == 0
   error(['File ' FileName ' not found.'])
end

%% Read some File info
% Note:  to explore the contents of a file, use:
%        FileInfo=h5info(FileName);

enFASTdataStruct.enFAST_HDF5_format_version = h5readatt(FileName,'/','enFAST HDF5 format version');

%% Read the model info
% Note:  the next attributes are also in the /Simulation group.
enFASTdataStruct.Model.Primary_enFAST_input_file = h5readatt(FileName,'/Model','Primary enFAST input file');
enFASTdataStruct.Model.enFAST_output_file        = h5readatt(FileName,'/Model','enFAST output file');
enFASTdataStruct.Model.ModelDesc                 = h5readatt(FileName,'/Model','ModelDesc');



%% Read the simulation info
% Note:  this section contains basic model information including timesteps
%        used during the simulation etc.  Also the module information is
%        available for checking what modules were actually run.
enFASTdataStruct.Simulation.enFAST_run_info           = h5readatt(FileName,'/Simulation','enFAST_run_info');
enFASTdataStruct.Simulation.SimExecutionDate          = h5readatt(FileName,'/Simulation','SimExecutionDate');
enFASTdataStruct.Simulation.SimExecutionTime          = h5readatt(FileName,'/Simulation','SimExecutionTime');
enFASTdataStruct.Simulation.enFAST_version            = h5readatt(FileName,'/Simulation','enFAST_version');
enFASTdataStruct.Simulation.SimDT                     = h5readatt(FileName,'/Simulation','SimDT');
enFASTdataStruct.Simulation.SimDurationPlanned        = h5readatt(FileName,'/Simulation','SimDurationPlanned');
enFASTdataStruct.Simulation.SimDurationActual         = h5readatt(FileName,'/Simulation','SimDurationActual');
enFASTdataStruct.Simulation.Primary_enFAST_input_file = h5readatt(FileName,'/Simulation','Primary enFAST input file');
enFASTdataStruct.Simulation.enFAST_output_file        = h5readatt(FileName,'/Simulation','enFAST output file');
enFASTdataStruct.Simulation.ModelDesc                 = h5readatt(FileName,'/Simulation','ModelDesc');
temp=h5read(FileName,'/Simulation/enFAST_Module_Info');
enFASTdataStruct.Simulation.enFAST_Module_Info.Name = transpose(temp.Name);
enFASTdataStruct.Simulation.enFAST_Module_Info.Ver  = transpose(temp.Ver);
enFASTdataStruct.Simulation.enFAST_Module_Info.Date = transpose(temp.Date);
% For DescStr:
ModVer=([' linked with ']);
for i=1:size(enFASTdataStruct.Simulation.enFAST_Module_Info.Name,1)
    ModVer=([ModVer ' ' strtrim(enFASTdataStruct.Simulation.enFAST_Module_Info.Name(i,:)) ' (' strtrim(enFASTdataStruct.Simulation.enFAST_Module_Info.Ver(i,:)) ', ' strtrim(enFASTdataStruct.Simulation.enFAST_Module_Info.Date(i,:)) ');']);
end
enFASTdataStruct.DescStr=([enFASTdataStruct.Simulation.enFAST_run_info ModVer ' Description from the FAST input file: ' enFASTdataStruct.Simulation.ModelDesc]);



%% Read the SimResults
% Note:  The TDC is compressed using ZLib in the HDF5 writer.  You will
%        need ZLib to decompress this dataset.
% Note:  The TDC array is transposed to have index 1 as timestep, index 2
%        as channel.  All further data reads (channel names etc) follow
%        this convention.
enFASTdataStruct.SimResults.NumChans     =           h5readatt(FileName,'/SimResults','NumChans');
enFASTdataStruct.SimResults.NumTSteps    =           h5readatt(FileName,'/SimResults','NumTSteps');
enFASTdataStruct.SimResults.Time         =           h5read   (FileName,'/SimResults/Time');
enFASTdataStruct.SimResults.TDC          = zeros(enFASTdataStruct.SimResults.NumTSteps,enFASTdataStruct.SimResults.NumChans+1);
enFASTdataStruct.SimResults.TDC(:,1)     = enFASTdataStruct.SimResults.Time;
enFASTdataStruct.SimResults.TDC(:,2:end) = transpose(h5read   (FileName,'/SimResults/TDC'));
% Prepend the Time channel.
tempName=h5read(FileName,'/SimResults/ChanNames');
tempUnit=h5read(FileName,'/SimResults/ChanUnits');
enFASTdataStruct.SimResults.ChanNames{1,1} = 'Time';
enFASTdataStruct.SimResults.ChanUnits{1,1} = '(s)';
for i=1:size(tempName,1)
   enFASTdataStruct.SimResults.ChanNames{i+1,1}=strtrim(tempName{i,1});
   enFASTdataStruct.SimResults.ChanUnits{i+1,1}=strtrim(tempUnit{i,1});
end


%% Read the Statistics
% Note:  the transpose is to put everything into the orientation we are
%        used to using in MATLAB.  Your use case may be different.
enFASTdataStruct.Statistics.ChanMaxTStep = transpose(h5read   (FileName,'/Statistics/ChanMaxTStep'));
enFASTdataStruct.Statistics.ChanMaxVal   = transpose(h5read   (FileName,'/Statistics/ChanMaxVal'));
enFASTdataStruct.Statistics.ChanMinTStep = transpose(h5read   (FileName,'/Statistics/ChanMinTStep'));
enFASTdataStruct.Statistics.ChanMinVal   = transpose(h5read   (FileName,'/Statistics/ChanMinVal'));
enFASTdataStruct.Statistics.ChanMean     = transpose(h5read   (FileName,'/Statistics/ChanMean'));
enFASTdataStruct.Statistics.ChanMaxTStep = transpose(h5read   (FileName,'/Statistics/ChanMaxTStep'));
enFASTdataStruct.Statistics.ChanStDev    = transpose(h5read   (FileName,'/Statistics/ChanStDev'));



return;
end
