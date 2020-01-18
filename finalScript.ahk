#SingleInstance, Force
#NoEnv

; Set working directory. Elevate permissions if directory needs to be created. Run init
if (!FileExist("C:\Program Files\T9-autocomplete")) {
	If !(A_IsAdmin){
		Run *RunAs "%A_ScriptName%"
	}
	FileCreateDir, C:\Program Files\T9-autocomplete
}
SetWorkingDir, C:\Program Files\T9-autocomplete
SendMode Input

gosub Init

;Initialization 
Init:
Suspend

NormalKeyList := "a`nb`nc`nd`ne`nf`ng`nh`ni`nj`nk`nl`nm`nn`no`np`nq`nr`ns`nt`nu`nv`nw`nx`ny`nz" ;list of key names separated by `n that make up words in upper and lower case variants
NumberKeyList := "1`n2`n3`n4`n5`n6`n7`n8`n9`n0" ;list of key names separated by `n that make up words as well as their numpad equivalents
OtherKeyList := "'`n-" ;list of key names separated by `n that make up words
ResetKeyList := "Esc`nSpace`nHome`nPGUP`nPGDN`nEnd`nLeft`nRight`nRButton`nMButton`n,`n.`n/`n[`n]`n;`n\`n=`n```n"""  ;list of key names separated by `n that cause suggestions to reset
TriggerKeyList := "Tab`nEnter" ;list of key names separated by `n that trigger completion

; Download and read wordlist from google github
If (!FileExist("standardWordList.txt")) 
UrlDownloadToFile https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-usa.txt, standardWordList.txt

FileRead standardWordList, standardWordList.txt

; Read user defined wordlist, if exists
If FileExist("userWordList.txt")
FileRead userWordList, userWordList.txt

; Concatenate the two wordlists
words := standardWordList . userWordList

;Split the wordlist into an array
StringSplit wordArray, Words, `n, `r
GlobalWordIndex := 1
GlobalCapsMode  := 1      ; 123 = abc, Abc, ABC, 123

CapsModeStrings := "abc,Abc,ABC,123"
StringSplit CapsModeString, CapsModeStrings, `,

OnExit, SetupGUI
Suspend Off

Return

SetupGUI:
;App Settings
MaxResults := 5 ;maximum number of results to display
OffsetX := 0 ;offset in caret position in X axis
OffsetY := 18 ;offset from caret position in Y axis
BoxHeight := 85 ;height of the suggestions box in pixels
ShowLength := 2 ;minimum length of word before showing suggestions
CorrectCase := True ;whether or not to fix uppercase or lowercase to match the suggestion

Gui, Settings:Submit
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
Gosub, ResetWord

SetHotkeys(NormalKeyList,NumberKeyList,OtherKeyList,ResetKeyList,TriggerKeyList)

; Convert Strings into their numerical form for comparison
Encoding:

; Map letter to numpad key and default characters for single digit codes
chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789"
nums  := "88899944455566611112223333rtyijm,ad"
wordCount := 0
StringSplit Chr, Chars
StringSplit Num, Nums
Loop %Chr0% {
ThisChr := Chr%A_Index%
Char_%ThisChr% := Num%A_Index%
}

;Store size of array in wordCount
wordCount := wordArray0
global dictionary := []

; Make one variable for each code, with space separated list of words
Loop %wordCount% {
If (Word%A_Index% = "") {
  Continue
}
encodedText := EncodeWord(Word%A_Index%)
if (!dictionary.HasKey(encodedText)) {
	newEncodedTextList := []
	dictionary.Push([encodedText, newEncodedTextList])
}
; Store each word as a reference to its index in the dictionary instead
encodedTextList := dictionary[%encodedText%]
encodedTextList.push(A_Index)
}

; Add some symbol words
Word_7 := ", . ? @ ! - + / * ( ) "" : % $ #"
Word_77 := ":) `;) :] ?! ??"
Word_777 := "... :-) ??? ?!? !!! --> <--"

EncodeWord(Word) {
	
}

DecodeWord(Word) {

}

; Function to register the word, and sort by weight
RegisterWord(word, weight) {
	
}

; Function to check the word preceeding the caret
CheckPreceeding:

; Function to replace the word preceeding the caret once a hotkey has been entered
ReplaceWord:

; Function to provide a list of words to be suggested from the list of registered words
WordSuggestion:

; Function to provide UI for suggested words
WordSuggestionUI:
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

; GUI Functions
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

;Acc standard library to retrieve caret info from apps that handle their own UI: chrome, spotify, visual studio, etc 

Acc_Init() {
	Static	h
	If Not	h
		h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
}

Acc_ObjectFromWindow(hWnd, idObject = -4) {
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

^c::ExitApp



