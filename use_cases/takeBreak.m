function takeBreak(mTimer,~)
import java.awt.*;
import java.awt.event.*;
%Create a Robot-object to do the key-pressing
rob=Robot;
%Commands for pressing keys:
rob.keyPress(KeyEvent.VK_A);
rob.keyRelease(KeyEvent.VK_A);
end