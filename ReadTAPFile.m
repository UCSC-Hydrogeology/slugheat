%%% =======================================================================
%%  Purpose: 
%       This function reads in the information from the penetration that was 
%       chosen in 'GetFiles' function. 
%       This file should have been created by SlugPen. Instead of using the 
%       .tap text file, this function uses the .mat file `MATFile` that 
%       houses structures containing these variables.
%%  Last edit:
%       01/14/2024 Kristin Dickerson, UCSC
%%% =======================================================================

function [TAPRecord, ...
         Tilt, Depth ...
         ] = ReadTAPFile(S_MATFile)


% Read in preliminary penetrtation tilt and pressure information 
% and data from saved MAT file from SlugPen
% * pressure = depth
% ----------------------------------------------------------------------
    TAPRecord = S_MATFile.S_TAPVAR.TAPRecord;
    Tilt      = S_MATFile.S_TAPVAR.Tilt;
    Depth     = S_MATFile.S_TAPVAR.Depth;
    
    