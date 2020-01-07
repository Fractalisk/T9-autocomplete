#NoEnv

#MaxThreadsBuffer On

SetBatchLines, -1

WordListFile := A_ScriptDir . "\WordList.txt" ;path of the wordlist file
SettingsFile := A_ScriptDir . "\Settings.ini" ;path of the settings file

MaxResults := 5 ;maximum number of results to display
OffsetX := 0 ;offset in caret position in X axis
OffsetY := 18 ;offset from caret position in Y axis
BoxHeight := 85 ;height of the suggestions box in pixels
ShowLength := 2 ;minimum length of word before showing suggestions
CorrectCase := True ;whether or not to fix uppercase or lowercase to match the suggestion

NormalKeyList := "a`nb`nc`nd`ne`nf`ng`nh`ni`nj`nk`nl`nm`nn`no`np`nq`nr`ns`nt`nu`nv`nw`nx`ny`nz" ;list of key names separated by `n that make up words in upper and lower case variants
NumberKeyList := "1`n2`n3`n4`n5`n6`n7`n8`n9`n0" ;list of key names separated by `n that make up words as well as their numpad equivalents
OtherKeyList := "'`n-" ;list of key names separated by `n that make up words
ResetKeyList := "Esc`nSpace`nHome`nPGUP`nPGDN`nEnd`nLeft`nRight`nRButton`nMButton`n,`n.`n/`n[`n]`n;`n\`n=`n```n"""  ;list of key names separated by `n that cause suggestions to reset
TriggerKeyList := "Tab`nEnter" ;list of key names separated by `n that trigger completion

;-------------------------------------------------------------------------------
; INIT
;-------------------------------------------------------------------------------

TrayTip, Autocorrect, Press alt-c to terminate

CoordMode, Caret
SetKeyDelay, 0
SendMode, Input

;obtain desktop size across all monitors
SysGet, ScreenWidth, 78
SysGet, ScreenHeight, 79

FileRead, WordList, %WordListFile%
PrepareWordList(WordList)

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

Gosub, ResetWord

SetHotkeys(NormalKeyList,NumberKeyList,OtherKeyList,ResetKeyList,TriggerKeyList)

OnExit, ExitSub
Return

;-------------------------------------------------------------------------------
; WRITE
;-------------------------------------------------------------------------------
;write settings
IniWrite, % URLEncode(MaxResults), %SettingsFile%, Settings, MaxResults
IniWrite, % URLEncode(ShowLength), %SettingsFile%, Settings, ShowLength
IniWrite, % URLEncode(CorrectCase), %SettingsFile%, Settings, CorrectCase

IniWrite, % URLEncode(NormalKeyList), %SettingsFile%, Keys, NormalKeyList
IniWrite, % URLEncode(NumberKeyList), %SettingsFile%, Keys, NumberKeyList
IniWrite, % URLEncode(OtherKeyList), %SettingsFile%, Keys, OtherKeyList
IniWrite, % URLEncode(ResetKeyList), %SettingsFile%, Keys, ResetKeyList
IniWrite, % URLEncode(TriggerKeyList), %SettingsFile%, Keys, TriggerKeyList

;write wordlist file
File := FileOpen(WordListFile,"w")
File.Seek(0)
Length := File.Write(WordList)
File.Length := Length
ExitApp

;-------------------------------------------------------------------------------
; METHODS
;-------------------------------------------------------------------------------

ExitSub:
Gui, Settings:Submit

ExitScript:
ExitApp

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

!1::
!2::
!3::
!4::
!5::
!6::
!7::
!8::
!9::
!0::
Gui, Suggestions:Default
KeyWait, Alt
Key := SubStr(A_ThisHotkey, 2, 1)
GuiControl, Choose, Matched, % Key = 0 ? 10 : Key
Gosub, CompleteWord
Return

#IfWinExist

~BackSpace::
CurrentWord := SubStr(CurrentWord,1,-1)
Gosub, Suggest
Return

Key:
CurrentWord .= SubStr(A_ThisHotkey,2)
Gosub, Suggest
Return

ShiftedKey:
Char := SubStr(A_ThisHotkey,3)
StringUpper, Char, Char
CurrentWord .= Char
Gosub, Suggest
Return

NumpadKey:
CurrentWord .= SubStr(A_ThisHotkey,8)
Gosub, Suggest
Return

ResetWord:
CurrentWord := ""
Gui, Suggestions:Hide
Return

;-------------------------------------------------------------------------------
; SUGGESTION WINDOW
;-------------------------------------------------------------------------------

Suggest:
Gui, Suggestions:Default

;check word length against minimum length
If StrLen(CurrentWord) < ShowLength
{
    Gui, Hide
    Return
}

MatchList := Suggest(CurrentWord,WordList)

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

;-------------------------------------------------------------------------------
; SUGGESTION ALGORITHM
;-------------------------------------------------------------------------------

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

SendWord(CurrentWord,NewWord,CorrectCase)

Gosub, ResetWord
Return

PrepareWordList(ByRef WordList)
{
    If InStr(WordList,"`r")
        StringReplace, WordList, WordList, `r,, All
    While, InStr(WordList,"`n`n") ;remove blank lines within the list
        StringReplace, WordList, WordList, `n`n, `n, All
    WordList := Trim(WordList,"`n") ;remove blank lines at the beginning and end
}

