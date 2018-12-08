:-consult(functions).
:-use_module(library(clpfd)).

schedule(Timelines,Ends,PathsChoices,Sum):-
  Input = [(f,a,0,240),(i,a,60,270),(i,m,30,210),(m,a,60,300),
           (a,j,180,360),(a,f,120,330),(c,m,90,240),(h,f,30,210),
           (m,g,60,300),(m,d,90,300),(f,i,150,300)],
  prep(Input,Starts,Ends,Timelines,PathsChoices),
  sumDueDate(Input,Ds),
  flatten(Starts,S), S ins 0..Ds,
  flatten(PathsChoices,I), I ins 1..2,
  constraints(Timelines),
  flatten([S,I],L),
  sum(Ends,Sum),
  labeling([min(Sum)],L),
  nl.

program :-
  open("timelines.txt",write,Stream1),
  open("tardiness.txt",write,Stream2),
  open("ends.txt",write,Stream3),
  schedule(Timelines,Ends,PathsChoices,Sum),!,
  write(Stream1, Timelines),
  write(Stream2, Sum),
  write(Stream3, Ends),
  close(Stream1),
  close(Stream2),
  close(Stream3).
