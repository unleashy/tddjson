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
    parseJSON("a").shouldThrow!(JSONException);
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

    parseJSON("0.0755").should == 0.0755;
    parseJSON("3.").shouldThrow!(JSONException);
    parseJSON(".3").shouldThrow!(JSONException);
    parseJSON("-3.14").should == -3.14;
    parseJSON("-.075").shouldThrow!(JSONException);
    parseJSON("5.12.").shouldThrow!(JSONException);

    parseJSON("0e1").should     == 0;
    parseJSON("100e5").should   == 100e5;
    parseJSON("100E+5").should  == 100e5;
    parseJSON("-100e-5").should == -100e-5;
    parseJSON("100e+5").should  == 100e5;
    parseJSON("100e").shouldThrow!(JSONException);
    parseJSON("100.e5").shouldThrow!(JSONException);
    parseJSON("100e-").shouldThrow!(JSONException);
    parseJSON("100E+").shouldThrow!(JSONException);
    parseJSON("100E.5").shouldThrow!(JSONException);
    parseJSON("100e-5-").shouldThrow!(JSONException);
    parseJSON("100ee5").shouldThrow!(JSONException);
    parseJSON("100e+5.0").shouldThrow!(JSONException);
}
