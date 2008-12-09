-module (vector_clock).
-export ([create/1, increment/2, compare/2, resolve/2, merge/2]).

-ifdef(TEST).
-compile(export_all).
-include("etest/vector_clock_test.erl").
-endif.

create(NodeName) -> [{NodeName, lib_misc:now_float()}].


increment(NodeName, Clock) ->
  orddict:store(NodeName, lib_misc:now_float(), Clock). 

resolve({ClockA, ValuesA}, {ClockB, ValuesB}) ->
  case compare(ClockA, ClockB) of
    less -> {ClockB, ValuesB};
    greater -> {ClockA, ValuesA};
    equal -> {ClockA, ValuesA};
    concurrent -> {merge(ClockA,ClockB), ValuesA ++ ValuesB}
  end.
  
merge(ClockA, ClockB) ->
  PickGreater = fun
    (_Key, AVal, BVal) when AVal > BVal -> AVal;
    (_Key, AVal, BVal) when BVal >= AVal -> BVal
  end,
  orddict:merge(PickGreater, ClockA, ClockB).


% Internal for the comparison fold to make things cleaner
-record(cmp_state, {seen_a_gt = false,
                    seen_eq = false,
                    seen_b_gt = false}).

compare(ClockA, ClockB) ->
  CS = int_compare(ClockA, ClockB, #cmp_state{}),
  case CS of
    #cmp_state{seen_a_gt = true,
               seen_b_gt = false} -> greater;
    #cmp_state{seen_a_gt = false,
               seen_b_gt = true} -> less;
    #cmp_state{seen_a_gt = true,
               seen_b_gt = true} -> concurrent;
    #cmp_state{seen_a_gt = false,
               seen_b_gt = false,
               seen_eq = true} -> equal
  end.

%% A shared node
int_compare([{Node, ValA} | RestA],
            [{Node, ValB} | RestB],
            CState) ->
  NewCS = if
    ValA > ValB   -> CState#cmp_state{seen_a_gt = true};
    ValA =:= ValB -> CState#cmp_state{seen_eq = true};
    ValB > ValA   -> CState#cmp_state{seen_b_gt = true}
  end,
  int_compare(RestA, RestB, NewCS);

% A node one has but the other doesn't
int_compare(A = [{NodeA, ValA} | RestA],
            B = [{NodeB, ValB} | RestB],
            CState) ->
  if
    NodeA < NodeB ->
      int_compare(RestA, B, CState#cmp_state{seen_a_gt = true});
    NodeB < NodeA ->
      int_compare(A, RestB, CState#cmp_state{seen_b_gt = true})
  end;

% A has more elements
int_compare(A = [Hd | Rest],
            B = [], CState) ->
  CState#cmp_state{seen_a_gt = true};

% B has more elements
int_compare(A = [],
            B = [Hd | Rest], CState) ->
  CState#cmp_state{seen_b_gt = true};

% Out of elements
int_compare([], [], CState) -> CState.
