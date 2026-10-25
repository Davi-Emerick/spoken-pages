// Spoken Pages
// Opening a book starts that reading. A, D, and the arrows only change the page on screen.
// Keyboard on a book: Space plays or pauses, Left Ctrl stops, X starts again.
// Controller on a book: Y plays or pauses, LB stops, X starts again. B still closes the book.

@addField(CR4Game) var spokenPagesActive : bool;
@addField(CR4Game) var spokenPagesPaused : bool;
@addField(CR4Game) var spokenPagesMenuHeld : bool;
@addField(CR4Game) var spokenPagesFreshRead : string;
@addField(CR4Game) var spokenPagesFreshTime : float;
@addField(CR4Game) var spokenPagesTimerOn : bool;
@addField(CR4Game) var spokenPagesElapsed : float;
@addField(CR4Game) var spokenPagesHeard : string;
@addField(CR4Game) var spokenPagesBook : string;
@addField(CR4Game) var spokenPagesViewed : string;
@addField(CR4Game) var spokenPagesViewedLoc : string;
@addField(CR4Game) var spokenPagesEvent : string;
@addField(CR4Game) var spokenPagesDuration : float;

@addMethod(CR4Game) function SpokenPagesSetActive(value : bool) { this.spokenPagesActive = value; }
@addMethod(CR4Game) function SpokenPagesIsActive() : bool { return this.spokenPagesActive; }
@addMethod(CR4Game) function SpokenPagesSetPaused(value : bool) { this.spokenPagesPaused = value; }
@addMethod(CR4Game) function SpokenPagesIsPaused() : bool { return this.spokenPagesPaused; }
@addMethod(CR4Game) function SpokenPagesSetMenuHeld(value : bool) { this.spokenPagesMenuHeld = value; }
@addMethod(CR4Game) function SpokenPagesMenuHeld() : bool { return this.spokenPagesMenuHeld; }
@addMethod(CR4Game) function SpokenPagesSetFreshRead(value : string) { this.spokenPagesFreshRead = value; }
@addMethod(CR4Game) function SpokenPagesGetFreshRead() : string { return this.spokenPagesFreshRead; }
@addMethod(CR4Game) function SpokenPagesSetFreshTime(value : float) { this.spokenPagesFreshTime = value; }
@addMethod(CR4Game) function SpokenPagesGetFreshTime() : float { return this.spokenPagesFreshTime; }
@addMethod(CR4Game) function SpokenPagesSetTimerOn(value : bool) { this.spokenPagesTimerOn = value; }
@addMethod(CR4Game) function SpokenPagesTimerOn() : bool { return this.spokenPagesTimerOn; }
@addMethod(CR4Game) function SpokenPagesSetElapsed(value : float) { this.spokenPagesElapsed = value; }
@addMethod(CR4Game) function SpokenPagesGetElapsed() : float { return this.spokenPagesElapsed; }
@addMethod(CR4Game) function SpokenPagesAddElapsed(value : float) { this.spokenPagesElapsed += value; }
@addMethod(CR4Game) function SpokenPagesSetBook(value : string) { this.spokenPagesBook = value; }
@addMethod(CR4Game) function SpokenPagesGetBook() : string { return this.spokenPagesBook; }
@addMethod(CR4Game) function SpokenPagesSetViewed(value : string) { this.spokenPagesViewed = value; }
@addMethod(CR4Game) function SpokenPagesGetViewed() : string { return this.spokenPagesViewed; }
@addMethod(CR4Game) function SpokenPagesSetViewedLoc(value : string) { this.spokenPagesViewedLoc = value; }
@addMethod(CR4Game) function SpokenPagesGetViewedLoc() : string { return this.spokenPagesViewedLoc; }
@addMethod(CR4Game) function SpokenPagesSetEvent(value : string) { this.spokenPagesEvent = value; }
@addMethod(CR4Game) function SpokenPagesGetEvent() : string { return this.spokenPagesEvent; }
@addMethod(CR4Game) function SpokenPagesSetDuration(value : float) { this.spokenPagesDuration = value; }
@addMethod(CR4Game) function SpokenPagesGetDuration() : float { return this.spokenPagesDuration; }

@addMethod(CR4Game) function SpokenPagesMarkHeard(bookName : name)
{
	if (bookName == '')
	{
		return;
	}

	this.SpokenPagesMarkHeardString(NameToString(bookName));
}

