#!/usr/bin/env bash
#set -x

# By Randy Taylor
# February, 2022

# Purpose: Use the resource guarded by the TEST_FILE_LOCK during execution of this script.
#          The resource could be anything that requires exclusive access.
# Caller:  test_run_program_with_flock.sh 
#

echo "Hello $0"

TEST_SECONDS=$1
EXIT_CODE=$2
TEST_LOCK_FILE=$3

MY_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
MY_BASENAME=`basename $0`

source ${MY_DIR}/flock_constants.sh
source ${MY_DIR}/flock_utils.sh

if [ "$1" == "" ]; then
    TEST_SECONDS=60
    echo "$0: WARNING: missing positional parameter: TEST_SECONDS, defaulting to $TEST_SECONDS"
else
    TEST_SECONDS=$1
fi
if [ "$2" == "" ]; then
    EXIT_CODE=999
    echo "$0: WARNING: missing positional parameter: EXIT_CODE, defaulting to $EXIT_CODE"
else
    EXIT_CODE=$2
fi

while (( 1 == 1 )); do 
    echo "$0: INFO: [$TEST_SECONDS] seconds remaining; Resource represented by [$TEST_LOCK_FILE] is in use by pid[$$]"
    FlockLogFileUsers "$TEST_LOCK_FILE" 
    TEST_SECONDS=$((--TEST_SECONDS))
    if (( $TEST_SECONDS >= 0 )); then
        sleep 1
    else 
        break
    fi
done
echo "$0: INFO: Exit with exit code: $EXIT_CODE"
echo "Goodbye $0"
exit $EXIT_CODE

