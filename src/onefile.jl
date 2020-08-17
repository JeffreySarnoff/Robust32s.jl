#=
  to maintain the package intent correctly
     implicit construction of a Float64 does not require the target become a Float32

  to maintain the package intent correctly
    some primitive operations must be taken with respect to Float32

  to maintain the package intent correctly
     explicit construction of T requires the target become a Float32
=#

"""
    Robust32s

A module for robust Float32 computation.

Exports: `Robust32`, `ComplexR32`
"""
module Robust32s

export Robust32, ComplexR32

import Base: ==, !=, <, <=, >, >=, isless, isequal, +, -, *, \, /, ^,
             signbit, significand, exponent, sign, eps, inv, sqrt, cbrt, hypot, clamp, clamp!,
             min, max, minmax, frexp, ldexp, abs, copysign, flipsign, zero, one, iszero, isone,
             isfinite, issubnormal, isinf, isnan, float, floatmin, floatmax, maxintfloat, typemax, typemin
             
import Base.Math: abs2, acos, acosd, acosh, acot, acotd, acoth, acsc, acscd, acsch, asec, asecd, asech, 
                  asin, asind, asinh, atan, atand, atanh, cos, cosc, cosd, cosh, cospi, cot, cotd, coth,
                  csc, cscd, csch, deg2rad, evalpoly, exp, exp10, exp2, expm1,
                  log, log10, log1p, log2, mod2pi, modf, rad2deg, rem2pi, sec, secd, sech,
                  sin, sinc, sincos, sincospi, sincosd, sind, sinh, sinpi, tan, tand, tan

import LinearAlgebra: tr, det, transpose, transpose!, adjoint, adjoint!, cond
using LinearAlgebra

struct As64 end # internal use only

struct Robust32 <: AbstractFloat
    val::Float64
  
    Robust32(x::Float64) = new(Float64(Float32(x)))
    Robust32(::Type{As64}, x::Float64) = new(x)
end

value64(x::Robust32) = x.val
value32(x::Robust32) = Float32(x.val)

# internal use only
Rob32(x::Float64) = Robust32(As64, x)

Robust32(x::Robust32) = x # idempotency

Base.show(io::IO, x::Robust32) = show(io, value32(x))
Base.string(x::Robust32) = string(value32(x))

const ComplexR32 = Complex{Robust32}

value64(x::ComplexR32) = (value64(x.re), value64(x.im))
value32(x::ComplexR32) = (value32(x.re), value32(x.im))

Base.Float64(x::Robust32) = Float64(value32(x))
Base.convert(::Type{Float64}, x::Robust32) = Float64(x)
Base.promote_rule(::Type{Robust32}, ::Type{Float64}) = Robust32

for T in (:BigFloat, :Float32, :Float16)
  @eval begin
    Base.$T(x::Robust32) = $T(value32(x))
    Robust32(x::$T) = Rob32(Float64(Float32(x)))
    Base.convert(::Type{$T}, x::Robust32) = $T(x)
    Base.promote_rule(::Type{Robust32}, ::Type{$T}) = Robust32
  end
end

for T in (:BigInt, :Int128, :Int64, :Int32, :Int16, :Int8,
                   :UInt128, :UInt64, :UInt32, :UInt16, :UInt8)
  @eval begin
    Base.$T(x::Robust32) = $T(value32(x))
    Robust32(x::$T) = Rob32(Float64(Float32(x)))
    Base.convert(::Type{$T}, x::Robust32) = $T(x)
    Base.promote_rule(::Type{Robust32}, ::Type{$T}) = Robust32
  end
end

Base.convert(::Type{Rational{T}}, x::Robust32) where {T} = convert(Rational{T}, value32(x))
Base.convert(::Type{Rational}, x::Robust32) = convert(Rational{Int64}, x)
Base.promote_rule(::Type{Robust32}, ::Type{Rational}) = Robust32

const Robust32_0 = Rob32(0.0)
const Robust32_1 = Rob32(1.0)

Robust32(x::Bool) = x ? Robust32_1 : Robust32_0

Base.hash(x::Robust32, h::UInt64) = Base.hash(value32(x), h)

Base.decompose(x::Robust32) = Base.decompose(value32(x))
Base.precision(::Type{Robust32}) = Base.precision(Float32)
Base.rtoldefault(x::Robust32) = Base.rtoldefault(Float32(x))

for F in (:floatmin, :floatmax, :maxintfloat, :typemax, :typemin)
  @eval $F(::Type{Robust32}) = Robust32($F(Float32))
end

Base.eps(x::Robust32) = eps(value32(x))
Base.significand(x::Robust32) = significand(value32(x))
Base.exponent(x::Robust32) = exponent(value32(x))
Base.sign(x::Robust32) = exponent(value32(x))
Base.iszero(x::Robust32) = iszero(value32(x))
Base.isone(x::Robust32) = isone(value32(x))
Base.isfinite(x::Robust32) = isfinite(value32(x))
Base.issubnormal(x::Robust32) = issubnormal(value32(x))
Base.isinf(x::Robust32) = isinf(value64(x))
Base.isnan(x::Robust32) = isnan(value64(x))

