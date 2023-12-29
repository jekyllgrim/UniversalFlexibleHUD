// This classes are here simply so that I can feed it
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
