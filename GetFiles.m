%%% ====================================================================
%%  Purpose: 
%       This function gets these INPUT files:
%	    	1. Penetration (.pen) file -- text file created by SlugPen 
%           prior to running SlugHeat. This is the parsed data from each 
%           penetration needed to be processed by SlugHeat.
%           2. Temperature and pressure (.tap) file -- text file created 
%           by SlugPen prior to running SlugHeat.
%           3. MAT (.mat) file -- binary datafile created by SlugPen 
%           prior to running SlugHeat. This is the parsed data from each 
%           penetration needed to be processed by SlugHeat, but in .mat
%           form, housing all variables in structures rather than text.
%	    This function creates these OUPUT files:
%           1. Log (.log) file -- text file logging the individual
%           penetration's information and progress (this is different 
%           from SlugHeat22.log which was created at the start up of the 
%           application and records the entire progam's progress)
%           2. Results (.res) file -- text file recording all results of 
%           processing 
%%  Last edit:
%       01/19/2024 by Kristin Dickerson, UCSC
%%% ====================================================================

function 	[PenFileName, PenFilePath, PenFile, ...
			TAPName, TAPFileName, TAPFile, ...
            MATFileName, MATFile, ...
			LogFileName, LogFile, ...
			ResFileName, ResFile, ...
            LogFileId, ResFileId...
            ] = GetFiles(...
			CurrentPath, ProgramLogId, figure_Main)
	
 	
% ====================================================================
% Get penetration (PEN) file. Create variables for names and paths of
% temp & pressure (TAP), mat (MAT), results (RES), and log (LOG) files
% -- all have same name as PEN file.
% ====================================================================

    PenFilePath = [CurrentPath, 'inputs/'];

	% Penetration (PEN) file name and path
	% ---------------------------------------------
    PrintStatus(ProgramLogId, [' -- Finding penetration file from ' ...
        'SlugPen...'],1);

    figure_Main.Interruptible='off';
    drawnow
    
    % Get pen file from user input
    % ----------------------------
	[PenFileName, PenFilePath] = uigetfile( ...
		[PenFilePath '*.pen'], ...
		'Select penetration file');

    % If there is no pen file, tell user the program needs to be restarted
    % -------------------------------------------------------------------
    if PenFileName==0
        uialert(figure_Main,'Program depricated. Please restart SlugHeat.',...
            'ERROR', 'Icon','error')
        PenFileName=0;
        PenFilePath=0;
        PenFile=0;
		TAPName=0;
        TAPFileName=0;
        TAPFile=0;
        MATFileName=0;
        MATFile=0;
		LogFileName=0;
        LogFile=0;
		ResFileName=0;
        ResFile=0;
        LogFileId=0;
        ResFileId=0;
        return
    end

    figure(figure_Main);

	PenFile = [PenFilePath PenFileName];

	PrintStatus(ProgramLogId, ['Penetration file: ' PenFile],2);

   
	% Results (RES), Log (LOG), Temperature & Pressure (TAP), and Variables 
    % from SlugPen workspace MAT files name and path
	% ---------------------------------------------------------------------
	extInd = find(PenFileName == '.');
	FileName = PenFileName(1:extInd-1);
	clear extInd;

	TAPName = FileName;
    TAPFileName = [FileName '.tap'];
    MATFileName = [FileName '.mat'];
	ResFileName = [FileName '.res'];
	LogFileName = [FileName '.log'];

    % Make a directory for the results files for this penetration
    % ----------------------------------------------------------
    PenPath = [CurrentPath 'outputs/' FileName '-out'];
    if ~exist(PenPath, 'dir')
        mkdir([CurrentPath 'outputs/'],[FileName '-out'])
    end
	
    TAPFile = [PenFilePath TAPFileName];
    MATFile = [PenFilePath MATFileName];

    LogFile = [PenPath '/outputs/' LogFileName];
    LogFileId = fopen(LogFile,'w');
    
   
    % Ensure there is not an existing .res file in this directory that will
    % be overwritten. If there is an existing .res file with same name, ask
    % user whether to continue and overwrite or cancel and allow user to
    % move or rename the exitign .res file.
    % ---------------------------------------------------------------------
    ResFile = [PenPath '/' ResFileName];
    if exist(ResFile, 'file')
        overwriteRes = uiconfirm(figure_Main, ['Results (.res) file for ' ...
            'this penetration' ...
            ' already exists in this directory.' newline newline ...
            'Continuing will overwrite all results recorded on this file. ' ...
            'To avoid losing previously recorded results and create a new ' ...
            'results file for this penetration, cancel and rename or move ' ...
            'existing .res ' ...
            'file to another directory.'], 'Results File Will Be Overwritten', ...
            'Icon','warning','Options',{'Overwrite existing .res file', ...
            'Cancel'});
        switch overwriteRes
            case 'Overwrite existing .res file'
	            ResFileId = fopen(ResFile,'w');
            case 'Cancel'
                ResFileId=[];
        end
    else
        ResFileId = fopen(ResFile,'w');
    end

    if isempty(ResFileId)
        return
    end
    
	

% Update SlugHeat22 Log file
% --------------------------

    % Temperature and pressure (TAP) file name and path
    PrintStatus(ProgramLogId, ' -- Finding tap file from SlugPen...',1);

	PrintStatus(ProgramLogId, ['TAP file: ' TAPFile],2);

   % Workspace variables MAT file name and path
    PrintStatus(ProgramLogId, ' -- Finding mat file from SlugPen...',1);

	PrintStatus(ProgramLogId, ['MAT file: ' MATFile],2);

    % Main parameters
    PrintStatus(ProgramLogId, [' -- Reading in parameters from parameter ' ...
    'file...'],1);


