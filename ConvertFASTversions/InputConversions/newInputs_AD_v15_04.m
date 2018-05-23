function [ADPar] = newInputs_AD_v15_04(ADPar)
%[ADPar] = newInputs_AD_v15_04(ADPar)
% ADPar is the data structure containing already-filled parameters for
%       AeroDyn, which will be modified for AeroDyn v15.04.

n   = length(ADPar.Label);    

%% Cavitation options:
[~, err1] = GetFASTPar(ADPar,'CavitCheck');        %Perform cavitation check? (flag)
if err1
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

%% Add DBEMT fields?
[~, err1] = GetFASTPar(ADPar,'DBEMT_Mod');
if err1
   n = n + 1;
   ADPar.Label{n} = 'DBEMT_Mod';
   ADPar.Val{n}   = 2;
   
   n = n + 1;
   ADPar.Label{n} = 'tau1_const';
   ADPar.Val{n}   = 4.0;
end

%% Add SkewModFactor fields
[~, err1] = GetFASTPar(ADPar,'SkewModFactor');
if err1
   n = n + 1;
   ADPar.Label{n} = 'SkewModFactor';
   ADPar.Val{n}   = '"default"';
end

return;
