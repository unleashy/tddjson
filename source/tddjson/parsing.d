module tddjson.parsing;

import tddjson.exception;

@safe:

bool parseJSON(in string s)
{
    if (s == "true") {
        return true;
    } else if (s == "false") {
        return false;
    } else {
        throw new JSONException("");
    }
}
