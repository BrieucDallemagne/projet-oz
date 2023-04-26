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
    {List.sort {List.map ListInput fun{$ O}{List.foldL O fun{$ X Y} X+Y end 0}#O end } fun{$ X Y}X.1 < Y.1 end}
end

fun {FindClosest Input ListWord Start Track} Close in
    if {List.nth ListWord Start-1}.1 < Input && Input < Track.1 then
        if {Number.abs Input-Track.1} < {Number.abs Input-{List.nth ListWord Start-1}.1} then
            Track
        else
            {List.nth ListWord Start-1}
        end
    else
        if Track.1 < Input && Input < {List.nth ListWord Start+1}.1 then
            if {Number.abs Input-Track.1} < {Number.abs Input-{list.nth ListWord Start-1}.1} then
                Track
            else
                {List.nth ListWord Start+1}
            end
        else
            if Track.1 > Input then
                {FindClosest Input ListWord Start-Start/2 {List.nth ListWord Start-Start/2}}
            else
                {FindClosest Input ListWord Start+Start/2 {List.nth ListWord Start+Start/2}}
            end
        end
    end
end 

Test=["hello" "how" "is"]
Wrong=["helro" "jow" "is"]

ReducedTest={Reducing Test}
{Browse ReducedTest}
ReducedWrong={Reducing Wrong}
{Browse ReducedWrong}

{Browse {FindClosest ReducedWrong.1.1 ReducedTest 2 ReducedTest.2.1 }}