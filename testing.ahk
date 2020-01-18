#SingleInstance, Force
#NoEnv

SetWorkingDir %A_ScriptDir%
SendMode Input

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

ENABLE_DEBUG := false   ; Enable to show detailed debug info 
var := EncodeWord("the")
MsgBox %var%
ExitApp
return

EncodeWord(Word) {
  Result := ""
  word := RegExReplace( word, "\W", "7" ) ; Replace all non standard characters with 7s, aka a symbol
  StringSplit Char, Word
  Loop %Char0% {
    ThisChar := Char%A_Index%
    Result .= ( RegExMatch( ThisChar, "\d" ) ? ThisChar : Char_%ThisChar% ) ; concatenate the next character to the result
  }  
  Return Result
}