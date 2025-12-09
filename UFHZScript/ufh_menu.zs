class OptionMenuItemJGPUFH_BuildInfo : OptionMenuItemStaticText
{
	OptionMenuItemJGPUFH_BuildInfo Init(String label, int cr = -1)
	{
		String build;
		int lump;
		while (lump >= 0)
		{
			lump = Wads.FindLump("flexihudbuild.txt", lump+1);
			if (lump >= 0)
			{
				build = Wads.ReadLump(lump).Left(7);
			}
		}
		if (build)
		{
			label = String.Format("%s - build %s", label, build);
		}
		Super.Init(label, cr);
		return self;
	}
}

class JGPUFH_OptionMenu : OptionMenu
{
	bool firstInit;
	Array<OptionMenuItem> allItems;
	
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		super.Init(parent, desc);
		
		if(!firstInit) 
		{
			allItems.Copy(mDesc.mItems);
			firstInit = true;
		}
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mDesc.mSelectedItem >= mDesc.mItems.Size())
		{
			mkey = MKEY_Back;
		}
		bool res = super.MenuEvent(mkey, fromcontroller);
	
		switch (mkey)
		{
			case MKEY_Back:
			{
				Close();
				let m = GetCurrentMenu();
				MenuSound(m != null ? "menu/backup" : "menu/clear");
				if (!m) menuDelegate.MenuDismissed();
				
				// Restore original items.
				mDesc.mItems.Clear();
				mDesc.mItems.Copy(allItems);
				
				return true;
			}
		}
		return res;
	}
	
	void UpdateMenuItems()
	{
		Array<OptionMenuItem> filter;
		OptionMenuItemJGPUFH_Else filterElseCondition;
		OptionMenuItemJGPUFH_CheckCVar filterCondition;
		for(int i = 0; i < allItems.Size(); i++)
		{
			let item = allItems[i];
			let ifCVar = OptionMenuItemJGPUFH_CheckCVar(item);
			let endIfCVar = OptionMenuItemJGPUFH_EndIf(item);
			let otherwiseCVar = OptionMenuItemJGPUFH_Else(item);
			
			if(ifCVar) filterCondition = ifCVar;
			if(otherwiseCVar) filterElseCondition = otherwiseCVar;
			if(endIfCVar) 
			{	
				filterCondition = NULL;	
				filterElseCondition = NULL;
			}
			
			bool conditionValid = (filterCondition && filterCondition.CheckCondition());
			if(filterElseCondition) conditionValid = !conditionValid;
			
			if( !filterCondition || conditionValid )
				filter.Push(allItems[i]);
		}
		
		mDesc.mItems.Clear();
		mDesc.mItems.Copy(filter);
	}
	
	override void Ticker()
	{
		UpdateMenuItems();
		super.Ticker();
	}
}

class JGPUFH_OptionMenuCondition : OptionMenuItemStaticText abstract
{
	String def_label;
	Const mc_noLabel = "----";

	void Init(String label = mc_noLabel, int cr = -1)
	{
		Super.Init(label, cr);
		def_label = label;
	}
		
	virtual bool CheckCondition()
	{
		return true;
	}

	override bool Selectable()
	{
		return false;
	}

	override void Ticker()
	{
		Super.Ticker();
		if (def_label)
		{
			mLabel = CheckCondition()? def_label : mc_noLabel;
		}
	}
}

class OptionMenuItemJGPUFH_CheckCVar : JGPUFH_OptionMenuCondition
{
	mixin JGPUFHCVarChecker;

	void Init(String label = "---", int cr = -1, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, cr);
		ParseCVarConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
	}
		
	override bool CheckCondition()
	{
		return CheckAllCVars();
	}
}

class OptionMenuItemJGPUFH_Else : JGPUFH_OptionMenuCondition {}
class OptionMenuItemJGPUFH_EndIf : JGPUFH_OptionMenuCondition {}

