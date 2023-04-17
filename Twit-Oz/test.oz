declare 
Temp={String.toAtom {ByteString.toString {ByteString.make "Test"}}}
Test=a(Temp:5 'mama':4 'aml':1)

   %Just a HELPER procedure to find the biggest value.  YOU SHOULD CALL {FingBiggestDic Dic} RATHER
   fun {FindBiggestDictHelper List Biggest Name}
    case List of nil then Name
    [] H|T then
       if H.2 > Biggest then
          {FindBiggestDictHelper T H.2 H.1}
       else
          {FindBiggestDictHelper T Biggest Name}
       end
    end
 end

 %Find the key with the highest number
 fun {FindBiggestDict Dic}
    {FindBiggestDictHelper {Record.toListInd Dic} 0 nil}
 end

 {Browse {FindBiggestDict Test}}