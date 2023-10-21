class JGPUFH_FlexibleHUD : BaseStatusBar
{
	const ASPECTSCALE = 1.2;
	const CIRCLEANGLES = 360.0;

	//See GetBaseplateColor():
	CVar c_BackColor;
	CVar c_BackAlpha;

	CVar c_aspectscale;
	CVar c_crosshairScale;

	CVar c_mainfont;
	CVar c_smallfont;
	CVar c_numberfont;

	CVar c_drawMainbars;
	CVar c_MainBarsPos;
	CVar c_MainBarsX;
	CVar c_MainBarsY;
	CVar c_DrawFace;

	CVar c_drawAmmoBlock;
	CVar c_AmmoBlockPos;
	CVar c_AmmoBlockX;
	CVar c_AmmoBlockY;
	CVar c_drawAmmoBar;
	CVar c_DrawWeapon;

	CVar c_drawAllAmmo;
	CVar c_AllAmmoPos;
	CVar c_AllAmmoX;
	CVar c_AllAmmoY;

	CVar c_drawInvBar;
	CVar c_AlwaysShowInvBar;
	CVar c_InvBarIconSize;
	CVar c_InvBarPos;
	CVar c_InvBarX;
	CVar c_InvBarY;
	
	CVar c_drawDamageMarkers;
	CVar c_DamageMarkersAlpha;
	CVar c_DamageMarkersFadeTime;

	CVar c_drawWeaponSlots;
	CVar c_WeaponSlotsAlign;
	CVar c_WeaponSlotsPos;
	CVar c_WeaponSlotsX;
	CVar c_WeaponSlotsY;

	CVar c_drawPowerups;
	CVar c_PowerupsPos;
	CVar c_PowerupsX;
	CVar c_PowerupsY;

	CVar c_drawKeys;
	CVar c_KeysPos;
	CVar c_KeysX;
	CVar c_KeysY;

	CVar c_drawMinimap;
	CVar c_CircularMinimap;
	CVar c_minimapSize;
	CVar c_minimapPos;
	CVar c_minimapPosX;
	CVar c_minimapPosY;
	CVar c_minimapZoom;

	CVar c_DrawKills;
	CVar c_DrawItems;
	CVar c_DrawSecrets;
	CVar c_DrawTime;

	CVar c_DrawEnemyHitMarkers;
	CVar c_DrawReticleBars;
	CVar c_ReticleBarsHealthArmor;
	CVar c_ReticleBarsAmmo;
	CVar c_ReticleBarsEnemy;
	CVar c_ReticleBarsText;
	CVar c_ReticleBarsAlpha;
	CVar c_ReticleBarsSize;
	CVar c_ReticleBarsWidth;

	HUDFont mainHUDFont;
	HUDFont smallHUDFont;
	HUDFont numHUDFont;

	JGPUFH_HudDataHandler handler;
	JGPHUD_LookTargetController lookTC;

	// see SetScreenFlags():
	static const int ScreenFlags[] =
	{
		DI_SCREEN_LEFT_TOP,
		DI_SCREEN_CENTER_TOP,
		DI_SCREEN_RIGHT_TOP,

		DI_SCREEN_LEFT_CENTER,
		DI_SCREEN_CENTER,
		DI_SCREEN_RIGHT_CENTER,

		DI_SCREEN_LEFT_BOTTOM,
		DI_SCREEN_CENTER_BOTTOM,
		DI_SCREEN_RIGHT_BOTTOM
	};

	// Health/armor bars CVAR values:
	enum EDrawBars
	{
		DB_NONE,
		DB_DRAWNUMBERS,
		DB_DRAWBARS,
	}
	double armAmount;
	double armMaxamount;
	color armorColor;
	
	// Hexen armor data:
	const WEAKEST_HEXEN_ARMOR_PIECE = 3;
	TextureID hexenArmorIcons[WEAKEST_HEXEN_ARMOR_PIECE+1];
	bool hexenArmorSetupDone;

	// Damage markers:
	Shape2D dmgMarker;
	Shape2DTransform dmgMarkerTransf;
	array <JGPUFH_DamageMarkerData> dmgMrkData;
	Actor prevAttacker;

	// Hit (reticle) markers:
	Shape2D reticleHitMarker;
	double reticleMarkerAlpha;
	Shape2DTransform reticleMarkerTransform;
	
	// Weapon slots
	const MAXWEAPONSLOTS = 10;
	const SLOTSDISPLAYDELAY = TICRATE * 2;
	array <JGPUFH_WeaponSlotData> weaponSlotData;
	int slotsDisplayTime;
	Weapon prevReadyWeapon;
	enum EWeapSlotsAlign
	{
		WA_HORIZONTAL,
		WA_VERTICAL,
		WA_VERTICALINV,
	}

	// Minimap
	const MAPSCALEFACTOR = 8.;
	Shape2D minimapShape_Square;
	Shape2D minimapShape_Circle;
	Shape2D minimapShape_Arrow;
	Shape2DTransform minimapTransform;

	// See DrawInventoryBar():
	const ITEMBARICONSIZE = 28;
	Inventory prevInvSel;
	double invbarCycleOfs;

	// See DrawReticleBars():
	Shape2D roundBars;
	Shape2D roundBarsAngMask;
	Shape2D roundBarsInnerMask;
	Shape2D roundBarsGenMask;
	Shape2DTransform roundBarsTransform;
	Shape2DTransform roundBarsGenMaskTransfInner;
	Shape2DTransform roundBarsGenMaskTransfOuter;
	const MARKERSDELAY = TICRATE*2;
	double prevArmAmount;
	double prevArmMaxAmount;
	int prevHealth;
	int prevMaxHealth;
	int prevAmmo1Amount;
	int prevAmmo1MaxAmount;
	int prevAmmo2Amount;
	int prevAmmo2MaxAmount;
	int reticleMarkersDelay[4];
	const BARCOVERANGLE = 80.0;
	enum EReticleBarTypes
	{
		RB_HEALTH,
		RB_ARMOR,
		RB_AMMO1,
		RB_AMMO2,
	}
	enum EReticleBarPos
	{
		RB_NONE,
		RB_LEFT,
		RB_TOP,
		RB_RIGHT,
		RB_BOTTOM,
		RB_DONTDRAW = 1000,
	}

	// CVar values for options that have
	// "no/autohide/always" display modes:
	enum EDisplayModes
	{
		DM_NONE,
		DM_AUTOHIDE,
		DM_ALWAYS,
	}

	double LinearMap(double val, double source_min, double source_max, double out_min, double out_max, bool clampIt = false) 
	{
		double d = (val - source_min) * (out_max - out_min) / (source_max - source_min) + out_min;
		if (clampit) 
		{
			double truemax = out_max > out_min ? out_max : out_min;
			double truemin = out_max > out_min ? out_min : out_max;
			d = Clamp(d, truemin, truemax);
		}
		return d;
	}

	override void Init()
	{
		super.Init();
		Font fnt = "Confont";
		mainHUDFont = HUDFont.Create(fnt);
		smallHUDFont = HUDFont.Create(newConsoleFont);
		fnt = "IndexFont";
		numHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true);
	}

	override void Tick()
	{
		super.Tick();
		UpdateDamageMarkers();
		UpdateReticleHitMarker();
		UpdateWeaponSlots();
		UpdateInventoryBar();
		UpdateReticleBars();
	}

	override void Draw(int state, double ticFrac)
	{
		// Cache CVars before anything else
		// and unconditionally:
		CacheCvars();
		super.Draw(state, ticFrac);

		if (state == HUD_None || state == HUD_AltHud)
			return;
		
		BeginHUD();
		DrawHealthArmor();
		DrawWeaponBlock();
		DrawAllAmmo();
		DrawWeaponSlots();
		DrawMinimap();
		DrawPowerups();
		DrawKeys();
		DrawInventoryBar();
		DrawDamageMarkers();
		DrawReticleHitMarker();
		DrawReticleBars();
	}

	void CacheCvars()
	{
		if (!handler)
			handler = JGPUFH_HudDataHandler(EventHandler.Find("JGPUFH_HudDataHandler"));

		if (!c_BackColor)
			c_BackColor = CVar.GetCVar('jgphud_BackColor', CPlayer);
		if (!c_BackAlpha)
			c_BackAlpha = CVar.GetCVar('jgphud_BackAlpha', CPlayer);

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
		if (!c_DamageMarkersAlpha)
			c_DamageMarkersAlpha = CVar.GetCvar('jgphud_DamageMarkersAlpha', CPlayer);
		if (!c_DamageMarkersFadeTime)
			c_DamageMarkersFadeTime = CVar.GetCvar('jgphud_DamageMarkersFadeTime', CPlayer);
		if (!c_DrawEnemyHitMarkers)
			c_DrawEnemyHitMarkers = CVar.GetCvar('jgphud_DrawEnemyHitMarkers', CPlayer);

		if (!c_drawAmmoBar)
			c_drawAmmoBar = CVar.GetCvar('jgphud_DrawAmmoBar', CPlayer);

		if (!c_drawAllAmmo)
			c_drawAllAmmo = CVar.GetCvar('jgphud_DrawAllAmmo', CPlayer);
		if (!c_AllAmmoPos)
			c_AllAmmoPos = CVar.GetCvar('jgphud_AllAmmoPos', CPlayer);
		if (!c_AllAmmoX)
			c_AllAmmoX = CVar.GetCvar('jgphud_AllAmmoX', CPlayer);
		if (!c_AllAmmoY)
			c_AllAmmoY = CVar.GetCvar('jgphud_AllAmmoY', CPlayer);

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

		if (!c_drawWeaponSlots)
			c_drawWeaponSlots = CVar.GetCvar('jgphud_DrawWeaponSlots', CPlayer);
		if (!c_WeaponSlotsAlign)
			c_WeaponSlotsAlign = CVar.GetCvar('jgphud_WeaponSlotsAlign', CPlayer);
		if (!c_WeaponSlotsPos)
			c_WeaponSlotsPos = CVar.GetCvar('jgphud_WeaponSlotsPos', CPlayer);
		if (!c_WeaponSlotsX)
			c_WeaponSlotsX = CVar.GetCvar('jgphud_WeaponSlotsX', CPlayer);
		if (!c_WeaponSlotsY)
			c_WeaponSlotsY = CVar.GetCvar('jgphud_WeaponSlotsY', CPlayer);

		if (!c_drawPowerups)
			c_drawPowerups = CVar.GetCvar('jgphud_DrawPowerups', CPlayer);
		if (!c_PowerupsPos)
			c_PowerupsPos = CVar.GetCvar('jgphud_PowerupsPos', CPlayer);
		if (!c_PowerupsX)
			c_PowerupsX = CVar.GetCvar('jgphud_PowerupsX', CPlayer);
		if (!c_PowerupsY)
			c_PowerupsY = CVar.GetCvar('jgphud_PowerupsY', CPlayer);

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
	}

	// Adjusts position of the element so that it never ends up
	// outside the screen. It also flips X and Y offset values
	// if the edge is at the bottom/right, so that positive
	// values are always aimed inward, and negative values cannot
	// take the element outside the screen.
	// If 'real' is true, returns real screen coordinates multiplied
	// by hudscale, rather than StatusBar coordinates.
	vector2 AdjustElementPos(vector2 pos, int flags, vector2 size, vector2 ofs = (0,0), bool real = false)
	{
		vector2 screenSize = (0,0);
		vector2 hudscale = GetHudScale();
		if (real)
		{
			screenSize = (Screen.GetWidth(), Screen.GetHeight());
			// Don't forget to get rid of the aspect correction if 
			// the hud_aspectscale CVAR is in use, because the
			// element's position must follow the angles properly
			// (mostly used by the automap):
			double aspect = c_aspectscale.GetBool() ? ASPECTSCALE : 1;
			hudscale.y /= aspect;
			pos.x *= hudscale.x;
			pos.y *= hudscale.y;
			size.x *= hudscale.x;
			size.y *= hudscale.y;
		}

		// DI_SCREEN flags are weird and don't really adhere to the norms
		// of what a bitfield should be. For instance, the TOP and LEFT
		// flags checks will always return true unless other flags are
		// explicitly excluded from the check. Hence, we have to do some
		// caching first:
		bool hCenter = ((flags & DI_SCREEN_HCENTER) == DI_SCREEN_HCENTER);
		bool vCenter = ((flags & DI_SCREEN_VCENTER) == DI_SCREEN_VCENTER);
		if (hCenter)
		{
			pos.x += -size.x*0.5 + screenSize.x * 0.5;
		}
		if (vCenter)
		{
			pos.y += -size.y*0.5 + screenSize.y * 0.5;
		}

		// Do the rest only if it's not screen center:
		if (!(hCenter && vCenter))
		{
			if ((flags & DI_SCREEN_BOTTOM) == DI_SCREEN_BOTTOM)
			{
				pos.y += -size.y + screenSize.y;
				if (ofs.y > 0)
					ofs.y = -abs(ofs.y);
				else
					ofs.y = 0;
			}
			// This has to explicitly exclude all other flags:
			else if ((flags & DI_SCREEN_TOP) == DI_SCREEN_TOP && !vCenter)
			{
				if (ofs.y < 0)
					ofs.y = 0;
			}

			if ((flags & DI_SCREEN_RIGHT) == DI_SCREEN_RIGHT)
			{
				pos.x += -size.x + screenSize.x;
				if (ofs.x > 0)
					ofs.x = -abs(ofs.x);
				else
					ofs.x = 0;
			}
			// This has to explicitly exclude all other flags:
			else if ((flags & DI_SCREEN_LEFT) == DI_SCREEN_LEFT && !hCenter)
			{
				if (ofs.x < 0)
					ofs.x = 0;
			}
		}
		if (real)
		{
			ofs.x *= hudscale.x;
			ofs.y *= hudscale.y;
		}
		pos += ofs;
		return pos;
	}

	// A CVar value should be passed here to return appropriate flags:
	int SetScreenFlags(int val)
	{
		val = Clamp(val, 0, ScreenFlags.Size() - 1);
		return ScreenFlags[val];
	}

	color GetBaseplateColor()
	{
		int a = 255 * Clamp(c_BackAlpha.GetFloat(), 0., 1.);
		color col = c_BackColor.GetInt();

		return color(a, col.r, col.g, col.b);
	}

	// Draws a bar using Fill()
	// If segments is above 0, will use multiple fills to create a segmented bar
	void DrawFlatColorBar(vector2 pos, double curValue, double maxValue, color barColor, string leftText = "", string rightText = "", int valueColor = -1, double barwidth = 64, double barheight = 8, double indent = 0.6, color backColor = color(255, 0, 0, 0), double sparsity = 1, uint segments = 0, int flags = 0)
	{
		vector2 barpos = pos;
		// This flag centers the bar vertically. I didn't add
		// horizontal centering because it felt useless, since
		// all bars in the HUD go from left to right:
		if (flags & DI_ITEM_CENTER)
		{
			barpos.y -= barheight*0.5;
		}

		if (leftText)
		{
			DrawString(mainHUDFont, leftText, barpos, flags|DI_TEXT_ALIGN_RIGHT);
		}

		// Background color (fills whole width):
		Fill(backColor, barpos.x, barpos.y, barwidth, barheight, flags);
		// The bar itself is indented against the background:
		double innerBarWidth = barwidth - (indent * 2);
		double innerBarHeight = barheight - (indent * 2);
		vector2 innerBarPos = (barpos.x + indent, barpos.y + indent);
		// Get the current bar size according to the provided values:
		double curInnerBarWidth = LinearMap(curValue, 0, maxValue, 0, innerBarWidth, true);
		
		// Draw segmented bar:
		if (sparsity > 0 && segments > 0)
		{
			// Sparsity can't be too small, or it'll corrupt the
			// rendering of the bar making segments invisible:
			sparsity = Clamp(sparsity, 0, innerBarWidth / (segments * 4));
			// If sparsity is too small, we'll alternate
			// segment color every other segment instead:
			bool sparsityTooSmall = sparsity <= 0.5;
			bool altColor = true;
			int r,g,b;
			if (sparsityTooSmall)
			{
				sparsity = 0;
				r = barcolor.r * 0.75;
				g = barcolor.g * 0.75;
				b = barcolor.b * 0.75;
			}
			// Calculate width of a single segment based
			// on bar width and sparsity:
			double singleSegWidth = (innerBarWidth - (segments - 1) * sparsity) / segments;
			vector2 segPos = innerBarPos;
			// Draw the segments:
			while (segPos.x < curInnerBarWidth + innerBarPos.x)
			{
				color col = barcolor;
				if (sparsityTooSmall)
				{
					if (altColor)
						col = color(barcolor.a, r,g,b);
					altColor = !altColor;
				}				
				double segW = min(singleSegWidth, curInnerBarWidth - segPos.x + innerBarPos.x);
				Fill(col, segPos.x, segPos.y, segW, innerBarHeight, flags);
				segPos.x += singleSegWidth + sparsity;
			}
		}
		else
		{
			Fill(barColor, innerBarPos.x, innerBarPos.y, curInnerBarWidth, innerBarHeight, flags);
		}

		// If value color is provided, draw the current value
		// in the middle of the bar:
		if (valueColor != -1)
		{
			double fy = numHUDFont.mFont.GetHeight();
			fy = Clamp(fy, 2, barheight);
			DrawString(numHUDFont, ""..int(curvalue), barpos + (barwidth * 0.5, barheight * 0.5 - fy * 0.5), flags|DI_TEXT_ALIGN_CENTER, translation: valueColor);
		}
		
		if (rightText)
		{
			DrawString(mainHUDFont, ""..rightText, barpos + (barwidth + 1, 0), flags|DI_TEXT_ALIGN_LEFT);
		}
	}

	int, int, int, int GetArmorColor(double savePercent)
	{
		int cRed, cGreen, cBlue, cFntCol;
		if (savePercent <= 1.0)
			savePercent *= 100;
		if (savePercent >= 50)
		{
			cBlue = 255;
			cFntCol = Font.CR_Blue;
			if (savePercent >= 80)
			{
				cGreen = 255;
				cFntCol = Font.CR_Cyan;
			}
		}
		else 
		{
			cFntCol = Font.CR_Brown;
			cRed = 72;
			if (savePercent >= 33)
			{
				cGreen = 160;
				cFntCol = Font.CR_Green;
			}
		}
		return cRed, cGreen, cBlue, cFntCol;
	}

	int GetPercentageFontColor(int amount, int maxamount)
	{
		if (amount >= maxamount * 0.75)
			return Font.CR_Green;
		if (amount >= maxamount * 0.5)
			return Font.CR_Yellow;
		if (amount >= maxamount * 0.25)
			return Font.CR_Orange;
		return Font.CR_Red;
	}

	// Returns color for a percentage value normalized
	// to the 0.0-1.0 range:
	int, int, int GetPercentageColor(double amount)
	{
		// Over 100%: cyan
		if (amount > 1)
			return 0, 255, 255;	
		// Over 75%: green
		if (amount >= 0.75)
			return 0, 255, 0;	
		// Over 50%: yellow
		if (amount >= 0.5)
			return 255, 255, 0;
		// Over 25: orange:
		if (amount >= 0.25)
			return 255, 128, 0;
		// Otherwise: red
		return 255, 0, 0;
	}

	// Cache existing icons for Hexen armor classes
	// On the off chance somebody is crazy enough to
	// create their own Hexen armor pickups...
	// Hexen armor is split into four classes, 0 being the strongest,
	// and 4 being the weakest  Classses 0-3 are pickups and have icons;
	// while 4 is your natural ammo and you always have it.
	// Since class 4 is not a pickup, we're not going to try and find
	// the icon for it.
	void SetupHexenArmorIcons()
	{
		if (hexenArmorSetupDone)
			return;

		for (int i = 0; i < AllActorClasses.Size(); i++)
		{
			if (!AllActorClasses[i])
				continue;
			
			let hexArm = (class<HexenArmor>)(AllActorClasses[i]);
			// don't cache the base HexenArmor class itself:
			if (hexArm && hexArm != 'HexenArmor')
			{
				let def = GetDefaultByType((class<HexenArmor>)(hexArm));
				if (!def.spawnState)
					continue;
				let icon = def.SpawnState.GetSpriteTexture(0);
				if (!icon.IsValid())
					continue;
				// The health field in Hexen armor pickups is used to
				// determine the class (from 0 to 3):
				int armorClass = Clamp(def.health, 0, WEAKEST_HEXEN_ARMOR_PIECE);
				hexenArmorIcons[armorClass] = icon;
			}
		}
		// If all icons have been cached, setup is done:
		hexenArmorSetupDone = true;
		for (int i = 0; i < hexenArmorIcons.Size(); i++)
		{
			TextureID check = hexenArmorIcons[i];
			if (!check.IsValid())
			{
				hexenArmorSetupDone = false;
				break;
			}
		}
	}

	void DrawHealthArmor(double height = 28, double width = 120)
	{
		int drawThis = c_drawMainbars.GetInt();
		if (drawThis <= DB_NONE)
			return;

		int flags = SetScreenFlags(c_MainBarsPos.GetInt());
		int indent = 1;
		int faceSize = height;
		int mainBlockWidth = width;
		bool drawbars = drawThis >= DB_DRAWBARS;
		// Draw the mugshot only if the CVAR allows it
		// and a mugshot is actually defined, or the
		// default STF graphics for it exist:
		bool drawface = c_DrawFace.GetBool() && (TexMan.CheckForTexture(CPlayer.mo.face).IsValid() || TexMan.CheckForTexture('STFST00').IsValid());
		// If bars are replaced with numbers,
		// the width is much shorter:
		if (!drawbars)
		{
			mainBlockWidth *= 0.36;
		}
		width = mainBlockWidth;
		// Increase total width (for position/offset calculation)
		// if we'll be drawing a mugshot:
		if (drawface)
		{
			width += indent + faceSize;
		}
		vector2 ofs = ( c_MainBarsX.GetInt(), c_MainBarsY.GetInt() );
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		int baseCol = GetBaseplateColor();
		// bars background:
		Fill(baseCol, pos.x, pos.y, mainBlockWidth, height, flags);
		// face background (draw separately because there's
		// a small indent between this and the bars background):
		if (drawFace)
		{
			vector2 facePos = (pos.x + mainBlockWidth + indent, pos.y);
			Fill(baseCol, facePos.x, facePos.y, faceSize, faceSize, flags);
			DrawTexture(GetMugShot(5), (facePos.x + faceSize*0.5, facePos.y + faceSize*0.5), flags|DI_ITEM_CENTER, box: (faceSize - 2, faceSize - 2));
		}

		int barFlags = flags|DI_ITEM_CENTER;
		indent = 4;
		double iconSize = 8;
		vector2 iconPos = (pos.x + indent + iconsize * 0.5, pos.y + height*0.75);

		// Draw health cross shape (instead of drawing a health item):
		double crossWidth = 2;
		double crossLength = 8;
		vector2 crossPos = iconPos;
		int crossIndent = 1;
		Fill(color(255,132,40,40), 
			crossPos.x - crossLength*0.5 - crossIndent, 
			crossPos.y - crossLength*0.5 - crossIndent,
			crossLength + crossIndent*2,
			crossLength + crossIndent*2,
			barFlags);
		Fill(color(255,200,200,200), 
			crossPos.x - crossWidth*0.5, 
			crossPos.y - crossLength*0.5,
			crossWidth,
			crossLength,
			barFlags);
		Fill(color(255,200,200,200), 
			crossPos.x - crossLength*0.5,
			crossPos.y - crossWidth*0.5, 
			crossLength,
			crossWidth,
			barFlags);
		
		// Calculate bar width (it should be indented deeper
		// from the edges and offset from the icon):
		int barWidth = mainBlockWidth - iconSize - indent*3;
		double barPosX = iconPos.x + iconsize*0.5 + indent;
		double fy = mainHUDFont.mFont.GetHeight();
		// Draw health bar or numbers:
		int health = CPlayer.mo.health;
		int maxhealth = CPlayer.mo.GetMaxHealth(true);
		int cRed, cGreen, cBlue, cFntCol;
		if (drawbars)
		{
			cRed = LinearMap(health, 0, maxhealth, 160, 0, true);
			cGreen = LinearMap(health, 0, maxhealth, 0, 160, true);
			cBlue = LinearMap(health, maxhealth, maxhealth * 2, 0, 160, true);
			DrawFlatColorBar((barPosX, iconPos.y), health, maxhealth, color(255, cRed, cGreen, cBlue), "", valueColor: Font.CR_White, barwidth:barWidth, barheight: 10, flags:barFlags);
		}
		else
		{
			DrawString(mainHUDFont, String.Format("%3d", health), (barPosX, iconPos.y - fy*0.5), translation:GetPercentageFontColor(health,maxhealth));
		}
		
		// Draw armor bar:
		// Check if armor exists and is above 0
		let barm = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		let hexarm = HexenArmor(CPlayer.mo.FindInventory("HexenArmor"));
		armMaxamount = 100;
		TextureID armTex;
		double armTexSize = 12;
		bool hasHexenArmor = false;
		if (barm)
		{
			armAmount = barm.amount;
			armMaxAmount = barm.maxamount;
			[cRed, cGreen, cBlue, cFntCol] = GetArmorColor(barm.savePercent);
			armorColor = color(cRed, cGreen, cBlue); //store for crosshair bars
			armTex = barm.icon;
		}
		if (hexArm)
		{
			double hexArmAmount;
			for (int i = 0; i < hexArm.Slots.Size(); i++)
			{
				hexArmAmount += hexArm.Slots[i];
			}
			if (hexArmAmount > 0)
			{
				SetupHexenArmorIcons();
				hasHexenArmor = true;
				armAmount = hexArmAmount;
				armMaxAmount = 80;
				[cRed, cGreen, cBlue, cFntCol] = GetArmorColor(hexArmAmount / armMaxAmount);
				armorColor = color(cRed, cGreen, cBlue); //store for crosshair bars
			}
		}

		if (armAmount > 0)
		{
			iconPos.y = pos.y + height * 0.25;
			string ap = "AP";
			// uses Hexen armor:
			if (hasHexenArmor)
			{
				//console.printf("HexArmSlots| 0: %.1f | 1: %.2f | 2: %.2f | 3: %.2f | 4: %.2f", hexArm.Slots[0], hexArm.Slots[1], hexArm.Slots[2], hexArm.Slots[3], hexArm.Slots[4]);
				// Build an array of icons from the previously set up array
				// (see SetupHexenArmorIcons()):
				array <TextureID> hArmTex;
				for (int i = WEAKEST_HEXEN_ARMOR_PIECE; i >= 0; i--)
				{
					TextureID icon;
					if (hexArm.Slots[i] <= 0)
						continue;
					// cache the icon for the slot if the amount of armor
					// in that slot is over 0 (since Hexen doesn't use
					// armor items or icons at all, only amounts):
					hArmTex.Push(int(hexenArmorIcons[i]));
				}
				// If any icons have been pushed, draw them:
				if (hArmTex.Size() > 0)
				{
					ap = "";
					// If there's only one armor piece, draw it as usual:
					if (hArmTex.Size() == 1)
					{
						armTex = hArmTex[0];
						DrawTexture(armTex, iconPos, flags|DI_ITEM_CENTER, box:(armTexSize,armTexSize));
					}
					// If there's more, draw smaller version of them in
					// a 2x2 pattern:
					else
					{
						armTexSize *= 0.5;
						double ofs = armTexSize*0.5;
						vector2 armPos;
						for (int i = 0; i < hArmTex.Size(); i++)
						{
							armTex = hArmTex[i];
							if (i == 0 || i == 2)
								armPos.x = iconPos.x - ofs;
							else
								armPos.x = iconPos.x + ofs;
							if (i == 0 || i == 1)
								armPos.y = iconPos.y - ofs;
							else
								armPos.y = iconPos.y + ofs;
							DrawTexture(armTex, armPos, flags|DI_ITEM_CENTER, box:(armTexSize,armTexSize));
						}
					}
				}
			}

			// uses normal armor:
			else if (armTex.IsValid())
			{
				ap = "";
				DrawTexture(armTex, iconPos, flags|DI_ITEM_CENTER, box:(armTexSize,armTexSize));
			}

			if (drawbars)
			{
				DrawFlatColorBar((barPosX, iconPos.y), armAmount, armMaxamount, color(255, cRed, cGreen, cBlue), ap, valueColor: Font.CR_White, barwidth:barWidth, barheight: 6, segments: barm.maxamount / 10, flags:barFlags);
			}
			else
			{
				DrawString(mainHUDFont, String.Format("%3d", armAmount), (barPosX, iconPos.y - fy*0.5), translation:cFntCol);
			}
		}
	}

	color GetAmmoColor(Ammo am)
	{
		int a = 255;
		// Explicit colors for Hexen mana:
		if (am is 'Mana1')
		{
			return color(a, 38, 41, 167);
		}
		if (am is 'Mana2')
		{
			return color(a, 42, 252, 42);
		}
		return color(a, 192, 128, 40);
	}

	void DrawWeaponBlock()
	{
		if (!c_drawAmmoBlock.GetBool())
			return;

		let weap = CPlayer.readyweapon;
		if (!weap)
			return;

		int flags = SetScreenFlags(c_AmmoBlockPos.GetInt());
		vector2 ofs = ( c_AmmoBlockX.GetInt(), c_AmmoBlockY.GetInt() );
		
		// As usual, calculate total block size first to do the fill.

		// Check if the weapon is using any ammo:
		Ammo am1, am2;
		int am1amt, am2amt;
		[am1, am2, am1amt, am2amt] = GetCurrentAmmo();

		// X size is fixed, we'll calculate Y size from here:
		int indent = 1;
		vector2 size = (66, 0);
		// predefine size for the weapon icon and ammo icon boxes:
		vector2 weapIconBox = (size.x - indent*2, 18);
		vector2 ammoIconBox = (size.x * 0.25 - indent*4, 16);
		double ammoTextHeight = mainHUDFont.mFont.GetHeight();
		// If we're drawing the ammo bar, add its height and indentation
		// to total height:
		bool drawAmmobar = c_drawAmmoBar.GetBool();
		int ammoBarHeight = 8;
		// If at least one ammo type exists, add ammoIconBox height
		// and indentation to total height:
		if (am1 || am2)
		{
			size.y += ammoIconBox.y + ammoTextHeight + indent*4;
			// If ammo exists, also add ammo bar height:
			if (drawAmmobar)
			{
				size.y += ammoBarHeight + indent*2;
			}
		}
		
		// If weapon icon is to be drawn (check CVAR and the validity of
		// the icon), add its height and indentation to total height:
		TextureID weapIcon = GetIcon(weap, DI_FORCESCALE);
		bool weapIconValid = c_DrawWeapon.GetBool() && weapIcon.IsValid() && TexMan.GetName(weapIcon) != 'TNT1A0';
		if (weapIconValid)
		{
			size.y += weapIconBox.y + indent*2;
		}

		// If there are no ammotypes or weapon icons, no need to draw anything,
		// so we'll stop here:
		if (!weapIconValid && !am1 && !am2)
		{
			return;
		}

		// Finally, adjust the position and draw fill:
		vector2 pos = AdjustElementPos((0,0), flags, (size.x, size.y), ofs);
		Fill(GetBaseplateColor(), pos.x, pos.y, size.x, size.y, flags);
		
		if (weapIconValid)
		{
			DrawTexture(weapIcon, pos + (weapIconBox.x  * 0.5 + indent, size.y - weapIconBox.y * 0.5 - indent), flags|DI_ITEM_CENTER, box: (64, 18));
		}

		// If there's no ammo, stop here:
		if (!am1 && !am2)
		{
			return;
		}

		// Draw the ammo.
		// Initially we'll assume there's only one ammo type
		// and we'll place the icon horizontally at the center;
		// if there are two ammo types, we'll adjust later:
		vector2 ammo1pos = pos + (size.x * 0.5, ammoIconBox.y * 0.5 + indent);
		vector2 ammo2pos = ammo1pos;
		// Calculate position for ammo amount text, placed right
		// below the ammo icon:
		vector2 ammoTextPos = ammo1pos + (0, ammoIconBox.y*0.5 + indent);
		// And now the ammo bar width:
		int barwidth = size.x - indent*2;
		// and the ammo bar pos:
		vector2 ammoBarPos = ammoTextPos + (-barwidth*0.5, ammoTextHeight + indent);

		// Uses only 1 ammo type - draw as calculated:
		if ((am1 && !am2) || (!am1 && am2))
		{
			Ammo am = am1 ? am1 : am2;
			DrawInventoryIcon(am, ammo1pos, flags|DI_ITEM_CENTER, boxSize: ammoIconBox);
			DrawString(mainHUDFont, ""..am.amount, ammoTextPos, flags|DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am.amount, am.maxamount));
			if (drawAmmobar)
			{
				DrawFlatColorBar(ammoBarPos, am.amount, am.maxamount, GetAmmoColor(am), barwidth: barwidth, barheight: ammoBarHeight, segments: am.maxamount / 10, flags: flags);
			}
		}
		// Uses 2 ammo types:
		else
		{
			// Ammo 1 is at the center of the left half:
			ammo1pos.x = pos.x + (size.x * 0.25);
			// Ammo 2 is at the center of the right half:
			ammo2pos.x = pos.x + (size.x * 0.75);
			// Bars will be twice as short:
			barwidth = size.x * 0.5 - indent * 4;
			ammoBarPos.x = ammo1Pos.x - barWidth*0.5;
			DrawInventoryIcon(am1, ammo1pos, flags|DI_ITEM_CENTER, boxSize: ammoIconBox);
			DrawString(mainHUDFont, ""..am1amt, (ammo1pos.x, ammoTextPos.y), flags|DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am1.amount, am1.maxamount));
			DrawInventoryIcon(am2, ammo2pos, flags|DI_ITEM_CENTER, boxSize: ammoIconBox);
			DrawString(mainHUDFont, ""..am2amt, (ammo2pos.x, ammoTextPos.y), flags|DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am2.amount, am2.maxamount));
			if (drawAmmobar)
			{
				DrawFlatColorBar(ammoBarPos, am1.amount, am1.maxamount, GetAmmoColor(am1), barwidth: barwidth, barheight: ammoBarHeight, segments: am1.maxamount / 20, flags: flags);
				ammoBarPos.x = ammo2Pos.x - barWidth*0.5;
				DrawFlatColorBar(ammoBarPos, am2.amount, am2.maxamount, GetAmmoColor(am2), barwidth: barwidth, barheight: ammoBarHeight, segments: am2.maxamount / 20, flags: flags);
			}
		}
	}

	// Draws a list of all ammo ordered by weapon slots,
	// akin to althud:
	void DrawAllAmmo()
	{
		if (!c_drawAllAmmo.GetBool())
			return;

		double iconSize = 6;
		int indent = 1;
		int flags = SetScreenFlags(c_AllAmmoPos.GetInt());
		vector2 ofs = ( c_AllAmmoX.GetInt(), c_AllAmmoY.GetInt() );
		let hfnt = mainHUDFont;
		double fntScale = 0.6;
		double fy = hfnt.mFont.GetHeight() * fntScale;
		double width = iconsize + indent + mainHUDFont.mFont.StringWidth("000/000") * fntScale;
		double height;

		// We'll iterate over ammo first to calculate the total
		// height of the block, put them in the array,
		// then draw them from the array:

		WeaponSlots wslots = CPlayer.weapons;
		if (!wslots)
			return;
		array <Ammo> ammoItems;
		// Sort ammo by weapon slots, not by the order of
		// receiving them!
		for (int sn = 0; sn <= MAXWEAPONSLOTS; sn++)
		{
			int size = wslots.SlotSize(sn);
			if (size <= 0)
				continue;

			// Get weapons in each index of the current slot:
			for (int s = 0; s < size; s++)
			{
				// Get the weapon in the slot and the index:
				class<Weapon> weap = wslots.GetWeapon(sn, s);
				if (weap)
				{
					// To get the ammo, we need to read the defaults of
					// the weapon (and cast them as class<Weapon>):
					let defWeap = GetDefaultByType((class<Weapon>)(weap));
					Ammo am;
					// Don't forget to only draw ammo if the player
					// actually has it in inventory:
					if (defWeap.ammotype1)
					{
						am = Ammo(CPlayer.mo.FindInventory(defWeap.ammotype1));
						if (am && ammoItems.Find(am) == ammoItems.Size())
						{
							ammoItems.Push(am);
							height += iconsize + indent;
						}
					}
					// And draw second ammo only if it's not the same
					// as primary ammo:
					if (defWeap.ammotype2 && defWeap.ammotype2 != defWeap.ammotype1)
					{
						am = Ammo(CPlayer.mo.FindInventory(defWeap.ammotype2));
						if (am && ammoItems.Find(am) == ammoItems.Size())
						{
							ammoItems.Push(am);
							height += iconsize + indent;
						}
					}
				}
			}
		}
		if (ammoItems.Size() <= 0)
			return;

		// Finally, draw the ammo:
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		for (int i = 0; i < ammoItems.Size(); i++)
		{
			Ammo am = ammoItems[i];
			DrawInventoryIcon(am, pos + (iconSize*0.5,iconSize*0.5), flags|DI_ITEM_CENTER, boxsize:(iconSize, iconSize));
			DrawString(hfnt, String.Format("%3d/%3d", am.amount, am.maxamount), pos + (iconSize + indent, iconsize*0.5 -fy*0.5), flags|DI_TEXT_ALIGN_LEFT, translation: GetPercentageFontColor(am.amount, am.maxamount), scale:(fntScale,fntScale));
			pos.y += max(fy, iconsize) + indent;
		}
	}

	// Called by event handler when the player is damaged:
	void UpdateAttacker(double angle)
	{
		let hmd = JGPUFH_DamageMarkerData.Create(angle);
		if (hmd)
		{
			dmgMrkData.Push(hmd);
		}
	}

	// Draws directional incoming damage markers:
	void DrawDamageMarkers(double size = 80)
	{
		if (!c_drawDamageMarkers.GetBool())
			return;

		// Create a simple long and narrow trapezium shape:
		if (!dmgMarker)
		{
			dmgMarker = new("Shape2D");

			vector2 p = (-0.1, -1);
			dmgMarker.Pushvertex(p);
			dmgMarker.PushCoord((0,0));
			p.x*= -1;
			dmgMarker.Pushvertex(p);
			dmgMarker.PushCoord((0,0));
			p.x *= -0.4;
			p.y = -0.55;
			dmgMarker.Pushvertex(p);
			dmgMarker.PushCoord((0,0));
			p.x*= -1;
			dmgMarker.Pushvertex(p);
			dmgMarker.PushCoord((0,0));

			dmgMarker.PushTriangle(0, 1, 2);
			dmgMarker.PushTriangle(1, 2, 3);
		}

		// Don't forget to multiply by hudscale:
		vector2 hudscale = GetHudScale();
		if (!dmgMarkerTransf)
			dmgMarkerTransf = new("Shape2DTransform");
		// Draw the shape for each damage marker data
		// in the previously built array:
		for (int i = dmgMrkData.Size() - 1; i >= 0; i--)
		{
			let hmd = JGPUFH_DamageMarkerData(dmgMrkData[i]);
			if (!hmd)
				continue;
			
			dmgMarkerTransf.Clear();
			dmgMarkerTransf.Scale((size, size) * hudscale.x);
			dmgMarkerTransf.Rotate(hmd.angle);
			dmgMarkerTransf.Translate((Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5));
			dmgMarker.SetTransform(dmgMarkerTransf);
			Screen.DrawShapeFill(color(0, 0, 255), hmd.alpha, dmgMarker);
		}
	}

	// Fade out damage markers:
	void UpdateDamageMarkers()
	{
		for (int i = dmgMrkData.Size() - 1; i >= 0; i--)
		{
			let hmd = JGPUFH_DamageMarkerData(dmgMrkData[i]);
			if (!hmd)
				continue;

			hmd.alpha -= c_DamageMarkersAlpha.GetFloat() / (c_DamageMarkersFadeTime.GetFloat() * TICRATE);
			if (hmd.alpha <= 0)
			{
				hmd.Destroy();
				dmgMrkData.Delete(i);
			}
		}
	}

	void RefreshReticleHitMarker()
	{
		reticleMarkerAlpha = 1.0;
	}

	void UpdateReticleHitMarker()
	{
		if (reticleMarkerAlpha > 0)
		{
			reticleMarkerAlpha -= 0.15;
		}
	}

	void DrawReticleHitMarker()
	{
		if (!c_DrawEnemyHitMarkers.GetBool())
			return;
		
		vector2 screenCenter = (Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5);
		vector2 hudscale = GetHudScale();
		// Four simple triangle shapes around the crosshair:
		if (!reticleHitMarker)
		{
			reticleHitMarker = new("Shape2D");
			vector2 p1 = (-1,-1);
			vector2 p2 = (-0.4, -0.2);
			vector2 p3 = (p2.y, p2.x);
			int id = 0;
			for (int i = 0; i < 4; i++)
			{
				reticleHitMarker.Pushvertex(p1);
				reticleHitMarker.Pushvertex(p2);
				reticleHitMarker.Pushvertex(p3);
				reticleHitMarker.PushCoord((0,0));
				reticleHitMarker.PushCoord((0,0));
				reticleHitMarker.PushCoord((0,0));
				reticleHitMarker.PushTriangle(id, id+1, id+2);
				id += 3;
				if (i == 0 || i == 2)
				{
					p1.x *= -1;
					p2.x *= -1;
					p3.x *= -1;
				}
				else if (i == 1 || i == 3)
				{
					p1.y *= -1;
					p2.y *= -1;
					p3.y *= -1;
				}
			}
		}
		if (reticleMarkerAlpha > 0)
		{
			if (!reticleMarkerTransform)
				reticleMarkerTransform = new("Shape2DTransform");
			// Factor in the crosshair size but up to a point
			// as to not make these too small:
			double size = 15 * max(c_crosshairScale.GetFloat(), 0.3);
			reticleMarkerTransform.Clear();
			reticleMarkerTransform.Scale((size, size) * hudscale.x);
			reticleMarkerTransform.Translate(screenCenter);
			reticleHitMarker.SetTransform(reticleMarkerTransform);
			Screen.DrawShapeFill(color(0, 0, 255), reticleMarkerAlpha, reticleHitMarker);
		}
	}

	bool CanDrawReticleBar(int which)
	{
		if (c_DrawReticleBars && c_DrawReticleBars.GetInt() != DM_AUTOHIDE)
			return true;

		which = Clamp(which, 0, reticleMarkersDelay.Size()-1);
		return reticleMarkersDelay[which] > 0;
	}

	void UpdateReticleBars()
	{
		if (c_DrawReticleBars && c_DrawReticleBars.GetInt() != DM_AUTOHIDE)
		{
			reticleMarkersDelay[RB_HEALTH] = MARKERSDELAY;
			reticleMarkersDelay[RB_ARMOR] = MARKERSDELAY;
			reticleMarkersDelay[RB_AMMO1] = MARKERSDELAY;
			reticleMarkersDelay[RB_AMMO2] = MARKERSDELAY;
			return;
		}

		int health = CPlayer.mo.health;
		int maxhealth = CPlayer.mo.GetMaxHealth(true);
		if (prevHealth != health || prevMaxHealth != maxhealth)
		{
			prevHealth = health;
			prevMaxHealth = maxhealth;
			reticleMarkersDelay[RB_HEALTH] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_HEALTH] -= 1;
		}

		if (prevArmAmount != armAmount || prevArmMaxAmount != armMaxAmount)
		{
			prevArmAmount = armAmount;
			prevArmMaxAmount = armMaxAmount;
			reticleMarkersDelay[RB_ARMOR] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_ARMOR] -= 1;
		}


		Ammo am1, am2;
		[am1, am2] = GetCurrentAmmo();
		if (am1 && (prevAmmo1Amount != am1.amount || prevAmmo1MaxAmount != am1.maxamount))
		{
			prevAmmo1Amount = am1.amount;
			prevAmmo1MaxAmount = am1.maxamount;
			reticleMarkersDelay[RB_AMMO1] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_AMMO1] -= 1;
		}
		if (am2 && (prevAmmo2Amount != am2.amount || prevAmmo2MaxAmount != am2.maxamount))
		{
			prevAmmo2Amount = am2.amount;
			prevAmmo2MaxAmount = am2.maxamount;
			reticleMarkersDelay[RB_AMMO2] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_AMMO2] -= 1;
		}
	}

	double, vector2, vector2, int, int GetReticleBarsPos(int i, double inwidth, double outwidth, double fntHeight)
	{
		i = Clamp(i, 0, 4);
		vector2 posIn;
		vector2 posOut;
		double angle;
		int inFlags = DI_TEXT_ALIGN_CENTER;
		int outFlags = DI_TEXT_ALIGN_CENTER;
		switch (i)
		{
			default:
				angle = RB_DONTDRAW;
				break;
			case RB_LEFT:
				angle = -90;
				posIn = (-inWidth, -fntHeight*0.25);
				posOut = (-outWidth, posIn.y);
				inFlags = DI_TEXT_ALIGN_LEFT;
				outFlags = DI_TEXT_ALIGN_RIGHT;
				break;
			case RB_TOP:
				angle = 0;
				posIn = (0, -inWidth + fntHeight*0.25);
				posOut = (0, -outWidth - fntHeight);
				break;
			case RB_RIGHT:
				angle = 90;
				posIn = (inWidth, -fntHeight*0.25);
				posOut = (outWidth, -fntHeight*0.25);
				inFlags = DI_TEXT_ALIGN_RIGHT;
				outFlags = DI_TEXT_ALIGN_LEFT;
				break;
			case RB_BOTTOM:
				angle = 180;
				posIn = (0, inWidth - fntHeight);
				posOut = (0, outWidth);
				break;
		}
		if (c_aspectscale.GetBool())
		{
			posIn.y /= ASPECTSCALE;
			posOut.y /= ASPECTSCALE;
		}
		return angle, posIn, posOut, inFlags|DI_SCREEN_CENTER, outFlags|DI_SCREEN_CENTER;
	}

	void DrawReticleBars(int steps = 100)
	{
		if (c_DrawReticleBars.GetInt() <= DM_NONE)
			return;
		
		double coverAngle = BARCOVERANGLE;
		if (!lookTC)
		{
			let ti = ThinkerIterator.Create("JGPHUD_LookTargetController");
			Thinker th;
			while (th = JGPHUD_LookTargetController(ti.Next()))
			{
				let ltc = JGPHUD_LookTargetController(th);
				if (ltc && ltc.pp && ltc.pp == CPlayer.mo)
				{
					lookTC = ltc;
					break;
				}
			}
		}

		// This is the general mask that cuts out the inner part
		// of the disks to make them appear as circular bars:
		if (!roundBarsGenMask)
		{
			double angStep = CIRCLEANGLES / steps;
			double ang = 270;
			roundBarsGenMask = New("Shape2D");
			// anchor point at the center:
			roundBarsGenMask.PushVertex((0,0));
			// coords are irrelevant as usual, because no textures:
			roundBarsGenMask.PushCoord((0,0));
			for (int i = 0; i < steps; i++)
			{
				double c = cos(ang);
				double s = sin(ang);
				roundBarsGenMask.PushVertex((c,s));
				roundBarsGenMask.PushCoord((0,0));
				ang += angStep;
			}
			int maxSegments = steps;
			// start with 1 because point 0 is the center
			// and is already accounted for:
			for (int i = 1; i <= steps; ++i)
			{
				int next = i+1;
				if (next > steps)
					next -= steps;
				roundBarsGenMask.PushTriangle(0, i, next);
			}
		}
		if (!roundBarsGenMaskTransfInner)
		{
			roundBarsGenMaskTransfInner = New("Shape2DTransform");
		}
		if (!roundBarsGenMaskTransfOuter)
		{
			roundBarsGenMaskTransfOuter = New("Shape2DTransform");
		}

		// Position and sizes:
		vector2 screenCenter = (Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5);
		vector2 hudscale = GetHudScale();
		double widthFac = 1.0 - Clamp(c_ReticleBarsWidth.GetFloat(), 0.0, 1.0);
		double virtualSize = c_ReticleBarsSize.GetInt();
		double secSizeFac = 1.05;
		double size = virtualSize * hudscale.x;
		double maskSize = size * widthFac;
		double secondarySize = (size * (secSizeFac / widthfac)) / secSizeFac;
		double secondaryMaskSize = secondarySize * widthFac;

		// Mask for inner bars:
		roundBarsGenMaskTransfInner.Clear();
		roundBarsGenMaskTransfInner.Scale((maskSize, maskSize));
		roundBarsGenMaskTransfInner.Translate(screenCenter);
		// Mask for outer bars:
		roundBarsGenMaskTransfOuter.Clear();
		roundBarsGenMaskTransfOuter.Scale((secondaryMaskSize, secondaryMaskSize));
		roundBarsGenMaskTransfOuter.Translate(screenCenter);
		// Autoide
		bool autoHide = c_DrawReticleBars.GetInt() == DM_AUTOHIDE;
		// Should draw text?
		bool drawBarText = c_ReticleBarsText.GetBool();
		// Element alpha:
		double alpha = Clamp(c_ReticleBarsAlpha.GetFloat(), 0.0, 1.0);
		
		// Font position and scale setup:
		HUDFont hfnt = numHUDFont;
		Font fnt = hfnt.mFont;
		// We need to do a lot here. The text strings, if show, have to be shown
		// in specific places, depending on where the bar is located (left, top,
		// right, bottom), and also whether it's an inner bar or an outer bar.
		// So, we need two sets of positions and two sets of flags (for inner 
		// and outer). Font height also plays a role for vertical positioning.
		// And, obviously, the angle at which the bar is rotated. All of this
		// can be set up by the player by changing the appropriate CVar.
		// See GetReticleBarsPos() with a whopping 5 return values.
		double fntScale = LinearMap(virtualSize, 12, 200, 0.5, 5, true);
		double fy = fnt.GetHeight() * fntScale;
		double fontOfsIn = maskSize / hudscale.x - 1;
		double fontOfsOut = secondarySize / hudscale.x + 1;
		vector2 fntPosIn, fntPosOut;
		int fntFlagsIn, fntFlagsOut;
		double angle;
		double valueFrac;

		// We also need to apply and remove stencil around each step,
		// so that each bar is masked individually.

		// Looktarget healthbar (inner bar):
		[angle, fntPosIn, fntPosOut, fntFlagsIn, fntFlagsOut] = GetReticleBarsPos(c_ReticleBarsEnemy.GetInt(), fontOfsIn, fontOfsOut, fy);
		if (angle != RB_DONTDRAW && lookTC && lookTC.looktarget)
		{
			roundBarsGenMask.SetTransform(roundBarsGenMaskTransfInner);
			let lt = lookTC.looktarget;
			int health = lt.health;
			let ltDef = GetDefaultByType(lt.GetClass());
			int maxhealth = max(lt.starthealth, lt.GetMaxHealth());
			Screen.EnableStencil(true);
			Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
			Screen.DrawShapeFill(color(0,0,0), 1, roundBarsGenMask);
			Screen.SetStencil(0, SOP_Keep, SF_AllOn);
			double fadeAlph = LinearMap(lookTC.targetTimer, 0, JGPHUD_LookTargetController.TARGETDISPLAYTIME / 2, 0.0, alpha, true);
			valueFrac = LinearMap(health, 0, maxhealth, 1.0, 0.0, true);
			DrawCircleSegmentShape(color(60,160,60), screenCenter, size, steps, angle, coverAngle, valueFrac, fadeAlph);
			if (drawBarText)
			{
				double s = 0.35;
				DrawString(smallHUDFont, String.Format("%s", lt.GetTag()), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75) * s);
				DrawString(hfnt, String.Format("%d", health), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
			}
			// Clear the general mask:
			Screen.EnableStencil(false);
			Screen.ClearStencil();
		}


		// Health and armor bars:
		[angle, fntPosIn, fntPosOut, fntFlagsIn, fntFlagsOut] = GetReticleBarsPos(c_ReticleBarsHealthArmor.GetInt(), fontOfsIn, fontOfsOut, fy);
		if (angle != RB_DONTDRAW)
		{
			// Health bar (inner):
			int health = CPlayer.mo.health;
			int maxhealth = CPlayer.mo.GetMaxHealth(true);
			if (CanDrawReticleBar(RB_HEALTH))
			{
				roundBarsGenMask.SetTransform(roundBarsGenMaskTransfInner);
				double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_HEALTH], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
				Screen.EnableStencil(true);
				Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
				Screen.DrawShapeFill(color(0,0,0), 1, roundBarsGenMask);
				Screen.SetStencil(0, SOP_Keep, SF_AllOn);
				valueFrac = LinearMap(health, 0, maxhealth, 1.0, 0.0, true);
				DrawCircleSegmentShape(color(215,100,100), screenCenter, size, steps, angle, coverAngle, valueFrac, fadeAlph);
				if (drawBarText)
				{
					DrawString(hfnt, String.Format("%d", health), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
				}
				// Clear the general mask:
				Screen.EnableStencil(false);
				Screen.ClearStencil();
			}
			// Armor bar (outer):
			int armAmount = armAmount;
			int armMaxAmount = armMaxAmount;
			if (CanDrawReticleBar(RB_ARMOR))
			{
				roundBarsGenMask.SetTransform(roundBarsGenMaskTransfOuter);
				double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_ARMOR], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
				Screen.EnableStencil(true);
				Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
				Screen.DrawShapeFill(color(0,0,0), 1, roundBarsGenMask);
				Screen.SetStencil(0, SOP_Keep, SF_AllOn);
				valueFrac = LinearMap(armAmount, 0, armMaxAmount, 1.0, 0.0, true);
				DrawCircleSegmentShape(color(armorColor.a, armorcolor.r+32, armorcolor.g+32, armorcolor.b+32), screenCenter, secondarySize, steps, angle, coverAngle, valueFrac, fadeAlph);
				if (drawBarText)
				{
					DrawString(hfnt, String.Format("%d", armAmount), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
				}
				Screen.EnableStencil(false);
				Screen.ClearStencil();
			}
		}
		

		Ammo am1, am2;
		[am1, am2] = GetCurrentAmmo();

		// Ammo bars:
		[angle, fntPosIn, fntPosOut, fntFlagsIn, fntFlagsOut] = GetReticleBarsPos(c_ReticleBarsAmmo.GetInt(), fontOfsIn, fontOfsOut, fy);
		if (angle != RB_DONTDRAW)
		{
			color amCol = GetAmmoColor(am2);
			// Ammo 1 (inner):
			if (am1)
			{
				if (CanDrawReticleBar(RB_AMMO1))
				{
					roundBarsGenMask.SetTransform(roundBarsGenMaskTransfInner);
					double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_AMMO1], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
					Screen.EnableStencil(true);
					Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
					Screen.DrawShapeFill(color(0,0,0), 1, roundBarsGenMask);
					Screen.SetStencil(0, SOP_Keep, SF_AllOn);
					valueFrac = LinearMap(am1.amount, 0, am1.maxAmount, 1.0, 0.0, true);
					DrawCircleSegmentShape(amCol, screenCenter, size, steps, angle, coverAngle, valueFrac, fadeAlph);
					if (drawBarText)
					{
						DrawString(hfnt, String.Format("%d", am1.amount), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
					}
					Screen.EnableStencil(false);
					Screen.ClearStencil();
				}
			}
			// Ammo 2 (outer):
			if (am2 && am2 != am1)
			{
				if (CanDrawReticleBar(RB_AMMO2))
				{
					roundBarsGenMask.SetTransform(roundBarsGenMaskTransfOuter);
					double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_AMMO2], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
					Screen.EnableStencil(true);
					Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
					Screen.DrawShapeFill(color(0,0,0), 1, roundBarsGenMask);
					Screen.SetStencil(0, SOP_Keep, SF_AllOn);
					valueFrac = LinearMap(am2.amount, 0, am2.maxAmount, 1.0, 0.0, true);
					DrawCircleSegmentShape(color(amCol.a, int(amCol.r*0.7),int(amCol.g*0.7),int(amCol.b*0.7)), screenCenter, secondarySize, steps, angle, coverAngle, valueFrac, fadeAlph);
					if (drawBarText)
					{
						DrawString(hfnt, String.Format("%d", am2.amount), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
					}
					Screen.EnableStencil(false);
					Screen.ClearStencil();
				}
			}
		}
	}

	void DrawCircleSegmentShape(color col, vector2 pos, double size, int steps, double angle, double coverAngle, double frac = 1.0, double alpha = 1.0)
	{
		// Make sure the shapes and transforms exist:
		if (!roundBars || !roundBarsAngMask || !roundBarsTransform)
		{
			CreateCircleSegmentShapes(roundBars, roundBarsAngMask, steps, coverAngle);
		}

		roundBarsTransform.Clear();
		roundBarsTransform.Scale((size, size));
		roundBarsTransform.Rotate(angle);
		roundBarsTransform.Translate(pos);
		roundBars.SetTransform(roundBarsTransform);
		// Draw the black background:
		Screen.DrawShapeFill(color(0,0,0), alpha, roundBars);
		// enable mask:
		Screen.EnableStencil(true);
		Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
		// draw mask shape:
		// Angle the mask (flip the angle if it was negative,
		// so it goes counter-clockwise instead of clockwise):
		double ofsMaskAngle = coverAngle*frac;
		if (angle <= 0)
			 ofsMaskAngle *= -1;
		roundBarsTransform.Clear();
		// Increase the size slightly just to make sure it doesn't
		// leave any stray pixels at the edge of the bar:
		roundBarsTransform.Scale((size, size));
		roundBarsTransform.Rotate(angle + ofsMaskAngle);
		roundBarsTransform.Translate(pos);
		roundBarsAngMask.SetTransform(roundBarsTransform);
		// set mask:
		Screen.DrawShapeFill(color(0,0,0), 1.0, roundBarsAngMask);
		Screen.SetStencil(0, SOP_Keep, SF_AllOn);
		// draw bar:
		roundBarsTransform.Clear();
		roundBarsTransform.Scale((size, size));
		roundBarsTransform.Rotate(angle);
		roundBarsTransform.Translate(pos);
		roundBars.SetTransform(roundBarsTransform);
		color colBGR = color(col.b, col.g, col.r);
		Screen.DrawShapeFill(colBGR, alpha, roundBars);
		// disable mask:
		Screen.EnableStencil(false);
		Screen.ClearStencil();
	}

	void CreateCircleSegmentShapes(out Shape2D inShape, out Shape2D outShape, int steps, double coverAngle)
	{
		if (!roundBarsTransform)
		{
			roundBarsTransform = New("Shape2DTransform");
		}
		coverAngle = Clamp(coverAngle, 0., CIRCLEANGLES);
		double halfAngle = coverAngle*0.5;
		// split the total number of steps between the smaller shape
		// and the bigger shape:
		int inSteps = ceil(steps * (coverAngle / CIRCLEANGLES)); // 23
		int outSteps = steps - inSteps; // 77
		// Start at the top:
		double startAng = 270;
		// Begin with the inner (pie) shape:
		if (!inShape)
		{
			double angStep = coverAngle / (inSteps - 1);
			// initial offset should be half of the cover angle
			// to the left:
			double ang = startAng - halfAngle; //230
			inShape = New("Shape2D");
			// anchor point at the center:
			inShape.PushVertex((0,0));
			inShape.PushCoord((0,0));
			for (int i = 1; i <= inSteps; i++)
			{
				double c = cos(ang);
				double s = sin(ang);
				inShape.PushVertex((c,s));
				inShape.PushCoord((0,0));
				ang += angStep;
			}
			for (int i = 1; i < inSteps; i++)
			{
				int next = i+1;
				if (next > inSteps)
					next -= inSteps;
				inShape.PushTriangle(0, i, next);
			}
		}
		// Now create another shape that covers the rest of the disk:
		if (!outShape)
		{
			// Move in the opposite direction:
			double angStep = (CIRCLEANGLES - coverAngle) / (outSteps - 1);
			// And start at the end of the previous shape:
			double ang = startAng + halfAngle;
			outShape = New("Shape2D");
			// first point:
			outShape.PushVertex((0,0));
			outShape.PushCoord((0,0));
			for (int i = 1; i <= outSteps; i++)
			{
				double c = cos(ang);
				double s = sin(ang);
				outShape.PushVertex((c,s));
				outShape.PushCoord((0,0));
				ang += angStep;
			}
			for (int i = 1; i < outSteps; i++)
			{
				int next = i+1;
				if (next > outSteps)
					next -= outSteps;
				outShape.PushTriangle(0, i, next);
			}
		}
	}

	// Collects the icons, slots and slot indexes of existing
	// weapons into an array of custom classes:
	// (See JGPUFH_WeaponSlotData class)
	void GetWeaponSlots()
	{
		if (weaponSlotData.Size() > 0)
			return;

		WeaponSlots wslots = CPlayer.weapons;
		if (!wslots)
			return;

		for (int i = 1; i <= MAXWEAPONSLOTS; i++)
		{
			// Slot 0 is the 10th slot:
			int sn = i >= MAXWEAPONSLOTS ? 0 : i;
			int size = wslots.SlotSize(sn);
			if (size <= 0)
				continue;

			let wsd = JGPUFH_WeaponSlotData.Create(sn);
			for (int s = 0; s < size; s++)
			{
				class<Weapon> weap = wslots.GetWeapon(sn, s);
				if (weap && wsd)
				{
					wsd.weapons.Push(weap);
				}
			}
			if (wsd.weapons.Size() > 0)
			{
				weaponSlotData.Push(wsd);
			}
		}
	}

	void UpdateWeaponSlots()
	{
		if (!prevReadyWeapon)
		{
			prevReadyWeapon = CPlayer.readyweapon;
		}
		if (CPlayer.readyweapon == prevReadyWeapon)
		{
			if (slotsDisplayTime > 0)
			{
				slotsDisplayTime--;
			}
		}
		else
		{
			slotsDisplayTime = SLOTSDISPLAYDELAY;
			prevReadyWeapon = CPlayer.readyweapon;
		}
	}

	void DrawWeaponSlots(vector2 box = (16, 10))
	{
		if (c_drawWeaponSlots.GetInt() <= DM_NONE)
			return;

		if (c_drawWeaponSlots.GetInt() == DM_AUTOHIDE && slotsDisplayTime <= 0)
			return;
		
		// Always run to make sure the slot data
		// is properly set up:
		GetWeaponSlots();


		int totalSlots;
		int maxSlotID = 1;
		// first iteration to calculate the size of the whole block:
		for (int i = 0; i < weaponSlotData.Size(); i++)
		{
			let wsd = weaponSlotData[i];
			if (wsd)
			{
				bool slotValid = false;
				int slotIndexes = 0;
				for (int id = 0; id < wsd.weapons.Size(); id++)
				{
					let foundweap = wsd.weapons[id];
					if (foundweap && CPlayer.mo.CountInv(foundweap))
					{
						slotValid = true;
						slotIndexes++;
					}
				}
				if (slotValid)
				{
					totalSlots++;
					maxSlotID = max(maxSlotID, slotIndexes);
				}
			}
		}

		int flags = SetScreenFlags(c_WeaponSlotsPos.GetInt());
		int alignment = c_WeaponSlotsAlign.GetInt();
		bool vertical = (alignment != WA_HORIZONTAL);
		bool rightEdge = vertical && (flags & DI_SCREEN_RIGHT == DI_SCREEN_RIGHT);
		vector2 ofs = ( c_WeaponSlotsX.GetInt(), c_WeaponSlotsY.GetInt() );
		double indent = 2;
		double horMul = vertical ? maxSlotID : totalSlots;
		double vertMul = vertical ? totalSlots : maxSlotID;
		double width = (box.x + indent) * horMul - indent; //we don't need indent at the end
		double height = (box.y + indent) * vertMul - indent; //ditto
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		if (vertical)
		{
			if (rightEdge)
				pos.x += box.x + indent;
			if (alignment == WA_VERTICALINV)
				pos.y += height - box.y;
		}

		// Now we're going to draw all weapons the player has,
		// split into slots and indexes.
		// By default slots are columns, indexes are rows,
		// but with vertical alignment it's the opposite.
		vector2 wpos = pos;
		// 1 array of data per each slot. Iterate over array:
		for (int i = 0; i < weaponSlotData.Size(); i++)
		{
			let wsd = weaponSlotData[i];
			if (wsd)
			{
				// Set to true if the player has at least one
				// weapon in this slot:
				bool slotValid = false;
				// Iterate over all weapons in this slot:
				for (int id = 0; id < wsd.weapons.Size(); id++)
				{
					let w = wsd.weapons[id];
					if (!w)
						continue;
					// Only draw slots for weapons that the player actually has:
					let weap = Weapon(CPlayer.mo.FindInventory(w));
					if (!weap || weap.amount <= 0)
						continue;
					
					slotValid = true;
					DrawOneWeaponSlot(weap, wpos, flags, box, wsd.slot);
					
					// Move the box to the next index
					// If it's vertical, move the box sideways:
					if (vertical)
					{
						// If it's at the right edge, move the box
						// to the right instead of to the left:
						double stepx = (box.x + indent) * (rightedge ? -1.0 : 1.0);
						wpos.x += stepx;
					}
					// Otherwise move it down:
					else
					{
						wpos.y += (box.y + indent);
					}
				}

				// If this slot wasn't empty, move the box to the
				// next weapon slot:
				if (slotValid)
				{
					// Move up/down if it's vertical:
					if (vertical)
					{
						// If inverted alignment is used, move it up:
						double stepy = (box.x*0.5 + indent*2) * (alignment == WA_VERTICALINV ? -1.0 : 1.0);
						wpos.y += stepy;
						// and reset horizontally:
						wpos.x = pos.x;
					}
					// otherwise move to the right:
					else
					{
						wpos.x += (box.x + indent);
						// and reset vertically:
						wpos.y = pos.y;
					}
				}
			}
		}
	}

	void DrawOneWeaponSlot(Weapon weap, vector2 pos, int flags, vector2 box, int slot = -1)
	{
		if (!weap)
			return;
		
		color col = GetBaseplateColor();
		int fntCol = Font.CR_Untranslated;
		// Compare this weapon to readyweapon and pendingweapon:
		Weapon rweap = Weapon(CPlayer.readyweapon);
		// MUST explicitly cast it as Weapon, otherwise the pointer
		// won't be properly null-checked:
		Weapon pweap = Weapon(CPlayer.pendingweapon);
		// If the weapon in question is selected or being
		// selected, invert the colors of the box:
		if ((rweap == weap && !pweap) || pweap == weap)
		{
			col = color(200, 255 - col.r, 255 - col.g, 255 - col.b);
			fntCol = Font.CR_Gold;
		}
		// fill the box color, then draw the weapon's icon:
		Fill(col, pos.x, pos.y, box.x, box.y, flags);
		DrawInventoryIcon(weap, pos + box*0.5, flags|DI_ITEM_CENTER, boxsize: box);
		
		// draw small ammo bars at the bottom of the box:
		double barheight = 0.5;
		double barPosY = pos.y + box.y - barheight;
		Ammo am1 = weap.ammo1;
		color amCol = color(255, 0, 255, 0); //ammo1 is green
		color amCol2 = color(255, 255, 128, 0); //ammo2 is orange
		if (am1)
		{
			double barWidth = LinearMap(am1.amount, 0, am1.maxamount, 0., box.x, true);
			Fill(amCol, pos.x, barPosY, barWidth, barheight, flags);
			barPosY -= barHeight*2;
		}
		// Only draw the second bar if ammotype2 isn't the same
		// as ammotype 1:
		Ammo am2 = weap.ammo2;
		if (am2 && am2 != am1)
		{
			double barWidth = LinearMap(am2.amount, 0, am2.maxamount, 0., box.x, true);
			Fill(amCol2, pos.x, barPosY, barWidth, barheight, flags);
		}
		
		// draw slot number in the bottom right corner of the box:
		if (slot != -1)
		{
			double fy = mainHUDFont.mFont.GetHeight();
			string slotNum = ""..slot;
			DrawString(mainHUDFont, slotNum, (pos.x+box.x, pos.y+box.y-fy*0.5), flags|DI_TEXT_ALIGN_RIGHT, fntCol, 0.8, scale:(0.5, 0.5));
		}
	}

	// The minimap is a pretty annoying bit. Aside from potentially causing
	// performance issues, it also has  to be drawn fully using Screen
	// methods because StatusBar doesn't have anything like shapes and
	// line drawing.
	void DrawMinimap()
	{
		// Don't draw any of this if the map is active:
		if (autoMapActive)
			return;

		bool drawMinimap = c_drawMinimap.GetBool();
		double size = c_MinimapSize.GetFloat();
		// Almost everything has to be multiplied by hudscale.x
		// so that it matches the general HUD scale regarldess
		// of physical resolution:
		vector2 hudscale = GetHudScale();
		// Screen flags are obtained as usual, although they're
		// only used in AdjustElementPos, not in the actual
		// drawing functions, since Screen functions don't
		// interact with statusbar DI_* flags:
		int flags = SetScreenFlags(c_MinimapPos.GetInt());
		vector2 ofs = ( c_MinimapPosX.GetInt(), c_MinimapPosY.GetInt() );
		// Real: true makes this function return real screeen
		// coordinates rather virtual ones:
		vector2 pos = AdjustElementPos((0,0), flags, (size, size), ofs, real:true);

		// Draw map data below the minimap
		// (or above it if it's at the bottom of the screen):
		vector2 msize = (64, 0);
		if (drawMinimap)
		{
			msize = (max(size, 44), size); //going under 44 pixels looks too bad scaling-wise
		}
		vector2 mapDataSize = (msize.x, msize.y + 16);
		// draw it above the minimap if that's at the bottom:
		vector2 mapDataPos = ((flags & DI_SCREEN_BOTTOM) == DI_SCREEN_BOTTOM) ? (0, 0) : (0, msize.y);
		mapdataPos = AdjustElementPos(mapDataPos, flags, (msize.x, msize.y), ofs);
		// Since this thing is anchored to the minimap, and the minimap,
		// being drawn by Screen, ignores HUD aspect scaling, we
		// need to make sure this bit's position also ignores
		// HUD scaling:
		if (c_aspectscale.GetBool())
		{
			mapDataPos.y /= ASPECTSCALE;
		}
		DrawMapData(mapDataPos, flags, msize.x, 0.35);
		
		// If the actual minimap is disabled, stop here:
		if (!drawMinimap)
			return;

		size *= hudscale.x;

		// Let the player change the size of the map:
		double mapZoom = Clamp(c_MinimapZoom.GetFloat(), 0.01, 10.0);
		mapZoom /= MAPSCALEFACTOR;
		// These are needed to position the lines on our
		// minimap to the same relative positions they are
		// in the world:
		vector2 ppos = CPlayer.mo.pos.xy;
		double playerAngle = -(CPlayer.mo.angle + 90);
		vector2 diff = Level.Vec2Diff((0,0), ppos);

		// Create square and circular shapes for the minimap:
		if (!minimapShape_Square)
		{
			minimapShape_Square = New("Shape2D");
			vector2 mv = (0, 0);
			minimapShape_Square.PushVertex(mv);
			mv = (0, 1);
			minimapShape_Square.PushVertex(mv);
			mv = (1, 0);
			minimapShape_Square.PushVertex(mv);
			mv = (1, 1);
			minimapShape_Square.PushVertex(mv);
			minimapShape_Square.PushCoord((0,0));
			minimapShape_Square.PushCoord((0,0));
			minimapShape_Square.PushCoord((0,0));
			minimapShape_Square.PushCoord((0,0));
			minimapShape_Square.PushTriangle(0,1,2);
			minimapShape_Square.PushTriangle(1,2,3);
		}
		if (!minimapShape_Circle)
		{
			minimapShape_Circle = New("Shape2D");
			vector2 mv = (0.5, 0.5);
			minimapShape_Circle.PushVertex(mv);
			minimapShape_Circle.PushCoord((0,0));
			int steps = 60;
			double ang = 0;
			double angStep = CIRCLEANGLES / steps;
			for (int i = 0; i < steps; i++)
			{
				double c = cos(ang);
				double s = sin(ang);
				minimapShape_Circle.PushVertex((c,s));
				minimapShape_Circle.PushCoord((0,0));
				ang += angStep;
			}
			for (int i = 1; i <= steps; ++i)
			{
				int next = i+1;
				if (next > steps)
					next -= steps;
				minimapShape_Circle.PushTriangle(0, i, next);
			}
		}
		if (!minimapTransform)
		{
			minimapTransform = New("Shape2DTransform");
		}
		minimapTransform.Clear();
		// Pick the shape to use based on the player's choice:
		bool circular = c_CircularMinimap.GetBool();
		Shape2D shapeToUse = circular ? minimapShape_Circle : minimapShape_Square;
		// A circular shape has to be scaled to 50% and moved 
		// to the center of the element, since it's drawn from
		// the center, not the corner, in contrast to a square:
		double shapeFac = circular ? 0.5 : 1.;
		vector2 shapeOfs = circular ? (size*shapeFac,size*shapeFac) : (0,0);
		minimapTransform.Scale((size,size) * shapeFac);
		minimapTransform.Translate(pos + shapeOfs);
		shapeToUse.SetTransform(minimapTransform);

		// background:
		Color baseCol = GetBaseplateColor();
		double edgeThickness = 1 * hudscale.x;
		
		// Fill the shape with the outline color
		// (remember than DrawShapeFill is BGR, not RGB):
		Screen.DrawShapeFill(color(baseCol.B, baseCol.G, baseCol.R), 1.0, shapeToUse);
		
		// Scale the shape down to draw the black background:
		// If the shape isn't circular, half of the line width
		// must be added to the offsets, because of positioning
		// differences:
		if (!circular)
			shapeOfs += (edgeThickness*0.5,edgeThickness*0.5);
		minimapTransform.Clear();
		minimapTransform.Scale((size-edgeThickness,size-edgeThickness) * shapeFac);
		minimapTransform.Translate(pos + shapeOfs);
		shapeToUse.SetTransform(minimapTransform);
		Screen.DrawShapeFill(color(255,0,0,0), 1.0, shapeToUse);

		// Apply mask
		// It's applied after outline and background scaling, 
		// so that the lines are maked within the outline:
		Screen.EnableStencil(true);
		Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
		// shape is used for the mask (colors aren't needed):
		Screen.DrawShapeFill(color(0,0,0,0), 0.0, shapeToUse);
		Screen.SetStencil(1, SOP_Keep, SF_AllOn);
		
		for (int i = 0; i < Level.Lines.Size(); i++)
		{
			Line ln = Level.Lines[i];
			if (!ln)
				continue;

			// Get vertices and scale them in accordance
			// with zoom value and hudscale:
			vector2 lp1 = ln.v1.p;
			vector2 lp2 = ln.v2.p;
			vector2 p1 = (lp1 - diff) * mapZoom * hudscale.x;
			vector2 p2 = (lp2 - diff) * mapZoom * hudscale.x;
			// Rotate and mirror horizontally, so that the top
			// of the minimap is pointing where the player
			// is facing:
			p1 = Actor.RotateVector(p1, playerAngle);
			p2 = Actor.RotateVector(p2, playerAngle);
			p1.x *= -1;
			p2.x *= -1;
			// Offset the vertices around the center
			// of the map (NOT player position):
			p1 += (size, size)*0.5;
			p2 += (size, size)*0.5;
			// Don't draw the lines that are 
			// completely out of the mask area:
			if (abs(p1.x) > size && abs(p1.y) > size && abs(p2.x) > size && abs(p2.y) > size)
				continue;
			// One-sided lines are thicker and opaque:
			double thickness = 1;
			color col = color(128, 0, 255, 0);
			if (!(ln.flags & Line.ML_TWOSIDED))
			{
				thickness = 2;
				col = color(col.a * 2, col.r, col.g, col.b);
			}
			if (ln.activation & SPAC_PlayerActivate)
			{
				col = color(255, 255, 255, 255);
			}
			Screen.DrawThickLine(p1.x + pos.x, p1.y + pos.y, p2.x + pos.x, p2.y + pos.y, thickness, col, col.a);
		}
		// Red arrow at the center:
		if (!minimapShape_Arrow)
		{
			minimapShape_Arrow = new("Shape2D");
			minimapShape_Arrow.Pushvertex((0, 0));
			minimapShape_Arrow.Pushvertex((0, -1));
			minimapShape_Arrow.Pushvertex((-0.5,0.5));
			minimapShape_Arrow.Pushvertex((0.5,0.5));
			minimapShape_Arrow.PushCoord((0,0));
			minimapShape_Arrow.PushCoord((0,0));
			minimapShape_Arrow.PushCoord((0,0));
			minimapShape_Arrow.PushCoord((0,0));
			minimapShape_Arrow.PushTriangle(0, 1, 2);
			minimapShape_Arrow.PushTriangle(0, 1, 3);
		}
		minimapTransform.Clear();
		minimapTransform.Scale((3.2, 3.2) * hudscale.x);
		minimapTransform.Translate(pos + (size*0.5,size*0.5));
		minimapShape_Arrow.SetTransform(minimapTransform);
		Screen.DrawShapeFill(color(0,0,255), 1.0, minimapShape_Arrow);
		
		// Disable the mask:
		Screen.EnableStencil(false);
		Screen.ClearStencil();
	}

	// Draw map data (kills/secrets/items/time) below the
	// minimap (even if the minimap isn't draw, it'll be
	// attached to the same position):
	void DrawMapData(vector2 pos, int flags, double width, double scale = 1.0)
	{
		HUDFont hfnt = smallHUDFont;
		Font fnt = hfnt.mFont;
		let fy = fnt.GetHeight() * scale;

		pos.x += width*0.5;
		// flip if it's at the bottom:
		if ((flags & DI_SCREEN_BOTTOM) == DI_SCREEN_BOTTOM)
		{
			pos.y -= fy * 3;
		}

		int secrets = Level.found_secrets;
		int kills = Level.killed_monsters;
		int items = Level.found_items;
		// Don't forget to account for multiplayer:
		if (multiplayer)
		{
			secrets = CPlayer.secretcount;
			kills = CPlayer.killcount;
			items = CPlayer.itemcount;
		}
		int totalsecrets = Level.total_secrets;
		int totalkills = Level.total_monsters;
		int totalitems = Level.total_items;
		string s_left, s_right;

		// Drawing the actual elements is relegated to a
		// separate function to properly handle scaling:
		if (c_DrawKills.GetBool())
		{
			s_left = String.Format("\cG%s", StringTable.Localize("$TXT_IMKILLS"));
			s_right = String.Format("\cD%d\c-/\cD%d", kills, totalkills);
			DrawMapDataElement(s_left, s_right, hfnt, pos, flags, width, scale);
			pos.y+=fy;
		}

		if (c_DrawItems.GetBool())
		{
			s_left = String.Format("\cG%s", StringTable.Localize("$TXT_IMITEMS"));
			s_right = String.Format("\cD%d\c-/\cD%d", items, totalitems);
			DrawMapDataElement(s_left, s_right, hfnt, pos, flags, width, scale);
			pos.y+=fy;
		}

		if (c_DrawSecrets.GetBool())
		{
			s_left = String.Format("\cG%s", StringTable.Localize("$TXT_IMSECRETS"));
			s_right = String.Format("\cD%d\c-/\cD%d", secrets, totalsecrets);
			DrawMapDataElement(s_left, s_right, hfnt, pos, flags, width, scale);
			pos.y+=fy;
		}

		if (c_DrawTime.GetBool())
		{
			s_left = String.Format("\cG%s", StringTable.Localize("$TXT_IMTIME"));
			int h,m,s;
			[h,m,s] = TicsToHours(level.time);
			if (h > 0)
			{
				s_right = String.Format("\cD%d:%d:%d", h, m, s);
			}
			else
			{
				s_right = String.Format("\cD%d:%d", m, s);
			}
			DrawMapDataElement(s_left, s_right, hfnt, pos, flags, width, scale);
		}
	}

	// Draws the actual map element, consisting of a label
	// (left), a colon, and the value (right):
	void DrawMapDataElement(string str1, string str2, HUDFont hfnt, vector2 pos, int flags, double width, double scale = 1.0)
	{
		Font fnt = hfnt.mFont;
		// Scale the string down if it's too wide
		// to account for possible long localized
		// strings (I wish more games would do that):
		double strOfs = 3 * scale;
		double maxStrWidth = width*0.5 - strOfs;
		double strScale = scale;
		double strWidth = fnt.StringWidth(str1) * scale;
		if (strWidth > maxStrWidth)
		{
			strScale = scale * (maxStrWidth / strWidth);
		}
		DrawString(hfnt, str1, pos-(strOfs,0), flags|DI_TEXT_ALIGN_RIGHT, scale:(strScale,strScale));
		DrawString(hfnt, ":", pos, flags|DI_TEXT_ALIGN_CENTER, scale:(scale,scale));
		DrawString(hfnt, str2, pos+(strOfs,0), flags|DI_TEXT_ALIGN_LEFT, scale:(scale,scale));
	}

	int, int, int TicsToHours(int tics)
	{
		int totalSeconds = tics / TICRATE;
		int hours = (totalSeconds / 3600) % 60;
		int minutes = (totalSeconds / 60) % 60;
		int seconds = totalSeconds % 60;

		return hours, minutes, seconds;
	}

	override void DrawPowerups()
	{
		if (!c_drawPowerups || !c_drawPowerups.GetBool())
			return;
		if (!handler)
			return;

		int powerNum = handler.powerupData.Size();
		if (powerNum <= 0)
			return;

		int flags = SetScreenFlags(c_PowerupsPos.GetInt());
		vector2 ofs = ( c_PowerupsX.GetInt(), c_PowerupsY.GetInt() );
		double iconSize = 10;
		int indent = 0;
		HUDFont fnt = smallHUDFont;
		double textScale = 0.5;
		double fy = fnt.mFont.GetHeight() * textScale;
		double width = iconSize + indent;
		double height = (iconsize + indent) * powerNum + indent;
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		pos.y += iconSize*0.5;

		double textOfs = iconsize + indent;
		flags |=  DI_ITEM_CENTER;
		if ((flags & DI_SCREEN_RIGHT) == DI_SCREEN_RIGHT)
		{
			flags |= DI_TEXT_ALIGN_RIGHT;
			textOfs = -1;
		}
		for (int i = 0; i < powerNum; i++)
		{
			let pwd = handler.powerupData[i];
			if (!pwd)
				continue;
			let pow = Powerup(CPlayer.mo.FindInventory(pwd.powerupType));
			if (pow)
			{
				DrawTexture(pwd.icon, (pos.x + iconSize*0.5, pos.y), flags|DI_ITEM_CENTER, box:(iconSize, iconSize));
				// Account for infinite flight in singleplayer:
				if (!multiplayer && pow is 'PowerFlight' && Level.infinite_flight)
				{
					continue;
				}

				string s_time;
				int h,m,s;
				[h,m,s] = TicsToHours(pow.EffectTics);
				if (h > 0)
				{
					s_time = String.Format("%d:%d:%d", h, m, s);
				}
				else
				{
					s_time = String.Format("%d:%d", m, s);
				}
				DrawString(fnt, s_time, pos + (textOfs, -fy*0.5), flags|DI_TEXT_ALIGN_LEFT, alpha: pow.isBlinking() ? 0.5 : 1.0, scale:(textscale,textscale));
				pos.y += iconSize + indent;
			}
		}
	}

	void DrawKeys()
	{
		if (!c_drawKeys.GetBool())
			return;

		if (!CPlayer.mo.FindInventory('Key',true))
			return;

		int flags = SetScreenFlags(c_KeysPos.GetInt());
		vector2 ofs = ( c_KeysX.GetInt(), c_KeysY.GetInt() );
		double iconSize = 10;
		int indent = 1;
		double width;
		double height;

		int keyCount = Key.GetKeyTypeCount();
		int totalKeys;
		for (int i = 0; i < keyCount; i++)
		{
			let k = CPlayer.mo.FindInventory(Key.GetKeyType(i));
			if (k)
			{
				let icon = GetIcon(k,0);
				if (icon.IsValid() && TexMan.GetName(icon) != 'TNT1A0')
					totalKeys++;
			}
		}
		if (totalKeys <= 0)
			return;

		// Calculate the size of the key block
		// If there are 3 keys or fewer: columns = total keys, and rows = 1.
		// Otherwise, columns are square root of the total number 
		// of keys, ceil'd:
		int columns = totalKeys > 3 ? ceil(sqrt(totalkeys)) : totalKeys;
		// Rows are total number of keys / rows.
		// Don't forget to convert columns to double, so that the resulting
		// number is not truncated before it's ceil'd:
		int rows = totalKeys > 3 ? ceil(totalkeys / double(columns)) : 1;
		width = (iconsize + indent) * columns + indent;
		height = (iconsize + indent) * rows;

		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		Fill(GetBaseplateColor(), pos.x, pos.y, width, height, flags);

		pos += (iconsize*0.5+indent, iconsize*0.5+indent);
		vector2 kpos = pos;
		// Keep track of how many keys we've drawn horizontally,
		// so we can switch to new line when we've filled all
		// columns:
		int horKeys;
		for (int i = 0; i < keyCount; i++)
		{
			let k = CPlayer.mo.FindInventory(Key.GetKeyType(i));
			if (k)
			{
				let icon = GetIcon(k,0);
				if (!icon.IsValid() || TexMan.GetName(icon) == 'TNT1A0')
					continue;
				DrawTexture(icon, kpos, flags|DI_ITEM_CENTER, box:(iconSize, iconSize));
				horKeys++;
				// Keep going right if this isn't the final
				// column yet:
				if (horKeys < columns)
				{
					kpos.x += iconsize + indent;
				}
				// Otherwise Reached the final column - 
				// reset x pos and move y pos:
				else
				{
					horKeys = 0;
					kpos.x = pos.x;
					kpos.y += iconSize;
				}
			}
		}
	}

	double GetInvBarIconSize()
	{
		if (c_InvBarIconSize)
			return c_InvBarIconSize.GetInt();
		return ITEMBARICONSIZE;
	}

	// This draws a vaguely Silent Hill-style inventory bar,
	// where the selected item is in the center, and the other
	// items are drawn to the left and to the right of it.
	// The bar has no beginning or end and can be scrolled
	// infinitely:
	void DrawInventoryBar(int numfields = 7)
	{
		// Perform the usual checks first:
		if (!c_drawInvBar.GetBool())
			return;
		if (Level.NoInventoryBar)
			return;
		// This does something important to make sure
		// the first item in the list is valid:
		CPlayer.mo.InvFirst = ValidateInvFirst(numfields);
		if (!CPlayer.mo.InvFirst)
			return;
		// Cache the currently selected item:
		Inventory invSel = CPlayer.mo.InvSel;	
		if (!invSel)
			return;
		
		// Calculate the total number of items to display
		// and clamp the number of icons to that value:
		int totalItems;
		Inventory invFirst = CPlayer.mo.InvFirst;
		while (invFirst)
		{
			invFirst = invFirst.NextInv();
			totalItems++;
		}
		// The number of fields can't be larger than the
		// total number of items:
		numfields = Clamp(numfields, 1, totalItems);

		// Numfields must be an odd number. So, if the player
		// only has 2 items, they'll see the current item
		// in the center, and the next item both to the left
		// and to the right of it:
		if (numfields % 2 == 0)
		{
			numfields += 1;
		}
		int indent = 1;
		double iconSize = GetInvBarIconSize();
		int width = (iconSize + indent) * numfields - indent;
		int height = iconSize;

		// Validate position as usual:
		int flags = SetScreenFlags(c_InvBarPos.GetInt());
		vector2 ofs = ( c_InvBarX.GetInt(), c_InvBarY.GetInt());
		vector2 pos = AdjustElementPos((width*0.5, height*0.5), flags, (width, height), ofs);

		vector2 cursOfs = (-iconSize*0.5 - indent, -iconSize*0.5 - indent);
		vector2 cursPos = pos + cursOfs;
		vector2 cursSize = (iconsize + indent*2, indent); //width, height

		// Show some gray fill behind the central icon
		// (which is the selected item):
		color backCol = color(80, 255,255,255);
		Fill (backCol, cursPos.x, cursPos.y, cursSize.x, cursSize.x, flags);

		// Show gray gradient fill aimed to the left and right of
		// the selected item when the inventory bar is active,
		// to visually "open it up":
		if (IsInventoryBarVisible())
		{
			double alph = backCol.a;
			int steps = 8;
			double sizex = (width*0.5 - cursSize.x) / steps;
			double posx = cursPos.x + cursSize.x;
			for (int i = 0; i < steps; i++)
			{
				alph *= 0.75;
				Fill (color(int(alph), backCol.r, backCol.g, backCol.b), posx, cursPos.y, sizex, cursSize.x, flags);
				posx += sizex;
			}
			alph = backCol.a;
			posx = cursPos.x - sizex;
			for (int i = 0; i < steps; i++)
			{
				alph *= 0.75;
				Fill (color(int(alph), backCol.r, backCol.g, backCol.b), posx, cursPos.y, sizex, cursSize.x, flags);
				posx -= sizex;
			}
		}
		
		// Null-check prevInvSel (will only run once):
		if (!prevInvSel)
		{
			prevInvSel = invSel;
		}
		// Detect the player cycled through inventory:
		if (invSel != prevInvSel)
		{
			let prevNext = NextItem(prevInvSel);
			bool toNext = (invSel == prevNext);
			// Add positive or negative offsets to the icon:
			invbarCycleOfs = toNext ? iconSize : -iconSize;
			prevInvSel = invSel;
			if (c_AlwaysShowInvBar.GetBool())
			{
				CPlayer.inventoryTics = 0;
			}
		}

		// We'll draw 2 additional fields and hide them with
		// SetClipRects, so that the rightmost/leftmost icons
		// slide out of view gradually instead of disappearing:
		numfields += 2;
		int i = 0;
		vector2 itemPos = pos;
		// Adding this lets us interpolate icon position. Until the player
		// cycles through inventory, invbarCycleOfs is 0; otherwise it's
		// set to be the size of the icon and then tics down
		// (see UpdateInventoryBar):
		double itemPosXOfs = invbarCycleOfs;
		Inventory item = invSel;
		// Calculate the length of half of the bar (minus the selected item,
		// thus minus 1) - we'll draw this much in both directions:
		int maxField = ceil((numfields - 1) / 2);
		// Set up clip rectangle to hide the two edge icons:
		SetClipRect(pos.x - width*0.5, pos.y - height*0.5, width, height, flags);
		// Scale the font (indexfont is made for 32x32 icons, so divide
		// the current icon size by that value to get the right scale):
		double fntScale = iconSize / 32.;
		double fy = numHUDFont.mFont.GetHeight() * fntScale;
		while (item)
		{
			// Modify alpha and scale based on how far the icon is from the center:
			double alph = LinearMap(i, 0, maxField, 1.0, 0.5);
			// If an item is selected (invbar is inactive) but the "always show 
			// invbar" CVar is true, make all items except selected one more
			// translucent:
			if (i != 0 && !IsInventoryBarVisible() && c_AlwaysShowInvBar.GetBool())
			{
				alph *= 0.5;
			}
			double scaleFac = LinearMap(i, 0, maxField, 1.0, 0.55);
			double boxSize = iconSize * scaleFac;
			itemPos.x = pos.x + (iconSize + indent) * i + itemPosXOfs;
			TextureID icon = GetIcon(item, 0);
			// Scale the icons to fit into the box (but without breaking their
			// aspect ratio):
			vector2 size = TexMan.GetscaledSize(icon);
			double longside = max(size.x, size.y);
			double scaleToBoxFac = boxSize / longSide;
			DrawInventoryIcon(item, itemPos, flags|DI_ITEM_CENTER, alph, boxsize:(boxSize, boxSize), scale:(scaleToBoxFac,scaleToBoxFac));
			DrawString(numHUDFont, ""..item.amount, itemPos + (boxsize*0.5, boxsize*0.5 - fy), flags|DI_TEXT_ALIGN_RIGHT, Font.CR_Gold, alpha: alph, scale:(fntscale, fntscale));
			// If the bar is not visible, stop here:
			if (!IsInventoryBarVisible() && !c_AlwaysShowInvBar.GetBool())
			{
				break;
			}

			// Going right:
			if (maxfield > 0)
			{
				// Keep going right until the edge:
				if (i < maxField) 
				{
					i++;
					item = NextItem(item);
				}
				// reached right edge - move to the first item
				// to the left of selected, and flip maxfield
				// to negative, so we'll start going to the left:
				else
				{
					i = -1;
					maxfield *= -1;
					item = PrevItem(invSel);
				}
			}
			// going left:
			else 
			{
				// Keep going left until the edge:
				if (i > maxField)
				{
					item = PrevItem(item);
					i--;
				}
				// We've reached the edge, stop here:
				else
				{
					break;
				}
			}
		}
		ClearClipRect();

		// Draw the edges of the cursor:
		color cursCol = color(220, 80, 200, 60);
		// Top edges are always drawn:
		Fill (cursCol, cursPos.x, cursPos.y, cursSize.x, cursSize.y, flags); // top
		Fill (cursCol, cursPos.x, cursPos.y+cursSize.x-cursSize.y, cursSize.x, cursSize.y, flags); //bottom
		Fill (cursCol, cursPos.x, cursPos.y, cursSize.y, cursSize.x, flags); // left
		Fill (cursCol, cursPos.x+cursSize.x-cursSize.y, cursPos.y, cursSize.y, cursSize.x, flags); //right
	}

	void UpdateInventoryBar(int numfields = 7)
	{
		double iconSize = GetInvBarIconSize();
		if (invbarCycleOfs > 0)
		{
			invbarCycleOfs = Clamp(invbarCycleOfs - iconSize * 0.25, 0, invbarCycleOfs);
		}
		if (invbarCycleOfs < 0)
		{
			invbarCycleOfs = Clamp(invbarCycleOfs + iconSize * 0.25, invbarCycleOfs, 0);
		}
	}

	// Returns actual next item, or the item
	// at the start of the list if there's nothing:
	Inventory NextItem(Inventory item)
	{
		if (item.NextInv())
		{
			return item.NextInv();
		}
		Inventory firstgood = item;
		while (firstgood.PrevInv())
		{
			firstgood = firstgood.PrevInv();
		}
		return firstgood;
	}

	// Returns actual prev item, or the item
	// at the end of the list if there's nothing:
	Inventory PrevItem(Inventory item)
	{
		if (item.PrevInv())
		{
			return item.PrevInv();
		}
		Inventory lastgood = item;
		while (lastgood.NextInv())
		{
			lastgood = lastgood.NextInv();
		}
		return lastgood;
	}
}

