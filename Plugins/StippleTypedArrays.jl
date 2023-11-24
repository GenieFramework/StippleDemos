module StippleTypedArrays

using Stipple

export TypedArray

type_dict = LittleDict(
    UInt8 => "Uint8Array",
    UInt16 => "Uint16Array",
    UInt32 => "Uint32Array",
    Int8 => "Int8Array",
    Int16 => "Int16Array",
    Int32 => "Int32Array",
    Float32 => "Float32Array",
    Float64 => "Float64Array",
    Int64 => "BigInt64Array",
    UInt64 => "BigUint64Array",
)

struct TypedArray{T}
    array::Vector{T}
end

Base.setindex!(x::TypedArray, args...) = Base.setindex!(x.array, args...)
Base.getindex(x::TypedArray, args...) = Base.getindex(x.array, args...)

Base.convert(::Type{TypedArray}, v::AbstractVector{T}) where T = TypedArray{T}(convert(Vector{T}, v))
Base.convert(::Type{T}, ta::TypedArray) where T <: Union{AbstractVector, TypedArray}  = convert(T, ta.array)
Base.convert(::Type{TypedArray{T1}}, v::AbstractVector{T2}) where {T1, T2} = TypedArray{T1}(convert(Vector{T1}, v))

Stipple.render(ta::TypedArray{T}) where T = LittleDict(:typedArray => T, :array => ta.array)
Stipple.render(ta::TypedArray{T}) where T <: Int64 = LittleDict(:typedArray => T, :array => string.(ta.array))
Stipple.render(ta::TypedArray{T}) where T <: UInt64 = LittleDict(:typedArray => T, :array => string.(reinterpret(Int64, ta.array)))

Stipple.jsrender(ta::TypedArray{T}, args...) where T <: Real = JSONText("$(type_dict[T]).from($(json(ta.array)))")
Stipple.jsrender(ta::TypedArray{T}, args...) where T <: UInt64 = JSONText("$(type_dict[T]).from($(json(string.(ta.array))))")
Stipple.jsrender(ta::TypedArray{T}, args...) where T <: Int64 = JSONText("$(type_dict[T]).from($(json(string.(ta.array))))")
 
Stipple.stipple_parse(::Type{TypedArray{T}}, v::Vector) where T = TypedArray(Vector{T}(v))

Stipple.stipple_parse(T::Type{TypedArray{UInt64}}, v::Vector) = Stipple.stipple_parse(T, [v...])
Stipple.stipple_parse(::Type{TypedArray{UInt64}}, v::Vector{String}) = TypedArray(parse.(UInt64, v))
Stipple.stipple_parse(::Type{TypedArray{UInt64}}, v::Vector{T}) where T <: Number = TypedArray(Vector{UInt64}(v))

Stipple.stipple_parse(T::Type{TypedArray{Int64}}, v::Vector) = Stipple.stipple_parse(T, [v...])
Stipple.stipple_parse(::Type{TypedArray{Int64}}, v::Vector{String}) = TypedArray(parse.(Int64, v))
Stipple.stipple_parse(::Type{TypedArray{Int64}}, v::Vector{T}) where T <: Number = TypedArray(Vector{UInt64}(v))


js_revive_typedArray = """
    function (k, v) {
        if ( (typeof v==='object') && (v!=null) && (v.typedArray) ) {
            switch (v.typedArray) {
                case 'UInt8':   a = Uint8Array.from(v.array); break
                case 'UInt16':  a = Uint16Array.from(v.array); break
                case 'UInt32':  a = Uint32Array.from(v.array); break
                case 'UInt64':  a = BigUint64Array.from(v.array.map(BigInt)); break
                case 'Int8':    a = Int8Array.from(v.array); break
                case 'Int16':   a = Int16Array.from(v.array); break
                case 'Int32':   a = Int32Array.from(v.array); break
                case 'Int64':   a = BigInt64Array.from(v.array.map(BigInt)); break
                case 'Float32': a = Float32Array.from(v.array); break
                case 'Float64': a = Float64Array.from(v.array); break
                default: a = v.array
            }
            return a
        } else {
            return v
        }
    }
"""


function deps()
    [
        script("\n", [
            "    $atype.prototype['toJSON'] = function () { return $(startswith(atype, "Big") ? "this.toString().split(',')" : "Array.from(this)") };\n"
            for atype in values(type_dict)
        ])
        script(Stipple.js_add_reviver(js_revive_typedArray))
    ]
end

end