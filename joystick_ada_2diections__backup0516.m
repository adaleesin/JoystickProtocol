function joystick_ada_2diections
% joystick_ada_2diections
% Ada LI, May30 2016

global BpodSystem

%% Program PulsePal
%load(fullfile(BpodSystem.ProtocolPath, 'AudGonogo_PulsePalProgram.mat'));
%ProgramPulsePal(ParameterMatrix);

%% ******************************************
% Training Level
TrainingLevel = 3 % option 1, 2 ,3, 4

switch TrainingLevel
    case 1 
        airpuff_dur = 0.02;
        TrialTypeProbs = [1 0];   % Go A only
    case 2 
        airpuff_dur = 0.02;
        TrialTypeProbs = [0 1];  % Go B only
    case 3 % task without air puff
        airpuff_dur = 0.02;
        TrialTypeProbs= [0.5 0.5];  % trial types --- Go A, Go B,
    case 4 % task without air puff
        airpuff_dur = 0.02;
        TrialTypeProbs= [0.5 0.5];  
    case 5 % task without air puff
        airpuff_dur = 0.02;
        TrialTypeProbs= [0.5 0.5];  
end

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.SoundDuration=1;          %sec
    S.SoundRamping=0.4;         %sec
    S.GUI.MeanSoundFrequencyA = 500;   %Hz
    S.GUI.MeanSoundFrequencyB = 50000;  %Hz
    WidthOfFrequencies=2;
    NumberOfFrequencies=5;
    S.GUI.RewardAmount = 8; % defalut 5, amount of reward delivered to the mouse in microliters
    S.GUI.PunishDuration = airpuff_dur;
    S.TrialTypeProbs = TrialTypeProbs; %Probability of trial types 1(go) & 2(nogo) in the session
%     S.ITI = 1;
    S.WaitForRunDur = 5;
    S.RewardValveCode =1;
    S.PunishValveCode =2;
   
    
end

%% Define trials
if TrainingLevel < 4 
maxTrials = 5000;
S.TrialTypes = zeros(1,maxTrials);
for x = 1:maxTrials
    P = rand;
    Cutoffs = cumsum(S.TrialTypeProbs);
    Found = 0;
    for y = 1:length(S.TrialTypeProbs)
        if P<Cutoffs(y) && Found == 0
            Found = 1;
            S.TrialTypes(x) = y;
        end
    end
end

elseif TrainingLevel == 4 
maxTrials =600;    
S.TrialTypes = zeros(1,maxTrials);
S.TrialTypes(1:300)=1;
S.TrialTypes(301:600)=2;
else 
maxTrials = 600;    
S.TrialTypes = zeros(1,maxTrials);
S.TrialTypes(1:300)=2;
S.TrialTypes(301:600)=1;
end

%% Initialize parameter GUI plugin
BpodParameterGUI('init', S);
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [400 600 1000 200],'Name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
OutcomePlot_Joystick(BpodSystem.GUIHandles.OutcomePlot,'init',2-S.TrialTypes);
BpodNotebook('init');

%% Define stimuli and send to sound server
SF = 192000; % Sound card sampling rate
noise = randn(1, SF);  
% noise = noise / max(abs(noise));
Sound1=SoundGenerator(SF, S.GUI.MeanSoundFrequencyA, WidthOfFrequencies, NumberOfFrequencies, S.SoundDuration, S.SoundRamping);
Sound2=SoundGenerator(SF, S.GUI.MeanSoundFrequencyB, WidthOfFrequencies, NumberOfFrequencies, S.SoundDuration, S.SoundRamping);

% Program sound server
PsychToolboxSoundServer('init');
PsychToolboxSoundServer('Load', 1, Sound1); %PsychToolboxSoundServer('load', SoundID, Waveform)
PsychToolboxSoundServer('Load', 2, Sound2); %Sounds are triggered by sending a soft code back to the governing computer 
                                            %from a trial's state matrix, and calling PsychToolboxSoundServer from a predetermined 
                                            %soft code handler function.
PsychToolboxSoundServer('Load', 3, noise); 
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';


%% Main loop
for currentTrial = 1:maxTrials
    disp(['Trial # ' num2str(currentTrial) ': trial type ' num2str(S.TrialTypes(currentTrial))]);
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    switch S.TrialTypes(currentTrial)
        case 1  % Go A; 
            %ParameterMatrix{5,2} = 0.0001; % Set PulsePal to 100us pulse width on output channel 1
            %ParameterMatrix{8,2} = 0.0001; % Set PulsePal to 100us pulse interval on output channel 1
