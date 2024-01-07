// This class is here simply so that I can feed it
// to the Class property in MENUDEF. This lets me detect
// that the mod's settings menu is open:
class JGPHUD_OptionMenu : OptionMenu
{}

class OptionMenuItemUFHResetCCMD : OptionMenuItemSubmenu
{
	private array <String> ccmds;

	OptionMenuItemUFHResetCCMD Init(String label, string commands, bool centered = false)
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

class OptionMenuItemUFHResetALLCCMD : OptionMenuItemSubmenu
{
	OptionMenuItemUFHResetALLCCMD Init(String label, bool centered = false)
	{
		Super.Init(label, '', 0, centered);
		return self;
	}

	override bool Activate()
	{
		JGPUFH_PresetHandler.ResetToDefault();
		return true;
	}
}

mixin class UFHCVarChecker
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
			ThrowAbortException("\cGERROR: \cDParseGrayConditions()\c- detected incorrect value declaration");
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
				ThrowAbortException(String.Format("\cGERROR: \cDParseGrayConditions()\c- detected incorrect condition declaration \cG%s\c-. Supported values: \cD\"0\"\c-, \cD\"!:0\"\c-, \cD\">:0\"\c-, \cD\"<:0\"\c- where \cD0\c- is the desired value. Only numeric CVars are supported.", s));
				return;
			}
			val = values[1].ToInt();
		}
	}

	void ParseGrayConditions(CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
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

	bool ShouldBeGrayed()
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

class OptionMenuItemUFHSlider : OptionMenuItemSlider
{
	mixin UFHCVarChecker;

	OptionMenuItemUFHSlider Init(String label, Name command, double min, double max, double step, int showval = 1, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, min, max, step, showval, null);
		ParseGrayConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override bool IsGrayed(void)
	{
		return ShouldBeGrayed();
	}
}

class OptionMenuItemUFHOption : OptionMenuItemOption
{
	mixin UFHCVarChecker;

	OptionMenuItemUFHOption Init(String label, Name command, Name values, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, values, null, 0);
		ParseGrayConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override bool IsGrayed(void)
	{
		return ShouldBeGrayed();
	}
}

class OptionMenuItemUFHScaleSlider : OptionMenuItemScaleSlider
{
	mixin UFHCVarChecker;

	OptionMenuItemUFHScaleSlider Init(String label, Name command, double min, double max, double step, String zero, String negone = "", CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, min, max, step, zero, negone);
		ParseGrayConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		drawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor, IsGrayed());

		int Selection = int(GetSliderValue());
		if ((Selection == 0 || Selection == -1) && mClickVal <= 0)
		{
			String text = Selection == 0? TextZero : Selection == -1? TextNegOne  : "";
			drawValue(indent, y, OptionMenuSettings.mFontColorValue, text, IsGrayed());
		}
		else
		{
			mDrawX = indent + CursorSpace();
			DrawSlider (mDrawX, y, mMin, mMax, GetSliderValue(), mShowValue, indent, IsGrayed());
		}
		return indent;
	}

	override bool IsGrayed(void)
	{
		return ShouldBeGrayed();
	}
}

class OptionMenuItemUFHColorPicker : OptionMenuItemColorPicker
{
	mixin UFHCVarChecker;

	OptionMenuItemUFHColorPicker Init(String label, Name command, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command);
		ParseGrayConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	//=============================================================================
	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		drawLabel(indent, y, selected? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor,  IsGrayedEx());

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
		return ShouldBeGrayed();
	}

	override bool Selectable()
	{
		return !IsGrayedEx();
	}
}

class OptionMenuItemUFHTextField : OptionMenuItemTextField
{
	mixin UFHCVarChecker;

	OptionMenuItemUFHTextField Init (String label, Name command, CVar _grayCheck1 = null, string _grayCheck1value = "", int _cvarLogic = GC_AND, CVar _grayCheck2 = null, string _grayCheck2value = "")
	{
		Super.Init(label, command, null);
		ParseGrayConditions(_grayCheck1, _grayCheck1value, _cvarLogic, _grayCheck2, _grayCheck2value);
		return self;
	}

	override int Draw(OptionMenuDescriptor desc, int y, int indent, bool selected)
	{
		if (mEnter)
		{
			// reposition the text so that the cursor is visible when in entering mode.
			String text = Represent();
			int tlen = Menu.OptionWidth(text, false) * CleanXfac_1;
			int newindent = screen.GetWidth() - tlen - CursorSpace();
			if (newindent < indent) indent = newindent;
		}
		bool grayed = IsGrayedEx();
		drawLabel(indent, y, selected ? OptionMenuSettings.mFontColorSelection : OptionMenuSettings.mFontColor, grayed);
		drawValue(indent, y, OptionMenuSettings.mFontColorValue, Represent(), grayed, false);
		return indent;
	}

	bool IsGrayedEx()
	{
		return ShouldBeGrayed();
	}

	override bool Selectable(void)
	{
		return !ShouldBeGrayed();
	}
}