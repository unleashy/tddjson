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

private string spanBetweenSlices(in string left, in string right) @trusted
{
    return left[0 .. (right.ptr - left.ptr)];
}

private ParseResult!double parseNumber(ref string str)
{
    import std.ascii : isDigit, toLower;
    import std.conv  : ConvException, to;

    // ensure this is at least the start of a possible number token
    if (str.empty || (str.front != '-' && !str.front.isDigit())) {
        return parseResultFail!(double);
    }

    auto originalStr = str;

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

    try {
        // only try to convert the text we actually processed!
        auto processedSlice = spanBetweenSlices(originalStr, str);
        return parseResultOk(to!double(processedSlice));
    } catch (ConvException e) {
        throw new JSONException(
            e.msg ~ " while converting number token to floating-point",
            e
        );
    }
}

private ParseResult!string parseString(ref string str)
{
    import std.ascii : isControl, isDigit, isHexDigit;
    import std.conv  : text;

    // make sure this is at least the start of a string token
    if (str.empty || str.front != '"') {
        return parseResultFail!(string);
    }

    // since we know the first char is a quotation mark, skip it
    str.popFront();

    string value;

    for (; !str.empty; str.popFront()) {
        auto c = str.front;
        if (c == '"') {
            break;
        } else if (c == '\\') {
            str.popFront();
            if (str.empty) {
                throw new JSONException("expected escape sequence after backslash");
            }

            immutable escapeSeq = str.front;
            switch (escapeSeq) {
                case '"':  c = '"';  break;
                case '\\': c = '\\'; break;
                case '/':  c = '/';  break;
                case 'b':  c = '\b'; break;
                case 'f':  c = '\f'; break;
                case 'n':  c = '\n'; break;
                case 'r':  c = '\r'; break;
                case 't':  c = '\t'; break;
                case 'u':
                    dchar escapedChar = 0;
                    foreach (i; 0 .. 4) {
                        str.popFront();

                        if (str.empty) {
                            throw new JSONException(text(
                                `expected 4 hexadecimal digits after \\u, not `, i
                            ));
                        }

                        immutable digit = str.front;
                        if (digit.isDigit()) {
                            escapedChar = escapedChar * 16 + (digit - '0');
                        } else if (digit.isHexDigit()) {
                            // we know this must be A-F or a-f, since the previous
                            // if handled 0-9 for us
                            // digit | 0x20 = ""tolower""
                            // any of a-f minus 87 equals their value, so we do that!
                            escapedChar = escapedChar * 16 + ((digit | 0x20) - 87);
                        } else {
                            throw new JSONException(text(
                                `expected 4 hexadecimal digits after \\u, not `, i
                            ));
                        }
                    }

                    c = escapedChar;
                    break;

                default:
                    throw new JSONException(text(
                        `unrecognised escape sequence '\`, escapeSeq, `'`
                    ));
            }
        } else if (c.isControl()) {
            throw new JSONException("strings may not contain control characters");
        }

        value ~= c;
    }

    // expecting closing quotation mark here
    if (str.empty || str.front != '"') {
        throw new JSONException("unclosed string");
    }

    // skip closing quotation mark...
    str.popFront();
    return parseResultOk(value);
}

private bool parseAggregate(string delims, alias fun)(ref string str)
{
    static assert(delims.length == 2, "need two delimiters for each side!");

    enum leftDelim  = delims[0];
    enum rightDelim = delims[1];

    skipWhitespace(str);

    if (str.empty || str.front != leftDelim) {
        return false;
    }

    str.popFront();
    skipWhitespace(str);

    while (!str.empty && str.front != rightDelim) {
        fun();

        skipWhitespace(str);

        if (str.empty || str.front != ',') {
            break;
        }

        str.popFront();
        skipWhitespace(str);

        if (str.empty || str.front == rightDelim) {
            throw new JSONException("trailing comma not allowed");
        }
    }

    if (str.empty || str.front != rightDelim) {
        throw new JSONException("unclosed aggregate");
    }

    str.popFront();
    skipWhitespace(str);

    return true;
}

private ParseResult!(JSONValue[]) parseArray(ref string str)
{
    JSONValue[] array;

    immutable successful = str.parseAggregate!("[]", {
        array ~= parseValue(str);
    });

    return successful ? parseResultOk(array) : parseResultFail!(typeof(array));
}

private ParseResult!(JSONValue[string]) parseObject(ref string str)
{
    JSONValue[string] obj;

    immutable successful = str.parseAggregate!("{}", {
        string key;
        if (auto result = parseString(str)) {
            key = result.value;

            if (key in obj) {
                throw new JSONException(
                    "key '" ~ key ~ "' has already been used in object"
                );
            }
        } else {
            throw new JSONException("expected string key in object");
        }

        skipWhitespace(str);
        if (str.empty || str.front != ':') {
            throw new JSONException("expected colon after object key");
        }

        str.popFront();
        skipWhitespace(str);

        obj[key] = parseValue(str);
    });

    return successful ? parseResultOk(obj) : parseResultFail!(typeof(obj));
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
    } else if (auto parseResult = parseString(str)) {
        return JSONValue(parseResult.value);
    } else if (auto parseResult = parseArray(str)) {
        return JSONValue(parseResult.value);
    } else if (auto parseResult = parseObject(str)) {
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
