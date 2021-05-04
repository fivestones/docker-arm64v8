# docker-arm64v8
FileRun Docker image for ARM 64bit (e.g. Rpi 4)

Tested just enough to see that it runs, on a Rpi 4 with 8 GB RAM.

Do a git clone of this repository
Then run ./build.sh

That will make you a docker image which you can use on the rpi to set up filerun.

Apparently, as of May 4, 2021, the makers of filerun plan to release a docker version for Rpi with the latest version of filerun "soon/in a couple of weeks" (https://www.reddit.com/r/FileRun/comments/n2gvis/raspberry_piarm_no_longer_being_maintained/), but in the meantime, feel free to use this one, at your own risk. I recommend checking the original filerun repository I forked this from to see what changes I made, almost all of which were in the dockerfile file.
