****************************************************************************** 
****************************************************************************** 

#Myth > Handbrake (H.264) > Plex Script++ for MythTV

****************************************************************************** 
****************************************************************************** 

  Pre-requisites: 
     * HandBrakeCLI
     * Filebot (portable edition)
     * Sickbeard w/sabtoSickBeard.py


  Usage: 
     'mythtoplex.sh %DIR% %FILE% %CHANID% %STARTTIME% "%TITLE%" "%SUBTITLE%"'

  Description:
      My script is currently pretty simple.  Here's the general flow:

      1. Creates a temporary directory under your recordings directory for 
      the show it is about to transcode.

      2. Uses Handbrake (could be modified to use ffmpeg or other transcoder, 
      but I chose this out of simplicity) to transcode the original, very 
      large MPEG2 format file to a smaller, more manageable H.264 mp4 file 
      (which can be streamed to my Roku boxes).

      3. Uses Filebot to rename the file and add the season number and 
      episode number (sXXeXX).  I do this because it makes it much smoother 
      for the last step to occur without issues.

      4. Uses the Sickbeard script, sabtosickbeard.py, which is normally used
      by SabNZBd to organize your downloaded files into directories, and 
      notify Sickbeard / Plex of the new show.  This will also rename your 
      file... again.  You may be wondering why I use Filebot at all in step 3?
      Well, the Sickbeard script seems to do better at recognizing the file if 
      it already has a season number and episode number in the file name.  The
      script also cleans up for you by deleting the temporary folder after 
      it's moved the file.  	  