// Allows specifying up to two CVar conditions
// with different operators and logic values.
// Used for optiona menu items (above) and for
// complex graycheck conditions in other items:
mixin class JGPUFHCVarChecker
{
	// possible cond values:
	// 0 		- equal to 0
	// !:0 		- not 0
	// >:0		- more than 0
	// <:0		- less than 0
	// possible logic values:
	// 0 		- AND
	// 1		- OR

	CVar grayCheck1, grayCheck2;
	String grayCheck1value, grayCheck2value;
	int targetCvarValue1, targetCvarValue2;
	ECVarCondition cvarCondition1, cvarCondition2;
	ECVarLogic cvarLogic;

	enum ECVarCondition
	{
		GC_IS,
		GC_ISNOT,
		GC_MORE,
		GC_LESS,
	}
	enum ECVarLogic
	{
		GC_AND,
		GC_OR,
	}

	void ParseOneCondition(string cmd, out int cond, out int val)
	{
		array<string> values;
		cmd.Split(values, ":");
		if (values.Size() > 2)
		{
			ThrowAbortException("\cGERROR: \cDParseCVarConditions()\c- detected incorrect value declaration");
			return;
		}
		if (values.Size() == 0)
		{
			cond = GC_IS;
			val = 0;
			return;
		}
		if (values.Size() == 1)
		{
			cond = GC_IS;
			val = values[0].ToInt();
			return;
		}
		if (values.Size() == 2)
		{
			string s = values[0];
			if (s == "!")
				cond = GC_ISNOT;
			else if (s == ">")
				cond = GC_MORE;
			else if (s == "<")
				cond = GC_LESS;
			else
			{
				ThrowAbortException(String.Format("\cGERROR: \cDParseCVarConditions()\c- detected incorrect condition declaration \cG%s\c-. Supported values: \cD\"0\"\c-, \cD\"!:0\"\c-, \cD\">:0\"\c-, \cD\"<:0\"\c- where \cD0\c- is the desired value. Only numeric CVars are supported.", s));
				return;
			}
			val = values[1].ToInt();
		}
	}

	void ParseCVarConditions(CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		grayCheck1 = _grayCheck1;
		grayCheck1value = _grayCheck1value;
		cvarLogic = _cvarLogic;
		grayCheck2 = _grayCheck2;
		grayCheck2value = _grayCheck2value;

		if (!graycheck1)
		{
			return;
		}
		ParseOneCondition(grayCheck1value, cvarCondition1, targetCvarValue1);
		ParseOneCondition(grayCheck2value, cvarCondition2, targetCvarValue2);
	}

	bool CheckCVarCondition(int curvalue, int targetvalue, int condition)
	{
		bool res;
		switch (condition)
		{
		default:
			res = (curvalue == targetvalue);
			break;
		case GC_ISNOT:
			res = (curvalue != targetvalue);
			break;
		case GC_MORE:
			res = (curvalue > targetvalue);
			break;
		case GC_LESS:
			res = (curvalue < targetvalue);
			break;
		}
		return res;
	}

	bool CheckAllCVars()
	{
		if (!graycheck1)
		{
			return false;
		}

		int curCVarValue = grayCheck1.GetInt();
		bool result1 = CheckCVarCondition(curCVarValue, targetCvarValue1, cvarCondition1);

		if (!grayCheck2)
		{
			return result1;
		}

		curCVarValue = grayCheck2.GetInt();
		bool result2 = CheckCVarCondition(curCVarValue, targetCvarValue2, cvarCondition2);

		if (cvarLogic == GC_AND)
		{
			return result1 && result2;
		}
		return result1 || result2;
	}
}

// Resets all CCMDs in FlexiHUD to default values
// Alternatively, resets them to a given value
class OptionMenuItemJGPUFHResetALLCCMD : OptionMenuItemSubmenu
{
	int mCVarCategory;
	int mCVarResetValue;
	bool mNeedConfirm;

