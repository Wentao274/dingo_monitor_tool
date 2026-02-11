# dingo_monitor_tool
The scripts for dingo region and store process monitor

To monitor your dingodb-cluser, just complete following steps:
1. put all files under monitor_tool folder in your cluster path which have dingodb_cli command tool exist (scripts and dingodb_cli at the same directory level);
2. two method to run the scripts:
   1) using crontab set run schedule, you must specify two arguments to the run_mon.sh, scripts will just only run one time (without loop) when the schedule reached, a beautiful example bellow in crontab (you can define the run frequency according to your demand):
      
      */30 * * * * flock -n /tmp/dingo_mon.lock /home/dingo-store/dingo-store/build/bin/run_mon.sh "300" "true" >> /home/dingo-store/dingo-store/build/bin/region_monitor.log
   3) run the monitor script directly:
      a. no arguments like: ./run_mon.sh           (this will sleep 300 seconds between two monitor loop by default)
      b. one arguments like: ./run_mon.sh 600      (this will sleep 600 seconds between two monitor loop;)       
