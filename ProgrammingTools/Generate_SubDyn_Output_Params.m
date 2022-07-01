clear; clc;

maxNumMember = 99; % 80;
maxNumNode   = 9;
maxNumMode   = 99;

out = fopen('SubDyn_Output_Params.f90','w');

fprintf(out,'%s\n','module SubDyn_Output_Params');
fprintf(out,'%s\n','   use NWTC_Library');
fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Indices for computing output channels:');
fprintf(out,'%s\n','   ! NOTES: ');
fprintf(out,'%s\n','   !    (1) These parameters are in the order stored in "OutListParameters.xlsx"');
fprintf(out,'%s\n','   !    (2) Array AllOuts() must be dimensioned to the value of the largest output parameter');
fprintf(out,'%s\n','   IMPLICIT                         NONE');
fprintf(out,'%s\n','');
fprintf(out,'%s\n','   PUBLIC');
fprintf(out,'%s\n','');
fprintf(out,'%s\n','   !  Time: ');
fprintf(out,'%s\n','   INTEGER, PARAMETER             :: Time      =     0');
fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Member Forces:');
fprintf(out,'%s\n','');

outIdx = 0;
allOutNames = cell(0,0);

channels = {'FKxe','FKye','FKze','FMxe','FMye','FMze',...
    'MKxe','MKye','MKze','MMxe','MMye','MMze'};
