% ----------- Perfrom CCE Eigenanalysis ------------------------------------
% Find eigenvalues and eigenvectors of the azimuth-averaged state matrix, AvgAMat:

% Inputs:
%  AMat(1:ns,1:ns,NAzimStep)
%  AvgAMat(1:ns,1:ns)
%  NAzimStep
% -----------------------------------------------------
% Find eigenvalues and eigenvectors of AMat at each azimuth step:

  for L = 1:NAzimStep
   [Eigenvectors(:,:,L), Eigenvalues(:,:,L) ] = eig( AMat(:,:,L) );
  end
%-------------------------------------------------------
% Find eigenvalues and eigenvectors of the azimuth-averaged state matrix, AvgAMat:
   %  call function 'eianalysis' to obtain the following
   %    nss                : number of re-sequenced states
   %    EigenVects         : nsXns
   %    Evals              : nsX1
   %    eigenVects         : ndofXnss
   %    eigenVals          : nssX1
   %    DampedFrequencies  : nssX1
   %    DampedFreqs_Hz     : nssX1
   %    NaturalFrequencies : nssX1
   %    NaturalFreqs_Hz    : nssX1
   %    DecrementRate      : nssX1
   %    DampRatios         : nssX1
   %    MagnitudeModes     : ndofXnss
   %    PhaseModes_deg     : ndofXnss

  [EigenVects,eigenVects,Evals,eigenVals,DampedFrequencies,DampedFreqs_Hz,NaturalFrequencies,...
   NaturalFreqs_Hz,DecrementRate,DampRatios,MagnitudeModes,PhaseModes_deg,nss] = eianalysis(AvgAMat);

   AvgEigenvectors = EigenVects;
   AvgEvals = Evals;
   AvgeigenVects = eigenVects;
   AvgeigenVals = eigenVals;

% Find the natural frequencies, damped frequencies, and damping ratios for
%   the azimuth-averaged state matrix:

AvgDampedFrequency    = DampedFrequencies;
AvgDampedFrequencyHz  = DampedFreqs_Hz;
AvgNaturalFrequency   = NaturalFrequencies;
AvgNaturalFrequencyHz = NaturalFreqs_Hz;
AvgDecrementRate = DecrementRate;
AvgDampingRatio       = DampRatios;
AvgModeShapeMagnitude = MagnitudeModes;
AvgModeShapePhaseDeg  = PhaseModes_deg;

% ----------- Clear unneeded variables -------------------------------
clear EigenVects eigenVects Evals eigenVals DampedFrequencies DampedFreqs_Hz NaturalFrequencies;
clear NaturalFreqs_Hz DecrementRate DampRatios MagnitudeModes PhaseModes_deg

% ----------- cce finished ----------------------------------------------

% Tell the user that we are finished:
disp( '                                      ' );
disp( 'cce.m completed             ' );
disp( 'Type "who" to list available variables' );

%%%xcce=[AvgDecrementRate  AvgDampedFrequencyHz  AvgDampingRatio*100 AvgNaturalFrequencyHz]'
