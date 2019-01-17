module tddjson.value;

@safe:

struct JSONValue
{
    import std.format : format;

    enum Type
    {
        Null,
        Boolean,
        Number,
        String,
        Array,
        Object
    }

    private union Value
    {
        @(Type.Null)
        typeof(null) nil;

        @(Type.Boolean)
        bool boolean;

        @(Type.Number)
        double number;

        @(Type.String)
        string str;

        @(Type.Array)
        JSONValue[] array;

        @(Type.Object)
        JSONValue[string] obj;

        static foreach (it; Value.tupleof)
        {
            this(inout(typeof(it)) value) @nogc @trusted inout
            {
                it = value;
            }
        }

        this(inout(int) value) @nogc @trusted inout
        {
            number = value;
        }
    }

    private Type type_;
    private Value value_;

    static foreach (it; Value.tupleof)
    {
        this(inout(typeof(it)) value) @nogc inout
        {
            type_  = __traits(getAttributes, it)[0];
            value_ = inout(Value)(value);
        }

        bool opEquals(in typeof(it) rhs) @nogc @trusted const pure
        {
            return type_ == __traits(getAttributes, it)[0] &&
                   mixin("value_." ~ it.stringof) == rhs;
        }

        inout(typeof(it)) as(T : typeof(it))() @trusted pure inout
        in (
            type_ == __traits(getAttributes, it)[0],
            format!"type mismatch: expected %s but got %s"(
                __traits(getAttributes, it)[0],
                type_
            )
        )
        do
        {
            return mixin("value_." ~ it.stringof);
        }
    }

    // workaround for number literal -> bool conversion
    this(inout(int) num) @nogc inout
    {
        type_  = Type.Number;
        value_ = Value(num);
    }

    bool opEquals(in int rhs) @nogc @trusted const pure
    {
        return opEquals(cast(double) rhs);
    }

    bool opEquals(in JSONValue rhs) @nogc @trusted const pure
    {
        if (type_ == rhs.type) {
            switch (type_) {
                static foreach (it; Value.tupleof) {
                    case __traits(getAttributes, it)[0]:
                        return opEquals(mixin("rhs.value_." ~ it.stringof));
                }

                default: break;
            }
        }

        return false;
    }

    bool isType(in Type t) @nogc @safe const pure
    {
        return type_ == t;
    }

    Type type() @nogc const pure nothrow
    {
        return type_;
    }
}
