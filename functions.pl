:-use_module(library(clpfd)).
:-consult(graph).
%----------------------------------------------------
%checks if two paths parts are the same edge
match(X,Y,X,Y).
match(X,Y,Y,X).
%----------------------------------------------------
%generates a list of the number D
durations(_,0,[]).
durations(D,N,[D|L]):-
  N>0,
  N1 is N-1,
  durations(D,N1,L).
%----------------------------------------------------
%ensures a duration D between parts L (which are parts of the timelines chosen before)
s1(_,[_]).
s1(_,[]).
s1(D,L):-
  length(L,N),
  N>1,
  durations(D,N,Ds),
  serialized(L,Ds).
%----------------------------------------------------
%ensures that the differece between the single-line parts are at least D minutes
s2_2(_,_,[]).
s2_2(D,X,[Y|L]):-
  absDiff(X,Y,D),
  s2_2(D,X,L).
%----------------------------------------------------
%iterates over all parts that head X->Y and Y->X
s2(_,[],_).
s2(D,[H|L],L2):-
  s2_2(D,H,L2),
  s2(D,L,L2).
%----------------------------------------------------
%enforces constraints on a single line
single(X,Y,L):-
  single(X,Y,L,L2,L3),
  d(X,Y,D),
  s1(10,L2),%ensures 10 minutes between single-line parts of the timelines that take the line X->Y
  s1(10,L3),%ensures 10 minutes between single-line parts of the timelines that take the line Y->X
  s2(D,L2,L3).%ensures trains wait for each other if they take lines in different directions
%----------------------------------------------------
%takes all timelines and returns 2 lists. The first is the parts of the timelines the edge and the second is the parts of the timelines using the edge in the other direction.
single(X,Y,[[e(X,Y,S)|L]|L1],[S|L2],L3):-
  single(X,Y,[L|L1],L2,L3).

single(X,Y,[[e(Y,X,S)|L]|L1],L2,[S|L3]):-
  single(X,Y,[L|L1],L2,L3).

single(X,Y,[[e(X1,Y1,_)|L]|L1],L2,L3):-
  \+match(X,Y,X1,Y1),
  single(X,Y,[L|L1],L2,L3).

single(X,Y,[[e(_,_,_,_)|L]|L1],L2,L3):-
  single(X,Y,[L|L1],L2,L3).

single(X,Y,[[]|L1],L2,L3):-
  single(X,Y,L1,L2,L3).

single(_,_,[],[],[]).
%----------------------------------------------------
%separates pairs into 2 lists
separate([],[],[]).
separate([(S,I)|Ls],[S|Ss],[I|Is]):-
  separate(Ls,Ss,Is).
%----------------------------------------------------
% it creates two lists
starts([],[],[],[],_).
starts([S|Ss],[I|Is],[S1|Ss1],[S2|Ss2],N):-% is a number that's not valid and it's used whenever the train takes the other line instead.
  %when a train takes a double-edged only S1 or S2 is valid so when S1 is a valid number S2 has the fake value N and vice verca.
  S1 #= S*(2-I)+N*(I-1),
  S2 #= S*(I-1)+N*(2-I),
  N1 is N-100,
  starts(Ss,Is,Ss1,Ss2,N1).
%----------------------------------------------------
%handle parts taking each edge in the same direction
d1(D,L):-
  length(L,N),
  durations(D,N,Ds),
  separate(L,Ss,Is),
  starts(Ss,Is,Ss1,Ss2,-10),
  %I add two serialized predicates to handle both edges of the double lines
  serialized(Ss1,Ds),
  serialized(Ss2,Ds).
