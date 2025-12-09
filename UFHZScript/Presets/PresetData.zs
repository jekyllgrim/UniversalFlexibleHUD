class JGPUFH_PresetCVarData
{
	CVar c_cvar;
	name cvarName;
	int cvarCategory;

	static JGPUFH_PresetCVarData Add(name cvarname, out array<JGPUFH_PresetCVarData> arr = null, int category = 0)
	{
		let data = new('JGPUFH_PresetCVarData');
		if (!data) return null;
		if (data)
		{
			data.c_cvar = CVar.FindCVar(cvarname);
			if (!data.c_cvar)
			{
				return null;
			}
			data.cvarName = cvarname;
			data.cvarCategory = category;
		}
		if (data && arr != null)
		{
			arr.Push(data);
		}
		return data;
	}
}

extend class JGPUFH_PresetHandler
{
	array<JGPUFH_PresetCVarData> cvarData;

	enum ECVarCategories
	{
		CVC_None			= 0,
		CVC_General			= 1 << 1,
		CVC_DmgMarkers		= 1 << 2,
		CVC_Mainbars		= 1 << 3,
		CVC_MugShot			= 1 << 4,
		CVC_AmmoBlock		= 1 << 5,
		CVC_AllAmmo			= 1 << 6,
		CVC_Keys			= 1 << 7,
		CVC_WSlots			= 1 << 8,
		CVC_Powerups		= 1 << 9,
		CVC_Minimap			= 1 << 10,
		CVC_Mapdata			= 1 << 11,
		CVC_InvBar			= 1 << 12,
		CVC_Hitmarkers		= 1 << 13,
		CVC_ReticleBars		= 1 << 14,
		CVC_CustomItems		= 1 << 16,
		CVC_Fonts			= 1 << 17,
		CVC_HealthColors	= 1 << 18,
		CVC_ArmorColors		= 1 << 19,
		CVC_Scaling			= 1 << 20,
		CVC_Visibility		= 1 << 21,
		CVC_Scoreboard		= 1 << 22,
		CVC_Compass			= 1 << 23,
	}

	void InitalizeJGPHUDCvars()
	{
		JGPUFH_PresetCVarData.Add('jgphud_BackColor', cvarData, CVC_General);
		JGPUFH_PresetCVarData.Add('jgphud_BackStyle', cvarData, CVC_General);
		JGPUFH_PresetCVarData.Add('jgphud_BackAlpha', cvarData, CVC_General);
		JGPUFH_PresetCVarData.Add('jgphud_BackTexture', cvarData, CVC_General);
		JGPUFH_PresetCVarData.Add('jgphud_BackTextureStretch', cvarData, CVC_General);

		JGPUFH_PresetCVarData.Add('jgphud_DrawDamageMarkers', cvarData, CVC_DmgMarkers|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_ScreenReddenFactor', cvarData, CVC_DmgMarkers);
		JGPUFH_PresetCVarData.Add('jgphud_DamageMarkersAlpha', cvarData, CVC_DmgMarkers);
		JGPUFH_PresetCVarData.Add('jgphud_DamageMarkersFadeTime', cvarData, CVC_DmgMarkers);

		JGPUFH_PresetCVarData.Add('jgphud_DrawMainbars', cvarData, CVC_Mainbars|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsPos', cvarData, CVC_Mainbars);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsX', cvarData, CVC_Mainbars);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsY', cvarData, CVC_Mainbars);
		JGPUFH_PresetCVarData.Add('jgphud_DrawFace', cvarData, CVC_Mainbars);

		JGPUFH_PresetCVarData.Add('jgphud_DrawMugshot', cvarData, CVC_MugShot|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_MugshotPos', cvarData, CVC_MugShot);
		JGPUFH_PresetCVarData.Add('jgphud_MugshotX', cvarData, CVC_MugShot);
		JGPUFH_PresetCVarData.Add('jgphud_MugshotY', cvarData, CVC_MugShot);

		JGPUFH_PresetCVarData.Add('jgphud_DrawAmmoBlock', cvarData, CVC_AmmoBlock|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_AmmoBlockPos', cvarData, CVC_AmmoBlock);
		JGPUFH_PresetCVarData.Add('jgphud_AmmoBlockX', cvarData, CVC_AmmoBlock);
		JGPUFH_PresetCVarData.Add('jgphud_AmmoBlockY', cvarData, CVC_AmmoBlock);
		JGPUFH_PresetCVarData.Add('jgphud_DrawAmmoBar', cvarData, CVC_AmmoBlock);
		JGPUFH_PresetCVarData.Add('jgphud_DrawWeapon', cvarData, CVC_AmmoBlock);

		JGPUFH_PresetCVarData.Add('jgphud_DrawAllAmmo', cvarData, CVC_AllAmmo|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoShowDepleted', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoPos', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoX', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoY', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoColumns', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoShowMax', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoShowBar', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoColorLow', cvarData, CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoColorHigh', cvarData, CVC_AllAmmo);

		JGPUFH_PresetCVarData.Add('jgphud_DrawKeys', cvarData, CVC_Keys|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_KeysPos', cvarData, CVC_Keys);
		JGPUFH_PresetCVarData.Add('jgphud_KeysX', cvarData, CVC_Keys);
		JGPUFH_PresetCVarData.Add('jgphud_KeysY', cvarData, CVC_Keys);

		JGPUFH_PresetCVarData.Add('jgphud_DrawWeaponSlots', cvarData, CVC_WSlots|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_WeaponSlotsSize', cvarData, CVC_WSlots);
		JGPUFH_PresetCVarData.Add('jgphud_WeaponSlotsAlign', cvarData, CVC_WSlots);
		JGPUFH_PresetCVarData.Add('jgphud_WeaponSlotsPos', cvarData, CVC_WSlots);
		JGPUFH_PresetCVarData.Add('jgphud_WeaponSlotsX', cvarData, CVC_WSlots);
		JGPUFH_PresetCVarData.Add('jgphud_WeaponSlotsY', cvarData, CVC_WSlots);
		JGPUFH_PresetCVarData.Add('jgphud_WeaponSlotsNumColor', cvarData, CVC_WSlots);

		JGPUFH_PresetCVarData.Add('jgphud_DrawPowerups', cvarData, CVC_Powerups|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_PowerupsAlignment', cvarData, CVC_Powerups);
		JGPUFH_PresetCVarData.Add('jgphud_PowerupsIconSize', cvarData, CVC_Powerups);
		JGPUFH_PresetCVarData.Add('jgphud_PowerupsPos', cvarData, CVC_Powerups);
		JGPUFH_PresetCVarData.Add('jgphud_PowerupsX', cvarData, CVC_Powerups);
		JGPUFH_PresetCVarData.Add('jgphud_PowerupsY', cvarData, CVC_Powerups);
		JGPUFH_PresetCVarData.Add('jgphud_PowerupsNumColor', cvarData, CVC_Powerups);

		JGPUFH_PresetCVarData.Add('jgphud_DrawScoreboard', cvarData, CVC_Scoreboard|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_ScoreboardScale', cvarData, CVC_Scoreboard);
		JGPUFH_PresetCVarData.Add('jgphud_ScoreboardPos', cvarData, CVC_Scoreboard);
		JGPUFH_PresetCVarData.Add('jgphud_ScoreboardX', cvarData, CVC_Scoreboard);
		JGPUFH_PresetCVarData.Add('jgphud_ScoreboardY', cvarData, CVC_Scoreboard);

		JGPUFH_PresetCVarData.Add('jgphud_DrawMinimap', cvarData, CVC_Minimap|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_CircularMinimap', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapSize', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapPos', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapPosX', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapPosY', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapMapMarkers', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapMapMarkersScale', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapEnemyDisplay', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapEnemyShape', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapZoom', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapDrawUnseen', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapDrawFloorDiff', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapDrawCeilingDiff', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapColorMode', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapBackColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapLineColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapIntLineColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapFloorDiffLineColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapCeilDiffLineColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapUnseenLineColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapUnseenSeparateColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapSecretLineColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapYouColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapMonsterColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapFriendColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapBlockLineThickness', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapNonblockLineThickness', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapCardinalDir', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapCardinalDirSize', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapCardinalDirColor', cvarData, CVC_Minimap);
		JGPUFH_PresetCVarData.Add('jgphud_MinimapOpacity', cvarData, CVC_Minimap);

		JGPUFH_PresetCVarData.Add('jgphud_MapDataScale', cvarData, CVC_Mapdata);
		JGPUFH_PresetCVarData.Add('jgphud_DrawKills', cvarData, CVC_Mapdata|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_DrawItems', cvarData, CVC_Mapdata|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_DrawSecrets', cvarData, CVC_Mapdata|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_DrawTime', cvarData, CVC_Mapdata|CVC_Visibility);

		JGPUFH_PresetCVarData.Add('jgphud_DrawCompass', cvarData, CVC_Compass|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_CompassStyle', cvarData, CVC_Compass);
		JGPUFH_PresetCVarData.Add('jgphud_CompassScale', cvarData, CVC_Compass);
		JGPUFH_PresetCVarData.Add('jgphud_CompassPos', cvarData, CVC_Compass);
		JGPUFH_PresetCVarData.Add('jgphud_CompassPosX', cvarData, CVC_Compass);
		JGPUFH_PresetCVarData.Add('jgphud_CompassPosY', cvarData, CVC_Compass);

		JGPUFH_PresetCVarData.Add('jgphud_DrawInvBar', cvarData, CVC_InvBar|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_AlwaysShowInvBar', cvarData, CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarIconSize', cvarData, CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarPos', cvarData, CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarX', cvarData, CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarY', cvarData, CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarNumColor', cvarData, CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarAlignment', cvarData, CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarMaxFields', cvarData, CVC_InvBar);

		JGPUFH_PresetCVarData.Add('jgphud_DrawEnemyHitMarkers', cvarData, CVC_Hitmarkers|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_EnemyHitMarkersColor', cvarData, CVC_Hitmarkers);
		JGPUFH_PresetCVarData.Add('jgphud_EnemyHitMarkersSize', cvarData, CVC_Hitmarkers);
		JGPUFH_PresetCVarData.Add('jgphud_EnemyHitMarkersShape', cvarData, CVC_Hitmarkers);

		JGPUFH_PresetCVarData.Add('jgphud_DrawReticleBars', cvarData, CVC_ReticleBars|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsText', cvarData, CVC_ReticleBars);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsSize', cvarData, CVC_ReticleBars);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsHealthArmor', cvarData, CVC_ReticleBars);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsAmmo', cvarData, CVC_ReticleBars);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsEnemy', cvarData, CVC_ReticleBars);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsAlpha', cvarData, CVC_ReticleBars);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsWidth', cvarData, CVC_ReticleBars);

		JGPUFH_PresetCVarData.Add('jgphud_DrawCustomItems', cvarData, CVC_CustomItems|CVC_Visibility);
		JGPUFH_PresetCVarData.Add('jgphud_CustomItemsIconSize', cvarData, CVC_CustomItems);
		JGPUFH_PresetCVarData.Add('jgphud_CustomItemsPos', cvarData, CVC_CustomItems);
		JGPUFH_PresetCVarData.Add('jgphud_CustomItemsX', cvarData, CVC_CustomItems);
		JGPUFH_PresetCVarData.Add('jgphud_CustomItemsY', cvarData, CVC_CustomItems);

		JGPUFH_PresetCVarData.Add('jgphud_mainfont', cvarData, CVC_Fonts);
		JGPUFH_PresetCVarData.Add('jgphud_smallfont', cvarData, CVC_Fonts);
		JGPUFH_PresetCVarData.Add('jgphud_numberfont', cvarData, CVC_Fonts);
	
		JGPUFH_PresetCVarData.Add('jgphud_cleanoffsets', cvarData, CVC_Scaling);
		JGPUFH_PresetCVarData.Add('jgphud_BaseScale', cvarData, CVC_Scaling);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsScale', cvarData, CVC_Scaling|CVC_Mainbars);
		JGPUFH_PresetCVarData.Add('jgphud_MugshotScale', cvarData, CVC_Scaling|CVC_MugShot);
		JGPUFH_PresetCVarData.Add('jgphud_AmmoBlockScale', cvarData, CVC_Scaling|CVC_AmmoBlock);
		JGPUFH_PresetCVarData.Add('jgphud_AllAmmoScale', cvarData, CVC_Scaling|CVC_AllAmmo);
		JGPUFH_PresetCVarData.Add('jgphud_PowerupsScale', cvarData, CVC_Scaling|CVC_Powerups);
		JGPUFH_PresetCVarData.Add('jgphud_InvBarScale', cvarData, CVC_Scaling|CVC_InvBar);
		JGPUFH_PresetCVarData.Add('jgphud_KeysScale', cvarData, CVC_Scaling|CVC_Keys);
		JGPUFH_PresetCVarData.Add('jgphud_WeaponSlotsScale', cvarData, CVC_Scaling|CVC_WSlots);
		JGPUFH_PresetCVarData.Add('jgphud_CustomItemsScale', cvarData, CVC_Scaling|CVC_CustomItems);
		JGPUFH_PresetCVarData.Add('jgphud_ReticleBarsScale', cvarData, CVC_Scaling|CVC_ReticleBars);

		JGPUFH_PresetCVarData.Add('jgphud_MainBarsHealthThresholds', cvarData, CVC_HealthColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsHealthColors', cvarData, CVC_HealthColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsHealthStripColor', cvarData, CVC_HealthColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainbarsHealthGradient', cvarData, CVC_HealthColors);

		JGPUFH_PresetCVarData.Add('jgphud_MainBarsArmorMode', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsArmorColorIsAbsorb', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsArmorStripColor', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainbarsArmorGradient_Amount', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsArmorThresholds_Amount', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsArmorColors_Amount', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainbarsArmorGradient_Absorb', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsArmorThresholds_Absorb', cvarData, CVC_ArmorColors);
		JGPUFH_PresetCVarData.Add('jgphud_MainBarsArmorColors_Absorb', cvarData, CVC_ArmorColors);
	}
}