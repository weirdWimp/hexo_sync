#!/bin/bash
#
# author: guo
# date: 2020-05-31
# description: a automatic way to update hexo post, steps:
# 1. copy local directories containing markdown files to hexo source path
# 2. add front-matter before every hexo post
# 3. run hexo commands to deploy
#
# hexo front-matter is used to classify the posts in hexo, format:
#   ---
#   title: ls Invalid option
#   date: 2020/05/30 22:21:59
#   categories:
#   - Linux
#   tags:
#   - Linux
#   ---
# use the direct directory name containing md files as categories and tags value
# use the file modification time as date value
#

function log() {
    echo "[$(date +"%F %T")]: $@"
}

function convertUrl() {

    mdPath=$1
    picPath=$2

    # convert 'F:\shell_tool\a.png' to '/mnt/f/shell_tool/png'
    tempPath=$(echo -n "$picPath" | tr '\\' '/' | tr -d ':')
    tempPath=$(echo -ne "${tempPath}" | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//')

    linuxPicPath="/mnt/"$(echo -n ${tempPath,})

    if [ ! -f "$linuxPicPath" ]; then
        return
    fi

    echo -e "\n\n"
    echo -e "[Linux Pic Path]:\t"$linuxPicPath

    # to match string F:\\shell_tool\\a.png, literal text '\' not escape
    # delete \r \n, it fucks me a lot of time !!!!!!!
    matchPath=$(echo -n "$picPath" | sed 's/\\/\\\\/g' | tr -d '\r' | tr -d '\n')

    key=$(echo -n $linuxPicPath | base64)
    setRes=$(redis-cli setnx $key 1)

    echo -e "[Redis Set]\t\t" $setRes
    if (($setRes == 0)); then
        picName=${linuxPicPath##*/}
        buildBedPicPath="https://raw.githubusercontent.com/weirdWimp/blog-store/main/img/"$picName

        echo -e "[ReBedPicPath]:\t\t"$buildBedPicPath
        echo "[Match Path]          $matchPath "

        eval sed -i 's#${matchPath}#${buildBedPicPath}#' '$mdPath'
        # cat $mdPath | grep -P '.png'
    else
        upRes=$(picgo u $linuxPicPath)
        if [[ "$upRes" = *SUCCESS* ]]; then
            picBedUrl=${upRes##*SUCCESS]:}
            picBedUrl=$(echo $picBedUrl | tr -d '[:space:]')
            echo -e "[PicBed Path]\t\t"$picBedUrl
            eval sed -i 's#${matchPath}#${picBedUrl}#' '$mdPath'
        fi
    fi
}

## function to add add front-matter
function addHeader() {
    dir=$1
    oldIFS=$IFS
    IFS=$(echo -ne "\x1c")
    for path in $(find $dir -type f -name "*.md" -exec printf {}"\x1c" \;); do
        file=${path##*/}
        title=${file%.*}
        crtdat=$(ls -l --time-style=+"%Y/%m/%d %T" $path | cut -d " " -f 6-7)
        categories=${dir##*/}
        tags=$categories
        head="---\ntitle: $title\ndate: $crtdat\ncategories:\n- $categories\ntags:\n- $tags\n---\n\n\n"
        sed -i "1i$head" $path

        pics=$(cat $path | grep -P '!\[.*\]\(.*\)' | sed -E 's/!\[.*\]\((.*)\)/\1/' | tr '\n' '\034')
        if [ -z "$pics" ]; then
            continue
        fi

        # echo "pictures:###"$pics"==="
        for pic in $pics; do
            convertUrl $path $pic
        done

        # sleep 1s
    done
    IFS=$oldIFS
}

filepath="/mnt/f/shell_tool/hexo_sync/sync.config"
basedir="/mnt/f/md-blog/weirdWimp.github.io"
postdir="/mnt/f/md-blog/weirdWimp.github.io/source/_posts"
while read line; do
    if [[ "$line" =~ ^\# ]]; then
        continue
    fi

    if [ -d "$line" ]; then
        # echo "$line exists"
        dirnam=${line##*/}
        targetDir="$postdir/$dirnam"
        if [ -d "$targetDir" ]; then
            # echo "deleting $targetDir"
            sudo rm -rf "$targetDir"
        fi
        mkdir -p "$targetDir"
        cp -r -p "$line" "$postdir"
        addHeader "$targetDir"
    fi
done <$filepath

# ```shell mark to ```bash
find "$postdir" -type f -name "*.md" -print0 | xargs -0 -n 1 sed -i -E 's/^[^`]*`{3,}sh(ell)?/```bash/'
find "$postdir" -type f -name "*.md" -print0 | xargs -0 -n 1 sed -i -E 's/^[^`]*`{3,}/```/g'

find "$postdir" -type f -name "*.png" -print0 | xargs -0 -n 1 sed -i -E 's/^[^`]*`{3,}/```/g'

cd $basedir || exit 1

log "start to clean..." >>"/mnt/f/shell_tool/hexo_sync/run_date.log"
/usr/local/bin/hexo clean

log "start to generate..." >>"/mnt/f/shell_tool/hexo_sync/run_date.log"
/usr/local/bin/hexo generate

log "start to deploy remote..." >>"/mnt/f/shell_tool/hexo_sync/run_date.log"
/usr/local/bin/hexo deploy

echo -e "\n" >>"/mnt/f/shell_tool/hexo_sync/run_date.log"
