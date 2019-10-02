# Prereqs:
# conda install pytest memory_profiler pyasdf
# conda install -c conda-forge pytest-benchmark # NOT NEEDED
import numpy as np
import glob
import gc
import os
import sys
import obspy
import pyasdf
from obspy import read
from obspy.io.ascii.core import _read_slist as read_slist
from memory_profiler import memory_usage
# from recipe_546530_1 import asizeof
from timeit import default_timer as timer
from time import sleep
from sys import getsizeof

def rasdf(file, path, tag):
    ds = pyasdf.ASDFDataSet(file, mpi=False, mode='r')
    tr = ds.waveforms[path][tag]
    return tr

def rslist(s):
    tr = read_slist(s)
    return tr

def get_obj_size(obj):
    marked = {id(obj)}
    obj_q = [obj]
    sz = 0

    while obj_q:
        sz += sum(map(sys.getsizeof, obj_q))

        # Lookup all the object referred to by the object in obj_q.
        # See: https://docs.python.org/3.7/library/gc.html#gc.get_referents
        all_refr = ((id(o), o) for o in gc.get_referents(*obj_q))

        # Filter object that are already marked.
        # Using dict notation will prevent repeated objects.
        new_refr = {o_id: o for o_id, o in all_refr if o_id not in marked and not isinstance(o, type)}

        # The new obj_q will be the ones that were not marked,
        # and we will update marked with their ids so we will
        # not traverse them again.
        obj_q = new_refr.values()
        marked.update(new_refr.keys())

    return sz

n = 100
ascii_formats = ['SLIST', 'TSPAIR']
rubric =[["1day-1hz.ah",                    "AH",       "ok"],  # 0
         ["2days-40hz.h5",                  "ASDF",     "ok"],  # 1
         ["geo-tspair.csv",                 "TSPAIR",   "--"],  # 2 unsupported -- TSPAIR isn't GeoCSV
         ["1day-100hz.mseed",               "MSEED",    "ok"],  # 3
         ["../Restricted/SHW.UW.mseed",     "MSEED",    "ok"],  # 4
         ["1day-100hz.segy",                "PASSCAL",  "--"],  # 5 unsupported -- SU SEG Y != PASSCAL SEG Y
         ["1day-100hz.sac",                 "SAC",      "ok"],  # 6
         ["1h-62.5hz.slist",                "SLIST",    "ok"],  # 7
         ["../Restricted/10081701.WVP",     "SUDS",     "--"],  # 8 unsupported
         ["99011116541W",                   "UW",       "--"],  # 9 unsupported
         ["../Restricted/2014092709*.cnt",  "WIN",      "--"]   # 10 fails: ObsPy recognizes files as valid but reads no trace data and doesn't support wildcards.
         ]
Ntests = len(rubric)
T = np.zeros((Ntests, n, 3), dtype=float)
# 0 size
# 1 memory
# 2 time
out = open('benchmarks_python.csv', 'w')

