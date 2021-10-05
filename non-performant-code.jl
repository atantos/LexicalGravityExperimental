using WordTokenizers
using Memoize
using DataFrames
using DataFramesMeta
using Pipe
using TextAnalysis
using Strs
using TidyStanza

const Strings = Union{Str,String,StringDocument,Vector{String},Vector{Vector{String}}}

str = """
tokenize and split_sentences are configurable functions that call one of the tokenizers or sentence splitters defined below. They have sensible defaults set, but you can override the method used by calling set_tokenizer(func) or set_sentence_splitter(func) passing in your preferred function func from the list below (or from elsewhere) Configuring them this way will throw up a method overwritten warning, and trigger recompilation of any methods that use them.
This means if you are using a package that uses WordTokenizers.jl to do tokenization/sentence splitting via the default methods, changing the tokenizer/splitter will change the behavior of that package. This is a feature of CorpusLoaders.jl. If as a package author you don't want to allow the user to change the tokenizer in this way, you should use the tokenizer you want explicitly, rather than using the tokenize method.
"""
@memoize sentence_split(text::String) = tokenize.(rulebased_split_sentences(text))

#=
 Takes the list of words in `sentence`, returns a list of all training pairs.
 The first word of each pair is the "input word", and the second word is a
 context word. The number of context words for each input word is (at most)
 2 * window_size. 
 =#
"""
    get_word_pairs(text, window_size)
    
    Get the word pairs for all words in a text within the window span of length window_size.


# Examples
```julia-repl
julia> get_word_pairs(text, window_size)

```   
"""
@memoize function get_word_pairs(text, window_size)

    word_pairs = Vector{Tuple{String,String,String}}()
    sentences_array = tokenize.(rulebased_split_sentences(text))
    # Looping through the array of words in sentences_array, that is Vector{Vector{String}}, from all sentences 
    for sentence_words in sentences_array
        print("ok! ")
        # For each input word in the sentence...
        for input_i = 1:1:length(sentence_words)

            # Calculate the index of the first context word.
            # Use `max` to ensure the index is 0 or greater.
            cntxt_start_i = max(input_i - window_size, 1)

            # Calculate the index of the last context word.
            # Use `min` to ensure the index is not past the end of the sentence.
            cntxt_end_i = min(input_i + window_size, length(sentence_words))
            # For each context word...

            for cntxt_i = cntxt_start_i:1:cntxt_end_i

                if cntxt_i == input_i
                    continue
                elseif cntxt_i < input_i

                    push!(
                        word_pairs,
                        (sentence_words[input_i], sentence_words[cntxt_i], "b"),
                    )
                else
                    push!(
                        word_pairs,
                        (sentence_words[input_i], sentence_words[cntxt_i], "f"),
                    )
                end
            end

        end
    end
    return word_pairs
end

words = collect(Iterators.flatten(sentences_array));

unique_words = unique(words)

@memoize function get_word_pairs2()
    n = 0
    global final_fourgrams_all_words = Array{Array{Array{String},1},1}()
    Threads.@threads for word in unique_words
        print(n += 1)
        words_index_within_sentences = Folds.findall.( x -> word == x, sentences_array)
        # Returns the non-empty vectors with the positions of the word in the sentences that is found in.
        words_index_array = Folds.collect(s for s in words_index_within_sentences if !all(isempty.(s)))

        # returns an array with the senteneces that a word is found.
        words_sentences_index = Folds.findall(x -> !isempty(x) , words_index_within_sentences)

        global all_fourgrams_of_a_word = Array{Array{String}, 1}()
        Threads.@threads for amem in Folds.collect(zip(words_sentences_index, words_index_array))
            for occurence in amem[2]
                # println("======")
                # println(amem[1])
                # println(length(sentences_array[amem[1]]))
                # println(amem[2])
                # println(occurence)
                #println(sentences_array[amem[1]][occurence:(occurence+3)])
                trigrams_f = sentences_array[amem[1]][occurence:min(occurence + 2, length(sentences_array[amem[1]]))]
                trigrams_b = sentences_array[amem[1]][max(occurence - 2, 1):occurence]
                push!(all_fourgrams_of_a_word, trigrams_f, trigrams_b)
            end
        end
        push!(final_fourgrams_all_words, all_fourgrams_of_a_word)
    end
    final_fourgrams_all_words
end


# frequency with TextAnalysis
freq_words_dict = TextAnalysis.frequencies(words)


"""
    sort_word_pairs(word_pairs)

    Apply transformation to tuples using sort() and here is the criterion; 
namely to sort by the first and then the third element of the tuple. The third element determines the mode.

# Examples
```julia-repl
julia>

```   
"""
@memoize function sort_word_pairs(text, window_size)
    word_pairs = get_word_pairs(text, window_size)
    mylt((x1, y1, z1)) = (x1, z1)
    sorted = sort(word_pairs, by = mylt)
    sorted
end

"""
    get_window(word, sorted, mode = "f")

By default the window span that is returned is for when the word is 
    the word1; namely the word on the left. 

# Examples
```julia-repl
julia>

```
"""
@memoize function get_window(word, text, window_size, mode = "f")
    [ amem for amem in sort_word_pairs(text, window_size) if amem[1] .== word && amem[3] == mode]
end

#======================================================#
# From that point on I have functions that calculate the n(w1), f(w1,w2), etc. 
# I am not sure if you can make sense out of them. They are not documented at all.   
#======================================================#
            
"""
    get_nword(word, text, window_size; mode = "f")

This function takes a word of type String and a Vector{Tuple{String, String, String}} and returns the number
distinct words followed of preceded by word in a window span window_span. sort_word_pairs().
        
# Examples
```julia-repl
julia>

```
"""
            
@memoize function get_nword(word, text, window_size; mode = "f")
              length(unique(get_window(word, text, window_size, mode)))
            end

"""
    get_fword(word, text, window_size; mode = "f")

    Get the token frequency of words that follow or precede `word` in `text` within a window span of window_size. The mode is by default "f"
    for "forward". It can be set with "b" for looking backwards and retrieving the token frequency of the words
        that precede.

# Examples
```julia-repl
julia>

```
"""
@memoize function get_fword(word, text, window_size; mode = "f")
                length(get_window(word, text, window_size, mode))
                end

"""
    get_alln(text)

This function takes a word of type String and a Vector{Tuple{String, String, String}} that is output by sort_word_pairs().
        
# Examples
```julia-repl
julia>

```
"""
@memoize function get_all_n_f(text, window_size, mode = "f")

    allns = DataFrame([String[], Int64[], Int64[]], [:word, :n, :f])
    for sentence in sentence_split(text)
        for word in sentence
            push!(allns, (word = word, n = get_nword(word, text, window_size, mode=mode), f = get_fword(word, text, window_size, mode=mode)))
        end
    end
    allns
end

"""
    joint_freq(word1, word2, window_size, text)
                
                
                This function takes a word of type String and a Vector{Tuple{String, String, String}} that is output by sort_word_pairs().
        
# Examples
```julia-repl
julia>

```
"""
@memoize function joint_freq(word1, word2, window_size, text)
    length([word2 for amem in get_window(word1, text, window_size) if word2 == amem[2]])
end

@memoize function G(word1, word2, window_size, text)
    G = log(joint_freq(word1, word2, window_size, text)*get_nword(word1, text, window_size, mode = "f")/get_fword(word1, text, window_size)) + log(joint_freq(word1, word2, window_size, text)*get_nword(word1, text, window_size, mode = "b")/get_fword(word2, text, window_size))
    G
end
