function [cellarr, headers] = csv2cellarray(filename, varargin)
% Reads a csv file to a cellarray
%
% INPUTS
%  - filename: CSV filename (string)
%
% OPTIONAL INPUTS
%  - delim: delimiter for csv file
%
% OUTPUTS:
%  - ret : cell array, including header 
%
sep = ',';
nHeaderLines = 0;
ret={};
headers={};

if nargin >=2 % NOTE: inputParser not available in Octave
    % check for delimiter
    DelimiterIndex = find( strcmp( varargin, 'delimiter' ) == 1);
    if ~isempty(DelimiterIndex)
        sep = varargin{DelimiterIndex + 1};
    end
    % check for headers
    HeaderIndex = find( strcmp( varargin, 'header' ) == 1);
    if ~isempty(HeaderIndex)
        nHeaderLines = varargin{HeaderIndex + 1};
    end
end
% open file
f = fopen(filename);
if f < 0
    error('Unable to open file %s',filename)
    return
end

% Read headers
headers=cell(1,nHeaderLines);
if nHeaderLines > 0
    for i = 1:nHeaderLines
        headers{i}=fgetl(f);
    end
end
% read file values into one string
ret = fread (f, 'char=>char').';
fclose(f);

% Split into lines
ret = regexp(ret,'(\n)+','split'); % lines
% count fields
nFieldMax=0;
for il = 1:length(ret)
    nFieldMax=max([nFieldMax, length(strfind(ret{il},','))+1]);
end

% Split each line and store in cellarray
cellarr = cell(length(ret), nFieldMax);
cellarr(:,:)={''};
for il = 1:length(ret)
    sp = regexp(strtrim(ret{il}), sep,'split');
    cellarr(il,1:length(sp)) = sp;
end

% remove empty lines
B=all(cellfun(@(x)length(x)==0, cellarr(:,:)),2);
cellarr=cellarr(~B,:);

% remove empty columns (only the ones at the end)
nCol=size(cellarr,2);
B=all(cellfun(@(x)length(x)==0, cellarr(:,:)),1);
IB  = fliplr(find(B)); % index of empty columns
IB2 = nCol:-1:nCol-length(IB)+1; % indices of empty columns if started from the end
IB  = IB(IB-IB2==0); % keeping only the ones that do are at the end
IKeep = setdiff(1:nCol,IB);
cellarr=cellarr(:,IKeep);