	OptionMenuItemJGPUFHResetALLCCMD Init(String label, bool centered = false, String type = "", int resetvalue = -1, bool needConfirm = false)
	{
		Super.Init(label, '', 0, centered);
		mCVarResetValue = resetvalue;
		mNeedConfirm = needConfirm;
		name ttype = type.MakeLower();
		switch (ttype)
		{
		default:
			mCVarCategory = JGPUFH_PresetHandler.CVC_None;
			break;
		case 'general':
			mCVarCategory = JGPUFH_PresetHandler.CVC_General;
			break;
		case 'dmgmarkers':
			mCVarCategory = JGPUFH_PresetHandler.CVC_DmgMarkers;
			break;
		case 'mainbars':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Mainbars;
			break;
		case 'mugshot':
			mCVarCategory = JGPUFH_PresetHandler.CVC_MugShot;
			break;
		case 'ammoblock':
			mCVarCategory = JGPUFH_PresetHandler.CVC_AmmoBlock;
			break;
		case 'allammo':
			mCVarCategory = JGPUFH_PresetHandler.CVC_AllAmmo;
			break;
		case 'keys':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Keys;
			break;
		case 'wslots':
			mCVarCategory = JGPUFH_PresetHandler.CVC_WSlots;
			break;
		case 'powerups':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Powerups;
			break;
			break;
		case 'scoreboard':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Scoreboard;
			break;
		case 'minimap':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Minimap;
			break;
		case 'mapdata':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Mapdata;
			break;
		case 'invbar':
			mCVarCategory = JGPUFH_PresetHandler.CVC_InvBar;
			break;
		case 'hitmarkers':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Hitmarkers;
			break;
		case 'reticlebars':
			mCVarCategory = JGPUFH_PresetHandler.CVC_ReticleBars;
			break;
		case 'customitems':
			mCVarCategory = JGPUFH_PresetHandler.CVC_CustomItems;
			break;
		case 'fonts':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Fonts;
			break;
		case 'healthcolors':
			mCVarCategory = JGPUFH_PresetHandler.CVC_HealthColors;
			break;
		case 'armorcolors':
			mCVarCategory = JGPUFH_PresetHandler.CVC_ArmorColors;
			break;
		case 'scaling':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Scaling;
			break;
		case 'visibility':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Visibility;
			break;
		case 'compass':
			mCVarCategory = JGPUFH_PresetHandler.CVC_Compass;
			break;
		}
		return self;
	}

	bool DoResetCCMDs()
	{
		if (mCVarCategory == JGPUFH_PresetHandler.CVC_None)
		{
			JGPUFH_PresetHandler.ResetToDefault();
			return true;
		}

		let handler = JGPUFH_PresetHandler(StaticEventHandler.Find('JGPUFH_PresetHandler'));
		if (!handler) return false;

		foreach(data : handler.cvardata)
		{
			if (!data) continue;
			if (data.cvarCategory & mCVarCategory)
			{
				if (mCVarResetValue < 0)
				{
					data.c_cvar.ResetToDefault();
				}
				else
				{
					data.c_cvar.SetInt(mCVarResetValue);
				}
				
			}
		}
		return true;
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mNeedConfirm && mkey == Menu.MKEY_MBYes)
		{
			DoResetCCMDs();
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}

	override bool Activate()
	{
		if (mNeedConfirm)
		{
			Menu.StartMessage(StringTable.Localize("$SAFEMESSAGE"), 0);
			return true;
		}
		return DoResetCCMDs();
	}
}

// Resets a list of CCMD provided as a string
// CCMDs should be delimited with :
class OptionMenuItemJGPUFHResetCCMD : OptionMenuItemSubmenu
{
	private array <String> ccmds;

	OptionMenuItemJGPUFHResetCCMD Init(String label, string commands, bool centered = false)
	{
		Super.Init(label, '', 0, centered);
		commands.Split(ccmds, ":");
		return self;
	}

	override bool Activate()
	{
		for (int i = 0; i < ccmds.Size(); i++)
		{
			if (!ccmds[i])
				continue;
			CVar cmd = CVar.FindCVar(ccmds[i]);
			if (cmd)
			{
				cmd.ResetToDefault();
			}
		}
		return true;
	}
}

class OptionMenuItemJGPUFHIntNumberField : OptionMenuItemNumberField
{
	override String Represent()
	{
		if (mCVar == null) return "";
		return String.format("%d", mCVar.GetInt());
	}
}

class OptionMenuItemJGPUFHSlider : OptionMenuItemSlider
{
	mixin JGPUFHCVarChecker;

	OptionMenuItemJGPUFHSlider Init(String label, Name command, double min, double max, double step, int showval = 1, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, min, max, step, showval, null);
		ParseCVarConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override bool IsGrayed(void)
	{
		return CheckAllCVars();
	}
}

class OptionMenuItemJGPUFHOption : OptionMenuItemOption
{
	mixin JGPUFHCVarChecker;

