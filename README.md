<pre>
Author: Randy Taylor
Date:   2024-03-19
Synopsis: Utility bash scripts to use the flock command to ensure only a single process 
          gains exclusive access to a resource represented by the file.
          Assumes the exit code from the user's process will be zero upon no error.
          Reserves exit code 255 as meaning flock has failed to lock the file.
</pre>

