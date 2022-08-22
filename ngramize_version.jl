#======================#
#======================#

# The big_text.txt is on a separate file you of the repo.
# s = read("/Users/atantos/Desktop/big_text.txt", String);

function get_ngrams(str::S, window_size::Int) where {S <: AbstractString}
    str = replace(str, r"([?!.])\s" => Base.SubstitutionString("\\1\n"))
    # Replacing the commas with spaces.
    str = replace(str, r"([a-z\s]*),([\sa-z]+)" => Base.SubstitutionString("\\1\\2"))
        
    str = WordTokenizers.postproc_splits(str)
    
    bigram_df = DataFrame(fill(String[], window_size), "word".*string.(collect(1:window_size)))
    
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
