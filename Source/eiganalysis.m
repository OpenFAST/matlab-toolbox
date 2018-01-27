function [mbc] = eiganalysis(Ain)
% Compute eivals and eivects of Ain. Re-sequence eivals assumoing that the subset of all complex eivals
% appear as conjugates. Generate re-sequencing id vector. Compute corresponding damped freqs, natural freqs,
% decrement rates, damping ratios, eivectors, modal amplitudes, and phases.

% Input:
%  Ain = input ns x ns matrix (ns=number of states)
         
% Outputs:
%  EigenVects         : ns X ns
%  Evals              : ns X 1
%  DampedFrequencies  : ns X 1
%  DampedFreqs_Hz     : ns X 1
%  NaturalFrequencies : ns X 1
%  NaturalFreqs_Hz    : ns X 1
%  DampRatios         : ns X 1
%  MagnitudeModes     : ndof X ns (ndof = ns/2)
%  PhaseModes_deg     : ndof X ns
%--------------------
    [m ns] = size(Ain);
    if(m~=ns)
        error('**ERROR: the state-space matrix is not a square matrix');
    end

    if(mod(ns,2) ~= 0)
        error('**ERROR: the input matrix is is not of even order');
    end

[mbc.EigenVects, EigenVals] = eig(Ain);
mbc.Evals = diag(EigenVals);
    
%% we're going to throw out the modes that have zero frequency or are
% critically or overdamped (i.e., abs(DampingRatio)>=1) 
% (this is because we don't get eigenvalue pairs from eig()):
nonzeroEvals = find( imag(mbc.Evals) > 0);
mbc.Evals      = mbc.Evals(nonzeroEvals);
mbc.EigenVects = mbc.EigenVects(1:(ns/2),nonzeroEvals);

%% loop through the pairs of eigenvalues
real_Evals = real(mbc.Evals);
imag_Evals = imag(mbc.Evals);

mbc.NaturalFrequencies = sqrt( real_Evals.^2 + imag_Evals.^2 );
mbc.NaturalFreqs_Hz = mbc.NaturalFrequencies./(2*pi);

mbc.DampRatios = -real_Evals ./ mbc.NaturalFrequencies;

mbc.DampedFrequencies  = imag_Evals;
mbc.DampedFreqs_Hz     = mbc.DampedFrequencies./(2*pi);
%%
mbc.MagnitudeModes = abs(mbc.EigenVects(1:(ns/2),:));
mbc.PhaseModes_deg = angle(mbc.EigenVects(1:(ns/2),:))*180/pi;


