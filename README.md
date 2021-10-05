# LexicalGravityExperimental

This is a repo for optiming code that calculates the Lexical Gravity measure by Daudaravicius et al (2004).

Here is the formula that corresponds to the measure:

**G(w1,w2)=log((f(w1,w2) \* n(w1)/f(w1))) + log((f(w1,w2) \* n'(w2)/f(w2)))**

There are 2 files: the first has the non-performant tries I made and the second one has the performant pieces of code based on the `ngramizenew()` and `everygram()` of `TextAnalysis.jl`.





