function [mbc] = eiganalysis(A)
% Compute eivals and eivects of A. Re-sequence eivals assumoing that the subset of all complex eivals
% appear as conjugates. Generate re-sequencing id vector. Compute corresponding damped freqs, natural freqs,
% decrement rates, damping ratios, eivectors, modal amplitudes, and phases.

% Input:
%  A = input ns x ns matrix (ns=number of states)
         
% Outputs:
%  EigenVals          : ns X 1
%  EigenVects         : ndof X nzs (nzs = # non-zero eVals)
%  Evals              : nzs X 1
%  DampedFrequencies  : nzs X 1
%  DampedFreqs_Hz     : nzs X 1
%  NaturalFrequencies : nzs X 1
%  NaturalFreqs_Hz    : nzs X 1
%  DampRatios         : nzs X 1
%  MagnitudeModes     : ndof X nzs (ndof = ns/2)
%  PhaseModes_deg     : ndof X nzs
%  NumRigidBodyModes  : 1x1 (equal to ndof - nzs)
%--------------------
    [m, ns] = size(A);
    ndof = ns/2;
    if(m~=ns)
        error('**ERROR: the state-space matrix is not a square matrix');
    end

    if(mod(ns,2) ~= 0)
        error('**ERROR: the input matrix is is not of even order');
    end

[mbc.EigenVects, mbc.Evals] = eig(A,'vector'); %,'nobalance'
% mbc.EigenVals = mbc.Evals; % save for later analysis if desired
% errorInSolution = norm(A * mbc.EigenVects - mbc.EigenVects* diag(mbc.EigenVals) )

% % % % if there are exactly 2 real eigenvalues, we know they are a pair
% % % zeroEvals = find( imag(mbc.Evals) == 0 );
% % % if sum(zeroEvals) == 2
% % %     mbc.RealEvals = mbc.Evals(zeroEvals);
% % %     mbc.RealEigenVects = mbc.EigenVects(1:ndof,zeroEvals);
% % % end

%% we're going to throw out the modes that have zero frequency or are
% critically or overdamped (i.e., abs(DampingRatio)>=1) 
% (this is because we don't get eigenvalue pairs from eig()):
nonzeroEvals = find( imag(mbc.Evals) > 0);

mbc.Evals      = mbc.Evals(nonzeroEvals);
mbc.EigenVects = mbc.EigenVects(1:ndof,nonzeroEvals);

%% loop through the pairs of eigenvalues
real_Evals = real(mbc.Evals);
imag_Evals = imag(mbc.Evals);

mbc.NaturalFrequencies = sqrt( real_Evals.^2 + imag_Evals.^2 );
mbc.NaturalFreqs_Hz = mbc.NaturalFrequencies./(2*pi);

mbc.DampRatios = -real_Evals ./ mbc.NaturalFrequencies;

mbc.DampedFrequencies  = imag_Evals;
mbc.DampedFreqs_Hz     = mbc.DampedFrequencies./(2*pi);
%%
mbc.MagnitudeModes = abs(mbc.EigenVects(1:ndof,:));
mbc.PhaseModes_deg = angle(mbc.EigenVects(1:ndof,:))*180/pi;
%%
mbc.NumRigidBodyModes = ndof - length(nonzeroEvals);



