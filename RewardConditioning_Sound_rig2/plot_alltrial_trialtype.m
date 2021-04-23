function fig = plot_alltrial_trialtype( SessionData, trials )

maxTrials = length(SessionData.RawEvents.Trial);
if nargin<2, trials = 1:maxTrials; end

fig = figure; hold on;



% align from trigger
try
    TrigStart = arrayfun( @(jj) SessionData.RawEvents.Trial{jj}.States.TrigTrialStart(2), 1:maxTrials);
catch
    TrigStart = arrayfun( @(jj) 0, 1:maxTrials);
end


for stimtypes =[1,2]
   ax(stimtypes) = subplot(1,2,stimtypes);
   hold on;
   trialID = find( SessionData.TrialTypes(trials) == stimtypes );
   plot_subtypes( ax(stimtypes), SessionData, trials(trialID), TrigStart )
   title( ['Stim ', num2str(stimtypes)] )
end



end


function plot_subtypes( ax, SessionData, subTrials, TrigStart )
    
    lickevent = 'BNC2High';
    nTrials = length(subTrials);
    leg(1) = scatter( ax, NaN, NaN, 20, 'r', 'filled');

    for trial=subTrials
    plot( ax, SessionData.RawEvents.Trial{1,trial}.States.SamplePeriod - TrigStart(trial), [trial,trial], 'k');
    end
    leg(2) = plot( ax,  NaN, NaN, 'k');

    for trial=subTrials
    if isfield(SessionData.RawEvents.Trial{1,trial}.States,'Reward')
        lw=1;
        if isfield( SessionData.RawEvents.Trial{trial}.Events, lickevent)
            if any(SessionData.RawEvents.Trial{trial}.Events.(lickevent)>=SessionData.RawEvents.Trial{trial}.States.Reward(1) ... 
           & SessionData.RawEvents.Trial{trial}.Events.(lickevent)<=SessionData.RawEvents.Trial{trial}.States.RewardConsumption(2))
            lw=3;
            end
        end
    plot( ax, SessionData.RawEvents.Trial{1,trial}.States.Reward - TrigStart(trial), [trial,trial], 'b', 'linewidth',lw);
    plot( ax, SessionData.RawEvents.Trial{1,trial}.States.RewardConsumption - TrigStart(trial), [trial,trial], 'b', 'linewidth',lw);
    end
    end

    leg(3) = plot( ax,  NaN, NaN, 'b');

    for trial=subTrials
    if isfield(SessionData.RawEvents.Trial{1,trial}.States,'AnswerPeriod')
    plot( ax, SessionData.RawEvents.Trial{1,trial}.States.AnswerPeriod - TrigStart(trial), [trial,trial], 'g');
    end
    end
    leg(4) = plot( ax,  NaN, NaN, 'g');

    % licks
    for trial=subTrials
    if isfield( SessionData.RawEvents.Trial{1,trial}.Events, lickevent), 
        licks = SessionData.RawEvents.Trial{1,trial}.Events.(lickevent) - TrigStart(trial); 
        scatter( ax, licks, ones(size(licks))*trial, 10,'r','filled');
    end
    end
    
    legend( leg, 'Licks', 'SamplePeriod', 'Reward and consumption', 'Answer Period');
    xlim([-1, 4] );
end