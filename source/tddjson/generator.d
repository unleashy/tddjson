module tddjson.generator;

import std.algorithm : map;
import std.array     : appender;
import std.format    : formattedWrite;
import std.range     : put;

import tddjson.value;

@safe:

private void generateString(Writer)(ref Writer w, in string str)
{
    import std.uni : isGraphical;

    put(w, '"');

    foreach (c; str) {
        if (c.isGraphical()) {
            if (c == '"' || c == '\\') {
                put(w, '\\');
            }

            put(w, c);
        } else switch (c) {
            case '\b': put(w, `\b`); break;
            case '\f': put(w, `\f`); break;
            case '\n': put(w, `\n`); break;
            case '\r': put(w, `\r`); break;
            case '\t': put(w, `\t`); break;
            default:   w.formattedWrite!`\u%04X`(cast(uint) c);
        }
    }

    put(w, '"');
}

private void generateArray(Writer)(ref Writer w, in JSONValue[] value)
{
    w.formattedWrite!"[%-(%s, %)]"(value.map!(generateJSON));
}

private void generateObject(Writer)(ref Writer w, in JSONValue[string] value)
{
    void generateEntry(Entry)(in Entry entry)
    {
        generateString(w, entry.key);
        put(w, ": ");
        generateJSON(w, entry.value);
    }

    put(w, '{');

    auto entries = value.byKeyValue();

    if (!entries.empty) {
        // process first entry
        generateEntry(entries.front);
        entries.popFront();

        // for the next entries, use a comma
        foreach (entry; entries) {
            put(w, ", ");
            generateEntry(entry);
        }
    }

    put(w, '}');
}

void generateJSON(Writer)(ref Writer w, in JSONValue value)
{
    final switch (value.type) with (JSONValue.Type) {
        case Null:
            put(w, `null`);
            break;

        case Boolean:
            put(w, value.as!bool ? `true` : `false`);
            break;

        case Number:
            w.formattedWrite!`%g`(value.as!double);
            break;

        case String:
            generateString(w, value.as!string);
            break;

        case Array:
            generateArray(w, value.as!(JSONValue[]));
            break;

        case Object:
            generateObject(w, value.as!(JSONValue[string]));
            break;
    }
}

string generateJSON(in JSONValue value)
{
    auto buf = appender!(string);
    generateJSON(buf, value);
    return buf.data;
}
