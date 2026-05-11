#!/usr/bin/env bash

CURRENT_VERSION=1

set -e # halt on error

echo_and_exec() {
    echo "> $@"
    "$@"
}

rm -rf bin/ && echo "Deleted bin/"

SDK="$(cat "${HOME}/.Garmin/ConnectIQ/current-sdk.cfg")"
# edit the following line to point to your developer key

PROJECT_FOLDER=${PWD}
PROJECT_NAME=$(basename "${PROJECT_FOLDER}")
PROJECT_NAME="SlavicGearIndex"

APP_TEST_ID="c4755d9c-e9e1-4924-b458-04e708ce9999"
APP_PROD_ID="c4755d9c-e9e1-4924-b458-04e708ce0000"

SYSTEM="Test"
# Branch name
BRANCH=$(git rev-parse --abbrev-ref HEAD)
[[ "${BRANCH}" == "main" ]] && SYSTEM="";

# Revert change on version
#git checkout -- resources/strings/strings.xml manifest.xml

#BUILD=$(git rev-list HEAD --count)
# Commits this month
COMMITS=$(git rev-list --count --since="$(date +'%+4Y-%m-01')" --all)

if [ -z ${SYSTEM} ];  then
    BUILD=${CURRENT_VERSION}"."$(date +'%+y%m')"."$(git rev-list --count --since="$(date +'%+4Y-%m-01')" --all)
else 
    BUILD=${CURRENT_VERSION}".${BRANCH}."$(git rev-list --no-merges --count HEAD ^${BRANCH})
    echo "BUILD=${BUILD}"
fi;



[[ ${BRANCH} == "main" ]] && BRANCH=""
VERSION=$(xmllint --xpath "//strings/string[@id='version']/text()" resources/strings/strings.xml)
echo "Version=${VERSION}"
echo "GIT Build=${BUILD}"

#OLDBUILD="${VERSION##*.}"
#VERSION=${VERSION%.*}
#VERSION=${VERSION}.${BUILD}
#echo "    GIT Build=${OLDBUILD}"
#echo "Version Build=${OLDBUILD}"
if [[ "${VERSION}" != "${BUILD}${SYSTEM}" ]]; then
    echo "Set version=${BUILD}${SYSTEM}"
    echo -e "cd /strings/string[@id=\"version\"]\nset ${BUILD}${SYSTEM}\nsave" | xmllint --shell resources/strings/strings.xml
fi
#xmllint --xpath "//strings/string[@id='version']/text()" resources/strings/strings.xml


APP_ID=$(echo -e "setns iq=http://www.garmin.com/xml/connectiq\ncat //iq:manifest/iq:application/@id" | xmllint --shell manifest.xml | grep -v ">" | cut -f 2 -d "=" | tr -d \");
#echo -e "\n1. APP_ID=${APP_ID}"

if [ "${SYSTEM}" == "Test" ]; then
    if [ ${APP_ID} != ${APP_TEST_ID} ]; then
        echo "Write APP_TEST_ID=${APP_TEST_ID}"
        echo -e "setns iq=http://www.garmin.com/xml/connectiq\ncd //iq:manifest/iq:application/@id\nset ${APP_TEST_ID}\nsave\nbye" | xmllint --shell manifest.xml
    fi
else
    if [ ${APP_ID} != ${APP_PROD_ID} ]; then
        echo "Write APP_PROD_ID=${APP_PROD_ID}"
        echo -e "setns iq=http://www.garmin.com/xml/connectiq\ncd //iq:manifest/iq:application/@id\nset ${APP_PROD_ID}\nsave\nbye" | xmllint --shell manifest.xml
    fi
fi
echo "Set AppName=${PROJECT_NAME} ${BUILD}"
echo -e "cd //strings/string[@id=\"AppName\"]\nset ${PROJECT_NAME} ${BUILD}\nsave\nbye" | xmllint --shell resources/strings/strings.xml

#echo -ne "2. APP_ID="
#echo -e "setns iq=http://www.garmin.com/xml/connectiq\ncat //iq:manifest/iq:application/@id" | xmllint --shell manifest.xml | grep -v ">" | cut -f 2 -d "=" | tr -d \"

#git add .
#git commit -m "Build version ${VERSION}"

#BUILD=$(git rev-list --count --all)

echo -e "\nGenerate ${PROJECT_NAME}-${BUILD}..."
DEV_KEY="${HOME}/.Garmin/ConnectIQ/developer_key.der"

if [[ -z ${1} ]]; then
    echo_and_exec java -Xms1g -"Dfile.encoding=UTF-8" -"Dapple.awt.UIElement=true"    \
        -jar "${SDK}"bin/monkeybrains.jar \
        --output "bin/${PROJECT_NAME}-${BUILD}.iq"    \
        --jungles "monkey.jungle" \
        --private-key ${DEV_KEY}    \
        --package-app --release --warn
    echo -e "Generated bin/${PROJECT_NAME}-${BUILD}.iq"
fi;

DEVICE=${1:-edge1050}
OUTPUT_FILE="bin/${PROJECT_NAME}-${BUILD}_${DEVICE}.prg"

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