Base.signbit(x::Robust32) = signbit(value32(x))

Base.zero(::Type{Robust32}) = Robust32_0
Base.one(::Type{Robust32}) = Robust32_1
Base.zero(x::Robust32) = zero(Robust32)
Base.one(x::Robust32) = one(Robust32)

Base.frexp(x::Robust32) = frexp(value32(x)) # ??????????? and ldexp

# include("provide.jl")
#=
   functions to enfold:
   organized by applicable signature.

   In these signature-based collections, the arguments to a given function share eltype.
=#

const scalar_functions_of_one_arg = map(Symbol, (
    abs, (-), 
    abs2, inv,
    deg2rad, rad2deg,
    mod2pi, rem2pi,
    sqrt, cbrt,
    exp, exp10, exp2, expm1,
    log, log10, log1p, log2,
    sin, sinpi, sinc, cos, cospi, cosc,
    tan, csc, sec, cot,
    asin, acos, atan, acsc, asec, acot,
    sind, cosd, tand, cscd, secd, cotd,
    asind, acosd, atand, acscd, asecd, acotd,
    sinh, cosh, tanh, csch, sech, coth,
    asinh, acosh, atanh, acsch, asech, acoth,
));

# modf, sincos, sincospi, sincosd, return 2 
# evalpoly

const scalar_functions_of_two_args = map(Symbol, (
    flipsign, copysign,
    mod, rem, div, fld, cld, hypot,
));

const scalar_functions_of_three_args = map(Symbol, (
    clamp, hypot,
));

const vector_functions_of_one_arg  = ()
const vector_functions_of_two_args = ()

const vector_adjoint_functions_of_two_args = ()
const adjoint_vector_functions_of_two_args = ()

const matrix_vector_functions_of_two_args = ()
const vector_matrix_functions_of_two_args = ()

const matrix_functions_of_one_arg  = (
   cond, det, tr, adjoint, transpose,
   eigvals, svdvals, eigvecs,
);
const matrix_functions_of_two_args = ()

const matrix_adjoint_functions_of_two_args = ()
const adjoint_matrix_functions_of_two_args = ()

#=     
     provide(x) uses reinterpret
     
     provide(x::Vector{Robust32}), provide(x::Matrix{Robust32})
        presents an Array of Robust32s as an Array of Float64s

     provide(x::Vector{Float64}), provide(x::Matrix{Float64})
        presents an Array of Float64s as an Array of Robust32s

     provide(x::Vector{ComplexR32}), provide(x::Matrix{ComplexR32})
        presents an Array of ComplexR32s as an Array of ComplexF64s

     provide(x::Vector{ComplexF64}), provide(x::Matrix{ComplexF64})
        presents an Array of ComplexF64s as an Array of ComplexR32s
=#

for (R,F) in ((:Robust32, :Float64), (:ComplexR32, :ComplexF64))
  for A in (:Vector, :Matrix)
    @eval begin
        provide(x::$A{$R}) = reinterpret($F, x)
        provide(x::$A{$F}) = reinterpret($R, x)
    end
  end
end

#=
    enfold(fn, ..) simplifies implementing functions correctly
=#

for F in scalar_functions_of_one_arg
  @eval enfold($F, x::Robust32) = provide(fn(provide(x)))
end

for F in scalar_functions_of_two_args
  @eval enfold($F, x::Robust32, y::Robust32) = provide(fn(provide(x), provide(y)))
end

for F in scalar_functions_of_three_args
  @eval enfold($F, x::Robust32, y::Robust32, z::Robust32) = provide(fn(provide(x), provide(y), provide(z)))
end

for F in vector_functions_of_one_arg
  @eval enfold($F, x::Vector{Robust32}) = provide(fn(provide(x)))
end

for F in vector_functions_of_two_args
  @eval enfold($F, x::Vector{Robust32}, y::Vector{Robust32}) = provide(fn(provide(x), provide(y)))
end

for F in vector_adjoint_functions_of_two_args
  @eval enfold($F, x::Vector{Robust32}, y::Adjoint{Robust32, Vector{Robust32}}) = provide(fn(provide(x), provide(y)))
end

for F in adjoint_vector_functions_of_two_args
  @eval enfold($F, x::Adjoint{Robust32, Vector{Robust32}}, y::Vector{Robust32}) = provide(fn(provide(x), provide(y)))
end

for F in matrix_functions_of_one_arg
  @eval enfold($F, x::Matrix{Robust32}) = provide(fn(provide(x)))
end

for F in matrix_functions_of_two_args
  @eval enfold($F, x::Matrix{Robust32}, y::Matrix{Robust32}) = provide(fn(provide(x), provide(y)))
end

for F in vector_functions_of_one_arg
  @eval enfold($F, x::Vector{Robust32}) = provide(fn(provide(x)))
end

for F in matrix_vector_functions_of_two_args
  @eval enfold($F, x::Matrix{Robust32}, y::Vector{Robust32}) = provide(fn(provide(x), provide(y)))
end

for F in vector_matrix_functions_of_two_args
  @eval enfold($F, x::Vector{Robust32}, y::Matrix{Robust32}) = provide(fn(provide(x), provide(y)))
