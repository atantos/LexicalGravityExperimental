#= NOTE: These functions are here for my visibility

function rulebased_split_sentences(sentences)
    sentences = replace(sentences, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))

    sentences = WordTokenizers.postproc_splits(sentences)
    split(sentences, "\n")
end
function everygram(seq::Vector{T}; min_len::Int=1, max_len::Int=-1) where { T <: AbstractString}
    ngram = []
    if max_len == -1
        max_len = length(seq)
    end
    for n in range(min_len, stop=max_len)
        temp = ngramizenew(seq, n)
        ngram = append!(ngram, temp)
    end
    return(ngram)
end
function ngramizenew(words::Vector{T}, nlist::Integer...) where { T <: AbstractString}
    n_words = length(words)
    tokens = []
    for n in nlist
        for index in 1:(n_words - n + 1)
            token = join(words[index:(index + n - 1)], " ")
            push!(tokens,token)
        end
    end
    return tokens
end
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
=#

# The big_text.txt is on a separate file you of the repo.
s = read("big_text.txt", String);
# sentences_array = tokenize.(rulebased_split_sentences(s));

using WordTokenizers

function get_ngrams(str::S, window_size::Int) where {S <: AbstractString}
    bigram_tokens = Dict{String, Int}()
    sentences_array = rulebased_split_sentences(str)
    for sentence in sentences_array
        words = tokenize(sentence)
        nwords = length(words)
        for i in 1:(nwords - window_size + 1)
            ngram = join(words[i:(i + window_size - 1)], " ")
            bigram_tokens[ngram] = get(bigram_tokens, ngram, 0) + 1
        end
    end
    return bigram_tokens
end

_bigrams = get_ngrams(s, 3)
