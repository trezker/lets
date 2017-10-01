module boiler.helpers;

import std.algorithm;
import std.ascii : letters, digits;
import std.conv : to;
import std.random : randomCover, rndGen;
import std.range : chain;
import std.string;
import std.array;
import core.exception;
import vibe.stream.memory;
import vibe.db.mongo.mongo;
import vibe.data.bson;

string get_random_string(uint length) {
	auto asciiLetters = to!(dchar[])(letters);
    auto asciiDigits = to!(dchar[])(digits);

    dchar[] key;
    key.length = length;
    fill(key[], randomCover(chain(asciiLetters, asciiDigits), rndGen));
    return to!(string)(key);
}

template assertOp(string op)
{
    void assertOp(T1, T2)(T1 lhs, T2 rhs,
                          string file = __FILE__,
                          size_t line = __LINE__)
    {
        string msg = format("(%s %s %s) failed.", lhs, op, rhs);

        mixin(format(q{
            if (!(lhs %s rhs)) throw new AssertError(msg, file, line);
        }, op));
    }
}

alias assertOp!"==" assertEqual;
alias assertOp!"!=" assertNotEqual;
alias assertOp!">" assertGreaterThan;
alias assertOp!">=" assertGreaterThanOrEqual;

MemoryStream createInputStreamFromString(string input) {
	ubyte[1000000] inputdata;
	auto inputStream = new MemoryStream(inputdata);
	inputStream.write(cast(const(ubyte)[])input);
	inputStream.seek(0);
	return inputStream;
}

T[] MongoArray(T)(MongoCollection collection, Bson conditions) {
    return collection.find(conditions).map!(doc => deserialize!(BsonSerializer, T)(doc)).array; 
}
