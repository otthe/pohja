-module(linerl).
-compile(export_all).

%https://ssojet.com/escaping/html-escaping-in-erlang#escaping-html-special-characters
esc(String) ->
    lists:flatten([esc_char(C) || C <- String]).
esc_char($<) -> "&lt;";
esc_char($>) -> "&gt;";
esc_char($") -> "&quot;";
esc_char($') -> "&apos;";
esc_char($&) -> "&amp;";
esc_char(Other) -> Other.

html_head(Head) ->
    [
        "<!DOCTYPE html>",
        "<html lang=\"en\">",
        "<head>",
        "<meta charset=\"UTF-8\">",
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">",
        Head,
        "</head>"
    ].
html_body(Body) ->
    ["<body>", Body, "</body>"].

attrs_str(Attrs) ->
    attrs_str(Attrs, <<>>).
attrs_str([], Str) ->
    Str;
attrs_str([Key | T], Str) when is_atom(Key) ->
    Key1 = atom_to_binary(Key),
    Attr = <<"\s", Key1/binary >>,
    NewStr = <<Str/binary, Attr/binary>>,
    attrs_str(T, NewStr);
attrs_str([{Key, Val} | T], Str) ->
    Key1 = atom_to_binary(Key),
    Val1 = case Val of
        N when is_integer(N) -> integer_to_binary(Val);
        N when is_atom(N) -> atom_to_binary(Val);
        N when is_list(N) -> unicode:characters_to_binary(Val);
        N when is_float(N) -> float_to_binary(Val);
        _ -> Val
    end,
    Attr = <<"\s", Key1/binary, "=\"", Val1/binary, "\"">>, %todo: fix to iolist
    NewStr = <<Str/binary, Attr/binary>>,
    attrs_str(T, NewStr).

tag_to_bin(Tag) ->
    case Tag of
        % for taken keywords like "div"; we must use hacks like these...
        (d) -> <<"div">>;
        (dv) -> <<"div">>;
        (div_) -> <<"div">>;
        (_) -> atom_to_binary(Tag)
    end.

content_to_bin(Content) ->
    case Content of
        [] -> <<"">>;
        _ when is_binary(Content) -> unicode:characters_to_binary(Content);
        _ -> unicode:characters_to_binary(Content)
    end.

tag_open(Tag, Attrs) ->
    case Attrs of
        [] -> 
            ["<", Tag, ">"];
        N when is_list(N) ->
            ["<", Tag, attrs_str(Attrs), ">"]; 
        _ -> 
            error
    end.

el(Tag) ->
    <<"<", (atom_to_binary(Tag))/binary, ">">>.
el(Tag, Attrs) ->
    Tag1 = tag_to_bin(Tag),
    [tag_open(Tag1, Attrs)].
el(Tag, Attrs, Content) ->
    Tag1 = tag_to_bin(Tag),
    [tag_open(Tag1, Attrs), content_to_bin(Content), "</", Tag1, ">"].

iter(Els) ->
    iter(Els, <<>>).
iter([], Str) ->
    Str;
iter([H|T], Str) ->
    iter(T, [Str, H]).

html(Head, Body) ->
    iolist_to_binary([
        html_head(iter(Head)),
        html_body(iter(Body)),
        "</html>"
    ]).
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
    IsAdmin = true,
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
                    el(input, [{name, "title"}, required]),
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
