using WordTokenizers, Dictionaries

include("utils.jl")

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
            if j > 1
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
            j = gettoken(bigram_tokens, ngram)[2][2]
            if j > 1
                @inbounds Dictionaries._values(bigram_tokens)[j] += 1
            else
                @inbounds set!(bigram_tokens, ngram, 1)
            end
        end
    end
    return bigram_tokens
end

function get_ngrams_alt(str::S, window_size::Int) where {S <: AbstractString}
    str = replace(str, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))
    str = WordTokenizers.postproc_splits(str)
    
    bigram_tokens = Dict{NTuple{window_size, String}, Int}()
    
    for sentence in eachsplit(str, '\n')
        words = tokenize(sentence)
        max_i = length(words) - window_size + 1
        for i in 1:max_i
            ngram = ntuple(j -> words[i + j], window_size)
            k = Base.ht_keyindex2!(bigram_tokens, ngram)
            if k > 1
                @inbounds bigram_tokens.vals[k] += 1
            else
                @inbounds Base._setindex!(bigram_tokens, 1, ngram, -k)
            end
        end
    end
    return bigram_tokens
end