class JGPUFH_PowerupData play
{
	TextureID icon;
	class<Inventory> powerupType;

	static JGPUFH_PowerupData Create(TextureID icon, class<Inventory> powerupType)
	{
		let pwd = JGPUFH_PowerupData(New("JGPUFH_PowerupData"));
		if (pwd)
		{
			pwd.icon = icon;
			pwd.powerupType = powerupType;
		}
		return pwd;
	}
}

// A simple container that saves a weapon class,
// its slot number and slot index:
class JGPUFH_WeaponSlotData ui
{
	int slot;
	array < class<Weapon> > weapons;

	static JGPUFH_WeaponSlotData Create(int slot)
	{
		let wsd = JGPUFH_WeaponSlotData(New("JGPUFH_WeaponSlotData"));
		{
			wsd.slot = slot;
		}
		return wsd;
	}
}

// Stores current angle and alpha for incoming damage markers:
class JGPUFH_DamageMarkerData ui
{
	double angle;
	double alpha;

	static JGPUFH_DamageMarkerData Create(double angle)
	{
		let hmd = JGPUFH_DamageMarkerData(New("JGPUFH_DamageMarkerData"));
		if (hmd)
		{
			hmd.angle = angle;
			hmd.alpha = Cvar.GetCvar("jgphud_DamageMarkersAlpha", players[consoleplayer]).GetFloat();
		}
		return hmd;
	}
}

