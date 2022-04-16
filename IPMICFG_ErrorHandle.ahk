#SingleInstance, Force
#NoTrayIcon
SendMode Input

Text:="|<IPMICFG>*212$70.wMAVtwS12502NUm84282Ak08b390EE09m00WIIY1100Z9DWNFGE7Ys2IYmD4d90EEb5SG8UGYY1120Ml8W16G84681X4WM4F8SE7U6AG9U"

if (ok:=FindText(X:="wait", Y:=3, 1762-150000, 1212-150000, 1762+150000, 1212+150000, 0, 0, Text)) {
    oUIA := UIA_Interface()
    oAE := oUIA.ElementFromPoint(X + 300, Y + 130)
    oAction := oAE.GetCurrentPatternAs("Invoke")
    oAction.Invoke()
}
ExitApp