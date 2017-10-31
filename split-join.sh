#!/bin/bash
#

while getopts ":a:x:q:w:e:" o; do
    case "${o}" in
        a)
            a=${OPTARG}
            ;;
        x)
            x=${OPTARG}
            ;;
        q)
            q=${OPTARG}
            ;;
        w)
            w=${OPTARG}
            ;;
        e)
            e=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))


AUDIO=${a}
EXT=${x}
DURMIN=${q}
DURMAX=${w}
OUTFILE=${e}

echo $AUDIO
echo $EXT
echo $DURMIN
echo $DURMAX
echo $OUTFILE

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
FILES=$(ls *.$EXT|sort)
outFiles=()

for FILE in $FILES
do
    let START=0
    echo Processing $FILE
    mkdir "${FILE}-chop"
    for COUNT in {1..40}
    do
        outFile="${FILE}-chop/${COUNT} - ${FILE}"
        dur=$(( ( RANDOM % $DURMAX-$DURMIN )  + $DURMIN ))
        ffmpeg -i "${FILE}" -ss $START -t $dur -c:v copy -c:a copy -y "$outFile"
        SIZE=exec wc -c "$outFile" | awk '{print $1}' | bc
        echo $SIZE
        minimumsize=20000
        actualsize=$(wc -c <"$outFile")
        if [ $actualsize -ge $minimumsize ]; then
            echo size is over $minimumsize bytes
            outFiles+=("$outFile")
        else
            echo size is under $minimumsize bytes
            rm "$outFile"
        fi
        let START=$START+$dur
    done
done

shuffle() {
   local i tmp size max rand

   # $RANDOM % (i+1) is biased because of the limited range of $RANDOM
   # Compensate by using a range which is a multiple of the outFiles size.
   size=${#outFiles[*]}
   max=$(( 32768 / size * size ))

   for ((i=size-1; i>0; i--)); do
      while (( (rand=$RANDOM) >= max )); do :; done
      rand=$(( rand % (i+1) ))
      tmp=${outFiles[i]} outFiles[i]=${outFiles[rand]} outFiles[rand]=$tmp
   done
}

shuffle

echo "${outFiles[*]}"

for j in "${outFiles[@]}"
do
      echo file \'"$j"\'
done >tmp.txt

tmpo="$OUTFILE tmp"

ffmpeg -safe 0 -f concat -i tmp.txt -f mp4 -y $tmpo.mp4
ffmpeg -i $tmpo.mp4 -i $AUDIO -c:a aac -c:v copy -y -shortest $OUTFILE.mp4
rm $tmpo.mp4
rm tmp.txt

IFS=$SAVEIFS