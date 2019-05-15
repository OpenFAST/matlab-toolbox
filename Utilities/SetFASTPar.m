% Function for getting fast parameter
% In:   FASTPar     -   Fast parameter structure
%       Par         -   Parameter string
%       Value       -   Value to set parameter to
% Out:  Result     -   Function call result (1+ Success, -1 Failure)  
%
% Knud A. Kragh %edited by Paul Fleming

function FASTPar=SetFASTPar(FASTPar,Par,Value)

found = false;
for i=1:length(FASTPar.Label)
    if strcmp(FASTPar.Label{i},Par)
        FASTPar.Val{i} = Value;
        found = true;
    end
end

if ~found
    i = length(FASTPar.Label) + 1;
    disp(['Parameter ' Par ' not found; adding it to data structure.'])
    FASTPar.Label{i} = Par;
    FASTPar.Val{i} = Value;
end
