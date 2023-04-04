functor
import 
   QTk at 'x-oz://system/wp/QTk.ozf'
   System
   Application
   Open
   OS
   Property
   Browser

define
    proc{Main}
        local 
            M R
            Desc=message(aspect:200
                        init:"This is a message widget" 
                        handle:M
                        return:R
                        )
        in 
            {{QTk.build td(Desc)} show}
            {M set("Long text for a message widget")}
            {Wait R} % R will be bound when the window is closed
            %{Show {String.toAtom R}}
        end
    end 
    {Main}
end