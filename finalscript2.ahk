#SingleInstance, Force
#NoEnv
#MaxThreadsBuffer On

SetBatchLines, -1

ENABLE_DEBUG := false   ; Enable to show detailed debug info 

; Set working directory. Elevate permissions if directory needs to be created. Run init
if !FileExist("C:\Program Files\T9-autocomplete") {
    Run *RunAs "%A_ScriptName%"
	FileCreateDir, C:\Program Files\T9-autocomplete
}
SetWorkingDir, C:\Program Files\T9-autocomplete
SendMode Input

Gosub Init
Gosub SetupGUI
SoundPlay *64

return

;-------------------------------------------------------------------------------
; Init
;-------------------------------------------------------------------------------

Init:
Suspend

NumberKeyList := "1`n2`n3`n4`n5`n6`n7`n8`n9`n0" ;list of key names separated by `n that make up words as well as their numpad equivalents
ResetKeyList := "Esc`nSpace`nHome`nPGUP`nPGDN`nEnd`nLeft`nRight`nRButton`nMButton`n,`n.`n/`n[`n]`n;`n\`n=`n```n"""  ;list of key names separated by `n that cause suggestions to reset
TriggerKeyList := "Tab`nEnter" ;list of key names separated by `n that trigger completion


SetHotkeys(NumberKeyList,ResetKeyList,TriggerKeyList)

; Download and read wordlist from google github
If (!FileExist("standardWordList.txt")) 
UrlDownloadToFile https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa.txt, standardWordList.txt

FileRead standardWordList, standardWordList.txt

; Read user defined wordlist, if exists
If FileExist("userWordList.txt")
FileRead userWordList, userWordList.txt

; Concatenate the two wordlists
words := standardWordList . userWordList


Chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789"
Nums  := "88899944455566611112223333rtyijm,ad"
StringSplit Chr, Chars
StringSplit Num, Nums
Loop %Chr0% {
  ThisChr := Chr%A_Index%
  Char_%ThisChr% := Num%A_Index%
}

;Split the wordlist into an array
StringSplit wordArray, words, `n, `r

Loop %wordArray0% {
    If( wordArray%A_Index% = "" )
      Continue
      
    var := wordArray%A_Index%
    RegisterWordVariable(var)
}

GlobalWordIndex := 1
GlobalCapsMode  := 1      ; 123 = abc, Abc, ABC, 123

CapsModeStrings := "abc,Abc,ABC,123"
StringSplit CapsModeString, CapsModeStrings, `,
Suspend Off

Return

SetHotkeys(NumberKeyList,ResetKeyList,TriggerKeyList) {

    Loop, Parse, NumberKeyList, `n 
        Hotkey, ~Numpad%A_LoopField%, NumpadKey, UseErrorLevel

    Loop, Parse, ResetKeyList, `n
        Hotkey, ~*%A_LoopField%, ResetWord, UseErrorLevel

    Hotkey, IfWinExist, AutoComplete ahk_class AutoHotkeyGUI
    Loop, Parse, TriggerKeyList, `n
        Hotkey, %A_LoopField%, ReplaceWord, UseErrorLevel
}

;-------------------------------------------------------------------------------
; Encoding
;-------------------------------------------------------------------------------

RegisterWordVariable(word) {
  ; Gets a word and registers it in the relevant a Word_%Code% variable

  Global 

  NumCode := EncodeWord(word)
  If(!InStr(Word_%NumCode%, word))
    Word_%NumCode% .= word . "`n"
}

EncodeWord(Word) {
  Result := ""
  word := RegExReplace(Word, "\W", "7" ) ; Replace all non standard characters with 7s, aka a symbol
  StringSplit Char, Word
  Loop %Char0% {
    ThisChar := Char%A_Index%
    Result .= ( RegExMatch( ThisChar, "\d" ) ? ThisChar : Char_%ThisChar% ) ; concatenate the next character to the result
  }  
  Return Result
}

;-------------------------------------------------------------------------------
; SetupGUI
;-------------------------------------------------------------------------------

SetupGUI:
;App Settings
MaxResults := 20 ;maximum number of results to display
BoxHeight := 85 ;height of the suggestions box in pixels
OffsetX := 0 ;offset in caret position in X axis
OffsetY := 18 ;offset from caret position in Y axis
ShowLength := 0 ;minimum length of word before showing suggestions

TrayTip, Autocorrect, Press ctrl-c to terminate

CoordMode, Caret
SetKeyDelay, 0
SendMode, Input

;obtain desktop size across all monitors
SysGet, ScreenWidth, 78
SysGet, ScreenHeight, 79

;set up tray menu
Menu, Tray, NoStandard
Menu, Tray, Click, 1
Menu, Tray, Add, Exit, ExitScript

;set up suggestions window
Gui, Suggestions:Default
Gui, Font, s10, Courier New
Gui, +Delimiter`n
Gui, Add, ListBox, x0 y0 h%BoxHeight% 0x100 vMatched gCompleteWord AltSubmit
Gui, -Caption +ToolWindow +AlwaysOnTop +LastFound
hWindow := WinExist()
Gui, Show, h%BoxHeight% Hide, AutoComplete

Gui, Settings:Submit
gosub ResetWord

return

ResetWord:
CurrentWord := ""
Gui, Suggestions:Hide
Return

ExitScript:
ExitApp

CompleteWord:
Critical

;only trigger word completion on non-interface event or double click on matched list
If (A_GuiEvent != "" && A_GuiEvent != "DoubleClick")
    Return

Gui, Suggestions:Default
Gui, Hide

;retrieve the word that was selected
GuiControlGet, Index,, Matched
TempList := "`n" . MatchList . "`n"
Position := InStr(TempList,"`n",0,1,Index) + 1
NewWord := SubStr(TempList,Position,InStr(TempList,"`n",0,Position) - Position)

SendWord(CurrentWord,NewWord)

Gosub, ResetWord
Return

SendWord(CurrentWord,NewWord) {

    Position := 1
    CaseSense := A_StringCaseSense
    StringCaseSense, Locale
    Loop, Parse, CurrentWord
    {
        Position := InStr(NewWord,A_LoopField,False,Position) ;find next character in the current word if only subsequence matched
        If A_LoopField Is Upper
        {
            Char := SubStr(NewWord,Position,1)
            StringUpper, Char, Char
            NewWord := SubStr(NewWord,1,Position - 1) . Char . SubStr(NewWord,Position + 1)
        }
    }
    StringCaseSense, %CaseSense%

    ;send the word
    Send, % "{BS " . StrLen(CurrentWord) . "}" ;clear the typed word
    SendRaw, %NewWord%
}

;-------------------------------------------------------------------------------
; Keybindings
;-------------------------------------------------------------------------------

#IfWinExist AutoComplete ahk_class AutoHotkeyGUI

~LButton::
MouseGetPos,,, Temp1
If (Temp1 != hWindow)
    Gosub, ResetWord
Return

Up::
Gui, Suggestions:Default
GuiControlGet, Temp1,, Matched
If Temp1 > 1 ;ensure value is in range
    GuiControl, Choose, Matched, % Temp1 - 1
Return

Down::
Gui, Suggestions:Default
GuiControlGet, Temp1,, Matched
GuiControl, Choose, Matched, % Temp1 + 1
Return

#IfWinExist

~BackSpace::
CurrentWord := SubStr(CurrentWord,1,-1)
if (StrLen(CurrentWord) > 0) {
    Gosub, Suggest
} else {
    Gosub, ResetWord
}
Return

^c::
Gosub ExitScript

ShiftedKey:
Char := SubStr(A_ThisHotkey,3)
StringUpper, Char, Char
CurrentWord .= Char
Gosub, Suggest
Return

NumpadKey:
CurrentWord .= SubStr(A_ThisHotkey,8) ;8
Gosub, Suggest
Return

;-------------------------------------------------------------------------------
; Suggestion Algorithm
;-------------------------------------------------------------------------------

Suggest:
Gui, Suggestions:Default

;check word length against minimum length
If StrLen(CurrentWord) < ShowLength
{
    Gui, Hide
    Return
}

MatchList := Suggest(CurrentWord)

;check for a lack of matches
If (MatchList = "")
{
    Gui, Hide
    Return
}

;limit the number of results
Position := InStr(MatchList,"`n",True,1,MaxResults)
If Position
    MatchList := SubStr(MatchList,1,Position - 1)

;find the longest text width and add numbers
MaxWidth := 0
DisplayList := ""
Loop, Parse, MatchList, `n
{
    Entry := (A_Index < 10 ? A_Index . ". " : "   ") . A_LoopField
    Width := TextWidth(Entry)
    If (Width > MaxWidth)
        MaxWidth := Width
    DisplayList .= Entry . "`n"
}
MaxWidth += 30 ;add room for the scrollbar
DisplayList := SubStr(DisplayList,1,-1)

