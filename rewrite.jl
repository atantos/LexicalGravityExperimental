using WordTokenizers
using Dictionaries
using DataFrames

include("utils.jl") # this file contains code for `eachsplit` while we wait for 1.8 to come out...

# The big_text.txt is on a separate file you of the repo.
s = read("big_text.txt", String);

#= 
A new version of creating a df out of ngrams in separate columns initating empty df and using push!().
=#
function get_ngrams_df(str::S, window_size::Int) where {S <: AbstractString}
    str = replace(str, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))
    # Replacing the commas with spaces.
    str = replace(str, r"([a-z\s]*),([\sa-z]+)" => Base.SubstitutionString("\\1\\2"))
        
    str = WordTokenizers.postproc_splits(str)
    
    bigram_df = DataFrame(fill(String[], window_size), "word".*string.(1:window_size))
    
    for sentence in eachsplit(str, '\n')
        words = tokenize(sentence)
        max_i = length(words) - window_size + 1
        for i in 1:max_i
            ngram = words[i:(i + window_size - 1)]
            push!(bigram_df, ngram)
        end
    end
    return bigram_df
end


# Jake's version with a disctionary of ngrams
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
