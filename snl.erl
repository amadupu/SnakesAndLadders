
-module(snl).
%% gen_server_mini_template
-behaviour(gen_server).
-export([start_link/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
terminate/2, code_change/3]).
-compile(export_all).
start_link(X) ->
   gen_server:start({local,X}, ?MODULE, [X], []).

%% assuming 8x8 cells, define the ladder climb positions 
%% and snake swallowing positions. make sure the ladder
%% and snake coordinates do not overlap
get_ladders() -> [{2,17} ,{7,64},  {16,40},{27,53},{30,60}].
get_snakes() ->  [{15,3}, {25,11}, {35,10},{42,5}, {63,1}]. 

init([User]) -> 
     process_flag(trap_exit,true),
     error_logger:info_msg("User [~p] Ready~n",[User]),
     {ok, {User, 0}}.


%% initialize user list
initusers(Users) ->
   error_logger:info_msg("Ladders: [~p] ~n Snakes: [~p]~n",[get_ladders(),get_snakes()]),
   [start_link(X) || X <- Users].


%% interface method for each play to toss a dice
play(User) -> 
    gen_server:call(User,{move,random:uniform(6)}).


%% gen_server sync call back for handing play command 
handle_call({move,Num} = _Req, _From, {User, Index} = State) ->
     error_logger:info_msg("User: Index:[~p] Dice:[~p]~n",[Index,Num]),
     NewIndex = Index + Num,
     if 
        NewIndex > 64 ->
          error_logger:info_msg("Exceeded Cell Boundary. Next User Pls~n"),
          {reply,Index,State};
        NewIndex == 64 ->
          error_logger:info_msg("Player [~p] Won!~n",[User]),
          {stop,normal,State};
        true ->
          %% check if belongs to later
          NewIndex1 = check_ladder(NewIndex),
          if 
            NewIndex1 =:= 64 ->
                error_logger:info_msg("Player [~p] Won!~n",[User]),
                {stop,normal,State};
            NewIndex1 =:= NewIndex  ->
                NewIndex2 = check_snakes(NewIndex),
                error_logger:info_msg("[MOVING TO [~p]]~n",[NewIndex2]),
               {reply,NewIndex2,{User,NewIndex2}};
            true -> 
               error_logger:info_msg("[MOVING TO [~p]]~n",[NewIndex1]),
               {reply,NewIndex1,{User,NewIndex1}}
          end
     end.
check_ladder(Index) -> check_ladder(Index,get_ladders()).
check_ladder(Index,[]) ->
      Index;
check_ladder(Index,[{Index,NextIndex}|T]) ->
      error_logger:info_msg("[LADDER CLIMBING TO [~p]]~n",[NextIndex]),
      NextIndex;
check_ladder(Index,[H|T]) -> check_ladder(Index,T).
check_snakes(Index) -> check_snakes(Index,get_snakes()).
check_snakes(Index,[]) ->
      Index;
check_snakes(Index,[{Index,NextIndex}|T]) -> 
      error_logger:info_msg("[SNAKE SWALLOWED TO [~p]]~n",[NextIndex]),
      NextIndex;
check_snakes(Index,[H|T]) -> check_snakes(Index,T).
handle_cast(Request,State) -> {noreply,State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, {User,_} = State) -> 
     error_logger:info_msg("[~p] User finished",[User]),
     ok.
code_change(_OldVsn, State, _Extra) -> {ok, State}.
