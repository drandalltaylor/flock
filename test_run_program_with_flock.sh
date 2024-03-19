#/bin/bash
#set -x

# By Randy Taylor
# February, 2022

# Purpose: Test run_program_with_flock.sh by retry of attempt to flock the lock file.

MY_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
MY_BASENAME=`basename $0`

source ${MY_DIR}/flock_constants.sh
source ${MY_DIR}/flock_utils.sh

TEST_LOCK_FILE=${EXCLUSIVE_FLOCK_TEST1_PATH}
TEST_FLOCK_FAILURE_EXIT_CODE="$1"  # if flock command fails, I want this exit code
TEST_SECONDS="$2"
TEST_EXIT_CODE="$3"  # my $TEST_PROGRAM will exit with this exit code if it runs" 

TEST_PROGRAM=${MY_DIR}/test_use_locked_resource.sh
DRIVER_PROGRAM=${MY_DIR}/run_program_with_flock.sh

if [ "$TEST_FLOCK_FAILURE_EXIT_CODE" == "" ]; then
    TEST_FLOCK_FAILURE_EXIT_CODE=999
    echo "$0: WARNING: missing positional parameter TEST_FLOCK_FAILURE_EXIT_CODE, defaulting to $TEST_FLOCK_FAILURE_EXIT_CODE"
fi
if [ "$TEST_EXIT_CODE" == "" ]; then
    TEST_EXIT_CODE=0
    echo "$0: WARNING: missing positional parameters TEST_EXIT_CODE, defaulting to $TEST_EXIT_CODE"
fi
if [ "$TEST_SECONDS" == "" ]; then
    TEST_SECONDS=60
    echo "$0: WARNING: missing positional parameter TEST_SECONDS, defaulting to $TEST_SECONDS"
fi

exit_code=1
while (( 1 == 1 )); do 
    $DRIVER_PROGRAM -l "$TEST_LOCK_FILE" -e "$TEST_FLOCK_FAILURE_EXIT_CODE" -f "$TEST_PROGRAM" "$TEST_SECONDS" "$TEST_EXIT_CODE" "$TEST_LOCK_FILE"
    exit_code=$?
    if (( $exit_code == $TEST_FLOCK_FAILURE_EXIT_CODE )); then
        seconds=10
        echo "$0: INFO: flock failed to lock $TEST_LOCK_FILE so try again in $seconds seconds"
        pids=`fuser $TEST_LOCK_FILE`
        LogPidInfo $pids
        sleep $seconds 
    else
        if (( $exit_code == 0 )); then
            echo "$0: INFO: flock succeeded; $TEST_PROGRAM succeded with exit code: $exit_code"
        else 
            echo "$0: ERROR: flock succeeded; $TEST_PROGRAM failed with exit code: $exit_code"
        fi
    fi
done
exit $exit_code 

