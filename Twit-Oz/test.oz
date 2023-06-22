functor
import 
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Open
   Browser
define 
   proc {Browse Buf}
      {Browser.browse Buf}
   end

   fun {RemoveEnd PathList}
      case PathList
      of nil then "" 
      [] H|T then 
         if T == nil then 
            "" 
         else
            if T.2 == nil then 
               H#{RemoveEnd T}
            else
               H#"/"#{RemoveEnd T}
            end
         end
      end
   end


   proc{Read Input} Test Content Before After Garbage TweetSnip Rest Res NewMake NewFile Path WOTxt TXT CleanPath in

      thread
         Path={QTk.dialogbox load(initialdir:"./" title:"New Tweets Folder" $)}
      end
      if Path==nil then
         skip
      else
         {String.token Path &. WOTxt TXT}
         %{Browse {String.toAtom Path}}
         CleanPath = {VirtualString.toString {RemoveEnd {String.tokens WOTxt &/}}}
      end

      Test = {New Open.file init(name:{String.toAtom Input} flags:[read])}
      {Test read(list:Content size:all)}

      {String.token Content &= Before After}
      {String.token After &" Garbage Rest}
      {String.token Rest &" TweetSnip Res}

      %{Browse {String.toAtom Before}}
      %{Browse {String.toAtom Rest}}
      %{Browse {String.toAtom TweetSnip}}
      %{Browse {String.toAtom Res}}

      NewMake = Before#{Atom.toString '="'}#CleanPath#{Atom.toString '"'}#Res 
      %{Browse {String.toAtom {VirtualString.toString NewMake}}}

      {Test close}

      NewFile = {New Open.file init(name:'Makefile' flags:[write] mode:mode(owner:[write] all:[write] group:[write] others:[write]))}
      {NewFile write(vs:{VirtualString.toString NewMake} len:{List.length {VirtualString.toString NewMake}})}
      {NewFile close}
end

{Read "Makefile"}
end