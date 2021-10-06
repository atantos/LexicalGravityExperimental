using WordTokenizers

# The big_text.txt is on a separate file you of the repo.
s = read("big_text.txt", String);

function get_ngrams(str::S, window_size::Int) where {S <: AbstractString}
    bigram_tokens = Dict{String, Int}()
    sentences_array = rulebased_split_sentences(str)
    for sentence in sentences_array
        words = tokenize(sentence)
        nwords = length(words)
        for i in 1:(nwords - window_size + 1)
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

_bigrams = get_ngrams(s, 3)
