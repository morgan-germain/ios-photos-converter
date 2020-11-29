#!/bin/sh

# iOS Photos / Videos converter
# All Photos and videos taken with an iOS device cannot be seen by
# everyone through a web browser (typically with a Nextcloud share)
# This script aims to find all photos from a given (sub)folder and
# - Convert HEIC files to JPG files
# - Correct HEIC files that are JPG files (iOS bug ?)
# - Convert MOV files to WebM files
# - Remove live photos because they are doubles with HEIC version

# Requirements
#	sudo apt install libheif-examples ffmpeg exiftool

FOLDER=/media/myPhotoFolder

# I am built to run on an Raspberry Pi 4
# so I don't want to overheat and photo
# conversion is less urgent than web server
renice --priority +19 --pid $$ 

remove_live_photo() {
	if [ $# -ne 1 ]; then
		echo 'Need one file argument' 1>&2
		exit 1
	fi

	local photo_file="${1}"
	local video_file="${1%.mov}"

	if [ ! -r "${video_file}" ]; then
		return
	fi

	photo_id=$(exiftool -u -s "${photo_file}" | grep ContentIdentifier | cut -d':' -f2 | tr -d ' ' )
	video_id=$(exiftool -ContentIdentifier "${video_file}" | cut -d':' -f2 | tr -d ' ' )

	if [ -z "${photo_file}" -o -z "${video_file}" ]; then
		return
	fi	       

	if [ "${photo_file}" = "${video_file}" ]; then
		echo "Removing Live photo ${video_file}"
		rm "${video_file}"
	fi	       
}


echo Finding HEIC photo files that are JPG instead
echo -----------------
find "${FOLDER}" \
	-type f \
	-iname '*.heic' \
	-exec sh -c 'file "$1" | grep --silent JPEG && echo "$1" && mv "$1" "${1%.heic}.jpg"' _ {} \;

echo Removing live photos since they are doubles
echo -----------------
find "${FOLDER}" \
	-type f\
	-iname '*.heic' | while read file; do remove_live_photo "${file}"; done

echo Converting photos
echo -----------------
find "${FOLDER}" \
	-type f \
	-iname '*.heic' \
	-exec sh -c 'echo "$1" && nice -n19 heif-convert "$1" "${1%.heic}.jpg" && rm "$1"' _ {} \;

echo Converting videos
echo -----------------
find "${FOLDER}" \
	-type f \
	-iname '*.mov' \
	-exec sh -c 'echo "$1" && nice -n19 ffmpeg -y -i "$1" "${1%.mov}.mp4" && rm "$1"' _ {} \;

