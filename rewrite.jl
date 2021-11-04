using WordTokenizers
using Dictionaries
using DataFrames

include("utils.jl") # this file contains code for `eachsplit` while we wait for 1.8 to come out...

# The big_text.txt is on a separate file you of the repo.
s = read("big_text.txt", String);

function get_ngrams(str::S, window_size::Int) where {S <: AbstractString}
    str = replace(str, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))
    str = WordTokenizers.postproc_splits(str)
    
    
    bigram_tokens = Dict{String, Int}()
    
    for sentence in eachsplit(str, '\n')
        words = tokenize(sentence)
        max_i = length(words) - window_size + 1
        for i in 1:max_i
            ngram = join(words[i:(i + window_size - 1)], " ")
            j = Base.ht_keyindex2!(bigram_tokens, ngram)
            if j > 0
                @inbounds bigram_tokens.vals[j] += 1
            else
                @inbounds Base._setindex!(bigram_tokens, 1, ngram, -j)
            end
        end
    end
    return bigram_tokens
end

function get_ngrams_dataframe(str::S, window_size::Int) where {S <: AbstractString}
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

# Here is the version for using the Dictionary data type. Essentially, I used the Dictionary's API for tokens and indices.
function get_ngrams_dictionary(str::S, window_size::Int) where {S <: AbstractString}
    str = replace(str, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))
    str = WordTokenizers.postproc_splits(str)
    
    bigram_tokens = Dictionary{String, Int}()
    
    for sentence in split(str, '\n')
        words = tokenize(sentence)
        max_i = length(words) - window_size + 1
        for i in 1:max_i
            ngram = join(words[i:(i + window_size - 1)], " ")
            hasindex, t = gettoken(bigram_tokens, ngram)
            if hasindex
                @inbounds Dictionaries._values(bigram_tokens)[last(t)] += 1
            else
                @inbounds set!(bigram_tokens, ngram, 1)
            end
        end
    end
    
    return bigram_tokens
end