@addMethod(CR4Game) function SpokenPagesMarkHeardString(bookName : string)
{
	var key : string;

	if (bookName == "")
	{
		return;
	}

	key = ";" + SpokenPagesVoiceTag() + bookName + ";";
	if (StrFindFirst(this.spokenPagesHeard, key) < 0)
	{
		this.spokenPagesHeard = this.spokenPagesHeard + key;
	}
}

@addMethod(CR4Game) function SpokenPagesHasHeard(bookName : name) : bool
{
	if (bookName == '')
	{
		return false;
	}

	return StrFindFirst(this.spokenPagesHeard, ";" + SpokenPagesVoiceTag() + NameToString(bookName) + ";") >= 0;
}

function SpokenPagesLength() : float
{
	var duration : float;

	duration = theGame.SpokenPagesGetDuration();
	if (duration < 1.0)
	{
		return 99999.0;
	}

	return duration;
}

function SpokenPagesOption(varName : name) : string
{
	return theGame.GetInGameConfigWrapper().GetVarValue('SpokenPages', varName);
}

function SpokenPagesOncePerBook() : bool
{
	return SpokenPagesOption('OncePerBook') != "false";
}

function SpokenPagesAutoStart() : bool
{
	return SpokenPagesOption('AutoStart') != "false";
}

function SpokenPagesStopOnClose() : bool
{
	return SpokenPagesOption('StopOnClose') != "false";
}

function SpokenPagesVoiceTag() : string
{
	if (SpokenPagesOption('Voice') == "1")
	{
		return "g";
	}

	return "s";
}

function SpokenPagesUseVoice(baseEvent : string) : string
{
	if (SpokenPagesOption('Voice') == "1")
	{
		return "ge_" + StrMid(baseEvent, 3);
	}

	return baseEvent;
}

function SpokenPagesVolume() : float
{
	var value : string;

	value = SpokenPagesOption('Volume');
	if (value == "")
	{
		return 50.0;
	}

	return StringToFloat(value, 50.0);
}

function SpokenPagesBookName(menu : CR4MenuPopup) : name
{
	var book : BookPopupFeedback;

	if (!menu)
	{
		return '';
	}

	book = (BookPopupFeedback)menu.GetMenuInitData();
	if (!book || !book.curInventory)
	{
		return '';
	}

	return book.curInventory.GetItemName(book.bookItemId);
}

function SpokenPagesAlreadyRead(menu : CR4MenuPopup) : bool
{
	var book : BookPopupFeedback;

	if (!menu)
	{
		return false;
	}

	book = (BookPopupFeedback)menu.GetMenuInitData();
	if (!book || !book.curInventory)
	{
		return false;
	}

	if (!book.curInventory.IsIdValid(book.bookItemId))
	{
		return false;
	}

	return book.curInventory.IsBookRead(book.bookItemId);
}

function SpokenPagesFreshOpen(bookName : name) : bool
{
	var fresh : string;

	fresh = theGame.SpokenPagesGetFreshRead();
	if (fresh == "" || bookName == '')
	{
		return false;
	}

	if (fresh != NameToString(bookName))
	{
		return false;
	}

	return theGame.GetEngineTimeAsSeconds() - theGame.SpokenPagesGetFreshTime() < 3.0;
}

function SpokenPagesIsBookPopup(menu : CR4MenuPopup) : bool
{
	var book : BookPopupFeedback;

	if (!menu)
	{
		return false;
	}

	book = (BookPopupFeedback)menu.GetMenuInitData();
	return book;
}

function SpokenPagesInPauseMenu() : bool
{
	var menu : CR4Menu;

	menu = theGame.GetGuiManager().GetRootMenu();
	if (!menu)
	{
		return false;
	}

	return menu.GetMenuName() == 'IngameMenu';
}

function SpokenPagesApplyVolume()
{
	theSound.SoundParameter("sp_volume", SpokenPagesVolume());
	theSound.SoundGlobalParameter("sp_volume", SpokenPagesVolume());
}

function SpokenPagesEnsureBank()
{
	var eventName : string;

	eventName = theGame.SpokenPagesGetEvent();
	if (eventName == "")
	{
		return;
	}

	theSound.SoundLoadBank(eventName + ".bnk", false);
}

function SpokenPagesPost(suffix : string)
{
	var eventName : string;

	eventName = theGame.SpokenPagesGetEvent();
	if (eventName == "")
	{
		return;
	}

	SpokenPagesEnsureBank();
	theSound.SoundEvent(eventName + suffix);
}

