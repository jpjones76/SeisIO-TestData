function nice_disp(R::Array{Union{Int64,Float64},2})
  N = size(R,1)
  Rs = Array{String,1}(undef, N+1)
  Rs[1] = @sprintf("%13s %30s %9s %9s %9s %8s %8s %8s %8s %4s", "Format", "Filename",
      "Opts", "Sz_[MB]", "Mem_[MB]", "Ovh_[%]", "Allocs", "T_[ms]", "GC_[%]", "N")
  for n = 1:N
    filename = splitdir(tests[n,1])[2]
    Rs[n+1] = @sprintf( "%13s %30s %9s %9.2f %9.2f %7.2f%% %8i %8.2f %7.2f%% %4i",
      tests[n,2], filename, tests[n,3], R[n,1], R[n,2], R[n,3], R[n,4], R[n,5], R[n,6], R[n,7] )
  end

  printstyled(Rs[1]*"\n", bold=true, color=:green)
  for i = 2:size(Rs,1)
    try
      println(Rs[i])
    catch
    end
  end

  println("")
  for i = 1:length(opts_guide)
    println(opts_guide[i])
  end
  return nothing
end
