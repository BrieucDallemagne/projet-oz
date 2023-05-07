declare    
Test=a(hello:1 you:1 and:1 nope:0)
I=0

{Browse {Record.dropWhile Test fun{$ O} {Browse O} true end}}
{Browse {Record.mapInd Test fun{$ A B} a(A) end}}
