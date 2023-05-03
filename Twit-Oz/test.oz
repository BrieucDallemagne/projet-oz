declare 
Test=["hello" "world" "hi"]
{Browse {List.take}}

%si j'ai "hello hello hello world" et que je rentre "hello hello" je voudrais en sortie [[hello, world] 1]
%Avec trainingWord: "hello hello hello world" 1 --> "hello hello world" 2 --> "hello world" 3 --> "hello hello world" 1