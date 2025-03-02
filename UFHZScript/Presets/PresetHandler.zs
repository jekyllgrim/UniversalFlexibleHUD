class JGPUFH_PresetHandler : StaticEventHandler
{
	JGPUFH_JsonObject presets;
	
	JGPUFH_JsonObject default_presets;
	
	Map<Name, Class<JGPUFH_JsonElement> > cvarTypes;
	
	JGPUFH_JsonObject LoadPresets(String jsonData, bool isCVar)
	{
		JGPUFH_JsonObject presets;
		
		let presetsOrError = JGPUFH_JSON.parse(jsonData);
		if(!(presetsOrError is 'JGPUFH_JsonObject'))
		{
			console.PrintfEx(PRINT_NONOTIFY, TEXTCOLOR_RED.."HUD "..(isCVar ? "Presets CVar" : "Default Presets").." has invalid JSON data");
			presets = JGPUFH_JsonObject.make();
		}
		else
		{
			presets = JGPUFH_JsonObject(presetsOrError);
			
			
			MapIterator<String,JGPUFH_JsonElement> it;
			it.Init(presets.data);
			
			Array<String> invalidPresets;
			
			while(it.Next())
			{
				let preset_name = it.getKey();
				let elem = it.getValue();
				
				if(!(elem is "JGPUFH_JsonObject"))
				{
					console.PrintfEx(PRINT_NONOTIFY, TEXTCOLOR_RED.."Invalid "..(isCVar ? "" : "default ").."preset '"..preset_name.."' found");
					invalidPresets.Push(preset_name);
				}
				else
				{
					let obj = JGPUFH_JsonObject(elem);
					
					Array<String> invalidKeys;
					
					MapIterator<String,JGPUFH_JsonElement> it2;
					it2.Init(obj.data);
					
					while(it2.Next())
					{
						let cvarName = it2.getKey();
						
						Class<JGPUFH_JsonElement> expectedClass = cvarTypes.GetIfExists(cvarName);
						let obj_elem = it2.getValue();
						
						if(expectedClass == null || !(obj_elem is expectedClass))
						{
							console.PrintfEx(PRINT_NONOTIFY, TEXTCOLOR_RED.."Invalid CVar '"..cvarName.."' found in "..(isCVar ? "" : "default ").."preset '"..preset_name.."'");
							invalidKeys.Push(cvarName);
						}
					}
					
					foreach(cvarName : invalidKeys)
					{
						obj.Delete(cvarName);
					}
				}
			}
			
			foreach(presetName : invalidPresets)
			{
				presets.Delete(presetName);
			}
		}
		
		return presets;
	}
	
	override void OnRegister()
	{
		InitalizeJGPHUDCvars();
		
		int numCVars = cvardata.Size();
		
		for(int i = 0; i < numCVars; i++)
		{
			let data = cvardata[i];
			if (!data) continue;

			class<JGPUFH_JsonElement> e;
			switch(data.c_cvar.GetRealType())
			{
			case CVar.CVAR_Int:
			case CVar.CVAR_Color:
				e = 'JGPUFH_JsonInt';
				break;
			case CVar.CVAR_String:
				e = 'JGPUFH_JsonString';
				break;
			case CVar.CVAR_Float:
				e = 'JGPUFH_JsonDouble';
				break;
			case CVar.CVAR_Bool:
				e = 'JGPUFH_JsonBool';
				break;
			default:
				ThrowAbortException("Invalid CVar type for cvar "..data.cvarname);
				break;
			}
			cvarTypes.Insert(data.cvarName, e);
		}
		
		presets = LoadPresets(__jgphud_user_presets_json, true);
		default_presets = LoadPresets(JGPUFH_DefaultPresets.default_presets_json, false);
	}
	
	clearscope void SavePresets()
	{
		CVar.FindCVar("__jgphud_user_presets_json").SetString(presets.serialize());
	}
	
	clearscope JGPUFH_JsonObject CurrentToJson()
	{
		let obj = JGPUFH_JsonObject.make();
		let n = cvardata.Size();
		for(int i = 0; i < n; i++)
		{
			let data = cvardata[i];
			if (!data) continue;
			
			JGPUFH_JsonElement e;
			CVar c = data.c_cvar;
			switch(c.GetRealType())
			{
			case CVar.CVAR_Int:
			case CVar.CVAR_Color:
				e = JGPUFH_JsonInt.make(c.GetInt());
				break;
			case CVar.CVAR_Float:
				e = JGPUFH_JsonDouble.make(c.GetFloat());
				break;
			case CVar.CVAR_Bool:
				e = JGPUFH_JsonBool.make(c.GetBool());
				break;
			case CVar.CVAR_String:
				e = JGPUFH_JsonString.make(c.GetString());
				break;
			default:
				ThrowAbortException("Unhandled CVar Type for '"..data.cvarname.."'");
			}
			obj.Set(data.cvarname,e);
		}
		return obj;
	}
	
	static clearscope void LoadPresetJSON(JGPUFH_JsonObject obj)
	{
		let handler = JGPUFH_PresetHandler(StaticEventHandler.Find('JGPUFH_PresetHandler'));
		if (!handler)
		{
			ThrowAbortException("PresetHandler not found");
			return;
		}
		let n = handler.cvardata.Size();
		for(int i = 0; i < n; i++)
		{
			let data = handler.cvardata[i];
			if (!data) continue;

			CVar c = data.c_cvar;
			let e = obj.Get(data.cvarname);
			
			if(!e)
			{
				c.ResetToDefault();
			}
			else switch(c.GetRealType())
			{
			case CVar.CVAR_Int:
			case CVar.CVAR_Color:
				c.SetInt(JGPUFH_JsonNumber(e).asInt());
				break;
			case CVar.CVAR_Float:
				c.SetFloat(JGPUFH_JsonNumber(e).asDouble());
				break;
			case CVar.CVAR_Bool:
				c.SetBool(JGPUFH_JsonBool(e).b);
				break;
			case CVar.CVAR_String:
				c.SetString(JGPUFH_JsonString(e).s);
				break;
			default:
				ThrowAbortException("Unhandled CVar Type for '"..data.cvarname.."'");
			}
		}
	}
	
	clearscope void LoadPreset(string preset_name)
	{
		let obj_e = presets.Get(preset_name);
		if(obj_e && obj_e is "JGPUFH_JsonObject")
		{
			LoadPresetJSON(JGPUFH_JsonObject(obj_e));
		}
	}
	
	static clearscope void ResetToDefault()
	{
		let handler = JGPUFH_PresetHandler(StaticEventHandler.Find('JGPUFH_PresetHandler'));
		if (!handler)
		{
			ThrowAbortException("JGPUFH_PresetHandler not found");
			return;
		}
		let n = handler.cvardata.Size();
		for(int i = 0; i < n; i++)
		{
			let data = handler.cvardata[i];
			if (!data) continue;
			data.c_cvar.ResetToDefault();
		}
	}
	
	clearscope void ExecuteCommand(name cmd, string data)
	{
		switch(cmd)
		{
		case 'SaveUserPreset':
			presets.Set(data, CurrentToJson());
			SavePresets();
			break;
		case 'DeleteUserPreset':
			presets.Delete(data);
			SavePresets();
			break;
		case 'LoadUserPreset':
			LoadPreset(data);
			break;
		case 'ResetToDefault':
		case 'LoadDefaultPreset':
			ResetToDefault();
			break;
		case 'LoadBuiltInPresetJSON':
			{
				JGPUFH_JsonObject obj = JGPUFH_JsonObject(default_presets.Get(data)); 
				if(obj) LoadPresetJSON(obj);
			}
			break;
		default:
			console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Unkonwn command for ExecuteCommand '"..cmd.."'");
		}
	}
}