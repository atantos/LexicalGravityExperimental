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

Another thing I would prefer to use is Julia 1.8's new feature, `eachsplit`.  Because we are splitting the whole corpus into lines, the resulting vector would potentially require a lot of memory to store.  Therefore, for no significant cost to the run-time, we use `eachsplit` to iterate over the splits of the corpus.  That said...if you're not worried about memory, feel free to change it back to using `split`.

This function produces the same code as `get_ngrams2`, but is a bit faster.  Benchmarking results:
```julia
julia> @btime get_ngrams(s, 3);
  9.318 s (29623167 allocations: 2.38 GiB)

julia> @benchmark get_ngrams(s, 3)
BenchmarkTools.Trial: 1 sample with 1 evaluation.
 Single result which took 8.966 s (6.63% GC) to evaluate,
 with a memory estimate of 2.38 GiB, over 29623167 allocations.
```

## `get_ngrams_dictionary`

The `get_ngrams_dictionary()` function  returns a dictionary of type `Dictionary`, implemented by `Dictionary.jl`. Benchmarking results do not show a big difference, although there is a slight improvement on time and allocations, although am not so sure how these changes will scale. I guess we would need to check with far more data to be able to say something more definitive. However, even if there is no statistically significant difference in the performance for bigger data, I am confident that by using the `Dictionary` type, things are much more convenient, as far as I saw.

```julia
julia> @btime get_ngrams(s,3)
  6.842 s (29623167 allocations: 2.38 GiB)
Dict{String, Int64} with 699809 entries:
  "a sharp pull"          => 1
  "was a time"            => 1
  "Boris to tell"         => 1
  ", my coachman"         => 1
  "morning finding fault" => 1
  "countess watched the"  => 1
  ⋮                       => ⋮
  
julia> @btime get_ngrams2(s,3)  
  6.454 s (29623188 allocations: 2.33 GiB)
699809-element Dictionary{String, Int64}
       "The Project Gutenberg" │ 1
     "Project Gutenberg EBook" │ 5
          "Gutenberg EBook of" │ 5
                             ⋮ │ ⋮
  "PROJECT GUTENBERG LITERARY" │ 1
  "GUTENBERG LITERARY ARCHIVE" │ 1
 "LITERARY ARCHIVE FOUNDATION" │ 1
```


## `get_ngrams_alt`

This function will return a `Dict`, similar to above, but where the keys are `Tuple`s of `String`s:
```julia
("proportion", "of", "cases")        => 7
("shouts", "of", "the")              => 4
("reports", ",", "while")            => 1
("of", ",", "364")                   => 2
("no", "reply", ".")                 => 7
  ⋮                                  => ⋮
```

## `get_ngrams_dataframe`

This function takes in a string and returns a dataframe. I added a line where I delete all commas from the text. The difference is not big for a 1 million string but not small either in terms of speed and result quality. Commas do not add much meaning to the string's info plus they add 500 more rows to the df, in our case.

Here is the first version of the function letting commas in:

```julia
julia> @btime get_ngrams_dataframe(str, 3)
  9.102 s (49959014 allocations: 2.94 GiB)
699809×5 DataFrame
    Row │ context                    w1          w2          w3           count 
        │ String                     String      String      String       Int64 ────────┼───────────────────────────────────────────────────────────────────────
      1 │ proportion of cases        proportion  of          cases            7      2 │ shouts of the              shouts      of          the              4
      3 │ reports , while            reports     ,           while            1
   ⋮    │             ⋮                  ⋮           ⋮            ⋮         ⋮
 699807 │ through an aperture        through     an          aperture         1
 699808 │ leave his study            leave       his         study            1
 699809 │ and resumed his            and         resumed     his              1
                                                             699803 rows omitted
```

Here is the version with the deleted commas:

```julia
julia> @btime get_ngrams_dataframe(str, 3)
  8.911 s (49521361 allocations: 2.86 GiB)
689409×5 DataFrame
    Row │ context                    w1           w2          w3           count 
        │ String                     String       String      String       Int64 ────────┼────────────────────────────────────────────────────────────────────────
      1 │ proportion of cases        proportion   of          cases            7      2 │ association of business    association  of          business         1
      3 │ shouts of the              shouts       of          the              4
   ⋮    │             ⋮                   ⋮           ⋮            ⋮         ⋮
 689407 │ leave his study            leave        his         study            1
 689408 │ and resumed his            and          resumed     his              1
 689409 │ President 264 ff.          President    264         ff.              1
                                                              689403 rows omitted
```

