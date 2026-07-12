-module(linerl).
-compile(export_all).

% html(
%     {
%         e(title, {}, {"My Blog"}),
%         e(script, [{src, "index.js"}], []),
%     },
%     {
%         e(ul, {"class='list'"},
%             {
%                 e(li, [], [])
%             }
%         )
%     }
% )

% io_lib:format(
%     "<meta name=~p content=~p>",
%     ["viewport", "width=device-width, initial-scale=1.0"]
% ).

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
build_attrs([], String) ->
    String;
build_attrs([{Key, Value} | T], String) ->
    Key1 = atom_to_binary(Key),
    Value1 = case Value of
        N when is_integer(N) -> integer_to_binary(Value);
        N when is_atom(N) -> atom_to_binary(Value);
        N when is_list(N) -> list_to_binary(Value);
        _ -> Value
    end,
    Attr = <<"\s", Key1/binary, "=\"", Value1/binary, "\"">>,
    NewString = <<String/binary, Attr/binary>>,
    build_attrs(T, NewString).

e(Tag, Attrs, Content) ->
    Tag1 = atom_to_binary(Tag),
    TagOpen = case Attrs of
        [] -> 
            <<"<", Tag1/binary, ">">>;
        N when is_list(N) -> 
            Str = build_attrs(Attrs),
            <<"<", Tag1/binary, Str/binary, ">">>;
        _ -> 
            error
    end,
    TagClose = <<"</", Tag1/binary, ">">>,
    <<TagOpen/binary, Content/binary, TagClose/binary >>.

    % TagOpen = <<"<", atom_to_binary(Tag), ">">>.

html(Head, Body) ->
    html_head(Head) ++
    html_body(Body) ++
    <<"</html">>.


test() ->
    Head = io_lib:format(
        "<meta name=~p content=~p>",
        ["viewport", "width=device-width, initial-scale=1.0"]
    ),
    Body = <<"Hello">>,
    %file:write_file("dump.html", html(Head, Body)),
    %file:write_file("dump2.html", build_attrs([{src, "index.js"}, {version, 1}])).
    Output = e(script, [{src, "index.js"}, {version, 1}], <<"alert('hello!')">>),
    file:write_file("dump2.html", Output).