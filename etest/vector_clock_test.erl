-include_lib("eunit.hrl").

increment_clock_test() ->
  Clock = create(a),
  Clock2 = increment(b, Clock),
  [{a, 1}, {b, 1}] = Clock2,
  Clock3 = increment(a, Clock2),
  [{a, 2}, {b, 1}] = Clock3,
  Clock4 = increment(b, Clock3),
  [{a, 2}, {b, 2}] = Clock4,
  Clock5 = increment(c, Clock4),
  [{a, 2}, {b, 2}, {c, 1}] = Clock5,
  Clock6 = increment(b, Clock5),
  [{a, 2}, {b, 3}, {c, 1}] = Clock6.
  
concurrent_test() ->
  ClockA = [{b, 1}],
  ClockB = [{a, 1}],
  concurrent = compare(ClockA, ClockB),
  concurrent = compare(ClockB, ClockA).

less_than_causal_test() ->
  ClockA = [{a,2}, {b,4}, {c,1}],
  ClockB = [{c,1}],
  less = compare(ClockB, ClockA),
  greater = compare(ClockA, ClockB).
 
less_than_causal_2_test() ->
  ClockA = [{a,2}, {b,4}, {c,1}],
  ClockB = [{a,3}, {b,4}, {c,1}],
  less = compare(ClockA, ClockB),
  greater = compare(ClockB, ClockA).
 
simple_merge_test() ->
  ClockA = [{a,1}],
  ClockB = [{b,1}],
  [{a,1},{b,1}] = merge(ClockA,ClockB).
  
overlap_equals_merge_test() ->
  ClockA = [{a,3},{b,4}],
  ClockB = [{a,3},{c,1}],
  [{a,3},{b,4},{c,1}] = merge(ClockA, ClockB).
  
overlap_unequal_merge_test() ->
  ClockA = [{a,3},{b,4}],
  ClockB = [{a,4},{c,5}],
  [{a,4},{b,4},{c,5}] = merge(ClockA, ClockB).

compare_test() ->
  Tests = [
    {[{a, 2}], [{a, 1}], greater},
    {[{a, 2}], [{a, 2}], equal},
    {[{a, 2}], [], greater},
    {[],       [{a, 2}], less},
    {[{a, 2}], [{b, 2}], concurrent},
    {[{a, 2}, {b, 3}], [{b, 2}], greater},
    {[{a, 2}, {b, 1}], [{b, 2}], concurrent}
    ],
  [{A,B,Res} = {A,B,compare(A, B)} || {A, B, Res} <- Tests].
