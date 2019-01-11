module tddjson.parsing;

import std.range.primitives : empty, front, popFront;

import tddjson.exception;
import tddjson.value;

@safe:

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

private void skipWhitespace(ref string str)
{
    for (; !str.empty; str.popFront()) {
        switch (str.front) {
            case '\t':
            case '\n':
            case '\r':
            case ' ':
                break; // keep consuming whitespace

            default: return; // stop, since we got a non-whitespace character.
        }
    }
}

private bool parseNull(ref string str)
{
    enum Null = "null";

    skipWhitespace(str);

    // check only the first Null.length characters...
    if (str.length >= Null.length && str[0 .. Null.length] == Null) {
        str = str[Null.length .. $]; // advance past the null
        return true;
    } else {
        return false;
    }
}

private ParseResult!bool parseBoolean(ref string str)
{
    enum True  = "true";
    enum False = "false";

    skipWhitespace(str);

    if (str.length >= True.length && str[0 .. True.length] == True) {
        str = str[True.length .. $];
        return parseResultOk(true);
    } else if (str.length >= False.length && str[0 .. False.length] == False) {
        str = str[False.length .. $];
        return parseResultOk(false);
    }

    return parseResultFail!(bool);
}

private ParseResult!long parseNumber(ref string str)
{
    skipWhitespace(str);

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

private JSONValue parseValue(ref string str)
{
    JSONValue value;

    if (parseNull(str)) {
        value = JSONValue(null);
    } else if (auto parseResult = parseBoolean(str)) {
        value = JSONValue(parseResult.value);
    } else if (auto parseResult = parseNumber(str)) {
        value = JSONValue(parseResult.value);
    }

    return value;
}

JSONValue parseJSON(string str)
{
    skipWhitespace(str);
    if (str.empty) {
        throw new JSONException("string is empty");
    }

    JSONValue value = parseValue(str);

    skipWhitespace(str);
    if (!str.empty) {
        throw new JSONException("extraneous characters after the end of the document");
    }

    return value;
}
