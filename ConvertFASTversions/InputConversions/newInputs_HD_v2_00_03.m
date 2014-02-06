function [HDP] = newInputs_HD_v2_00_03(HDPar)
% [HDP] = newInputs_HD_v2_00_03(HDPar)
% HDP is the data structure containing already-filled parameters for
% HydroDyn. We're going to add existing fields and based on the old ones.

    HDP = HDPar;
    
    
     
    n = length(HDP.Label);

    [NAxCoef, err1] = GetFastPar(HDP,'NAxCoef');    
    if err1
      [NAxCoef, err1] = GetFastPar(HDP,'NHvCoef');    
      if ~err1
        n = n + 1;
        HDP.Label{n} = 'NAxCoef';
        HDP.Val{n}   = NAxCoef;
        HDP.AxCoefsHdr    = HDP.HvCoefsHdr;
        HDP.AxCoefsHdr{1} = 'AxCoefID';
        HDP.AxCoefsHdr{2} = 'AxCd';
        HDP.AxCoefsHdr{3} = 'AxCa';
        HDP.AxCoefs       = HDP.HvCoefs;
      end
    end
    
    if length(HDP.AxCoefsHdr) < 4
      HDP.AxCoefsHdr{4} = 'AxCp';       
      for i=1:NAxCoef
         HDP.AxCoefs(i,4) = 1.0;     
      end
    end
    
      % Change header labels for Joint table per v2.00.03 specification
    HDP.JointsHdr{2}   = 'Jointxi';
    HDP.JointsHdr{3}   = 'Jointyi';
    HDP.JointsHdr{4}   = 'Jointzi';
    HDP.JointsHdr{5}   = 'JointAxID';
    
    if length(HDP.SmplPropHdr) < 5
      HDP.SmplPropHdr{5}= 'SimplCp';
      HDP.SmplPropHdr{6}= 'SimplCpMG';
      HDP.SmplProp(5)   = 1.0;
      HDP.SmplProp(6)   = 1.0;
    end
    
    if length(HDP.DpthPropHdr) < 6
      HDP.DpthPropHdr{6}     = 'DpthCp';
      HDP.DpthPropHdr{7}     = 'DpthCpMG';
      for i=1:size(HDP.DpthProp,1)
         HDP.DpthProp(i,6)     = 1.0;
         HDP.DpthProp(i,7)     = 1.0;
      end
    end
    
    if length(HDP.MemberPropHdr) < 10
      HDP.MemberPropHdr{10}     = 'MemberCp1';
      HDP.MemberPropHdr{11}     = 'MemberCp2';
      HDP.MemberPropHdr{12}     = 'MemberCpMG1';
      HDP.MemberPropHdr{13}     = 'MemberCpMG2';
      for i=1:size(HDP.MemberProp,1)
         HDP.MemberProp(i,10)     = 1.0;
         HDP.MemberProp(i,11)     = 1.0;
         HDP.MemberProp(i,12)     = 1.0;
         HDP.MemberProp(i,13)     = 1.0;
      end
    end
    
    if ~isfield(HDP,'OutList')
      if isfield(HDP,'PtfmOutList')  && isfield(HDP,'MeshOutList') 
         HDP.OutList = [HDP.PtfmOutList; HDP.MeshOutList];
         HDP.OutListComments = [HDP.PtfmOutListComments; HDP.MeshOutListComments];
      elseif isfield(HDP,'PtfmOutList') 
         HDP.OutList = HDP.PtfmOutList;
         HDP.OutListComments = HDP.PtfmOutListComments;
      elseif isfield(HDP,'MeshOutList')
         HDP.OutList = HDP.MeshOutList;
         HDP.OutListComments = HDP.MeshOutListComments;
      end
    end
    
end 