function fig = plot_alltrial_events( SessionData, trials )

if nargin<2, trials = 1:length(SessionData.RawEvents.Trial); end

fig = figure; hold on;


leg(1) = scatter(NaN, NaN, 20, 'r', 'filled');


for trial=trials
plot(SessionData.RawEvents.Trial{1,trial}.States.SamplePeriod, [trial,trial], 'k');
end
leg(2) = plot( NaN, NaN, 'k');

for trial=trials
if isfield(SessionData.RawEvents.Trial{1,trial}.States,'Reward')
lw=1;
if isfield( SessionData.RawEvents.Trial{trial}.Events, 'Port1In')
    if any(SessionData.RawEvents.Trial{trial}.Events.Port1In>=SessionData.RawEvents.Trial{trial}.States.Reward(1) ... 
   & SessionData.RawEvents.Trial{trial}.Events.Port1In<=SessionData.RawEvents.Trial{trial}.States.RewardConsumption(2))
    lw=3;
    end
end

plot(SessionData.RawEvents.Trial{1,trial}.States.Reward, [trial,trial], 'b', 'linewidth',lw);
plot(SessionData.RawEvents.Trial{1,trial}.States.RewardConsumption, [trial,trial], 'b', 'linewidth',lw);
end
end
leg(3) = plot( NaN, NaN, 'b');

for trial=trials
if isfield(SessionData.RawEvents.Trial{1,trial}.States,'AnswerPeriod')
plot(SessionData.RawEvents.Trial{1,trial}.States.AnswerPeriod, [trial,trial], 'g');
end
end
leg(4) = plot( NaN, NaN, 'g');

% licks - should be on top
for trial=trials
if isfield( SessionData.RawEvents.Trial{1,trial}.Events, 'Port1In'), licks = SessionData.RawEvents.Trial{1,trial}.Events.Port1In; 
scatter(licks, ones(size(licks))*trial, 20,'r','filled');
end
end


legend( leg, 'Licks', 'SamplePeriod', 'Reward and consumption', 'Answer Period');

end