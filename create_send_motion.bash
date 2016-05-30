#!/bin/bash
# script makes video file out of jpg images and uploads the video file to a ftp server
# created by Floris van den Berg < info at linip dot nl >

DATE=$(date +%Y%m%d)
YESTERDAY=$(date -d '1 day ago' +%Y%m%d)
FTPUSER="someuser"
FTPPASSWORD="somepassword"
FTPPORT="21"
FTPSERVER="ftp.someserver.com"
PROJECTFOLDER="somefolder"

start_time=`date +%s`
rm -f /tmp/*
if [ ! -d /motion/$YESTERDAY/camera-1/motions ]; then 
	mkdir -p /motion/$YESTERDAY/camera-1/motions/dummy
else 
	cd /motion/$YESTERDAY/camera-1/motions
	mkdir dummy
fi

cp /$PROJECTFOLDER/dummy.jpg /motion/$YESTERDAY/camera-1/motions/dummy/dummy1.jpg
cp /$PROJECTFOLDER/dummy.jpg /motion/$YESTERDAY/camera-1/motions/dummy/dummy2.jpg

y=0
cd /motion/$YESTERDAY/camera-1/motions/

for dir in $( ls -d -1 -tr $PWD/** )
do
	time_now=`date +%s`
	elapsed_time=`expr $time_now - $start_time`
	if [ $elapsed_time -lt 72000 ]; then
		x=0; for i in $(ls -r -t `find $dir -name *jpg`); do counter=$(printf %05d $x); ln -s "$i" /tmp/img"$counter".jpg; x=$(($x+1)); done
		avconv -f image2 -i /tmp/img%05d.jpg -r 12 -s 640x480 -vcodec libx264 /tmp/daily_$YESTERDAY$y.pics.avi
		rm /tmp/*jpg
		y=$(($y+1))
	fi

done

y=0
cd /motion/$DATE/camera-1/motions/ 
for dir in $( ls -d -1 -tr $PWD/** )
do
	time_now2=`date +%s`
        elapsed_time=`expr $time_now2 - $start_time`

	if [ $elapsed_time -lt 72000 ]; then 
		if [[ "$y" < 3 ]]; then
			x=0; for i in $(ls -r -t `find $dir -name *jpg`); do counter=$(printf %05d $x); ln -s "$i" /tmp/img"$counter".jpg; x=$(($x+1)); done
			avconv -f image2 -i /tmp/img%05d.jpg -r 12 -s 640x480 -vcodec libx264 /tmp/daily_$DATE$y.pics.avi
			rm /tmp/*jpg
			y=$(($y+1))
		fi
	fi

done
cd /tmp
arr=( $(ls -tr /tmp/*avi) )
cat ${arr[@]} > all_$DATE.avi
avconv -i all_$DATE.avi -acodec copy -vcodec copy daily_$DATE.pics.avi
rm all_$DATE.avi
rm /tmp/*avi

wput --binary daily_$DATE.pics.avi ftp://$FTPUSER:$FTPPASSWORD@$FTPSERVER:$FTPPORT/$PROJECTFOLDER/
OUT=$?
if [ "$OUT" = "0" ];then
   echo "Upload succesfull"
   rm daily_$DATE.pics.avi

else
   echo "Upload failed"
   mv daily_$DATE.pics.avi /buffer
fi
 

cd /motion
rm -rf $YESTERDAY
