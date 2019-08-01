function [ SteadyState ] = readSteadyState( fileName )
%%
wantedChannels = {'GenTrq','B1PitchAng','RotSpeed'};

if length(fileName) > 4 && strcmpi( fileName((end-4):end),'.outb' )
    [Channels, ChannelNames, ChannelUnits] = ReadFASTbinary(fileName);
else
    [Channels, ChannelNames, ChannelUnits] = ReadFASTtext(fileName);
end

ChanIndx = strcmpi(ChannelNames,'Wind1VelX');
Channels(:,ChanIndx) = round( Channels(:,ChanIndx), 1);
nt = size(Channels,1);

TimeIndx = true(nt,1);
TimeIndx(1:(nt-1)) = abs( Channels(1:(nt-1),ChanIndx) - Channels(2:nt,ChanIndx) ) > 0.1 & Channels(1:(end-1),ChanIndx) > 2; % more than 2 m/s

SteadyState.WindSpeed = Channels(TimeIndx,ChanIndx);

for i=1:length(wantedChannels)
    ChanIndx = strcmpi(ChannelNames,wantedChannels{i});
    SteadyState.(wantedChannels{i}) = Channels(TimeIndx,ChanIndx);
end