	OptionMenuItemJGPUFHOption Init(String label, Name command, Name values, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, values, null, 0);
		ParseCVarConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override bool IsGrayed(void)
	{
		return CheckAllCVars();
	}
}

// This not only allows for two conditions, but also
// allows displaying decimal values, like default Slider,
// which default ScaleSlider can't do for some reason.
class OptionMenuItemJGPUFHScaleSlider : OptionMenuItemScaleSlider
{
	mixin JGPUFHCVarChecker;

	OptionMenuItemJGPUFHScaleSlider Init(String label, Name command, double min, double max, double step, String zero, String negone = "", CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, min, max, step, zero, negone);
		ParseCVarConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		// Infer the number of decimal places to display
		// from the length of the decimal part of the
		// 'step' argument:
		String s_step = String.Format("%f", step);
		array <String> places;
		s_step.Split(places, ".");
		if (places.Size() == 2)
		{
			String str = places[1];
			str.Replace("0", "");
			mShowValue = Clamp(str.Length(), 0, 8);
		}
		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		DrawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor, IsGrayed());

		double sliderVal = GetSliderValue();
		if ((sliderVal <= 0.0) && mClickVal <= 0)
		{
			String text = sliderVal <= -1 ? TextNegOne : TextZero;
			DrawValue(indent, y, OptionMenuSettings.mFontColorValue, text, IsGrayed());
		}
		else
		{
			mDrawX = indent + CursorSpace();
			DrawSlider (mDrawX, y, mMin, mMax, sliderVal, mShowValue, indent, IsGrayed());
		}
		return indent;
	}

	override bool IsGrayed(void)
	{
		return CheckAllCVars();
	}
}

class OptionMenuItemJGPUFHColorPicker : OptionMenuItemColorPicker
{
	mixin JGPUFHCVarChecker;

	OptionMenuItemJGPUFHColorPicker Init(String label, Name command, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command);
		ParseCVarConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		DrawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor,  IsGrayedEx());

		if (mCVar != null)
		{
			int box_x = indent + CursorSpace();
			int box_y = y + CleanYfac_1;
			screen.Clear (box_x, box_y, box_x + 32*CleanXfac_1, box_y + OptionMenuSettings.mLinespacing*CleanYfac_1, mCVar.GetInt() | 0xff000000);
		}
		return indent;
	}

	bool IsGrayedEx(void)
	{
		return CheckAllCVars();
	}

	override bool Selectable()
	{
		return !IsGrayedEx();
	}
}

class OptionMenuItemJGPUFHTextField : OptionMenuItemTextField
{
	mixin JGPUFHCVarChecker;

	OptionMenuItemJGPUFHTextField Init (String label, Name command, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, null);
		ParseCVarConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		if (mEnter)
		{
			String text = Represent();
			int tlen = Menu.OptionWidth(text, false) * CleanXfac_1;
			int newindent = screen.GetWidth() - tlen - CursorSpace();
			if (newindent < indent) indent = newindent;
		}
		bool grayed = IsGrayedEx();
		DrawLabel(indent, y, selected ? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor, grayed);
		drawValue(indent, y, OptionMenuSettings.mFontColorValue, Represent(), grayed, false);
		return indent;
	}

	bool IsGrayedEx()
	{
		return CheckAllCVars();
	}

	override bool Selectable(void)
	{
		return !CheckAllCVars();
	}
}

class OptionMenuItemJGPUFH_ColorizedValueRange : OptionMenuItem
{
	const COLORRANGESTEPS = 8.0;
	enum ESetupModes
	{
		SM_None,
		SM_Thresholds,
		SM_Colors,
	}
	ESetupModes setupMode;
	int lastRangeValue;
	int selectedRange;
	bool colorSelected;
	array<int> healthValues;
	array<color> healthColors;
	array<int> defaultHealthValues;
	array<color> defaultHealthColors;
	CVar thresholds;
	CVar colorList;
	CVar currentStripColor;
	CVar useGradients;
	String prevColorListString;

	void Init(name colorListCVar, name thresholdsCVar, name currentColorCVar, name useGradientsCVar, int maxvalue)
	{
		Super.Init("", "");
		colorList = CVar.FindCVar(colorListCVar);
		thresholds = CVar.FindCVar(thresholdsCVar);
		currentStripColor = CVar.FindCVar(currentColorCVar);
		useGradients = CVar.FindCVar(useGradientsCVar);
		lastRangeValue = maxvalue; 
		colorSelected = false;
		setupMode = SM_None;
		ParseGradients();
		JGPUFH_CVarTools.ParseGradientColors(colorList, defaultHealthValues, defaultHealthColors, true);
	}

