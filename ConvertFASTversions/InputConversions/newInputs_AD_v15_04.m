function [ADPar, ADBladeRootname] = newInputs_AD_v15(ADPar, ADrootname)
%[ADPar] = newInputs_AD_v15(ADPar, ADrootname)
% ADPar is the data structure containing already-filled parameters for
%       AeroDyn, which will be modified for AeroDyn v15.
% ADrootname is the base file name (without path or extension) of the
%       AeroDyn input file [to set name of blade files]

%% Cavitation options:
n = length(ADPar.Label);
%[CavitCheck] = GetFASTPar(ADPar,'CavitCheck');        %Perform cavitation check? (flag)
if ~isfield(ADPar,'CavitCheck')
   n = n + 1;
   ADPar.Label{n} = 'CavitCheck';
   ADPar.Val{n}   = 'False';
   n = n + 1;
   ADPar.Label{n} = 'Patm';
   ADPar.Val{n}   = 103500;
   n = n + 1;
   ADPar.Label{n} = 'Pvap';
   ADPar.Val{n}   = 1700;
   n = n + 1;
   ADPar.Label{n} = 'FluidDepth';
   ADPar.Val{n}   = 0.1;
end


return;
