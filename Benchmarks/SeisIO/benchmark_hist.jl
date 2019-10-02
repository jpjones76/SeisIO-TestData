using DelimitedFiles, Printf, PyPlot, SeisIO

# Master table of (exact) filenames and test names
pref  = pwd() * "/../test/SampleFiles/"
test0 = String[
	       "1day-1hz.ah"                 "AH"
	       "2days-40hz.h5"               "ASDF"
	       "geo-tspair.csv"              "GeoCSV-tspair"
	       "1day-100hz.mseed"            "MSEED-1"
	       "Restricted/SHW.UW.mseed"     "MSEED-2"
	       "1day-100hz.segy"             "PASSCAL"
	       "1day-100hz.sac"              "SAC"
         "1h-62.5hz.slist"             "SLIST"
	       "SUDS/10081701.WVP"           "SUDS"
	       "99011116541W"                "UW"
	       "Restricted/2014092709*.cnt"  "WIN32"
	       ]
filenames = pref.*test0[:,1]

# Get file sizes
file_size = zeros(Float64, length(filenames))
for (i,f) in enumerate(filenames)
  if safe_isfile(f)
    file_size[i] = stat(f).size/1024^2
  else
    files = ls(f)
    sz = 0.0
    for j in files
      sz += stat(j).size
    end
    sz /= 1024^2
    file_size[i] = sz
  end
end

# SeisIO benchmarks
M = readdlm("benchmarks_julia.csv", ';')
N = size(M,1)
M = hcat(M, zeros(N, 6))
X = collect(1:N)
formats = test0[:,2]
files = M[:,2]

# Python benchmarks
M_py = readdlm("../ObsPy/benchmarks_python.csv", ';')
N_py = size(M_py, 1)
for i = 1:N_py
  j = findfirst(M_py[i,2].==test0[:,1])
  M[j,7:10] .= M_py[i,3:6]
end

# SAC benchmarks
(M_sac, M_sac_hdr) = readdlm("../SAC/benchmarks_sac.csv", ';', header=true)
N_sac = size(M_sac, 1)
for i = 1:N_sac
  j = findfirst(M_sac[i,2].==test0[:,1])
  M[j,11:12] .= M_sac[i,3:4]
end

# Indices for data
i_python  = findall(M[:,7].>0)    # Python
i_julia   = findall(M[:,3].>0)    # Julia
i_sac     = findall(M[:,11].>0)   # SAC
iu        = sort(unique(union(i_python, i_sac)))

# Program colors
ref_col = 0.00.*ones(Float64,3)
ju_col  = 0.25.*ones(Float64,3)
py_col  = 0.50.*ones(Float64,3)
sac_col = 0.75.*ones(Float64,3)

# Program labels
py_label  = "ObsPy v1.1.1"
ju_label  = "SeisIO v0.4.1"
sz_label  = "File Size"
sac_label = "SAC v101.6a"

# Plotting parameters
x_os = 0.1
x_sz = 0.87

# Plotting indices
x     = collect(1:length(iu))
py_x  = collect(1:N_py)
sac_x = findall(M[iu, 11] .!= 0.0)

# y = memory, oh = overhead, t = time
fs_y  = file_size[iu]
ju_y  = M[iu, 4]
ju_oh = M[iu, 5]
ju_t  = M[iu, 6]
py_y  = M[i_python, 8]
py_oh = M[i_python, 9]
py_t  = M[i_python, 10]
sac_y = M[i_sac, 11]
sac_t = M[i_sac, 12]

# y limits
mem_min = 10.0^(floor(log10(min(minimum(fs_y), minimum(ju_y), minimum(sac_y), minimum(py_y))-eps())))
mem_max = 10.0^(ceil(log10(max(maximum(fs_y), maximum(ju_y), maximum(sac_y), maximum(py_y))+eps())))
t_min = min(minimum(ju_t), minimum(sac_t), minimum(py_t))
t_max = max(maximum(ju_t), maximum(sac_t), maximum(py_t))
ov_min = 10.0^(log10(0.5*min(minimum(ju_oh), minimum(py_oh))))
ov_max = 10.0^(log10(2.0*max(maximum(ju_oh), maximum(py_oh))))

# x labels
xl = Array{String,1}(undef, length(iu))
for i = 1:length(xl)
  xl[i] = test0[iu[i],2]
end

