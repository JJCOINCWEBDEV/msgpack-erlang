%%
%% MessagePack for Erlang
%%
%% Copyright (C) 2009-2013 UENISHI Kota
%%
%%    Licensed under the Apache License, Version 2.0 (the "License");
%%    you may not use this file except in compliance with the License.
%%    You may obtain a copy of the License at
%%
%%        http://www.apache.org/licenses/LICENSE-2.0
%%
%%    Unless required by applicable law or agreed to in writing, software
%%    distributed under the License is distributed on an "AS IS" BASIS,
%%    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%    See the License for the specific language governing permissions and
%%    limitations under the License.
%%
%% Created : 26 Apr 2011 by UENISHI Kota <uenishi.kota@lab.ntt.co.jp>

-module(msgpack_test).

-import(msgpack, [pack/2, unpack/2, pack/1, unpack/1]).

-include_lib("eunit/include/eunit.hrl").

-ifdef(DO_MSGPACK_CROSSLANG_TEST).

test_data_jsx()->
    [true, false, nil,
     0, 1, 2, 123, 512, 1230, 678908, 16#FFFFFFFFFF,
     -1, -23, -512, -1230, -567898, -16#FFFFFFFFFF,
     123.123, -234.4355, 1.0e-34, 1.0e64,
     [23, 234, 0.23],
     <<"hogehoge">>, <<"243546rf7g68h798j", 0, 23, 255>>,
     <<"hoasfdafdas][">>,
     [0,42, <<"sum">>, [1,2]], [1,42, nil, [3]],
     -234, -40000, -16#10000000, -16#100000000,
     42,
     [{}], {hoge}
    ].

test_data_jiffy()->
    [true, false, nil,
     0, 1, 2, 123, 512, 1230, 678908, 16#FFFFFFFFFF,
     -1, -23, -512, -1230, -567898, -16#FFFFFFFFFF,
     123.123, -234.4355, 1.0e-34, 1.0e64,
     [23, 234, 0.23],
     <<"hogehoge">>, <<"243546rf7g68h798j", 0, 23, 255>>,
     <<"hoasfdafdas][">>,
     [0,42, <<"sum">>, [1,2]], [1,42, nil, [3]],
     -234, -40000, -16#10000000, -16#100000000,
     42,
     {[]}, {hoge}
    ].

compare_all([], [])-> ok;
compare_all([],  R)-> {toomuchrhs, R};
compare_all(L,  [])-> {toomuchlhs, L};
compare_all([LH|LTL], [RH|RTL]) ->
    ?assertEqual(LH, RH),
    compare_all(LTL, RTL).

port_receive(Port) ->
    port_receive(Port, <<>>).
port_receive(Port, Acc) ->
    receive
        {Port, {data, Data}} -> port_receive(Port, <<Acc/binary, Data/binary>>);
        {Port, eof} -> Acc
    after 1000 -> Acc
    end.

