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

void testParseNull()
{
    parseJSON("null").should == null;
}

void testParseNumber()
{
    parseJSON("0").should == 0;
}
