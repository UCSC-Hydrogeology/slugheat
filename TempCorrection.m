%%% =====================================================================
%%  Purpose: 
%       This function corrects the raw temperature data by using the
%       chosen bottom water temperature as a reference for all thermistors. 
%       Next, the temperatures are corrected with respect to the 
%       temperature read in the bottom water sensor during the time of 
%       measurements.
%%  Last edit:
%       08/10/2023 by Kristin Dickerson, UCSC
%%% =====================================================================

function [...
        BottomWaterTemp, ...
        WaterSensorTemp, ...
        AllSensorsTempRelBW, ...
        AllSensorsCalibratedTemp,...
        WaterThermistor] = TempCorrection(BWChosen, BottomWaterValue,...
         AllSensorsRawData, ...
         WaterThermistor, ...
         WaterSensorRawData, ...
         Offset, ...
         PenetrationRecord, ...
         AllRecords, ...
         MeanCalibTemps, ...
         NumberOfSensors, ...
         SensorsToUse, ...
         figure_Main, ...
         app)


%% Rename variables for clarity
%% =======================================================================
% Naming system:
%   
%   CAL          : calibration of each sensor. this will vary for each sensor
%   
%   BOTTOM WATER : assumed temperature of the bottom water during
%                  penetration that will be removed from every temperature 
%                  reading so that temperatures are recorded as 
%                  "Temperature relative to bottom water". This value
%                  should be the SAME for ALL SENSORS
%
%   TOP SENSOR   : the sensor that is presumably NOT penetrated into the 
%                  seafloor and instead remains bottom water during
%                  penetration. this sensor is removed from the others and
%                  lies on TOP of the data logger, not inside the sensor
%                  string with all other sensors
%% =======================================================================

%% Initialize

    % Define number of sensors total (including water sensor) and number of recods
    % ----------------------------------------------------------------------------
    [NumRecords,NumSensTot] = size(AllSensorsRawData);
    
    % Convert temps to degrees if they are still milli degree
    % -----------------------------------------------------------------
    if AllSensorsRawData(1,1)>1000
        AllSensorsRawData = AllSensorsRawData/1000;
    end
    
    if WaterSensorRawData(1,1)>1000
       WaterSensorRawData = WaterSensorRawData/1000;
    end
    
    % Determine if the raw data has a bottom water sensor based on number of
    % columns and number of sensors noted in .pen file. 
    % ------------------------------------------------------------------------
    [~,NC]=size(AllSensorsRawData);
    if NC == NumberOfSensors+1 
        WaterThermistor = 1;
    elseif NC == NumberOfSensors 
        WaterThermistor = 0; 
    end
    
    % Find raw temperatures during penetration period
    % -------------------------------------------------------------------
    
        % Find record numbers for bottom water equilibrium (calibration) period and penetration
        PenRecords      = AllRecords;
    
        % Temps during penetration
        PenTopSens  = WaterSensorRawData(PenRecords); % only sensor on top of data logger
    
    
%% SENSOR CALIBRATION
%% ==================
    
    AllSensorsCalibratedTemp = NaN*ones(NumRecords, NumSensTot);
    
    if ~all(MeanCalibTemps==-999)
         
         % Determine calibration offsets for each sensor
         % ----------------------------------------------
    
            % Find average calibration temp for all sensors
              TCAL = mean(MeanCalibTemps(SensorsToUse), 'omitnan');
    
            % Initialize arrays in for loop
              TOFFSET = NaN*ones(1, NumSensTot);
    
        % Apply calibration correction for each sensor
        % --------------------------------------------
    
        for i = SensorsToUse
    
            TOFFSET(i) = MeanCalibTemps(i)- TCAL;
    
            AllSensorsCalibratedTemp(:, i) = AllSensorsRawData(:, i) - TOFFSET(i);
    
        end 
    
        if WaterThermistor == 1
            TOFFSETBW = MeanCalibTemps(end) - TCAL;
            WaterSensorCalibratedTemp = AllSensorsRawData(:, end) - TOFFSETBW;
            PenTopSens  = WaterSensorCalibratedTemp(PenRecords); % only sensor on top of data logger
        end
    end
    
%% CONVERT RAW TEMPERATURES TO TEMPERATURES RELATIVE TO BOTTOM WATER
%% =================================================================
    
    % Determine bottom water
    % -----------------------
    % (1)If there is a working top sensor (water thermistor), 
    % then the bottom water is the mean of all temps recorded by this sensor 
    % during penetration
    % (2)If there is NOT a working top sensor (water thermistor),
    % then bottom water is the LAST temp recorded by the shallowest sensor
    % before penetration OR the user can manually input a bottom water
    % temperature
        if WaterThermistor == 1 && BWChosen == 0
            BottomWaterValue = mean(PenTopSens, 1, 'omitnan');
        elseif BWChosen == 0
            ChooseBW = uiconfirm(figure_Main, ['Bottom water sensor is not found or is being ignored.' newline ...
            'Options for choosing alternate bottom water temperature: ' newline newline ...
            'Option (1): Last temperature recorded before penetration by the most shallow working sensor (T' num2str(SensorsToUse(end)) ') used as bottom water temperature.' newline newline ...
            'Option (2): Manually input a bottom water temperature.'], ...
            'NO TOP SENSOR', 'Options', {'Option (1)','Option (2)', 'Cancel'});
            switch ChooseBW
            case 'Option (1)'
                BottomWaterValue = AllSensorsCalibratedTemp(PenetrationRecord-1, end);
            case 'Option (2)'
                UserBWTAuxApp(AllSensorsCalibratedTemp, NumberOfSensors, SensorsToUse, AllRecords, PenetrationRecord);
                  BottomWaterApp = BottomWaterAuxApp(app,...
                  AllSensorsCalibratedTemp, ...
                  WaterThermistor, ...
                  NumberOfSensors, ...
                  SensorsToUse, ...
                  AllRecords, ...
                  PenetrationRecord, ...
                  AllSensorsRawData, ...
                  app.edit_bottomwater.Value);
                waitfor(BottomWaterApp)
            case 'Cancel'
                return
            end
        end 
    
         BottomWaterTemp = repmat(BottomWaterValue, 1,NumSensTot);
    
    
    % Subtract bottom water from all temps, 
    % excluding top sensor if there is a working top sensor
    % -------------------------------------------------------------------------
    if WaterThermistor == 1
        BottomWaterTemp = repmat(BottomWaterTemp(1:end-1),NumRecords,1); % extended array of bottom water sensor data for each thermistor except the actual bototm water sensor
        AllSensorsTempRelBW = AllSensorsCalibratedTemp(:, 1:end-1) - BottomWaterTemp; % subtract bottom water from all temps of all thermistors except the actual bottom water sensor
        WaterSensorTemp = WaterSensorCalibratedTemp;
    else
        BottomWaterTemp = repmat(BottomWaterTemp(1:end),NumRecords,1); % extended array of bottom water sensor data for each thermistor 
        AllSensorsTempRelBW = AllSensorsCalibratedTemp(:, 1:end) - BottomWaterTemp; % subtract bottom water from all temps of all thermistors because no water sensor
        WaterSensorTemp = [];
    end
    
    % Manual offset to remove negative temperatures. The manual offset value is
    % defined by the user in the .par file.
    % ----------------------------------------------
    AllSensorsTempRelBW = AllSensorsTempRelBW + Offset;
    BottomWaterTemp = BottomWaterTemp(1);










