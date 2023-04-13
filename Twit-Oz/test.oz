declare 
Ozmania='#2020Election\r\n.@seanhannity'|'#2020Election\r\nThe'|'#2020Election\r\n├ó\x80\x9CI'|'#2A.'|'#ISIS'|'#MAGA\r\nHighly'|'#MAGA\r\nI'|'#MAGA\r\nNews'|'#MAGA\r\nWow!'|nil

fun {Clean Input}
    case Input of nil then nil
    [] H|T then 
        if {Char.isCntrl H} then
            {Clean T}
        else
            H|{Clean T}
        end
    end
end
{Browse 'Hello'}
{Browse Ozmania}
{Browse {String.toAtom {Clean "#2020Election\r\n.@seanhannity"}}}
Res={List.map Ozmania fun{$ Input} {Clean {Atom.toString Input}} end}
{Browse {List.map Res String.toAtom}}