package dev.stupeni.career

enum class Method { GET, POST, PUT, DELETE }

sealed interface ApiError {
    data class Network(val detail: String) : ApiError
    data class Http(val code: Int, val body: String) : ApiError
    data object Unauthorized : ApiError
}

fun isIdempotent(method: Method): Boolean = TODO("C2: isIdempotent")

fun mapHttp(code: Int, body: String): ApiError = TODO("C2: mapHttp")
