module tddjson.parsing;

import tddjson.exception;
import tddjson.value;

@safe:

JSONValue parseJSON(string str)
{
    if (str == "true") {
        return JSONValue(true);
    } else if (str == "false") {
        return JSONValue(false);
    } else if (str == "null") {
        return JSONValue(null);
    } else if (auto parsedNum = parseNumber(str)) {
        return JSONValue(parsedNum.value);
    }

    throw new JSONException("parsing error");
}

private struct ParseResult(T)
{
    T value;
    bool successful;

    bool opCast(T : bool)() const
    {
        return successful;
    }
}

private ParseResult!T parseResultOk(T)(T value)
{
    return ParseResult!T(value, true);
}

private ParseResult!T parseResultFail(T)()
{
    return ParseResult!T(T.init, false);
}

private ParseResult!long parseNumber(ref string str)
{
    import std.range.primitives : empty, front, popFront;

    if (str.empty) return parseResultFail!(long);

    long value = 0;

    for (; !str.empty; str.popFront()) {
        immutable c = str.front;
        switch (c) {
            case '0': .. case '9':
                value = value * 10 + (c - '0');
                break;

            default: break;
        }
    }

    return parseResultOk(value);
}
