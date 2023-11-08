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
		for (int i = 0; i < JGPHUD_AllCvars.Size(); i++)
		{
			if (!JGPHUD_AllCvars[i])
				continue;
			CVar cmd = CVar.FindCVar(JGPHUD_AllCvars[i]);
			if (cmd)
			{
				cmd.ResetToDefault();
			}
		}
		return true;
	}

	static const name JGPHUD_AllCvars[] =
	{
		'jgphud_debug',
		'jgphud_BackColor',
		'jgphud_BackStyle',
		'jgphud_BackAlpha',
		'jgphud_BackTexture',

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
		'jgphud_MinimapZoom',
		'jgphud_MinimapDrawUnseen',
		'jpghud_MinimapBackColor',
		'jgphud_MinimapLineColor',
		'jgphud_MinimapIntLineColor',
		'jgphud_MinimapYouColor',
		'jgphud_MinimapMonsterColor',
		'jgphud_MinimapFriendColor',

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

		'jgphud_DrawEnemyHitMarkers',
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
		'jgphud_CustomItemsY'
	};
}
