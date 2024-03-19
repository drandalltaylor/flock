/*
# Defines all the system-wide flock (file-lock) file names.
# flock is a common command on unix-like platforms. 
# Each file-lock represents a system-wide shared resource that requires exclusive access.
# Naming conventions should follow the examples TEST1 and TEST2:
#    TEST1  - names and represents a shared resource that requires exclusive access.
#    TEST2  - names and represents a shared resource that requires exclusive access.
#    XXXX   - names and represents a shared resource that requires exclusive access.
*/

class FlockConstants {

    public static final String EXCLUSIVE_FLOCK_TEST1_PATH = "/var/lock/EXCLUSIVE_FLOCK_TEST1";
    public static final String EXCLUSIVE_FLOCK_TEST2_PATH = "/var/lock/EXCLUSIVE_FLOCK_TEST2";

}

