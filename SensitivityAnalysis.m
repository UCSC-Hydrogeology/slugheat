%%% ======================================================================
%%  Purpose: 
%       This function runs the heat flow sensitivity analysis.
%%  Last edit:
%       09/07/2023 by Kristin Dickerson, UCSC 
%%% ======================================================================

function [Params,...
         Results] = SensitivityAnalysis(NumberOfSensors, ...
            MaxSAIterations, ...
            Sigmak0, ...
            kMin, ...
            kMax, ...
            MinThickness, ...
            kAnisotropy, ...
            SensorsToUse, ...
            IgnoredSensors, ...
            Badk, ...
            BadT,...
            ShiftedCTR, ...
            ShiftedRelativeDepths, ...
            Slope, ...
            k0, ...
            MinimumFricEqTemp, ...
            h_axTempAboveBWT, ...
            SensorsUsedForBullardFit, ...
            HeatFlow, ...
            axes_SA_SDvIter, ...
            axes_SA_TCvDepth, ...
            axes_SA_TempvCTR, ...
            label_heatflowrange, ...
            label_meanheatflow, ...
            label_currentheatflow, ...
            label_initheatflow, ...
            label_standev, ...
            label_currentiteration, ...
            label_meandev, ...
            label_minthickness, ...
            label_thermconbounds, ...
            label_ThermConBoundsTitle, ...
            label_standev_perc, ...
            loading, ...
            table_ErrorUncertaintySummary, ...
            ErrData, ...
            kDistribution, ...
            r, ...
            Meank,...
            UseFrictional, ...
            figure_Main, ...
            FricTime, ...
            FricTemp, ...
            FrictionalDelays, ...
            FricMaxStep, ...
            TimeInc, ...
            HyndmanCoeffs, ...
            SensorRadius, ...
            FricTauMin, ...
            FricTauMax, ...
            app, ...
            NumSensAnalyses)


%% Initialize
        [nr,~] = size(SensorsToUse);
        if nr~=1
            SensorsToUse=SensorsToUse';
        end
         kToUse = SensorsToUse;
         qMin = HeatFlow;
         qMax = HeatFlow;
    
         % Empty outputs in case user cancels analysis before it finishes
         Params=struct();
         Results=struct();
    
         % Initialize arrays for iterative process
         % ---------------------------------------
        
         Iterations = NaN*zeros(MaxSAIterations,1);
         MeanT = NaN*zeros(MaxSAIterations,length(SensorsUsedForBullardFit));
         Rz = NaN*zeros(MaxSAIterations,length(SensorsUsedForBullardFit));
         SigmaHF = NaN*zeros(MaxSAIterations,1);
         AllT = NaN*zeros(length(SensorsUsedForBullardFit),MaxSAIterations);
         AllBullardDepths = NaN*zeros(length(SensorsUsedForBullardFit),MaxSAIterations);
         AllHeatFlows = NaN*zeros(MaxSAIterations,1);
         AllHeatFlowsErr = NaN*zeros(MaxSAIterations,1);
         MeanHeatFlow = NaN*zeros(MaxSAIterations,1);
         MeanHeatFlowErr = NaN*zeros(MaxSAIterations,1);
         ScatterSens = NaN*zeros(MaxSAIterations,1);
    
         % Define colors for plots
         % -----------------------
         Colors = cell(size(NumberOfSensors));
         for i = 1:NumberOfSensors
            Colors{i} = h_axTempAboveBWT(i).Color;
         end
        
         % Distribution of thermal conductivity values
         if kDistribution == 1
             DisCond = 'Gaussian';
             ThermBounds = ['[' num2str(min(min(r(:, SensorsToUse))), 2) ' - ' num2str(max(max(r(:, SensorsToUse))), 2) ']'];
         elseif kDistribution == 2
             DisCond = 'Gamma';
             ThermBounds =  ['[' num2str(min(min(r(:, SensorsToUse))), 2) ' - Infinity]'];
         elseif kDistribution == 3
             DisCond = 'None';
         end
    
        % Generate Random boundaries given ShiftedRelativeDepths 
        % -------------------------------------------------------
        
        zToUse = ShiftedRelativeDepths(kToUse);
        
        zLims = [zToUse(1:length(zToUse)-1) - MinThickness/2; ...
                zToUse(2:length(zToUse)) + MinThickness/2];
        
        zBD = repmat(zLims(1,:),MaxSAIterations,1) ...
            + rand(MaxSAIterations,length(zToUse)-1) ...
            .* repmat(diff(zLims),MaxSAIterations,1);