%----------------------------------------------------
% if two parts happens to be in the same line of the double-edge and in opposite directions then one should wait for the other to finish before starting
d2_2(_,_,[]).
d2_2(D,(X,I1),[(Y,I2)|L]):-
  (I1#=I2)#<==> Eq,
  X1 #= Eq*X, Y1#= Eq*Y, D1 #= Eq*D,
  absDiff(X1,Y1,D1),
  d2_2(D,(X,I1),L).
%----------------------------------------------------
%iterates over all parts that head X->Y and Y->X
d2(_,[],_).
d2(D,[H|L],L2):-
  d2_2(D,H,L2),
  d2(D,L,L2).
%----------------------------------------------------
%enforces constraints on a double line
double(X,Y,L):-
  double(X,Y,L,L2,L3),
  d(X,Y,D),
  d1(10,L2),%ensures 10 minutes between double-line parts of the timelines that take the line X->Y
  d1(10,L3),%ensures 10 minutes between double-line parts of the timelines that take the line Y->X
  d2(D,L2,L3).%ensures trains wait for each other if they take lines in different directions
%----------------------------------------------------
%takes all timelines and returns 2 lists. The first is the parts of the timelines using any of the double lines and the second is the parts of the timelines using any of the double lines in the other direction.
double(X,Y,[[e(X,Y,I,S)|L]|L1],[(S,I)|L2],L3):-
  double(X,Y,[L|L1],L2,L3).

double(X,Y,[[e(Y,X,I,S)|L]|L1],L2,[(S,I)|L3]):-
  double(X,Y,[L|L1],L2,L3).

double(X,Y,[[e(X1,Y1,_,_)|L]|L1],L2,L3):-
  \+match(X,Y,X1,Y1),
  double(X,Y,[L|L1],L2,L3).

double(X,Y,[[e(_,_,_)|L]|L1],L2,L3):-
  double(X,Y,[L|L1],L2,L3).

double(X,Y,[[]|L1],L2,L3):-
  double(X,Y,L1,L2,L3).

double(_,_,[],[],[]).
%----------------------------------------------------
% it applies a constraint where if (X>Y) X-Y>D otherwise Y-X>D
absDiff(X,Y,D):-
  (X#>Y)#<==>C,
  C*(X-Y)#>=C*D,
  (1-C)*(Y-X)#>=(1-C)*D.
%----------------------------------------------------
%%applies the constrains regarding each edge
constraints(T):-
  bagof((X,Y),D^Y^X^d(X,Y,D),L),
  constraints(T,L).

constraints(_,[]).
constraints(T,[(X,Y)|L]):-
  doubleLine(X,Y), % checks if it's a double line
  double(X,Y,T),%% handles constraints for a single line
  constraints(T,L).

constraints(T,[(X,Y)|L]):-
  \+doubleLine(X,Y), %checks if it's a single line
  single(X,Y,T),%% handles constraints for a single line
  constraints(T,L).
%----------------------------------------------------
% merge([],[]).
% merge([H|L],L2):-
% 	merge(L,L3),
% 	append(H,L3,L2).

% domain(S,E,X,S):-
%   S+X>E.
% domain(S,E,X,D):-
%   S+X=<E,
%   E1 is S+X,
%   D = S\/D1,
%   domain(E1,E,X,D1).
%----------------------------------------------------
%gets a path from S to E
path(S,E,L,Cost):-
	path(S,E,L,Cost,[]).

path(S,S,[],0,_).

path(S,D,[d(S,M,C)|L],Cost2,U):-
	S\=D,
	d(S,M,C),
	\+member(d(S,M,C),U),
  \+member(d(M,S,C),U),
	path(M,D,L,Cost1,[d(S,M,C)|U]),
	Cost2 is Cost1 + C.

path(S,D,[d(S,M,C)|L],Cost2,U):-
	S\=D,
	d(M,S,C),
	\+member(d(M,S,C),U),
  \+member(d(S,M,C),U),
	path(M,D,L,Cost1,[d(S,M,C)|U]),
	Cost2 is Cost1 + C.
%----------------------------------------------------
%gets the shortest path between two vertices S and E
shortest(S,E,P):-
	bagof((L,Cost),path(S,E,L,Cost),Ps),  %gets all paths
	min(Ps,(P,_)). %chooses the shortest path

%----------------------------------------------------
%% min taks a list of pairs of Ps and Cs and returns the pair with the minimum C
min([(P,C)],(P,C)).

min([(P,C)|Ps],(P,C)):-
	Ps\=[],
	min(Ps,(_,C1)),
	C is min(C,C1).

min([(_,C)|Ps],(P1,C1)):-
	Ps\=[],
	min(Ps,(P1,C1)),
	C1 is min(C,C1).

%----------------------------------------------------
% t generates a timeline for a path
t([d(X,Y,D)],[S1,S2],S2,[e(X,Y,S1)],[]):-
  \+doubleLine(X,Y),
  \+doubleLine(Y,X),
  S2#>=S1+D.

t([d(X,Y,D)],[S1,S2],S2,[e(X,Y,I,S1)],[I]):-
  (doubleLine(X,Y);doubleLine(Y,X)),
  S2#>=S1+D.

t([d(X,Y,D)|Ps],[S1,S2|Ss],E,[e(X,Y,S1)|T],Is):-
	Ps\=[],
  \+doubleLine(X,Y),
  \+doubleLine(Y,X),
	S2#>=S1+D,
	t(Ps,[S2|Ss],E,T,Is).

t([d(X,Y,D)|Ps],[S1,S2|Ss],E,[e(X,Y,I,S1)|T],[I|Is]):-
	Ps\=[],
  (doubleLine(X,Y);doubleLine(Y,X)),
	S2#>=S1+D,
	t(Ps,[S2|Ss],E,T,Is).
%----------------------------------------------------
% call_time(G,T) :-
%  statistics(runtime,[T0|_]),
%  G,
%  statistics(runtime,[T1|_]),
%  T is T1 - T0.
%----------------------------------------------------
%the main function which gets the shortest path and generates a timeline for every train set a constraint for when the train can start moving
prep([],[],[],[],[]).
prep([(X,Y,R,_)|Ls],[S|Ss],[E|Es],[T|Ts],[I|Is]):-
  shortest(X,Y,P),
  t(P,S,E,T,I),
  S = [S0|_],S0#>=R,
  prep(Ls,Ss,Es,Ts,Is).
%----------------------------------------------------
%takes a list and returns its sum
sum([],0).
sum([H|L],S):-
  sum(L,S1),
  S #= S1+H.
%----------------------------------------------------
sumDueDate([],0).
sumDueDate([(_,_,_,X)|L],V):-
  sumDueDate(L,V1),
  V is V1+X.
