#!/bin/bash
DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIRMED_SLUG_ID=$(cat $DIRECTORY/../config/config.json | jq -r ".config.remoteId")

TEMPFILE=$DIRECTORY/output.tmp
echo 0 > $TEMPFILE

ERRORS_FOUND=0

echo "Verifying audio for words data ${CONFIRMED_SLUG_ID}."
#CHECKSUM_WORDS=$(md5 $DIRECTORY/../data/words.json)

cat $DIRECTORY/../data/words.json | jq -r '.[] | select(.audio != null).audio[].filename' | while read file ; do

  # Extract slug from URL
  SLUG_ID=$( echo "$file" |cut -d/ -f 4 )

	# Check if slug in URL is correct
  if [[ $SLUG_ID == $CONFIRMED_SLUG_ID ]]; then
    # Check if binary file exists in remote
    if [ $(curl  -o /dev/null --silent --head -w "%{http_code}\n" ${file}) -ne "200" ]; then
      echo "File not found: ${file}"
      ERRORS_FOUND=$((ERRORS_FOUND+1))
      echo $ERRORS_FOUND > $TEMPFILE
    fi
  else 
    echo "Wrong slug id for file: ${file}. Expected '${CONFIRMED_SLUG_ID}' but found '${SLUG_ID}'"
    ERRORS_FOUND=$((ERRORS_FOUND+1))
    echo $ERRORS_FOUND > $TEMPFILE
  fi

  let WORDS_PROCESSED=WORDS_PROCESSED+1
  if [ $(( $WORDS_PROCESSED % 500 )) -eq 0 ]; then
    echo "Verified ${WORDS_PROCESSED} entries for ${SLUG_ID}"
  fi

done

echo "Verifying audio for phrases data ${CONFIRMED_SLUG_ID}."
#CHECKSUM_WORDS=$(md5 $DIRECTORY/../data/phrases.json)

cat $DIRECTORY/../data/phrases.json | jq -r '.[] | select(.audio != null).audio[].filename' | while read file ; do

  # Extract slug from URL
  SLUG_ID=$( echo "$file" |cut -d/ -f 4 )

	# Check if slug in URL is correct
  if [[ $SLUG_ID == $CONFIRMED_SLUG_ID ]]; then
    # Check if binary file exists in remote
    if [ $(curl  -o /dev/null --silent --head -w "%{http_code}\n" ${file}) -ne "200" ]; then
      echo "File not found: ${file}"
      ERRORS_FOUND=$((ERRORS_FOUND+1))
      echo $ERRORS_FOUND > $TEMPFILE
    fi
  else 
    echo "Wrong slug id for file: ${file}. Expected '${CONFIRMED_SLUG_ID}' but found '${SLUG_ID}'"
    ERRORS_FOUND=$((ERRORS_FOUND+1))
    echo $ERRORS_FOUND > $TEMPFILE
  fi

  let PHRASES_PROCESSED=PHRASES_PROCESSED+1
  if [ $(( $PHRASES_PROCESSED % 500 )) -eq 0 ]; then
    echo "Verified ${PHRASES_PROCESSED} entries for ${SLUG_ID}"
  fi

done

ERROR_FOUND=$(cat $TEMPFILE)
unlink $TEMPFILE

echo "Verifications complete."

if [ $ERROR_FOUND -gt 0 ]; then 
  echo "Found ${ERROR_FOUND} errors."
  exit 1;
fi

echo "No errors found."

exit 0
