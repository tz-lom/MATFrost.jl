module _Types

export MATFrostArrayAbstract, MATFrostArrayEmpty, MATFrostArrayPrimitive, MATFrostArrayString, MATFrostArrayCell, MATFrostArrayStruct, MATFrostException, MATFrostConversionException, MATFrostIO

abstract type MATFrostArrayAbstract end

struct MATFrostArrayEmpty <: MATFrostArrayAbstract
end

struct MATFrostArrayPrimitive{T<:Number} <: MATFrostArrayAbstract
    dims::Vector{Int64}
    values::Vector{T}
end

struct MATFrostArrayString <: MATFrostArrayAbstract
    dims::Vector{Int64}
    values::Vector{String}
end

struct MATFrostArrayCell <: MATFrostArrayAbstract
    dims::Vector{Int64}
    values::Vector{MATFrostArrayAbstract}
end

struct MATFrostArrayStruct <: MATFrostArrayAbstract
    dims::Vector{Int64}
    fieldnames::Vector{Symbol}
    values::Vector{MATFrostArrayAbstract}
end

struct MATFrostException <: Exception 
    id::String
    message::String
end

struct MATFrostConversionException <: Exception
    id::String
    message::String
    stacktrace::Vector{Any}
end

struct MATFrostIO <: MATFrostArrayAbstract
    stream::UInt8 # 1 for stdout, 2 for stderr
    content::String 
end

end