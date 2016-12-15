# posterize (0.12.0)

[![Build Status](https://travis-ci.org/talentdeficit/posterize.svg?branch=master)](https://travis-ci.org/talentdeficit/posterize)

an erlang wrapper for [postgrex](https://github.com/ericmj/postgrex)

documentation at [hexdocs](http://hexdocs.pm/posterize/)

## data representation

    postgres        erlang
    ----------      ------
    NULL            null
    bool            true | false
    char            <<"é">>
    int             42
    float           42.0
    text            <<"hallo world">>
    bytea           <<42>>
    array           [1, 2, 3]
    composite type  {42, <<"title">>, <<"content">>}
    uuid            <<160,238,188,153,156,11,78,248,187,109,107,185,189,56,10,17>>
    hstore          #{<<"foo">> => <<"bar">>}
    date            {2016, 12, 14}
    time            12261247241 | {native, 12261247241} | {milli_seconds, 12261}
    timetz          12261247241 | {native, 12261247241} | {milli_seconds, 12261}
    timestamp       381783411081267571 | {native, 381783411081267571} | {milli_seconds, 381783411081}
    json            1 | 2.0 | 3.0e3 | "hallo world" | true | false | [1,2.0,3.0e3] | #{<<"foo">> => <<"bar">>}
    jsonb           1 | 2.0 | 3.0e3 | "hallo world" | true | false | [1,2.0,3.0e3] | #{<<"foo">> => <<"bar">>}

## todo

* ranges, numerics, geo and all the other missing data types
* more tests, especially integration

## acknowledgments

this thing definitely wouldn't exist without [ericmj](https://github.com/ericmj) and [fishcakez](https://github.com/fishcakez). all credit to them
