class JGPUFH_PresetMessageBox : CustomMessageBoxMenuBase {
	
	string mPreset;
	
	static const string options[] = 
	{
		"$JGPHUD_Presets_Verb_Load",
		"$JGPHUD_Presets_Verb_Overwrite",
		"$JGPHUD_Presets_Verb_Delete",
		"$JGPHUD_Presets_Menu_Cancel"
	};
	
	static const string cmds[] = 
	{
		"LoadUserPreset",
		"SaveUserPreset",
		"DeleteUserPreset"
	};
	
	int confirm_index;
	
	override uint optionCount()
	{
		return options.Size();
	}
	
	override string optionName(uint i)
	{
		return StringTable.Localize(options[i]);
	}
	
	override int OptionXOffset(uint index) 
	{
		return -30;
	}
	
	// -1 = no shortcut
	override int OptionForShortcut(int char_key, out bool activate) 
	{
		if(char_key == 110) 
		{
			activate = false;
			return 3;
		}
		return -1;
	}
	
	// -1 = escape
	override void HandleResult(int i) 
	{
		if(i == -1 || i == 3) 
		{
			CloseSound();
			Close();
		}
		else
		{
			MenuSound("menu/activate");
			confirm_index = i;
			string msg = StringTable.Localize("$JGPHUD_Presets_ConfirmAction");
			msg = String.Format(msg, StringTable.Localize(options[i]), mPreset);
			Menu.StartMessage(TEXTCOLOR_NORMAL..msg, 0);
		}
	}
	
	int toClose;
	
	override void OnReturn() 
	{
		if(toClose) 
		{
			JGPUFH_UserPresetsMenu(mParentMenu).toClose = toClose - 1;
			Close();
		}
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mkey == Menu.MKEY_MBYes)
		{
			JGPUFH_PresetHandler(StaticEventHandler.Find("JGPUFH_PresetHandler")).ExecuteCommand(cmds[confirm_index],mPreset);
			toClose = confirm_index == 0 ? 3 : confirm_index == 1 ? 1 : 2;
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}
	
}

class JGPUFH_UserPreset : OptionMenuItemSubmenu
{
	String mPreset;


	JGPUFH_UserPreset Init(String preset)
	{
		Super.Init(preset, "");
		mPreset = preset;
		return self;
	}

	override bool Activate()
	{
		let mBox = new("JGPUFH_PresetMessageBox");
		mBox.mPreset = mPreset;
		mBox.Init(Menu.GetCurrentMenu(),mPreset,true);
		mBox.ActivateMenu();
		return true;
	}
}

class JGPUFH_SavePresetMenu : JGPHUD_OptionMenu
{
	bool toClose;
	
	override void OnReturn() 
	{
		if(toClose) 
		{
			Close();
		}
	}
}

class OptionMenuItemJGPUFH_SaveUserPreset : OptionMenuItemSubmenu
{
	OptionMenuItemJGPUFH_SaveUserPreset Init()
	{
		Super.Init(StringTable.Localize("$JGPHUD_Presets_Menu_Confirm"), "", 0, true);
		return self;
	}
	
	JGPUFH_SavePresetMenu parentMenu;

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mkey == Menu.MKEY_MBYes)
		{
			JGPUFH_PresetHandler(StaticEventHandler.Find("JGPUFH_PresetHandler")).ExecuteCommand("SaveUserPreset",__jgphud_save_preset_name);
			CVar.GetCVar("__jgphud_save_preset_name").SetString("");
			parentMenu.toClose = true;
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}
	
	override bool Activate()
	{
		let handler = JGPUFH_PresetHandler(StaticEventHandler.Find("JGPUFH_PresetHandler"));
		parentMenu = JGPUFH_SavePresetMenu(Menu.GetCurrentMenu());
		handler.presets;
		String msg;
		if(__jgphud_save_preset_name.RightIndexOf(" ") != -1){
			msg = StringTable.Localize("$JGPHUD_Preset_Warning_Whitespace");
			Menu.StartMessage(TEXTCOLOR_NORMAL..msg, 1);
		} else if(handler.presets.Get(__jgphud_save_preset_name) != null) {
			msg = StringTable.Localize("$JGPHUD_Preset_Warning_Overwrite");
			msg = String.Format(msg, __jgphud_save_preset_name);
			Menu.StartMessage(TEXTCOLOR_NORMAL..msg, 0);
		} else if(__jgphud_save_preset_name.Length() == 0){
			msg = StringTable.Localize("$JGPHUD_Preset_Warning_EmptyName");
			Menu.StartMessage(TEXTCOLOR_NORMAL..msg, 1);
		} else {
			handler.ExecuteCommand("SaveUserPreset",__jgphud_save_preset_name);
			parentMenu.Close();
		}
		return true;
	}
}


class OptionMenuItemJGPUFH_ConfirmCommand : OptionMenuItemSubmenu
{
	String mPrompt;
	Name mCommand;
	String mData;


	OptionMenuItemJGPUFH_ConfirmCommand Init(String label,Name command,String data, String prompt = "")
	{
		Super.Init(label, "");
		mPrompt = StringTable.Localize(prompt);
		mCommand = command;
		mData = data;
		return self;
	}

	override bool MenuEvent (int mkey, bool fromcontroller)
	{
		if (mkey == Menu.MKEY_MBYes)
		{
			JGPUFH_PresetHandler(StaticEventHandler.Find("JGPUFH_PresetHandler")).ExecuteCommand(mCommand,mData);
			return true;
		}
		return Super.MenuEvent(mkey, fromcontroller);
	}
	
	override bool Activate()
	{
		Menu.StartMessage(TEXTCOLOR_NORMAL..mPrompt, 0);
		return true;
	}
}


class JGPUFH_UserPresetsMenu : JGPHUD_OptionMenu
{
	
	void RebuildList(OptionMenuDescriptor desc)
	{
		let handler = JGPUFH_PresetHandler(StaticEventHandler.Find("JGPUFH_PresetHandler"));
		desc.mItems.Clear();
		Array<String> keys;
		handler.presets.GetKeysInto(keys);
		let n = keys.Size();
		for(int i = 0; i < n; i++)
		{
			desc.mItems.Push(new("JGPUFH_UserPreset").Init(keys[i]));
		}
	}
	
	
	override void Init(Menu parent, OptionMenuDescriptor desc)
	{
		RebuildList(desc);
		
		Super.Init(parent,desc);
	}
	
	int toClose;
	
	override void OnReturn()
	{
		if(toClose) 
		{
			JGPUFH_PresetsMenu(mParentMenu).toClose = toClose - 1;
			mDesc.mSelectedItem = 0;
			Close();
		}
	}
}

class OptionMenuItemJGPUFH_UserPresetsSubmenu : OptionMenuItemSubmenu
{
	JGPUFH_PresetHandler handler;
	OptionMenuItemJGPUFH_UserPresetsSubmenu Init(String label, Name command, int param = 0, bool centered = false)
	{
		Super.Init(label,command,param,centered);
		handler = JGPUFH_PresetHandler(StaticEventHandler.Find("JGPUFH_PresetHandler"));
		return self;
	}
	override bool Selectable()
	{
		return handler.presets.size() != 0;
	}
	
	override bool Activate()
	{
		if(Selectable()) return Super.Activate();
		return false;
	}
}

class JGPUFH_PresetsMenu : JGPHUD_OptionMenu
{
	bool toClose;
	
	override void OnReturn()
	{
		CVar.GetCVar("__jgphud_save_preset_name").SetString("");
		if(toClose) 
		{
			Close();
		}
	}
}