#!/usr/bin/env bash

set -e # halt on error

echo_and_exec() {
    echo "> $@"
    "$@"
}

SDK="$(cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")"
# edit the following line to point to your developer key

PROJECT_FOLDER=${PWD}
PROJECT_NAME=$(basename "${PROJECT_FOLDER}")

# Branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -e "\nGenerate ${PROJECT_NAME}_TEST..."
DEV_KEY="${HOME}/.Garmin/ConnectIQ/keys/developer_key_test.der"
echo_and_exec java -Xms1g -"Dfile.encoding=UTF-8" -"Dapple.awt.UIElement=true"    \
    -jar "${SDK}"bin/monkeybrains.jar \
    --output "bin/${PROJECT_NAME}Test.iq"    \
    --jungles "monkey.jungle" \
    --private-key ${DEV_KEY}    \
    --package-app --release --warn
echo -e "Generated bin/${PROJECT_NAME}Test.iq"

DEVICE=${1:-edge1050}
OUTPUT_FILE="bin/${PROJECT_NAME}_${DEVICE}.prg"

#if [[ $1 == "" ]]; then
#    >&2 echo Usage: ciq-release.sh [device]
#    >&2 echo e.g.: ciq-release.sh fr255
#    exit 1
#fi

 
if [[ ! -e manifest.xml ]]; then
    >&2 echo manifest.xml not found in the current folder: ${PROJECT_FOLDER}
    >&2 echo Run this script from the root of a Monkey C project
    exit 1
fi
 
# start simulator
# echo_and_exec "${SDK}"bin/connectiq &
# Creates output as:
# bin/{PROJECT_FOLDERNAME}-release.prg

JUNGLEPATHS="${PWD}/monkey.jungle"
[[ -e "${PWD}/barrels.jungle" ]] && JUNGLEPATHS="${JUNGLEPATHS};${PWD}/barrels.jungle"

echo_and_exec "${SDK}"bin/monkeyc \
    --private-key "${DEV_KEY}" --jungles "${JUNGLEPATHS}" \
    --device ${DEVICE} --output "${OUTPUT_FILE}" \
    --warn --typecheck 1 --release
    # --debug-log-output logs/monkeyc.zip --debug-log-level 3 
# echo_and_exec "${SDK}"/bin/monkeydo "${OUTPUT_FILE}" ${DEVICE}
echo -e "Generated ${OUTPUT_FILE}"

mtp-detect | grep "Model: Edge 1050"
echo "Status=$?"

exit 0

MTP="../../MTP/"
[[ -d ${MTP} ]] || mkdir -p ${MTP}
rm -f ${MTP}${PROJECT_NAME}*.prg
cp -v "${OUTPUT_FILE}"* "${MTP}"

IFS=$'\n'
regex="^\s*([0-9]+)\s(.*)" # put the regex in a variable because some patterns won't work if included literally
for f in $(mtp-filetree | grep "${PROJECT_NAME}.prg"); do
    if [[ ${f} =~ ${regex} ]]; then
        num="${BASH_REMATCH[1]}"
        file="${BASH_REMATCH[2]}"
        echo "DELETE ${num} ${file}"
        #mtp-connect --delete ${file}
        mtp-delfile -n ${num} && echo "File ${file} deleted"
    fi
done;
for f in $(mtp-filetree | grep "Apps")
do
    if [[ ${f} =~ ${regex} ]]; then
        num="${BASH_REMATCH[1]}"
        file="${BASH_REMATCH[2]}"
        echo "mtp-connect --sendfile ${OUTPUT_FILE} ${num}"
        #mtp-detect | grep "idVendoridVendor: 091e"
        #if [ $? -eq 0 ]; then
            mtp-connect --sendfile ${OUTPUT_FILE} ${num}
            mtp-files | grep -B 1 -A 4 "${PROJECT_NAME}" | grep -B 3 -A 2 "Parent ID: ${num}"
            echo "${PROJECT_NAME} copy to device"
        #else
            #echo "MTP Garmin device not found!" >&2
        #fi
        break;
    fi
done

echo "mtp-filetree | grep CIQ"
echo "mtp-getfile 436 logs/CIQ_LOG.YML"
