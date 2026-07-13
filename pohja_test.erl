-module(pohja_test).
-export([bench/1, test/0]).
-import(pohja, [html/2, el/3, el/2, el/1, esc/1]).
bench(N) ->
    {Time, _} =
        timer:tc(
            fun() ->
                lists:foreach(
                    fun(_) ->
                        test()
                    end,
                    lists:seq(1, N)
                )
            end
        ),

    io:format("~p us total~n", [Time]),
    io:format("~p us/op~n", [Time / N]).

test() ->
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
    file:write_file("dump2.html", Output).