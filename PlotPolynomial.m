%%% ======================================================================
%%   Purpose: 
%       This function plots a 2nd order polynomial regression for the
%       thermal gradient and Bullard plot. 
%%  Last edit:
%       02/08/2024 by Kristin Dickerson, UCSC
%%% ======================================================================

function [Tvz_poly,TvCTR_poly] = PlotPolynomial(ShiftedRelativeDepths, ...
          MinimumFricEqTemp, ShiftedCTR,...
          TToUse,CTRToUse,axes_TempvDepth,axes_TempvCTR)

%% get data
shifteddepth = ShiftedRelativeDepths(TToUse);
temp = MinimumFricEqTemp;
CTR = ShiftedCTR(CTRToUse);
ax_z = axes_TempvDepth;
ax_CTR = axes_TempvCTR;


%% polynomial fitting fo T vs. z
    y = shifteddepth;
    x = temp(TToUse);
    
    % polynomial fit
    p = polyfit(x,y,2);
    f1 = polyval(p,x);
    
    % plot
    Tvz_poly = plot(ax_z,x,f1,'k--','LineWidth',1,'Visible','off');
    
%% polynomial fitting fo T vs. z  
    y = CTR;
    x = temp(CTRToUse);

    % polynomial fit
    p = polyfit(x,y,2);
    f1 = polyval(p,x);
    % plot
    TvCTR_poly = plot(ax_CTR,x,f1,'k--','LineWidth',1, 'Visible','off');