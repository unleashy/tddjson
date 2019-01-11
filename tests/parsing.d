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

    parseJSON("0.0125").should == 0.0125;
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

void testParseString()
{
    parseJSON(`""`).should    == "";
    parseJSON(`"abc"`).should == "abc";
    parseJSON(`"`).shouldThrow!(JSONException);
    parseJSON(`"""`).shouldThrow!(JSONException);
    parseJSON(`"a " a"`).shouldThrow!(JSONException);
    parseJSON("\"\x00\x1F\"").shouldThrow!(JSONException);
    parseJSON(`"\"`).shouldThrow!(JSONException);
    parseJSON(`"\`).shouldThrow!(JSONException);

    parseJSON(`"\""`).should == `"`;
    parseJSON(`"\\"`).should == `\`;
    parseJSON(`"\/"`).should == `/`;
    parseJSON(`"\b"`).should == "\b";
    parseJSON(`"\f"`).should == "\f";
    parseJSON(`"\n"`).should == "\n";
    parseJSON(`"\r"`).should == "\r";
    parseJSON(`"\t"`).should == "\t";
    parseJSON(`"\\\ "`).shouldThrow!(JSONException);
    parseJSON(`"\"\""`).should == `""`;
    parseJSON(`"\"\"`).shouldThrow!(JSONException);

    parseJSON(`"\u12345678"`).should == "\u12345678";
    parseJSON(`"\uABCDEF"`).should == "\uABCDEF";
    parseJSON(`"\uabcdef"`).should == "\uabcdef";
    parseJSON(`"\u`).shouldThrow!(JSONException);
    parseJSON(`"\u"`).shouldThrow!(JSONException);
    parseJSON(`"\u5"`).shouldThrow!(JSONException);
    parseJSON(`"\u56"`).shouldThrow!(JSONException);
    parseJSON(`"\u567"`).shouldThrow!(JSONException);
    parseJSON(`"\u5678`).shouldThrow!(JSONException);
    parseJSON(`"\uFFGH"`).shouldThrow!(JSONException);
}

void testParseArray() @system
{
    parseJSON("[]").should == [];
    parseJSON(" [ ] ").should == [];
    parseJSON("[").shouldThrow!(JSONException);
    parseJSON("[true]").should == [JSONValue(true)];
    parseJSON("[false]").should == [JSONValue(false)];
    parseJSON("[null]").should == [JSONValue(null)];
    parseJSON("[0]").should == [JSONValue(0)];
    parseJSON(`[""]`).should == [JSONValue("")];
    parseJSON("[[]]").should == [JSONValue(cast(JSONValue[]) [])];
    parseJSON(`[true, false, null, 0, "", []]`).should == [
        JSONValue(true),
        JSONValue(false),
        JSONValue(null),
        JSONValue(0),
        JSONValue(""),
        JSONValue(cast(JSONValue[]) [])
    ];
    parseJSON("[ 1 , ]").shouldThrow!(JSONException);
    parseJSON("[,]").shouldThrow!(JSONException);
    parseJSON("[a]").shouldThrow!(JSONException);
    parseJSON("[1,").shouldThrow!(JSONException);
    parseJSON("[[1]").shouldThrow!(JSONException);
}

void testParseObject() @system
{
    parseJSON("{}").should == cast(JSONValue[string]) null;
    parseJSON(" { } ").should == cast(JSONValue[string]) null;
    parseJSON("{").shouldThrow!(JSONException);
    parseJSON(`{ "a": 1 }`).should == JSONValue(["a": JSONValue(1)]);
    parseJSON(`{ "b": true , "c": "d" }`).should == JSONValue([
        "b": JSONValue(true),
        "c": JSONValue("d")
    ]);
    parseJSON(`{ "e" : null `).shouldThrow!(JSONException);
    parseJSON(`{ "f" : false, `).shouldThrow!(JSONException);
    parseJSON(`{ "g" : [1], }`).shouldThrow!(JSONException);
    parseJSON(`{ "i" : [ } `).shouldThrow!(JSONException);
    parseJSON(`{ 1 : "j" }`).shouldThrow!(JSONException);
    parseJSON(`{ a : "j" }`).shouldThrow!(JSONException);
    parseJSON(`{ " : "k" }`).shouldThrow!(JSONException);
    parseJSON(`{ "l"; "m" }`).shouldThrow!(JSONException);
    parseJSON(`"l": "m" }`).shouldThrow!(JSONException);
    parseJSON(`{"a": 1, "a": 2}`).shouldThrow!(JSONException);
}
