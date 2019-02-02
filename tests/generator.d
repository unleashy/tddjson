module tests.generator;

import unit_threaded;

import tddjson;

@safe:

void testNullGeneration()
{
    generateJSON(JSONValue(null)).should  == `null`;
}

void testBoolGeneration()
{
    generateJSON(JSONValue(true)).should  == `true`;
    generateJSON(JSONValue(false)).should == `false`;
}

void testNumberGeneration()
{
    generateJSON(JSONValue(3.14)).should    == `3.14`;
    generateJSON(JSONValue(-2.5555)).should == `-2.5555`;
}

void testStringGeneration()
{
    generateJSON(
        JSONValue("hello\"\\\b\f\n\r\t\x00")
    ).should == `"hello\"\\\b\f\n\r\t\u0000"`;
}

void testArrayGeneration()
{
    generateJSON(JSONValue(cast(JSONValue[]) [])).should == `[]`;
    generateJSON(JSONValue([JSONValue(3.14159)])).should == `[3.14159]`;
    generateJSON(JSONValue([
        JSONValue(true),
        JSONValue(cast(JSONValue[]) [])
    ])).should == `[true, []]`;
    generateJSON(JSONValue([
        JSONValue("ab\rcd"),
        JSONValue(1000),
        JSONValue([JSONValue(null), JSONValue(-2)]),
        JSONValue(false)
    ])).should == `["ab\rcd", 1000, [null, -2], false]`;
}

void testObjectGeneration()
{
    generateJSON(JSONValue(cast(JSONValue[string]) null)).should == `{}`;

    generateJSON(JSONValue(["a": JSONValue(true)])).should == `{"a": true}`;
    generateJSON(JSONValue([
        "\n": JSONValue(-77),
        "/": JSONValue([JSONValue("1"), JSONValue(null)])
    ])).should == `{"\n": -77, "/": ["1", null]}`;
}