%             StateReinforcer = 'TriggerReward_A';
        
            OutputActionArgument = {'SoftCode', 1,'WireState',4};  % generate sound
        case 2  % Go B; 
            %ParameterMatrix{5,2} = 0.001; % Set PulsePal to 100us pulse width on output channel 1
            %ParameterMatrix{8,2} = 0.001; % Set PulsePal to 100us pulse interval on output channel 1
%             StateReinforcer = 'TriggerReward_B';
            
            OutputActionArgument = {'SoftCode', 2,'WireState',8};
    end
    %ProgramPulsePal(ParameterMatrix);
    WaterTime = GetValveTimes(S.GUI.RewardAmount,[1]); % This code gets the time valves 2 (valve code)must be open to deliver liquid being set. 
    PuffTime = S.GUI.PunishDuration;
    
        S.ReinforcementDelays(currentTrial) =1;
%         S.ReinforcementDelays(currentTrial) = 0.5;
    %     Assemble state matrix
    sma = NewStateMatrix();
    sma = AddState(sma, 'Name', 'Dummy1',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','Dummy2'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'Dummy2',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','DeliverStimulus'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DeliverStimulus',...
        'Timer',0.5,...
        'StateChangeConditions',{'Tup','ControlRunDelay'},...
        'OutputActions', OutputActionArgument);
    sma = AddState(sma, 'Name', 'ControlRunDelay', ...
        'Timer',S.ReinforcementDelays(currentTrial),...
        'StateChangeConditions', {'BNC1High', 'DeliverNoise','BNC2High', 'DeliverNoise','Tup','WaitForRun'},...
        'OutputActions', {});
    if S.TrialTypes(currentTrial)==1 
%     sma = AddState(sma, 'Name', 'CueDelivery', ...
%         'Timer', 0.5,...
%         'StateChangeConditions',{'Tup', 'WaitForRun'},...%waiting for trigger in input 1
%         'OutputActions', {'PWM3', 255,'WireState', 1});  
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',S.WaitForRunDur,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC1High','DeliverReward','BNC2High','DeliverPunish'},...
            'OutputActions', {'PWM3', 255,'WireState', 1});
    elseif S.TrialTypes(currentTrial)==2 
%     sma = AddState(sma, 'Name', 'CueDelivery', ...
%         'Timer', 0.5,...
%         'StateChangeConditions',{'Tup', 'WaitForRun'},...%waiting for trigger in input 1
%         'OutputActions', {'PWM3', 255,'WireState', 2}); 
    sma = AddState(sma, 'Name', 'WaitForRun', ...
            'Timer',S.WaitForRunDur,...
            'StateChangeConditions', {'Tup', 'TimeOut','BNC2High','DeliverReward','BNC1High','DeliverPunish'},...
            'OutputActions', {'PWM3', 255,'WireState', 2});
    end 
      
    sma = AddState(sma, 'Name', 'DeliverNoise', ...
        'Timer',0.5,...
        'StateChangeConditions', {'Tup', 'ITI'}, ...
        'OutputActions', {'SoftCode', 3}); 
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer',5,...
        'StateChangeConditions', {'Tup', 'exit'}, ...
        'OutputActions', {}); 
    sma = AddState(sma, 'Name', 'DeliverPunish', ...
        'Timer',PuffTime,...
        'StateChangeConditions', {'Tup', 'ITI'}, ...
        'OutputActions', {'ValveState', 2});
    sma = AddState(sma,'Name', 'DeliverReward', ...
        'Timer',WaterTime, ...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'ValveState', 1});
    sma = AddState(sma, 'Name', 'TimeOut', ...
        'Timer',0.5,...
        'StateChangeConditions', {'Tup', 'ITI'}, ...
        'OutputActions', {'PWM1', 255'}); 

    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
    BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
    BpodSystem.Data = BpodNotebook('sync',BpodSystem.Data);
    BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
    BpodSystem.Data.S.TrialTypes(currentTrial) = S.TrialTypes(currentTrial); % Adds the trial type of the current trial to data
    UpdateOutcomePlot(S.TrialTypes, BpodSystem.Data);
    SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
if BpodSystem.BeingUsed == 0
    return
  end
end



%---------------------------------------- /MAIN LOOP

%% sub-functions
function UpdateOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);
for x = 1:Data.nTrials
    if ~isnan(Data.RawEvents.Trial{x}.States.DeliverReward(1))
        Outcomes(x) = 1;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.DeliverPunish(1))
         Outcomes(x) = 0;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.DeliverNoise(1))
         Outcomes(x) = 2;
    else
        Outcomes(x) = 3;
    end
end
OutcomePlot_Joystick(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,2-TrialTypes,Outcomes);
