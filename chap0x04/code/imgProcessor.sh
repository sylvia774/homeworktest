#!/usr/bin/env bash

check_dependencies(){
    if [[ -z "$(convert -v 2>/dev/null)" ]];then
        echo "还没安装 ImageMagick"
    fi
}

Help() {
    cat << EOF
    Usage:
        bash $0 [-q <dir> <Q>] [-r <dir> <R>] [-w <dir> <content> <position> <size>] 
                [-p <dir> <prefix>] [-s <dir> <suffix>] [-t <dir>] 
    
    Options:
        -q Q          将jpeg格式图片的图片质量压缩为Q
        -r R         维持原始长宽比的前提下压缩jpeg/png/svg格式图片分辨率为R   
        -w content    对图片批量添加自定义文本水印
        -p prefix     对文件名加前缀
        -s suffix     对文件名加后缀
        -t            将png/svg格式图片转换为jpg格式图片
        -h            显示帮助信息
    
EOF
}

# 对jpeg格式图片进行图片质量压缩
CompressQuality(){
    Q=$2    
    for jpg in "$1"/* ;do  
        mgk_num=$(xxd  -p  -l  3  "$jpg" )
        if [[ "$mgk_num" == "ffd8ff" ]]; then
            convert -strip -interlace Plane -gaussian-blur 0.01 -quality "$Q" "$jpg" "$jpg"
            echo Quality of "${jpg}" is compressed into "$Q" 
        else
            echo "warn: $jpg is not a jpeg image "
        fi
    done
    exit 0 
}

# 对jpeg/png/svg格式图片在保持原始宽高比的前提下压缩分辨率
CompressResolution(){
    R=$2
    for img in "$1"/* ;do
        mgk_num=$(xxd  -p  -l  3  "$img" )
        suffix=${img##*.}
        if [[ "$mgk_num" == "ffd8ff" || "$mgk_num" == "89504e" ]]; then
            convert -resize "$R%" "$img" "$img"
            echo Resolution of "${img}" is resized into "$R%"
        elif [[ "$suffix" == "svg" || "$suffix" == "SVG" ]]; then
            r=$(echo "scale=2;$R/100"|bc)
            rsvg-convert -a -z "$r" -f svg "$img" -o "$1"/new.svg
            echo Resolution of "${img}" is resized into "$R%"
        else
            echo "warn: $img is not a jpeg/png/svg image"
        fi
    done
    exit 0
}

# 对图片批量添加自定义文本水印
WaterMark(){
    content=$2
    position=$3
    size=$4
    for img in "$1"/* ;do
        convert "${img}" -pointsize "$size" -fill 'rgba(221, 34, 17, 0.25)' -gravity "$position" -draw "text 10,10 '$content'" "${img}"
        echo "${img} is watermarked with $content."
    done
    
    exit 0
}

#添加文件名前缀
Prefix(){
    prefix=$2
    for img in "$1"/*; do
        name=${img##*/}
        new_name=$1"/"${prefix}${name}
        mv "${img}" "${new_name}"
        echo "${img} is renamed to ${new_name}"
    done
    exit 0
}

#添加文件名后缀
Suffix(){
    suffix=$2
    for img in "$1"/*; do
        type=${img##*.}
        new_name=${img%.*}${suffix}"."${type}
        mv "${img}" "${new_name}"
        echo "${img} is renamed to ${new_name}"
    done
    exit 0
}

# 将png/svg图片统一转换为jpg格式图片
Transform(){
    for img in "$1"/* ;do
        format="$(identify -format "%m" "$img")"
        suffix=${img##*.}
        if [[ "$format" == "PNG" || "$format" == "SVG" ]]; then
            new_img=${img%.*}".jpg"
            convert "${img}" "$new_img"
            echo "${img}" has transformed into "$new_img"
        fi
    done
    exit 0
}


[ $# -eq 0 ] && Help
while getopts 'q:r:w:p:s:t:h' OPT; do
    case $OPT in
        q)  
            CompressQuality "$2" "$3"
            ;;
        r)
            CompressResolution "$2" "$3"
            ;;
        w)  
            WaterMark "$2" "$3" "$4" "$5" "$6"
            ;;
        p)
            Prefix "$2" "$3"
            ;;
        s)
            Suffix "$2" "$3"
            ;;
        t)
            Transform "$2"
            ;;
        h | *) 
            Help
            ;;

    esac
done
check_dependencies