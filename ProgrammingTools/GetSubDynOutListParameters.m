function [Category, VarName, InvalidCriteria, ValidInputStr, ValidInputStr_VarName, ValidInputStr_Units, SubCategory ] = GetSubDynOutListParameters()

maxNumMember = 99;
maxNumNode   = 9;
maxNumMode   = 99;

AllChannels{1}.Category = 'Member Forces';
AllChannels{1}.channels = {'FKxe','FKye','FKze','FMxe','FMye','FMze',...
    'MKxe','MKye','MKze','MMxe','MMye','MMze'};
AllChannels{1}.units = {'(N)','(N)','(N)','(N)','(N)','(N)',...
    '(N*m)','(N*m)','(N*m)','(N*m)','(N*m)','(N*m)'};
AllChannels{1}.SubCatIdx = [1,1,1,2,2,2,1,1,1,2,2,2];
AllChannels{1}.SubCatNames = {'MNfmKe','MNfmMe'};
AllChannels{1}.MemberNumber = true;

AllChannels{2}.Category = 'Displacements';
AllChannels{2}.channels = {'TDxss','TDyss','TDzss','RDxe','RDye','RDze'};
AllChannels{2}.units = {'(m)','(m)','(m)','(rad)','(rad)','(rad)'};
AllChannels{2}.SubCatIdx = [1,1,1,2,2,2];
AllChannels{2}.SubCatNames = {'MNTDss','MNRDe'};
AllChannels{2}.MemberNumber = true;

AllChannels{3}.Category = 'Accelerations';
AllChannels{3}.channels = {'TAxe','TAye','TAze','RAxe','RAye','RAze'};
AllChannels{3}.units = {'(m/s^2)','(m/s^2)','(m/s^2)','(rad/s^2)','(rad/s^2)','(rad/s^2)'};
AllChannels{3}.SubCatIdx = [1,1,1,1,1,1];
AllChannels{3}.SubCatNames = {'MNTRAe'};
AllChannels{3}.MemberNumber = true;

AllChannels{4}.Category = 'Reactions';
Prefix = transpose(repmat({'React';'Intf'},1,6));
AllChannels{4}.channels = strcat( reshape(Prefix,1,[]),repmat({'FXss','FYss','FZss','MXss','MYss','MZss'},1,2));
AllChannels{4}.units = repmat({'(N)','(N)','(N)','(N*m)','(N*m)','(N*m)'},1,2);
% AllChannels{4}.SubCatIdx = [1,1,1,1,1,1,2,2,2,2,2,2];
% AllChannels{4}.SubCatNames = {'ReactSS','IntfSS'};
AllChannels{4}.MemberNumber = false;

AllChannels{5}.Category = 'Interface Deflections';
AllChannels{5}.channels = strcat('Intf',{'TDXss','TDYss','TDZss','RDXss','RDYss','RDZss'});
AllChannels{5}.units = {'(m)','(m)','(m)','(rad)','(rad)','(rad)'};
AllChannels{5}.MemberNumber = false;

AllChannels{6}.Category = 'Interface Accelerations';
AllChannels{6}.channels = strcat('Intf',{'TAXss','TAYss','TAZss','RAXss','RAYss','RAZss'});
AllChannels{6}.units = {'(m/s^2)','(m/s^2)','(m/s^2)','(rad/s^2)','(rad/s^2)','(rad/s^2)'};
AllChannels{6}.MemberNumber = false;

AllChannels{7}.Category = 'Modal Parameters';
ModeNums = num2str((1:maxNumMode)','%02.0f');
Prefix = transpose(repmat({'SSqm';'SSqmd';'SSqmdd'},1,maxNumMode));
AllChannels{7}.channels = strcat(reshape(Prefix,[],1), repmat(ModeNums,3,1));
AllChannels{7}.units = reshape( transpose(repmat({'(-)';'(1/s)';'(1/s^2)'},1,maxNumMode)), [], 1);
AllChannels{7}.MemberNumber = false;



%% compute the number of output channels:
MaxOutPts = 0;
NumSubCats = 0;
for iCategory = 1:length(AllChannels)
    if AllChannels{iCategory}.MemberNumber
        MaxOutPts = MaxOutPts + maxNumMember*maxNumNode*length( AllChannels{iCategory}.channels );
        NumSubCats = NumSubCats + length(AllChannels{iCategory}.SubCatNames);
    else
        MaxOutPts = MaxOutPts + length( AllChannels{iCategory}.channels );
    end
end % iCategory
nLines = length(AllChannels) + MaxOutPts; % add lines for the categories

VarName = cell(1,nLines);
Units = cell(1,nLines);
InvalidCriteria = cell(1,nLines);
Category = cell(1,nLines);
SubCategory = cell(1,NumSubCats);

%% Get Channel names
outIdx = 0;

for iCategory = 1:length(AllChannels)
    outIdx = outIdx + 1;
    Category{outIdx} = AllChannels{iCategory}.Category;

    for channelNo = 1:length( AllChannels{iCategory}.channels )
        channel = AllChannels{iCategory}.channels{channelNo};

        if AllChannels{iCategory}.MemberNumber
            for member = 1:maxNumMember
                for node = 1:maxNumNode
                    outIdx = outIdx + 1;
                    VarName{outIdx} = ['M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel];
                    Units{outIdx} = AllChannels{iCategory}.units{channelNo};
                end %node
            end %member
        else
            outIdx = outIdx + 1;
            VarName{outIdx} = channel;
            Units{outIdx} = AllChannels{iCategory}.units{channelNo};  
        end

    end %channelNo
end %iCategory

%% Get ReshapeArrays
Indx1 = 0;
for iCategory = 1:length(AllChannels)

    if isfield(AllChannels{iCategory},'SubCatNames')
        for iSubCat = 1:length(AllChannels{iCategory}.SubCatNames)
            ChanList =  AllChannels{iCategory}.channels ( AllChannels{iCategory}.SubCatIdx == iSubCat );
    
            Indx1 = Indx1 + 1;
            SubCategory{Indx1}.Name = AllChannels{iCategory}.SubCatNames{iSubCat};
            SubCategory{Indx1}.Sizes = [length(ChanList), maxNumNode, maxNumMember];
    
            outIdx = 0;
    
            if AllChannels{iCategory}.MemberNumber
                for member = 1:maxNumMember
                    for node = 1:maxNumNode
                        for channelNo = 1:length( ChanList )
                            channel = ChanList{channelNo};
                            
                            outIdx = outIdx + 1;
                            SubCategory{Indx1}.VarName{outIdx} = ['M' pad(num2str(member),2,'left','0') 'N' num2str(node) channel];
                        end %channelNo
                    end %node
                end %member  
            else
                for channelNo = 1:length( ChanList )
                    channel = ChanList{channelNo};
                    
                    outIdx = outIdx + 1;
                    SubCategory{Indx1}.VarName{outIdx} = channel;
                end %channelNo
            end
    
        end %iSubCat
    end %if isfield
end %iCategory

%%
ValidInputStr = cell(1,1);
ValidInputStr_VarName  = cell(1,1);
ValidInputStr_Units = cell(1,1);
nr = 0;

for i=1:length(VarName)
    if ischar(VarName{i})
        nr = nr + 1;
        ValidInputStr{        nr,1} = VarName{i};
        ValidInputStr_VarName{nr,1} = VarName{i};
        ValidInputStr_Units{  nr,1} = Units{  i};
    end    
end

