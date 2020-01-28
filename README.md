# Ultratnk

FPGA implementation by james10952001 of [Ultratank](https://github.com/james10952001/UltraTank) arcade game released by Kee Games in 1976

Port to MiSTer by Aitor Pelaez (NeuroRulez)
Uses the Top level .sv of sprint2 created by Alan Steremberg, i'm learning the MiSTer framework.

The original Ultratank has 2 levers and one button for player to control. This version implemente one Joystick for player.
The original Ultratank was B&W, but has three signal of colors form the image generation (rgb?) who never used.
I generate the colors from that tree signals mixing it in rgb form. You can select it in OSD.

There are 3 modes to change the gameplay in the OSD:

Visible or invisible tanks (Only make visible when fire)

Rebouncing fire or Remote control Fire

Barriers or open field.

# Keyboard inputs :
```
	5  Insert Coin
	1  Start Player 1
	2  Start Player 2
	
 Joystick support. 
```
 
# ROMs
```
                                *** Attention ***

ROM is not included. In order to use this arcade, you need to provide a correct ROM file.

Find this zip file somewhere. You need to find the file exactly as required.
Do not rename other zip files even if they also represent the same game - they are not compatible!
The name of zip is taken from M.A.M.E. project, so you can get more info about
hashes and contained files there.

To generate the ROM using Windows:
1) Copy the zip into "releases" directory
2) Execute bat file - it will show the name of zip file containing required files.
3) Put required zip into the same directory and execute the bat again.
4) If everything will go without errors or warnings, then you will get the a.*.rom file.
5) Copy generated a.*.rom into root of SD card along with the Arcade-*.rbf file

To generate the ROM using Linux/MacOS:
1) Copy the zip into "releases" directory
2) Execute build_rom.sh
3) Copy generated a.*.rom into root of SD card along with the Arcade-*.rbf file

To generate the ROM using MiSTer:
1) scp "releases" directory along with the zip file onto MiSTer:/media/fat/
2) Using OSD execute build_rom.sh
3) Copy generated a.*.rom into root of SD card along with the Arcade-*.rbf file
```
