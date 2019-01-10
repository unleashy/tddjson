module tddjson.exception;

@safe:

final class JSONException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}
