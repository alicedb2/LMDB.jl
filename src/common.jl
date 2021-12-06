const MBDValue = MDB_val
const EnvironmentFlags = Unsigned
MDBValue() = MDB_val(zero(Csize_t), C_NULL)
MDBValue(_::Nothing) = MDBValue()
MDBValue(val::String) = MDB_val(Csize_t(sizeof(val)), convert(Ptr{Cvoid},pointer(val)))
function MDBValue(val::T) where {T}
    isbitstype(T) && error("Can not wrap a $T in MDBValue. Use a $T array instead")
    val_size = sizeof(eltype(val))*length(val)
    return MDB_val(Csize_t(val_size), convert(Ptr{Cvoid},pointer(val)))
end

convert(::Type{T}, mdb_val_ref::Ref{MDB_val}) where {T} = _convert(T, mdb_val_ref[])
function _convert(::Type{String}, mdb_val::MDB_val)
    unsafe_string(convert(Ptr{UInt8}, mdb_val.mv_data), mdb_val.mv_size)
end
function _convert(::Type{Vector{T}}, mdb_val::MDB_val) where {T}
    res = unsafe_wrap(Array, convert(Ptr{UInt8}, mdb_val.mv_data), mdb_val.mv_size)
    reinterpret(T,res)
end
function _convert(::Type{T}, mdb_val::MDB_val) where {T}
    unsafe_load(convert(Ptr{T}, mdb_val.mv_data))
end


"""Return the LMDB library version and version information

Function returns tuple `(VersionNumber, String)` that contains a library version and a library version string.
"""
function version()
    major = Cint[0]
    minor = Cint[0]
    patch = Cint[0]
    ver_str = _mdb_version(major, minor, patch)
    return VersionNumber(major[1],minor[1],patch[1]), unsafe_string(ver_str)
end

"""Return a string describing a given error code

Function returns description of the error as a string. It accepts following arguments:
* `err::Int32`: An error code.
"""
function errormsg(err::Cint)
    errstr = _mdb_strerror(err)
    return unsafe_string(errstr)
end

""" Check if binary flag is set in provided value"""
isflagset(value, flag) = (value & flag) == flag