function SpokenPagesEnsureTimer()
{
	if (theGame.SpokenPagesTimerOn())
	{
		return;
	}

	thePlayer.AddTimer('SpokenPagesTick', 0.25, true);
	theGame.SpokenPagesSetTimerOn(true);
}

function SpokenPagesLocName(menu : CR4MenuPopup) : string
{
	var book : BookPopupFeedback;

	if (!menu)
	{
		return "";
	}

	book = (BookPopupFeedback)menu.GetMenuInitData();
	if (!book || !book.curInventory)
	{
		return "";
	}

	return book.curInventory.GetItemLocalizedNameByUniqueID(book.bookItemId);
}

function SpokenPagesPlayNamed(bookName : string) : bool
{
	var info : string;
	var eventName : string;
	var secondsText : string;
	var bar : int;

	if (bookName == "")
	{
		return false;
	}

	info = SpokenPagesInfo(StrLower(bookName));
	if (info == "")
	{
		return false;
	}

	bar = StrFindFirst(info, "|");
	if (bar <= 0)
	{
		return false;
	}

	eventName = SpokenPagesUseVoice(StrLeft(info, bar));
	secondsText = StrMid(info, bar + 1);
	if (StrFindFirst(secondsText, "|") > 0 && SpokenPagesOption('Voice') == "1")
	{
		secondsText = StrMid(secondsText, StrFindFirst(secondsText, "|") + 1);
	}
	else if (StrFindFirst(secondsText, "|") > 0)
	{
		secondsText = StrLeft(secondsText, StrFindFirst(secondsText, "|"));
	}
	if (theGame.SpokenPagesIsActive())
	{
		SpokenPagesPost("_s");
	}
	theGame.SpokenPagesSetBook(bookName);
	theGame.SpokenPagesSetEvent(eventName);
	theGame.SpokenPagesSetDuration(StringToFloat(secondsText, 1.0));
	SpokenPagesEnsureBank();
	theSound.SoundEvent(eventName);
	SpokenPagesApplyVolume();
	theGame.SpokenPagesSetElapsed(0.0);
	theGame.SpokenPagesSetPaused(false);
	theGame.SpokenPagesSetMenuHeld(false);
	theGame.SpokenPagesSetActive(true);
	SpokenPagesEnsureTimer();
	return true;
}

function SpokenPagesPlayFromStart()
{
	SpokenPagesPlayNamed(theGame.SpokenPagesGetBook());
}

function SpokenPagesPause()
{
	if (!theGame.SpokenPagesIsActive() || theGame.SpokenPagesIsPaused())
	{
		return;
	}

	SpokenPagesPost("_p");
	theGame.SpokenPagesSetPaused(true);
}

function SpokenPagesResume()
{
	if (!theGame.SpokenPagesIsActive() || !theGame.SpokenPagesIsPaused())
	{
		return;
	}

	SpokenPagesEnsureBank();
	SpokenPagesPost("_r");
	theGame.SpokenPagesSetPaused(false);
	theGame.SpokenPagesSetMenuHeld(false);
}

function SpokenPagesRememberShown(menu : CR4MenuPopup, itemId : SItemUniqueId)
{
	var book : BookPopupFeedback;
	var inv : CInventoryComponent;
	var itemName : name;

	book = (BookPopupFeedback)menu.GetMenuInitData();
	if (book && book.curInventory && book.curInventory.IsIdValid(itemId))
	{
		inv = book.curInventory;
	}
	else if (thePlayer.inv.IsIdValid(itemId))
	{
		inv = thePlayer.inv;
	}
	else
	{
		return;
	}

	itemName = inv.GetItemName(itemId);
	if (itemName != '')
	{
		theGame.SpokenPagesSetViewed(NameToString(itemName));
	}
	else
	{
		theGame.SpokenPagesSetViewed("");
	}
	theGame.SpokenPagesSetViewedLoc(inv.GetItemLocalizedNameByUniqueID(itemId));
}

function SpokenPagesShownIsCurrent() : bool
{
	var playing : string;

	if (!theGame.SpokenPagesIsActive())
	{
		return false;
	}

	playing = theGame.SpokenPagesGetBook();
	if (playing == "")
	{
		return false;
	}

	if (theGame.SpokenPagesGetViewed() == "" && theGame.SpokenPagesGetViewedLoc() == "")
	{
		return true;
	}

	if (theGame.SpokenPagesGetViewed() != "" && theGame.SpokenPagesGetViewed() == playing)
	{
		return true;
	}

	if (theGame.SpokenPagesGetViewedLoc() != "" && theGame.SpokenPagesGetViewedLoc() == playing)
	{
		return true;
	}

	return false;
}