	override bool Activate()
	{
		// Disable color/threshold setup mode:
		if (setupMode != SM_None)
		{
			Menu.MenuSound("menu/back");
			UpdateCVarFromArrays();
			setupMode = SM_None;
			return true;
		}
		// Start threshold setup mode:
		if (!colorSelected)
		{
			setupMode = SM_Thresholds;
			Menu.MenuSound("menu/advance");
		}
		// Start color setup mode (activate custom color picker):
		else
		{
			setupMode = SM_Colors;
			// update cvar that holds the current strip's color:
			currentStripColor.SetInt(healthColors[selectedRange]);
			let desc = OptionMenuDescriptor(MenuDescriptor.GetDescriptor('Colorpickermenu'));
			if (desc)
			{
				Menu.MenuSound("menu/advance");
				let picker = new('JGPUFH_HealthColorPickerMenu');
				picker.Init(Menu.GetCurrentMenu(), mLabel, desc, self, selectedRange, currentStripColor);
				picker.ActivateMenu();
				return true;
			}
		}
		return true;
	}

	void UpdateCVarFromArrays()
	{
		JGPUFH_CVarTools.SetGradientCVarFromArrays(colorlist, healthValues, healthColors);
	}

	void ParseGradients()
	{
		if (prevColorListString != colorList.GetString())
		{
			JGPUFH_CVarTools.ParseGradientColors(colorlist, healthValues, healthcolors);
		}

		// We need to make sure that every next health threshold
		// is in order. This is needed in case where the user first
		// sets a specific threshold high, and then decides to
		// increase the number of thresholds - this could cause overlap:

		int lastIndex = GetMaxThresholds() - 1;
		// prevent final value from exceeding maximum:
		healthValues[lastIndex] = min(healthValues[lastINdex], lastRangeValue);
		// go backward and make sure every value is at least 1 lower
		// than the next value:
		for (int i = lastIndex - 1; i >= 0; i--)
		{
			healthValues[i] = clamp(healthValues[i], 0, healthValues[i+1] - 1);
		}
		// now go forward and make sure every value is at least 1 higher
		// than the previous one:
		for (int i = 1; i <= lastIndex; i++)
		{
			healthValues[i] = max(healthValues[i], 0, healthValues[i-1] + 1);
		}

		prevColorListString = colorList.GetString();
	}

	int GetMaxThresholds()
	{
		// technically should always be the same number:
		return min(thresholds.GetInt(), healthValues.Size(), healthcolors.Size());
	}

