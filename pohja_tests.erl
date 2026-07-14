-module(pohja_tests).
-include_lib("eunit/include/eunit.hrl").
-export([bench/1]).
-import(pohja, [html/2, el/3, el/2, el/1, esc/1]).
%run: eunit:test(pohja).

c(El) ->
    iolist_to_binary(El).

nested() ->
    List = [
        {1,"Blog Post 1"},
        {2,"Blog Post 2"},
        {3,"Blog Post 3"}
    ],
    c(el(ul, [], lists:map(fun({Id, Title}) -> el(li, [{id, Id}], [Title]) end, List))).
nested_nested() ->
    List = [
        {1,"Blog Post 1"},
        {2,"Blog Post 2"},
        {3,"Blog Post 3"}
    ],
    c(
        el(ul, [], lists:map(
            fun({Id, Title}) ->
                el(li, [{id, Id}], [
                    Title,
                    el(ul, [], [
                        el(li, [], ["Child 1"]),
                        el(li, [], ["Child 2"])
                    ])
                ])
            end,
            List
        ))
    ).


el_1_test() ->
    ?assertEqual(<<"<br>">>, c(el(br))),
    ?assertEqual(<<"<hr>">>, c(el(hr))),
    ?assertEqual(<<"<test1>">>, c(el(list_to_atom("test1")))),
    ?assertError(badarg, el("test")).

el_2_test() ->
    Output = <<"<input type=\"text\" required>">>,
    Output2 = <<"<input type=\"1\" required>">>,
    Output3 = <<"<input type=\"1.53\" required>">>,
    ?assertEqual(Output, c(el(input, [{type, "text"}, required]))),
    ?assertEqual(Output, c(el(input, [{type, text}, required]))),
    ?assertEqual(Output, c(el(input, [{type, ["text"]}, required]))),
    ?assertEqual(Output, c(el(input, [{type, <<"text">>}, required]))),
    ?assertEqual(Output, c(el(input, [{type, [[<<"text">>]]}, required]))),
    ?assertEqual(Output2, c(el(input, [{type, 1}, required]))),
    ?assertEqual(Output3, c(el(input, [{type, 1.53}, required]))),
    ?assertError(badarg, c(el(input, [{type, {asd}}, required]))).

el_3_test() ->
    NestedOutput = <<"<ul><li id=\"1\">Blog Post 1</li><li id=\"2\">Blog Post 2</li><li id=\"3\">Blog Post 3</li></ul>">>,
    NestedNestedOutput = <<"<ul><li id=\"1\">Blog Post 1<ul><li>Child 1</li><li>Child 2</li></ul></li><li id=\"2\">Blog Post 2<ul><li>Child 1</li><li>Child 2</li></ul></li><li id=\"3\">Blog Post 3<ul><li>Child 1</li><li>Child 2</li></ul></li></ul>">>,
    ?assertEqual(NestedOutput, nested()),          
    ?assertEqual(NestedNestedOutput, nested_nested()).

esc_test() ->
    EscapedOutput = <<"<p>&lt;script&gt;alert(&quot;I am evil script!&quot;)&lt;/script&gt;</p>">>,
    StrInput = "<script>alert(\"I am evil script!\")</script>",
    BinInput = <<"<script>alert(\"I am evil script!\")</script>">>,
    ?assertEqual(EscapedOutput, c(el(p, [], [esc(StrInput)]))),
    ?assertEqual(EscapedOutput, c(el(p, [], [esc(BinInput)]))),
    ?assertEqual(<<"<p></p>">>, c(el(p, [], [esc("")]))),
    ?assertEqual(<<"<p></p>">>, c(el(p, [], [esc([])]))),
    ?assertException(error, {bad_generator, {}}, c(el(p, [], [esc({})]))).

html_test() ->
    Scaffold = <<"<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"></head><body></body></html>">>,
    ?assertEqual(Scaffold, c(html([], []))).

bench(N) ->
    {Time, _} =
        timer:tc(
            fun() ->
                lists:foreach(
                    fun(_) ->
                        generate()
                    end,
                    lists:seq(1, N)
                )
            end
        ),

    io:format("~p us total~n", [Time]),
    io:format("~p us/op~n", [Time / N]).

generate() ->
    List = [
        {1,"Blog Post 1"},
        {2,"Blog Post 2"},
        {3,"Blog Post 3"}
    ],
    IsAdmin = false,
    Output = 
        html(
            [
                el(meta, [{version, 7}]),
                el(title, [], <<"My Blog!">>)
            ],
            [
                % for div-element use 'd', 'dv' or 'div_' atom, this is because
                % 'div' is reserved word in erlang and causes syntax error
                el(d, [{class, container}], [
                    el(h1, [], ["My Blog!"]),
                    el(hr),
                    el(br),
                    el(ul, [], 
                        lists:map(fun({Id, Title}) -> el(li, [{id, Id}], [Title]) end, List)
                    ),
                    el(form, [{method, "POST"}, {action, "/blog/new"}], [
                        el(input, [{name, "title"}]), %, required
                        el(br),
                        el(button, [{type, "submit"}], [<<"Submit">>])
                    ]),
                    el(p, [], [esc("<script>alert(\"I am evil script!\")</script>")]),
                    case IsAdmin of
                        true ->
                            el(p, [], "This user is admin");
                        false ->
                            el(p, [], "This user is not admin!")
                    end
                ]),
                el(script, [{src, "index.js"}, {type, module}], [])
            ]
        ),
    byte_size(iolist_to_binary(Output)).