function SpokenPagesPlayShownBook()
{
	var played : bool;

	if (SpokenPagesShownIsCurrent())
	{
		if (theGame.SpokenPagesIsPaused())
		{
			SpokenPagesResume();
		}
		else
		{
			SpokenPagesPause();
		}
		return;
	}

	played = false;
	if (theGame.SpokenPagesGetViewed() != "")
	{
		played = SpokenPagesPlayNamed(theGame.SpokenPagesGetViewed());
	}
	if (!played && theGame.SpokenPagesGetViewedLoc() != "")
	{
		played = SpokenPagesPlayNamed(theGame.SpokenPagesGetViewedLoc());
	}
	if (!played)
	{
		return;
	}

	if (theGame.SpokenPagesGetViewed() != "")
	{
		theGame.SpokenPagesMarkHeardString(theGame.SpokenPagesGetViewed());
	}
	else
	{
		theGame.SpokenPagesMarkHeardString(theGame.SpokenPagesGetBook());
	}
}

function SpokenPagesToggle()
{
	if (!theGame.SpokenPagesIsActive())
	{
		SpokenPagesPlayFromStart();
	}
	else if (theGame.SpokenPagesIsPaused())
	{
		SpokenPagesResume();
	}
	else
	{
		SpokenPagesPause();
	}
}

function SpokenPagesStop()
{
	SpokenPagesPost("_s");
	theGame.SpokenPagesSetActive(false);
	theGame.SpokenPagesSetPaused(false);
	theGame.SpokenPagesSetMenuHeld(false);
	theGame.SpokenPagesSetElapsed(0.0);
}

function SpokenPagesRewind()
{
	SpokenPagesPlayFromStart();
}

function SpokenPagesKeepAlive()
{
	if (!theGame.SpokenPagesIsActive() || theGame.SpokenPagesIsPaused() || theGame.SpokenPagesMenuHeld())
	{
		return;
	}

	if (SpokenPagesInPauseMenu())
	{
		return;
	}

	SpokenPagesPost("_r");
}

function SpokenPagesHoldForPauseMenu()
{
	if (!theGame.SpokenPagesIsActive() || theGame.SpokenPagesIsPaused())
	{
		return;
	}

	SpokenPagesPost("_p");
	theGame.SpokenPagesSetMenuHeld(true);
	theGame.SpokenPagesSetPaused(true);
}

function SpokenPagesReleasePauseMenu()
{
	if (!theGame.SpokenPagesMenuHeld())
	{
		return;
	}

	theGame.SpokenPagesSetMenuHeld(false);
	theGame.SpokenPagesSetPaused(false);
	SpokenPagesEnsureBank();
	SpokenPagesPost("_r");
}

@addMethod(CR4Player) timer function SpokenPagesTick(delta : float, id : int)
{
	if (!theGame.SpokenPagesIsActive())
	{
		return;
	}

	SpokenPagesApplyVolume();

	if (theGame.SpokenPagesGetBook() != "")
	{
		if (SpokenPagesOption('Voice') == "1" && StrFindFirst(theGame.SpokenPagesGetEvent(), "ge_") != 0)
		{
			SpokenPagesPlayNamed(theGame.SpokenPagesGetBook());
			return;
		}
		if (SpokenPagesOption('Voice') != "1" && StrFindFirst(theGame.SpokenPagesGetEvent(), "sp_") != 0)
		{
			SpokenPagesPlayNamed(theGame.SpokenPagesGetBook());
			return;
		}
	}

	if (!theGame.SpokenPagesIsPaused())
	{
		theGame.SpokenPagesAddElapsed(delta);
		if (theGame.SpokenPagesGetElapsed() >= SpokenPagesLength())
		{
			SpokenPagesStop();
			return;
		}
	}
}

function SpokenPagesAddButton(storage : CScriptedFlashValueStorage, list : CScriptedFlashArray, padCode : string, keyCode : int, label : string)
{
	var holder : CScriptedFlashObject;
	var button : CScriptedFlashObject;

	holder = storage.CreateTempFlashObject();
	button = holder.CreateFlashObject("red.game.witcher3.data.KeyBindingData");
	button.SetMemberFlashString("gamepad_navEquivalent", padCode);
	button.SetMemberFlashInt("keyboard_keyCode", keyCode);
	button.SetMemberFlashString("label", label);
	list.PushBackFlashObject(button);
}

