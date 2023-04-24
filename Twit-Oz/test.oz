declare
%Takes a String, clean and put each word in a list
fun {Split Input}
    {List.filter {String.tokens Input & } fun {$ O} O \= nil end}
end

fun {SplitMultiple ListInput}
    case ListInput of nil then nil
    [] H|T then {Split H}|{SplitMultiple T}
    end
end
 
Test="Hello world"

{Browse {Split Test}}