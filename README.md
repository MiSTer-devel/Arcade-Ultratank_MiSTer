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

ROMs are not included. In order to use this arcade, you need to provide the
correct ROMs.

To simplify the process .mra files are provided in the releases folder, that
specifies the required ROMs with checksums. The ROMs .zip filename refers to the
corresponding file of the M.A.M.E. project.

Please refer to https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms for
information on how to setup and use the environment.

Quickreference for folders and file placement:

/_Arcade/<game name>.mra
/_Arcade/cores/<game rbf>.rbf
/_Arcade/mame/<mame rom>.zip
/_Arcade/hbmame/<hbmame rom>.zip

```