	override void Ticker()
	{
		ParseGradients();
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		int width = int(ceil(Screen.GetWidth() * 0.8));
		int height = Menu.OptionHeight() * 2;
		int x = indent - (width / 2);
		int steps = GetMaxThresholds();
		// updated the currently selected range if the number of values
		// was reduced:
		selectedRange = min(selectedRange, steps-1);
		// width of one color strip:
		double widthstep = double(width) / lastRangeValue;
		// start with a black rectangle under the whole color gradient:
		Screen.Dim(0x000000, 1.0, x, y - height / 2, width, height * 2);
		int curVal, nextVal, stripwidth;
		int selectedPosX, selectedPosY, selectedWidth, selectedHeight;
		for (int i = 0; i < steps; i++)
		{
			// calculate current strip's width and position based
			// on the current and next health values:
			curVal = steps > 1? healthValues[i] : 0;
			nextVal = i < steps - 1? healthValues[i+1] : lastRangeValue;
			stripwidth = int(ceil(widthstep * (nextval - curVal)));
			int stripPos = int(ceil(curVal * widthstep));
			// dim the alpha of the whole thing slightly while it's not
			// selected:
			double colalpha = selected? 1.0 : 0.7;
			// fill the leftmost part with solid color
			// from 0 to first value if first value is above 0:
			if (i == 0 && curVal > 0)
			{
				Screen.Dim(healthColors[i], colAlpha, x, y, stripPos, height);
			}
			int colPos = x + stripPos;
			// Draw a gradient if the CVar allows it, there are enough
			// thresholds, we're not at the end of the list, and the
			// next color is different from the current one:
			if (useGradients.GetBool() && i < steps -1 && healthColors[i] != healthColors[i+1])
			{
				int colorsteps = nextval - curval;
				int x1, x2, w;
				double a;
				for (int c = 0; c < colorsteps; c++)
				{
					// draw in integer steps to avoid weird pixels
					// in various resolutions:
					x1 = colPos + (stripWidth * c) / colorsteps;
					x2 = colPos + (stripWidth * (c + 1)) / colorsteps;
					w = x2 - x1;
					a = c / double(colorsteps);
					Screen.Dim(healthColors[i],
						colalpha * (1.0 - a),
						x1,
						y,
						w,
						height);
					Screen.Dim(healthColors[i+1],
						colalpha * a,
						x1,
						y,
						w,
						height);
				}
			}
			// Otherwise draw solid color:
			else
			{
				Screen.Dim(healthColors[i], colalpha, colPos, y, stripwidth, height);
			}
			// threshold pip:
			int pipposX = x + stripPos - 2;
			int pipposY = y - height / 2;
			if (steps > 1)
			{
				Screen.Dim(0xffffff, 1.0, pipposX, pipposY, 4, int(round(height * 1.5)));
				// health value next to the pip above the gradient:
				Screen.DrawText(ConFont,
					Font.CR_White,
					pipposX + 5, pipposY,
					""..curVal.."\%",
					DTA_CleanNoMove_1, true);
			}
			// color value next to the pip below the gradient:
			Screen.DrawText(ConFont,
				Font.CR_White,
				pipposX + 5, y + height,
				String.Format("%06x", healthColors[i]),
				DTA_CleanNoMove_1, true);

			// determine if this element should be selected:
			if (selected && i == selectedRange)
			{
				// if there's only one element (i.e. it's one single
				// solid color for health regardless of value),
				// thresholds are not selectable:
				if (colorSelected || steps == 1)
				{
					indent = colPos + stripWidth / 2;
					selectedPosX = colPos;
					selectedPosY = y;
					selectedWidth = stripwidth;
					selectedHeight = height;
				}
				else
				{
					indent = pipPosX + 4;
					selectedPosX = pipPosX;
					selectedPosY = pipPosY;
					selectedWidth = 4;
					selectedHeight =  int(round(height * 1.5));
				}
			}
		}
		// start and end pips:
		int pip1x = x;
		int pip2x = x + width - 2;
		int pipY = y - height / 2;
		if (healthvalues[0] > 0)
		{
			Screen.Dim(0xffffff, 1.0, pip1x, pipY, 4, height*2);
			Screen.DrawText(ConFont,
				Font.CR_White,
				pip1x + 5, pipY,
				"0\%",
				DTA_CleanNoMove_1, true);
		}
		if (healthValues[healthValues.Size()-1] < lastRangeValue)
		{
			Screen.Dim(0xffffff, 1.0, pip2x, pipY, 4, height*2);
			Screen.DrawText(ConFont,
				Font.CR_White,
				pip2x + 5, pipY,
				String.Format("%d\%", lastRangeValue),
				DTA_CleanNoMove_1, true);
		}
		// draw selection highlight (a simple edge highlight fluctuating
		// between white and black, since no other combination is guaranteed
		// to look fine on top of other colors):
		if (selectedPosX > 0)
		{
			double ang = 360.0 * Menu.MenuTime() / TICRATE;
			double aW = sin(ang);
			Screen.Dim(0x000000, aW, selectedPosX, selectedPosY, selectedWidth, 2); //top
			Screen.Dim(0x000000, aW, selectedPosX, selectedPosY + selectedHeight - 2, selectedWidth, 2); //bottom
			Screen.Dim(0x000000, aW, selectedPosX, selectedPosY, 2, selectedHeight); //left
			Screen.Dim(0x000000, aW, selectedPosX + selectedWidth - 2, selectedPosY, 2, selectedHeight); //right
			double aB = 1.0 - aW;
			Screen.Dim(0xffffff, aB, selectedPosX, selectedPosY, selectedWidth, 2); //top
			Screen.Dim(0xffffff, aB, selectedPosX, selectedPosY + selectedHeight - 2, selectedWidth, 2); //bottom
			Screen.Dim(0xffffff, aB, selectedPosX, selectedPosY, 2, selectedHeight); //left
			Screen.Dim(0xffffff, aB, selectedPosX + selectedWidth - 2, selectedPosY, 2, selectedHeight); //right

			// if a pip is selected and is being currently moved,
			// draw simple text-based arrows next to it:
			if (setupMode == SM_Thresholds)
			{
				String sel = "< >";
				Screen.DrawText(ConFont,
					Font.CR_White,
					selectedPosX - ConFont.StringWidth(sel), y,
					sel,
					DTA_CleanNoMove, true,
					DTA_Alpha, aB);
			}
		}
		/*Screen.DrawText(ConFont,
			Font.CR_White,
			x, y + height,
			colorList.GetString(),
			DTA_CleanNoMove_1, true);*/
		return indent;
	}
}

