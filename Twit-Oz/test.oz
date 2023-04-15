declare 
List1=["a" "b" "c" "d"]

fun {SubCluster Input Start Num} Res in
    if {List.length Input}<Start+Num then
        nil
    else
        Res={List.drop Input Start}
        {List.take Res Num}
    end
end

%With Start being 0, split a List of word into packet of Num size of word -->[a b c d] --> [[a b c] [b c d]]
%Input: a List  Start: Where to Start in the List    Num: The size of each subarray
fun {ClusterMaker Input Start Num} Sub in
    case Input of nil then nil
    [] H|T then
        Sub={SubCluster Input Start Num}
        {Browse Sub}
        if Sub==nil then
            nil
        else
            Sub|{ClusterMaker Input Start+1 Num}
        end
    end
end

Tot={ClusterMaker List1 0 3}
{Browse Tot}
{Browse {List.length Tot}}