declare 
List1="Hello\r my namé is   ç&§ ° How are you? Ã "
NumberWord=2
N=2
Parsed=["this" "another" "test" "this" "is" "the" "test" "for" "the" "test" "the" "test" "the" "test"]|nil
List2=["bonjour comment allez-vous" "hello how are you"]
Test1="... HEllo\r how are you !"


%Takes a String and remove all non Ascii Character
fun {Clean Input}
    case Input of nil then nil
    [] H|T then 
        if {Char.isCntrl H} then
            32|{Clean T}
        else 
          if {Char.isAlpha H} then
                if 195==H then
                    32|{Clean T}
                else
                    H|{Clean T}
                end
          else
             32|{Clean T}
          end
        end
    end
end

%Takes a String, clean and put each word in a list
fun {Split Input}
    {List.filter {String.tokens {Clean Input} & } fun {$ O} O \= nil end}
end

fun {SplitMultiple ListInput}
    case ListInput of nil then nil
    [] H|T then {Split H}|{SplitMultiple T}
    end
end

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
%Input: a List of ByteString  Start: Where to Start in the List    Num: The size of each subarray
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

%Word: le mot en byteString à trouver     File: un fichier lu et séparé en byteString
%Flag: si le mot précédent est bien Word  Acc: contient un Dictionnaire qui est mis à jour 
fun {TrainingWord Word File Acc Track} Size Retrieve Inc Name in


    case File of nil then 
        Acc
    [] H|T then
        if Track>{List.length Word} then
            {Browse H}
            Name={String.toAtom H}
            {Browse Name}
            Retrieve={Value.condSelect Acc Name 0}+1
            {TrainingWord Word File {Record.adjoin Acc a(Name : Retrieve)} 1} %Redoing over the Same input
        else
            if H=={List.nth Word Track} then
                {TrainingWord Word T Acc Track+1}
            else
                {TrainingWord Word T Acc 1}
            end
        end

    end
end

%Take a List and "mash" them together
%ex: [a b c d] --> a_b_c_d
fun {Mashing Input}
    case Input of nil then ""
    [] H|T then H#"_"#{Mashing T}
    end
end

%Cherche parmis tous les fichiers (liste dans Files) un mot et retourner les probas d'avoir un tel comme second
fun {TrainingWordFiles Word Files Acc N} Size NewAcc ByteFiles Mashed in
    Size=NumberWord % Nombre de mots, à remplacer par CountAllWords

    case Files of nil then 
        %Because Dictionnary is not supported by pickle in Oz
        Mashed={VirtualString.toString {Mashing Word}}
        {Pickle.saveWithHeader Acc "Pickle/Word/"#Mashed#".ozp" "Pour "#Mashed 0} %It uses a false compression take 4kb on disk for 24bit
        {Browse 'Finished'}
        Acc
    [] H|T then
        NewAcc={TrainingWord Word H Acc 1} 
        {Browse 'Next'}
        {TrainingWordFiles Word T NewAcc N}
    end
end

fun {FindBiggestHelper List Name Max}
    case List of nil then Name
    [] H|T then
        if H.2 > Max then
            {FindBiggestHelper T H.1 H.2}
        else
            {FindBiggestHelper T Name Max}
        end
    end
end

%Take a Record and return the biggest key for its value
fun {FindBiggest Input} Temp in
    {FindBiggestHelper {Record.toListInd Input} nil 0}
end

proc {PressNgram} InputText CleanText1 CleanText Last Dict TempDict TempRes PlaceHolder WordRecord TempAcc in
    %To get the user's input
    InputText="This is the test"
    Last={List.last {ClusterMaker {Split {Clean InputText}} 0 N}}
    {Browse Last}

    %Read all the Files
    case Parsed of nil then
        {Browse 'We need to read the files'}
    [] H|T then
        {Browse 'Files are already loaded'}
    end

    %Check if the record already exists
    case Parsed of nil then %The correct string {List.member {Mashing Last}#".ozp" {OS.getDir "Pickle/Word"}} then
        {Browse 'Exist'}
        WordRecord={Pickle.load "Pickle/Word/"#{VirtualString.toAtom {ByteString.toString {Mashing Last}}#".ozp"}}
    else
        {Browse 'Working'}
        TempDict=a()
        WordRecord={TrainingWordFiles Last Parsed TempDict N}
    end

    {Browse WordRecord}
    {Browse {FindBiggest WordRecord}}

end


{Browse "Ã"}
{Browse {List.map {Split List1} String.toAtom}}

