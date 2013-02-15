% Function for getting fast parameter
% In:   FastPar     -   Fast parameter structure
%       Par         -   Parameter string
%       Value       -   Value to set parameter to
% Out:  Result     -   Function call result (1+ Success, -1 Failure)  
%
% Knud A. Kragh %edited by Paul Fleming

function FastParOut=SetFastPar(FastPar,Par,Value)
FastParOut = [];
for i=1:length(FastPar.Label)
    if strcmp(FastPar.Label{i},Par)
        FastPar.Val{i} = Value;
        FastParOut = FastPar;
    end
end

if isempty(FastParOut)
    error('Parameter not found')
end
