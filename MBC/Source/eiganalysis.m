function [mbc, EigenVects_save] = eiganalysis(A, ndof2, ndof1)
% Compute eivals and eivects of A. Re-sequence eivals assumoing that the subset of all complex eivals
% appear as conjugates. Generate re-sequencing id vector. Compute corresponding damped freqs, natural freqs,
% decrement rates, damping ratios, eivectors, modal amplitudes, and phases.

% Input:
%  A = input ns x ns matrix (ns=number of states)
%      the states are assumed to be in order of {q2, q2_dot, q1}
         
% Outputs:
%  EigenVals          : ns X 1 (ns = 2*ndof2 + ndof1)
%  EigenVects         : ndof X nPos (nPos = # eVals with positive imaginary part)
%  Evals              : nPos X 1
%  DampedFrequencies  : nPos X 1
%  DampedFreqs_Hz     : nPos X 1
%  NaturalFrequencies : nPos X 1
%  NaturalFreqs_Hz    : nPos X 1
%  DampRatios         : nPos X 1
%  MagnitudeModes     : ndof X nPos (ndof = ndof2 + ndof1)
%  PhaseModes_deg     : ndof X nPos
%  NumRigidBodyModes  : 1x1 (equal to ndof - nPos)
%  EigenVects_save    : (ndof+ndof2) X nPos (saved for mode-shape visualization)
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

[origEigenVects, origEvals] = eig(A,'vector'); %,'nobalance'
% errorInSolution = norm(A * mbc.EigenVects - mbc.EigenVects* diag(mbc.EigenVals) )

% these eigenvalues aren't sorted, so we just take the ones with
% positive imaginary parts to get the pairs for modes with damping < 1:
positiveImagEvals = find( imag(origEvals) > 0);

mbc.Evals             = origEvals(positiveImagEvals);
mbc.EigenVects        = origEigenVects([1:ndof2  (ndof2*2+1):ns],positiveImagEvals); % save q2 and q1, throw away q2_dot
    EigenVects_save   = origEigenVects(:,positiveImagEvals); % save these for VTK visualization;


real_Evals = real(mbc.Evals);
imag_Evals = imag(mbc.Evals);

mbc.NaturalFrequencies = sqrt( real_Evals.^2 + imag_Evals.^2 );
mbc.DampRatios = -real_Evals ./ mbc.NaturalFrequencies;
mbc.DampedFrequencies  = imag_Evals;

mbc.NumRigidBodyModes = ndof - length(positiveImagEvals);

% % % if ndof1 == 0 && mbc.NumRigidBodyModes == 1 
% % % %% second-order system (let's look for the over-damped values):
% % % % I'm limiting this to one pair because otherwise I don't have an algorithm
% % % % to determine what the "pairs" of real eigenvalues are
% % %     
% % %     realEvalpair = find( imag(origEvals) == 0 );    
% % %     if length(realEvalpair) ~= 2
% % %         error('invalid assumption in eigenalysis.');
% % %     end   
% % %     n = length(positiveImagEvals) + 1;
% % %     
% % %     mbc.Evals(n)               = origEvals(                                 realEvalpair(1));
% % %     mbc.EigenVects(:,n)        = origEigenVects([1:ndof2    (ndof2*2+1):ns],realEvalpair(1)); % save q2 and q1, throw away q2_dot
% % %         EigenVects_save(:,n)   = origEigenVects(:,                          realEvalpair(1)); % save these for VTK visualization;
% % %        
% % %     mbc.NaturalFrequencies(n) = sqrt( realEvalpair(1).*realEvalpair(2) );
% % %     mbc.DampRatios(n)         = 0.5 .* (-realEvalpair(1) - realEvalpair(2)) ./ mbc.NaturalFrequencies(n);
% % %     mbc.DampedFrequencies(n)  = 0;
% % %     
% % %     mbc.NumRigidBodyModes = 0;
% % % end 
mbc.NaturalFreqs_Hz = mbc.NaturalFrequencies./(2*pi);
mbc.DampedFreqs_Hz  = mbc.DampedFrequencies ./(2*pi);

mbc.MagnitudeModes  = abs(mbc.EigenVects);
mbc.PhaseModes_deg  = angle(mbc.EigenVects)*180/pi;
%%



