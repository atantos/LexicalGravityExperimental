# NOTE: This file is only used until Julia 1.8 is released properly, and then we will have access to `eachsplit`...it's long awaited, considering how large some splitting is!

function eachsplit end

# Forcing specialization on `splitter` improves performance (roughly 30% decrease in runtime)
# and prevents a major invalidation risk (1550 MethodInstances)
struct SplitIterator{S<:AbstractString,F}
    str::S
    splitter::F
    limit::Int
    keepempty::Bool
end

Base.eltype(::Type{<:SplitIterator}) = SubString
Base.IteratorSize(::Type{<:SplitIterator{S, F}}) where {S <: AbstractString, F} = Base.SizeUnknown()

# i: the starting index of the substring to be extracted
# k: the starting index of the next substring to be extracted
# n: the number of splits returned so far; always less than iter.limit - 1 (1 for the rest)
function Base.iterate(iter::SplitIterator{S, F}, (i, k, n)=(firstindex(iter.str), firstindex(iter.str), 0)) where {S <: AbstractString, F}
    i - 1 > ncodeunits(iter.str)::Int && return nothing
    r = findnext(iter.splitter, iter.str, k)::Union{Nothing,Int,UnitRange{Int}}
    while r !== nothing && n != iter.limit - 1 && first(r) <= ncodeunits(iter.str)
        j, k = first(r), nextind(iter.str, last(r))::Int
        k_ = k <= j ? nextind(iter.str, j) : k
        if i < k
            substr = @inbounds SubString(iter.str, i, prevind(iter.str, j)::Int)
            (iter.keepempty || i < j) && return (substr, (k, k_, n + 1))
            i = k
        end
        k = k_
        r = findnext(iter.splitter, iter.str, k)::Union{Nothing,Int,UnitRange{Int}}
    end
    iter.keepempty || i <= ncodeunits(iter.str) || return nothing
    @inbounds (SubString(iter.str, i), (ncodeunits(iter.str) + 2, k, n + 1))
end

eachsplit(str::T, splitter; limit::Integer=0, keepempty::Bool=true) where {T<:AbstractString} =
    SplitIterator(str, splitter, limit, keepempty)

eachsplit(str::T, splitter::Union{Tuple{Vararg{AbstractChar}},AbstractVector{<:AbstractChar},Set{<:AbstractChar}};
          limit::Integer=0, keepempty=true) where {T<:AbstractString} =
    eachsplit(str, in(splitter); limit, keepempty)

eachsplit(str::T, splitter::AbstractChar; limit::Integer=0, keepempty=true) where {T<:AbstractString} =
    eachsplit(str, isequal(splitter); limit, keepempty)

# a bit oddball, but standard behavior in Perl, Ruby & Python:
eachsplit(str::AbstractString; limit::Integer=0, keepempty=false) =
    eachsplit(str, isspace; limit, keepempty)

nothing_sentinel(i) = i == 0 ? nothing : i

# Line for being able to read in the UTF-8 encoded characters.
first_utf8_byte(c::Char) = (Base.bitcast(UInt32, c) >> 24) % UInt8

function Base.findnext(pred::Base.Fix2{<:Union{typeof(isequal),typeof(==)},<:AbstractChar},
                  s::String, i::Integer)
    if i < 1 || i > sizeof(s)
        i == sizeof(s) + 1 && return nothing
        throw(BoundsError(s, i))
    end
    @inbounds isvalid(s, i) || string_index_err(s, i)
    c = pred.x
    c ≤ '\x7f' && return nothing_sentinel(_search(s, c % UInt8, i))
    while true
        i = _search(s, first_utf8_byte(c), i)
        i == 0 && return nothing
        pred(s[i]) && return i
        i = nextind(s, i)
    end
end

Base.findfirst(pred::Base.Fix2{<:Union{typeof(isequal),typeof(==)},<:Union{Int8,UInt8}}, a::Base.ByteArray) =
    nothing_sentinel(_search(a, pred.x))

Base.findnext(pred::Base.Fix2{<:Union{typeof(isequal),typeof(==)},<:Union{Int8,UInt8}}, a::Base.ByteArray, i::Integer) =
    nothing_sentinel(_search(a, pred.x, i))
    
function _search(a::Union{String,Base.ByteArray}, b::Union{Int8,UInt8}, i::Integer = 1)
    if i < 1
        throw(BoundsError(a, i))
    end
    n = sizeof(a)
    if i > n
        return i == n+1 ? 0 : throw(BoundsError(a, i))
    end
    p = pointer(a)
    q = GC.@preserve a ccall(:memchr, Ptr{UInt8}, (Ptr{UInt8}, Int32, Csize_t), p+i-1, b, n-i+1)
    return q == C_NULL ? 0 : Int(q-p+1)
end

function _search(a::Base.ByteArray, b::AbstractChar, i::Integer = 1)
    if isascii(b)
        _search(a,UInt8(b),i)
    else
        _search(a,unsafe_wrap(Vector{UInt8},string(b)),i).start
    end
end
