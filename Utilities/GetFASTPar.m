% Function for getting FAST parameter
% In:   FASTPar     -   FAST parameter structure
%       Par         -   Parameter string
% Out:  OutData     -   Value of input parameter   
%
% Knud A. Kragh

function [OutData,err,Indx]=GetFASTPar(FASTPar,Par)
err = false;
OutData=[];
Indx=0;
if isfield(FASTPar, 'Label')
    for i=1:length(FASTPar.Label)
        if strcmp(FASTPar.Label{i},Par)==1
            OutData=FASTPar.Val{i};
            Indx = i;
            return
        end
    end
end

if isempty(OutData)
    disp(['GetFASTPar:: Parameter ' Par ' not found.'])
    err = true;
end