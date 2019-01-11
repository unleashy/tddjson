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

private bool parseLiteral(string name)(ref string str)
{
    if (str.length >= name.length && str[0 .. name.length] == name) {
        str = str[name.length .. $]; // advance past the literal
        return true;
    } else {
        return false;
    }
}

private ParseResult!long parseNumber(ref string str)
{
    if (str.empty) return parseResultFail!(long);

    long value = 0;

    if (str.front == '0') {
        str.popFront();

        if (!str.empty) {
            immutable c = str.front;
            if (c >= '0' && c <= '9') {
                throw new JSONException("leading zeros are not allowed");
            }
        }
    } else {
        loop: for (; !str.empty; str.popFront()) {
            immutable c = str.front;
            switch (c) {
                case '0': .. case '9':
                    value = value * 10 + (c - '0');
                    break;

                default: break loop;
            }
        }
    }

    return parseResultOk(value);
}

private JSONValue parseValue(ref string str)
{
    if (parseLiteral!"null"(str)) {
        return JSONValue(null);
    } else if (parseLiteral!"true"(str)) {
        return JSONValue(true);
    } else if (parseLiteral!"false"(str)) {
        return JSONValue(false);
    } else if (auto parseResult = parseNumber(str)) {
        return JSONValue(parseResult.value);
    } else {
        throw new JSONException("malformed input");
    }
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
