% Function for getting fast parameter
% In:   FastPar     -   Fast parameter structure
%       Par         -   Parameter string
% Out:  OutData     -   Value of input parameter   
%
% Knud A. Kragh

function [OutData,err,Indx]=GetFastPar(FastPar,Par)
err = false;
OutData=[];
Indx=0;
if isfield(FastPar, 'Label')
    for i=1:length(FastPar.Label)
        if strcmp(FastPar.Label{i},Par)==1
            OutData=FastPar.Val{i};
            Indx = i;
            return
        end
    end
end

if isempty(OutData)
    disp(['GetFastPar:: Parameter ' Par ' not found.'])
    err = true;
end