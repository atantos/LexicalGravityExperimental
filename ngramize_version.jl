#======================#
#======================#

# The big_text.txt is on a separate file you of the repo.
# s = read("big_text.txt", String);

function getngrams_df(str::S, window_size::Int) where {S <: AbstractString}
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


