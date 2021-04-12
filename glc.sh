rm -rf /tmp/pineapple
mkdir -p /tmp/pineapple && cd /tmp/pineapple
isolate () {
    sed "$(( COUNT + $1 ))q;d" matches.txt|sed 's/<[^>]*>//g'|sed 's/^[ \t]*//'|awk '{$1=$1};1'|tr -d '\n'
}
curl -s https://greeklivechannels.ml/livematches.html|sed -n '/<div class="match" >/,$p'| sed -n '/<center>/q;p'> matches.txt
echo "Νούμερο,Πρωτάθλημα,Ήχος,Ομάδες,Ώρα" >> matches.csv
NR=1
while read line; do
    COUNT=$(( $COUNT + 1 ))
    if [[ $line =~ match ]] ; then 
        CHAMPIONSHIP=$(isolate 1)
        AUDIO=$(isolate 2)
        TEAMS=$(isolate 5)
        TIME=$(isolate 9)
        if [ "$AUDIO" != "Ξένο" ] ; then
            echo "$NR,$CHAMPIONSHIP,$AUDIO,$TEAMS,$TIME,$COUNT" >> matches.csv
            NR=$(( $NR + 1 ))
        fi
    fi
done <matches.txt
COUNT=0
cat matches.csv|cut -d, -f6 --complement|sed 's/,/ ,/g'|column -t -s,
read -p "Διάλεξτε ένα νούμερο από το 1 μέχρι το $(($NR - 1)): " NOUMERO
if [ "$NOUMERO" -gt "$(($NR - 1))" ] || [ "$NOUMERO" -lt "1" ]  ; then
    echo "Λανθαμένη επιλογή"
    exit
else
    :
fi
CHOSEN=`sed "$(( NOUMERO + 1 ))q;d" matches.csv|sed 's/,/\n/g'|sed -n 6p`
TEAMS=`sed "$(( NOUMERO + 1 ))q;d" matches.csv|sed 's/,/\n/g'|sed -n 4p`
sed -i "1,${CHOSEN}d" matches.txt
awk 'NF { $1=$1; print }' matches.txt > links.txt
rm -rf matches.txt
mv links.txt matches.txt
rm -rf links.txt
sed -i ':a;N;$!ba;s#</div>\n</div>.*$##g' matches.txt
echo "#EXTM3U">playlist.m3u
while read line; do
    COUNT=$(( $COUNT + 1 ))
    LINKNO=1
    if [[ $line =~ b-t-n ]] ; then
        LINK=`sed "$(( COUNT + 4 ))q;d" matches.txt|cut -d'"' -f2|sed '1s#^#https://greeklivechannels.ml/#'`
        HLS=`curl -s $LINK|sed -e :a -re 's/<!--.*?-->//g;/<!--/N;//ba'|grep 'youtube\|m3u8'`
	if [[ $HLS =~ youtu ]] ; then
		HLSLINK=`echo $HLS|cut -d'"' -f6`
	else
		HLSLINK=`echo $HLS|cut -d'"' -f2`
	fi
	if [ -n "$HLSLINK" ] ; then
		echo "#EXTINF:-1,$TEAMS LINK$LINKNO">>playlist.m3u
		echo "$HLSLINK">>playlist.m3u
		LINKNO=$(( $LINKNO + 1 ))
	fi
    fi
done <matches.txt
mpv playlist.m3u
