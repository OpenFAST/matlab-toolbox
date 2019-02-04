function [ f1, Sf1, f1_Bin, Sf1_Bin ] = getPSD( Data, df, N, CreatePlot, BinLen )
%function [ f, S1 ] = getPSD( Data, df )
%This function calculates the 1-sided PSD directly using fft
%
%Inputs:
%   "Data" is the time series data
%   "df" is the frequency step in Hz = 1/tmax
%   Optional: "N" is the number of steps to be processed by the fft
%   Optional" "CreatePlot" is a flag for plotting
%   Optional: "BinLen" is the number of frequency steps to bin the fft by
%
%Outputs:
%   "f1" are the 1-sided frequencies in Hz
%   "Sf1" is the 1-sided PSD in the units of [Data's unit]^2/Hz
%   Optional: "f1_Bin" are the binned 1-sided frequencies in Hz
%   Optional: "Sf1_Bin" is the binned 1-sided PSD in the units of [Data's unit]^2/Hz
%
%Internals:
%   "NData" is the number of steps in Data
%   "N2" is half the number of steps to be processed by the fft
%   "domega" is the frequency step in rad/s
%   "Data_fft" is the DFT of Data
%   "omega1" are the 1-sided frequencies in rad/s
%   "Somega1" is the 1-sided PSD in the units of [Data's unit]^2/(rad/s) 
%   "omega2" are the 2-sided frequencies in rad/s
%   "Somega2" is the 2-sided PSD in the units of [Data's unit]^2/(rad/s) 
%   "f2" are the 2-sided frequencies in Hz
%   "Sf2" is the 2-sided PSD in the units of [Data's unit]^2/(Hz) 

NData  = length(Data);
if nargin < 3 || ( nargin >= 3 && isempty(N) )
    N = NData;
end
if mod(N,2) == 1
    disp( 'Aborting: N must be even in Jason_PSD.' );  
    return;
end
N2 = N/2;
domega   = 2*pi*df;
Data_fft = fft(Data,N); %truncate Data or pad Data with zeros if N /= length(Data)

%Compute 2-sided psds:
omega2  = domega*[ 0:N2 (-N2+1):(-1) ]';
Somega2 = ( Data_fft/N ).*( conj( Data_fft/N ) )/domega;

f2  = omega2 /( 2*pi );
Sf2 = Somega2*( 2*pi );

%Compute 1-sided psds:
omega1  = omega2 (1:N2);
Somega1 = Somega2(1:N2)*2;

f1  = f2 (1:N2);
Sf1 = Sf2(1:N2)*2;

% Bin the PSDs:
if nargin >= 5 && nargout == 4
    MaxLen = length(f1);
    Bins   = 1:BinLen:MaxLen;
    NBins  = length(Bins);

    f1_Bin  = zeros(NBins,1);
    Sf1_Bin = zeros(NBins,1);

    for iBin = 1:NBins
        BinStart = Bins(iBin);
        BinIx    = BinStart:min(MaxLen,(BinStart+BinLen-1));

        f1_Bin (iBin) = mean( f1 (BinIx) );
        Sf1_Bin(iBin) = mean( Sf1(BinIx) );
    end
elseif nargout ~= 2
    disp( 'Aborting: Incorrect arguments in Jason_PSD.' );  
    return;
end

%Plot the PSDs:
if nargin >= 4 && CreatePlot
    figure;
    semilogy(f1,Sf1,'b.','DisplayName','Raw');
    if nargin >= 5
        hold on;
        semilogy(f1_Bin,Sf1_Bin,'r-','DisplayName','Binned');
        hold off;
    end
    xlabel('Frequency, Hz')
    ylabel('PSD, [Data''s unit]^2/Hz')
    legend(gca,'show');
end

