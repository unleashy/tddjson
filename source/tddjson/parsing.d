module tddjson.parsing;

import tddjson.exception;
import tddjson.value;

@safe:

JSONValue parseJSON(in string s)
{
    switch (s) {
        case "true":  return JSONValue(true);
        case "false": return JSONValue(false);
        case "null":  return JSONValue(null);
        case "0":     return JSONValue(0);
        default:      throw new JSONException("parsing error");
    }
}
