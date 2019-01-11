module tddjson.value;

import taggedalgebraic;

@safe:

struct JSONNull
{}

union JSONValueUnion
{
    JSONNull null_;
    bool boolean;
}

alias JSONValue = TaggedAlgebraic!JSONValueUnion;
