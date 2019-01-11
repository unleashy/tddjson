module tddjson.value;

import taggedalgebraic;

@safe:

struct JSONNull
{}

union JSONValueUnion
{
    typeof(null) null_;
    bool boolean;
    double number;
}

alias JSONValue = TaggedAlgebraic!JSONValueUnion;
