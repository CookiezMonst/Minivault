# Minivault
Yes, i know it's was ChatGPT and sucks. But it worked.
The code was a script that use asusfancontrol.exe from [] to overwrite the default states of the fans.
Adding fan curves for efficient and make the fans more reliable (Though i was using it at 100% all times in the old 9 years-old machine but still dont have any problems, LOL :P)
##
Keys:
$highSpeedDuration = 30  # Duration to run high-speed fan in seconds (default: 30 seconds)
$cycleInterval = 600      # Interval for auto cycle in seconds (default:10 minutes)
$tempThreshold = 50       # CPU temperature threshold in degrees Celsius (for normal ramp-up; default: 50 degrees)
$criticalTempThreshold = 80  # Critical CPU temperature threshold (for immediate fan boost; default: 80 degrees)

Fan curve:
Base on my system i use this data, you can change it to whatever can applied best for your laptop.
Say X was the current RPM of fans when checking the speeds.
10= ~650 x<500rpm
20= ~1450 500<x<1300rpm
30= ~2050 1300<x<1800rpm
40= ~2650 1800<x<2500rpm
50= ~3150 2500<x<2900rpm
60= ~3550 2900<x<3400rpm
70= ~3990 3400<x<3800rpm
80= ~4430 3800<x<4300rpm
90= ~4750 4300<x<4900rpm
100= ~5050 x>4900rpm