@wrapMethod(W3PopupData)
function GetGFxButtons(parentFlashValueStorage : CScriptedFlashValueStorage) : CScriptedFlashArray
{
	var buttons : CScriptedFlashArray;

	buttons = wrappedMethod(parentFlashValueStorage);

	if ((BookPopupFeedback)this)
	{
		SpokenPagesAddButton(parentFlashValueStorage, buttons, "gamepad_Y", IK_Space, "Play / Pause");
		SpokenPagesAddButton(parentFlashValueStorage, buttons, "gamepad_L1", IK_LControl, "Stop");
		SpokenPagesAddButton(parentFlashValueStorage, buttons, "gamepad_X", IK_X, "Rewind");
	}

	return buttons;
}

@wrapMethod(W3PopupData)
function OnClosing() : void
{
	if ((BookPopupFeedback)this && SpokenPagesStopOnClose())
	{
		SpokenPagesStop();
	}

	wrappedMethod();
}

@wrapMethod(CR4MenuPopup)
function OnInputHandled(NavCode : string, KeyCode : int, ActionId : int)
{
	var bookName : name;

	if (SpokenPagesIsBookPopup(this))
	{
		if (NavCode == "gamepad_Y" || KeyCode == IK_Space)
		{
			SpokenPagesPlayShownBook();
			return true;
		}

		if (NavCode == "gamepad_L1" || KeyCode == IK_LControl)
		{
			SpokenPagesStop();
			return true;
		}

		if (NavCode == "gamepad_X" || KeyCode == IK_X)
		{
			if (!SpokenPagesShownIsCurrent())
			{
				SpokenPagesPlayShownBook();
			}
			else
			{
				SpokenPagesRewind();
				if (theGame.SpokenPagesGetViewed() != "")
				{
					theGame.SpokenPagesMarkHeardString(theGame.SpokenPagesGetViewed());
				}
				else
				{
					theGame.SpokenPagesMarkHeard(SpokenPagesBookName(this));
				}
			}
			return true;
		}
	}

	return wrappedMethod(NavCode, KeyCode, ActionId);
}

@wrapMethod(CR4MenuPopup)
function OnConfigUI()
{
	var bookName : name;
	var isBook : bool;
	var alreadyRead : bool;

	isBook = SpokenPagesIsBookPopup(this);
	alreadyRead = false;
	bookName = '';
	if (isBook)
	{
		bookName = SpokenPagesBookName(this);
		alreadyRead = SpokenPagesAlreadyRead(this);
		if (alreadyRead && SpokenPagesFreshOpen(bookName))
		{
			alreadyRead = false;
		}
	}

	wrappedMethod();

	if (!SpokenPagesIsBookPopup(this))
	{
		return true;
	}

	if (bookName == '')
	{
		bookName = SpokenPagesBookName(this);
		if (SpokenPagesFreshOpen(bookName))
		{
			alreadyRead = false;
		}
		else
		{
			alreadyRead = SpokenPagesAlreadyRead(this);
		}
	}

	theGame.SpokenPagesSetFreshRead("");
	if (bookName != '')
	{
		theGame.SpokenPagesSetViewed(NameToString(bookName));
	}
	if (SpokenPagesLocName(this) != "")
	{
		theGame.SpokenPagesSetViewedLoc(SpokenPagesLocName(this));
	}

	if (!SpokenPagesAutoStart())
	{
		return true;
	}

	if (SpokenPagesOncePerBook() && (alreadyRead || theGame.SpokenPagesHasHeard(bookName)))
	{
		return true;
	}

	if (SpokenPagesPlayNamed(NameToString(bookName)))
	{
		theGame.SpokenPagesMarkHeard(bookName);
	}
	else if (SpokenPagesPlayNamed(SpokenPagesLocName(this)))
	{
		theGame.SpokenPagesMarkHeard(bookName);
	}
	return true;
}

@wrapMethod(CR4MenuPopup)
function OnBookRead(bookItemId : SItemUniqueId) : void
{
	wrappedMethod(bookItemId);

	if (SpokenPagesIsBookPopup(this))
	{
		SpokenPagesRememberShown(this, bookItemId);
	}
}

@wrapMethod(CR4MenuPopup)
function OnClosingMenu()
{
	if (SpokenPagesIsBookPopup(this))
	{
		theGame.SpokenPagesSetViewed("");
		theGame.SpokenPagesSetViewedLoc("");
		theGame.SpokenPagesSetFreshRead("");
	}

	wrappedMethod();
	return true;
}

@wrapMethod(CR4CommonMenu)
function OnConfigUI()
{
	wrappedMethod();
	SpokenPagesKeepAlive();
	return true;
}

