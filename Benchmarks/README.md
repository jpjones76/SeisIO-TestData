# Benchmarks from Jones et al.,  SeisIO

Benchmark data are here provided files can be redistributed.

# ObsPy
1. install ObsPy cf. their GitHub instructions
2. create a conda environment named "obspy" cf. their GitHub instructions
3. execute:

```
conda activate obspy
conda install pytest memory_profiler pyasdf
cd ObsPy
python
exec(open("./ObsPy_bench1.py").read())
```

This will run all benchmarks and generate `benchmarks_python.csv` with output.
Raw data for each trial are not saved to the CSV file.

# SeisIO
1. install Julia cf. instructions at http://www.julialang.org
2. execute:

```
julia
using Pkg
Pkg.add("SeisIO")
cd("SeisIO")
include("benchmark_file_reads.jl")
```

This will run all benchmarks and generate `benchmarks_julia.csv` with output.
Raw data for each trial are not saved to the CSV file.

# SAC
1. request SAC from their website
2. compile and install SAC-101.6a from source cf. the Makefile
3. install `perf`; it may be part of a larger package, as in Ubuntu 18.04 LTS
4. follow the command syntax skeleton in `sac_shell.sh`
5. clean the logs with grep -v