for channelNo = 1:length(channels)
    channel = channels{channelNo};
    for member = 1:maxNumMember
        for node = 1:maxNumNode
            outIdx = outIdx + 1;
            outName = pad(['M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel],10);
            allOutNames = [allOutNames {outName}];
            line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
            fprintf(out,'%s\n',line);
        end
    end
end

fprintf(out,'%s\n',''); fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Displacements:'); fprintf(out,'%s\n','');

channels = {'TDxss','TDyss','TDzss','RDxe','RDye','RDze'};
for channelNo = 1:length(channels)
    channel = channels{channelNo};
    for member = 1:maxNumMember
        for node = 1:maxNumNode
            outIdx = outIdx + 1;
            outName = pad(['M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel],10);
            allOutNames = [allOutNames {outName}];
            line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
            fprintf(out,'%s\n',line);
        end
    end
end

fprintf(out,'%s\n',''); fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Accelerations:'); fprintf(out,'%s\n','');

channels = {'TAxe','TAye','TAze','RAxe','RAye','RAze'};
for channelNo = 1:length(channels)
    channel = channels{channelNo};
    for member = 1:maxNumMember
        for node = 1:maxNumNode
            outIdx = outIdx + 1;
            outName = pad(['M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel],10);
            allOutNames = [allOutNames {outName}];
            line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
            fprintf(out,'%s\n',line);
        end
    end
end

fprintf(out,'%s\n',''); fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Reactions:'); fprintf(out,'%s\n','');

channels = {'FXss','FYss','FZss','MXss','MYss','MZss'};
for channelNo = 1:length(channels)
    channel = channels{channelNo};
    outIdx = outIdx + 1;
    outName = pad(['React' channel],11);
    allOutNames = [allOutNames {outName}];
    line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
    fprintf(out,'%s\n',line);
end
for channelNo = 1:length(channels)
    channel = channels{channelNo};
    outIdx = outIdx + 1;
    outName = pad(['Intf' channel],11);
    allOutNames = [allOutNames {outName}];
    line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
    fprintf(out,'%s\n',line);
end

fprintf(out,'%s\n',''); fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Interface Deflections:'); fprintf(out,'%s\n','');

channels = {'TDXss','TDYss','TDZss','RDXss','RDYss','RDZss'};
for channelNo = 1:length(channels)
    channel = channels{channelNo};
    outIdx = outIdx + 1;
    outName = pad(['Intf' channel],10);
    allOutNames = [allOutNames {outName}];
    line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
    fprintf(out,'%s\n',line);
end

fprintf(out,'%s\n',''); fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Interface Accelerations:'); fprintf(out,'%s\n','');

channels = {'TAXss','TAYss','TAZss','RAXss','RAYss','RAZss'};
for channelNo = 1:length(channels)
    channel = channels{channelNo};
    outIdx = outIdx + 1;
    outName = pad(['Intf' channel],10);
    allOutNames = [allOutNames {outName}];
    line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
    fprintf(out,'%s\n',line);
end

fprintf(out,'%s\n',''); fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! Modal Parameters:'); fprintf(out,'%s\n','');

for modeNo = 1:maxNumMode
    outIdx = outIdx + 1;
    outName = pad(['SSqm' pad(num2str(modeNo),2,'left','0')],10);
    allOutNames = [allOutNames {outName}];
    line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
    fprintf(out,'%s\n',line);
end
for modeNo = 1:maxNumMode
    outIdx = outIdx + 1;
    outName = pad(['SSqmd' pad(num2str(modeNo),2,'left','0')],10);
    allOutNames = [allOutNames {outName}];
    line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
    fprintf(out,'%s\n',line);
end
for modeNo = 1:maxNumMode
    outIdx = outIdx + 1;
    outName = pad(['SSqmdd' pad(num2str(modeNo),2,'left','0')],10);
    allOutNames = [allOutNames {outName}];
    line = ['   INTEGER(IntKi), PARAMETER      :: ' outName '= ' pad(num2str(outIdx),5,'left')];
    fprintf(out,'%s\n',line);
end

fprintf(out,'%s\n',''); fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! The maximum number of output channels which can be output by the code.');
fprintf(out,'%s\n',['   ! INTEGER(IntKi), PARAMETER    :: MaxOutPts = ' num2str(outIdx)]);
fprintf(out,'%s\n','');
fprintf(out,'%s\n','   ! End of code generated by Matlab script');
fprintf(out,'%s\n','');

channels = {'FKxe','FKye','FKze','MKxe','MKye','MKze'};
fprintf(out,'%s',['   INTEGER, PARAMETER             :: MNfmKe(6,' num2str(maxNumNode) ',' num2str(maxNumMember) ') = reshape((/']);
for member = 1:maxNumMember
    for node = 1:maxNumNode
        if member == 1 && node == 1
            line = '';
        else
            line = '                                                                ';
        end
        for channelNo = 1:length(channels)
            channel = channels{channelNo};
            line = [line 'M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel ','];
        end
        
        if member == maxNumMember && node == maxNumNode
            line = [line(1:end-1) '/),(/6,' num2str(maxNumNode) ',' num2str(maxNumMember) '/))'];
        else
            line = [line ' & '];
        end
        fprintf(out,'%s\n',line);
    end
end

fprintf(out,'%s\n','   '); fprintf(out,'%s\n','  '); fprintf(out,'%s\n','   ');
channels = {'FMxe','FMye','FMze','MMxe','MMye','MMze'};
fprintf(out,'%s',['   INTEGER, PARAMETER             :: MNfmMe(6,' num2str(maxNumNode) ',' num2str(maxNumMember) ') = reshape((/']);
for member = 1:maxNumMember
    for node = 1:maxNumNode
        if member == 1 && node == 1
            line = '';
        else
            line = '                                                                ';
        end
        for channelNo = 1:length(channels)
            channel = channels{channelNo};
            line = [line 'M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel ','];
        end
        
        if member == maxNumMember && node == maxNumNode
            line = [line(1:end-1) '/),(/6,' num2str(maxNumNode) ',' num2str(maxNumMember) '/))'];
        else
            line = [line ' &'];
        end
        fprintf(out,'%s\n',line);
    end
end

fprintf(out,'%s\n','                                                                  ');
channels = {'TDxss','TDyss','TDzss'};
fprintf(out,'%s',['   INTEGER, PARAMETER             :: MNTDss(3,' num2str(maxNumNode) ',' num2str(maxNumMember) ') = reshape((/']);
for member = 1:maxNumMember
    for node = 1:maxNumNode
        if member == 1 && node == 1
            line = '';
        else
            line = '                                                                ';
        end
        for channelNo = 1:length(channels)
            channel = channels{channelNo};
            line = [line 'M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel ','];
        end
        
        if member == maxNumMember && node == maxNumNode
            line = [line(1:end-1) '/), (/3,' num2str(maxNumNode) ',' num2str(maxNumMember) '/))'];
        else
            line = [line ' &'];
        end
        fprintf(out,'%s\n',line);
    end
end

fprintf(out,'%s\n','');
channels = {'RDxe','RDye','RDze'};
fprintf(out,'%s',['   INTEGER, PARAMETER             :: MNRDe (3,' num2str(maxNumNode) ',' num2str(maxNumMember) ') = reshape((/']);
for member = 1:maxNumMember
    for node = 1:maxNumNode
        if member == 1 && node == 1
            line = '';
        else
            line = '                                                                ';
        end
        for channelNo = 1:length(channels)
            channel = channels{channelNo};
            line = [line 'M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel ','];
        end
        
        if member == maxNumMember && node == maxNumNode
            line = [line(1:end-1) '/), (/3,' num2str(maxNumNode) ',' num2str(maxNumMember) '/))'];
        else
            line = [line ' &'];
        end
        fprintf(out,'%s\n',line);
    end
end

fprintf(out,'%s\n','                                                              '); fprintf(out,'%s\n','   ');
channels = {'TAxe','TAye','TAze','RAxe','RAye','RAze'};
fprintf(out,'%s',['   INTEGER, PARAMETER             :: MNTRAe(6,' num2str(maxNumNode) ',' num2str(maxNumMember) ') = reshape((/']);
for member = 1:maxNumMember
    for node = 1:maxNumNode
        if member == 1 && node == 1
            line = '';
        else
            line = '                                                                ';
        end
        for channelNo = 1:length(channels)
            channel = channels{channelNo};
            line = [line 'M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel ','];
        end
        
        if member == maxNumMember && node == maxNumNode
            line = [line(1:end-1) '/), (/6,' num2str(maxNumNode) ',' num2str(maxNumMember) '/))'];
        else
            line = [line '  &'];
        end
        fprintf(out,'%s\n',line);
    end
end

fprintf(out,'%s\n','');
fprintf(out,'%s\n','      INTEGER, PARAMETER             :: ReactSS(6)   =  (/ReactFXss, ReactFYss, ReactFZss, &');
fprintf(out,'%s\n','                                                          ReactMXss, ReactMYss, ReactMZss/)');
% fprintf(out,'%s\n','');
fprintf(out,'%s\n','      INTEGER, PARAMETER             :: IntfSS(6)    =  (/IntfFXss,  IntfFYss,  IntfFZss , &');
fprintf(out,'%s\n','                                                          IntfMXss,  IntfMYss,  IntfMZss/)');
% fprintf(out,'%s\n','');
% fprintf(out,'%s\n','');
fprintf(out,'%s\n','      INTEGER, PARAMETER             :: IntfTRss(6)  =  (/IntfTDXss, IntfTDYss, IntfTDZss, &');
fprintf(out,'%s\n','                                                          IntfRDXss, IntfRDYss, IntfRDZss/)');
% fprintf(out,'%s\n','');
fprintf(out,'%s\n','      INTEGER, PARAMETER             :: IntfTRAss(6) =  (/IntfTAXss, IntfTAYss, IntfTAZss, &');
fprintf(out,'%s\n','                                                          IntfRAXss, IntfRAYss, IntfRAZss/)');
% fprintf(out,'%s\n',''); fprintf(out,'%s\n','   '); fprintf(out,'%s\n','   ');
% fprintf(out,'%s\n','   '); fprintf(out,'%s\n','  '); fprintf(out,'%s\n','');
fprintf(out,'%s\n',' ');

allOutNamesSorted = sort(allOutNames);

entryPerLine = 7;

halfOutIdx = ceil(outIdx/2);
fprintf(out,'%s\n',['   CHARACTER(10), PARAMETER  :: ValidParamAry1(' num2str(halfOutIdx) ') =  (/ &                  ! This lists the names of the allowed parameters, which must be sorted alphabetically']);
ctr = 0;
while ctr<halfOutIdx
    is = ctr+1;
    if (ctr+entryPerLine) >= halfOutIdx
        ie = halfOutIdx;
        bLastLine = true;
    else
        ie = ctr+entryPerLine;
        bLastLine = false;
    end
    line = '                               ';
    for j = is:ie
        line = [line '"' pad(strtrim(upper(allOutNamesSorted{j})),10) '",'];
    end
    if bLastLine
        line = [line(1:end-1) '/)'];
    else
        line = [line ' &'];
    end
    fprintf(out,'%s\n',line);
    ctr = ctr+entryPerLine;
end

fprintf(out,'%s\n',['   CHARACTER(10), PARAMETER  :: ValidParamAry2(' num2str(outIdx-halfOutIdx) ') =  (/ &                  ! This lists the names of the allowed parameters, which must be sorted alphabetically']);
ctr = halfOutIdx;
while ctr<outIdx
    is = ctr+1;
    if (ctr+entryPerLine) >= outIdx
        ie = outIdx;
        bLastLine = true;
    else
        ie = ctr+entryPerLine;
        bLastLine = false;
    end
    line = '                               ';
    for j = is:ie
        line = [line '"' pad(strtrim(upper(allOutNamesSorted{j})),10) '",'];
    end
    if bLastLine
        line = [line(1:end-1) '/)'];
    else
        line = [line ' &'];
    end
    fprintf(out,'%s\n',line);
    ctr = ctr+entryPerLine;
end
fprintf(out,'%s\n',['   CHARACTER(10), PARAMETER  :: ValidParamAry(' num2str(outIdx) ') =  [ValidParamAry1,ValidParamAry2]']);

fprintf(out,'%s\n','');
fprintf(out,'%s\n',['   INTEGER(IntKi), PARAMETER :: ParamIndxAry1(' num2str(halfOutIdx) ') =  (/ &                            ! This lists the index into AllOuts(:) of the allowed parameters ValidParamAry(:)']);
ctr = 0;
while ctr<halfOutIdx
    is = ctr+1;
    if (ctr+entryPerLine) >= halfOutIdx
        ie = halfOutIdx;
        bLastLine = true;
    else
        ie = ctr+entryPerLine;
        bLastLine = false;
    end
    line = '                               ';
    for j = is:ie
        line = [line pad(strtrim(allOutNamesSorted{j}),10,'left') ','];
    end
    if bLastLine
        line = [line(1:end-1) '/)'];
    else
        line = [line ' &'];
    end
    fprintf(out,'%s\n',line);
    ctr = ctr+entryPerLine;
end
fprintf(out,'%s\n',['   INTEGER(IntKi), PARAMETER :: ParamIndxAry2(' num2str(outIdx-halfOutIdx) ') =  (/ &                            ! This lists the index into AllOuts(:) of the allowed parameters ValidParamAry(:)']);
ctr = halfOutIdx;
while ctr<outIdx
    is = ctr+1;
    if (ctr+entryPerLine) >= outIdx
        ie = outIdx;
        bLastLine = true;
    else
        ie = ctr+entryPerLine;
        bLastLine = false;
    end
    line = '                               ';
    for j = is:ie
        line = [line pad(strtrim(allOutNamesSorted{j}),10,'left') ','];
    end
    if bLastLine
        line = [line(1:end-1) '/)'];
    else
        line = [line ' &'];
    end
    fprintf(out,'%s\n',line);
    ctr = ctr+entryPerLine;
end
fprintf(out,'%s\n',['   INTEGER(IntKi), PARAMETER :: ParamIndxAry(' num2str(outIdx) ') =  [ParamIndxAry1,ParamIndxAry2]']);

fprintf(out,'%s\n','');
fprintf(out,'%s\n',['   CHARACTER(ChanLen), PARAMETER :: ParamUnitsAry1(' num2str(halfOutIdx) ') =  (/ &                     ! This lists the units corresponding to the allowed parameters']);
ctr = 0;
while ctr<halfOutIdx
    is = ctr+1;
    if (ctr+entryPerLine) >= halfOutIdx
        ie = halfOutIdx;
        bLastLine = true;
    else
        ie = ctr+entryPerLine;
        bLastLine = false;
    end
    line = '                               ';
    for j = is:ie
        
        unit = '';
        if contains(allOutNamesSorted{j},{'FK','FM','IntfF','ReactF'})
            unit = '(N)';
        elseif contains(allOutNamesSorted{j},{'MK','MM','IntfM','ReactM'})
            unit = '(N*m)';
        elseif contains(allOutNamesSorted{j},'TA')
            unit = '(m/s^2)';
        elseif contains(allOutNamesSorted{j},'RA')
            unit = '(rad/s^2)';
        elseif contains(allOutNamesSorted{j},'TD')
            unit = '(m)';
        elseif contains(allOutNamesSorted{j},'RD')
            unit = '(rad)';
        elseif contains(allOutNamesSorted{j},'SSqmdd')
            unit = '(1/s^2)';
        elseif contains(allOutNamesSorted{j},'SSqmd')
            unit = '(1/s)';
        elseif contains(allOutNamesSorted{j},'SSqm')
            unit = '(--)';
        end

        unit = pad(unit,10);
        line = [line '"' unit '",'];
    end
    if bLastLine
        line = [line(1:end-1) '/)'];
    else
        line = [line ' &'];
    end
    fprintf(out,'%s\n',line);
    ctr = ctr+entryPerLine;
end

fprintf(out,'%s\n',['   CHARACTER(ChanLen), PARAMETER :: ParamUnitsAry2(' num2str(outIdx-halfOutIdx) ') =  (/ &                     ! This lists the units corresponding to the allowed parameters']);
ctr = halfOutIdx;
while ctr<outIdx
    is = ctr+1;
    if (ctr+entryPerLine) >= outIdx
        ie = outIdx;
        bLastLine = true;
    else
        ie = ctr+entryPerLine;
        bLastLine = false;
    end
    line = '                               ';
    for j = is:ie
        
        unit = '';
        if contains(allOutNamesSorted{j},{'FK','FM','IntfF','ReactF'})
            unit = '(N)';
        elseif contains(allOutNamesSorted{j},{'MK','MM','IntfM','ReactM'})
            unit = '(N*m)';
        elseif contains(allOutNamesSorted{j},'TA')
            unit = '(m/s^2)';
        elseif contains(allOutNamesSorted{j},'RA')
            unit = '(rad/s^2)';
        elseif contains(allOutNamesSorted{j},'TD')
            unit = '(m)';
        elseif contains(allOutNamesSorted{j},'RD')
            unit = '(rad)';
        elseif contains(allOutNamesSorted{j},'SSqmdd')
            unit = '(1/s^2)';
        elseif contains(allOutNamesSorted{j},'SSqmd')
            unit = '(1/s)';
        elseif contains(allOutNamesSorted{j},'SSqm')
            unit = '(--)';
        end

        unit = pad(unit,10);
        line = [line '"' unit '",'];
    end
    if bLastLine
        line = [line(1:end-1) '/)'];
    else
        line = [line ' &'];
    end
    fprintf(out,'%s\n',line);
    ctr = ctr+entryPerLine;
end
fprintf(out,'%s\n',['   CHARACTER(ChanLen), PARAMETER :: ParamUnitsAry(' num2str(outIdx) ') = [ParamUnitsAry1,ParamUnitsAry2]']);

fprintf(out,'%s\n','');
fprintf(out,'%s\n','');
fprintf(out,'%s\n','! End of code generated by Matlab script');
fprintf(out,'%s\n','end module SubDyn_Output_Params');

fclose(out);