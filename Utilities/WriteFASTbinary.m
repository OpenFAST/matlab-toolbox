%WriteFASTbinary(Channels, ChanName, ChanUnit, DescStr, FileName, compress)
% Author: Jens Geisler
% (c) 2021 Flensburg University of Applied Sciences
%
% Input:
%  Channels      - 2-D array: dimension 1 is time, dimension 2 is channel
%                  first channel is expected to be time
%  ChanName      - cell array containing names of output channels
%  ChanUnit      - cell array containing unit names of output channels
%  FileName      - string: contains file name to write to. existing file
%                  will be overwritten
%  compressed    - optional (default is false): write channel data in
%                  compressed form
%                  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function WriteFASTbinary(Channels, ChanName, ChanUnit, DescStr, FileName, compress)

if ~exist('compress', 'var')
    compress= false;
end

TimeIncr= mean(diff(Channels(:, 1)));
UniformTime= Channels(1, 1) + TimeIncr*(0:size(Channels, 1)-1);
with_time= max(abs( Channels(:, 1)-UniformTime' )) > eps;

if with_time
    max_val= max(Channels(:, 1));
    min_val= min(Channels(:, 1));
    range= max_val-min_val;
    range(range<=0)= 1;

    TimeScl= (double(intmax('int32')) - double(intmin('int32')) - 2.0) / range;
    TimeOff= double(intmin('int32')) - min_val.*TimeScl;

    PackedTime= int32(Channels(:, 1) * TimeScl + TimeOff);
    
    compress= true;
end

TimeOut= Channels(1);
Channels= Channels(:, 2:end);

if compress
    max_val= max(Channels);
    min_val= min(Channels);
    range= max_val-min_val;
    range(range<=0)= 1;

    ColScl= single((double(intmax('int16')) - double(intmin('int16')) - 2.0) ./ range);
    ColOff= single(double(intmin('int16')) - min_val.*ColScl);

    PackedData= zeros(size(Channels), 'int16');
    for i_ch= 1:size(Channels, 2)
        PackedData(:, i_ch)= int16(Channels(:, i_ch) * ColScl(i_ch) + ColOff(i_ch));
    end
end

fid= fopen(FileName, 'w');

if with_time
    fwrite(fid, 1, 'int16');
else
    if compress
        fwrite(fid, 2, 'int16');
    else
        fwrite(fid, 3, 'int16');
    end
end

fwrite(fid, size(Channels, 2), 'int32');
fwrite(fid, size(Channels, 1), 'int32');
        
if with_time
    fwrite(fid, TimeScl, 'double');
    fwrite(fid, TimeOff, 'double');
else    
    fwrite(fid, TimeOut, 'double');
    fwrite(fid, TimeIncr, 'double');
end

if compress
    fwrite(fid, ColScl, 'single');
    fwrite(fid, ColOff, 'single');
end

fwrite(fid, length(DescStr), 'int32');
fwrite(fid, DescStr, 'char');
        
for i_ch= 1:length(ChanName)
    ch_name= ChanName{i_ch};
    if length(ch_name)>10
        ch_name= ch_name(1:10);
    end
    ch_name= sprintf('%-10s', ch_name);
    fwrite(fid, ch_name, 'char');
end

for i_ch= 1:length(ChanUnit)
    ch_unit= ChanUnit{i_ch};
    if length(ch_unit)>10
        ch_unit= ch_unit(1:10);
    end
    ch_unit= sprintf('%-10s', ch_unit);
    fwrite(fid, ch_unit, 'char');
end
        
if compress
    if with_time
        fwrite(fid, PackedTime', 'int32');
    end        
    fwrite(fid, PackedData', 'int16');
else
    fwrite(fid, Channels', 'double');
end
        
fclose(fid);