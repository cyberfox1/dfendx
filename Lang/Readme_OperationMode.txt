DFendX knows 3 operation modes:

1.) D-Fend style:
Configuration data is stored in subdirectories of the DFendX program folder
(like D-Fend does). This works fine under XP if you are Admin. Unter Vista you will have problems.

2.) User directory style:
DFendX will use your personal data folder for settings (under Vista "C:\Users\<YourName>\DFendX\").
This is the most recommended operation mode.

3.) Portable mode:
Like 1.) but additionally the DOSBox directory, the games directory, the games data directory, the ScummVM directory, the path to QBasic, the wave->ogg and the wave->mp3 encoder will be stored relative to the program folder so you can
use DFendX from any drive.


To manually setup the operation mode you have to change the "DFend.dat" in the DFendX program folder.
The "DFend.dat" is a text file which should contain exactly one of the following lines:

PRGDIRMODE
USERDIRMODE
PORTABLEMODE

"PRGDIRMODE" is for operation mode 1, "USERDIRMODE" for operation mode 2 and "PORTABLEMODE" for operation mode 3.

If you have used the installer to install DFendX there ist no need to change the operation mode.