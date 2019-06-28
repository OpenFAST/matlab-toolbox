function [mbc] = eiganalysis(A, ndof2, ndof1)
% Compute eivals and eivects of A. Re-sequence eivals assumoing that the subset of all complex eivals
% appear as conjugates. Generate re-sequencing id vector. Compute corresponding damped freqs, natural freqs,
% decrement rates, damping ratios, eivectors, modal amplitudes, and phases.

% Input:
%  A = input ns x ns matrix (ns=number of states)
%      the states are assumed to be in order of {q2, q2_dot, q1}
         
% Outputs:
%  EigenVals          : ns X 1 (ns = 2*ndof2 + ndof1)
%  EigenVects         : ndof X nPos (nPos = # eVals with positive imaginary part)
%  EigenVects_q2_dot  : ndof2 X nPos (saved for mode-shape visualization)
%  Evals              : nPos X 1
%  DampedFrequencies  : nPos X 1
%  DampedFreqs_Hz     : nPos X 1
%  NaturalFrequencies : nPos X 1
%  NaturalFreqs_Hz    : nPos X 1
%  DampRatios         : nPos X 1
%  MagnitudeModes     : ndof X nPos (ndof = ndof2 + ndof1)
%  PhaseModes_deg     : ndof X nPos
%  NumRigidBodyModes  : 1x1 (equal to ndof - nPos)
%--------------------
[m, ns] = size(A);
if(m~=ns)
    error('**ERROR: the state-space matrix is not a square matrix.');
end

if nargin == 1
    ndof1 = 0;
    ndof2 = ns/2;

    if mod(ns,2) ~= 0
        error('**ERROR: the input matrix is not of even order.');
    end
elseif nargin == 2
    ndof1 = ns - 2*ndof2;
    if ndof1 < 0
        error('**ERROR: ndof2 must be no larger than half the dimension of the state-space matrix.');
    end            

else
    if ns ~= 2*ndof2 + ndof1
        error('**ERROR: the dimension of the state-space matrix must equal 2*ndof2 + ndof1.');
    end            
end

ndof = ndof2 + ndof1;

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
positiveImagEvals = find( imag(mbc.Evals) > 0);

mbc.Evals             = mbc.Evals(positiveImagEvals);
mbc.EigenVects_q2_dot = mbc.EigenVects(  (ndof2+1):(ndof2*2)      ,positiveImagEvals); % save for mode-shape visualization capability
mbc.EigenVects        = mbc.EigenVects([1:ndof2    (ndof2*2+1):ns],positiveImagEvals); % save q2 and q1, throw away q2_dot

%% loop through the pairs of eigenvalues
real_Evals = real(mbc.Evals);
imag_Evals = imag(mbc.Evals);

mbc.NaturalFrequencies = sqrt( real_Evals.^2 + imag_Evals.^2 );
mbc.NaturalFreqs_Hz = mbc.NaturalFrequencies./(2*pi);

mbc.DampRatios = -real_Evals ./ mbc.NaturalFrequencies;

mbc.DampedFrequencies  = imag_Evals;
mbc.DampedFreqs_Hz     = mbc.DampedFrequencies./(2*pi);
%%
mbc.MagnitudeModes = abs(mbc.EigenVects);
mbc.PhaseModes_deg = angle(mbc.EigenVects)*180/pi;
mbc.MagnitudeModes_q2_dot = abs(mbc.EigenVects_q2_dot);
mbc.PhaseModes_deg_q2_dot = angle(mbc.EigenVects_q2_dot)*180/pi;
%%
mbc.NumRigidBodyModes = ndof - length(positiveImagEvals);



