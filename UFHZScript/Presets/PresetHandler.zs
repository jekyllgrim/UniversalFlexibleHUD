class JGPUFH_PresetHandler : StaticEventHandler
{

	
	JGPUFH_JsonObject presets;
	
	Map<Name, Class<JGPUFH_JsonElement> > cvarTypes;
	
	override void OnRegister()
	{
		if(preset_cvars.Size() != preset_cvar_json_types.Size()) ThrowAbortException("mis-sized data arrays in PresetData.zs");
		
		int numCVars = preset_cvars.Size();
		
		for(int i = 0; i < numCVars; i++)
		{
			cvarTypes.Insert(preset_cvars[i], preset_cvar_json_types[i]);
		}
		
		let presetsOrError = JGPUFH_JSON.parse(__jgphud_user_presets_json);
		if(!(presetsOrError is 'JGPUFH_JsonObject'))
		{
			console.PrintfEx(PRINT_NONOTIFY, TEXTCOLOR_RED.."HUD Presets CVar has invalid JSON data");
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
					console.PrintfEx(PRINT_NONOTIFY, TEXTCOLOR_RED.."Invalid preset '"..preset_name.."' found");
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
							console.PrintfEx(PRINT_NONOTIFY, TEXTCOLOR_RED.."Invalid CVar '"..cvarName.."' found in preset '"..preset_name.."'");
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
	}
	
	clearscope void SavePresets()
	{
		CVar.FindCVar("__jgphud_user_presets_json").SetString(presets.serialize());
	}
	
	clearscope JGPUFH_JsonObject CurrentToJson()
	{
		let obj = JGPUFH_JsonObject.make();
		let n = preset_cvars.Size();
		for(uint i = 0; i < n; i++)
		{
			JGPUFH_JsonElement e;
			CVar c = CVar.FindCVar(preset_cvars[i]);
			
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
				ThrowAbortException("Unhandled CVar Type for '"..preset_cvars[i].."'");
			}
			obj.Set(preset_cvars[i],e);
		}
		return obj;
	}
	
	clearscope void LoadPreset(string preset_name)
	{
		let obj_e = presets.Get(preset_name);
		if(obj_e && obj_e is "JGPUFH_JsonObject")
		{
			let obj = JGPUFH_JsonObject(obj_e);
			let n = preset_cvars.Size();
			for(uint i = 0; i < n; i++)
			{
				CVar c = CVar.FindCVar(preset_cvars[i]);
				let e = obj.Get(preset_cvars[i]);
				
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
					ThrowAbortException("Unhandled CVar Type for '"..preset_cvars[i].."'");
				}
			}
		}
	}
	
	static clearscope void ResetToDefault()
	{
		let n = JGPUFH_PresetHandler.preset_cvars.Size();
		for(uint i = 0; i < n; i++)
		{
			CVar.FindCVar(JGPUFH_PresetHandler.preset_cvars[i]).ResetToDefault();
		}
	}
	
	static const Name enablerCVars[] =
	{
		'jgphud_DrawDamageMarkers',
		'jgphud_DrawMainbars',
		'jgphud_DrawAmmoBlock',
		'jgphud_DrawAmmoBar',
		'jgphud_DrawWeapon',
		'jgphud_DrawAllAmmo',
		'jgphud_DrawKeys',
		'jgphud_DrawWeaponSlots',
		'jgphud_DrawPowerups',
		'jgphud_DrawMinimap',
		'jgphud_DrawKills',
		'jgphud_DrawItems',
		'jgphud_DrawSecrets',
		'jgphud_DrawTime',
		'jgphud_DrawInvBar',
		'jgphud_DrawEnemyHitMarkers',
		'jgphud_DrawCustomItems'
	};
	
	static clearscope void DisableAllElements()
	{
		let n = JGPUFH_PresetHandler.enablerCVars.Size();
		for(uint i = 0; i < n; i++)
		{
			CVar.FindCVar(JGPUFH_PresetHandler.enablerCVars[i]).SetBool(false);
		}
	}
	
	static clearscope void LoadMinimapOnlyPreset()
	{
		ResetToDefault();
		DisableAllElements();
		CVar.FindCVar('jgphud_DrawMinimap').SetBool(true);
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
		case 'LoadMinimapOnlyPreset':
			LoadMinimapOnlyPreset();
			break;
		default:
			console.PrintfEx(PRINT_NONOTIFY,TEXTCOLOR_RED.."Unkonwn command for ExecuteCommand '"..cmd.."'");
		}
	}
}