%% Generate and plot cnductivity distribution

        % -----------------------------------------------------
        % TWO OPTIONS:
        %      (1) There is NO in-situ thermal conductivity measurements, 
        %           user can correct for anisotropy
        %      OR 
        %      (2) If user chooses to use a normal or gamma distribution of
        %          thermal conductivities, no need to correct for anisotropy
        %          because this uncertainty will be accounted for in the 
        %          larger distribution of thermal conductivity values
        % --------------------------------------------------------------------
       
        k0 = [k0(kToUse)  k0(kToUse(end))];
        
        %% If the k distributions are normal or gamma
        if kDistribution == 1 || kDistribution == 2

            % Get depths
            z = [ShiftedRelativeDepths(kToUse(1)) ShiftedRelativeDepths(kToUse(1:end-1)) ...
                        + diff(ShiftedRelativeDepths(kToUse))/2 0];
            hold(axes_SA_TCvDepth, 'on')
        
            % For all sensors, plot k vs. depth
            for i=SensorsToUse
                plot(axes_SA_TCvDepth, r(:, i), ShiftedRelativeDepths(i), '.',...
                    'Color',Colors{i})
                drawnow;
            end
                
                % Plot k distributions on the k vs. depth plots
                % --------------------------------------------
                Bins = 25;
                SensorDistance = 0.3;
                VarDist = 0;
        
                [N,X] = hist(r,Bins); %#ok<HIST>
                Diffk = diff(X);
                X = [X(1)-Diffk(1)/2 X'-Diffk(1)/2 X(end)+Diffk(1)/2 X(end)+Diffk(1)/2];
        
                MaxN = max(max(N));
        
                % AF 9/02 max height of histograms - for variable spacing
                %
                    PlotSpace = min(abs(diff(SensorDistance)));
        
                % AF 9/02 Scale histograms differently for constant or variable spacing
                    for i = SensorsToUse
                        if VarDist == 1
                           Y = ShiftedRelativeDepths(i) ...
                             - PlotSpace*[0 N(:,i)' N(end,i) 0]/MaxN;
                        else
                           Y = ShiftedRelativeDepths(i) ...
                             - SensorDistance*[0 N(:,i)' N(end,i) 0]/MaxN;
                        end
        
                        Hist = stairs(axes_SA_TCvDepth, X,Y, 'linewidth', 4);
                        Hist.Color = h_axTempAboveBWT(i).Color;
                    end
        
        
                % Plot k min and max lines
                kMinLine = line(axes_SA_TCvDepth, [min(min(r(:, SensorsToUse))) min(min(r(:, SensorsToUse)))],[0 max(ShiftedRelativeDepths(kToUse))+0.5], ...
                    'color','k', ...
                    'linestyle','--');
                kMaxLine = line(axes_SA_TCvDepth, [max(max(r(:, SensorsToUse))) max(max(r(:, SensorsToUse)))],[0 max(ShiftedRelativeDepths(kToUse))+0.5], ...
                    'color','k', ...
                    'linestyle','--');
        
                % Set axes
                set(axes_SA_TCvDepth, ...
                    'ydir','reverse', ...
                    'box','on', ...
                    'xaxislocation','top', ...
                    'ylim',[0 max(ShiftedRelativeDepths(kToUse))+0.5])
                axes_SA_TCvDepth.XLim = [min(min(r(:, SensorsToUse)))-.05 max(max(r(:, SensorsToUse)))+.05];
                xlabel(axes_SA_TCvDepth, '\bfThermal Conductivity (W/m ^oC)', ...
                    'verticalalignment','bottom', 'FontSize',18, 'Color',[0.00,0.45,0.74])
                ylabel(axes_SA_TCvDepth, '\bfDepth (m)', ...
                    'verticalalignment','bottom', 'FontSize',18, 'Color',[0.00,0.45,0.74])
        
               % Update labels that describe sensitivity analysis parameters
               % -----------------------------------------------------------
               label_meandev.Interpreter = 'latex';
               label_minthickness.Interpreter = 'latex';
               label_thermconbounds.Interpreter = 'latex';
        
               label_meandev.Text = [num2str(Sigmak0(1)) ' $W/m°C$'];
               label_minthickness.Text = [num2str(MinThickness) ' m'];
               label_thermconbounds.Text = [ThermBounds ' $W/m°C$'];
        
         %% Else if there are only single values of k used, no distributions
        elseif kDistribution == 3
        
                % Incorporate k anisotropy
                k_AnChange = k0 - (1-kAnisotropy) * k0;
                k_Anisotropy = NaN(size(k0));
        
                i = 1;
                while i <= MaxSAIterations
                	randomk = k0 - (k_AnChange - k0).*rand(1,1);
                	k_Anisotropy(i, :) = randomk;
                  i = i+1;
                end
        
                % Plot Conductivity distribution
                % ------------------------------
                k = [k_Anisotropy(:,kToUse(1)) k_Anisotropy(:,kToUse)]; 
                z = [zToUse(1)*ones(MaxSAIterations,1) zBD zeros(MaxSAIterations,1)];
                hold(axes_SA_TCvDepth, 'on') 
        
                i=1;       
                    while i<=length(kToUse)
                        CurrentSensor = kToUse(i);
        
                		% Plot original k (no anisotropy)
                        plot(axes_SA_TCvDepth, k0(CurrentSensor),ShiftedRelativeDepths(CurrentSensor),'o', ...
                            'Color',h_axTempAboveBWT(i).Color, ...
                            'MarkerFaceColor',h_axTempAboveBWT(i).Color, ...
                            'MarkerSize',10);
        
        
                		% Plot range of thermal conductivities with anisotropy correction
                        j=1;
                        while j<=MaxSAIterations
                            plot(axes_SA_TCvDepth, k_Anisotropy(j,CurrentSensor),ShiftedRelativeDepths(CurrentSensor),'.', ...
                                'color',h_axTempAboveBWT(i).Color, ...
                                'MarkerFaceColor',h_axTempAboveBWT(i).Color, ...
                                'MarkerSize',10);
        
                            j=j+1;
                        end
        
                        i=i+1;
                    end
        
                plot(k(intersect(Badk,SensorsUsedForBullardFit)), ...
                        ShiftedRelativeDepths(intersect(Badk,SensorsUsedForBullardFit)),'k+','markersize',15);
                drawnow;
        
                % Grab minimum and maximum
                kMin=min(min(k_Anisotropy));
                kMax=max(max(k_Anisotropy));
        
                % Set axes
                set(axes_SA_TCvDepth, ...
                    'ydir','reverse', ...
                    'box','on', ...
                    'xaxislocation','top', ...
                    'ylim',[0 max(ShiftedRelativeDepths(kToUse))+0.5], ...
                    'xlim',[kMin-0.05*kMin kMax+0.05*kMax]);
                xlabel(axes_SA_TCvDepth, '\bfThermal Conductivity (W/m ^oC)', ...
                    'verticalalignment','bottom', 'FontSize',18, 'Color',[0.00,0.45,0.74])
                ylabel(axes_SA_TCvDepth, '\bfRelative Depths (m)', ...
                    'fontsize',18, ...
                    'verticalalignment','bottom', 'Color',[0.00,0.45,0.74])
        
        
                    % Update labels that describe sensitivity analysis parameters
                    % ---- need to make these labels
                    % -----------------------------------------------------------
                   label_meandev.Interpreter = 'tex';
                   label_minthickness.Interpreter = 'tex';
                   label_thermconbounds.Interpreter = 'tex';        
                   label_minthickness.Text = [num2str(MinThickness) ' m'];    
                   label_thermconbounds.Text = [num2str(abs(1-kAnisotropy)*100,0) '%'];
                   label_ThermConBoundsTitle.Text = 'k anisotropy:';
                   label_meandev.Text = 'N/A';
        
        end
        
%% Plot initial conductivity
        
        % Plot stairs connecting k points
        if kDistribution~=3
           x = k0;
           y = ShiftedRelativeDepths(kToUse);
           y = [y(1) y(1:end-1) + diff(y)/2 0];
           h_axTCvDepthStairs = stairs(axes_SA_TCvDepth, x,y,'m-', 'LineWidth',2);
        end
        
%% Plot initial heat flow plot
        
        T0 = MinimumFricEqTemp;
        idx = isnan(T0);
        ShiftedCTR(idx) = nan;
       
        % Plot CTR vs. temperature for all sensors
        for i = SensorsToUse
            plot(axes_SA_TempvCTR, T0(i),ShiftedCTR(i),'o', ...
                'Color','m', ...
                'MarkerFaceColor',h_axTempAboveBWT(i).Color, ...
                'MarkerSize',10);
       
            hold(axes_SA_TempvCTR, 'on');    
        end
       
        % Plot Bullard line
        line_initialheatflow = plot(axes_SA_TempvCTR, [0 max(ShiftedCTR)+0.5]/Slope(2), ...
            [0 max(ShiftedCTR)+0.5],'m-','linewidth',2);
        drawnow;
       
        % Set axes
        set(axes_SA_TempvCTR, ...
            'ydir','reverse', ...
            'box','on', ...
            'xaxislocation','top', ...
            'ylim',[0 max(ShiftedCTR)+0.5]);
        xlabel(axes_SA_TempvCTR,'\bfTemperature ( ^oC)', ...
            'verticalalignment','bottom', 'FontSize',18, 'Color',[0.00,0.45,0.74])
        ylabel(axes_SA_TempvCTR,'\bfCumulative Thermal Resistance (m^2 ^oC/W)', ...
            'verticalalignment','bottom', 'FontSize',18, 'Color',[0.00,0.45,0.74])
       
        % Update labels that describe sensitivity analysis parameters
        % -----------------------------------------------------------
        label_heatflowrange.Interpreter = 'latex';
        label_initheatflow.Interpreter = 'latex';help
        label_currentheatflow.Interpreter = 'latex';
        label_heatflowrange.Text = ['[' num2str(qMin,'%1.1f') ...
                 ' - ' num2str(qMax,'%1.1f') '] $mW/m^{2}$'];
        label_initheatflow.Text = [num2str(HeatFlow,'%1.0f') ' $mW/m^{2}$'];
        label_currentheatflow.Text = 'NaN $mW/m^{2}$';
        
        
%% Plot iteration and standard deviation
        
        % Initialize Iterations plot
        % --------------------------
        set(axes_SA_SDvIter, ...
            'ydir','reverse', ...
            'box','on', ...
            'xaxislocation','top', ...
            'ylim',[0 MaxSAIterations]);
        xlabel(axes_SA_SDvIter, '\bfHeat Flow Uncertainty (mW/m^{2})', ...
            'verticalalignment','bottom', 'FontSize',16, 'Color',[0.00,0.45,0.74])
        ylabel(axes_SA_SDvIter, '\bfIteration', ...
            'verticalalignment','bottom', 'FontSize',18, 'Color',[0.00,0.45,0.74])
       
        hold(axes_SA_SDvIter, 'on');
       
        % Update labels that describe sensitivity analysis parameters
        % -----------------------------------------------------------
        label_currentiteration.Interpreter = 'latex';
        label_meanheatflow.Interpreter = 'latex';
        label_standev.Interpreter = 'latex';
        label_standev_perc.Interpreter = 'latex';
       
        label_currentiteration.Text = ['NaN/' int2str(MaxSAIterations)];
        label_meanheatflow.Text = 'NaN $mW/m^{2}$';
        label_standev.Text = 'NaN $mW/m^{2}$';
        label_standev_perc.Text = 'NaN \%';
         
        % Set plot invisible
        % ------------------
        for i = 1:length(axes_SA_SDvIter.Children)
            axes_SA_SDvIter.Children(i).Visible = 'off';
        end
       
%%      BEGIN ANALYSIS %
        
        % Remove distributions of all sensors that are ignored
        % ----------------------------------------------------
        Allk = r;
        r = r(:,SensorsToUse);
        
        % Begin iterations
        % ----------------
        for n = 1:MaxSAIterations
        
        % Define variables for conductivity distributions 
        % ---------------------------------
        if exist("k_Anisotropy", "var")
        	k0 = k_Anisotropy(n, :);
        end
       
        Iterations(n) = n;
       
        % Update loading message
        loading.Message = ['Running each realization... ' num2str(n) '/' num2str(MaxSAIterations)];
        loading.Value = n/MaxSAIterations;
       
        % Plot Current profile
        % --------------------   
        remainder = rem(n,10);
        if remainder == 0 || n == 1
        
            if n>1 
                delete(PreviousPoints)
                delete(PreviousProfile)
                if Iterations(end)~=MaxSAIterations
                    delete(PreviousProfile)
                end
            end
        
            if exist("k_Anisotropy", "var")
                PreviousProfile = stairs(axes_SA_TCvDepth, k(n,:),z(n,:),'k:','linewidth',2);
                PreviousPoints  = plot(axes_SA_TCvDepth, k(n,:),z(n,:),'ok','MarkerSize',8);
        
            else
                PreviousProfile = stairs(axes_SA_TCvDepth, [r(n,1) r(n,:)],[ShiftedRelativeDepths(kToUse(1)) zBD(n,:) 0], 'k:', 'linewidth', 2);
                PreviousPoints = plot(axes_SA_TCvDepth, r(n,:),ShiftedRelativeDepths(kToUse),'ko', ...
                    'markersize',8);  
            end
        
        end
        
        % Frictional decay reduction: Re-detemrine equilibrium 
        % temperatures of each sensor using the selected thermal 
        % conductivity values
        % ---------------------------
       
        if UseFrictional 
            Currentk = Allk(n,:); % use all random distributions of k values, even ignored sensors. these will be ignored in the frictional decay reduction. 
        
            [~, ...
            T0, ...
            ~, ...
            ~, ...
            ~, ...
            HPTooLow, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~ ...
            ] = FrictionalDecay( ...
            figure_Main, ...
            FricTime, ...
            FricTemp, ...
            NumberOfSensors, ...
            FrictionalDelays, ...
            FricMaxStep, ...
            TimeInc, ...
            Currentk, ...
            HyndmanCoeffs, ...
            SensorRadius, ...
            FricTauMin, ...
            FricTauMax, ...
            SensorsToUse, ...
            loading);
        
             if HPTooLow
                 return
             end
        end

        %% KD TESTIGN change bad T to average of T's on either side of it
        %BadTtoFix = intersect(BadT, SensorsUsedForBullardFit);
        %for i = 1:length(BadTtoFix)
        %    if BadTtoFix(i)==SensorsUsedForBullardFit(end)
        %        T0(BadTtoFix(i)) = (T0(BadTtoFix(i)-1));
        %    elseif BadTtoFix(i)==SensorsUsedForBullardFit(1)
        %        T0(BadTtoFix(i)) = (T0(BadTtoFix(i)+1));
        %    else
        %        t = (T0(BadTtoFix(i)-1)) + T0(BadTtoFix(i)+1);
        %        T0(BadTtoFix(i)) = t/2;
        %    end
        %end
         %% KD TESTIGN change bad T to average of T's on either side of it

        
         % Compute cumulative thermal resistance and associated error
         % -------------------------------------------------------------- 
         CTR = NaN*zeros(length(kToUse),1);
         
             if exist("k_Anisotropy", "var")
                 CTR(length(kToUse)) = zToUse(end)/k0(kToUse(end));
         
                 for i = length(kToUse)-1:-1:1
                 CTR(i) = CTR(i+1) + (zBD(n,i)-zToUse(i+1))/k0(kToUse(i+1)) ...
                     + (zToUse(i)-zBD(n,i))/k0(kToUse(i));
                 end
             else
                 CTR(length(kToUse)) = zToUse(end)/r(n,end);
         
                 for i = length(kToUse)-1:-1:1
                 CTR(i) = CTR(i+1) + (zBD(n,i)-zToUse(i+1))/r(n,i+1) ...
                     + (zToUse(i)-zBD(n,i))/r(n,i);
                 end
             end
         
         CurrentCTR = NaN*zeros(NumberOfSensors,1);
         CurrentCTR(SensorsToUse) = CTR;
         
         [p,~] = polyfit(T0(SensorsUsedForBullardFit)',CurrentCTR(SensorsUsedForBullardFit),1);
        
         % ==================================================================
         % Determine error from method by BP 2017 -- using chi squared fit requires data to be normally
         % distributed (I think)
         [~,Slope,~,SlopeErr, ~,Scatter,~,~,Q] = ChiSquaredFit(T0(SensorsUsedForBullardFit),CurrentCTR(SensorsUsedForBullardFit)); % BP
         
         Err=mean([abs(1/Slope - 1/(Slope+SlopeErr)),abs(1/Slope - 1/(Slope-SlopeErr))]); % BP
         if Q < 0.1
             uialert(app.figure_Main, "Q < 0.1, therefore goodness of fit for Bullard plot is NOT believable !",'Statistical test failure','Icon','warning')
         end
         % =================================================================
      
         ShiftCurrentCTR = -p(2);
         SlopeCurrentCTR = p(1);
         
         ShiftedCurrentCTR = CurrentCTR + ShiftCurrentCTR;
        
%%  PLOT

         % Plot final iteration INSIDE LOOP
         % ===================================
         % Remove colors of ignored sensors so that you can plot 
         % -----------------------------------------------------
         for i = 1:NumberOfSensors
             Colors{i} = h_axTempAboveBWT(i).Color;
         end
         
         Colors(IgnoredSensors) = [];
         
         % Plot new heat flow plot for each iteration
         % ------------------------------------------
         for i = SensorsToUse
             plot(axes_SA_TempvCTR, T0(i),ShiftedCurrentCTR(i),'.', ...
                 'markersize',14, ...
                 'Color',h_axTempAboveBWT(i).Color, ...
                 'MarkerFaceColor',h_axTempAboveBWT(i).Color);
         
         end
         CurrentBullard = plot(axes_SA_TempvCTR, [0 max(ShiftedCurrentCTR)+0.5]/SlopeCurrentCTR, ...
             [0 max(ShiftedCurrentCTR)+0.5],'k:');
         
         plot(axes_SA_SDvIter, SigmaHF,Iterations,'k-o', ...
             'markersize',8, 'MarkerFaceColor','k')
         
         % Set axes limits for the heat flow standard deviation plot
         % ---------------------------------------------------------
         if ~isnan(max(SigmaHF))
             axes_SA_SDvIter.XLim = [0 max(SigmaHF)+0.1];
         end

%%  Sensitivity analysis !
        
         % Determine temperature, Bullard depths, heat flow, and all
         % assocaited error
         AllT(:,n) = T0(SensorsUsedForBullardFit);
         AllBullardDepths(:,n) = ShiftedCurrentCTR(SensorsUsedForBullardFit)';
         AllHeatFlows(n) = (1/SlopeCurrentCTR)*1000;
         AllHeatFlowsErr(n) = Err; 
         MeanT(n,:) = mean(AllT,2, 'omitnan')';
         SigmaTD = std(AllT,0,2, 'omitnan');
         Rz(n,:) = mean(AllBullardDepths,2, 'omitnan')';
         SigmaR = std(AllBullardDepths,0,2, "omitnan");
         MeanHeatFlow(n) = mean(AllHeatFlows, 'omitnan');
         MeanHeatFlowErr(n) = mean(AllHeatFlowsErr, 'omitnan'); % BP
         SigmaTI = MeanHeatFlow(n)*SigmaR;
         SigmaT = sqrt(SigmaTI.^2 + SigmaTD.^2);
         ScatterSens(n) = Scatter;
         
         %% Get standard deviation from sensitivity analysis (from Bevington and Robinson, 2003)
         if any(SigmaT == 0)
             SigmaHF(n) = NaN;
         else
             Delta = sum(1./SigmaT.^2)*sum(Rz(n,:)'.^2./SigmaT.^2) ...
                 -(sum(Rz(n,:)'./SigmaT.^2)).^2;
             SigmaHF(n) = round(sqrt(sum(1./SigmaT.^2)/Delta),1);
         end
          
         % Get min and max heat flow
         if AllHeatFlows(n)>qMax 
             qMax = AllHeatFlows(n);
         end
         if AllHeatFlows(n)<qMin
             qMin = AllHeatFlows(n);
         end 
         
         % get heat flow uncertainty as a percent of the mean
         AllHFUncertainty_perc = round((SigmaHF./MeanHeatFlow).*100,1);
        
        
%% Update legends and labels that describe sensitivity analysis parameters
        
         % Heat flow plot
         label_currentheatflow.Text = [num2str(AllHeatFlows(n),'%1.0f') ' $mW/m^{2}$'];
         label_heatflowrange.Text = ['[' num2str(qMin,'%1.0f') ...
                ' - ' num2str(qMax,'%1.0f') ']  $mW/m^{2}$'];
         
         % Realization plot
         label_currentiteration.Text = [num2str(n) '/' int2str(MaxSAIterations)];
         label_meanheatflow.Text =  [num2str(mean(AllHeatFlows, 'omitnan'), '%1.0f') ' $mW/m^{2}$'];
         label_standev.Text = [num2str(SigmaHF(n), '%1.2f') ' $mW/m^{2}$'];
         label_standev_perc.Text = [num2str(AllHFUncertainty_perc(n), '%1.2f') ' \%'];
         
         drawnow;
         
         % If the user cancels the laoding message, end this function
         if loading.CancelRequested
           return
         end
         
         end
              
         % Update y label of realizations plot
         ylabel(axes_SA_SDvIter, '\bfRealizations', ...
             'verticalalignment','bottom', 'FontSize',18, 'Color',[0.00,0.45,0.74])
         
         % Update legends
         legend([line_initialheatflow,CurrentBullard], {'Initial Bullard Best Fit Line', 'Current Bullard Best Fit Line'});
         if kDistribution~=3
            legend([h_axTCvDepthStairs PreviousProfile kMinLine kMaxLine PreviousProfile], {'Initial Parameters', 'Current Parameters', 'Min k', 'Max k'});
         end
        
%% Format and fill results data table
            
         % Close laoding message box
         close(loading)
 
         % Set trial number
         Trial = num2str(NumSensAnalyses);
         ErrData{4} = Trial;
       
         %% If only single values of k used, no distributions
         if kDistribution == 3
         
             % Set bins to zero and k min and k max to the set k values for each sensor
             Bins = 25;
             kMin = k_Anisotropy(1,:);
             kMax = k_Anisotropy(1,:);
     
             % Set standard deviation info
             qstd_perc = round((SigmaHF(n)/MeanHeatFlow(n))*100,1);
             [~,nc]=size(Sigmak0);
             Sigmak0(1,:) = zeros(1,nc);
         
             % Table column names
             table_ErrorUncertaintySummary.ColumnName = {'Cruise'; 'Station'; ...
             'Penetration'; 'Trial'; 'Realizations';
             'Thickness Distribution';'Min Thickness (m)'; ...
             'k Distribution'; 'k Range (W/m°C)'; ...
             'k Standard Deviation'; ...
             'Initial q (mW/m^2)';'Final q (mW/m^2)';'Mean q (mW/m^2)';...
             'Total q Range (mW/m^2)'; 'q Standard Deviation (mW/m^2)'; 'q Standard Deviation (%)';'Average Uncertainty'};
             
             % Table data
             Iter = num2str(MaxSAIterations);
             DisLayer = 'None';
             MinThick = num2str(MinThickness);
             for i = SensorsToUse
                 kBounds{i} = num2str(k_Anisotropy(1,i),2); %#ok<AGROW>
             end
             kBoundsAll = strjoin(kBounds(SensorsToUse));
             kDev       = 'N/A';
             InitHF = num2str(HeatFlow);
             FinalHF = num2str(AllHeatFlows(n),'%1.0f');
             MeanHF = num2str(MeanHeatFlow(n),'%1.0f');
             TotHFR = ['[' num2str(qMin,'%1.0f') ...
                    ' - ' num2str(qMax,'%1.0f') ']'];
             HFstd = num2str(SigmaHF(n));
             HFstd_perc = num2str(qstd_perc);
             AvUncer = num2str(MeanHeatFlowErr(end));
     
             ErrData = [ErrData, Iter, DisLayer, MinThick, DisCond, kBoundsAll, ...
                 kDev, InitHF, ...
                 FinalHF, MeanHF, TotHFR, HFstd, HFstd_perc,AvUncer];
         
             % Fill table on GUI with error and uncertainty results
             table_ErrorUncertaintySummary.Data = [table_ErrorUncertaintySummary.Data; ErrData];
         
         %% If normal or gamma k distributions were used
         else
             
             % Table column names
             table_ErrorUncertaintySummary.ColumnName = {'Cruise'; 'Station'; ...
             'Penetration'; 'Trial'; 'Realizations';
             'Thickness Distribution';'Min Thickness (m)'; ...
             'k Distribution'; 'k Range (W/m°C)'; ...
             'k Standard Deviation'; ...
             'Initial q (mW/m^2)';'Final q (mW/m^2)';'Mean q (mW/m^2)';...
             'Total q Range (mW/m^2)'; 'q Standard Deviation (mW/m^2)'; 'q Standard Deviation (%)'; 'Average Uncertainty'};
            
             % Table data
             Iter = num2str(MaxSAIterations);
             if kDistribution == 1
                 DisLayer = 'Uniform';
             elseif kDistribution == 2
                 DisLayer = 'Gamma';
             end
             MinThick = num2str(MinThickness);
             for i = SensorsToUse
                 kBounds{i} = ['[' num2str(kMin(i)) ' - ' num2str(kMax(i)) ']']; %#ok<AGROW>
             end
             kBoundsAll = strjoin(kBounds(SensorsToUse));
             kDev = strjoin(string(Sigmak0(SensorsToUse)));
             InitHF = num2str(HeatFlow);
             FinalHF = num2str(AllHeatFlows(n), '%1.0f');
             MeanHF = num2str(mean(AllHeatFlows, 'omitnan'), '%1.0f');
             TotHFR = ['[' num2str(qMin, '%1.0f') ...
                    ' - ' num2str(qMax,'%1.0f') ']'];
             qstd_perc = round((SigmaHF(n)/MeanHeatFlow(n))*100,1);
             HFstd = num2str(SigmaHF(n));
             HFstd_perc = num2str(qstd_perc);
             AvUncer = num2str(MeanHeatFlowErr(end));
         
             ErrData = [ErrData, Iter, DisLayer, MinThick, DisCond, kBoundsAll, ...
                 kDev, InitHF, FinalHF, MeanHF, TotHFR, HFstd, HFstd_perc, AvUncer];
         
             % Fill table on GUI with error and uncertainty results
             table_ErrorUncertaintySummary.Data = [table_ErrorUncertaintySummary.Data; ErrData];
         end
         
         ErrResultsSummary = table_ErrorUncertaintySummary;
         
         % Save error results table as a .mat file in the current directory
         save('ErrResultsSummaryTable', "ErrResultsSummary");
         
         drawnow;
       
%% Report all results and inputs to results (.res) and .log files
        
         % Parameters structure for output
         Params = struct('Realizations', Iterations, ...
                           'MinThickness', MinThickness, ...
                           'Anisotropy', kAnisotropy, ...
                           'Meank', Meank,...
                           'kstd', Sigmak0, ...
                           'Mink', kMin, ...
                           'Maxk', kMax, ...
                           'NumBins', Bins, ...
                           'DistributionType', DisLayer, ...
                           'TrialNumber', num2str(NumSensAnalyses),...
                           'IgnoredSensors', IgnoredSensors,...
                           'Ignoredk', Badk,...
                           'IgnoredT',BadT);

         
         % Results structure for output
         Results = struct('Initialq', HeatFlow, ...
                           'Finalq', AllHeatFlows(n), ...
                           'Meanq', mean(AllHeatFlows),...
                            'Minq', qMin, ...
                            'Maxq', qMax, ...
                            'qstd', SigmaHF(n), ...
                            'qstd_perc', qstd_perc, ...
                            'AveUnc', MeanHeatFlowErr(end), ...
                            'AllT', AllT',...
                            'MeanT', MeanT,...
                            'SigmaTD', SigmaTD,...
                            'AllRz', AllBullardDepths',...
                            'MeanRz', Rz, ...
                            'SigmaRz', SigmaR,...
                            'AllScatter',ScatterSens, ...
                            'AllHeatFlow', AllHeatFlows, ...
                            'MeanHeatFlow', MeanHeatFlow, ...
                            'AllHeatFlowErr', AllHeatFlowsErr,...
                            'MeanHeatFlowErr', MeanHeatFlowErr,...
                            'SigmaTI', SigmaTI,...
                            'SigmaT', SigmaT,...
                            'AllHFUncertainty', SigmaHF, ...
                            'AllHFUncertainty_perc', AllHFUncertainty_perc);
         
        
%% Plot results of the entire sensitivity analysis on main GUI tab for sensitivity analysis comparisons
        
         % Plot scatter
         % ------------
         plot(app.axes_sensscatter,AllHFUncertainty_perc,Iterations,'-o', ...
                 'markersize',8, 'Tag',['Trial ',Trial]);
         hold(app.axes_sensscatter, 'on')
         app.axes_sensscatter.YDir='reverse';
         
         n=length(app.axes_sensscatter.Children);
         trials=cell(n,1);
         for i=1:n
             trials{i} = app.axes_sensscatter.Children(i).Tag;
         end
         trials=flip(trials);
         
         % legend
         legend(app.axes_sensscatter,trials)
         
         % Plot histogram of results
         % --------------------------
         histogram(app.axes_senshist, AllHeatFlows, 'BinWidth', 0.5,'Tag', ...
             ['Trial ',Trial], 'NumBins',Bins); 
         hold(app.axes_senshist, 'on')
         
         % legend
         legend(app.axes_senshist,trials)

        
        
        
        
        


