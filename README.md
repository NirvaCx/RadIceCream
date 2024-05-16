# RadIceCream
RISC-V Assembly project for Introduction to Computer Systems class at University of Brasilia<br>
Created by Nirva Neves, Rodrigo Rafik and Mariana Simion<br>
Inspired by BadIceCream by Nitrome<br>
## Note for future students
This is important to anyone who's interested in the game's development process in general - The compressed release files DO NOT CONTAIN everything that's used for development and a lot of it is omitted. If you want to have a full look, always download the source of that specific release. Older releases that were not uploaded to github are in the Project Archive linked at the end of this Readme

If you want to take a look at the latest version, don't download the latest release source - instead just clone or download the main branch as we've added some documentation since the latest release.

And finally, if you have any specific questions, feel free to ask me personally at my e-mail: nive.yellow@gmail.com

## How to run (Latest Versions)

Please note that the information below is for Windows and Linux. You should check out FPGRARS' GitHub repository if you're on MacOS so that you can run the game in your system: https://github.com/LeoRiether/FPGRARS

### For Windows

Open terminal from the game directory and type in the following:
```
./fpgrars-windows.exe main.s
```

### For Linux

**LINUX USERS SHOULD DOWNLOAD THE CODE OR CLONE THE REPOSITORY**

Open terminal from the game directory and run:
```
./fpgrars-linux main.s
```
Notes: FPGRARS' MIDI is tricky on linux, and it's suggested you configure a MIDI daemon for your system. See https://wiki.archlinux.org/title/MIDI#Software_playback .

Selection of the MIDI port on FPGRARS is done with the flag `--port x` where `x` is the cardinal port number (0, 1, 2, 3).

## How to run (Versions Prior to 1.1.0)
Important note about versions prior to 1.1.0: They WILL crash after running for a certain amount of time due to an imperfection in the version of FPGRARS we used for those earlier versions. Replacing the old fpgrars version in the folder with the one used in 1.1.0 should absolutely fix this problem :)

Open terminal from the game directory and type in the following:
```
./fpgrars-x86_64-pc-windows-msvc--unb.exe main.s
```
Or run the executable .bat file which does the above for you automatically

Make sure you have the latest Microsoft Visual C++ Redist installed on your computer as FPGRARS depends on it<br>
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170 <br>

## Project Article
See RadIceCream_Article.pdf in source

## Project Archive
Earlier versions, funny placeholder images, development videos, and all sorts of other fun things.<br>
https://drive.google.com/drive/folders/1qve_bUNcumaPKPH73_zFgW3DIwvwJ50J?usp=sharing
