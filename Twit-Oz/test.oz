declare    
Test=['hello' 'world' 'yo']
Test1=['lmao']

fun {FuseList ListOne ListTwo} 
    case ListTwo of nil then ListOne
    [] H|T then {FuseList ListOne|H T}
    end
 end

{Browse {FuseList Test Test1}}
{Browse Test|Test1}
