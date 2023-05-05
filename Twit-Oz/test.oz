declare    
%Takes a String and remove all non Ascii Character
fun {Clean Input}
   case Input of nil then nil
   [] H|T then 
      if {Char.isCntrl H} then
         32|46|32|{Clean T}
      else 
         if {Char.isAlNum H} then
               if H >= 126 then
                  32|{Clean T}
               else
                  {Char.toLower H}|{Clean T}
               end
         else
            if {Char.isPunct H} then
               32|46|32|{Clean T}
            else
               32|{Clean T}
            end
         end
      end
   end
end

proc {AlphaName Num}
   if Num < 200 then
      skip
   else
      {Browse {String.toAtom Num|nil}}
      {AlphaName Num-1}
   end
end

fun {NilatorHelp ListSimplePointSplit Ngram}
   if Ngram =< 1 then
      ListSimplePointSplit
   else
      {NilatorHelp nil|ListSimplePointSplit Ngram-1}
   end
end

fun {Nilator ListPointSplit Ngram}
   case ListPointSplit of nil then nil
   [] H|T then {NilatorHelp H Ngram}|{Nilator T Ngram}
   end
end

fun {SplitHelper Input}
   case Input of nil then nil
   [] H|T then {List.filter {String.tokens H & } fun {$ O} O \= nil end}|{SplitHelper T}
   end
end

fun {Split Input}
   {SplitHelper {String.tokens {Clean Input} &.}}
end

%Word: le mot en byteString à trouver     File: un fichier lu et séparé en byteString
%Flag: si le mot précédent est bien Word  Acc: contient un Dictionnaire qui est mis à jour 
fun {TrainingWord Word File PassFile Acc Track} Retrieve Name in
   %{Browse File}

   case File of nil then 
      Acc
   [] H|T then
      if Track>{List.length Word} then
         Name={String.toAtom H}
         Retrieve={Value.condSelect Acc Name 0}+1
         {TrainingWord Word {List.take PassFile 1}.1|H|T PassFile {Record.adjoin Acc a(Name : Retrieve)} 1}
      else
         if H=={List.nth Word Track} then
               {TrainingWord Word T H|PassFile Acc Track+1}
         else
            if Track > 1 then
               {TrainingWord Word H|T PassFile Acc 1}
            else
               {TrainingWord Word T H|PassFile Acc 1}
            end
         end
      end

   end
end

fun {TrainingWordHelper Word BigFiles Acc}
   case BigFiles of nil then Acc
   [] H|T then {TrainingWordHelper Word T {TrainingWord Word {NilatorHelp H 2}  nil a() 1}}
   end
end


{Browse 'Starting'}
{Browse {Split "hello, how are you"}}

{Browse {TrainingWordHelper [nil "hello"] {Split "hello, how are you"} a()}}

{Browse 'Nilator'}
{Browse {NilatorHelp "hello it is" 2}}