// Since LineTrace (for some reason) is only play-scoped,
// a separate play-scoped thinker is needed per each
// player so that they could call LineTrace and detect
// if the player is looking at any enemy:
class JGPHUD_LookTargetController : Thinker
{
	PlayerPawn pp;
	Actor looktarget;
	int targetTimer;
	const TARGETDISPLAYTIME = TICRATE;

	override void Tick()
	{
		if (!pp)
		{
			Destroy();
			return;
		}
		FLineTraceData lt;
		pp.LineTrace(pp.angle, 2048, pp.pitch, offsetz: pp.height * 0.5 - pp.floorclip + pp.AttackZOffset*pp.player.crouchFactor, data:lt);
		if (lt.HitType == TRACE_HitActor)
		{
			let ha = lt.HitActor;
			if (ha && ha.bISMONSTER && ha.bSHOOTABLE && ha.health > 0)
			{
				looktarget = ha;
				targetTimer = TARGETDISPLAYTIME;
			}
		}
		if (looktarget && looktarget.health <= 0)
		{
			looktarget = null;
		}
		if (targetTimer > 0)
		{
			targetTimer--;
			if (targetTimer == 0)
			{
				looktarget = null;
			}
		}
	}
}

class JGPUFH_HudDataHandler : EventHandler
{
	ui JGPUFH_FlexibleHUD hud;
	array <JGPUFH_PowerupData> powerupData;
	transient CVar c_ScreenReddenFactor;

