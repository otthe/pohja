-module(pohja).
-export([esc/1, html/2, el/1, el/2, el/3]).

-type html_tag() :: atom().

-type html_attr_value() ::
    binary()
    | string()
    | atom()
    | integer()
    | float().

-type html_attr() ::
    atom()
    | {atom(), html_attr_value()}.

-type html_attrs() :: [html_attr()].

-type html_content() ::
    iolist()
    | binary()
    | string()
    | [html_content()].

-type html_node() :: iolist().

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
    attrs_str(Attrs, []).
attrs_str([], Str) ->
    Str;
attrs_str([Key | T], Str) when is_atom(Key) ->
    Key1 = atom_to_binary(Key),
    Attr = ["\s", Key1],
    NewStr = [Str, Attr],
    attrs_str(T, NewStr);
attrs_str([{Key, Val} | T], Str) ->
    Key1 = atom_to_binary(Key),
    Val1 = case Val of
        N when is_integer(N) -> integer_to_binary(Val);
        N when is_atom(N) -> atom_to_binary(Val);
        N when is_list(N) -> unicode:characters_to_binary(Val);
        N when is_float(N) -> float_to_binary(Val, [short]);
        _ -> Val
    end,
    Attr = ["\s", Key1, "=\"", Val1, "\""],
    NewStr = [Str, Attr],
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

iter(Els) ->
    iter(Els, <<>>).
iter([], Str) ->
    Str;
iter([H|T], Str) ->
    iter(T, [Str, H]).

-spec html([html_node()], [html_node()]) -> binary().
html(Head, Body) ->
    iolist_to_binary([
        html_head(iter(Head)),
        html_body(iter(Body)),
        "</html>"
    ]).

-spec el(html_tag()) -> html_node().
el(Tag) ->
    ["<", atom_to_binary(Tag), ">"].

-spec el(html_tag(), html_attrs()) -> html_node().
el(Tag, Attrs) ->
    Tag1 = tag_to_bin(Tag),
    [tag_open(Tag1, Attrs)].

-spec el(html_tag(), html_attrs(), html_content()) -> html_node().
el(Tag, Attrs, Content) ->
    Tag1 = tag_to_bin(Tag),
    [tag_open(Tag1, Attrs), content_to_bin(Content), "</", Tag1, ">"].

%https://ssojet.com/escaping/html-escaping-in-erlang#escaping-html-special-characters
-spec esc(binary() | string()) -> binary() | string().
esc(Str) when is_binary(Str) ->
    unicode:characters_to_binary(
        [esc_char(C) || C <- unicode:characters_to_list(Str)]
    );
esc(Str) ->
    lists:flatten([esc_char(C) || C <- Str]).
esc_char($<) -> "&lt;";
esc_char($>) -> "&gt;";
esc_char($") -> "&quot;";
esc_char($') -> "&apos;";
esc_char($&) -> "&amp;";
esc_char(Other) -> Other.