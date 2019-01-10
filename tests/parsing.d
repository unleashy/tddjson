module tests.parsing;

import unit_threaded;

import tddjson;

@safe:

void testEmptyStringFails()
{
    parseJSON("").shouldThrow!(JSONException);
}

void testParseBoolean()
{
    parseJSON("true").should  == true;
    parseJSON("false").should == false;
}
