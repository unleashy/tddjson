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
    string str;
}

alias JSONValue = TaggedAlgebraic!JSONValueUnion;
