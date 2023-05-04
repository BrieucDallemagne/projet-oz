declare 

fun {FakeFold List Acc}
    case List of nil then nil
    [] H|T then H+Acc|{FakeFold T H+Acc}
    end
end

fun {LoadBalancer NumFiles NbThreads Remaining}
    if Remaining < 2*(NumFiles div NbThreads) then
       Remaining|nil
    else
       (NumFiles div NbThreads)|{LoadBalancer NumFiles NbThreads Remaining-(NumFiles div NbThreads)}
    end
 end

 {Browse {FakeFold {LoadBalancer 259 4 259} ~{LoadBalancer 259 4 259}.1}}