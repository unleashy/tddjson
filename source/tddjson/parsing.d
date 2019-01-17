module tddjson.parsing;

import std.range.primitives;
import std.traits : Unqual;

import tddjson.exception;
import tddjson.value;

@safe:

private struct ParseResult
{
    JSONValue value;
    bool successful;

    bool opCast(T : bool)() const
    {
        return successful;
    }

    ParseResult opBinary(string op : "|")(lazy ParseResult rhs)
    {
        return successful ? this : rhs;
    }
}

private ParseResult parseResultOk(T)(T value) @nogc pure
{
    return ParseResult(JSONValue(value), true);
}

private ParseResult parseResultFail() @nogc pure
{
    return ParseResult(JSONValue.init, false);
}

private void skipWhitespace(R)(ref R range)
{
    for (; !range.empty; range.popFront()) {
        switch (range.front) {
            case '\t':
            case '\n':
            case '\r':
            case ' ':
                break; // keep consuming whitespace

            default: return; // stop, since we got a non-whitespace character.
        }
    }
}

private ParseResult parseLiteral(string name, R)(ref R range)
{
    import std.algorithm.searching : skipOver;
    return range.skipOver(name) ? parseResultOk(mixin(name)) : parseResultFail();
}

private ParseResult parseNumber(R)(ref R range)
{
    import std.ascii : isDigit, toLower;
    import std.conv  : ConvException, to;

    // ensure this is at least the start of a possible number token
    if (range.empty || (range.front != '-' && !range.front.isDigit())) {
        return parseResultFail();
    }

    string processed;

    if (range.front == '-') {
        range.popFront();
        if (range.empty) {
            throw new JSONException("stray minus sign");
        }

        processed = "-";
    }

    bool consumedOneDigit = false;

    if (range.front == '0') {
        range.popFront();

        if (!range.empty && range.front.isDigit()) {
            throw new JSONException("leading zeros are not allowed");
        }

        processed ~= '0';
        consumedOneDigit = true;
    }

    bool consumedPoint = false;

    Lnumloop:
    for (; !range.empty; range.popFront()) {
        immutable c = range.front;
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

        processed ~= c;
    }

    // try to parse an exponent if available
    if (consumedOneDigit && !range.empty && range.front.toLower() == 'e') {
        range.popFront();
        processed ~= 'e';

        // try for minus or plus sign
        if (range.empty || (range.front != '-' && range.front != '+' && !range.front.isDigit())) {
            throw new JSONException("expected number for exponent");
        }

        if (range.front == '-' || range.front == '+') {
            processed ~= range.front;
            range.popFront();
        }

        consumedOneDigit = false;

        Lexploop:
        for (; !range.empty; range.popFront()) {
            immutable c = range.front;
            switch (c) {
                case '0': .. case '9':
                    consumedOneDigit = true;
                    break;

                default: break Lexploop;
            }

            processed ~= c;
        }
    }

    if (!consumedOneDigit) {
        throw new JSONException("unexpected character in number token");
    }

    try {
        // only try to convert the text we actually processed!
        return parseResultOk(to!double(processed));
    } catch (ConvException e) {
        throw new JSONException(
            e.msg ~ " while converting number token to floating-point",
            e
        );
    }
}

private ParseResult parseString(R)(ref R range)
{
    import std.ascii : isControl, isDigit, isHexDigit;
    import std.conv  : text;

    // make sure this is at least the start of a string token
    if (range.empty || range.front != '"') {
        return parseResultFail();
    }

    // since we know the first char is a quotation mark, skip it
    range.popFront();

    string value;

    for (; !range.empty; range.popFront()) {
        dchar c = range.front;
        if (c == '"') {
            break;
        } else if (c == '\\') {
            range.popFront();
            if (range.empty) {
                throw new JSONException("expected escape sequence after backslash");
            }

            immutable escapeSeq = range.front;
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
                        range.popFront();

                        if (range.empty) {
                            throw new JSONException(text(
                                `expected 4 hexadecimal digits after \\u, not `, i
                            ));
                        }

                        immutable digit = range.front;
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
    if (range.empty || range.front != '"') {
        throw new JSONException("unclosed string");
    }

    // skip closing quotation mark...
    range.popFront();
    return parseResultOk(value);
}

private bool parseAggregate(string delims, alias fun, R)(ref R range)
{
    static assert(delims.length == 2, "need two delimiters for each side!");

    enum leftDelim  = delims[0];
    enum rightDelim = delims[1];

    skipWhitespace(range);

    if (range.empty || range.front != leftDelim) {
        return false;
    }

    range.popFront();
    skipWhitespace(range);

    while (!range.empty && range.front != rightDelim) {
        fun();

        skipWhitespace(range);

        if (range.empty || range.front != ',') {
            break;
        }

        range.popFront();
        skipWhitespace(range);

        if (range.empty || range.front == rightDelim) {
            throw new JSONException("trailing comma not allowed");
        }
    }

    if (range.empty || range.front != rightDelim) {
        throw new JSONException("unclosed aggregate");
    }

    range.popFront();
    skipWhitespace(range);

    return true;
}

private ParseResult parseArray(R)(ref R range)
{
    JSONValue[] array;

    immutable successful = range.parseAggregate!("[]", {
        array ~= parseValue(range);
    });

    return successful ? parseResultOk(array) : parseResultFail();
}

private ParseResult parseObject(R)(ref R range)
{
    JSONValue[string] obj;

    immutable successful = range.parseAggregate!("{}", {
        string key;
        if (auto result = parseString(range)) {
            key = result.value.as!string;

            if (key in obj) {
                throw new JSONException(
                    "key '" ~ key ~ "' has already been used in object"
                );
            }
        } else {
            throw new JSONException("expected string key in object");
        }

        skipWhitespace(range);
        if (range.empty || range.front != ':') {
            throw new JSONException("expected colon after object key");
        }

        range.popFront();
        skipWhitespace(range);

        obj[key] = parseValue(range);
    });

    return successful ? parseResultOk(obj) : parseResultFail();
}

private JSONValue parseValue(R)(ref R range)
{
    auto parseResult = parseLiteral!"null"(range)  |
                       parseLiteral!"true"(range)  |
                       parseLiteral!"false"(range) |
                       parseNumber(range)          |
                       parseString(range)          |
                       parseArray(range)           |
                       parseObject(range);

    if (parseResult) {
        return parseResult.value;
    } else {
        throw new JSONException("malformed input");
    }
}

private enum isStringyFwdRange(R) =
    isForwardRange!R && is(Unqual!(ElementType!R) : dchar);

JSONValue parseJSON(R)(R range)
    if (isStringyFwdRange!R)
{
    skipWhitespace(range);
    if (range.empty) {
        throw new JSONException("input is empty");
    }

    JSONValue value = parseValue(range);

    skipWhitespace(range);
    if (!range.empty) {
        throw new JSONException("extraneous characters after the end of input");
    }

    return value;
}
