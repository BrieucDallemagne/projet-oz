declare

A=1
B=2
Ratio={Int.toFloat A} / {Int.toFloat B} %Number/All
InFill=c({Float.toInt (1.0-Ratio)*255.0} {Float.toInt Ratio*255.0} 0)
Test={Float.toInt ~260.0*Ratio}
{Browse Test}