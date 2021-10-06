# Benchmarking Results

All functions were run once before 

Initialisation: `s = read("big_english.txt", String)`

## `get_word_pairs`

This returns a `6217852-element Vector{Tuple{String, String, String}}`.

For example:
```julia
 ("The", "Project", "f")
 ("The", "Gutenberg", "f")
 ("The", "EBook", "f")
 ("Project", "The", "b")
 ("Project", "Gutenberg", "f")
 ⋮
```

Benchmarking results:
```julia
julia> @btime get_word_pairs(s, 3);
  1.371 ms (1 allocation: 32 bytes)

julia> @benchmark get_word_pairs(s, 3)
BenchmarkTools.Trial: 2801 samples with 1 evaluation.
 Range (min … max):  1.356 ms … 52.053 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     1.555 ms              ┊ GC (median):    0.00%
 Time  (mean ± σ):   1.763 ms ±  1.527 ms  ┊ GC (mean ± σ):  0.00% ± 0.00%

   ▁██▇▆▅▄▄▃▂▂▁▁▁  ▁                                         ▁
  ▆████████████████████▆▇██▅▇▆▇▅▆▆▅▆▅▄▆▄▄▅▇▅▁▅▅▄▄▃▁▁▁▅▁▄▄▁▄▆ █
  1.36 ms      Histogram: log(frequency) by time     4.06 ms <

 Memory estimate: 32 bytes, allocs estimate: 1.
```

## `get_word_pairs2`

Took too long (may review later).

## `get_ngrams2`

This returns a `Dict{String, Int64} with 699809 entries`.

For example:
```julia
  "a sharp pull"               => 1
  "was a time"                 => 1
  "Boris to tell"              => 1
  ", my coachman"              => 1
  "morning finding fault"      => 1
  ⋮                            => ⋮
```

Benchmarking results:
```julia
julia> @btime get_ngrams2(s, 3);
  11.821 s (30432359 allocations: 2.46 GiB)

julia> @benchmark get_ngrams2(s, 3)
BenchmarkTools.Trial: 1 sample with 1 evaluation.
 Single result which took 11.403 s (5.95% GC) to evaluate,
 with a memory estimate of 2.46 GiB, over 30432359 allocations.
```

## `get_ngrams` 

This is my attempt at improving performance.

The first thing I did is merge `ngramizenew` and `everygram`, and `get_ngrams`, as there were some parts of these functions that were unnecessary if we are going to use them together anyway (e.g., temporary arrays which we then append, and computing the length of the input multiple times, and within a look effectively.  As we are also always setting `min_len` and `max_len` to the same number, I made it a single parameter.  Finally, I made this function slightly more type-stable.

With regard to the `get_ngrams` function specifically&mdash;which was based on your `get_ngrams2` function&mdash;I merged two loops, as the initial `Vector` was only used once, which was in the construction of the `Dict` in the second loop, in which I also created the ngrams.