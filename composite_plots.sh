#!/bin/bash

script=$(basename "$0" .${0##*.})

default_configuration="remove_intermediate_files=true
delimiter=-

# Align the scanned images.
control_points=32

# Make the aligned images monochromatic.
monochrome_options='-gamma 0.45455'

# Trim the composited image.
trim=true
deskew=40%
fuzz=80%

# Define tick marks.
draw_tick=true
tick_interval_mm=10
tick_length_mm=2
tick_width_mm=0.25
tick_color=DimGray

# Define plot legends.
gravity=SouthEast
font=Cantarell-Regular
pointsize=36
stroke=white
strokewidth=8
color=(red green blue DarkOrange)

annotate[0]='Series 1'
annotate[1]='Series 2'
annotate[2]='Series 3'
annotate[3]='Series 4'"

. configuration.sh initialize || exit

# Check the input files.
if [ $# == 0 ] || [[ $1 =~ ^- ]] || [ $# -lt 2 -o $# -gt ${#color[*]} ]; then
    echo Usage: ${0##*/} [option] input_1 input_2 [... input_${#color[*]}] >&2
    exit 2
elif [ ! -w . ]; then
    echo Current directory is not writable >&2
    exit 1
else
    number=0
    for path in "$@"; do
        if canonical_path=$(readlink -e "$path"); then
            input=("${input[@]}" "$canonical_path")
            eval $(identify \
                       -format \
                       'x_density[number]=%x y_density[number]=%y' \
                       "$canonical_path" || echo exit $?)
            if [ "${x_density[number]}" \
                     != "${previous_x_density:-${x_density[0]}}" \
                     -o "${y_density[number]}" \
                     != "${previous_y_density:-${y_density[0]}}" ]; then
                density_mismatch=true
                echo Density mismatch >&2
            fi
            previous_x_density=${x_density[number]}
            previous_y_density=${y_density[number]}
            if [ -z "$output" ]; then
                output=$(basename "$canonical_path" .${canonical_path##*.})
            else
                output=$output$delimiter$(basename "$canonical_path" \
                                                   .${canonical_path##*.})
            fi
        else
            echo $path does not exist >&2
            exit 1
        fi
        ((++number))
    done
fi

# Align the scanned images.
aligned=$script-$$-$(printf %03d $LINENO)-aligned
align_image_stack -a "$aligned-" -i -c $control_points "${input[@]}" || exit

# Make the aligned images monochromatic and composite them
# successively.
current=0
monochrome=$script-$$-$(printf %03d $LINENO)-monochrome
composite=$script-$$-$(printf %03d $LINENO)-composite
while [ "$current" -lt $# ]; do
    current=$(printf %04d $current)
    # In JPEG files, align_image_stack sets 150 ppi to pixel densities
    # of output files.
    mogrify -density ${x_density[current]}x${y_density[current]} \
            "$aligned-$current.tif" || exit
    convert $monochrome_options \
            -colorspace Gray +level-colors ${color[current]}, \
            "$aligned-$current.tif" "$monochrome-$current.tif" || exit
    if [ "$remove_intermediate_files" == true ]; then
        rm "$aligned-$current.tif"
    fi
    if [ "$current" -eq 1 ]; then
        convert -composite -compose multiply \
                "$monochrome-$previous.tif" "$monochrome-$current.tif" \
                "$composite-$current.tif" || exit
        if [ "$remove_intermediate_files" == true ]; then
            rm "$monochrome-$previous.tif" "$monochrome-$current.tif"
        fi
    elif [ "$current" -ge 2 ]; then
        convert -composite -compose multiply \
                "$composite-$previous.tif" "$monochrome-$current.tif" \
                "$composite-$current.tif" || exit
        if [ "$remove_intermediate_files" == true ]; then
            rm "$composite-$previous.tif" "$monochrome-$current.tif"
        fi
    fi
    previous=$current
    ((++current))
done

# Trim the composited image.
trimmed=$script-$$-$(printf %03d $LINENO)-trimmed
if [ "$trim" == true ]; then
    convert -deskew $deskew -trim -fuzz $fuzz +repage \
            "$composite-$previous.tif" "$trimmed-$previous.tif" || exit
else
    cp "$composite-$previous.tif" "$trimmed-$previous.tif"
fi
if [ "$remove_intermediate_files" == true ]; then
    rm "$composite-$previous.tif"
fi

# Define tick marks.
if [ "$draw_tick" == true -a "$density_mismatch" != true ]; then
    calculate() {
        awk "BEGIN {printf (\"%.${1}f\", $2)}"
    }
    eval $(identify -format 'page_width=%W page_height=%H' \
                    "$trimmed-$previous.tif" || echo exit $?)
    x_pixels_per_mm=$(calculate 6 "${x_density[0]} / 25.4")
    y_pixels_per_mm=$(calculate 6 "${y_density[0]} / 25.4")
    page_width_mm=$(calculate 6 "$page_width / $x_pixels_per_mm")
    page_height_mm=$(calculate 6 "$page_height / $y_pixels_per_mm")
    x_tick_length=$(calculate 0 "$y_pixels_per_mm * $tick_length_mm")
    x_tick_width=$(calculate 0 "$x_pixels_per_mm * $tick_width_mm")
    for i in $(seq $tick_interval_mm $tick_interval_mm $page_width_mm); do
        x=$(calculate 0 "$x_pixels_per_mm * $i")
        x_draw="$x_draw line $x,$page_height $x,$((page_height - x_tick_length))"
    done
    y_tick_length=$(calculate 0 "$x_pixels_per_mm * $tick_length_mm")
    y_tick_width=$(calculate 0 "$y_pixels_per_mm * $tick_width_mm")
    for i in $(seq $tick_interval_mm $tick_interval_mm $page_height_mm); do
        y=$(calculate 0 "$y_pixels_per_mm * $i")
        y_draw="$y_draw line 0,$((page_height - y)) $y_tick_length,$((page_height - y))"
    done
else
    x_tick_length=0
    y_tick_length=0
fi

# Define plot legends.
number=0
while [ "$number" -lt $# ]; do
    if [[ $gravity =~ ^South ]]; then
        subscript=$(($# - number - 1))
        suffix=$newlines
    else
        subscript=$number
        prefix=$newlines
    fi
    annotate_1=("${annotate_1[@]}" \
                    -annotate +$y_tick_length+$x_tick_length \
                    "$prefix${annotate[subscript]}$suffix")
    annotate_2=("${annotate_2[@]}" \
                    -stroke ${color[subscript]} -fill ${color[subscript]} \
                    -annotate +$y_tick_length+$x_tick_length \
                    "$prefix${annotate[subscript]}$suffix")
    ((++number))
    newlines="$newlines\n"
done

# Add the defined tick marks and plot legends to the trimmed image.
convert -stroke $tick_color \
        -strokewidth ${x_tick_width:-0} -draw "$x_draw" \
        -strokewidth ${y_tick_width:-0} -draw "$y_draw" \
        -gravity $gravity -font $font -pointsize $pointsize \
        -stroke $stroke -strokewidth $strokewidth "${annotate_1[@]}" \
        -strokewidth 0 "${annotate_2[@]}" \
        "$trimmed-$previous.tif" "$output.tif" || exit
if [ "$remove_intermediate_files" == true ]; then
    rm "$trimmed-$previous.tif"
fi
