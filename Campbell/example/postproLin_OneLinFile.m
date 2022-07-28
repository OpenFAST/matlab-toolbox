%% Documentation   
% Standalone script to post-process one linearization file from OpenFAST. 
% NOTE: this should not be used if the rotor is turning. 
% This script would typically be used for a standstill analysis (no rotation), 
% or to compute modes of when only isolated degrees of freedom are turned on (and no rotation).
%  
% 

%% Initialization
clear all; close all; 
restoredefaultpath;
addpath(genpath('C:/Work/FAST/matlab-toolbox/')); % TODO adapt me

%% Script Parameters
BladeLen     = 103               ; % Blade length, used to tune relative modal energy [m]
TowerLen     = 137               ; % Tower length, used to tune relative modal energy [m]
lin_file     = 'compare_lin/bar_urc_stab_13_F.1.lin'; % Linearization file
nModesMax    = 10                  ; % Maximum number of modes to be shown
nCharMaxDesc = 30                  ; % Maximum number of characters for description written to screen

%% Derived parameters
outputFile = strrep(lin_file, '.1.lin','_ModesSummary.csv');
lin_files = {lin_file};

%% Performing MBC (NOTE: not stricly necessary without rotation)
[mbc_data, matData, FAST_linData] = fx_mbc3( lin_files );
[CampbellData] = campbell_diagram_data(mbc_data, BladeLen, TowerLen); %, xlsFileName);

%% Outputs to screen and save to file
CD=CampbellData;
fid=fopen(outputFile,'w');
fprintf(    'Mode, NatFreq_[Hz], Damp_Ratio_[-], LogDec._[%%], Mode_content_[-]\n')
fprintf(fid,'Mode, NatFreq_[Hz], Damp_Ratio_[-]\n')
nModesMax = min(length(CD.NaturalFreq_Hz),nModesMax);

Freq=zeros(1,nModesMax);
Damp=zeros(1,nModesMax);
for i = 1:nModesMax
    Desc=CD.Modes{i}.DescStates(CD.Modes{i}.StateHasMaxAtThisMode);
    DescCat='';
    DescCatED='';
    if length(Desc)==0
        DescCat = '' ;
        DescCatED = 'NoMax -' ;
        Desc = CD.Modes{i}.DescStates(1:5);
    end
    nBD=0;
    % This is replaceModeDescription
    for iD=1:length(Desc)
        s=Desc{iD};
        s = strrep(s,'First time derivative of'     ,'d/dt of');
        s = strrep(s,'fore-aft bending mode DOF, m'    ,'FA'     );
        s = strrep(s,'side-to-side bending mode DOF, m','SS'     );
        s = strrep(s,'bending-mode DOF of blade '    ,''     );
        s = strrep(s,' rotational-flexibility DOF, rad','-rot'   );
        s = strrep(s,'rotational displacement in ','rot'   );
        s = strrep(s,'translational displacement in ','trans'   );
        s = strrep(s,', rad','');
        s = strrep(s,', m','');
        s = strrep(s,'finite element node ','N'   );
        s = strrep(s,'cosine','cos'   );
        s = strrep(s,'sine','sin'   );
        s = strrep(s,'collective','coll.');
        s = strrep(s,'Blade','Bld');
        s = strrep(s,'rotZ','TORS-ROT');
        s = strrep(s,'transX','FLAP-DISP');
        s = strrep(s,'transY','EDGE-DISP');
        s = strrep(s,'rotX','EDGE');
        s = strrep(s,'rotY','FLAP');
        if Desc{iD}(1:2)=='BD'
            nBD=nBD+1;
        elseif Desc{iD}(1:2)=='ED'
            DescCatED = [s ' - ' DescCatED];
        else
            DescCat = [DescCat ' - ' s];
        end
    end
    DescCat=[DescCatED, DescCat];
    if nBD>0
        DescCat = sprintf('BD%d/%d %s',nBD,sum(CD.Modes{i}.StateHasMaxAtThisMode),DescCat);
    end
    fprintf(    '%3d ,%12.3f, %8.5f       , %7.4f,  %s \n',i, CD.NaturalFreq_Hz(i), CD.DampingRatio(i), CD.DampingRatio(i)*100*2*pi, DescCat(1:min(nCharMaxDesc,length(DescCat))));
    fprintf(fid,'%3d ,%12.3f, %8.5f\n'        ,i, CD.NaturalFreq_Hz(i),CD.DampingRatio(i));
    Freq(i)=CD.NaturalFreq_Hz(i);
    Damp(i)=CD.DampingRatio(i);
end
fclose(fid);
disp(['Outputs written to ',outputFile ])