@wrapMethod(CR4MapMenu)
function OnConfigUI()
{
	wrappedMethod();
	SpokenPagesKeepAlive();
	return true;
}

@wrapMethod(CR4IngameMenu)
function OnConfigUI()
{
	wrappedMethod();
	SpokenPagesHoldForPauseMenu();
	return true;
}

@wrapMethod(CR4IngameMenu)
function OnClosingMenu()
{
	SpokenPagesReleasePauseMenu();
	wrappedMethod();
	return true;
}

@wrapMethod(CScriptSoundSystem)
function SoundGameStateChange(gameState : ESoundGameState)
{
	wrappedMethod(gameState);

	if (!theGame.SpokenPagesIsActive())
	{
		return;
	}

	if (gameState == ESGS_Paused)
	{
		if (SpokenPagesInPauseMenu())
		{
			SpokenPagesHoldForPauseMenu();
		}
		else
		{
			SpokenPagesKeepAlive();
		}
	}
	else if (theGame.SpokenPagesMenuHeld() && !SpokenPagesInPauseMenu())
	{
		SpokenPagesReleasePauseMenu();
	}
}

@wrapMethod(CInventoryComponent)
function ReadBook(item : SItemUniqueId, optional noNotification : bool)
{
	var wasRead : bool;
	var bookName : name;

	wasRead = false;
	bookName = '';
	if (this.IsIdValid(item))
	{
		wasRead = this.IsBookRead(item);
		bookName = this.GetItemName(item);
	}

	wrappedMethod(item, noNotification);

	if (!wasRead && bookName != '')
	{
		theGame.SpokenPagesSetFreshRead(NameToString(bookName));
		theGame.SpokenPagesSetFreshTime(theGame.GetEngineTimeAsSeconds());
	}
}

@addMethod(CR4Player) event OnSPPlayPause(action : SInputAction)
{
	if (IsPressed(action))
	{
		if (theGame.SpokenPagesGetViewed() != "" && !SpokenPagesShownIsCurrent())
		{
			SpokenPagesPlayShownBook();
		}
		else
		{
			SpokenPagesToggle();
		}
	}
}

@addMethod(CR4Player) event OnSPStop(action : SInputAction)
{
	if (IsPressed(action))
	{
		SpokenPagesStop();
	}
}

@addMethod(CR4Player) event OnSPRewind(action : SInputAction)
{
	if (IsPressed(action))
	{
		if (theGame.SpokenPagesGetViewed() != "" && !SpokenPagesShownIsCurrent())
		{
			SpokenPagesPlayShownBook();
		}
		else
		{
			SpokenPagesRewind();
		}
	}
}

@wrapMethod(CR4Player) function OnSpawned(spawnData : SEntitySpawnData)
{
	theInput.RegisterListener(this, 'OnSPPlayPause', 'SPPlayPause');
	theInput.RegisterListener(this, 'OnSPStop', 'SPStop');
	theInput.RegisterListener(this, 'OnSPRewind', 'SPRewind');
	return wrappedMethod(spawnData);
}

function SP_Localize(key : string) : string
{
	if (key == "preset_Mods_SpokenPages")
	{
		return "Preset";
	}
	if (key == "preset_value_spPresetDefault")
	{
		return "Default";
	}
	if (key == "panel_SpokenPages" || key == "SpokenPages")
	{
		return "Spoken Pages";
	}

	return "";
}

@wrapMethod
function inGameMenu_TryLocalize(key : string) : string
{
	var modLoc : string;

	modLoc = SP_Localize(key);
	if (modLoc != "")
	{
		return modLoc;
	}

	return wrappedMethod(key);
}

@wrapMethod
function IngameMenu_FetchAndGenerateGroupMenuObject(flashStorageUtility : CScriptedFlashValueStorage, displayNamePrefix : string, groupDisplayName : string, rootFlashArray : CScriptedFlashArray, out optionParentArray : CScriptedFlashArray) : CScriptedFlashObject
{
	var obj : CScriptedFlashObject;
	var groupId : string;

	obj = wrappedMethod(flashStorageUtility, displayNamePrefix, groupDisplayName, rootFlashArray, optionParentArray);
	if (obj)
	{
		groupId = obj.GetMemberFlashString("id");
		if (groupId == "SpokenPages")
		{
			obj.SetMemberFlashString("label", "Spoken Pages");
			obj.SetMemberFlashString("listTitle", "Spoken Pages");
		}
	}

	return obj;
}
