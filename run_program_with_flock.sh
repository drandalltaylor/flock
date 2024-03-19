#/usr/bin/env bash
#set -x

# By Randy Taylor
# February, 2022 

# Purpose: Run a program under the control of the flock command.  The flock command will create or re-use
# an existing file and attempts to gain exclusive write-access to a file (thereby establishing system-wide
# exclusive access to some resource that is represented by the file). Further, by using flock, other utility
# programs such as "fuser" can be used to identify which process pid has exclusive access to the resource.
#
#   For example:
#       ./run_program_with_flock.sh -l /var/lock/EXCLUSIVE_FLOCK_TEST1 -e 999 -f /var/app/user_program --param1 one --param2 two 
#
#       -l LOCK_PATH for the lock file (required)
#       -e EXIT_CODE for the failure of the flock command (required)
#       -f USER_PROGRAM for the user program to execute (required)
#       
#       Additional parameters are simply passed to the user's program indicated by the -f parameter.
#  
#  Operating systems: Linux, OSX, and other Unices.
#
#  Notes:
#       See: https://stackoverflow.com/questions/1964301/how-do-i-check-the-exit-code-of-a-command-executed-by-flock
#
#  OSX Darwin Notes:
#     /private/var/run is the place for system/root level pid files to live on OSX (Darwin)
#     See: https://stackoverflow.com/questions/64963956/xcode-log-message-flock-failed-to-lock-list-file
#

MY_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
MY_BASENAME=`basename $0`

source ${MY_DIR}/flock_constants.sh
source ${MY_DIR}/flock_utils.sh

UNAME_VAL=`uname -a`
which flock >/dev/null 2>&1
if (( $? != 0 )); then
    FlockLog "$MY_BASENAME: ERROR: Missing flock command"
    if [[ "${UNAME_VAL}" == *"Darwin"* ]]; then
        FlockLog "$MY_BASENAME: INFO: On OSX, try: brew install flock"
    fi
    exit 1
fi

function Usage() {
    echo "$MY_BASENAME --lockfile LOCK_PATH --flock_error EXIT_CODE -f USER_PROGRAM [additional parameters...]" 
    echo "   -l --lockfile      LOCK_PATH for the lock file (required)"
    echo "   -e --flock_error   EXIT_CODE for the failure of the flock command (required)"
    echo "   -f --user_program  USER_PROGRAM for the user program to execute (required)"
    echo " "
    echo "    example: ./$MY_BASENAME -l /var/lock/EXCLUSIVE_FLOCK_TEST1 -e 999 -f ./test_use_locked_resource.sh"
    echo " "
}

# Command line parameter variables, prior to command line processing
export LOCK_FILE=""                # -l parameter, for example /var/lock/EXCLUSIVE_FLOCK_TEST1 
export EXIT_CODE_FLOCK_FAILURE=""  # -e parameter, exit code from this script if flock fails 
export USER_PROGRAM=""             # -f parameter, the script to run under control of flock 
export USER_PARAMS=""              # parameters passed to USER_PROGRAM

# User's program and it's parameters 
USER_CMD=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      Usage
      exit 0
      ;;
    -l|--lockfile)
      LOCK_FILE="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--user_program)
      USER_PROGRAM="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--flock_error)
      EXIT_CODE_FLOCK_FAILURE="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      USER_PARAMS="$USER_PARAMS $1"
      shift # past token 
      ;;
  esac
done

if [ "${LOCK_FILE}" == "" ] || [ "${USER_PROGRAM}" == "" ] || [ "${EXIT_CODE_FLOCK_FAILURE}" == "" ]; then
    msg="${MY_BASENAME}: ERROR: Required parameters missing"
    Usage
    FlockLog "${msg}"
    exit 1
fi

if [ ! -f "${USER_PROGRAM}" ]; then
    msg="${MY_BASENAME}: ERROR: file does not exist: [${USER_PROGRAM}]"
    Usage
    logger -s -- "${msg}"
    exit 1
fi

USER_CMD="${USER_PROGRAM} ${USER_PARAMS}"

msg="${MY_BASENAME}: INFO: Attempt to exclusively lock [${LOCK_FILE}] then run [${USER_CMD}]" 
FlockLog "${msg}"

# The parenthesis make a subshell; Attempt to lock file then run the user script; 200 is a file descriptor

(
    if flock --nonblock --verbose --exclusive 200; then
       msg="${MY_BASENAME}: INFO: ${LOCK_FILE} is now exclusively owned by me. Running cmd: [${USER_CMD}]"
       FlockLog "${msg}"
       ${USER_CMD} 
       user_exit_code=$?
       msg="${MY_BASENAME}: INFO: ${LOCK_FILE} will be freed. Exit code: [${user_exit_code}] for cmd: [${USER_CMD}]"
       FlockLog "${msg}"
       #rm -f ${LOCK_FILE}
       exit ${user_exit_code}
    else
       msg="${MY_BASENAME}: ERROR: ${LOCK_FILE} not locked by flock; cmd not run: [${USER_CMD}]"
       FlockLog "${msg}"
       #rm -f ${LOCK_FILE}
       exit ${EXIT_CODE_FLOCK_FAILURE}
    fi
) 200>${LOCK_FILE}

# Capture the sub-shell exit code
subshell_exit_code=$?

if (( ${subshell_exit_code} == ${EXIT_CODE_FLOCK_FAILURE} )); then
    msg="${MY_BASENAME}: ERROR: flock failed for ${LOCK_FILE}; cmd not executed: [${USER_CMD}]; exit_code=${EXIT_CODE_FLOCK_FAILURE}"
    FlockLog "${msg}"
    exit ${EXIT_CODE_FLOCK_FAILURE}
else
    if (( ${subshell_exit_code} == 0 )); then
        msg="$MY_BASENAME: INFO: flock succeeded, now unlocked for ${LOCK_FILE}; cmd succeeded: [${USER_CMD}] ; exit_code=${subshell_exit_code}"
    elif (( ${subshell_exit_code} == 1 )); then
        msg="$MY_BASENAME: ERROR: flock failed, cmd not attempted: [${USER_CMD}] ; exit_code=${subshell_exit_code}"
    else
        msg="$MY_BASENAME: ERROR: flock succeeded, now unlocked for ${LOCK_FILE}; cmd failed: [${USER_CMD}] ; exit_code=${subshell_exit_code}"
    fi
    FlockLog "${msg}"
    exit ${subshell_exit_code}
fi