end

for F in matrix_adjoint_functions_of_two_args
  @eval enfold($F, x::Matrix{Robust32}, y::Adjoint{Robust32, Vector{Robust32}}) = provide(fn(provide(x), provide(y)))
end

for F in adjoint_matrix_functions_of_two_args
  @eval enfold($F, x::Adjoint{Robust32, Vector{Robust32}}, y::Matrix{Robust32}) = provide(fn(provide(x), provide(y)))
end

#=
for F in (:-, :abs, :inv, :sqrt, :cbrt)
  @eval Base.$F(x::Robust32) = Rob32($F(value64(x)))
end

for F in (:(==), :(!=), :(<), :(<=), :(>), :(>=), :isless, :isequal)
  @eval begin
    Base.$F(x::Robust32, y::Robust32) = $F(value32(x), value32(y))
    Base.$F(x::Robust32, y::Real) = $F(promote(x,y)...)
    Base.$F(x::Real, y::Robust32) = $F(promote(x,y)...)
  end  
end

for F in (:+, :-, :*, :/, :\, :hypot, :copysign, :flipsign)
  @eval begin
    Base.$F(x::Robust32, y::Robust32) = Rob32($F(value64(x), value64(y)))
    Base.$F(x::Robust32, y::Real) = $F(promote(x,y)...)
    Base.$F(x::Real, y::Robust32) = $F(promote(x,y)...)
  end  
end

for F in (:hypot, :clamp)
  @eval begin
    Base.$F(x::Robust32, y::Robust32, z::Robust32) = Robust32($F(value(x), value(y), value(z)))
    Base.$F(x::Robust32, y::Real, z::Real) = $F(promote(x,y,z)...)
    Base.$F(x::Real, y::Robust32, z::Real) = $F(promote(x,y,z)...)
    Base.$F(x::Real, y::Real, z::Robust32) = $F(promote(x,y,z)...)
  end  
end

for F in (:abs2, :acos, :acosd, :acosh, :acot, :acotd, :acoth, :acsc, :acscd, :acsch, :asec,
          :asecd, :asech, :asin, :asind, :asinh, :atan, :atand, :atanh, :cos, :cosc,
          :cosd, :cosh, :cospi, :cot, :cotd, :coth, :csc, :cscd, :csch, :deg2rad,
          :exp, :exp10, :exp2, :expm1, :log, :log10, :log1p, :log2, :mod2pi,
          :rad2deg, :rem2pi, :sec, :secd, :sech, :sin, :sinc, :sind, :sinh,
          :sinpi, :tan, :tand, :tanh)
    @eval Base.Math.$F(x::Robust32) = Rob32($F(value64(x)))
end

for F in (:modf, :sincos, :sincosd) # , :sincospi)
  @eval function $F(x::Robust32)
            s, c = Base.Math.$F(value64(x))
            return Rob32(s), Rob32(c)
         end
end
=#

# ?????? @evalpoly

function Base.evalpoly(x::Robust32, p::NTuple{N, Robust32}) where {N}
    Rob32(evalpoly(value64(x), map(value64, p)))
end
function Base.evalpoly(x::T, p::NTuple{N, Robust32}) where {T,N}
    Rob32(evalpoly(Float64(x), map(value64, p)))
end
function Base.evalpoly(x::Robust32, p::NTuple{N, T}) where {T,N}
    Rob32(evalpoly(value64(x), p))
end

import LinearAlgebra: isdiag, ishermitian, isposdef, isposdef!, issuccess, issymmetric, istril, istriu,
     tr, det, dot, cross, adjoint, adjoint!, transpose, transpose!, diag, diagm, diagind, 
     svdvals, svdvals!, svd, svd!, eigvals, eigvals!, eigvecs, eigen, eigen!

for F in (:+, :-, :*, :/, :\)
  @eval begin
    $F(x::Vector{Robust32}, y::Vector{Robust32}) = rewrap($F(rewrap(x), rewrap(y)))
    $F(x::Vector{Robust32}, y::Vector{Float64})  = rewrap($F(rewrap(x), y))
    $F(x::Vector{Float64}, y::Vector{Robust32})  = rewrap($F(x, rewrap(y)))
    $F(x::Vector{Robust32}, y::Vector{Float32})  = rewrap($F(rewrap(x), y))
    $F(x::Vector{Float32}, y::Vector{Robust32})  = rewrap($F(x, rewrap(y)))

    $F(x::Matrix{Robust32}, y::Matrix{Robust32}) = rewrap($F(rewrap(x), rewrap(y)))
    $F(x::Matrix{Robust32}, y::Matrix{Float64})  = rewrap($F(rewrap(x), y))
    $F(x::Matrix{Float64}, y::Matrix{Robust32})  = rewrap($F(x, rewrap(y)))
    $F(x::Matrix{Robust32}, y::Matrix{Float32})  = rewrap($F(rewrap(x), y))
    $F(x::Matrix{Float32}, y::Matrix{Robust32})  = rewrap($F(x, rewrap(y)))
  end
end

end  # Robust32s