SetHotkeys(NormalKeyList,NumberKeyList,OtherKeyList,ResetKeyList,TriggerKeyList)
{
    Loop, Parse, NormalKeyList, `n
    {
        Hotkey, ~%A_LoopField%, Key, UseErrorLevel
        Hotkey, ~+%A_LoopField%, ShiftedKey, UseErrorLevel
    }

    Loop, Parse, NumberKeyList, `n
    {
        Hotkey, ~%A_LoopField%, Key, UseErrorLevel
        Hotkey, ~Numpad%A_LoopField%, NumpadKey, UseErrorLevel
    }

    Loop, Parse, OtherKeyList, `n
        Hotkey, ~%A_LoopField%, Key, UseErrorLevel

    Loop, Parse, ResetKeyList, `n
        Hotkey, ~*%A_LoopField%, ResetWord, UseErrorLevel

    Hotkey, IfWinExist, AutoComplete ahk_class AutoHotkeyGUI
    Loop, Parse, TriggerKeyList, `n
        Hotkey, %A_LoopField%, CompleteWord, UseErrorLevel
}

Suggest(CurrentWord,ByRef WordList)
{
    Pattern := RegExReplace(CurrentWord,"S).","$0.*") ;subsequence matching pattern

    ;treat accented characters as equivalent to their unaccented counterparts
    Pattern := RegExReplace(Pattern,"S)[a" . Chr(224) . Chr(226) . "]","[a" . Chr(224) . Chr(226) . "]")
    Pattern := RegExReplace(Pattern,"S)[c" . Chr(231) . "]","[c" . Chr(231) . "]")
    Pattern := RegExReplace(Pattern,"S)[e" . Chr(233) . Chr(232) . Chr(234) . Chr(235) . "]","[e" . Chr(233) . Chr(232) . Chr(234) . Chr(235) . "]")
    Pattern := RegExReplace(Pattern,"S)[i" . Chr(238) . Chr(239) . "]","[i" . Chr(238) . Chr(239) . "]")
    Pattern := RegExReplace(Pattern,"S)[o" . Chr(244) . "]","[o" . Chr(244) . "]")
    Pattern := RegExReplace(Pattern,"S)[u" . Chr(251) . Chr(249) . "]","[u" . Chr(251) . Chr(249) . "]")

    Pattern := "`nimS)^" . Pattern ;match options

    ;search for words matching the pattern
    MatchList := ""
    Position := 1
    While, Position := RegExMatch(WordList,Pattern,Word,Position)
    {
        Position += StrLen(Word)
        StringReplace, Word, Word, %A_Tab%, %A_Space%%A_Space%%A_Space%%A_Space%, All ;convert tabs to spaces
        MatchList .= Word . "`n"
    }
    MatchList := SubStr(MatchList,1,-1) ;remove trailing delimiter

    ;sort by score
    SortedMatches := ""
    Loop, Parse, MatchList, `n
        SortedMatches .= Score(CurrentWord,A_LoopField) . "`t" . A_LoopField . "`n"
    SortedMatches := SubStr(SortedMatches,1,-1)
    Sort, SortedMatches, N R ;rank results numerically descending by score
    MatchList := RegExReplace(SortedMatches,"`nmS)^[^`t]+`t") ;remove scores

    Return, MatchList
}

Score(Word,Entry)
{
    Score := 100

    Length := StrLen(Word)

    ;determine prefixing
    Position := 1
    While, Position <= Length && SubStr(Word,Position,1) = SubStr(Entry,Position,1)
        Position ++
    Score *= Position ** 8

    ;determine number of superfluous characters
    RegExMatch(Entry,"`nimS)^" . SubStr(RegExReplace(Word,"S).","$0.*"),1,-2),Remaining)
    Score *= (1 + StrLen(Remaining) - Length) ** -1.5

    Score *= StrLen(Word) ** 0.4

    Return, Score
}

SendWord(CurrentWord,NewWord,CorrectCase = False)
{
    If CorrectCase
    {
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
    }

    ;send the word
    Send, % "{BS " . StrLen(CurrentWord) . "}" ;clear the typed word
    SendRaw, %NewWord%
}

TextWidth(String)
{
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

;-------------------------------------------------------------------------------
; ENCODING
;-------------------------------------------------------------------------------

URLEncode(Text)
{
    StringReplace, Text, Text, `%, `%25, All
    FormatInteger := A_FormatInteger, FoundPos := 0
    SetFormat, IntegerFast, Hex
    While, FoundPos := RegExMatch(Text,"S)[^\w-\.~%]",Char,FoundPos + 1)
        StringReplace, Text, Text, %Char%, % "%" . SubStr("0" . SubStr(Asc(Char),3),-1), All
    SetFormat, IntegerFast, %FormatInteger%
    Return, Text
}

URLDecode(Encoded)
{
    FoundPos := 0
    While, FoundPos := InStr(Encoded,"%",False,FoundPos + 1)
    {
        Value := SubStr(Encoded,FoundPos + 1,2)
        If (Value != "25")
            StringReplace, Encoded, Encoded, `%%Value%, % Chr("0x" . Value), All
    }
    StringReplace, Encoded, Encoded, `%25, `%, All
    Return, Encoded
}

^c::ExitApp