	bool IsVoodooDoll(PlayerPawn mo)
	{
		return !mo.player || !mo.player.mo || mo.player.mo != mo;
	}

	override void WorldThingDamaged(worldEvent e)
	{
		let pmo = PlayerPawn(e.thing);
		if (pmo)
		{
			if (!c_ScreenReddenFactor)
				c_ScreenReddenFactor = CVar.GetCvar('jgphud_ScreenReddenFactor', pmo.player);
			pmo.player.damageCount *= c_ScreenReddenFactor.GetFloat();

			let attacker = e.inflictor ? e.inflictor : e.damageSource;
			if (attacker)
			{
				EventHandler.SendInterfaceEvent(pmo.PlayerNumber(), "PlayerWasAttacked", Actor.DeltaAngle(pmo.AngleTo(attacker), pmo.angle));
			}
			else
			{
				for (int i = 0; i <= 360; i += 30)
				{
					EventHandler.SendInterfaceEvent(pmo.PlayerNumber(), "PlayerWasAttacked", i, 0);
				}
			}
		}

		if (e.thing.bSHOOTABLE && e.thing.bISMONSTER && e.thing.target)
		{
			pmo = PlayerPawn(e.thing.target);
			if (pmo)
			{
				EventHandler.SendInterfaceEvent(pmo.PlayerNumber(), "PlayerHitMonster");
			}
		}
	}

