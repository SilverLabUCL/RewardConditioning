%% HG 2021

function temp()
    
    % SETUP
    % You will need:
    % - A Bpod.
    % > Port#1: Lickport, DI/O
    % Psych Toolbox (For playing Sound)
    % Speakers

    global BpodSystem S;

    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.WaterValveTime = 0.05;        % in sec
        S.GUI.PreSamplePeriod = 0.5;        % in sec
        S.GUI.SamplePeriod = 0.10;          % in sec
        
        S.GUI.Prob_Cue1  = 1;               % probability of cue 1
        S.GUI.Delay_Cue2 = 0.2;             % in sec
        S.GUI.Delay_Cue1 = 0.2;             % in sec
        S.GUI.RewardProb_Cue1 = 0.8;        % probability of reward for cue 1
        S.GUI.RewardProb_Cue2 = 0.2;        % probability of reward for cue 2
        
        S.GUI.AnswerPeriod = 1.5;           % in sec        
        S.GUI.ConsumptionPeriod = 1.5;      % in sec
        S.GUI.StopLickingPeriod = 0.5;      % in sec
        S.GUI.TimeOut = 4;                  % in sec
        S.GUIPanels.Behaviour= {'WaterValveTime', 'PreSamplePeriod', 'SamplePeriod', ...                          % common params
                                'Prob_Cue1', 'Delay_Cue1', 'Delay_Cue2', 'RewardProb_Cue1', 'RewardProb_Cue2',... % stim dep params
                                'AnswerPeriod', 'ConsumptionPeriod', 'StopLickingPeriod', 'TimeOut'};             % task params

        S.GUI.Freq_Cue1 = 500;        
        S.GUI.Freq_Cue2 = 5000;        
        S.GUIPanels.Stimuli = {'Freq_Cue1', 'Freq_Cue2'};
        
        S.GUIMeta.ProtocolType.Style = 'popupmenu';     % protocol type selection
        S.GUIMeta.ProtocolType.String = {'Water_Valve_Calibration', 'Licking', ... case 1,2
                                         'Stim_Delay_Reward',  'Stim_Delay_Response'  ... case 3,4
                                         'Stim_Nolick_Delay_Reward', 'Stim_Nolick_Delay_Response' }; % case 5,6
        S.GUI.ProtocolType = 3; % default =  delay reward
        S.GUIPanels.Protocol= {'ProtocolType'};
    end

    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    % Sync the protocol selections
    p = cellfun(@(x) strcmp(x,'ProtocolType'),BpodSystem.GUIData.ParameterGUI.ParamNames);
    set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualChangeProtocol, S})

    %% Initiate sounds
    SF = 192000; % Analog module sampling rate
    Cue1 = GenerateSineWave(SF, S.GUI.Freq_Cue1, S.GUI.SamplePeriod)*.9; % Sampling freq (hz), Sine frequency (hz), duration (s)
    Cue2 = GenerateSineWave(SF, S.GUI.Freq_Cue2, S.GUI.SamplePeriod)*.9; % Sampling freq (hz), Sine frequency (hz), duration (s)
    PunishSound = (rand(1,SF*.5)*2) - 1;
    
    PsychToolboxSoundServer('init')
    PsychToolboxSoundServer('Load', 1, Cue1);
    PsychToolboxSoundServer('Load', 2, Cue2);
    PsychToolboxSoundServer('Load', 3, PunishSound)

    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

    %% Define trials
    MaxTrials = 9999;
    TrialTypes = [];
    BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
    BpodSystem.Data.TrialOutcomes = []; % The trial outcomes

    %% Initialise plots
    
    initialise_plots( true, true );
    PerfOutcomePlot(BpodSystem.GUIHandles.PerfOutcomePlot,1,'init',0);
    TrialBehPlot( BpodSystem.GUIHandles.LickFig, 1, [] );
    
    % Pause the protocol before starting
    BpodSystem.Status.Pause = 1;
    HandlePauseCondition;

    % Define outputs
    io.WaterOutput  = {'ValveState',1};      % Valve 1 open 
    io.AcqTrig = {'BNC1', 1};
    io.Bitcode = {'BNC2', 1};
    io.CameraTrig = {'WireState', 1};
    io.Punish = {'SoftCode', 3};
   

    %% Main trial loop
        
    for currentTrial = 1 : MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        disp(['Starting trial ',num2str(currentTrial)])

        % which stim
        xx = rand();
        if xx < S.GUI.Prob_Cue1
            TrialTypes(currentTrial) = 1; rewardProb= S.GUI.RewardProb_Cue1; delay= S.GUI.Delay_Cue1; % stim 1
            stimOut = {'SoftCode', 1};
        else                       
            TrialTypes(currentTrial) = 2; rewardProb= S.GUI.RewardProb_Cue2; delay= S.GUI.Delay_Cue2; % stim 2
            stimOut = {'SoftCode', 2};
        end

        PerfOutcomePlot(BpodSystem.GUIHandles.PerfOutcomePlot,currentTrial,'next_trial',TrialTypes(currentTrial), BpodSystem.GUIHandles.DisplayNTrials);

        sma = NewStateMatrix(); % Assemble state matrix
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data

        % Build state matrix depending on the protocol type
        if S.GUI.ProtocolType==1   % Water_Valve_Calibration
        %---------------------------------------------------------
        %  when sensor is touched, release 50 drops every 0.5 seconds
           
                ndrops = 50; interval = 0.5;

                sma = AddState(sma, 'Name', 'TrigTrialStart', ...                    
                    'Timer', interval, ...
                    'StateChangeConditions', {'Tup', 'Drop1_Openvalve'}, ...
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

        else
            
        %% Tasks 
        
        % Default transitions
        SampleState = 'SamplePeriod';
        SampleTup = 'Delay';
        AnswerTup = 'NoResponse';
        DelayTrig = []; % nothing happens during delay licking
        lickDelay = 0.025; % punish for 3 licks in 50 ms
        EarlyLickAction = 'Punish';
        
        % rewarded?
        yy = rand(); if yy<rewardProb, doReward=1; else, doReward=0; end
        
        % conditioning task with probabilistic reward
        if doReward 
            DelayTup = 'Reward'; LickAction = 'Reward';
        else
            DelayTup = 'StopLicking'; LickAction = 'StopLicking';
        end
        
        switch S.GUI.ProtocolType
            case 2          % Licking
            %---------------------------------------------------------
            % Each lick is rewarded with reward
                SampleState = 'WaitForLick';
                LickAction = 'Reward';        
                
            case 3          % 'Stim_Delay_Reward'
            %---------------------------------------------------------                
                % Stim-Pole comes in, Reward is delivered after Delay
                % No punishment and no reqt for licking
                % Pole stays in throughout

            case 4          % 'Stim_Delay_Response'
            %---------------------------------------------------------     
                % operant conditioning
                % reward is delivered after delay only if there is licking
                % in answer period
                DelayTup = 'AnswerPeriod'; % need reward for lick
                                
            case 5          % Stim_Nolick_delay_Reward'            
            %---------------------------------------------------------    
            % prevent anticipatory licking (< 3 licks in 50 ms) ->
            % restarts delay for fewer licks, else no reward
            SampleTup = 'Delay_nolick';
            DelayTrig = {'GlobalTimerTrig', 1}; % start delay timer
                    
            case 6     % Stim_Nolick_delay_Response
            %---------------------------------------------------------    
            % timed response (delay operant conditioning)
            SampleTup = 'Delay_nolick';
            DelayTrig = {'GlobalTimerTrig', 1}; % start delay timer
            DelayTup = 'AnswerPeriod'; % need reward for lick
                
        end
        
        % can add output channel for light or sound later - to enforce no
        % licking period
        sma = SetGlobalTimer(sma, 'TimerID', 1, 'Duration', delay, 'OnsetDelay', 0); 
        
        sma = AddState(sma, 'Name', 'TrigTrialStart', ...                       % pre-sample
                'Timer', S.GUI.PreSamplePeriod, ...
                'StateChangeCondition',{'Tup', SampleState}, ...
                'OutputActions', [io.AcqTrig io.CameraTrig]);
            
        sma = AddState(sma, 'Name', 'WaitForLick', ...
                    'Timer', 300,...
                    'StateChangeConditions', {'Port1In', 'Reward', 'Tup', 'NoResponse'}, ...
                    'OutputActions', {});
        
        sma = AddBitcode(sma, currentTrial, io.Bitcode, [io.AcqTrig io.CameraTrig], 'SamplePeriod');

        sma = AddState(sma, 'Name', 'SamplePeriod', ...                         % play sound
            'Timer', S.GUI.SamplePeriod, ...
            'StateChangeConditions', {'Tup',SampleTup}, ...
            'OutputActions', [stimOut io.AcqTrig io.CameraTrig]);   


        % delay states
        % ----------------------------------------------------------------
        sma = AddState(sma, 'Name', 'Delay', ...                                % just wait (no punish for licks)
            'Timer', delay, ...
            'StateChangeConditions', {'Tup', DelayTup}, ...
            'OutputActions', [io.AcqTrig io.CameraTrig]);                   

        % enforce no licking (no 3 licks within 50 ms; isolated licks ok)
        sma = AddState(sma, 'Name', 'Delay_nolick', ...                         
            'Timer', delay, ...
            'StateChangeConditions', {'Tup', DelayTup, 'Port1In', 'Delay_nolick2'}, ... % move if lick
            'OutputActions', [DelayTrig io.AcqTrig io.CameraTrig]);     % start delay timer and wait...

        sma = AddState(sma, 'Name', 'Delay_nolick1', ...                         % wait ...
            'Timer', delay, ...
            'StateChangeConditions', {'Tup', DelayTup, 'GlobalTimer1_End', DelayTup, 'Port1In', 'Delay_nolick2'}, ... % move if lick
            'OutputActions', [io.AcqTrig io.CameraTrig]);                   
        
        
        sma = AddState(sma, 'Name', 'Delay_nolick2', ...                         % wait for 3rd lick
            'Timer', lickDelay, ...
            'StateChangeConditions', {'Tup', 'Delay_nolick1', 'GlobalTimer1_End', DelayTup, 'Port1In', 'Delay_nolick3'}, ... % move if lick
            'OutputActions', [io.AcqTrig io.CameraTrig]);                           
        
        
        sma = AddState(sma, 'Name', 'Delay_nolick3', ...                         % wait for 3rd lick
            'Timer', lickDelay, ...
            'StateChangeConditions', {'Tup', 'Delay_nolick1', 'GlobalTimer1_End', DelayTup, 'Port1In', EarlyLickAction}, ... % punish if licking
            'OutputActions', [io.AcqTrig io.CameraTrig]);                   
        
        sma = AddState(sma, 'Name', 'Punish', ...                         % punish sound
            'Timer', S.GUI.SamplePeriod, ...
            'StateChangeConditions', {'Tup', 'StopLicking'}, ... %
            'OutputActions', [io.Punish io.AcqTrig io.CameraTrig]);                   

        
        % response and reward states
        % -----------------------------------------------------------------
        sma = AddState(sma, 'Name', 'AnswerPeriod', ...                         % pole still in and wait for response
            'Timer', S.GUI.AnswerPeriod, ...
            'StateChangeConditions', {'Port1In', LickAction, 'Tup', AnswerTup}, ...
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

        end
        
        
        SendStateMatrix(sma);
        RawEvents = RunStateMatrix;         % this step takes a long time and variable (seem to wait for GUI to update, which takes a long time)

        if ~isempty(fieldnames(RawEvents)) % If trial data was returned

            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Add the settings used for the current trial to the Data struct (to be saved after the trial ends)
            BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Add the trial type of the current trial to data

            if S.GUI.ProtocolType > 2
                UpdatePerfOutcomePlot(TrialTypes, BpodSystem.Data);
                TrialBehPlot(BpodSystem.GUIHandles.LickFig, BpodSystem.Data.nTrials, currentTrial)
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

        % reward outcome = 1
        if Data.TrialSettings(x).GUI.ProtocolType > 2        
            if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
                Outcomes(x) = 2;    % hit
                BpodSystem.Data.TrialOutcomes(x) = 1;
                if isfield( BpodSystem.Data.RawEvents.Trial{x}.Events, 'Port1In')
                   if any(BpodSystem.Data.RawEvents.Trial{x}.Events.Port1In>=BpodSystem.Data.RawEvents.Trial{x}.States.Reward(1) ... 
                        & BpodSystem.Data.RawEvents.Trial{x}.Events.Port1In<=BpodSystem.Data.RawEvents.Trial{x}.States.RewardConsumption(2))
                       Outcomes(x) = 1;    % reward delivered, maybe not consumed
                   end
                end
                BpodSystem.Data.TrialOutcomes(x) = Outcomes(x);
            else
                if isfield( BpodSystem.Data.RawEvents.Trial{x}.Events, 'Port1In')
                   bad_licks = find( BpodSystem.Data.RawEvents.Trial{x}.Events.Port1In>=BpodSystem.Data.RawEvents.Trial{x}.States.Delay(2)); 
                   if length(bad_licks)>3
                       Outcomes(x) = 3;    % early/bad ;icks
                   else
                       Outcomes(x) = 0;
                   end
                else
                    Outcomes(x) = 0;    % no reward given
                end
                BpodSystem.Data.TrialOutcomes(x) = Outcomes(x);
            end
        end
        
        % operant (no lick)
        if Data.TrialSettings(x).GUI.ProtocolType==4 || Data.TrialSettings(x).GUI.ProtocolType==6
            % no response
            if ~isnan(Data.RawEvents.Trial{x}.States.NoResponse(1))
                Outcomes(x) = 2;    % no lick, no reward
                BpodSystem.Data.TrialOutcomes(x) = 2;            
            end
        end
        
        % lick during delay
        if Data.TrialSettings(x).GUI.ProtocolType==5 || Data.TrialSettings(x).GUI.ProtocolType==6
            if isnan(Data.RawEvents.Trial{x}.States.NoResponse(1)) && isnan(Data.RawEvents.Trial{x}.States.Reward(1))
                Outcomes(x) = 3;    % early licks
                BpodSystem.Data.TrialOutcomes(x) = 3;         
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

            Type1 = (types==1);
            hit  = (outcomes == 1); %reward delivered
            noresponse  = (outcomes == 2);
            
            Type2 = (types==2);
            norew = (outcomes == 0);
            earlylick = (outcomes == 3);

            hold(ax, 'off');
            xdat = find(toPlot&hit);
            plot(ax, xdat, types(xdat), 'go', 'MarkerSize', sz); hold(ax, 'on'); % plot based on stim type

            xdat = find(toPlot&norew);
            plot(ax, xdat, types(xdat), 'kx', 'MarkerSize', sz);

            xdat = find(toPlot&noresponse);
            plot(ax, xdat, types(xdat), 'ro', 'MarkerSize', sz);

            xdat = find(toPlot&earlylick);
            plot(ax, xdat, types(xdat), 'rx', 'MarkerSize', sz);

            hitpct = 100.*sum(hit&Type1)./(sum(Type1));
            corrrej = 100.*sum(norew&Type2)./(sum(Type2));
            ind40 = max(1, Ntrials-40+1):Ntrials;
            
            hitpctrecent = 100.*sum(hit(ind40)&Type1(ind40))./sum(Type1(ind40));
            correjrecent = 100.*sum(norew(ind40)&Type2(ind40))./sum(Type2(ind40));

            set(BpodSystem.GUIHandles.hitpct, 'String', num2str(hitpct));
            set(BpodSystem.GUIHandles.hitpctrecent, 'String', num2str(hitpctrecent));
            set(BpodSystem.GUIHandles.numtrials, 'String', num2str(Ntrials));
            set(BpodSystem.GUIHandles.numRewards, 'String', num2str(sum(hit)+sum(noresponse)));
            
            set(BpodSystem.GUIHandles.corrRej, 'String', num2str(corrrej));
            set(BpodSystem.GUIHandles.corrRejrecent, 'String', num2str(correjrecent));
            
            xlim(ax, [ind1 ind1+Ndisplay-1+5]);
            ylim(ax, [0 3]);


        case 'next_trial'
            currentType = varargin{1};
            displayHand = varargin{2};
            Ndisplay = str2double(get(displayHand, 'String'));
            ind1 = max(1, Ntrials-Ndisplay+1);
    %         ind2 = Ntrials;

            hold(ax, 'on');
            plot(ax, Ntrials, currentType, 'ko', 'MarkerSize', sz);
            xlim(ax, [ind1 ind1+Ndisplay-1+5]);

    end

    set(ax, 'YTick', [1 2], 'YTickLabel', {'Cue1'; 'Cue2'});

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
%%


function TrialBehPlot(ax, Ntrials, trials)

    global BpodSystem
    sz = 10;
    
    Ndisplay = 40;
    ind1 = max(1, Ntrials-Ndisplay+1);
    
    hold(ax, 'on');
    
    
    leg(1) = scatter(ax, NaN, NaN, sz, 'r', 'filled');


    for trial=trials
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.SamplePeriod, [trial,trial], 'k');
    end
    leg(2) = plot(ax, NaN, NaN, 'k');

    for trial=trials
    if isfield(BpodSystem.Data.RawEvents.Trial{1,trial}.States,'Reward')
        lw=1;
        if isfield( BpodSystem.Data.RawEvents.Trial{trial}.Events, 'Port1In')
            if any(BpodSystem.Data.RawEvents.Trial{trial}.Events.Port1In>=BpodSystem.Data.RawEvents.Trial{trial}.States.Reward(1) ... 
           & BpodSystem.Data.RawEvents.Trial{trial}.Events.Port1In<=BpodSystem.Data.RawEvents.Trial{trial}.States.RewardConsumption(2))
            lw=3;
            end
        end
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.Reward, [trial,trial], 'b', 'linewidth',lw);
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.RewardConsumption, [trial,trial], 'b', 'linewidth',lw);
    end
    end
    
    leg(3) = plot( ax, NaN, NaN, 'b');

    for trial=trials
    if isfield(BpodSystem.Data.RawEvents.Trial{1,trial}.States,'AnswerPeriod')
    plot(ax, BpodSystem.Data.RawEvents.Trial{1,trial}.States.AnswerPeriod, [trial,trial], 'g');
    end
    end
    leg(4) = plot(ax,  NaN, NaN, 'g');

    % licks
    for trial=trials
    if isfield( BpodSystem.Data.RawEvents.Trial{1,trial}.Events, 'Port1In'), licks = BpodSystem.Data.RawEvents.Trial{1,trial}.Events.Port1In; 
    scatter(ax, licks, ones(size(licks))*trial, sz,'r','filled');
    end
    end
    
    legend(ax,  leg, 'Licks', 'SamplePeriod', 'Reward and consumption', 'Answer Period');
    ylim(ax, [ind1 ind1+40]);
    xlim(ax, [-1, 8] );
