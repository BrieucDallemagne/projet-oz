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

 fun {SplitHelper Input}
    case Input of nil then nil
    [] H|T then {List.filter {String.tokens H & } fun {$ O} O \= nil end}|{SplitHelper T}
    end
 end
 
 fun {Split Input}
    {SplitHelper {String.tokens {Clean Input} &.}}
 end

 fun {Mashing Input}
    case Input of nil then ""
    [] H|T then H#"_"#{Mashing T}
    end
 end

Test="Hello world we are"

{Browse {Clean Test}}
{Browse {Mashing {Split {Clean Test}}.1}}