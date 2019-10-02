using DelimitedFiles, Printf, Statistics
ovh = median(readdlm("SAC.q.log", ',')[:,1]) # system overhead; time to start/exit SAC
t_sac = median(readdlm("SAC.read_sac.log", ',')[:,1])
t_suds = median(readdlm("SAC.read_suds.log", ',')[:,1])
mem_sac = 73140/1024
mem_suds = 11132/1024
mem_q = 5540/1024

f_suds = "10081701.WVP"

@printf("%13s %30s %9s %9s\n", "Format", "Filename", "Mem_[MB]", "T_[ms]")
@printf("%13s %30s %9.2f %9.2f\n", "SAC", "1d-100hz.sac", mem_sac-mem_q, t_sac-ovh)
@printf("%13s %30s %9.2f %9.2f\n", "SUDS", "../Restricted/10081701.WVP", mem_suds-mem_q, t_suds-ovh)

# Memory
# SUDS: 11132 K
# SAC: 73140 K
# Q: 5540 K

# Result:
# Format                       Filename  Mem_[MB]    T_[ms]
#    SAC                    one_day.sac     66.02    113.58
#   SUDS                   10081701.WVP      5.46     15.35
