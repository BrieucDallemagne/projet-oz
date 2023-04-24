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

fun {Reducing ListInput}
    {List.map ListInput fun{$ O}{List.foldL O fun{$ X Y} X+Y end 0} end }
end

fun {FindClosest Input ListWord Start Track Diff} Close in
    if Start > {List.length ListWord} then
        Track
    else
        Close={Number.abs {Number.'-' Input {List.nth ListWord Start}}}
        if Close < Diff then
            {FindClosest Input ListWord Start+1 Start Close}
        else
            {FindClosest Input ListWord Start+1 Track Diff}
        end
    end
end 

Test=["hello" "how" "is"]
Wrong=["helro" "jow" "is"]

ReducedTest={Reducing Test}
{Browse ReducedTest}
ReducedWrong={Reducing Wrong}
{Browse ReducedWrong}

{Browse 'Shortest'}
{Browse {FindClosest ReducedWrong.1 ReducedTest 1 0 1000}}

TestSecond="âhello"
{Browse {String.toAtom {Filter TestSecond Char.isAlpha}}}