	// The weird hack that is meant to give icons to powerups
	// that have no icons defined (like the Doom powerups):
	override void WorldThingSpawned(worldEvent e)
	{
		// A wild PowerupGiver spawns!
		let pwrg = PowerupGiver(e.thing);
		if (pwrg)
		{
			// Get its powerupType field:
			let pwr = GetDefaultByType((class<Inventory>)(pwrg.powerupType));
			if (!pwr)
				return;
			
			// Check if that powerupType has a proper icon;
			// if so, we're good, so abort:
			TextureID icon = pwr.Icon;
			if (icon.isValid() && TexMan.GetName(icon) != 'TNT1A0')
				return;

			// Check if that powerup was already processed:
			JGPUFH_PowerupData pwd;
			let pwrCls = pwr.GetClass();
			for (int i = 0; i < powerupData.Size(); i++)
			{
				pwd = powerupData[i];
				if (pwd && pwd.powerupType == pwrCls)
					return;
			}
			
			// Try getting the icon for the powerup from its
			// PowerupGiver:
			icon = pwrg.icon;
			// If that didn't work, record the PowerupGiver's
			// spawn sprite as that powerup's icon:
			if (!icon.isValid() || TexMan.GetName(icon) == 'TNT1A0')
			{
				icon = pwrg.spawnState.GetSpriteTexture(0);
			}
			// In case of success, store it:
			if (icon.isValid())
			{
				pwd = JGPUFH_PowerupData.Create(icon, pwrCls);
				powerupData.Push(pwd);
			}
		}

		let pmo = PlayerPawn(e.thing);
		if (pmo && !IsVoodooDoll(pmo))
		{
			let ltc = New("JGPHUD_LookTargetController");
			if (ltc)
			{
				ltc.pp = pmo;
			}
		}
	}

	override void InterfaceProcess(consoleEvent e)
	{
		if (!e.isManual)
		{
			if (!hud)
				hud = JGPUFH_FlexibleHUD(StatusBar);
			if(e.name == "PlayerWasAttacked")
			{
				hud.UpdateAttacker(e.args[0]);
			}
			if (e.name == "PlayerHitMonster")
			{
				hud.RefreshReticleHitMarker();
			}
		}
	}
}