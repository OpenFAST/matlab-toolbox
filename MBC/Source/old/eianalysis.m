function [EigenVects,eigenVects,Evals,eigenVals,DampedFrequencies,DampedFreqs_Hz,NaturalFrequencies,...
NaturalFreqs_Hz,DecrementRate,DampRatios,MagnitudeModes,PhaseModes_deg,nss] = eianalysis(Ain)
% Compute eivals and eivects of Ain. Re-sequence eivals assumoing that the subset of all complex eivals
% appear as conjugates. Generate re-sequencing id vector. Compute corresponding damped freqs, natural freqs,
% decrement rates, damping ratios, eivectors, modal amplitudes, and phases.

% Input:
%  Ain = input nsxns matrix (ns=number of states)

% Outputs:
%  nss                : number of re-sequenced states
%  EigenVects         : nsXns
%  Evals              : nsX1
%  eigenVects         : ndofXnss
%  eigenVals          : nssX1
%  DampedFrequencies  : nssX1
%  DampedFreqs_Hz     : nssX1
%  NaturalFrequencies : nssX1
%  NaturalFreqs_Hz    : nssX1
%  DecrementRate      : nssX1
%  DampRatios         : nssX1
%  MagnitudeModes     : ndofXnss
%  PhaseModes_deg     : ndofXnss

%NOTE: MatLab macro eig cannot handle repeated-eivals-associated eivects. Tackle this later.
%--------------------
   [m ns] = size(Ain);
   if(m~=ns)
    display('**ERROR: the state-space matrix is not a square matrix');
    return
   end

   if(mod(ns,2) ~= 0)
    display('**ERROR: the input matrix is is not of even order');
    return
   end
   ndof = ns/2;

   EigenVects=[]; EigenVals=[]; Evals=[];
  [EigenVects, EigenVals] = eig(Ain);
   Evals = diag(EigenVals);
% find new sequence association with the old sequence
  nseq_assoc = [];
  j=0;
  for i = 1:ns
   if(imag(Evals(i)) >= 0)
    j=j+1;
    nseq_assoc(j) = i;
   end
  end
  nseq_assoc = nseq_assoc';
  [nss m]= size(nseq_assoc);

  eigenVals = [];
  for j =1: nss
   eigenVals(j) = Evals(nseq_assoc(j));
   eigenVects(1:ndof,j) = EigenVects(1:ndof,nseq_assoc(j));
  end
  eigenVals =transpose(eigenVals);
   real_eigenVals = real(eigenVals);
   imag_eigenVals = imag(eigenVals);

   DampedFrequencies = imag_eigenVals;
   DampedFreqs_Hz = DampedFrequencies/(2*pi);
   NaturalFrequencies = sqrt(real_eigenVals.*real_eigenVals+imag_eigenVals.*imag_eigenVals);
   NaturalFreqs_Hz = NaturalFrequencies/(2*pi);

   DecrementRate = -real_eigenVals;
   DampRatios = -real_eigenVals./NaturalFrequencies;
   DampRatios(DampRatios == -1) = -Inf;
   DampRatios(DampRatios == 1) = Inf;

   MagnitudeModes = abs(eigenVects);
   PhaseModes_deg = angle(eigenVects)*180/pi;

% determine dof associated with indeterminate damping ratios
%%   indt_dof =[];
%%
%%    for k = 1: ndof;
%%      if (NaturalFrequencies(k) == 0.0)
%%        indt_dof = [indt_dof;k];
%%      end
%%    end
%%
%%    if (size(indt_dof) > 0)
%%      display(' ***WARNING: the following dof have indeterminate daming ratio (because the corrp natural frquency is zero)');
%%      [indt_dof];
%%      display(' -------------------');
%%    end


clear EigenVals real_eigenVals imag_eigenVals i j m ndof ns;