class JGPUFH_HealthGradientMenu : JGPUFH_OptionMenu
{
	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		int sel = mDesc.mSelectedItem;
		// nothing special needs to be done:
		if (sel < 0 || sel >= mDesc.mItems.Size())
		{
			return Super.MenuEvent(mkey, fromcontroller);
		}
		// a different item is selected:
		let g = OptionMenuItemJGPUFH_ColorizedValueRange(mDesc.mItems[sel]);
		if (!g)
		{
			return Super.MenuEvent(mkey, fromcontroller);
		}
		int limit = g.GetMaxThresholds() - 1;
		if (limit <= 0)
		{
			return Super.MenuEvent(mkey, fromcontroller);
		}
		switch (mkey)
		{
		default:
			return Super.MenuEvent(mkey, fromcontroller);
			break;
		// pressing Right or Left will move the highlight across
		// the pips or ranges:
		case MKEY_Right:
			if (g.setupMode == g.SM_None)
			{
				if (g.colorSelected)
				{
					g.colorSelected = false;
					if (++g.selectedRange > limit)
					{
						g.selectedRange = 0;
					}
				}
				else 
				{
					g.colorSelected = true;
				}
				MenuSound ("menu/cursor");
			}
			else
			{
				int valueLimit;
				if (g.selectedRange < limit)
				{
					valueLimit = g.healthValues[g.selectedRange + 1] - 1;
				}
				else
				{
					valueLimit = 200;
				}
				if (g.healthValues[g.selectedRange] < valueLimit)
				{
					g.healthValues[g.selectedRange] += 1;
					MenuSound ("menu/cursor");
				}
			}
			break;
		case MKEY_Left:
			if (g.setupMode == g.SM_None)
			{
				if (g.colorSelected)
				{
					g.colorSelected = false;
				}
				else 
				{
					if (--g.selectedRange < 0)
					{
						g.selectedRange = limit;
					}
					g.colorSelected = true;
				}
				MenuSound ("menu/cursor");
			}
			else
			{
				int valueLimit;
				if (g.selectedRange > 0)
				{
					valueLimit = g.healthValues[g.selectedRange - 1] + 1;
				}
				else
				{
					valueLimit = 0;
				}
				if (g.healthValues[g.selectedRange] > valueLimit)
				{
					g.healthValues[g.selectedRange] -= 1;
					MenuSound ("menu/cursor");
				}
			}
			break;
		}
		return true;
	}
}

class JGPUFH_HealthColorPickerMenu : ColorPickerMenu
{
	int gradientColorID;
	OptionMenuItemJGPUFH_ColorizedValueRange gradientMenuItem;

	void Init(Menu parent,
		String name,
		OptionMenuDescriptor desc,
		OptionMenuItemJGPUFH_ColorizedValueRange item,
		int colorID,
		CVar currentStripColor
	)
	{
		gradientMenuItem = item;
		gradientcolorID = colorID;
		Super.Init(parent, name, desc, currentStripColor);
	}

	override void OnDestroy()
	{
		if (gradientMenuItem)
		{
			gradientMenuItem.healthColors[gradientColorID] = Color(int(mRed), int(mGreen), int(mBlue));
			gradientMenuItem.setupMode = gradientMenuItem.SM_None;
			gradientMenuItem.UpdateCVarFromArrays();
		}
		Super.OnDestroy();
	}
}