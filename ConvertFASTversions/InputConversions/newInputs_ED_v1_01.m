function [EDP] = newInputs_ED_v1_01(EDPar)
% [EDP] = newInputs_ED_v1_01(EDPar)
% EDP is the data structure containing already-filled parameters for
% ElastoDyn. We're going to add existing fields and based on the old ones.

    EDP = EDPar;
    
    %----------------------------------------------------------------------
    % Add fields for ElastoDyn v1.01.x:
    %   PtfmRefzt = -PtfmRef
    %   TowerBsHt = TwrRBHt - TwrDraft
    %----------------------------------------------------------------------   
    n = length(EDP.Label);

    [PtfmRef, err1] = GetFastPar(EDP,'PtfmRef');    
    if ~err1
        n = n + 1;
        EDP.Label{n} = 'PtfmRefzt';
        EDP.Val{n}   = -PtfmRef;
    end

    [TwrRBHt, err2] = GetFastPar(EDP,'TwrRBHt');    
    if ~err2
        [TwrDraft,err3] = GetFastPar(EDP,'TwrDraft');
        if ~err3 
            n = n + 1;
            EDP.Label{n} = 'TowerBsHt';
            EDP.Val{n}   = TwrRBHt - TwrDraft;
        end
    end

end 