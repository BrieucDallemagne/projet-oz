declare 
Num=3
List1=[{ByteString.make 'Hello'} {ByteString.make 'World'}]

%Use {ClusterMaker}
fun {SubCluster Input Start Num} Res in
if {List.length Input} < Num then
    {SubCluster {List.append {ByteString.make 'EMPTYSTRING'}|nil Input} Start Num}
else
    if {List.length Input}<Start+Num then
        nil
    else
        Res={List.drop Input Start}
        {List.take Res Num}
    end
end
end

%With Start being 0, split a List of word into packet of Num size of word -->[a b c d] --> [[a b c] [b c d]]
%Input: a List  Start: Where to Start in the List    Num: The size of each subarray
fun {ClusterMaker Input Start Num} Sub in
case Input of nil then nil
[] H|T then
    Sub={SubCluster Input Start Num}
    if Sub==nil then
        nil
    else
        Sub|{ClusterMaker Input Start+1 Num}
    end
end
end


   %Take a List and "mash" them together
   %ex: [a b c d] --> abcd
fun {Mashing Input}
    case Input of nil then ""
    [] H|T then H#{Mashing T}
    end
 end

{Browse 'Résultat'}
{Browse {VirtualString.toString {Mashing{List.map [{ByteString.make "test"} {ByteString.make "test"}] ByteString.toString}}}}
{Browse {String.toAtom {VirtualString.toString {Mashing{List.map [{ByteString.make "test"} {ByteString.make "test"}] ByteString.toString}}}}}
