-module (fs_storage).
-export ([open/2, close/1, get/2, put/4, has_key/2, delete/2, fold/3]).

-record(file, {
  name,
  path,
  context
}).

% open with the name of the fs directory
open(Directory, Name) ->
  ok = filelib:ensure_dir(Directory ++ "/"),
  TableName = list_to_atom(lists:concat([Name, '/', node()])),
  {ok, Table} = dets:open_file(TableName, [{file, lists:concat([Directory, "/files.dets"])}, {keypos, 2}]),
  {ok, {Directory, TableName}}.

% noop
close({_Directory, Table}) -> dets:close(Table).

fold(Fun, {_Directory, Table}, AccIn) when is_function(Fun) ->
  dets:foldl(fun(#file{name=Key,path=Path,context=Context}, Acc) ->
      {ok, Value} = file:read_file(Path),
      Fun({Key, Context, Value}, Acc)
    end, AccIn, Table).

put(Key, Context, Values, {Directory, Table}) ->
  case dets:lookup(Table, Key) of
    [Record] -> #file{path=HashedFilename} = Record;
    [] -> HashedFilename = create_filename(Directory, Key),
      _Record = not_found
  end,
  {ok, Io} = file:open(HashedFilename, [write]),
  ToWrite = if
    is_list(Values) -> term_to_binary(Values);
    true -> term_to_binary([Values])
  end,
  ok = file:write(Io, ToWrite),
  ok = file:close(Io),
  dets:insert(Table, [#file{name=Key, path=HashedFilename, context=Context}]),
  {ok, {Directory, Table}}.
	
get(Key, {_Directory, Table}) ->
  case dets:lookup(Table, Key) of
	  [] -> {ok, not_found};
	  [#file{path=Path,context=Context}] -> 
	    {ok, Binary} = file:read_file(Path),
	    Values = case (catch binary_to_term(Binary)) of
	      {'EXIT', _} -> [Binary];
	      Terms -> Terms
      end,
	    {ok, {Context, Values}}
  end.
	
has_key(Key, {_Directory, Table}) ->
  case dets:lookup(Table, Key) of
    [] -> {ok, false};
    [_Record] -> {ok, true}
  end.
	
delete(Key, {Directory, Table}) ->
	case dets:lookup(Table, Key) of
	  [] -> {ok, {Directory, Table}};
	  [#file{path=Path}] ->
	    ok = file:delete(Path),
	    ok = dets:delete(Table, Key),
	    {ok, {Directory, Table}}
  end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%	internal functions	
	
create_filename(Directory, Key) ->
  Hash = lists:concat(
    lists:map(
      fun(Int) -> erlang:integer_to_list(Int, 16) end, 
      binary_to_list(
        crypto:sha(
          list_to_binary(Key))))),
  Filename = ensure_against_collisions(Directory, Hash),
  ok = filelib:ensure_dir(Filename),
  Filename.
  
ensure_against_collisions(Directory, Hash) ->
  ensure_against_collisions(Directory, Hash, 0).
  
ensure_against_collisions(Directory, Hash, Append) ->
  Filename = case Append > 0 of
    true -> hash_to_directory(Directory, Hash) ++ "-" ++ integer_to_list(Append);
    false -> hash_to_directory(Directory, Hash)
  end,
  case filelib:is_file(Filename) of
    true -> ensure_against_collisions(Directory, Hash, Append+1);
    false -> Filename
  end.
  
hash_to_directory(Directory, Hash) ->
  hash_to_directory(Directory, Hash, Hash, 3).
  
hash_to_directory(Directory, _Left, Original, 0) ->
  lists:concat([Directory, '/', Original]);
  
hash_to_directory(Directory, [Char|Left], Original, Depth) ->
  hash_to_directory(lists:concat([Directory, '/', [Char]]), Left, Original, Depth-1).
