#!/usr/bin/bash
#perf stat -r 10 record -F 99 -a
# sudo chrt -f 99 /usr/bin/time --verbose `sac sac_q`
#`sac sac_q`

# time
for i in {1..100}; do (sudo chrt -f 99 perf stat -e task-clock -x ',' bash -c 'export SACAUX=/usr/local/sac/aux; /usr/local/sac/bin/sac sac_suds'); done

# memory
sudo chrt -f 99 /usr/bin/time -v bash -c 'export SACAUX=/usr/local/sac/aux; /usr/local/sac/bin/sac sac_suds'
