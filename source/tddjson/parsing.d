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

private ParseResult!real parseNumber(ref string str)
{
    import std.ascii : isDigit, toLower;
    import std.conv  : parse;

    // ensure this is at least the start of a possible number token
    if (str.empty || (str.front != '-' && !str.front.isDigit())) {
        return parseResultFail!(real);
    }

    auto strOriginal = str[];

    if (str.front == '-') {
        str.popFront();
        if (str.empty) {
            throw new JSONException("stray minus sign");
        }
    }

    bool consumedOneDigit = false;

    if (str.front == '0') {
        str.popFront();

        if (!str.empty) {
            immutable c = str.front;
            if (c.isDigit()) {
                throw new JSONException("leading zeros are not allowed");
            }
        }

        consumedOneDigit = true;
    }

    bool consumedPoint = false;

    Lnumloop:
    for (; !str.empty; str.popFront()) {
        immutable c = str.front;
        switch (c) {
            case '0': .. case '9':
                consumedOneDigit = true;
                break;

            case '.':
                if (!consumedOneDigit || consumedPoint) {
                    throw new JSONException("stray decimal point in number token");
                }

                consumedOneDigit = false;
                consumedPoint = true;
                break;

            default:
                break Lnumloop;
        }
    }

    // try to parse an exponent if available
    if (consumedOneDigit && !str.empty && str.front.toLower() == 'e') {
        str.popFront();

        // try for minus or plus sign
        if (str.empty || (str.front != '-' && str.front != '+' && !str.front.isDigit())) {
            throw new JSONException("expected number for exponent");
        }

        if (str.front == '-' || str.front == '+') {
            str.popFront();
        }

        consumedOneDigit = false;

        Lexploop:
        for (; !str.empty; str.popFront()) {
            immutable c = str.front;
            switch (c) {
                case '0': .. case '9':
                    consumedOneDigit = true;
                    break;

                default: break Lexploop;
            }
        }
    }

    if (!consumedOneDigit) {
        throw new JSONException("unexpected character in number token");
    }

    return parseResultOk(parse!real(strOriginal));
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