print("%13s %30s %9s %9s %9s %9s" % ('Format', 'File(s)', 'Sz_[MB]', 'Mem_[MB]', 'Ovh_[%]', 'T_[ms]'))
path = os.path.abspath('../')
for j in range(0, Ntests):
    if rubric[j][2] == 'ok':
        for i in range(0, n):
            s = path + '/' + rubric[j][0]
            fmt = rubric[j][1]
            if j == 1:
                sta = 'CI.SDD'
                tag = 'CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-09T00:00:00__hhz_'
                T[j,i,1] = memory_usage((rasdf, (s, sta, tag)), include_children=True, max_usage=True)[0]
                ts = timer()
                rt = rasdf(s, sta, tag)
                te = timer()
            # elif j == 11:
            #     T[j,i,1] = memory_usage((read_slist, (s,), {'check-compression' : False}), include_children=True, max_usage=True)[0]
            #     ts = timer()
            #     rt = read_slist(s)
            #     te = timer()
            else:
                T[j,i,1] = memory_usage((read, (s,), {'format' : fmt, 'check-compression' : False}), include_children=True, max_usage=True)[0]
                ts = timer()
                rt = read(s, format=fmt)
                te = timer()
            T[j,i,0] = get_obj_size(rt)/(1024**2)

            # the object size function above doesn't track this accurately for some reason
            if fmt in ascii_formats:
                T[j,i,0] += (8*len(rt.traces[0].data)/(1024**2))

            T[j,i,2] = (te-ts)*1000.0
            gc.collect()

        t = T[j,:,:]
        m = np.median(t, axis=0)
        print('%13s %30s %9.2f %9.2f %9.2f %9.2f'% (fmt, rubric[j][0], m[0], m[1], 100.0*(m[1]/m[0]-1.0), m[2]))
        out.write('%s;%s;%f;%f;%f;%f\n'% (fmt, rubric[j][0], m[0], m[1], 100.0*(m[1]/m[0]-1.0), m[2]))

out.close()
# find these with:
# import inspect
# inspect(obspy.io.sac.core)
# ...etc
# Using read functions directly
# ==========================================
# from obspy.io.ah.core import _read_ah1 as read_ah1
# from obspy.io.sac.core import _read_sac as read_sac
# from obspy.io.segy.core import _read_segy as read_segy
# from obspy.io.segy.core import _read_su_file as read_su
# from obspy.io.mseed.core import _read_mseed as read_mseed
# from obspy.io.win.core import _read_win as read_win

# from obspy.io.ascii.core import _read_tspair as read_tspair



# def rah():
#     return read('../test/SampleFiles/lhz.ah', format="AH")
# def rmseed1():
#     # return read_mseed('../test/SampleFiles/one_day.mseed')
#     return read('../test/SampleFiles/one_day.mseed', format="MSEED")
# def rmseed2():
#     return read('../test/SampleFiles/Restricted/SHW.UW.mseed', format="MSEED")
# def rpasscal(s):
#     x = read_su(s, endian='<', unpack_headers=False)
#     stream = obspy.Stream()
#     endian = x.traces[0].endian
#     for tr in x.traces:
#         trace = obspy.Trace()
#         stream.append(trace)
#         trace.stats.su = obspy.core.AttribDict()
#         header = obspy.io.segy.core.LazyTraceHeaderAttribDict(tr.header.unpacked_header, tr.header.endian)
#         trace.stats.su.trace_header = header
#         trace.stats.su.endian = endian
#         tr_header = trace.stats.su.trace_header
#         if tr_header.sample_interval_in_ms_for_this_trace > 0:
#             trace.stats.delta = \
#                 float(tr.header.sample_interval_in_ms_for_this_trace) / \
#                 1E6
#         if tr_header.year_data_recorded > 0:
#             year = tr_header.year_data_recorded
#             if year < 100:
#                 if year < 30:
#                     year += 2000
#                 else:
#                     year += 1900
#             julday = tr_header.day_of_year
#             julday = tr_header.day_of_year
#             hour = tr_header.hour_of_day
#             minute = tr_header.minute_of_hour
#             second = tr_header.second_of_minute
#             trace.stats.starttime = obspy.UTCDateTime(
#                 year=year, julday=julday, hour=hour, minute=minute,
#                 second=second)
#     return stream
# def rsac():
#     return read('../test/SampleFiles/one_day.sac', format="SAC")
# def rsegy():
#     return read_segy('../test/SampleFiles/test_PASSCAL.segy')
# def rtspair():
#     return read_tspair(s)

# def rwin():
#     path = os.path.abspath('../test/SampleFiles/Restricted')
#     files = glob.glob(path + "/2014092709*.cnt")
#     tr = read_win(files[0])
#     files.pop(0)
#     for file in files:
#         tr += read_win(file)
#     return tr
# ==========================================
