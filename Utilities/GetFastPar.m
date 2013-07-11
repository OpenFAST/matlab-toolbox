% Function for getting fast parameter
% In:   FastPar     -   Fast parameter structure
%       Par         -   Parameter string
% Out:  OutData     -   Value of input parameter   
%
% Knud A. Kragh

function [OutData,err]=GetFastPar(FastPar,Par)
err = false;
OutData=[];
for i=1:length(FastPar.Label)
    if strcmp(FastPar.Label{i},Par)==1
        OutData=FastPar.Val{i};
    end
end

if isempty(OutData)
    disp(['ERROR in GetFastPar: Parameter ' Par ' not found.'])
    err = true;
end