# ============================================================================
# First histogram: Memory and overhead
fig = PyPlot.figure(figsize=[8.0, 6.0], dpi=300)
ax = PyPlot.axes([x_os, 0.52, x_sz, 0.4])
width = 0.2
rects1 = ax.bar(x .- 1.5*width, fs_y, width, label=sz_label, color=ref_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
rects2 = ax.bar(x .- 0.5*width, ju_y, width, label=ju_label, color=ju_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
rects3 = ax.bar(py_x .+ 0.5*width, py_y, width, label=py_label, color=py_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
rects4 = ax.bar(sac_x .+ 1.5*width, sac_y, width, label=sac_label, color=sac_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
for i = 1:length(x)
  if !(i in sac_x)
    text(i+1.5*width, mem_min, "NR", horizontalalignment="center", verticalalignment="bottom", fontsize=8.0, fontweight="bold", color=sac_col)
  elseif !(i in py_x)
    text(i+0.5*width, mem_min, "NR", horizontalalignment="center", verticalalignment="bottom", fontsize=8.0, fontweight="bold", color=py_col)
  end
end

PyPlot.xlim([0.5, length(xl)+0.5])
PyPlot.ylim([mem_min, mem_max])
PyPlot.ylabel("Memory [MB]", fontweight="bold", fontsize=12.0, family="serif", color="black")
PyPlot.setp(gca().get_yticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.setp(gca().get_xticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.xticks(x, "")
PyPlot.legend()

ax2 = PyPlot.axes([x_os, x_os, x_sz, 0.4])
width = 0.4
rects1 = ax2.bar(x .- 0.5*width, ju_oh, width, label=ju_label, color=ju_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
rects2 = ax2.bar(py_x .+ 0.5*width, py_oh, width, label=py_label, color=py_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
for i = 1:length(x)
  if !(i in py_x)
    text(i+0.5*width, ov_min, "NR", horizontalalignment="center", verticalalignment="bottom", fontsize=10.0, fontweight="bold", color=py_col)
  end
end

PyPlot.xlim([0.5, length(xl)+0.5])
PyPlot.ylim([ov_min, ov_max])
PyPlot.ylabel("Mem Overhead [%]", fontweight="bold", fontsize=12.0, family="serif", color="black")
PyPlot.setp(gca().get_yticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.setp(gca().get_xticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.xticks(x, xl)
PyPlot.legend()
savefig("mem_hist.png", pi=300, format="png", transparent=false, frameon=false)

# ============================================================================
# Second histogram: file read times
fig = PyPlot.figure(figsize=[8.0, 6.0], dpi=300)
ax = PyPlot.axes([x_os, 0.10, x_sz, 0.85])
width = 0.3
rects1 = ax.bar(x .- width, ju_t, width, label=ju_label, color=ju_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0])
rects2 = ax.bar(py_x, py_t, width, label=py_label, color=py_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0])
rects3 = ax.bar(sac_x .+ width, sac_t, width, label=sac_label, color=sac_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0])
for i = 1:length(x)
  if !(i in sac_x)
    text(i+width, 0.0, "NR", horizontalalignment="center", verticalalignment="bottom", fontsize=10.0, fontweight="bold", color=sac_col)
  elseif !(i in py_x)
    text(i, 0.0, "NR", horizontalalignment="center", verticalalignment="bottom", fontsize=10.0, fontweight="bold", color=py_col)
  end
end

# label with true ObsPy read time
text(6, 120.0, @sprintf("%.2f ms ", py_t[6]), horizontalalignment="center", verticalalignment="top", fontsize=10.0, fontweight="bold", color=[0.0, 0.0, 0.0], rotation=90.0)

# label with true Julia read time
text(1.0-width, ju_t[1], @sprintf(" %.2f ms", ju_t[1]), horizontalalignment="center", verticalalignment="bottom", fontsize=10.0, fontweight="bold", color=[0.0, 0.0, 0.0], rotation=90.0)
text(7.0-width, ju_t[7], @sprintf(" %.2f ms", ju_t[7]), horizontalalignment="center", verticalalignment="bottom", fontsize=10.0, fontweight="bold", color=[0.0, 0.0, 0.0], rotation=90.0)

PyPlot.xlim([0.5, length(xl)+0.5])
PyPlot.ylim([0.0, 120.0])
PyPlot.ylabel("Median Read Time [ms], 100 trials", fontweight="bold", fontsize=12.0, family="serif", color="black")
PyPlot.setp(gca().get_yticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.setp(gca().get_xticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.xticks(x, xl)
PyPlot.legend()
savefig("time_hist.png", dpi=300, format="png", transparent=false, frameon=false)

# ============================================================================
# Third histogram: All SeisIO read times and sizes
fig3 = PyPlot.figure(figsize=[8.0, 8.0], dpi=300)

ax3 = PyPlot.axes([0.52, 0.10, 0.46, 0.85])
width = 0.45
rects3 = ax3.barh(X .- 0.5*width, file_size, width, label=sz_label, color=sac_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
rects1 = ax3.barh(X .+ 0.5*width, M[:, 4], width, label=ju_label, color=ju_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
for i = 1:N
  text(1.1*mem_min, X[i] - 0.5*width, formats[i], horizontalalignment="left", verticalalignment="center", fontsize=8.0, fontweight="bold")
end

PyPlot.xlim([mem_min, 50.0])
PyPlot.xlabel("Memory [MB]", fontweight="bold", fontsize=12.0, family="serif", color="black")
PyPlot.setp(gca().get_yticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.setp(gca().get_xticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.ylim(N+0.5, 0.5)
PyPlot.yticks([], "")
PyPlot.legend()

ax4 = PyPlot.axes([0.02, 0.10, 0.46, 0.85])
t_max = maximum(M[:,6])
width = 1.0
rects1 = ax4.barh(X, M[:, 6], width, label=ju_label, color=ju_col, linewidth=1, edgecolor=[0.0, 0.0, 0.0], log=true)
text(1.1*t_min, X[1], formats[1], horizontalalignment="left", verticalalignment="center", fontsize=10.0, fontweight="bold")
for i = 2:N
  text(1.1*t_min, X[i], formats[i], horizontalalignment="left", verticalalignment="center", fontsize=10.0, fontweight="bold", color=[1.0, 1.0, 1.0])
end

PyPlot.xlim([0.9*t_min, 300.0])
PyPlot.xlabel("Median read time [ms], 100 trials", fontweight="bold", fontsize=12.0, family="serif", color="black")
PyPlot.setp(gca().get_yticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.setp(gca().get_xticklabels(), fontsize=10.0, color="black", fontweight="bold", family="serif")
PyPlot.ylim(N+0.5, 0.5)
PyPlot.yticks([], "")

savefig("raw_benchmarks.png", dpi=300, format="png", transparent=false, frameon=false)
