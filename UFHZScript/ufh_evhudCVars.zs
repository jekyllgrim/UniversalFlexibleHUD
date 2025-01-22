extend class JGPUFH_FlexibleHUD
{
	ui transient CVar c_enable;
	
	ui transient CVar c_BackColor;
	ui transient CVar c_BackAlpha;
	ui transient CVar c_BackTexture;
	ui transient CVar c_BackStyle;
	ui transient CVar c_BackTextureStretch;

	ui transient CVar c_aspectscale;
	ui transient CVar c_crosshairScale;

	ui transient CVar c_mainfont;
	ui transient CVar c_smallfont;
	ui transient CVar c_numberfont;

	ui transient CVar c_drawMainbars;
	ui transient CVar c_MainBarsPos;
	ui transient CVar c_MainBarsX;
	ui transient CVar c_MainBarsY;
	ui transient CVar c_DrawFace;

	ui transient CVar c_drawMugshot;
	ui transient CVar c_MugshotPos;
	ui transient CVar c_MugshotX;
	ui transient CVar c_MugshotY;

	ui transient CVar c_drawAmmoBlock;
	ui transient CVar c_AmmoBlockPos;
	ui transient CVar c_AmmoBlockX;
	ui transient CVar c_AmmoBlockY;
	ui transient CVar c_drawAmmoBar;
	ui transient CVar c_DrawWeapon;

	ui transient CVar c_drawAllAmmo;
	ui transient CVar c_AllAmmoShowDepleted;
	ui transient CVar c_AllAmmoPos;
	ui transient CVar c_AllAmmoX;
	ui transient CVar c_AllAmmoY;
	ui transient CVar c_AllAmmoColumns;
	ui transient CVar c_AllAmmoShowMax;
	ui transient CVar c_AllAmmoShowBar;
	ui transient CVar c_AllAmmoColorLow;
	ui transient CVar c_AllAmmoColorHigh;

	ui transient CVar c_drawInvBar;
	ui transient CVar c_AlwaysShowInvBar;
	ui transient CVar c_InvBarIconSize;
	ui transient CVar c_InvBarPos;
	ui transient CVar c_InvBarX;
	ui transient CVar c_InvBarY;
	ui transient CVar c_InvBarNumColor;
	ui transient CVar c_InvBarAlignment;
	ui transient CVar c_InvBarMaxFields;
	
	ui transient CVar c_drawDamageMarkers;

	ui transient CVar c_drawWeaponSlots;
	ui transient CVar c_WeaponSlotsSize;
	ui transient CVar c_WeaponSlotsAlign;
	ui transient CVar c_WeaponSlotsPos;
	ui transient CVar c_WeaponSlotsX;
	ui transient CVar c_WeaponSlotsY;
	ui transient CVar c_WeaponSlotsNumColor;

	ui transient CVar c_drawPowerups;
	ui transient CVar c_PowerupsAlignment;
	ui transient CVar c_PowerupsIconSize;
	ui transient CVar c_PowerupsPos;
	ui transient CVar c_PowerupsX;
	ui transient CVar c_PowerupsY;
	ui transient CVar c_PowerupsNumColor;

	ui transient CVar c_drawKeys;
	ui transient CVar c_KeysPos;
	ui transient CVar c_KeysX;
	ui transient CVar c_KeysY;

	ui transient CVar c_drawMinimap;
	ui transient CVar c_MinimapEnemyDisplay;
	ui transient CVar c_MinimapEnemyShape;
	ui transient CVar c_CircularMinimap;
	ui transient CVar c_minimapSize;
	ui transient CVar c_minimapPos;
	ui transient CVar c_minimapPosX;
	ui transient CVar c_minimapPosY;
	ui transient CVar c_minimapZoom;
	ui transient CVar c_minimapDrawUnseen;
	ui transient CVar c_minimapDrawFloorDiff;
	ui transient CVar c_minimapDrawCeilingDiff;
	ui transient CVar c_MinimapMonsterMarkerSize;
	ui transient CVar c_MinimapColorMode;
	ui transient CVar c_minimapBackColor;
	ui transient CVar c_minimapLineColor;
	ui transient CVar c_minimapIntLineColor;
	ui transient CVar c_MinimapFloorDiffLineColor;
	ui transient CVar c_MinimapCeilDiffLineColor;
	ui transient CVar c_MinimapUnseenLineColor;
	ui transient CVar c_MinimapUnseenSeparateColor;
	ui transient CVar c_minimapYouColor;
	ui transient CVar c_minimapMonsterColor;
	ui transient CVar c_minimapFriendColor;
	ui transient CVar c_MinimapBlockLineThickness;
	ui transient CVar c_MinimapNonblockLineThickness;
	ui transient CVar c_MinimapCardinalDir;
	ui transient CVar c_MinimapCardinalDirSize;
	ui transient CVar c_MinimapCardinalDirColor;
	ui transient CVar c_MinimapOpacity;
	ui transient CVar c_MapDataScale;

	ui transient CVar c_DrawKills;
	ui transient CVar c_DrawItems;
	ui transient CVar c_DrawSecrets;
	ui transient CVar c_DrawTime;

	ui transient CVar c_DrawEnemyHitMarkers;
	ui transient CVar c_EnemyHitMarkersColor;
	ui transient CVar c_EnemyHitMarkersSize;
	ui transient CVar c_EnemyHitMarkersShape;
	ui transient CVar c_DrawReticleBars;
	ui transient CVar c_ReticleBarsHealthArmor;
	ui transient CVar c_ReticleBarsAmmo;
	ui transient CVar c_ReticleBarsEnemy;
	ui transient CVar c_ReticleBarsText;
	ui transient CVar c_ReticleBarsAlpha;
	ui transient CVar c_ReticleBarsSize;
	ui transient CVar c_ReticleBarsWidth;

	ui transient CVar c_drawCustomItems;
	ui transient CVar c_CustomItemsIconSize;
	ui transient CVar c_CustomItemsPos;
	ui transient CVar c_CustomItemsX;
	ui transient CVar c_CustomItemsY;

	ui transient CVar c_scale_general;
	ui transient CVar c_scale_mainbars;
	ui transient CVar c_scale_weaponblock;

	ui transient CVar c_cleanoffsets;
	ui transient CVar c_BaseScale;
	ui transient CVar c_MainBarsScale;
	ui transient CVar c_MugshotScale;
	ui transient CVar c_AmmoBlockScale;
	ui transient CVar c_AllAmmoScale;
	ui transient CVar c_PowerupsScale;
	ui transient CVar c_InvBarScale;
	ui transient CVar c_KeysScale;
	ui transient CVar c_WeaponSlotsScale;
	ui transient CVar c_CustomItemsScale;
	ui transient CVar c_ReticleBarsScale;

	ui transient CVar c_MainBarsArmorMode;
	ui transient CVar c_MainBarsArmorColorMode;
	ui transient CVar c_MainBarsHealthColorMode;
	ui transient CVar c_MainBarsArmorColor;
	ui transient CVar c_MainBarsHealthColor;
	ui transient CVar c_MainbarsHealthRange_25;
	ui transient CVar c_MainbarsHealthRange_50;
	ui transient CVar c_MainbarsHealthRange_75;
	ui transient CVar c_MainbarsHealthRange_100;
	ui transient CVar c_MainbarsHealthRange_101;
	ui transient CVar c_MainbarsArmorRange_25;
	ui transient CVar c_MainbarsArmorRange_50;
	ui transient CVar c_MainbarsArmorRange_75;
	ui transient CVar c_MainbarsArmorRange_100;
	ui transient CVar c_MainbarsArmorRange_101;
	ui transient CVar c_MainbarsAbsorbRange_33;
	ui transient CVar c_MainbarsAbsorbRange_50;
	ui transient CVar c_MainbarsAbsorbRange_66;
	ui transient CVar c_MainbarsAbsorbRange_80;
	ui transient CVar c_MainbarsAbsorbRange_100;

	// default map color cvars (not stored in FlexiHUD settings):
	ui transient CVar c_am_colorset;
	ui transient CVar c_am_backcolor;
	ui transient CVar c_am_yourcolor;
	ui transient CVar c_am_wallcolor;
	ui transient CVar c_am_specialwallcolor;
	ui transient CVar c_am_thingcolor_monster;
	ui transient CVar c_am_thingcolor_friend;
	ui transient CVar c_am_fdwallcolor;
	ui transient CVar c_am_cdwallcolor;
	ui transient CVar c_am_notseencolor;

	ui void CacheCvars()
	{
		if (!CPlayer)
			CPlayer = players[consoleplayer];

		if (!c_enable)
			c_enable = CVar.GetCVar('jgphud_enable', CPlayer);
		if (!c_BackColor)
			c_BackColor = CVar.GetCVar('jgphud_BackColor', CPlayer);
		if (!c_BackAlpha)
			c_BackAlpha = CVar.GetCVar('jgphud_BackAlpha', CPlayer);
		if (!c_BackStyle)
			c_BackStyle = CVar.GetCVar('jgphud_BackStyle', CPlayer);
		if (!c_BackTexture)
			c_BackTexture = CVar.GetCVar('jgphud_BackTexture', CPlayer);
		if (!c_BackTextureStretch)
			c_BackTextureStretch = CVar.GetCVar('jgphud_BackTextureStretch', CPlayer);

		if (!c_aspectscale)
			c_aspectscale = CVar.GetCvar('hud_aspectscale', CPlayer);
		if (!c_crosshairScale)
			c_crosshairScale = CVar.GetCvar('CrosshairScale', CPlayer);

		if (!c_mainfont)
			c_mainfont = CVar.GetCvar('jgphud_mainfont', CPlayer);
		if (!c_smallfont)
			c_smallfont = CVar.GetCvar('jgphud_smallfont', CPlayer);
		if (!c_numberfont)
			c_numberfont = CVar.GetCvar('jgphud_numberfont', CPlayer);

		if (!c_drawMainbars)
			c_drawMainbars = CVar.GetCvar('jgphud_DrawMainbars', CPlayer);
		if (!c_MainBarsPos)
			c_MainBarsPos = CVar.GetCvar('jgphud_MainBarsPos', CPlayer);
		if (!c_MainBarsX)
			c_MainBarsX = CVar.GetCvar('jgphud_MainBarsX', CPlayer);
		if (!c_MainBarsY)
			c_MainBarsY = CVar.GetCvar('jgphud_MainBarsY', CPlayer);
		if (!c_DrawFace)
			c_DrawFace = CVar.GetCvar('jgphud_Drawface', CPlayer);

		if (!c_drawMugshot)
			c_drawMugshot = CVar.GetCvar('jgphud_DrawMugshot', CPlayer);
		if (!c_MugshotPos)
			c_MugshotPos = CVar.GetCvar('jgphud_MugshotPos', CPlayer);
		if (!c_MugshotX)
			c_MugshotX = CVar.GetCvar('jgphud_MugshotX', CPlayer);
		if (!c_MugshotY)
			c_MugshotY = CVar.GetCvar('jgphud_MugshotY', CPlayer);

		if (!c_drawAmmoBlock)
			c_drawAmmoBlock = CVar.GetCvar('jgphud_DrawAmmoBlock', CPlayer);
		if (!c_AmmoBlockPos)
			c_AmmoBlockPos = CVar.GetCvar('jgphud_AmmoBlockPos', CPlayer);
		if (!c_AmmoBlockX)
			c_AmmoBlockX = CVar.GetCvar('jgphud_AmmoBlockX', CPlayer);
		if (!c_AmmoBlockY)
			c_AmmoBlockY = CVar.GetCvar('jgphud_AmmoBlockY', CPlayer);
		if (!c_DrawAmmoBar)
			c_DrawAmmoBar = CVar.GetCvar('jgphud_DrawAmmoBar', CPlayer);
		if (!c_DrawWeapon)
			c_DrawWeapon = CVar.GetCvar('jgphud_DrawWeapon', CPlayer);

		if (!c_drawDamageMarkers)
			c_drawDamageMarkers = CVar.GetCvar('jgphud_DrawDamageMarkers', CPlayer);
		if (!c_DrawEnemyHitMarkers)
			c_DrawEnemyHitMarkers = CVar.GetCvar('jgphud_DrawEnemyHitMarkers', CPlayer);
		if (!c_EnemyHitMarkersColor)
			c_EnemyHitMarkersColor = CVar.GetCvar('jgphud_EnemyHitMarkersColor', CPlayer);
		if (!c_EnemyHitMarkersSize)
			c_EnemyHitMarkersSize = CVar.GetCvar('jgphud_EnemyHitMarkersSize', CPlayer);
		if (!c_EnemyHitMarkersShape)
			c_EnemyHitMarkersShape = CVar.GetCvar('jgphud_EnemyHitMarkersShape', CPlayer);

		if (!c_drawAmmoBar)
			c_drawAmmoBar = CVar.GetCvar('jgphud_DrawAmmoBar', CPlayer);

		if (!c_drawAllAmmo)
			c_drawAllAmmo = CVar.GetCvar('jgphud_DrawAllAmmo', CPlayer);
		if (!c_AllAmmoShowDepleted)
			c_AllAmmoShowDepleted = CVar.GetCvar('jgphud_AllAmmoShowDepleted', CPlayer);
		if (!c_AllAmmoPos)
			c_AllAmmoPos = CVar.GetCvar('jgphud_AllAmmoPos', CPlayer);
		if (!c_AllAmmoX)
			c_AllAmmoX = CVar.GetCvar('jgphud_AllAmmoX', CPlayer);
		if (!c_AllAmmoY)
			c_AllAmmoY = CVar.GetCvar('jgphud_AllAmmoY', CPlayer);
		if (!c_AllAmmoColumns)
			c_AllAmmoColumns = CVar.GetCvar('jgphud_AllAmmoColumns', CPlayer);
		if (!c_AllAmmoShowMax)
			c_AllAmmoShowMax = CVar.GetCvar('jgphud_AllAmmoShowMax', CPlayer);
		if (!c_AllAmmoShowBar)
			c_AllAmmoShowBar = CVar.GetCvar('jgphud_AllAmmoShowBar', CPlayer);
		if (!c_AllAmmoColorLow)
			c_AllAmmoColorLow = CVar.GetCvar('jgphud_AllAmmoColorLow', CPlayer);
		if (!c_AllAmmoColorHigh)
			c_AllAmmoColorHigh = CVar.GetCvar('jgphud_AllAmmoColorHigh', CPlayer);

		if (!c_drawInvBar)
			c_drawInvBar = CVar.GetCvar('jgphud_DrawInvBar', CPlayer);
		if (!c_AlwaysShowInvBar)
			c_AlwaysShowInvBar = CVar.GetCvar('jgphud_AlwaysShowInvBar', CPlayer);
		if (!c_InvBarIconSize)
			c_InvBarIconSize = CVar.GetCvar('jgphud_InvBarIconSize', CPlayer);
		if (!c_InvBarPos)
			c_InvBarPos = CVar.GetCvar('jgphud_InvBarPos', CPlayer);
		if (!c_InvBarX)
			c_InvBarX = CVar.GetCvar('jgphud_InvBarX', CPlayer);
		if (!c_InvBarY)
			c_InvBarY = CVar.GetCvar('jgphud_InvBarY', CPlayer);
		if (!c_InvBarNumColor)
			c_InvBarNumColor = CVar.GetCvar('jgphud_InvBarNumColor', CPlayer);
		if (!c_InvBarAlignment)
			c_InvBarAlignment = CVar.GetCvar('jgphud_InvBarAlignment', CPlayer);
		if (!c_InvBarMaxFields)
			c_InvBarMaxFields = CVar.GetCvar('jgphud_InvBarMaxFields', CPlayer);

		if (!c_drawWeaponSlots)
			c_drawWeaponSlots = CVar.GetCvar('jgphud_DrawWeaponSlots', CPlayer);
		if (!c_WeaponSlotsSize)
			c_WeaponSlotsSize = CVar.GetCvar('jgphud_WeaponSlotsSize', CPlayer);
		if (!c_WeaponSlotsAlign)
			c_WeaponSlotsAlign = CVar.GetCvar('jgphud_WeaponSlotsAlign', CPlayer);
		if (!c_WeaponSlotsPos)
			c_WeaponSlotsPos = CVar.GetCvar('jgphud_WeaponSlotsPos', CPlayer);
		if (!c_WeaponSlotsX)
			c_WeaponSlotsX = CVar.GetCvar('jgphud_WeaponSlotsX', CPlayer);
		if (!c_WeaponSlotsY)
			c_WeaponSlotsY = CVar.GetCvar('jgphud_WeaponSlotsY', CPlayer);
		if (!c_WeaponSlotsNumColor)
			c_WeaponSlotsNumColor = CVar.GetCvar('jgphud_WeaponSlotsNumColor', CPlayer);

		if (!c_drawPowerups)
			c_drawPowerups = CVar.GetCvar('jgphud_DrawPowerups', CPlayer);
		if (!c_PowerupsAlignment)
			c_PowerupsAlignment = CVar.GetCvar('jgphud_PowerupsAlignment', CPlayer);
		if (!c_PowerupsIconSize)
			c_PowerupsIconSize = CVar.GetCvar('jgphud_PowerupsIconSize', CPlayer);
		if (!c_PowerupsPos)
			c_PowerupsPos = CVar.GetCvar('jgphud_PowerupsPos', CPlayer);
		if (!c_PowerupsX)
			c_PowerupsX = CVar.GetCvar('jgphud_PowerupsX', CPlayer);
		if (!c_PowerupsY)
			c_PowerupsY = CVar.GetCvar('jgphud_PowerupsY', CPlayer);
		if (!c_PowerupsNumColor)
			c_PowerupsNumColor = CVar.GetCvar('jgphud_PowerupsNumColor', CPlayer);

		if (!c_drawKeys)
			c_drawKeys = CVar.GetCvar('jgphud_DrawKeys', CPlayer);
		if (!c_KeysPos)
			c_KeysPos = CVar.GetCvar('jgphud_KeysPos', CPlayer);
		if (!c_KeysX)
			c_KeysX = CVar.GetCvar('jgphud_KeysX', CPlayer);
		if (!c_KeysY)
			c_KeysY = CVar.GetCvar('jgphud_KeysY', CPlayer);

		if (!c_drawMinimap)
			c_drawMinimap = CVar.GetCvar('jgphud_DrawMinimap', CPlayer);
		if (!c_MinimapEnemyDisplay)
			c_MinimapEnemyDisplay = CVar.GetCvar('jgphud_MinimapEnemyDisplay', CPlayer);
		if (!c_MinimapEnemyShape)
			c_MinimapEnemyShape = CVar.GetCvar('jgphud_MinimapEnemyShape', CPlayer);
		if (!c_CircularMinimap)
			c_CircularMinimap = CVar.GetCvar('jgphud_CircularMinimap', CPlayer);
		if (!c_minimapSize)
			c_minimapSize = CVar.GetCvar('jgphud_MinimapSize', CPlayer);
		if (!c_minimapPos)
			c_minimapPos = CVar.GetCvar('jgphud_MinimapPos', CPlayer);
		if (!c_minimapPosX)
			c_minimapPosX = CVar.GetCvar('jgphud_MinimapPosX', CPlayer);
		if (!c_minimapPosY)
			c_minimapPosY = CVar.GetCvar('jgphud_MinimapPosY', CPlayer);
		if (!c_minimapZoom)
			c_minimapZoom = CVar.GetCvar('jgphud_MinimapZoom', CPlayer);
		if (!c_minimapDrawUnseen)
			c_minimapDrawUnseen = CVar.GetCvar('jgphud_MinimapDrawUnseen', CPlayer);
		if (!c_minimapDrawFloorDiff)
			c_minimapDrawFloorDiff = CVar.GetCvar('jgphud_MinimapDrawFloorDiff', CPlayer);
		if (!c_minimapDrawCeilingDiff)
			c_minimapDrawCeilingDiff = CVar.GetCvar('jgphud_MinimapDrawCeilingDiff', CPlayer);
		if (!c_minimapMonsterMarkerSize)
			c_minimapMonsterMarkerSize = CVar.GetCvar('jgphud_minimapMonsterMarkerSize', CPlayer);
		if (!c_MinimapColorMode)
			c_MinimapColorMode = CVar.GetCvar('jgphud_MinimapColorMode', CPlayer);
		if (!c_minimapBackColor)
			c_minimapBackColor = CVar.GetCvar('jgphud_MinimapBackColor', CPlayer);
		if (!c_minimapLineColor)
			c_minimapLineColor = CVar.GetCvar('jgphud_MinimapLineColor', CPlayer);
		if (!c_minimapIntLineColor)
			c_minimapIntLineColor = CVar.GetCvar('jgphud_MinimapIntLineColor', CPlayer);
		if (!c_MinimapFloorDiffLineColor)
			c_MinimapFloorDiffLineColor = CVar.GetCvar('jgphud_MinimapFloorDiffLineColor', CPlayer);
		if (!c_MinimapCeilDiffLineColor)
			c_MinimapCeilDiffLineColor = CVar.GetCvar('jgphud_MinimapCeilDiffLineColor', CPlayer);
		if (!c_MinimapUnseenLineColor)
			c_MinimapUnseenLineColor = CVar.GetCvar('jgphud_MinimapUnseenLineColor', CPlayer);
		if (!c_MinimapUnseenSeparateColor)
			c_MinimapUnseenSeparateColor = CVar.GetCvar('jgphud_MinimapUnseenSeparateColor', CPlayer);
		if (!c_minimapYouColor)
			c_minimapYouColor = CVar.GetCvar('jgphud_MinimapYouColor', CPlayer);
		if (!c_minimapMonsterColor)
			c_minimapMonsterColor = CVar.GetCvar('jgphud_MinimapMonsterColor', CPlayer);
		if (!c_minimapFriendColor)
			c_minimapFriendColor = CVar.GetCvar('jgphud_MinimapFriendColor', CPlayer);
		if (!c_MinimapBlockLineThickness)
			c_MinimapBlockLineThickness = CVar.GetCvar('jgphud_MinimapBlockLineThickness', CPlayer);
		if (!c_MinimapNonblockLineThickness)
			c_MinimapNonblockLineThickness = CVar.GetCvar('jgphud_MinimapNonblockLineThickness', CPlayer);
		if (!c_MinimapCardinalDir)
			c_MinimapCardinalDir = CVar.GetCvar('jgphud_MinimapCardinalDir', CPlayer);
		if (!c_MinimapCardinalDirSize)
			c_MinimapCardinalDirSize = CVar.GetCvar('jgphud_MinimapCardinalDirSize', CPlayer);
		if (!c_MinimapCardinalDirColor)
			c_MinimapCardinalDirColor = CVar.GetCvar('jgphud_MinimapCardinalDirColor', CPlayer);
		if (!c_MinimapOpacity)
			c_MinimapOpacity = CVar.GetCvar('jgphud_MinimapOpacity', CPlayer);
			
		if (!c_MapDataScale)
			c_MapDataScale = CVar.GetCvar('jgphud_MapDataScale', CPlayer);
		if (!c_DrawKills)
			c_DrawKills = CVar.GetCvar('jgphud_DrawKills', CPlayer);
		if (!c_DrawItems)
			c_DrawItems = CVar.GetCvar('jgphud_DrawItems', CPlayer);
		if (!c_DrawSecrets)
			c_DrawSecrets = CVar.GetCvar('jgphud_DrawSecrets', CPlayer);
		if (!c_DrawTime)
			c_DrawTime = CVar.GetCvar('jgphud_DrawTime', CPlayer);

		if (!c_DrawReticleBars)
			c_DrawReticleBars = CVar.GetCvar('jgphud_DrawReticleBars', CPlayer);
		if (!c_ReticleBarsText)
			c_ReticleBarsText = CVar.GetCvar('jgphud_ReticleBarsText', CPlayer);
		if (!c_ReticleBarsAlpha)
			c_ReticleBarsAlpha = CVar.GetCvar('jgphud_ReticleBarsAlpha', CPlayer);
		if (!c_ReticleBarsSize)
			c_ReticleBarsSize = CVar.GetCvar('jgphud_ReticleBarsSize', CPlayer);
		if (!c_ReticleBarsHealthArmor)
			c_ReticleBarsHealthArmor = CVar.GetCvar('jgphud_ReticleBarsHealthArmor', CPlayer);
		if (!c_ReticleBarsAmmo)
			c_ReticleBarsAmmo = CVar.GetCvar('jgphud_ReticleBarsAmmo', CPlayer);
		if (!c_ReticleBarsEnemy)
			c_ReticleBarsEnemy = CVar.GetCvar('jgphud_ReticleBarsEnemy', CPlayer);
		if (!c_ReticleBarsWidth)
			c_ReticleBarsWidth = CVar.GetCvar('jgphud_ReticleBarsWidth', CPlayer);
			
		if (!c_drawCustomItems)
			c_drawCustomItems = CVar.GetCvar('jgphud_DrawCustomItems', CPlayer);
		if (!c_CustomItemsIconSize)
			c_CustomItemsIconSize = CVar.GetCvar('jgphud_CustomItemsIconSize', CPlayer);
		if (!c_CustomItemsPos)
			c_CustomItemsPos = CVar.GetCvar('jgphud_CustomItemsPos', CPlayer);
		if (!c_CustomItemsX)
			c_CustomItemsX = CVar.GetCvar('jgphud_CustomItemsX', CPlayer);
		if (!c_CustomItemsY)
			c_CustomItemsY = CVar.GetCvar('jgphud_CustomItemsY', CPlayer);

		if (!c_cleanoffsets)
			c_cleanoffsets = CVar.GetCvar('jgphud_cleanoffsets', CPlayer);
		if (!c_BaseScale)
			c_BaseScale = CVar.GetCVar('jgphud_BaseScale', CPlayer);
		if (!c_MainBarsScale)
			c_MainBarsScale = CVar.GetCVar('jgphud_MainBarsScale', CPlayer);
		if (!c_MugshotScale)
			c_MugshotScale = CVar.GetCVar('jgphud_MugshotScale', CPlayer);
		if (!c_AmmoBlockScale)
			c_AmmoBlockScale = CVar.GetCVar('jgphud_AmmoBlockScale', CPlayer);
		if (!c_AllAmmoScale)
			c_AllAmmoScale = CVar.GetCVar('jgphud_AllAmmoScale', CPlayer);
		if (!c_PowerupsScale)
			c_PowerupsScale = CVar.GetCVar('jgphud_PowerupsScale', CPlayer);
		if (!c_InvBarScale)
			c_InvBarScale = CVar.GetCVar('jgphud_InvBarScale', CPlayer);
		if (!c_KeysScale)
			c_KeysScale = CVar.GetCVar('jgphud_KeysScale', CPlayer);
		if (!c_WeaponSlotsScale)
			c_WeaponSlotsScale = CVar.GetCVar('jgphud_WeaponSlotsScale', CPlayer);
		if (!c_CustomItemsScale)
			c_CustomItemsScale = CVar.GetCVar('jgphud_CustomItemsScale', CPlayer);
		if (!c_ReticleBarsScale)
			c_ReticleBarsScale = CVar.GetCVar('jgphud_ReticleBarsScale', CPlayer);

		if (!c_MainBarsArmorMode)
			c_MainBarsArmorMode = CVar.GetCvar('jgphud_MainBarsArmorMode', CPlayer);
		if (!c_MainBarsArmorColorMode)
			c_MainBarsArmorColorMode = CVar.GetCvar('jgphud_MainBarsArmorColorMode', CPlayer);
		if (!c_MainBarsHealthColorMode)
			c_MainBarsHealthColorMode = CVar.GetCvar('jgphud_MainBarsHealthColorMode', CPlayer);
		if (!c_MainBarsArmorColor)
			c_MainBarsArmorColor = CVar.GetCvar('jgphud_MainBarsArmorColor', CPlayer);
		if (!c_MainBarsHealthColor)
			c_MainBarsHealthColor = CVar.GetCvar('jgphud_MainBarsHealthColor', CPlayer);

		if (!c_MainbarsHealthRange_25)
			c_MainbarsHealthRange_25 = CVar.GetCvar('jgphud_MainbarsHealthRange_25', CPlayer);
		if (!c_MainbarsHealthRange_50)
			c_MainbarsHealthRange_50 = CVar.GetCvar('jgphud_MainbarsHealthRange_50', CPlayer);
		if (!c_MainbarsHealthRange_75)
			c_MainbarsHealthRange_75 = CVar.GetCvar('jgphud_MainbarsHealthRange_75', CPlayer);
		if (!c_MainbarsHealthRange_100)
			c_MainbarsHealthRange_100 = CVar.GetCvar('jgphud_MainbarsHealthRange_100', CPlayer);
		if (!c_MainbarsHealthRange_101)
			c_MainbarsHealthRange_101 = CVar.GetCvar('jgphud_MainbarsHealthRange_101', CPlayer);

		if (!c_MainbarsArmorRange_25)
			c_MainbarsArmorRange_25 = CVar.GetCvar('jgphud_MainbarsArmorRange_25', CPlayer);
		if (!c_MainbarsArmorRange_50)
			c_MainbarsArmorRange_50 = CVar.GetCvar('jgphud_MainbarsArmorRange_50', CPlayer);
		if (!c_MainbarsArmorRange_75)
			c_MainbarsArmorRange_75 = CVar.GetCvar('jgphud_MainbarsArmorRange_75', CPlayer);
		if (!c_MainbarsArmorRange_100)
			c_MainbarsArmorRange_100 = CVar.GetCvar('jgphud_MainbarsArmorRange_100', CPlayer);
		if (!c_MainbarsArmorRange_101)
			c_MainbarsArmorRange_101 = CVar.GetCvar('jgphud_MainbarsArmorRange_101', CPlayer);

		if (!c_MainbarsAbsorbRange_33)
			c_MainbarsAbsorbRange_33 = CVar.GetCvar('jgphud_MainbarsAbsorbRange_33', CPlayer);
		if (!c_MainbarsAbsorbRange_50)
			c_MainbarsAbsorbRange_50 = CVar.GetCvar('jgphud_MainbarsAbsorbRange_50', CPlayer);
		if (!c_MainbarsAbsorbRange_66)
			c_MainbarsAbsorbRange_66 = CVar.GetCvar('jgphud_MainbarsAbsorbRange_66', CPlayer);
		if (!c_MainbarsAbsorbRange_80)
			c_MainbarsAbsorbRange_80 = CVar.GetCvar('jgphud_MainbarsAbsorbRange_80', CPlayer);
		if (!c_MainbarsAbsorbRange_100)
			c_MainbarsAbsorbRange_100 = CVar.GetCvar('jgphud_MainbarsAbsorbRange_100', CPlayer);
		
		// default map color cvars (not stored in FlexiHUD settings):
		// which color set GZDoom uses (0 - custom, 1 - Doom, 2 - Strife, 3 - Raven):
		if (!c_am_colorset)
			c_am_colorset = CVar.GetCvar('am_colorset', CPlayer);
		// background:
		if (!c_am_backcolor)
			c_am_backcolor = CVar.GetCvar('am_backcolor', CPlayer);
		// you:
		if (!c_am_yourcolor)
			c_am_yourcolor = CVar.GetCvar('am_yourcolor', CPlayer);
		// one-sided walls (used for all walls on minimap):
		if (!c_am_wallcolor)
			c_am_wallcolor = CVar.GetCvar('am_wallcolor', CPlayer);
		// interactive walls
		if (!c_am_specialwallcolor)
			c_am_specialwallcolor = CVar.GetCvar('am_specialwallcolor', CPlayer);
		if (!c_am_thingcolor_monster)
			c_am_thingcolor_monster = CVar.GetCvar('am_thingcolor_monster', CPlayer);
		if (!c_am_thingcolor_friend)
			c_am_thingcolor_friend = CVar.GetCvar('am_thingcolor_friend', CPlayer);
		if (!c_am_fdwallcolor)
			c_am_fdwallcolor = CVar.GetCvar('am_fdwallcolor', CPlayer);
		if (!c_am_cdwallcolor)
			c_am_cdwallcolor = CVar.GetCvar('am_cdwallcolor', CPlayer);
		if (!c_am_notseencolor)
			c_am_notseencolor = CVar.GetCvar('am_notseencolor', CPlayer);
	}
}