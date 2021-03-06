#RequireAdmin
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=Iconka.com-Robot-male.ico
#AutoIt3Wrapper_Outfile_x64=PeakyBuyer.exe
#AutoIt3Wrapper_Res_Description=PeakyBuyer
#AutoIt3Wrapper_Res_Fileversion=1.3
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#AutoIt3Wrapper_Run_Tidy=y
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so /rm /pe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ########## ====================================================================================================================
; Name ..........:  PeakyBuyer, previously known as Simple Autobuyer
; Description ...:  The worst autobuyer ever.
; Author ........:  Pawelek
; Link ..........:  https://github.com/Demogorgon/PeakyBuyer
; ===============================================================================================================================


#include "Include/PeakyBuyerConsts/PeakyBuyerConsts.au3"
#include "Include/GUI/MetroGUI_UDF.au3" ;<--- https://www.autoitscript.com/forum/files/file/365-metrogui-udf/
#include "Include/ImageSearch2015/ImageSearch2015.au3" ; <--- https://www.autoitscript.com/forum/topic/148005-imagesearch-usage-explanation/?do=findComment&comment=1263796

Global $PlayerListFile = ""
SetDefaultPlayerList()

#include "Include/GUI/MainGUI.au3"
#include "Include/GUI/SettingsGUI.au3"

Global Const $bTest = False
Global $Paused = False
Global $WebAppArea[4] = [0, 0, 0, 0] ; StartX, StartY, EndX, EndY
Global $MouseMovementSpeed = 10
Global $PeakyBuyerSpeed = "*1"
Global $AutoRelistTime = 0
Global $CurrentPlayer = 1

Init()

While 1
	_Metro_HoverCheck_Loop($PeakyBuyerGUI);This hover check has to be added to the main While loop, otherwise the hover effects won't work.
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE, $GUI_CLOSE_BUTTON
			_Metro_GUIDelete($PeakyBuyerGUI)
			Exit
		Case $GUI_MAXIMIZE_BUTTON
			GUISetState(@SW_MAXIMIZE)
		Case $GUI_RESTORE_BUTTON
			GUISetState(@SW_RESTORE)
		Case $GUI_MINIMIZE_BUTTON
			GUISetState(@SW_MINIMIZE)
		Case $GUI_FULLSCREEN_BUTTON, $GUI_FSRestore_BUTTON
			_Metro_FullscreenToggle($PeakyBuyerGUI, $Control_Buttons)
		Case $GUI_MENU_BUTTON
			Local $MenuSelect = _Metro_MenuStart($PeakyBuyerGUI, $GUI_MENU_BUTTON, 150, $MenuButtonsArray) ; Opens the metro Menu. See decleration of $MenuButtonsArray
			Switch $MenuSelect ;Above function returns the index number of the button from the provided buttons array.
				Case "0" ;Settings
					_GUIDisable($PeakyBuyerGUI, 0, 30)
					Settings()
					_GUIDisable($PeakyBuyerGUI)
				Case "1" ;GitHub
					ShellExecute("https://github.com/Demogorgon/PeakyBuyer")
				Case "2" ;Donate
					ShellExecute("https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=7T7ZF4GH5ZCZA")
			EndSwitch
		Case $ButtonStart
			StartBuying()
	EndSwitch
WEnd

