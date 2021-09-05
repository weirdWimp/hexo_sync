#!/usr/bin/env bash


function convertUrl() {

mdPath=$1
picPath=$2

# convert 'F:\shell_tool\a.png' to '/mnt/f/shell_tool/png'
tempPath=$(echo -n "$picPath" | tr '\\' '/' | tr -d ':')
linuxPicPath="/mnt/"$(echo -n ${tempPath,})
echo $linuxPicPath

# to match string F:\\shell_tool\\a.png, literal text '\' not escape
matchPath=$(echo -n "$picPath" | sed 's/\\/\\\\/g')
echo $matchPath

upRes=$(picgo u $linuxPicPath)

if [[ "$upRes" = *SUCCESS* ]]; then
    picBedUrl=${upRes##*SUCCESS]:}
    picBedUrl=$(echo $picBedUrl | tr -d '\n')
    echo $picBedUrl

    eval sed 's#${matchPath}#${picBedUrl}#' $mdPath
fi
}



pics=($(cat $mdPath | grep -P '!\[.*\]\(.*\)' | sed -E 's/!\[.*\]\((.*)\)/\1/' | | tr '\n' '\034'))
for pic in $pics; do
    echo
done

trimmed=`echo -e "${var}" |  sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'`
trimmed=`echo -e "${var}" | sed -e 's/^[[:space:]]*//'`


trimmed=`echo -e "${var}" |  sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//'`

cat -n text | sed -En -e '
  1 { N;N;N;N }     # ensure the pattern space contains *five* lines

  N                 # append a sixth line onto the queue
  P                 # Print the head of the queue
  D                 # Remove the head of the queue
'