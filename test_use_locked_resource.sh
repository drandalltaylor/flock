#!/usr/bin/env bash
#set -x

# By Randy Taylor
# February, 2022

# Purpose: Use the resource guarded by the TEST_FILE_LOCK during execution of this script.
#          The resource could be anything that requires exclusive access.
# Caller:  test_run_program_with_flock.sh 
#


TEST_SECONDS=$1
TEST_EXIT_CODE=$2
TEST_LOCK_FILE=$3

MY_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
MY_BASENAME=`basename $0`

echo "Hello $MY_BASENAME"

source ${MY_DIR}/flock_constants.sh
source ${MY_DIR}/flock_utils.sh

if [ "$1" == "" ]; then
    TEST_SECONDS=60
    echo "$MY_BASENAME: WARNING: missing positional parameter: TEST_SECONDS, defaulting to $TEST_SECONDS"
else
    TEST_SECONDS=$1
fi
if [ "$2" == "" ]; then
    TEST_EXIT_CODE=255
    echo "$MY_BASENAME: WARNING: missing positional parameter: TEST_EXIT_CODE, defaulting to $TEST_EXIT_CODE"
else
    TEST_EXIT_CODE=$2
fi

start_timet=`date +%s`
now_timet=`date +%s`
remaining_seconds=$(( TEST_SECONDS - (now_timet - start_timet) )) 
while (( $remaining_seconds >= 0 )); do 
    echo "$MY_BASENAME: INFO: [$remaining_seconds] seconds remaining; Resource represented by [$TEST_LOCK_FILE] is in use by pid[$$]"
    FlockLogFileUsers "$TEST_LOCK_FILE" 
    sleep 10
    now_timet=`date +%s`
    remaining_seconds=$(( TEST_SECONDS - (now_timet - start_timet) )) 
done

echo "$MY_BASENAME: INFO: Goodbye. exit_code:[$TEST_EXIT_CODE]"
exit $TEST_EXIT_CODE

