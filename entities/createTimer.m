function t = createTimer()
secondsInterval = 60;
secondsPerHour = 60^2;
secondsWorkTime = 24*secondsPerHour;

t = timer;
t.TimerFcn = @takeAction;
t.StopFcn = @timerCleanup;
t.Period = secondsInterval;
t.StartDelay = t.Period;
t.TasksToExecute = ceil(secondsWorkTime/t.Period);
t.ExecutionMode = 'fixedSpacing';
end 