port_jiffy_test()->
    Tests = test_data_jiffy(),
    ?assertEqual({[Tests],<<>>}, msgpack:unpack(msgpack:pack([Tests], [jiffy]), [jiffy)),

                                                %    Port = open_port({spawn, "ruby ../test/crosslang.rb"}, [binary, eof]),
                                                %    true = port_command(Port, msgpack:pack(Tests)),
                                                %    ?assertEqual({Tests, <<>>}, msgpack:unpack(port_receive(Port))),
                                                %    port_close(Port).
                 ok.


port_jsx_test()->
    Tests = test_data_jsx(),
    ?assertEqual({[Tests],<<>>}, msgpack:unpack(msgpack:pack([Tests], [jsx]), [jsx])),

                                                %    Port = open_port({spawn, "ruby ../test/crosslang.rb"}, [binary, eof]),
                                                %    true = port_command(Port, msgpack:pack(Tests)),
                                                %    ?assertEqual({Tests, <<>>}, msgpack:unpack(port_receive(Port))),
                                                %    port_close(Port).
    ok.

unknown_test_freezed_test_dont_do_this()->
    Port = open_port({spawn, "ruby testcase_generator.rb"}, [binary, eof]),
    Tests = [0, 1, 2, 123, 512, 1230, 678908,
             -1, -23, -512, -1230, -567898,
             <<"hogehoge">>, <<"243546rf7g68h798j">>,
             123.123,
             -234.4355, 1.0e-34, 1.0e64,
             [23, 234, 0.23],
             [0,42,<<"sum">>, [1,2]], [1,42, nil, [3]],
             [{1,2},{<<"hoge">>,nil}], % map
             -234, -50000,
             42
            ],
    ?assertEqual(ok, compare_all(Tests, msgpack:unpack_all(port_receive(Port)))),
    port_close(Port).

-endif.

issue_jsx_5_test() ->
    %% {'type':"workers", 'data':[{'workerid': "std.1", 'slots':[] }]}
    Term = [
            {<<"type">>, <<"workers">>},
            {<<"data">>,[
                         [{<<"workerid">>, <<"std.1">>}, {<<"slots">>, []}]
                        ]
            }
           ],
    Encoded = msgpack:pack(Term, [jsx,{enable_str,true}]),
    Bin0 = <<130,196,4,116,121,112,101,196,7,119,111,114,107,101,114,115,
             196,4,100,97,116,97,145,130,196,8,119,111,114,107,101,114,105,100,
             196,5,115,116,100,46,49,196,5,115,108,111,116,115,160>>,
    ?assertEqual(Bin0, Encoded),

    {ok, Decoded} = msgpack:unpack(Bin0, [jsx,{enable_str,true}]),
    ?assertEqual(Term, Decoded).


issue_jiffy_5_test() ->
    %% {'type':"workers", 'data':[{'workerid': "std.1", 'slots':[] }]}
    Term = {[
             {<<"type">>, <<"workers">>},
             {<<"data">>,[
                          {[{<<"workerid">>, <<"std.1">>},{<<"slots">>, []}]}
                         ]
             }
            ]},
    Encoded = msgpack:pack(Term, [jiffy,{enable_str,true}]),
    Bin0 = <<130,196,4,116,121,112,101,196,7,119,111,114,107,101,114,115,
             196,4,100,97,116,97,145,130,196,8,119,111,114,107,101,114,105,100,
             196,5,115,116,100,46,49,196,5,115,108,111,116,115,160>>,
    ?assertEqual(Bin0, Encoded),

    {ok, Decoded} = msgpack:unpack(Bin0, [jiffy,{enable_str,true}]),
    ?assertEqual(Term, Decoded).


string_test() ->
    {ok, CWD} = file:get_cwd(),
    Path = CWD ++ "/../test/utf8.txt",
    {ok, UnicodeBin} = file:read_file(Path),
    String = unicode:characters_to_list(UnicodeBin),
    MsgpackStringBin = msgpack:pack(String),
    {ok, String} = msgpack:unpack(MsgpackStringBin).



unpack_test_() ->
    [
     {"not binary",
      ?_assertEqual({error, {badarg, []}}, unpack([]))},

     {"incomplete: null binary",
      ?_assertEqual({error, incomplete}, unpack(<<>>))},

     {"incomplete: unknown binary",
      ?_assertEqual({error, incomplete}, unpack(<<16#DA>>))}
    ].

array_test_()->
    [
     {"length 16",
      fun() ->
              List = lists:seq(0, 16),
              Binary = pack(List),
              ?assertEqual({ok, List}, unpack(Binary))
      end},
     {"length 32",
      fun() ->
              List = lists:seq(0, 16#010000),
              Binary = pack(List),
              ?assertEqual({ok, List}, unpack(Binary))
      end},
     {"empty",
      fun() ->
              EmptyList = [],
              Binary = pack(EmptyList),
              ?assertEqual({ok, EmptyList}, unpack(Binary))
      end}
    ].

map_test_()->
    [
     {"jiffy length 16",
      fun() ->
              Map = {[ {X, X * 2} || X <- lists:seq(0, 16) ]},
              Binary = pack(Map, [jiffy]),
              ?assertEqual({ok, Map}, unpack(Binary, [jiffy]))
      end},
     {"jiffy length 32",
      fun() ->
              Map = {[ {X, X * 2} || X <- lists:seq(0, 16#010000) ]},
              Binary = pack(Map, [jiffy]),
              ?assertEqual({ok, Map}, unpack(Binary, [jiffy]))
      end},
     {"jiffy empty",
      fun() ->
              EmptyMap = {[]},
              Binary = pack(EmptyMap, [jiffy]),
              ?assertEqual({ok, EmptyMap}, unpack(Binary, [jiffy]))
      end},
     {"jsx length 16",
      fun() ->
              Map = [ {X, X * 2} || X <- lists:seq(0, 16) ],
              Binary = pack(Map, [jsx]),
              ?assertEqual({ok, Map}, unpack(Binary, [jsx]))
      end},
     {"jsx length 32",
      fun() ->
              Map = [ {X, X * 2} || X <- lists:seq(0, 16#010000) ],
              Binary = pack(Map, [jsx]),
              ?assertEqual({ok, Map}, unpack(Binary, [jsx]))
      end},
     {"jsx empty",
      fun() ->
              EmptyMap = [{}],
              Binary = pack(EmptyMap, [jsx]),
              ?assertEqual({ok, EmptyMap}, unpack(Binary, [jsx]))
      end}
    ].

int_test_() ->
    [
     {"",
      fun() ->
              Term = -2147483649,
              Binary = pack(Term),
              ?assertEqual({ok, Term}, unpack(Binary))
      end}
    ].

error_test_()->
    [
     {"badarg atom",
      ?_assertEqual({error, {badarg, atom}},
                    pack(atom))},
     {"badarg tuple",
      fun() ->
              Term = {"hoge", "hage", atom},
              ?assertEqual({error, {badarg, Term}},
                           pack(Term))
      end}
    ].

binary_test_() ->
    [
     {"0 byte",
      fun() ->
              Binary = pack(<<>>),
              ?assertEqual({ok, <<>>}, unpack(Binary))
      end}
    ].

%% long_binary_test_()->
%%     [
%%         {"long binary",
%%             fun() ->
%%                     A = pack(1),
%%                     B = pack(10),
%%                     C = pack(100),
%%                     ?assertEqual({[1,10,100], <<>>},
%%                                  unpack(list_to_binary([A, B, C])))
%%             end}
%%     ].

%% benchmark_test()->
%%     Data = [test_data() || _ <- lists:seq(0, 10000)],
%%     {ok, S} = ?debugTime("  serialize", pack(Data)),
%%     {ok, Data} = ?debugTime("deserialize", unpack(S)),
%%     ?debugFmt("for ~p KB test data.", [byte_size(S) div 1024]),
%%     ok.
