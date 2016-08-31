#!/bin/sh

#****************************************************************************** 
#****************************************************************************** 
#
#             Myth > Handbrake (H.264) > Plex Script++ for MythTV
#
#****************************************************************************** 
#****************************************************************************** 
#  
#  Version: 1.0
#
#  Pre-requisites: 
#     HandBrakeCLI
#     Filebot (portable edition)
#     Sickbeard w/sabtoSickBeard.py
#
#
#  Usage: 
#     'mythtoplex.sh %DIR% %FILE% %CHANID% %STARTTIME% "%TITLE%" "%SUBTITLE%"'
#
#  Description:
#      My script is currently pretty simple.  Here's the general flow:
#
#      1. Creates a temporary directory under your recordings directory for 
#      the show it is about to transcode.
#
#      2. Uses Handbrake (could be modified to use ffmpeg or other transcoder, 
#      but I chose this out of simplicity) to transcode the original, very 
#      large MPEG2 format file to a smaller, more manageable H.264 mp4 file 
#      (which can be streamed to my Roku boxes).
#
#      3. Uses Filebot to rename the file and add the season number and 
#      episode number (sXXeXX).  I do this because it makes it much smoother 
#      for the last step to occur without issues.
#
#      4. Uses the Sickbeard script, sabtosickbeard.py, which is normally used
#      by SabNZBd to organize your downloaded files into directories, and 
#      notify Sickbeard / Plex of the new show.  This will also rename your 
#      file... again.  You may be wondering why I use Filebot at all in step 3?
#      Well, the Sickbeard script seems to do better at recognizing the file if 
#      it already has a season number and episode number in the file name.  The
#      script also cleans up for you by deleting the temporary folder after 
#      it's moved the file.  	  
#
#****************************************************************************** 

#****************************************************************************** 
#  Edit the following for your system
#****************************************************************************** 

TEMPDIR="/mnt/dionysus/mythtv/recordings/tmp"		# Temporary directory for transcoding
SBSPATH="/home/parmeter/sickbeard/autoProcessTV"  	# Path to sabToSickBeard.py
FBPATH="/home/parmeter/filebot"				# Path to filebot.sh (from portable edition)
SED="/bin/sed"	# Path to sed (Stream Editor)

#****************************************************************************** 
#  Do not edit below this line
#****************************************************************************** 

VIDEODIR=$1 	# %DIR% - Directory name of original file
FILENAME=$2 	# %FILE% - Filename of original file
CHAN=$3 	# %CHANID% - Channel ID for the recorded program - Reserved for future use
START=$4 	# %STARTTIME% - Start time of the recorded program - Reserved for future use
TITLE=$5 	# %TITLE% - Program Title
SUBTITLE=$6 	# %SUBTITLE% - Program Subtitle

AIRDATE=$(date +"%Y.%m.%d")

MYPID=$$	# Process ID for current script

echo "********************************************************"
echo "********************************************************"
echo "         MythTV to Plex > Transcode and Organize" 
echo "********************************************************"
echo "********************************************************"

# Adjust niceness of CPU priority for the current process
renice 19 $MYPID

# Convert space laden variables to have underscores instead (not used in lookup)
sed_str="s/[$\!@\/:;~#%^&*\`\(\)\"\'<>,.?]//g"
OTITLE=`echo $TITLE | $SED -e 's/[[ \t]]*/_/g' | $SED -e $sed_str`
OSUBTITLE=`echo $SUBTITLE | $SED -e 's/[[ \t]]*/_/g' | $SED -e $sed_str`
OUTFILEA="$OTITLE-$OSUBTITLE.mpg"
OUTFILEB="$OTITLE-$OSUBTITLE-$AIRDATE.mp4" 

# Make temporary directory TEMPDIR/OTITLE
mkdir $TEMPDIR/$OTITLE

echo "********************************************************"
echo "Flagging Commercials with mythcommflag"
echo "********************************************************"
#mythcommflag --chanid $CHAN --starttime $START

echo "********************************************************"
echo "Generating cutlist with mythutil"
echo "********************************************************"
#mythutil --gencutlist --chanid $CHAN --starttime $START

echo "********************************************************"
echo "Transcoding, Removing Commercials w/mythtranscode"
echo "********************************************************"
#mythtranscode --honorcutlist --showprogress -i $VIDEODIR/$FILENAME -o $TEMPDIR/$OTITLE/$OUTFILEA

echo "********************************************************"
echo "Transcoding, Converting to H.264 w/Handbrake"
echo "********************************************************"
#HandBrakeCLI -i "$TEMPDIR/$OTITLE/$OUTFILEA" -o "$TEMPDIR/$OTITLE/$OUTFILEB" -e X264 -q 20 -a 1 -E copy:aac -B 160 -6 dp12 -R Auto -D0.0 --audio-copy-mask aac --audio-fallback faac -f mp4 --loose-anamorphic --modulus 2 -m --x264-preset veryfast --h264-profile baseline --h264-level 4.0
HandBrakeCLI -i "$VIDEODIR/$FILENAME" -o "$TEMPDIR/$OTITLE/$OUTFILEB" -e X264 -q 20 -a 1 -E copy:aac -B 160 -6 dp12 -R Auto -D0.0 --audio-copy-mask aac --audio-fallback faac -f mp4 --loose-anamorphic --modulus 2 -m --x264-preset veryfast --h264-profile auto --h264-level 4.0 --maxHeight 720

echo "********************************************************"
echo "Cleaning up first pass transcoded file $OUTFILEA"
echo "********************************************************"
#rm -f $TEMPDIR/$OTITLE/$OUTFILEA

# First Pass: FileBot
echo "********************************************************"
echo "Rename with FileBot... $OUTFILE"
echo "********************************************************"
# Set permissions so post-processing doesn't fail (ymmv)
chmod -R 777 $TEMPDIR/$OTITLE/
# Filebot may fail if permissions aren't set correctly.  
# 1. Make sure Filebot is executable by the mythtv user
# 2. Make sure Filebot's cache folder permissions are writable by the mythtv user
if [ $OTITLE = "iZombie" ]
then
$FBPATH/./filebot.sh -rename "$TEMPDIR/$OTITLE/$OUTFILEB" --q "iZombie" --format "{n}.{s00e00}.{t}" --db TheTVDB -non-strict
else 
$FBPATH/./filebot.sh -rename "$TEMPDIR/$OTITLE/$OUTFILEB" --format "{n}.{s00e00}.{t}" --db TheTVDB -non-strict
fi

# Second Pass: SickBeard
echo "********************************************************"
echo "Sending to SickBeard for proper organization w/Plex"
echo "********************************************************"
# Execute script on the temporary directory
# This script may fail if permissions aren't set correctly
# 1. Make sure this script is executable by the mythtv user
# 2. Make sure that the source and destination folders are writable by the sickbeard script owner/user
chmod -R 777 $TEMPDIR/
python $SBSPATH/sabToSickBeard.py $TEMPDIR/$OTITLE/

echo "Done.  Congrats!"
