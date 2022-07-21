function t = createErgoTimer()
secondsBreakInterval = 30;
secondsPerHour = 60^2;
secondsWorkTime = 8*secondsPerHour;

t = timer;
t.StartFcn = @ergoTimerStart;
t.TimerFcn = @takeBreak;
t.StopFcn = @ergoTimerCleanup;
t.Period = secondsBreakInterval;
t.StartDelay = t.Period;
t.TasksToExecute = ceil(secondsWorkTime/t.Period);
t.ExecutionMode = 'fixedSpacing';
end 