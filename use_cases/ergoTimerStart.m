function ergoTimerStart(mTimer,~)
secondsPerMinute = 60;
secondsPerHour = 60*secondsPerMinute;
str1 = 'Starting Ergonomic Break Timer.  ';
str2 = sprintf('For the next %d hours you will be notified',...
    round(mTimer.TasksToExecute*(mTimer.Period)/secondsPerHour));
str3 = sprintf(' to take a  second break every %d minutes.',...
    (mTimer.Period/secondsPerMinute));
disp([str1 str2 str3])
end