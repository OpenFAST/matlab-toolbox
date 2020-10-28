% Function for getting FAST parameter
% In:   FASTPar     -   FAST parameter structure
%       Par         -   Parameter string
% Out:  OutData     -   Value of input parameter   
%
% Knud A. Kragh

function [OutData,err,Indx]=GetFASTPar(FASTPar,Par,ReturnIndx)
err = false;
OutData=[];
Indx=0;
iCnt = 1;
if nargin<3
    ReturnIndx = 1; % by default, return the first time we see this value
end

if isfield(FASTPar, 'Label')
    for i=1:length(FASTPar.Label)
        if strcmpi(FASTPar.Label{i},Par)==1
            OutData=FASTPar.Val{i};
            Indx = i;
            if iCnt == ReturnIndx
                return
            end
            
            iCnt = iCnt + 1;
        end
    end
end

if isempty(OutData)
    disp(['GetFASTPar:: Parameter ' Par ' not found.'])
    err = true;
end