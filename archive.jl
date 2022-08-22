

# This one uses a dataframe as a dictionary, so it is not very efficient...at all...
# it is more of a proof of concept than anything useful; I was wondering how a 
# dataframe would do if it were acting as a dictionary.
function get_ngrams_dataframe_alt(str::S, window_size::Int) where {S <: AbstractString}
    str = replace(str, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))
    # Replacing the commas with spaces.
    str = replace(str, r"([a-z\s]*),([\sa-z]+)" => Base.SubstitutionString("\\1\\2"))
    str = WordTokenizers.postproc_splits(str)
    
    ncols = window_size + 2
    bigram_tokens_df = DataFrame(Vector{Union{String, Int}}[(String[] for _ in 2:ncols)...,  Int[]], :auto) # 2:ncols == 1:(ncols - 1) == 1:(window_size + 1)
    rename!(bigram_tokens_df, Symbol[:context, (Symbol("w$i") for i in 1:window_size)..., :count])
    
    for sentence in eachsplit(str, '\n')
        words = tokenize(sentence)
        max_i = length(words) - window_size + 1
        for i in 1:max_i
            ngram = ntuple(j -> words[i + j - 1], window_size)
            ngram_str = join(ngram, ' ')
            # this method is probably not efficient, but we essentially use the dataframe as a dictionary
            # in this loop, we check that the current ngram is not in the dataframe
            # it _might_ be faster to check the last row first...but not entirely sure
            ngram_in_df = false
            for j in nrow(bigram_tokens_df):-1:1
                if bigram_tokens_df[j, :context] == ngram_str
                    ngram_in_df = true
                    bigram_tokens_df[j, :count] += 1
                    break
                end
            end
            if !ngram_in_df
                # we have not found this ngram in the dataframe, so we need to add it
                push!(bigram_tokens_df, (ngram_str, ngram..., 1))
            end
        end
    end
    
    return bigram_tokens_df
end


#= 
Older version of getting ngrams and converting them to dfs. (not so efficiently created)
Take a look at get_ngrams_df the ngramize_version.jl.
=#
function get_ngrams_df_old(str::S, window_size::Int) where {S <: AbstractString}
    str = replace(str, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))
    # Replacing the commas with spaces.
    str = replace(str, r"([a-z\s]*),([\sa-z]+)" => Base.SubstitutionString("\\1\\2"))
    str = WordTokenizers.postproc_splits(str)
    
    bigram_tokens = Dict{NTuple{window_size, String}, Int}()
    
    for sentence in eachsplit(str, '\n')
        words = tokenize(sentence)
        max_i = length(words) - window_size + 1
        for i in 1:max_i
            ngram = ntuple(j -> words[i + j - 1], window_size)
            k = Base.ht_keyindex2!(bigram_tokens, ngram)
            if k > 0
                @inbounds bigram_tokens.vals[k] += 1
            else
                @inbounds Base._setindex!(bigram_tokens, 1, ngram, -k)
            end
        end
    end
    
    bigram_tokens_df = DataFrame(Vector{Union{String, Int}}[(String[] for _ in 1:(window_size + 1))...,  Int[]], :auto)
    rename!(bigram_tokens_df, Symbol[:context, (Symbol("w$i") for i in 1:window_size)..., :count])
    
    for (tokens, _count) in bigram_tokens
        push!(bigram_tokens_df, (join(tokens, ' '), tokens..., _count))
    end
    
    return bigram_tokens_df
end

sentences_array = tokenize.(rulebased_split_sentences(s));

function get_ngrams2(str::AbstractString, window_size::Integer)
    sentences_array = rulebased_split_sentences(str)
    sentences_ngrams = Array{Array{String, 1}, 1}()
    for sentence in sentences_array
        words = tokenize(sentence)
        sent_gram = everygram(words, min_len=window_size, max_len=window_size)
        push!(sentences_ngrams, sent_gram)
    end
    bigram_tokens = Dict{String, Int}()
    for sentence_ngram in sentences_ngrams
        #ngrams = tokenize.(sentence_ngram)
        #println(ngrams)
        for ngram in sentence_ngram
            bigram_tokens[ngram] = get(bigram_tokens, ngram, 0) + 1
        end
    end
    bigram_tokens
end

bigrams_tokens = get_ngrams2(s, 3)

# Convert the dictionary to a dataframe (ask whether it is preferrable or to simply add it directly to a dataframe and not create a dictionar dict_ngrams)
df_ngrams = DataFrame(keys = collect(keys(bigrams_tokens)),
values = collect(values(bigrams_tokens)))

# split the column with the trigrams and select the 3 split columns and ignote the initial keys columns.  
df_ngrams_final =  @pipe df_ngrams |> transform(_, :keys =>
    ByRow(x -> get.(Ref(split(x, ' ')), 1:3, missing)) =>
    [:word1, :word2, :word3] ) |>
    relocate(_, :values, after = :word3) |>
    select(_, Not(:keys))

# Sorting the bigrams [w1, w2] by the nrow within a trigram.
@pipe df_ngrams_final |>
    groupby(_, [:word1, :word2]) |>
    combine(_, nrow) |>
    filter(:nrow => >=(5), _) |>
    sort(_, [:nrow], rev=true) 

# any bigram within the trigram with w1 as the first word and w2 as either the second or the third word.
function f(w1,w2)
    f_w1_w2 = @pipe df_ngrams_final |>
    filter( [:word1, :word2, :word3] => (x, y, z) -> (x == w1 && (y == w2 || z == w2)), _) |>
    combine(_, :values => sum)
    f_w1_w2 
end

# Getting the sum of bigram frequencies
function f(w)
    f_w = @pipe df_ngrams_final |>
    filter(:word1 => x -> x == w, _) |>
    combine(_, :values => sum)
    f_w
end


# sum(df_ngrams_final[df_ngrams_final[:,:word1] .== "of", :][!,:values])
# the number of distinct bigrams that w is inside.
function n(w)
    n_w = @pipe df_ngrams_final |>
    filter(:word1 => x -> x == w, _) |>
    nrow(_)
    n_w
end

# The final G is not implemented yet
function G(df_ngrams_final, w1,w2)
    @pipe df_ngrams_final |>
    log((f(w1,w2)*n(w1)/f(w1))) + log((f(w1,w2)*n'(w2)/f'(w2)))
end
