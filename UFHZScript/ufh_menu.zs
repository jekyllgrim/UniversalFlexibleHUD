class OptionMenuItemJGPHUDResetCCMD : OptionMenuItemSubmenu
{
	private array <String> ccmds;

	OptionMenuItemJGPHUDResetCCMD Init(String label, string commands, bool centered = false)
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