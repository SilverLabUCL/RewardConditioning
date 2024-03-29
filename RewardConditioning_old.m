%% HG 2021

function RewardConditioning_old()
    
    % SETUP
    % You will need:
    % - A Bpod.
    % > Port#1: Lickport, DI/O
    % > Port#2: Pole (LED channel)

    global BpodSystem S;

    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

        S.GUI.WaterValveTime = 0.05;        % in sec
        S.GUI.PreSamplePeriod = 0.5;        % in sec
        S.GUI.SamplePeriod = 0.05;          % in sec
        S.GUI.Delay = 0.2;                  % in sec
        S.GUI.AnswerPeriod = 1.5;           % in sec
        S.GUI.ConsumptionPeriod = 1.5;      % in sec
        S.GUI.StopLickingPeriod = 0.5;      % in sec
        S.GUI.TimeOut = 4;                  % in sec
        S.GUIPanels.Behaviour= {'WaterValveTime', 'PreSamplePeriod', 'SamplePeriod', 'Delay', 'AnswerPeriod',...
            'ConsumptionPeriod', 'StopLickingPeriod', 'TimeOut'};


        %S.GUI.NoGoPosition = 7e4;
        S.GUI.Position = 2e4;        
        S.GUI.MotorMoveTime = 2;
        S.GUI.APMotorPosition = 1.5;
        S.GUI.LateralPolePosition = 1e5;
        

        S.GUIPanels.PolePositions = {'Position', 'MotorMoveTime', 'APMotorPosition', 'LateralPolePosition'};


        S.GUIMeta.ProtocolType.Style = 'popupmenu';     % protocol type selection
        
        S.GUIMeta.ProtocolType.String = {'Water_Valve_Calibration', 'Licking', ... case 1,2
                                         'Pole_Delay_Reward',   'Pole_Trace_Delay_Reward', ... case 3,4
                                         'Pole_Delay_Response', 'Pole_Trace_Delay_Response',  ... case 5,6
                                         'Pole_Nolick_Delay_Reward', 'Pole_Nolick_Delay_Reward' }; % case 7,8
        S.GUI.ProtocolType = 3;

        S.GUIPanels.Protocol= {'ProtocolType'};

    end

    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    % Sync the protocol selections
    p = cellfun(@(x) strcmp(x,'ProtocolType'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualChangeProtocol, S})

    % Initiate motor
    initiateZaberMotor;    

    % Setup manual motor inputs
    p = cellfun(@(x) strcmp(x,'APMotorPosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualMoveZaberMotor,'1'})

    p = cellfun(@(x) strcmp(x,'LateralPolePosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualMoveZaberMotor,'2'})


    % Move motors to current values from config file
    p = cellfun(@(x) strcmp(x,'APMotorPosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    anterior_pole_position = get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String');
    move_absolute(motors,str2double(anterior_pole_position),1);

    p = cellfun(@(x) strcmp(x,'LateralPolePosition'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    lateral_pole_position = get(BpodSystem.GUIHandles.ParameterGUI.Params(p),'String');
    move_absolute(motors,str2double(lateral_pole_position),2);


    %% Define trials
    MaxTrials = 9999;
    TrialTypes = [];
    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    BpodSystem.Data.TrialOutcomes = []; % The trial outcomes


    %% Initialise plots
    BpodSystem.ProtocolFigures.PerfOutcomePlotFig = figure('Position', [150 800 1600 200], ...
        'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'Color', [1 1 1]);

    BpodSystem.GUIHandles.PerfOutcomePlot = axes('Position', [.15 .2 .8 .7], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'nDisplay: ','Position',[20 170 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.DisplayNTrials = uicontrol('Style','edit','string','100','Position',[125 170 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'hit % (all): ','Position',[20 140 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.hitpct = uicontrol('Style','text','string','0','Position',[125 140 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'hit % (40): ','Position',[20 120 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.hitpctrecent = uicontrol('Style','text','string','0','Position',[125 120 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'Trials: ','Position',[20 40 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.numtrials = uicontrol('Style','text','string','0','Position',[125 40 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    uicontrol('Style', 'text', 'String', 'Rewards: ','Position',[20 20 100 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
    BpodSystem.GUIHandles.numRewards = uicontrol('Style','text','string','0','Position',[125 20 40 18], ...
        'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    PerfOutcomePlot(BpodSystem.GUIHandles.PerfOutcomePlot,1,'init',0);
    
    % Pause the protocol before starting
    BpodSystem.Status.Pause = 1;
    HandlePauseCondition;


    % Define outputs
    io.WaterOutput  = {'ValveState',2^0};    % Valve 1 open 
    io.PoleOutput = {'PWM2',255};            % Behavioural port 2, LED pin
    io.AcqTrig = {'BNC1', 1};
    io.Bitcode = {'BNC2', 1};
    io.CameraTrig = {'WireState', 1};
   

    %% Main trial loop
    
    % Move motor into position
    moveZaberMotors(1); 

    for currentTrial = 1 : MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

        disp(['Starting trial ',num2str(currentTrial)])

        TrialTypes(currentTrial) = 1; % only one kind of trial
        PerfOutcomePlot(BpodSystem.GUIHandles.PerfOutcomePlot,currentTrial,'next_trial',TrialTypes(currentTrial), BpodSystem.GUIHandles.DisplayNTrials);

        sma = NewStateMatrix(); % Assemble state matrix

        % Build state matrix depending on the protocol type
        switch S.GUI.ProtocolType
%%            
            case 1          % Water_Valve_Calibration            
            %---------------------------------------------------------
            % Water_Valve_Calibration when sensor is touched, release 50 drops every 0.5 seconds
                

            
                ndrops = 50; interval = 0.5;

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                    
                    'Timer', interval, ...
                    'StateChangeConditions', {'Port1In', 'Drop1_Openvalve', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', {});

                for i_drop = 1:ndrops-1   

                    sma = AddState(sma, 'Name', ['Drop',num2str(i_drop),'_Openvalve'], ...
                        'Timer', S.GUI.WaterValveTime, ...
                        'StateChangeConditions', {'Tup', ['Drop',num2str(i_drop),'_Closevalve']}, ...
                        'OutputActions', io.WaterOutput);

                    sma = AddState(sma, 'Name', ['Drop',num2str(i_drop),'_Closevalve'], ...
                        'Timer', interval, ...
                        'StateChangeConditions', {'Tup', ['Drop',num2str(i_drop+1),'_Openvalve']}, ...
                        'OutputActions', {});           
                end

                sma = AddState(sma, 'Name', ['Drop',num2str(ndrops),'_Openvalve'], ...
                    'Timer', S.GUI.WaterValveTime,...
                    'StateChangeConditions', {'Tup', 'TrialEnd'}, ...
                    'OutputActions', io.WaterOutput);
                
                sma = AddState(sma, 'Name', 'TrialEnd', ...                            
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});

                
%%
            case 2          % Licking
            %---------------------------------------------------------
            % Each lick is rewarded with reward
            
                
                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                sma = AddState(sma, 'Name', 'WaitForLick', ...
                    'Timer', 300,...
                    'StateChangeConditions', {'Port1In', 'Reward', 'Tup', 'NoResponse'}, ...
                    'OutputActions', {});
                sma = AddState(sma, 'Name', 'Reward', ...
                    'Timer', S.GUI.WaterValveTime,...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions',  io.WaterOutput);
                sma = AddState(sma, 'Name', 'NoResponse', ...
                    'Timer', 0.05,...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});


                
%%
            case 3          % 'Pole_Delay_Reward'
            %---------------------------------------------------------                
                % Stim-Pole comes in, Reward is delivered after Delay
                % No punishment and no reqt for licking
                % Pole stays in throughout

                LickAction = '';  % licking changes nothing

                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                
                sma = AddState(sma, 'Name', 'TrigTrialStart', ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   

                
                sma = AddState(sma, 'Name', 'Delay', ...                         % pole still in.. keep waiting
                    'Timer', S.GUI.Delay, ...
                    'StateChangeConditions', {'Tup', 'Reward'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.PoleOutput io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);


                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % pole out and trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});

%%
            case 4          % 'Pole_Trace_Delay_Reward'
            %---------------------------------------------------------                
                % Stim-Pole comes in, stays only for sample period
                % Reward is delivered after Delay
                % No punishment and no reqt for licking


                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                
                sma = AddState(sma, 'Name', 'TrigTrialStart', ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   

                
                sma = AddState(sma, 'Name', 'Delay', ...                         % pole out and wait..
                    'Timer', S.GUI.Delay, ...
                    'StateChangeConditions', {'Tup', 'Reward'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);   

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);


                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});
                
  

%%                
            case 5          % 'Pole_Delay_Response'
            %---------------------------------------------------------     
                % operant conditioning
                % reward is delivered after delay only if there is licking
                % in answer period
                

                % only go trials
                LickAction = 'Reward';
                
                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data


                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                       % pre-sample
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   
                
                
                sma = AddState(sma, 'Name', 'Delay', ...                                % pole in
                    'Timer', S.GUI.Delay, ...
                    'StateChangeConditions', {'Tup', 'AnswerPeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);                   
                
                sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % pole still in and wait for response
                    'Timer', S.GUI.AnswerPeriod, ...
                    'StateChangeConditions', {'Port1In', LickAction, 'Tup', 'NoResponse'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.PoleOutput io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'NoResponse', ...                           % no response
                    'Timer', 0.002, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});

                
                
%%                
            case 6          % 'Pole_Trace_Delay_Response'
            %---------------------------------------------------------     
                % operant conditioning
                % reward is delivered after delay only if there is licking
                % in answer period
                

                % only go trials
                LickAction = 'Reward';
                
                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                       % pre-sample
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   
                
                
                sma = AddState(sma, 'Name', 'Delay', ...                                % pole out and wait
                    'Timer', S.GUI.Delay, ...
                    'StateChangeConditions', {'Tup', 'AnswerPeriod'}, ...
                    'OutputActions', [ io.AcqTrig io.CameraTrig]);                   
                
                sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % and wait for response
                    'Timer', S.GUI.AnswerPeriod, ...
                    'StateChangeConditions', {'Port1In', LickAction, 'Tup', 'NoResponse'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'NoResponse', ...                           % no response
                    'Timer', 0.002, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});
                

                
%%                
            case 7          % Pole_Nolick_delay_Reward',            
            %---------------------------------------------------------    
            % prevent anticipatory licking (< 3 licks in 50 ms) ->
            % restarts delay for fewer licks, else no reward
            
            
                LickAction = 'Reward';
                EarlyLickAction = 'StopLicking'; % no reward for early lick
               
                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in, deliver reward
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   
                
                sma = AddState(sma, 'Name', 'Delay', ...                         % pole in
                    'Timer', S.GUI.Delay, ...
                    'StateChangeConditions', {'Port1In',  'Delay_lick2', 'Tup', 'Reward'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);    
                sma = AddState(sma, 'Name', 'Delay_lick2', ...                         % pole in
                    'Timer', 0.025, ...
                    'StateChangeConditions', {'Port1In', 'Delay_lick3', 'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);    
                sma = AddState(sma, 'Name', 'Delay_lick3', ...                         % pole in
                    'Timer', 0.025, ...
                    'StateChangeConditions', {'Port1In', EarlyLickAction, 'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);    
               

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.PoleOutput io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);


                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % pole out and trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});


        
%%
        case 8     % Pole_Nolick_delay_Response
            %---------------------------------------------------------    
            % timed response (delay operant conditioning)

                LickAction = 'Reward';
                EarlyLickAction = 'StopLicking'; % no reward for early lick
                
                BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
                BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...
                    'Timer', S.GUI.PreSamplePeriod, ...
                    'StateChangeCondition',{'Tup', 'SamplePeriod'}, ...
                    'OutputActions', [io.AcqTrig io.CameraTrig]);

                % Add bitcode here
                sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

                sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % pole in, deliver reward
                    'Timer', S.GUI.SamplePeriod, ...
                    'StateChangeConditions', {'Tup', 'Delay'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);   
                
                sma = AddState(sma, 'Name', 'Delay', ...                                % pole in
                    'Timer', S.GUI.Delay, ...
                    'StateChangeConditions', {'Port1In', EarlyLickAction, 'Tup', 'AnswerPeriod'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);    
               
                
                sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % wait for response
                    'Timer', S.GUI.AnswerPeriod, ...
                    'StateChangeConditions', {'Port1In', LickAction, 'Tup', 'NoResponse'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'Reward', ...                               % turn on water
                    'Timer', S.GUI.WaterValveTime, ...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'}, ...
                    'OutputActions', [io.PoleOutput io.WaterOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'RewardConsumption', ...                    % reward consumption
                    'Timer', S.GUI.ConsumptionPeriod, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'NoResponse', ...                           % no response
                    'Timer', 0.002, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLicking', ...                          % stop licking before advancing to next trial
                    'Timer', S.GUI.StopLickingPeriod, ...
                    'StateChangeConditions', {'Port1In', 'StopLickingReturn', 'Tup', 'TrialEnd'}, ...
                    'OutputActions', [io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'StopLickingReturn', ...                    % return to stop licking
                    'Timer', 0.01, ...
                    'StateChangeConditions', {'Tup', 'StopLicking'}, ...
                    'OutputActions',[io.PoleOutput io.AcqTrig io.CameraTrig]);

                sma = AddState(sma, 'Name', 'TrialEnd', ...                             % pole out and trial end
                    'Timer', 0.05, ...
                    'StateChangeConditions', {'Tup', 'exit'}, ...
                    'OutputActions', {});

                
        end
        
        
        %%
        
        SendStateMatrix(sma);
        RawEvents = RunStateMatrix;         % this step takes a long time and variable (seem to wait for GUI to update, which takes a long time)

        if ~isempty(fieldnames(RawEvents)) % If trial data was returned

            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Add the settings used for the current trial to the Data struct (to be saved after the trial ends)
            BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Add the trial type of the current trial to data

            if S.GUI.ProtocolType > 2
                UpdatePerfOutcomePlot(TrialTypes, BpodSystem.Data);
            end

            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            BpodSystem.ProtocolSettings = S;
            SaveProtocolSettings(S); % SaveBpodProtocolSettings;

        end

        % Pause the protocol before starting if in Water-Valve-Calibration
        if S.GUI.ProtocolType == 1
            BpodSystem.Status.Pause = 1;
        end        

        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.Status.BeingUsed == 0
            return
        end

    end

end



%%
function UpdatePerfOutcomePlot(TrialTypes, Data)

    global BpodSystem
    Outcomes = zeros(1,Data.nTrials);

    for x = 1:Data.nTrials

        if Data.TrialSettings(x).GUI.ProtocolType > 2
        % reward outcome = 1
            if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
                Outcomes(x) = 1;    % correct
                BpodSystem.Data.TrialOutcomes(x) = 1;

            else
                Outcomes(x) = 0;    % no reward
                BpodSystem.Data.TrialOutcomes(x) = 0;
            end
        end
        
        % no response outcome = 2
        if Data.TrialSettings(x).GUI.ProtocolType==5 || Data.TrialSettings(x).GUI.ProtocolType==6  || Data.TrialSettings(x).GUI.ProtocolType==8
            % no response
            if ~isnan(Data.RawEvents.Trial{x}.States.NoResponse(1))
                Outcomes(x) = 2;    % no reward
                BpodSystem.Data.TrialOutcomes(x) = 2;            
            end
        end

    end


    PerfOutcomePlot(BpodSystem.GUIHandles.PerfOutcomePlot,Data.nTrials,'update', ...
        TrialTypes, BpodSystem.GUIHandles.DisplayNTrials, Outcomes);

end


%%
function PerfOutcomePlot(ax, Ntrials, action, varargin)

    global BpodSystem
    sz = 10;

    switch action
        case 'update'
            types = varargin{1};
            displayHand = varargin{2};
            outcomes = varargin{3};

            Ndisplay = str2double(get(displayHand, 'String'));

            toPlot = false(1, Ntrials);

            ind1 = max(1, Ntrials-Ndisplay+1);
            ind2 = Ntrials;

            toPlot(ind1:ind2) = true;

            miss = (outcomes == 0);
            hit  = (outcomes == 1);
            noresponse  = (outcomes == 2);

            hold(ax, 'off');
            xdat = find(toPlot&hit);
            plot(ax, xdat, outcomes(xdat), 'go', 'MarkerSize', sz); hold(ax, 'on');

            xdat = find(toPlot&miss);
            plot(ax, xdat, outcomes(xdat), 'ro', 'MarkerSize', sz);

            xdat = find(toPlot&noresponse);
            plot(ax, xdat, outcomes(xdat), 'kx', 'MarkerSize', sz);

            hitpct = 100.*sum(hit)./Ntrials;
            ind40 = max(1, Ntrials-40+1):Ntrials;
            hitpctrecent = 100.*sum(hit(ind40))./numel(ind40);

            set(BpodSystem.GUIHandles.hitpct, 'String', num2str(hitpct));
            set(BpodSystem.GUIHandles.hitpctrecent, 'String', num2str(hitpctrecent));
            set(BpodSystem.GUIHandles.numtrials, 'String', num2str(Ntrials));
            
            xlim(ax, [ind1 ind1+Ndisplay-1+5]);
            ylim(ax, [0 3]);


        case 'next_trial'
            currentType = varargin{1};
            displayHand = varargin{2};
            Ndisplay = str2double(get(displayHand, 'String'));
            ind1 = max(1, Ntrials-Ndisplay+1);
    %         ind2 = Ntrials;

            hold(ax, 'on');
            plot(ax, Ntrials, currentType+1, 'ko', 'MarkerSize', sz);
            xlim(ax, [ind1 ind1+Ndisplay-1+5]);

    end

    set(ax, 'YTick', [0 1 2], 'YTickLabel', {'EarlyLick'; 'Go', 'NoResp'});

end


%%
% function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
% % If Rewarded based on the state data, update the TotalRewardDisplay
%     global BpodSystem
% 
%     if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Reward(1))
%         
%         TotalRewardDisplay('add', RewardAmount);
%         
%     end
%     
% end


%% Assemble Bitcode
function state_matrix = AddBitcode(state_matrix_in, trial_num, bitcodeCH_output, otherCH_output, next_state_name)
    
    state_matrix = state_matrix_in;

    bit_time = 0.002; % bit time
    gap_time = 0.008; % gap (inter-bit) time
    num_bits = 10;     % 2^10 = 1024 possible trial nums

    x = double(dec2binvec(trial_num)');
    if length(x) < num_bits
        x = [x; zeros([num_bits-length(x) 1])];
    end
    x = double(x); % x is now 10-bit vector giving trial num.

    for i_bit = 1:num_bits

        if x(i_bit)==1

            output_bitONState = [bitcodeCH_output otherCH_output];
        else

            output_bitONState = otherCH_output;
        end

        state_matrix = AddState(state_matrix, 'Name', ['Bitcode_bit',num2str(i_bit),'_ON'], ...                              % incorrect response
            'Timer', bit_time,...
            'StateChangeConditions', {'Tup', ['Bitcode_bit',num2str(i_bit),'_OFF']},...
            'OutputActions', output_bitONState);

        if i_bit < num_bits
            state_matrix = AddState(state_matrix, 'Name', ['Bitcode_bit',num2str(i_bit),'_OFF'], ...                              % incorrect response
                'Timer', gap_time,...
                'StateChangeConditions', {'Tup', ['Bitcode_bit',num2str(i_bit+1),'_ON']},...
                'OutputActions', otherCH_output);

        else
            state_matrix = AddState(state_matrix, 'Name', ['Bitcode_bit',num2str(i_bit),'_OFF'], ...                              % incorrect response
                'Timer', gap_time,...
                'StateChangeConditions', {'Tup', next_state_name},...
                'OutputActions', otherCH_output);
        end

    end

end