Func StartBuying()
	DoLogs("=============START=============")
	DoLogs("Current player list: " & StringTrimRight(_StringBetween($PlayerListFile, "PlayerList\", "")[0], 4))
	InitCoords()
	MainSearchLoop()
EndFunc   ;==>StartBuying

Func MainSearchLoop()
	Local $MaxPlayers = _FileCountLines($PlayerListFile)
	Local $hAutoRelistTimer = TimerInit()
	While 1
		If $CurrentPlayer > $MaxPlayers Then $CurrentPlayer = 1
		_SLEEP(100)
		If ($AutoRelistTime > 0 And TimerDiff($hAutoRelistTimer) > ($AutoRelistTime * 60000)) Then
			AutoRelist()
			$hAutoRelistTimer = TimerInit()
		EndIf
		PressReset()
		InputPlayerData()
		WaitForSearchResult()
		If IsArray(CheckSearchResult()) Then
			TryToBuyNow()
		EndIf
		$CurrentPlayer += 1
	WEnd
EndFunc   ;==>MainSearchLoop

Func PressReset()
	DoLogs("Click on reset button.")
	WINAPI_MOUSECLICK($WebAppArea[0] + 80, $WebAppArea[1] + 452, 2)
EndFunc   ;==>PressReset

Func PressSearch()
	DoLogs("Click on search button.")
	WINAPI_MOUSECLICK($WebAppArea[0] + 261, $WebAppArea[1] + 452, 2)
EndFunc   ;==>PressSearch

Func InputPlayerData()
	Local $OldClip = ClipGet() ;save old clipboard to var
	Local $ReadLine = FileReadLine($PlayerListFile, $CurrentPlayer)
	Local $PlayerDataArray = StringSplit($ReadLine, ":")
	If IsArray($PlayerDataArray) And UBound($PlayerDataArray) = 9 Then
		TypePlayerName($PlayerDataArray[1], $PlayerDataArray[3])
		TypePlayerBuyNowMax($PlayerDataArray[2])
		TypeIsPlayerSpecial($PlayerDataArray[4])
		ClipPut($OldClip) ;restore old clipboard
	Else
		DoLogs("Invalid player data in PlayerListFile.", True)
	EndIf
EndFunc   ;==>InputPlayerData

Func TypePlayerName($PlayerName, $PickNumber)
	DoLogs("Player Name: " & $PlayerName & " nr. " & $PickNumber)
	ClipPut($PlayerName)
	WINAPI_MOUSECLICK($WebAppArea[0] + 292, $WebAppArea[1] + 148, 3) ;Click on "Type Player Name"
	_SLEEP(250)
	Send("^a") ; CTRL + a
	Send("{DEL}")
	Send("^v") ; CTRL + V
	_SLEEP(500)
	WINAPI_MOUSECLICK($WebAppArea[0] + 125, $WebAppArea[1] + 130 + (50 * $PickNumber), 2) ;Click on player to accept
	_SLEEP(250)
EndFunc   ;==>TypePlayerName

Func TypePlayerBuyNowMax($BuyNowMax)
	DoLogs("Buy Now Max. " & $BuyNowMax)
	ClipPut($BuyNowMax)
	WINAPI_MOUSECLICK($WebAppArea[0] + 264, $WebAppArea[1] + 387, 2) ; Click on "Buy Now Max."
	_SLEEP(250)
	Send("^a") ; CTRL + a
	Send("{DEL}")
	Send("^v") ; CTRL + V
	_SLEEP(250)
EndFunc   ;==>TypePlayerBuyNowMax

Func TypeIsPlayerSpecial($bPlayerSpecial)
	DoLogs("Player Special Quality: " & $bPlayerSpecial)
	If $bPlayerSpecial == "True" Then
		MouseMove($WebAppArea[0] + 539, $WebAppArea[1] + 235)
		_SLEEP(250)
		WINAPI_MOUSECLICK($WebAppArea[0] + 539, $WebAppArea[1] + 235, 1) ; Choose Quality
		_SLEEP(250)
		WINAPI_MOUSECLICK($WebAppArea[0] + 411, $WebAppArea[1] + 352, 2) ; Click on "Special"
	EndIf
EndFunc   ;==>TypeIsPlayerSpecial

Func WaitForSearchResult()
	Local $iCheckSum = PixelChecksum($WebAppArea[0] + 443, $WebAppArea[1] + 270, $WebAppArea[0] + 526, $WebAppArea[1] + 296)
	PressSearch()
	DoLogs("Waiting for search result...")
	MouseMove($WebAppArea[0] + 480, $WebAppArea[1] + 40, $MouseMovementSpeed)

	Local $exitloop = 0
	While $iCheckSum = PixelChecksum($WebAppArea[0] + 443, $WebAppArea[1] + 270, $WebAppArea[0] + 526, $WebAppArea[1] + 296)
		If $exitloop >= 150 Then ExitLoop ; anti stuck
		Sleep(100)
		$exitloop += 1
	WEnd
EndFunc   ;==>WaitForSearchResult

Func CheckSearchResult()
	Local $SearchResult = False
	Local $ImgOk = False
	Local $ImgBack = False
	Local $OkTol = 130
	DoLogs("Checking search result...")

	Local $exitloop = 0
	While 1
		Sleep(100)
		$ImgOk = PeakyBuyerImgSearch("Ok.png", $WebAppArea[0] + 443, $WebAppArea[1] + 270, $WebAppArea[0] + 526, $WebAppArea[1] + 296, $OkTol)
		If IsArray($ImgOk) Then
			DoLogs("No search results.")
			WINAPI_MOUSECLICK($ImgOk[0], $ImgOk[1], 1) ;Click on "Ok"
			ExitLoop
		EndIf
		$ImgBack = PeakyBuyerImgSearch("Back.png", $WebAppArea[0] + 208, $WebAppArea[1] + 250, $WebAppArea[0] + 254, $WebAppArea[1] + 264, 130)
		If IsArray($ImgBack) Then
			$SearchResult = $ImgBack
			ExitLoop
		EndIf
		If $exitloop >= 100 Then
			$OkTol += 1
		EndIf
		$exitloop += 1
	WEnd
	Return $SearchResult
EndFunc   ;==>CheckSearchResult

Func TryToBuyNow()
	Local $ImgBuynow = False
	Local $ImgBuynowInactive = False
	Local $exitloop = 0
	Local $Clicked = False
	DoLogs("Attempting to buy now player.")

	While 1
		If $exitloop >= 20 Then ExitLoop ; anti stuck
		$ImgBuynowInactive = PeakyBuyerImgSearch("BuyNowInactive.png", $WebAppArea[0] + 764, $WebAppArea[1] + 172, $WebAppArea[0] + 832, $WebAppArea[1] + 189, 65)
		If IsArray($ImgBuynowInactive) Then
			If $Clicked = False Then
				ClickOnCard()
				$Clicked = True
			EndIf
		EndIf
		$ImgBuynow = PeakyBuyerImgSearch("BuyNow.png", $WebAppArea[0] + 764, $WebAppArea[1] + 172, $WebAppArea[0] + 832, $WebAppArea[1] + 189, 139)
		If IsArray($ImgBuynow) Then
			ClickOnBuyNow($ImgBuynow)
			ExitLoop
		EndIf
		_SLEEP(250)
		$exitloop += 1
	WEnd
	ClickOnBack()
EndFunc   ;==>TryToBuyNow

Func ClickOnCard()
	Local $iCheckSum = PixelChecksum($WebAppArea[0] + 73, $WebAppArea[1] + 80, $WebAppArea[0] + 83, $WebAppArea[1] + 90)
	Local $exitloop = 0

	WINAPI_MOUSECLICK($WebAppArea[0] + 47, $WebAppArea[1] + 339, 1);Click on card

	While $iCheckSum = PixelChecksum($WebAppArea[0] + 73, $WebAppArea[1] + 80, $WebAppArea[0] + 83, $WebAppArea[1] + 90)
		If $exitloop >= 20 Then ExitLoop ; anti stuck
		Sleep(100)
		$exitloop += 1
	WEnd
EndFunc   ;==>ClickOnCard

Func ClickOnBuyNow($BuyNowXY)
	Local $ImgOk = False
	Local $toExpired = 0
	Do
		If $toExpired >= 20 Then ExitLoop ; Auction probably expired
		WINAPI_MOUSECLICK($BuyNowXY[0], $BuyNowXY[1], 1) ;Click on "Buy Now"
		_SLEEP(250)
		$ImgOk = PeakyBuyerImgSearch("Ok.png", $WebAppArea[0] + 426, $WebAppArea[1] + 276, $WebAppArea[0] + 462, $WebAppArea[1] + 294, 130)
		$toExpired += 1
	Until IsArray($ImgOk)

	If IsArray($ImgOk) Then
		DoLogs("We got this card!")
		WINAPI_MOUSECLICK($ImgOk[0], $ImgOk[1], 1) ;Click on "Ok"
		PrepareForNextSearch()
		Return True
	Else
		DoLogs("Auction probably expired.")
		Return False
	EndIf
EndFunc   ;==>ClickOnBuyNow

Func PrepareForNextSearch()
	Local $ImgQuickList = False
	Local $ImgNotEnoughCoins = False
	Local $exitloop = 0

	Do
		If $exitloop >= 20 Then ExitLoop ; anti stuck
		Sleep(100)
		$ImgQuickList = PeakyBuyerImgSearch("OuickList.png", $WebAppArea[0] + 153, $WebAppArea[1] + 132, $WebAppArea[0] + 233, $WebAppArea[1] + 150, 135)
		$exitloop += 1
	Until IsArray($ImgQuickList)

	_SLEEP(500)

	If IsArray($ImgQuickList) Then
		Local $ReadLine = FileReadLine($PlayerListFile, $CurrentPlayer)
		Local $PlayerDataArray = StringSplit($ReadLine, ":")
		Local $bQuickList = $PlayerDataArray[5]
		If $bQuickList == "True" Then
			QuickListCard($ImgQuickList, $PlayerDataArray)
		Else
			SendToTransferList($ImgQuickList)
		EndIf
		Return
	EndIf

	$ImgNotEnoughCoins = PeakyBuyerImgSearch("Ok.png", $WebAppArea[0] + 443, $WebAppArea[1] + 270, $WebAppArea[0] + 526, $WebAppArea[1] + 296, 130)
	If IsArray($ImgNotEnoughCoins) Then
		DoLogs("Not enough coins. :(")
		Do
			WINAPI_MOUSECLICK($ImgNotEnoughCoins[0], $ImgNotEnoughCoins[1], 1) ;Click on "Ok"
			$ImgNotEnoughCoins = PeakyBuyerImgSearch("Ok.png", $WebAppArea[0] + 443, $WebAppArea[1] + 270, $WebAppArea[0] + 526, $WebAppArea[1] + 296, 130)
		Until Not IsArray($ImgNotEnoughCoins)
		_SLEEP(250)
		Return
	EndIf
EndFunc   ;==>PrepareForNextSearch

Func QuickListCard($QuickListXY, $PlayerDataArray)
	Local $StartPrice = $PlayerDataArray[6]
	Local $BuyNowPrice = $PlayerDataArray[7]
	Local $TransferDuration = $PlayerDataArray[8]
	DoLogs("Quick list card.")
	WINAPI_MOUSECLICK($QuickListXY[0], $QuickListXY[1], 2) ; Click on "Quick List"

	;Wait for "List on transfer market window"
	Local $ImgQuickListOk = False
	Do
		Sleep(100)
		$ImgQuickListOk = PeakyBuyerImgSearch("QuickListOk.png", $WebAppArea[0] + 416, $WebAppArea[1] + 367, $WebAppArea[0] + 445, $WebAppArea[1] + 382, 151)
	Until IsArray($ImgQuickListOk)

	ClipPut($StartPrice)
	WINAPI_MOUSECLICK($WebAppArea[0] + 671, $WebAppArea[1] + 155, 2) ; Click on "Start price"
	Send("^a") ; CTRL + A -> select old start price
	Send("{DEL}") ; Delete old start price
	Send("^v") ; CTRL + V -> Put new start price
	_SLEEP(250)

	ClipPut($BuyNowPrice)
	WINAPI_MOUSECLICK($WebAppArea[0] + 671, $WebAppArea[1] + 200, 2) ; Click on "Buy now price"
	Send("^a")
	Send("{DEL}")
	Send("^v")
	_SLEEP(250)

	;Change transfer duration
	WINAPI_MOUSECLICK($WebAppArea[0] + 738, $WebAppArea[1] + 245, 1) ; Click on "Transfer duration"
	_SLEEP(500)
	WINAPI_MOUSECLICK($WebAppArea[0] + 630, $WebAppArea[1] + 246 + (23 * $TransferDuration), 1) ; set new transfer duration

	WINAPI_MOUSECLICK($ImgQuickListOk[0], $ImgQuickListOk[1], 2) ;click on "Ok"
EndFunc   ;==>QuickListCard

Func SendToTransferList($QuickListXY)
	DoLogs("Sending card to transfer list.")
	WINAPI_MOUSECLICK($QuickListXY[0], $QuickListXY[1] + 39, 2) ; Click on "Send to transfer list"
EndFunc   ;==>SendToTransferList

Func ClickOnBack()
	DoLogs("Back.")
	Local $ImgBack = False
	Local $imgButtonSearch = False
	Do
		Sleep(100)
		$ImgBack = PeakyBuyerImgSearch("Back.png", $WebAppArea[0] + 208, $WebAppArea[1] + 250, $WebAppArea[0] + 254, $WebAppArea[1] + 264, 130)
	Until IsArray($ImgBack)
	WINAPI_MOUSECLICK($ImgBack[0], $ImgBack[1], 1) ;Click on "Back"
	Do
		Sleep(100)
		$imgButtonSearch = PeakyBuyerImgSearch("SearchButton.png", $WebAppArea[0], $WebAppArea[1], $WebAppArea[2], $WebAppArea[3], 130)
	Until IsArray($imgButtonSearch)
	_SLEEP(500)
EndFunc   ;==>ClickOnBack

Func AutoRelist()
	Local $imgReListAll = False
	Local $imgButtonSearch = False
	DoLogs("Auto Re-list.")
	WINAPI_MOUSECLICK($WebAppArea[0] + 619, $WebAppArea[1] + 30, 1) ; Click on "Transfer list"

	Do
		Sleep(100)
		$imgReListAll = PeakyBuyerImgSearch("relist.png", $WebAppArea[0] + 852, $WebAppArea[1] + 247, $WebAppArea[0] + 911, $WebAppArea[1] + 268, 130)
	Until IsArray($imgReListAll)
	_SLEEP(500)
	WINAPI_MOUSECLICK($imgReListAll[0], $imgReListAll[1], 3) ; Click on "Re-List all"
	_SLEEP(500)
	Do
		Sleep(100)
		WINAPI_MOUSECLICK($WebAppArea[0] + 345, $WebAppArea[1] + 30, 1) ; Click on "Transfer market"
		$imgButtonSearch = PeakyBuyerImgSearch("SearchButton.png", $WebAppArea[0], $WebAppArea[1], $WebAppArea[2], $WebAppArea[3], 130)
	Until IsArray($imgButtonSearch)
	_SLEEP(500)
EndFunc   ;==>AutoRelist

Func Init()
	OnAutoItExitRegister(OnExit)
	If @Compiled Then DoLogs("PeakyBuyer v." & GetVerion() & " The worst autobuyer ever.")
	CreateSettingFiles()
	SetHotkeys()
	DoLogs("PeakyBuyer is ready.")
EndFunc   ;==>Init

Func CreateSettingFiles()
	If Not FileExists($SettingsFile) Then _FileCreate($SettingsFile)
	If Not FileExists($PlayerListFile) Then _FileCreate($PlayerListFile)
EndFunc   ;==>CreateSettingFiles

Func ReadSettingsIni()
	$MouseMovementSpeed = IniRead($SettingsFile, "Other", "MouseMoveSpeed", "10")
	$PeakyBuyerSpeed = IniRead($SettingsFile, "Other", "PeakyBuyerSpeed", "*1")
	$AutoRelistTime = IniRead($SettingsFile, "Other", "AutoRelist", "0")
EndFunc   ;==>ReadSettingsIni

Func SetHotkeys()
	Local $StartKey = IniRead($SettingsFile, "Hotkeys", "StartHotkey", "HOME")
	Local $ExitKey = IniRead($SettingsFile, "Hotkeys", "ExitHotkey", "END")
	Local $PauseKey = IniRead($SettingsFile, "Hotkeys", "PauseHotkey", "PAUSE")
	HotKeySet("{" & $StartKey & "}", StartBuying)
	HotKeySet("{" & $ExitKey & "}", _EXIT)
	HotKeySet("{" & $PauseKey & "}", PAUSE)
EndFunc   ;==>SetHotkeys


Func FindWebAppWindow()
	DoLogs("Searching for Web App window.")
	Local $WindowList = WinList()
	For $i = 1 To $WindowList[0][0]
		If StringInStr($WindowList[$i][0], "Web App") >= 1 Then
			WinActivate($WindowList[$i][0])
			$WebAppArea = WinGetPos($WindowList[$i][0])
			DoLogs("Window found.")
			Return
		EndIf
	Next
	DoLogs("Cannot find Web App window...")
	$WebAppArea[2] = @DesktopWidth
	$WebAppArea[3] = @DesktopHeight
EndFunc   ;==>FindWebAppWindow

Func SetupWebAppArea()
	Local $tempArrea = PeakyBuyerImgSearch("SearchButton.png", $WebAppArea[0], $WebAppArea[1], $WebAppArea[2], $WebAppArea[3], 130)
	If IsArray($tempArrea) Then
		$WebAppArea[0] = $tempArrea[0] - 230
		$WebAppArea[1] = $tempArrea[1] - 448
		$WebAppArea[2] = $WebAppArea[0] + 970
		$WebAppArea[3] = $WebAppArea[1] + 475
		If Not @Compiled And $bTest Then
			_ArrayDisplay($WebAppArea)
			WinMove("[ACTIVE]", "", 0, 0)
			Exit
		EndIf
	Else
		DoLogs("Cannot find SearchButton.", True)
		PAUSE()
	EndIf
EndFunc   ;==>SetupWebAppArea

Func PeakyBuyerImgSearch($ImgToFind, $startx, $starty, $endx, $endy, $maxTolerance)
	Local $SearchResult = 0
	Local $FullImgPath = $ImagesDir & $ImgToFind
	Local $x = 0, $y = 0
	Local $return[2] = [$x, $y]

	If Not FileExists($FullImgPath) Then
		DoLogs("Image " & $ImgToFind & " doesn't exist", True)
		Exit
	EndIf

	$SearchResult = _ImageSearchArea($FullImgPath, 0, $startx, $starty, $endx, $endy, $x, $y, $maxTolerance)
	If $SearchResult = 1 Then
		$return[0] = $x
		$return[1] = $y
		Return $return
	Else
		Return False
	EndIf
EndFunc   ;==>PeakyBuyerImgSearch

Func SetDefaultPlayerList()

	Local $fname = IniRead($SettingsFile, "PlayerList", "LastUsedList", "PlayerList.txt")
	$PlayerListFile = $PlayerListPath & $fname

	If Not FileExists($PlayerListFile) Or $fname = "" Then
		$PlayerListFile = $PlayerListPath & "PlayerList.txt"
	EndIf

EndFunc   ;==>SetDefaultPlayerList

Func InitCoords()
	DoLogs("Settingup workspace.")
	ReadSettingsIni()
	FindWebAppWindow()
	SetupWebAppArea()
EndFunc   ;==>InitCoords

Func PAUSE()
	$Paused = Not $Paused
	DoLogs("PAUSE: " & $Paused)
	If Not $Paused Then InitCoords()
	While $Paused
		Sleep(100)
	WEnd
EndFunc   ;==>PAUSE

Func WINAPI_MOUSECLICK($x, $y, $clicks = 1)
	Local $WIN_API_MouseEvent_LEFTDOWN = 0x0002
	Local $WIN_API_MouseEvent_LEFTUP = 0x0004

	MouseMove($x, $y, $MouseMovementSpeed)
	If ($clicks > 1) Then
		$i = 0
		While $clicks > $i
			Sleep(50)
			_WinAPI_Mouse_Event($WIN_API_MouseEvent_LEFTDOWN)
			Sleep(50)
			_WinAPI_Mouse_Event($WIN_API_MouseEvent_LEFTUP)
			$i += 1
		WEnd
	Else
		_WinAPI_Mouse_Event($WIN_API_MouseEvent_LEFTDOWN)
		Sleep(50)
		_WinAPI_Mouse_Event($WIN_API_MouseEvent_LEFTUP)
	EndIf
EndFunc   ;==>WINAPI_MOUSECLICK

Func _SLEEP($time)
	Sleep(Execute($time & $PeakyBuyerSpeed))
EndFunc   ;==>_SLEEP

Func _EXIT()
	Exit
EndFunc   ;==>_EXIT

Func OnExit()
	IniWrite($SettingsFile, "PlayerList", "LastUsedList", _StringBetween($PlayerListFile, "PlayerList\", "")[0]) ;save last used player list file name.
	DoLogs("=============EXIT==============")
EndFunc   ;==>OnExit
