#!/bin/sh
set -e
FF=/c/Users/leven/tools_dl/ffmpeg-master-latest-win64-gpl/bin/ffmpeg.exe
G="eq=contrast=1.12:saturation=1.3:brightness=-0.03,unsharp=5:5:0.6"
ENC="-c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p -r 30 -an"
# 1) kanca: ağır çekim pembe tuğla patlaması (1.6 sn kaynak > 2.1 sn)
$FF -y -loglevel error -ss 20.5 -t 1.6 -i smashB.mkv -i ov_hook.png -filter_complex "[0]crop=1320:742:300:0,scale=1920:1080:flags=lanczos,$G,setpts=1.33*PTS,fps=30[v];[v][1]overlay[o]" -map "[o]" -t 2.1 $ENC s1.mp4
# 2) LVL 1 > LVL 200 (hafif yakınlaşma)
$FF -y -loglevel error -loop 1 -t 1.2 -i cmp_small.png -i ov_lvl1.png -filter_complex "[0]crop=1323:744:295:0,scale=1920:1080:flags=lanczos,$G,zoompan=z='1+0.0015*on':d=36:s=1920x1080:fps=30[v];[v][1]overlay[o]" -map "[o]" -t 1.2 $ENC s2.mp4
$FF -y -loglevel error -loop 1 -t 1.7 -i cmp_big.png -i ov_lvl200.png -filter_complex "[0]crop=1323:744:298:0,scale=1920:1080:flags=lanczos,$G,zoompan=z='1.06-0.0012*on':d=51:s=1920x1080:fps=30[v];[v][1]overlay[o]" -map "[o]" -t 1.7 $ENC s3.mp4
# 3) duvar serisi: altın > yakut, safir > zümrüt
$FF -y -loglevel error -ss 12.9 -t 1.7 -i smashB.mkv -i ov_walls.png -filter_complex "[0]crop=1320:742:592:0,scale=1920:1080:flags=lanczos,$G[v];[v][1]overlay[o]" -map "[o]" -t 1.7 $ENC s4.mp4
$FF -y -loglevel error -ss 27.7 -t 1.7 -i smashB.mkv -i ov_walls.png -filter_complex "[0]crop=1320:742:592:0,scale=1920:1080:flags=lanczos,$G[v];[v][1]overlay[o]" -map "[o]" -t 1.7 $ENC s5.mp4
# 4) yumurta: sallanma > kırılma > EPIC
$FF -y -loglevel error -ss 2.2 -t 3.4 -i hatch2.mkv -i ov_pets.png -filter_complex "[0]crop=1320:742:296:0,scale=1920:1080:flags=lanczos,$G[v];[v][1]overlay[o]" -map "[o]" -t 3.4 $ENC s6.mp4
# 5) kapanış kartı
$FF -y -loglevel error -loop 1 -t 3.2 -i endcard.png -filter_complex "[0]zoompan=z='1.08-0.0009*on':d=96:s=1920x1080:fps=30,fade=t=in:st=0:d=0.25[o]" -map "[o]" -t 3.2 $ENC s7.mp4
printf "file 's1.mp4'\nfile 's2.mp4'\nfile 's3.mp4'\nfile 's4.mp4'\nfile 's5.mp4'\nfile 's6.mp4'\nfile 's7.mp4'\n" > list.txt
$FF -y -loglevel error -f concat -safe 0 -i list.txt -c copy video_noaudio.mp4
D=$(/c/Users/leven/tools_dl/ffmpeg-master-latest-win64-gpl/bin/ffprobe.exe -v error -show_entries format=duration -of csv=p=0 video_noaudio.mp4)
echo "duration $D"
$FF -y -loglevel error -i video_noaudio.mp4 -i music.wav -filter_complex "[1]atrim=0:$D,afade=t=in:d=0.15,afade=t=out:st=$(awk "BEGIN{print $D-0.9}"):d=0.9,volume=0.9[a]" -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -shortest promo_15s.mp4
