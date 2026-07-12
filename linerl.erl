-module(linerl).
-compile(export_all).

html_head(Head) ->
    [
        <<"<!DOCTYPE html>">>,
        <<"<html lang=\"en\">">>,
        <<"<head>">>,
        <<"<meta charset=\"UTF-8\">">>,
        <<"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">">>,
        Head,
        <<"</head>">>
    ].
html_body(Body) ->
    [
        <<"<body>">>,
        Body,
        <<"</body>">>
    ].

build_attrs(Attrs) ->
    build_attrs(Attrs, <<>>).
build_attrs([], Str) ->
    Str;
build_attrs([{Key, Val} | T], Str) ->
    Key1 = atom_to_binary(Key),
    Val1 = case Val of
        N when is_integer(N) -> integer_to_binary(Val);
        N when is_atom(N) -> atom_to_binary(Val);
        N when is_list(N) -> list_to_binary(Val);
        N when is_float(N) -> float_to_binary(Val);
        _ -> Val
    end,
    Attr = <<"\s", Key1/binary, "=\"", Val1/binary, "\"">>,
    NewStr = <<Str/binary, Attr/binary>>,
    build_attrs(T, NewStr).

el(Tag) ->
    TagOpen = atom_to_binary(Tag),
    <<"<", TagOpen/binary, ">">>.
el(Tag, Attrs, Content) ->
    %Tag1 = atom_to_binary(Tag),
    Tag1 = case Tag of
        % for taken keywords like "div"; we must use hacks like these...
        (d) -> <<"div">>;
        (_) -> atom_to_binary(Tag)
    end,
    TagOpen = case Attrs of
        [] -> 
            <<"<", Tag1/binary, ">">>;
        N when is_list(N) -> 
            Str = build_attrs(Attrs),
            <<"<", Tag1/binary, Str/binary, ">">>;
        _ -> 
            error
    end,
    Content1 = case Content of
        [] -> <<"">>;
        _ when is_binary(Content) -> Content;
        _ -> list_to_binary(Content)
    end,
    TagClose = <<"</", Tag1/binary, ">">>,
    <<TagOpen/binary, Content1/binary, TagClose/binary >>.

iter(Els) ->
    iter(Els, <<>>).
iter([], Str) ->
    Str;
iter([H|T], Str) ->
    NewStr = <<Str/binary, H/binary>>,
    iter(T, NewStr).

html(Head, Body) ->
    html_head(iter(Head)) ++
    html_body(iter(Body)) ++
    <<"</html>">>.

test() ->
    Output = 
    html(
        [
            el(meta, [{version, 7}], []),
            el(title, [], <<"My Blog!">>)
        ],
        [
            el(d, [], [<<"Hello friends">>]),
            el(br),
            el(hr)
        ]
    ),    
    file:write_file("dump2.html", Output).

        % el(script, [{src, "index.js"}, {version, 1}], list_to_binary("alert('world!')"))


            % el(div, [{class, container}, {style, "background-color: black;"}], [])


        %el(script, [{version, 1}], list_to_binary("alert('world!')"))