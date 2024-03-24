extend class JGPUFH_PresetHandler
{
	static const Name preset_cvars[] =
	{
		'jgphud_BackColor',
		'jgphud_BackStyle',
		'jgphud_BackAlpha',
		'jgphud_BackTexture',
		'jgphud_BackTextureStretch',

		'jgphud_ScreenReddenFactor',
		'jgphud_DrawDamageMarkers',
		'jgphud_DamageMarkersAlpha',
		'jgphud_DamageMarkersFadeTime',

		'jgphud_DrawMainbars',
		'jgphud_MainBarsPos',
		'jgphud_MainBarsX',
		'jgphud_MainBarsY',
		'jgphud_DrawFace',

		'jgphud_DrawAmmoBlock',
		'jgphud_AmmoBlockPos',
		'jgphud_AmmoBlockX',
		'jgphud_AmmoBlockY',
		'jgphud_DrawAmmoBar',
		'jgphud_DrawWeapon',

		'jgphud_DrawAllAmmo',
		'jgphud_AllAmmoShowDepleted',
		'jgphud_AllAmmoPos',
		'jgphud_AllAmmoX',
		'jgphud_AllAmmoY',
		'jgphud_AllAmmoColumns',
		'jgphud_AllAmmoShowMax',

		'jgphud_DrawKeys',
		'jgphud_KeysPos',
		'jgphud_KeysX',
		'jgphud_KeysY',

		'jgphud_DrawWeaponSlots',
		'jgphud_WeaponSlotsSize',
		'jgphud_WeaponSlotsAlign',
		'jgphud_WeaponSlotsPos',
		'jgphud_WeaponSlotsX',
		'jgphud_WeaponSlotsY',

		'jgphud_DrawPowerups',
		'jgphud_PowerupsIconSize',
		'jgphud_PowerupsPos',
		'jgphud_PowerupsX',
		'jgphud_PowerupsY',

		'jgphud_DrawMinimap',
		'jgphud_CircularMinimap',
		'jgphud_MinimapSize',
		'jgphud_MinimapPos',
		'jgphud_MinimapPosX',
		'jgphud_MinimapPosY',
		'jgphud_MinimapEnemyDisplay',
		'jgphud_MinimapEnemyShape',
		'jgphud_MinimapZoom',
		'jgphud_MinimapDrawUnseen',
		'jgphud_MinimapDrawFloorDiff',
		'jgphud_MinimapDrawCeilingDiff',
		'jgphud_MinimapMapMarkersSize',
		'jgphud_MinimapColorMode',
		'jgphud_MinimapBackColor',
		'jgphud_MinimapLineColor',
		'jgphud_MinimapIntLineColor',
		'jgphud_MinimapYouColor',
		'jgphud_MinimapMonsterColor',
		'jgphud_MinimapFriendColor',
		'jgphud_MinimapCardinalDir',
		'jgphud_MinimapCardinalDirSize',
		'jgphud_MinimapCardinalDirColor',
		'jgphud_MinimapOpacity',

		'jgphud_DrawKills',
		'jgphud_DrawItems',
		'jgphud_DrawSecrets',
		'jgphud_DrawTime',

		'jgphud_DrawInvBar',
		'jgphud_AlwaysShowInvBar',
		'jgphud_InvBarIconSize',
		'jgphud_InvBarPos',
		'jgphud_InvBarX',
		'jgphud_InvBarY',
		'jgphud_InvBarNumColor',

		'jgphud_DrawEnemyHitMarkers',
		'jgphud_EnemyHitMarkersColor',
		'jgphud_EnemyHitMarkersSize',
		'jgphud_EnemyHitMarkersShape',
		'jgphud_DrawReticleBars',
		'jgphud_ReticleBarsText',
		'jgphud_ReticleBarsSize',
		'jgphud_ReticleBarsHealthArmor',
		'jgphud_ReticleBarsAmmo',
		'jgphud_ReticleBarsEnemy',
		'jgphud_ReticleBarsAlpha',
		'jgphud_ReticleBarsWidth',

		'jgphud_DrawCustomItems',
		'jgphud_CustomItemsIconSize',
		'jgphud_CustomItemsPos',
		'jgphud_CustomItemsX',
		'jgphud_CustomItemsY',

		'jgphud_mainfont',
		'jgphud_smallfont',
		'jgphud_numberfont',
	
		'jgphud_BaseScale',
		'jgphud_MainBarsScale',
		'jgphud_AmmoBlockScale',
		'jgphud_AllAmmoScale',
		'jgphud_PowerupsScale',
		'jgphud_InvBarScale',
		'jgphud_KeysScale',
		'jgphud_WeaponSlotsScale',
		'jgphud_CustomItemsScale',
		'jgphud_ReticleBarsScale',

		'jgphud_MainBarsHealthColorMode',
		'jgphud_MainBarsHealthColor',
		'jgphud_MainbarsHealthRange_25',
		'jgphud_MainbarsHealthRange_50',
		'jgphud_MainbarsHealthRange_75',
		'jgphud_MainbarsHealthRange_100',
		'jgphud_MainbarsHealthRange_101',

		'jgphud_MainBarsArmorMode',
		'jgphud_MainBarsArmorColorMode',
		'jgphud_MainBarsArmorColor',
		'jgphud_MainbarsArmorRange_25',
		'jgphud_MainbarsArmorRange_50',
		'jgphud_MainbarsArmorRange_75',
		'jgphud_MainbarsArmorRange_100',
		'jgphud_MainbarsArmorRange_101',
		'jgphud_MainbarsAbsorbRange_33',
		'jgphud_MainbarsAbsorbRange_50',
		'jgphud_MainbarsAbsorbRange_66',
		'jgphud_MainbarsAbsorbRange_80',
		'jgphud_MainbarsAbsorbRange_100'
	};

	static const Class<JGPUFH_JsonElement> preset_cvar_json_types[] =
	{
		'JGPUFH_JsonNumber',	// jgphud_BackColor
		'JGPUFH_JsonBool',		// jgphud_BackStyle
		'JGPUFH_JsonNumber',	// jgphud_BackAlpha
		'JGPUFH_JsonString',	// jgphud_BackTexture
		'JGPUFH_JsonBool',		// jgphud_BackTextureStretch

		'JGPUFH_JsonNumber',	// jgphud_ScreenReddenFactor
		'JGPUFH_JsonBool',		// jgphud_DrawDamageMarkers
		'JGPUFH_JsonNumber',	// jgphud_DamageMarkersAlpha
		'JGPUFH_JsonNumber',	// jgphud_DamageMarkersFadeTime

		'JGPUFH_JsonNumber',	// jgphud_DrawMainbars
		'JGPUFH_JsonNumber',	// jgphud_MainBarsPos
		'JGPUFH_JsonNumber',	// jgphud_MainBarsX
		'JGPUFH_JsonNumber',	// jgphud_MainBarsY
		'JGPUFH_JsonBool',		// jgphud_DrawFace

		'JGPUFH_JsonBool',		// jgphud_DrawAmmoBlock
		'JGPUFH_JsonNumber',	// jgphud_AmmoBlockPos
		'JGPUFH_JsonNumber',	// jgphud_AmmoBlockX
		'JGPUFH_JsonNumber',	// jgphud_AmmoBlockY
		'JGPUFH_JsonBool',		// jgphud_DrawAmmoBar
		'JGPUFH_JsonBool',		// jgphud_DrawWeapon

		'JGPUFH_JsonNumber',	// jgphud_DrawAllAmmo
		'JGPUFH_JsonBool',		// jgphud_AllAmmoShowDepleted
		'JGPUFH_JsonNumber',	// jgphud_AllAmmoPos
		'JGPUFH_JsonNumber',	// jgphud_AllAmmoX
		'JGPUFH_JsonNumber',	// jgphud_AllAmmoY
		'JGPUFH_JsonNumber',	// jgphud_AllAmmoColumns
		'JGPUFH_JsonBool',		// jgphud_AllAmmoShowMax

		'JGPUFH_JsonBool',		// jgphud_DrawKeys
		'JGPUFH_JsonNumber',	// jgphud_KeysPos
		'JGPUFH_JsonNumber',	// jgphud_KeysX
		'JGPUFH_JsonNumber',	// jgphud_KeysY

		'JGPUFH_JsonNumber',	// jgphud_DrawWeaponSlots
		'JGPUFH_JsonNumber',	// jgphud_WeaponSlotsSize
		'JGPUFH_JsonNumber',	// jgphud_WeaponSlotsAlign
		'JGPUFH_JsonNumber',	// jgphud_WeaponSlotsPos
		'JGPUFH_JsonNumber',	// jgphud_WeaponSlotsX
		'JGPUFH_JsonNumber',	// jgphud_WeaponSlotsY

		'JGPUFH_JsonNumber',	// jgphud_DrawPowerups
		'JGPUFH_JsonNumber',	// jgphud_PowerupsIconSize
		'JGPUFH_JsonNumber',	// jgphud_PowerupsPos
		'JGPUFH_JsonNumber',	// jgphud_PowerupsX
		'JGPUFH_JsonNumber',	// jgphud_PowerupsY

		'JGPUFH_JsonNumber',	// jgphud_DrawMinimap
		'JGPUFH_JsonBool',		// jgphud_CircularMinimap
		'JGPUFH_JsonNumber',	// jgphud_MinimapSize
		'JGPUFH_JsonNumber',	// jgphud_MinimapPos
		'JGPUFH_JsonNumber',	// jgphud_MinimapPosX
		'JGPUFH_JsonNumber',	// jgphud_MinimapPosY
		'JGPUFH_JsonBool',		// jgphud_MinimapEnemyDisplay
		'JGPUFH_JsonBool',		// jgphud_MinimapEnemyShape
		'JGPUFH_JsonNumber',	// jgphud_MinimapZoom
		'JGPUFH_JsonNumber',	// jgphud_MinimapDrawUnseen
		'JGPUFH_JsonBool',		// jgphud_MinimapDrawFloorDiff
		'JGPUFH_JsonBool',		// jgphud_MinimapDrawCeilingDiff
		'JGPUFH_JsonNumber',	// jgphud_MinimapMapMarkersSize
		'JGPUFH_JsonNumber',	// jgphud_MinimapColorMode
		'JGPUFH_JsonNumber',	// jgphud_MinimapBackColor
		'JGPUFH_JsonNumber',	// jgphud_MinimapLineColor
		'JGPUFH_JsonNumber',	// jgphud_MinimapIntLineColor
		'JGPUFH_JsonNumber',	// jgphud_MinimapYouColor
		'JGPUFH_JsonNumber',	// jgphud_MinimapMonsterColor
		'JGPUFH_JsonNumber',	// jgphud_MinimapFriendColor
		'JGPUFH_JsonNumber',	// jgphud_MinimapCardinalDir
		'JGPUFH_JsonNumber',	// jgphud_MinimapCardinalDirSize
		'JGPUFH_JsonNumber',	// jgphud_MinimapCardinalDirColor
		'JGPUFH_JsonNumber',	// jgphud_MinimapOpacity

		'JGPUFH_JsonBool',		// jgphud_DrawKills
		'JGPUFH_JsonBool',		// jgphud_DrawItems
		'JGPUFH_JsonBool',		// jgphud_DrawSecrets
		'JGPUFH_JsonBool',		// jgphud_DrawTime

		'JGPUFH_JsonBool',		// jgphud_DrawInvBar
		'JGPUFH_JsonBool',		// jgphud_AlwaysShowInvBar
		'JGPUFH_JsonNumber',	// jgphud_InvBarIconSize
		'JGPUFH_JsonNumber',	// jgphud_InvBarPos
		'JGPUFH_JsonNumber',	// jgphud_InvBarX
		'JGPUFH_JsonNumber',	// jgphud_InvBarY
		'JGPUFH_JsonNumber',	// jgphud_InvBarNumColor

		'JGPUFH_JsonBool',		// jgphud_DrawEnemyHitMarkers
		'JGPUFH_JsonNumber',	// jgphud_EnemyHitMarkersColor
		'JGPUFH_JsonNumber',	// jgphud_EnemyHitMarkersSize
		'JGPUFH_JsonNumber',	// jgphud_EnemyHitMarkersShape
		'JGPUFH_JsonNumber',	// jgphud_DrawReticleBars
		'JGPUFH_JsonBool',		// jgphud_ReticleBarsText
		'JGPUFH_JsonNumber',	// jgphud_ReticleBarsSize
		'JGPUFH_JsonNumber',	// jgphud_ReticleBarsHealthArmor
		'JGPUFH_JsonNumber',	// jgphud_ReticleBarsAmmo
		'JGPUFH_JsonNumber',	// jgphud_ReticleBarsEnemy
		'JGPUFH_JsonNumber',	// jgphud_ReticleBarsAlpha
		'JGPUFH_JsonNumber',	// jgphud_ReticleBarsWidth

		'JGPUFH_JsonBool',		// jgphud_DrawCustomItems
		'JGPUFH_JsonNumber',	// jgphud_CustomItemsIconSize
		'JGPUFH_JsonNumber',	// jgphud_CustomItemsPos
		'JGPUFH_JsonNumber',	// jgphud_CustomItemsX
		'JGPUFH_JsonNumber',	// jgphud_CustomItemsY

		'JGPUFH_JsonString',	// jgphud_mainfont
		'JGPUFH_JsonString',	// jgphud_smallfont
		'JGPUFH_JsonString',	// jgphud_numberfont

		'JGPUFH_JsonNumber', 	// jgphud_BaseScale,
		'JGPUFH_JsonNumber', 	// jgphud_MainBarsScale,
		'JGPUFH_JsonNumber', 	// jgphud_AmmoBlockScale,
		'JGPUFH_JsonNumber', 	// jgphud_AllAmmoScale,
		'JGPUFH_JsonNumber', 	// jgphud_PowerupsScale,
		'JGPUFH_JsonNumber', 	// jgphud_InvBarScale,
		'JGPUFH_JsonNumber', 	// jgphud_KeysScale,
		'JGPUFH_JsonNumber', 	// jgphud_WeaponSlotsScale,
		'JGPUFH_JsonNumber', 	// jgphud_CustomItemsScale,
		'JGPUFH_JsonNumber', 	// jgphud_ReticleBarsScale

		'JGPUFH_JsonNumber', 	// jgphud_MainBarsHealthColorMode,
		'JGPUFH_JsonNumber', 	// jgphud_MainBarsHealthColor,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsHealthRange_25,
		'JGPUFH_JsonNumber',	// jgphud_MainbarsHealthRange_50,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsHealthRange_75,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsHealthRange_100,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsHealthRange_101,

		'JGPUFH_JsonNumber',	// jgphud_MainBarsArmorMode,
		'JGPUFH_JsonNumber',	// jgphud_MainBarsArmorColorMode,
		'JGPUFH_JsonNumber',	// jgphud_MainBarsArmorColor,
		'JGPUFH_JsonNumber',	// jgphud_MainbarsArmorRange_25,
		'JGPUFH_JsonNumber',	// jgphud_MainbarsArmorRange_50,
		'JGPUFH_JsonNumber',	// jgphud_MainbarsArmorRange_75,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsArmorRange_100,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsArmorRange_101,
		'JGPUFH_JsonNumber',	// jgphud_MainbarsAbsorbRange_33,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsAbsorbRange_50,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsAbsorbRange_66,
		'JGPUFH_JsonNumber', 	// jgphud_MainbarsAbsorbRange_80,
		'JGPUFH_JsonNumber' 	// jgphud_MainbarsAbsorbRange_100
	};

	static const String preset_cvar_data_types[] =
	{
		"general:jgphud_BackColor",
		"general:jgphud_BackStyle",
		"general:jgphud_BackAlpha",
		"general:jgphud_BackTexture",
		"general:jgphud_BackTextureStretch",
			
		"dmgmarkers:jgphud_ScreenReddenFactor",
		"dmgmarkers:jgphud_DrawDamageMarkers",
		"dmgmarkers:jgphud_DamageMarkersAlpha",
		"dmgmarkers:jgphud_DamageMarkersFadeTime",
			
		"mainbars:jgphud_DrawMainbars",
		"mainbars:jgphud_MainBarsPos",
		"mainbars:jgphud_MainBarsX",
		"mainbars:jgphud_MainBarsY",
		"mainbars:jgphud_DrawFace",
			
		"ammoblock:jgphud_DrawAmmoBlock",
		"ammoblock:jgphud_AmmoBlockPos",
		"ammoblock:jgphud_AmmoBlockX",
		"ammoblock:jgphud_AmmoBlockY",
		"ammoblock:jgphud_DrawAmmoBar",
		"ammoblock:jgphud_DrawWeapon",
			
		"allammo:jgphud_DrawAllAmmo",
		"allammo:jgphud_AllAmmoShowDepleted",
		"allammo:jgphud_AllAmmoPos",
		"allammo:jgphud_AllAmmoX",
		"allammo:jgphud_AllAmmoY",
		"allammo:jgphud_AllAmmoColumns",
		"allammo:jgphud_AllAmmoShowMax",
			
		"keys:jgphud_DrawKeys",
		"keys:jgphud_KeysPos",
		"keys:jgphud_KeysX",
		"keys:jgphud_KeysY",
			
		"wslots:jgphud_DrawWeaponSlots",
		"wslots:jgphud_WeaponSlotsSize",
		"wslots:jgphud_WeaponSlotsAlign",
		"wslots:jgphud_WeaponSlotsPos",
		"wslots:jgphud_WeaponSlotsX",
		"wslots:jgphud_WeaponSlotsY",
			
		"powerups:jgphud_DrawPowerups",
		"powerups:jgphud_PowerupsIconSize",
		"powerups:jgphud_PowerupsPos",
		"powerups:jgphud_PowerupsX",
		"powerups:jgphud_PowerupsY",
			
		"minimap:jgphud_DrawMinimap",
		"minimap:jgphud_CircularMinimap",
		"minimap:jgphud_MinimapSize",
		"minimap:jgphud_MinimapPos",
		"minimap:jgphud_MinimapPosX",
		"minimap:jgphud_MinimapPosY",
		"minimap:jgphud_MinimapEnemyDisplay",
		"minimap:jgphud_MinimapEnemyShape",
		"minimap:jgphud_MinimapZoom",
		"minimap:jgphud_MinimapDrawUnseen",
		"minimap:jgphud_MinimapDrawFloorDiff",
		"minimap:jgphud_MinimapDrawCeilingDiff",
		"minimap:jgphud_MinimapMapMarkersSize",
		"minimap:jgphud_MinimapColorMode",
		"minimap:jgphud_MinimapBackColor",
		"minimap:jgphud_MinimapLineColor",
		"minimap:jgphud_MinimapIntLineColor",
		"minimap:jgphud_MinimapYouColor",
		"minimap:jgphud_MinimapMonsterColor",
		"minimap:jgphud_MinimapFriendColor",
		"minimap:jgphud_MinimapCardinalDir",
		"minimap:jgphud_MinimapCardinalDirSize",
		"minimap:jgphud_MinimapCardinalDirColor",
		"minimap:jgphud_MinimapOpacity",
			
		"mapdata:jgphud_DrawKills",
		"mapdata:jgphud_DrawItems",
		"mapdata:jgphud_DrawSecrets",
		"mapdata:jgphud_DrawTime",
			
		"invbar:jgphud_DrawInvBar",
		"invbar:jgphud_AlwaysShowInvBar",
		"invbar:jgphud_InvBarIconSize",
		"invbar:jgphud_InvBarPos",
		"invbar:jgphud_InvBarX",
		"invbar:jgphud_InvBarY",
		"invbar:jgphud_InvBarNumColor",
			
		"hitmarkers:jgphud_DrawEnemyHitMarkers",
		"hitmarkers:jgphud_EnemyHitMarkersColor",
		"hitmarkers:jgphud_EnemyHitMarkersSize",
		"hitmarkers:jgphud_EnemyHitMarkersShape",

		"reticlebars:jgphud_DrawReticleBars",
		"reticlebars:jgphud_ReticleBarsText",
		"reticlebars:jgphud_ReticleBarsSize",
		"reticlebars:jgphud_ReticleBarsHealthArmor",
		"reticlebars:jgphud_ReticleBarsAmmo",
		"reticlebars:jgphud_ReticleBarsEnemy",
		"reticlebars:jgphud_ReticleBarsAlpha",
		"reticlebars:jgphud_ReticleBarsWidth",
			
		"customitems:jgphud_DrawCustomItems",
		"customitems:jgphud_CustomItemsIconSize",
		"customitems:jgphud_CustomItemsPos",
		"customitems:jgphud_CustomItemsX",
		"customitems:jgphud_CustomItemsY",
			
		"fonts:jgphud_mainfont",
		"fonts:jgphud_smallfont",
		"fonts:jgphud_numberfont",
			
		"scaling:jgphud_BaseScale",
		"scaling:jgphud_MainBarsScale",
		"scaling:jgphud_AmmoBlockScale",
		"scaling:jgphud_AllAmmoScale",
		"scaling:jgphud_PowerupsScale",
		"scaling:jgphud_InvBarScale",
		"scaling:jgphud_KeysScale",
		"scaling:jgphud_WeaponSlotsScale",
		"scaling:jgphud_CustomItemsScale",
		"scaling:jgphud_ReticleBarsScale",
			
		"mainbars:jgphud_MainBarsScale",
		"ammoblock:jgphud_AmmoBlockScale",
		"allammo:jgphud_AllAmmoScale",
		"powerups:jgphud_PowerupsScale",
		"invbar:jgphud_InvBarScale",
		"keys:jgphud_KeysScale",
		"wslots:jgphud_WeaponSlotsScale",
		"customitems:jgphud_CustomItemsScale",
		"reticlebars:jgphud_ReticleBarsScale",
			
		"healthcolors:jgphud_MainBarsHealthColorMode",
		"healthcolors:jgphud_MainBarsHealthColor",
		"healthcolors:jgphud_MainbarsHealthRange_25",
		"healthcolors:jgphud_MainbarsHealthRange_50",
		"healthcolors:jgphud_MainbarsHealthRange_75",
		"healthcolors:jgphud_MainbarsHealthRange_100",
		"healthcolors:jgphud_MainbarsHealthRange_101",
			
		"armorcolors:jgphud_MainBarsArmorMode",
		"armorcolors:jgphud_MainBarsArmorColorMode",
		"armorcolors:jgphud_MainBarsArmorColor",
		"armorcolors:jgphud_MainbarsArmorRange_25",
		"armorcolors:jgphud_MainbarsArmorRange_50",
		"armorcolors:jgphud_MainbarsArmorRange_75",
		"armorcolors:jgphud_MainbarsArmorRange_100",
		"armorcolors:jgphud_MainbarsArmorRange_101",
		"armorcolors:jgphud_MainbarsAbsorbRange_33",
		"armorcolors:jgphud_MainbarsAbsorbRange_50",
		"armorcolors:jgphud_MainbarsAbsorbRange_66",
		"armorcolors:jgphud_MainbarsAbsorbRange_80",
		"armorcolors:jgphud_MainbarsAbsorbRange_100"
	};
}