;update suggestion interface
GuiControl,, Matched, `n%DisplayList%
GuiControl, Choose, Matched, 1
GuiControl, Move, Matched, w%MaxWidth% ;set the control width
WinGet, id1, ID, A
Acc_Caret := Acc_ObjectFromWindow(id1, OBJID_CARET := 0xFFFFFFF8)
Caret_Location := Acc_Location(Acc_Caret)
PosX := (A_CaretX != "" ? A_CaretX : Caret_Location.x != "" ? Caret_Location.x : 0) + OffsetX
If PosX + MaxWidth > ScreenWidth ;past right side of the screen
    PosX := ScreenWidth - MaxWidth
PosY := (A_CaretY != "" ? A_CaretY : Caret_Location.y != "" ? Caret_Location.y : 0) + OffsetY
If PosY + BoxHeight > ScreenHeight ;past bottom of the screen
    PosY := PosY - BoxHeight - 22
Gui, Show, x%PosX% y%PosY% w%MaxWidth% NoActivate ;show window
Return

;Suggestion algorithm

Suggest(CurrentWord) {
    ;search for words matching the pattern
    tempVar := Word_%CurrentWord%
    loop, 10 {
        tempInt := A_Index - 1
        tempWord = %CurrentWord%%tempInt%
        tempVar .= Word_%tempWord%
    }
    
    MatchList := SubStr(tempVar,1,-1) ;remove trailing delimiter
    Return, MatchList
}

TextWidth(String) {
    static Typeface := "Courier New"
    static Size := 10
    static hDC, hFont := 0, Extent
    If !hFont
    {
        hDC := DllCall("GetDC","UPtr",0,"UPtr")
        Height := -DllCall("MulDiv","Int",Size,"Int",DllCall("GetDeviceCaps","UPtr",hDC,"Int",90),"Int",72)
        hFont := DllCall("CreateFont","Int",Height,"Int",0,"Int",0,"Int",0,"Int",400,"UInt",False,"UInt",False,"UInt",False,"UInt",0,"UInt",0,"UInt",0,"UInt",0,"UInt",0,"Str",Typeface)
        hOriginalFont := DllCall("SelectObject","UPtr",hDC,"UPtr",hFont,"UPtr")
        VarSetCapacity(Extent,8)
    }
    DllCall("GetTextExtentPoint32","UPtr",hDC,"Str",String,"Int",StrLen(String),"UPtr",&Extent)
    Return, NumGet(Extent,0,"UInt")
}

;Acc standard libray to retrieve caret info from apps that handle their own UI: chrome, spotify, visual studio, etc 

Acc_Init()
{
	Static	h
	If Not	h
		h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
}

Acc_ObjectFromWindow(hWnd, idObject = -4)
{
	Acc_Init()
	If	DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hWnd, "UInt", idObject&=0xFFFFFFFF, "Ptr", -VarSetCapacity(IID,16)+NumPut(idObject==0xFFFFFFF0?0x46000000000000C0:0x719B3800AA000C81,NumPut(idObject==0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0,IID,"Int64"),"Int64"), "Ptr*", pacc)=0
	Return	ComObjEnwrap(9,pacc,1)
}

Acc_Location(Acc, ChildId=0, byref Position="") { 
	try Acc.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), ChildId)
	catch
		return
	Position := "x" NumGet(x,0,"int") " y" NumGet(y,0,"int") " w" NumGet(w,0,"int") " h" NumGet(h,0,"int")
	return	{x:NumGet(x,0,"int"), y:NumGet(y,0,"int"), w:NumGet(w,0,"int"), h:NumGet(h,0,"int")}
}
