%%% =======================================================================
%%   Purpose: 
%       This function updates the layout of the SlugHeat GUI. All labels, 
%       text boxes, checkboxes,blegends, etc. are updated to current 
%       conditions.
%%   Last edit:
%       07/27/2023 by Kristin Dickerson, UCSC 
%%% =======================================================================

function updateLabels(label_currentpathfull, CurrentPath, label_penfilename, ...
    PenFileName, label_tapfilename, TAPFileName, label_resfilename, ...
    ResFileName, label_Cruise, CruiseName, ...
    label_Station, StationName, label_Penetration, Penetration, ...
    label_Latitude, Latitude, label_Longitude, Longitude, edit_PenStart, ...
    PenetrationRecord, edit_PenEnd, EndRecord, edit_HP, HeatPulseRecord)

    label_currentpathfull.Text = ['...' CurrentPath(end-20:end)];
    label_currentpathfull.Tooltip = CurrentPath;
    %label_parfilename.Text = ParFileName;

    if ischar(PenFileName)
        label_penfilename.Text  = PenFileName;
        label_tapfilename.Text  = TAPFileName;
        label_resfilename.Text  = ResFileName;
        label_Cruise.Text       = CruiseName;
        
        if isstring(StationName)
            label_Station.Text      = StationName;
            label_Penetration.Text  = Penetration;
            label_Latitude.Text     = Latitude;
            label_Longitude.Text    = Longitude;
        else
            label_Station.Text      = num2str(StationName);       
            label_Penetration.Text  = num2str(Penetration);
            label_Latitude.Text     = num2str(Latitude);
            label_Longitude.Text    = num2str(Longitude);
        end

        edit_PenStart.Value     = PenetrationRecord;
        edit_PenEnd.Value       = EndRecord;
        edit_HP.Value           = HeatPulseRecord;
    end
