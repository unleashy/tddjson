module tests.parsing;

import unit_threaded;

import tddjson;

@safe:

void testEmptyStringFails()
{
    parseJSON("").shouldThrow!(JSONException);
}
