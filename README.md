## Example:
```erlang
    List = [
        {1,"Blog Post 1"},
        {2,"Blog Post 2"},
        {3,"Blog Post 3"}
    ],
    IsAdmin = true,
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
    ).
```

## Docs:
Notice that the `html/2` - converts the generated `iolist` to `<<binary>>` format automatically. By default `el/1`, `el/2` and `el/3` returns `iolist` so you have to manually convert those to `<<binary>>` format if you are calling those functions outside `html/2`.

If you want to define `<div>` -elements in `el -functions`, you must use atoms `d`, `dv` or `div_` - this is because `div` is reserved word in erlang.

|Function|Example    |
|--------|-----------|
|html/2  |`html(HeadList, BodyList)`|
|el/1    |`el(br)`|
|el/2    |`el(input, [{name, "title"}, required])`|
|el/3    |`el(h1, [], ["Some title!"])`|
|esc/1   |`esc("<script>alert(\"I am evil script!\")</script>")`|




### Benchmark on example template:
```bash
start_benchmark
13> pohja_tests:bench(10000).
113983 us total
11.3983 us/op
ok
14> pohja_tests:bench(10000).
119034 us total
11.9034 us/op
ok
15> pohja_tests:bench(10000).
125880 us total
12.588 us/op
ok
16> pohja_tests:bench(10000).
123471 us total
12.3471 us/op
ok
17> pohja_tests:bench(10000).
116512 us total
11.6512 us/op

AVG: ~12 microseconds
```