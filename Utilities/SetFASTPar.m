% Function for getting fast parameter
% In:   FASTPar     -   Fast parameter structure
%       Par         -   Parameter string
%       Value       -   Value to set parameter to
% Out:  Result     -   Function call result (1+ Success, -1 Failure)  
%
% Knud A. Kragh %edited by Paul Fleming

function FASTParOut=SetFASTPar(FASTPar,Par,Value)
FASTParOut = [];
for i=1:length(FASTPar.Label)
    if strcmp(FASTPar.Label{i},Par)
        FASTPar.Val{i} = Value;
        FASTParOut = FASTPar;
    end
end

if isempty(FASTParOut)
    error('Parameter not found')
end
