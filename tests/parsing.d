module tests.parsing;

import unit_threaded;

import tddjson;

@safe:

void testMalformedFails()
{
    parseJSON("").shouldThrow!(JSONException);
    parseJSON(" \t\r\n").shouldThrow!(JSONException);
    parseJSON("true0").shouldThrow!(JSONException);
    parseJSON("123,").shouldThrow!(JSONException);
}

void testParseBoolean()
{
    parseJSON("true").should    == true;
    parseJSON("false").should   == false;
    parseJSON(" \t\r\ntrue \t\r\n").should   == true;
    parseJSON(" \t\r\nfalse \t\r\n").should  == false;
}

void testParseNull()
{
    parseJSON("null").should     == null;
    parseJSON(" \t\r\nnull \t\r\n").should   == null;
    parseJSON(" \t\r\nnull \t\r\n").should == null;
}

void testParseNumber()
{
    parseJSON("0").should == 0;
    parseJSON("1").should == 1;
    parseJSON("1023456789").should == 1_023_456_789;

    parseJSON("01023456789").shouldThrow!(JSONException);
    parseJSON("0003").shouldThrow!(JSONException);

    parseJSON("-904").should == -904;
    parseJSON("-").shouldThrow!(JSONException);
    parseJSON("-01").shouldThrow!(JSONException);
    parseJSON("--75").shouldThrow!(JSONException);
}
