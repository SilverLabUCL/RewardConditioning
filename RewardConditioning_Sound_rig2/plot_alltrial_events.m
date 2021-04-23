function fig = plot_alltrial_events( SessionData, trials )

lickevent = 'BNC2High';
if nargin<2, trials = 1:length(SessionData.RawEvents.Trial); end

fig = figure; hold on;


leg(1) = scatter(NaN, NaN, 20, 'r', 'filled');

% align from trigger
try
    TrigStart = arrayfun( @(jj) SessionData.RawEvents.Trial{jj}.States.TrigTrialStart(2), trials);
catch
    TrigStart = arrayfun( @(jj) 0, trials);
end


for trial=trials
plot(SessionData.RawEvents.Trial{1,trial}.States.SamplePeriod - TrigStart(trial), [trial,trial], 'k');
end
leg(2) = plot( NaN, NaN, 'k');

for trial=trials
if isfield(SessionData.RawEvents.Trial{1,trial}.States,'Reward')
    lw=1;
    if isfield( SessionData.RawEvents.Trial{trial}.Events, lickevent)
        if any(SessionData.RawEvents.Trial{trial}.Events.(lickevent)>=SessionData.RawEvents.Trial{trial}.States.Reward(1) ... 
       & SessionData.RawEvents.Trial{trial}.Events.(lickevent)<=SessionData.RawEvents.Trial{trial}.States.RewardConsumption(2))
        lw=3;
        end
    end
plot(SessionData.RawEvents.Trial{1,trial}.States.Reward - TrigStart(trial), [trial,trial], 'b', 'linewidth',lw);
plot(SessionData.RawEvents.Trial{1,trial}.States.RewardConsumption - TrigStart(trial), [trial,trial], 'b', 'linewidth',lw);
end
end
    
leg(3) = plot( NaN, NaN, 'b');

for trial=trials
if isfield(SessionData.RawEvents.Trial{1,trial}.States,'AnswerPeriod')
plot(SessionData.RawEvents.Trial{1,trial}.States.AnswerPeriod - TrigStart(trial), [trial,trial], 'g');
end
end
leg(4) = plot( NaN, NaN, 'g');

% licks
for trial=trials
if isfield( SessionData.RawEvents.Trial{1,trial}.Events, lickevent), 
    licks = SessionData.RawEvents.Trial{1,trial}.Events.(lickevent) - TrigStart(trial); 
    scatter(licks, ones(size(licks))*trial, 20,'r','filled');
end
end



legend( leg, 'Licks', 'SamplePeriod', 'Reward and consumption', 'Answer Period');


xlim([-1, 6] );


end