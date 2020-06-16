function campbellSummaryFile(CampbellData, OutputTxtFile, nFreqOut )

    if ~exist('nFreqOut','var'); nFreqOut=20; end;

    nOP = length(CampbellData);

    nModesKeep=min([length(CampbellData{1}.NaturalFreq_Hz), 20]);
    MFreq = zeros(nModesKeep,nOP);
    MDamp = zeros(nModesKeep,nOP);
    MDesc = cell(nModesKeep ,nOP) ;
    for iOP = 1:nOP
        CD=CampbellData{iOP};
        for i = 1:nModesKeep
            DescCat = ShortModeDescr(CD,i);
            %fprintf('%8.3f ; %7.4f ; %s\n',CD.NaturalFreq_Hz(i),CD.DampingRatio(i),DescCat(1:min(120,length(DescCat))));
            MFreq(i,iOP)=CD.NaturalFreq_Hz(i);
            MDamp(i,iOP)=CD.DampingRatio(i);
            MDesc{i,iOP}=DescCat;
        end
    end
    %% Write a summary file, like what is outputted to screen
    fid=fopen(OutputTxtFile,'w');
    for iOP =1:nOP
        try
            WS= CampbellData{iOP}.WindSpeed;
        catch
            WS= NaN;
        end
        try
            RPM = CampbellData{iOP}.RotSpeed_rpm;
        catch
            RPM = NaN;
        end
        fprintf(fid,'------------------------------------------------------------------------\n');
        fprintf(fid,'--- OP %d - WS %.1f - RPM %.2f \n',iOP, WS, RPM);
        fprintf(fid,'------------------------------------------------------------------------\n');
        for i=1:size(MFreq,1)
            fprintf(fid, '%02d ; %8.3f ; %7.4f ; %s\n',i,MFreq(i,iOP),MDamp(i,iOP),MDesc{i,iOP});
        end
    end
    fclose(fid);
end
function DescCat = ShortModeDescr(CD,i)
    % Returns a shor description of the mode
    Desc      = CD.Modes{i}.DescStates(CD.Modes{i}.StateHasMaxAtThisMode);
    DescCat   = ''                                                       ;
    DescCatED = ''                                                       ;
    if length(Desc)==0
        DescCat = '' ;
        DescCatED = 'NoMax -' ;
        Desc = CD.Modes{i}.DescStates(1:8);
    end
    nBD=0;
    for iD=1:length(Desc)
        s=Desc{iD};
        s=fReplaceModeDescription(s);
        if Desc{iD}(1:2)=='BD'
            nBD=nBD+1;
        elseif Desc{iD}(1:2)=='ED'
            DescCatED = [s ' - ' DescCatED];
        else
            DescCat = [DescCat ' - ' s];
        end
    end
    DescCat=[DescCatED, DescCat];
    if nBD>0
        DescCat = sprintf('BD%d/%d %s',nBD,sum(CD.Modes{i}.StateHasMaxAtThisMode),DescCat);
    end
end

function s=fReplaceModeDescription(s)
    % Perform replacements to shorten mode description
    s = strrep(s,'First time derivative of'     ,'d/dt of');
    s = strrep(s,'fore-aft bending mode DOF, m'    ,'FA'     );
    s = strrep(s,'side-to-side bending mode DOF, m','SS'     );
    s = strrep(s,'bending-mode DOF of blade '    ,''     );
    s = strrep(s,' rotational-flexibility DOF, rad','-ROT'   );
    s = strrep(s,'rotational displacement in ','rot'   );
    s = strrep(s,'Drivetrain','DT'   );
    s = strrep(s,'translational displacement in ','trans'   );
    s = strrep(s,', rad','');
    s = strrep(s,', m','');
    s = strrep(s,'finite element node ','N'   );
    s = strrep(s,'cosine','cos'   );
    s = strrep(s,'sine','sin'   );
    s = strrep(s,'collective','coll.');
    s = strrep(s,'Blade','Bld');
    s = strrep(s,'rotZ','TORS-R');
    s = strrep(s,'transX','FLAP-D');
    s = strrep(s,'transY','EDGE-D');
    s = strrep(s,'rotX','EDGE-R');
    s = strrep(s,'rotY','FLAP-R');
    s = strrep(s,'flapwise','FLAP');
    s = strrep(s,'edgewise','EDGE');
    s = strrep(s,',','|');
end


% --------------------------------------------------------------------------------
%% --- Write File for pyDatView
% --------------------------------------------------------------------------------
% fid=fopen([outbase 'ModesFreqDamp.csv'],'w'); 
% MM=[MFreq; MDamp];
% fprintf(fid,'OP,'); % TODO
% for i=1:size(MFreq,1)
%     fprintf(fid,'Freq%d_[Hz],',i);
% end
% for i=1:size(MDamp,1)
%     if i<size(MDamp,1)
%         fprintf(fid,'Damp%d_[Hz],',i);
%     else
%         fprintf(fid,'Damp%d_[Hz]\n',i);
%     end
% end
% for iOP =1:nOp
%     %ws=vWS(iOP);
%     fprintf(fid,'%d,',iOP); % TODO
%     for i=1:size(MM,1)
%         if i==size(MM,1)
%             fprintf(fid,'%f\n',MM(i,iOP));
%         else
%             fprintf(fid,'%f,',MM(i,iOP));
%         end
%     end
% end
% fclose(fid);