end

function initialise_plots( doOutcome, doLicks )

    global BpodSystem
    if nargin<2, doLicks=true; end
    if nargin<1, doOutcome=true'; end
    
    if doOutcome
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

        uicontrol('Style', 'text', 'String', 'CR % (all): ','Position',[20 120 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.corrRej = uicontrol('Style','text','string','0','Position',[125 120 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        
        
        uicontrol('Style', 'text', 'String', 'hit % (40): ','Position',[20 90 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.hitpctrecent = uicontrol('Style','text','string','0','Position',[125 90 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        
        
        uicontrol('Style', 'text', 'String', 'CR % (40): ','Position',[20 70 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.corrRejrecent = uicontrol('Style','text','string','0','Position',[125 70 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        
        

        uicontrol('Style', 'text', 'String', 'Trials: ','Position',[20 40 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.numtrials = uicontrol('Style','text','string','0','Position',[125 40 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

        uicontrol('Style', 'text', 'String', 'Rewards: ','Position',[20 20 100 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);
        BpodSystem.GUIHandles.numRewards = uicontrol('Style','text','string','0','Position',[125 20 40 18], ...
            'HorizontalAlignment', 'left', 'BackgroundColor', [1 1 1], 'FontSize', 11);

    
    end

    
    if doLicks
        
        BpodSystem.ProtocolFigures.LickFig = figure('Position', [150 400 800 400], ...
            'name','Trial behaviour plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off', 'Color', [1 1 1]);

        BpodSystem.GUIHandles.LickFig = axes('Position', [.15 .2 .8 .7], 'FontSize', 11);
    end
    
    
end



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