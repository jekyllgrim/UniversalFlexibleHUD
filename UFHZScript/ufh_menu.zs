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
class OptionMenuItemJGPUFHResetALLCCMD : OptionMenuItemSubmenu
{
	int mCVarCategory;

	OptionMenuItemJGPUFHResetALLCCMD Init(String label, bool centered = false, String type = "")
	{
		Super.Init(label, '', 0, centered);
		name ttype = type.MakeLower();
		switch (ttype)
		{
		default:
			mCVarCategory = JGPUFH_PresetHandler.CVC_None;
			break;
		case 'general':
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
		}
		return self;
	}

	override bool Activate()
	{
		if (mCVarCategory == JGPUFH_PresetHandler.CVC_None)
		{
			JGPUFH_PresetHandler.ResetToDefault();
			return true;
		}

		let handler = JGPUFH_PresetHandler(StaticEventHandler.Find('JGPUFH_PresetHandler'));
		if (!handler) return false;

		foreach(data: handler.cvardata)
		{
			if (!data) continue;
			if (data.cvarCategory & mCVarCategory)
			{
				data.c_cvar.ResetToDefault();
			}
		}
		return true;
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