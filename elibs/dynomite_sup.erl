%%%-------------------------------------------------------------------
%%% File:      dynomite_sup.erl
%%% @author    Cliff Moon <cliff@powerset.com> []
%%% @copyright 2008 Cliff Moon
%%% @doc  
%%%
%%% @end  
%%%
%%% @since 2008-06-27 by Cliff Moon
%%%-------------------------------------------------------------------
-module(dynomite_sup).
-author('cliff moon').

-behaviour(supervisor).

%% API
-export([start_link/2]).

%% Supervisor callbacks
-export([init/1]).

-include("config.hrl").

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================
%%--------------------------------------------------------------------
%% @spec start_link() -> {ok,Pid} | ignore | {error,Error}
%% @doc Starts the supervisor
%% @end 
%%--------------------------------------------------------------------
start_link(Config, Options) ->
    supervisor:start_link(dynomite_sup, [Config, Options]).

%%====================================================================
%% Supervisor callbacks
%%====================================================================
%%--------------------------------------------------------------------
%% @spec init(Args) -> {ok,  {SupFlags,  [ChildSpec]}} |
%%                     ignore                          |
%%                     {error, Reason}
%% @doc Whenever a supervisor is started using 
%% supervisor:start_link/[2,3], this function is called by the new process 
%% to find out about restart strategy, maximum restart frequency and child 
%% specifications.
%% @end 
%%--------------------------------------------------------------------
init([Config, Options]) ->
    {ok,{{one_for_one,10,1}, [
			{configuration, {configuration,start_link,[Config]}, permanent, 1000, worker, [configuration]},
			{stats_server, {stats_server,start_link,[]}, permanent, 1000, worker, [stats_server]},
      {storage_server_sup, {storage_server_sup,start_link,[Config]}, permanent, 10000, supervisor, [storage_server_sup]},
      {sync_manager, {sync_manager,start_link,[]}, permanent, 1000, worker, [sync_manager]},
      {sync_server_sup, {sync_server_sup,start_link,[Config]}, permanent, 10000, supervisor, [sync_server_sup]},
      {membership, {membership,start_link,[Config]}, permanent, 1000, worker, [membership]},
      {mediator, {mediator,start_link,[Config]}, permanent, 1000, worker, [mediator]},
      {dynomite_web, {dynomite_web,start,[Options]}, permanent, 1000, worker, [dynomite_web]},
      {socket_server, {socket_server,start_link,[Config]}, permanent, 1000, worker, [socket_server]},
      {thrift_service, {thrift_service,start_link,[Config]}, permanent, 1000, worker, [thrift_service]}
    ]}}.

%%====================================================================
%% Internal functions
%%====================================================================
