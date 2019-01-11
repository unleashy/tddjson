module tddjson.value;

import taggedalgebraic;

@safe:

struct JSONValue
{
    union U
    {
        typeof(null) null_;
        bool boolean;
        double number;
        string str;
        JSONValue[] array;
        JSONValue[string] obj;
    }

    TaggedAlgebraic!U payload;
    alias payload this;

    this(T)(T value)
    {
        payload = value;
    }
}
