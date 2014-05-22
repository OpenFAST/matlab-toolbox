function CompareMatrices(MatTitle,CellMat,caseDescr)
% function CompareMatrices(MatTitle,CellMat,caseDescr)
% this plots up to 2 dimensions of matrices stored in cell array Mat
% (CellMat can also be a structure with field MatTitle)
%%
refMat = 1;
nMat   = length(CellMat); % number of matrices to compare/plot

if isstruct(CellMat{refMat})
    [nr,nc] = size( eval( ['CellMat{refMat}.' MatTitle]));
else
    [nr,nc] = size(CellMat{refMat});
end
n=nr*nc;

%% reshape data for use in bar plots:
thisData = zeros(n,nMat);
if isstruct(CellMat{refMat})
    for i=1:nMat
        thisData(:,i)=eval( ['CellMat{i}.' MatTitle '(:)'] );
    end 
else
    for i=1:nMat
        thisData(:,i)=CellMat{i}(:);
    end 
end

refData = repmat(thisData(:,refMat),1,nMat);


%% set labels (empty values won't get printed):
skipValue = 2;
xLab = cell(nr,nc);
k=0;
for i=1:nr
    for j=1:nc
        xLab{i,j} = '';
        if nr==1
            k=j;
        else
            k=i;
        end
        if i==j || mod(k,skipValue)==1
            xLab{i,j}=['(' num2str(i), ',' num2str(j) ')'];
        end
    end
end
xLab = xLab(:); %reshape this

%% plot:

f=figure;
set(f,'paperorientation','landscape','paperposition',[0.25 0.25 10.5 8] ...
    ,'Name',MatTitle);
MatTitle = strrep(MatTitle,'_','\_'); %for nicer printing on plots


subplot(2,1,1);
bar(thisData);
% plot(1:size(thisData,1),thisData);
title([MatTitle ': ' num2str(nr) ' x ' num2str(nc) ]);
legend(caseDescr{:},'Location','Best');
setLimits(xLab);

subplot(4,1,3);
bar(thisData./refData);
% plot(1:size(thisData,1),thisData./refData);
title([MatTitle ' normalized by values in ' caseDescr{1}]);
setLimits(xLab);

subplot(4,1,4);
bar(thisData - refData);
% plot(1:size(thisData,1),thisData - refData);
title([MatTitle ' differences from ' caseDescr{1}]);
xlabel('matrix entry')
setLimits(xLab);


return;

end

function setLimits(xLab)

    n = length(xLab);
    
    grid on;
    xlim([0, n+1]);
    set(gca,'XTick',1:n, 'XTickLabel',xLab);

end