class JGPUFH_FlexibleHUD : EventHandler
{
	const ASPECTSCALE = 1.2;
	const CIRCLEANGLES = 360.0;
	const SQUARERADIUSFAC = 1.43;
	const STR_INVALID = "<invalid>";

	ui PlayerInfo CPlayer;
	ui bool gamePaused;
	ui transient CVar c_enable;

	ui HUDFont mainHUDFont;
	ui HUDFont smallHUDFont;
	ui HUDFont numHUDFont;

	ui double prevMSTime;
	ui double deltaTime;
	ui double fracTic;
	ui bool initDone;
	array <JGPUFH_PowerupData> powerupData;
	array <MapMarker> mapMarkers;
	bool levelUnloaded;

	// see SetScreenFlags():
	static const int ScreenFlags[] =
	{
		StatusBarCore.DI_SCREEN_LEFT_TOP,
		StatusBarCore.DI_SCREEN_CENTER_TOP,
		StatusBarCore.DI_SCREEN_RIGHT_TOP,

		StatusBarCore.DI_SCREEN_LEFT_CENTER,
		StatusBarCore.DI_SCREEN_CENTER,
		StatusBarCore.DI_SCREEN_RIGHT_CENTER,

		StatusBarCore.DI_SCREEN_LEFT_BOTTOM,
		StatusBarCore.DI_SCREEN_CENTER_BOTTOM,
		StatusBarCore.DI_SCREEN_RIGHT_BOTTOM
	};

	// Health/armor bars CVAR values:
	ui LinearValueInterpolator healthIntr;
	ui LinearValueInterpolator armorIntr;
	enum EDrawBars
	{
		DB_NONE,
		DB_DRAWNUMBERS,
		DB_DRAWBARS,
	}
	ui double healthAmount;
	ui double healthMaxAmount;
	ui double armAmount;
	ui double armMaxamount;
	ui bool hasHexenArmor;
	ui color armorColor;
	
	// Hexen armor data:
	const WEAKEST_HEXEN_ARMOR_PIECE = 3;
	ui TextureID hexenArmorIcons[WEAKEST_HEXEN_ARMOR_PIECE+1];
	ui bool hexenArmorSetupDone;

	// All ammo display:
	enum EAllAmmoDisplay
	{
		AA_None,
		AA_OwnedWeapons,
		AA_All,
	}

	// Damage markers:
	JGPUFH_DmgMarkerController dmgMarkerControllers[MAXPLAYERS];
	ui Shape2D dmgMarker;
	ui Shape2DTransform dmgMarkerTransf;
	ui TextureID dmgMarkerTex;

	// Hit (reticle) markers:
	ui Shape2D reticleHitMarker;
	ui double reticleMarkerAlpha;
	ui double reticleMarkerScale;
	ui Shape2DTransform reticleMarkerTransform;
	
	// Weapon slots
	const MAXWEAPONSLOTS = 10;
	const SLOTSDISPLAYDELAY = TICRATE * 2;
	ui array <JGPUFH_WeaponSlotData> weaponSlotData;
	ui int slotsDisplayTime;
	ui Weapon prevReadyWeapon;
	enum EWeapSlotsAlign
	{
		WA_HORIZONTAL,
		WA_VERTICAL,
		WA_VERTICALINV,
	}

	// Minimap
	const MAPSCALEFACTOR = 8.;
	ui array <Line> mapLines;
	ui array <Actor> radarMonsters;
	ui Shape2D minimapShape_Square;
	ui Shape2D minimapShape_Circle;
	ui Shape2D minimapShape_Arrow;
	ui Shape2DTransform minimapTransform;
	/*enum EMinimapDisplayModes
	{
		MD_NONE,
		MD_MAPONLY,
		MD_RADAR,
	}*/
	enum EMapEnemyDisplay
	{
		MED_NONE,
		MED_ALERTED,
		MED_ALL
	}

	// DrawInventoryBar():
	const ITEMBARICONSIZE = 28;
	ui Inventory prevInvSel;
	ui double invbarCycleOfs;

	// DrawCustomItems():	
	ui array < class<Inventory> > customItems;

	// DrawReticleBars():
	const MARKERSDELAY = TICRATE*2;
	const BARCOVERANGLE = 80.0;
	JGPUFH_LookTargetController lookControllers[MAXPLAYERS];
	ui Shape2D roundBars;
	ui Shape2D roundBarsAngMask;
	ui Shape2D roundBarsInnerMask;
	ui Shape2D genRoundMask;
	ui Shape2DTransform roundBarsTransform;
	ui Shape2DTransform genRoundMaskTransfInner;
	ui Shape2DTransform genRoundMaskTransfOuter;
	ui double prevArmAmount;
	ui double prevArmMaxAmount;
	ui int prevHealth;
	ui int prevMaxHealth;
	ui int prevAmmo1Amount;
	ui int prevAmmo1MaxAmount;
	ui int prevAmmo2Amount;
	ui int prevAmmo2MaxAmount;
	ui double reticleMarkersDelay[4];
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

	clearscope double LinearMap(double val, double source_min, double source_max, double out_min, double out_max, bool clampIt = false) 
	{
		double sourceDiff = (source_max - source_min);
		if (sourceDiff == 0)
			sourceDiff = 1;
		double d = (val - source_min) * (out_max - out_min) / sourceDiff + out_min;
		if (clampit) 
		{
			double truemax = out_max > out_min ? out_max : out_min;
			double truemin = out_max > out_min ? out_min : out_max;
			d = Clamp(d, truemin, truemax);
		}
		return d;
	}

	clearscope bool IsVoodooDoll(PlayerPawn mo)
	{
		return !mo.player || !mo.player.mo || mo.player.mo != mo;
	}
	
	override void WorldThingSpawned(worldEvent e)
	{
		// A wild PowerupGiver spawns!
		let pwrg = PowerupGiver(e.thing);
		if (pwrg)
		{
			JGPUFH_PowerupData.CreatePowerupIcon(pwrg, powerupData);
		}

		let mm = MapMarker(e.thing);
		if (mm)
		{
			mapMarkers.Push(mm);
		}
	}

	override void PlayerSpawned(playerEvent e)
	{
		int i = e.PlayerNumber;
		if (!PlayerInGame[i])
			return;
		PlayerInfo player = players[i];
		PlayerPawn pmo = player.mo;
		if (pmo && !IsVoodooDoll(pmo))
		{
			let ltc = JGPUFH_LookTargetController.Create(pmo);
			if (ltc)
			{
				if (jgphud_debug)
					Console.PrintF("Initializing \cDLookTargetController\c- for player #%d", i);
				lookControllers[i] = ltc;
			}

			let dmc = JGPUFH_DmgMarkerController.Create(player);
			if (dmc)
			{
				if (jgphud_debug)
					Console.PrintF("Initializing \cDDmgMarkerController\c- for player #%d", i);
				dmgMarkerControllers[i] = dmc;
			}
		}
	}

	// This field only really has one purpose: it's checked
	// in ShouldDrawMinimap() to make sure the level is still
	// valid and loaded. If this isn't done, the array of
	// linedefs obtained with BlockLinesIterator may not be
	// properly garbage-collected upon level unload (e.g.
	// when moving from stats/intermission to next map),
	// and DrawMinimapLines() may still try to iterate over
	// it, resulting in a null abort or sometimes even a
	// hard crash:
	override void WorldUnloaded(worldEvent e)
	{
		levelUnloaded = true;
	}

	override void WorldThingDamaged(worldEvent e)
	{
		let pmo = PlayerPawn(e.thing);
		// Handle damage markers:
		if (pmo && pmo.player)
		{
			// Modify player's red screen tint based on
			// the value of the CVAR:
			CVar fac = CVar.GetCvar('jgphud_ScreenReddenFactor', pmo.player);
			pmo.player.damageCount *= fac.GetFloat();

			// Damage came from an attacker:
			int pn = pmo.PlayerNumber();
			let dmc = dmgMarkerControllers[pn];
			if (dmc)
			{
				int damage = e.Damage;
				// If self damage, point to the inflictor (projectile)
				// instead of the source:
				Actor attacker = e.damageSource == pmo ? e.inflictor : e.damageSource;
				if (attacker)
				{
					dmc.AddMarker(attacker, 0, damage);
				}
				// Damage came from the world - draw a circle
				// of damage markers:
				else
				{
					for (int i = 0; i <= 360; i += 30)
					{
						dmc.AddMarker(null, i, damage);
					}
				}
			}
		}

		// Player hit a monster:
		if (e.thing.bSHOOTABLE && e.thing.bISMONSTER && e.thing.target)
		{
			pmo = PlayerPawn(e.thing.target);
			if (pmo)
			{
				EventHandler.SendInterfaceEvent(pmo.PlayerNumber(), "PlayerHitMonster", e.thing.health <= 0);
			}
		}
	}

	override void InterfaceProcess(consoleEvent e)
	{
		if (e.isManual)
			return;
		if (e.name == "PlayerHitMonster")
		{
			RefreshEnemyHitMarker(e.args[0]);
		}
	}

	// Updates delta time to allow for sub-tic interpolation
	// of values that are updated per tic. Must be called
	// in RenderOverlay unconditionally:
	ui void UpdateDeltaTime()
	{
		if (!prevMSTime)
			prevMSTime = MSTimeF();

		double ftime = MSTimeF() - prevMSTime;
		prevMSTime = MSTimeF();
		double dtime = 1000.0 / TICRATE;
		deltaTime = (ftime / dtime);
	}

	ui void UiInit()
	{
		if (initDone)
			return;
		
		smallHUDFont = HUDFont.Create(newConsoleFont, shadowx: -1, shadowy: -1);
		Font fnt = "Confont";
		mainHUDFont = HUDFont.Create(fnt);
		fnt = "IndexFont";
		numHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true);
		
		GetCustomItemsList();

		initDone = true;
	}

	override void UiTick()
	{
		if (!CPlayer || !CPlayer.mo)
			return;

		UpdateWeaponSlots();
		UpdateMinimapLines();
		UpdateEnemyRadar();
		UpdateInterpolators();
	}

	override void RenderOverlay(renderEvent e)
	{
		// Cache CVars before anything else:
		CacheCvars();
		UpdateDeltaTime();
		fracTic = e.fracTic;
		if (!c_enable.GetBool())
		{
			return;
		}
		if (!CPlayer || !CPlayer.mo)
		{
			return;
		}
		if (CPlayer.camera != CPlayer.mo)
		{
			return;
		}

		UiInit();
		statusbar.BeginHUD();
		// These value updates need to be interpolated
		// with framerate, so they happen here rather
		// than in UiTick(). They also shouldn't
		// progress if a menu is open:
		gamePaused = Menu.GetCurrentMenu();
		if (!gamePaused)
		{
			UpdateHealthArmor();
			UpdateInventoryBar();
			UpdateReticleBars();
			UpdateEnemyHitMarker();
		}
		
		DrawDamageMarkers();
		DrawHealthArmor();
		DrawWeaponBlock();
		DrawAllAmmo();
		DrawWeaponSlots();
		DrawMinimap();
		DrawPowerups();
		DrawKeys();
		DrawInventoryBar();
		DrawEnemyHitMarker();
		DrawReticleBars();
		DrawCustomItems();
	}

	// Adjusts position of the element so that it never ends up
	// outside the screen. It also flips X and Y offset values
	// if the edge is at the bottom/right, so that positive
	// values are always aimed inward, and negative values cannot
	// take the element outside the screen.
	// If 'real' is true, returns real screen coordinates multiplied
	// by hudscale, rather than StatusBar coordinates.
	ui vector2 AdjustElementPos(vector2 pos, int flags, vector2 size, vector2 ofs = (0,0), bool real = false)
	{
		vector2 screenSize = (0,0);
		vector2 hudscale = statusbar.GetHudScale();
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
		bool hCenter = ((flags & StatusBarCore.DI_SCREEN_HCENTER) == StatusBarCore.DI_SCREEN_HCENTER);
		bool vCenter = ((flags & StatusBarCore.DI_SCREEN_VCENTER) == StatusBarCore.DI_SCREEN_VCENTER);
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
			if ((flags & StatusBarCore.DI_SCREEN_BOTTOM) == StatusBarCore.DI_SCREEN_BOTTOM)
			{
				pos.y += -size.y + screenSize.y;
				if (ofs.y > 0)
					ofs.y = -abs(ofs.y);
				else
					ofs.y = 0;
			}
			// This has to explicitly exclude all other flags:
			else if ((flags & StatusBarCore.DI_SCREEN_TOP) == StatusBarCore.DI_SCREEN_TOP && !vCenter)
			{
				if (ofs.y < 0)
					ofs.y = 0;
			}

			if ((flags & StatusBarCore.DI_SCREEN_RIGHT) == StatusBarCore.DI_SCREEN_RIGHT)
			{
				pos.x += -size.x + screenSize.x;
				if (ofs.x > 0)
					ofs.x = -abs(ofs.x);
				else
					ofs.x = 0;
			}
			// This has to explicitly exclude all other flags:
			else if ((flags & StatusBarCore.DI_SCREEN_LEFT) == StatusBarCore.DI_SCREEN_LEFT && !hCenter)
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

	ui vector2 ScaleToBox(TextureID tex, double squareSize)
	{
		vector2 size = TexMan.GetScaledSize(tex);
		double longside = max(size.x, size.y);
		double s = squareSize / longSide;
		return (s,s);
	}

	// A CVar value should be passed here to return appropriate flags:
	ui int SetScreenFlags(int val)
	{
		val = Clamp(val, 0, ScreenFlags.Size() - 1);
		return ScreenFlags[val];
	}

	// Returns the color (or texture, is available)
	// and the alpha for the background fill:
	ui color, TextureID, double GetHUDBackground()
	{
		double alpha = Clamp(c_BackAlpha.GetFloat(), 0., 1.);

		int a = 255 * alpha;
		color c = c_BackColor.GetInt();
		color col = color(a, c.r, c.g, c.b);

		TextureID tex;
		tex.SetInvalid();
		// Check if the player set a texture to be used for
		// the background via the jgphud_BackTexture CVAR:
		if (!c_BackStyle.GetBool())
		{
			string texname = c_BackTexture.GetString();
			if (texname != STR_INVALID)
			{
				tex = TexMan.CheckForTexture(texname);
				if (!tex.IsValid())
				{
					c_BackTexture.SetString(STR_INVALID);
				}
			}
		}

		return color(a, col.r, col.g, col.b), tex, alpha;
	}

	// Draws a flat background fill or a texture fill,
	// if a valid texture was set by the player
	// via the jgphud_BackTexture CVAR:
	ui void BackgroundFill(double xPos, double yPos, double width, double height, int flags, color fillcol = color(0,0,0,0))
	{
		color col;
		TextureID tex;
		double alpha;
		[col, tex, alpha] = GetHUDBackground();
		if (fillcol.a != 0)
		{
			col = fillcol;
		}
		
		// Draw flat color fill:
		if (c_BackStyle.GetBool() || !tex || !tex.IsValid())
		{
			statusbar.Fill(col, xPos, yPos, width, height, flags);
			return;
		}

		// Otherwise draw a texture, tiled and slightly scaled:
		flags |= StatusBarCore.DI_ITEM_LEFT_TOP|StatusBarCore.DI_FORCEFILL;
		color texCol = fillcol.a == 0 ? 0xffffffff : fillcol;
		vector2 box = (width, height);
		vector2 pos = (xPos, yPos);
		
		// Stretch to fit mode:
		if (c_BackTextureStretch.GetBool())
		{
			statusbar.DrawTexture(tex, pos, flags, alpha, box, col: texCol);
			return;
		}
		
		// Otherwise tile the texture:

		// Get texture size and aspect ratio:
		vector2 size = TexMan.GetScaledSize(tex);
		double texaspect = size.x / size.y;
		// If the bos is wider than it is tall:
		if (width >= height)
		{
			// Stretch the texture to the box's height vertically:
			box.y = height;
			// Modify its width relatively:
			box.x = box.y * texaspect;
			// How many instances of the texture would fit WHOLLY
			// in the specified box:
			int steps = Clamp(width / box.x, 1, 1000);
			// Modify width slightly so that the textures will fit
			// in the box without clipping mid-texture:
			box.x = width / steps;
			
			// Draw the texture the necessary number of times:
			for (int i = 0; i < steps; i++)
			{
				statusbar.DrawTexture(tex, pos, flags, alpha, box, col: texCol);
				pos.x += box.x;
			}
		}
		// Otherwise do the same but vertically
		// instead of horizontally:
		else
		{
			box.x = width;
			box.y = box.x / texaspect;
			int steps = Clamp(height / box.y, 1, 1000);
			box.y = height / steps;
			for (int i = 0; i < steps; i++)
			{
				statusbar.DrawTexture(tex, pos, flags, alpha, box, col: texCol);
				pos.y += box.y;
			}
		}
	}

	// Returns a value that pulses using a sine wave,
	// optionally, with a range specified. If inMenus
	// argument is true, it'll also pulse while a menu
	// is open (the game is paused):
	ui double SinePulse(double frequency = TICRATE, double startVal = 0.0, double endVal = 1.0, double inMenus = false)
	{
		//return 0.5 + 0.5 * sin(360.0 * deltatime / (frequency*1000.0));
		double time = (inMenus && gamePaused) ? Menu.MenuTime() : Level.mapTime;
		double pulseVal = 0.5 + 0.5 * sin(360.0 * (time + fracTic) / frequency);
		return LinearMap(pulseVal, 0.0, 1.0, startVal, endVal);
	}

	// Returns true if the menu belonging to the
	// specified class is currently open:
	ui bool IsMenuOpen(class<Object> menuname)
	{
		let mnu = Menu.GetCurrentMenu();
		return mnu && mnu is menuname;
	}

	// Wrappers to enable and disable stencil masks:
	ui void EnableMask(int ofs, Shape2D mask)
	{
		Screen.EnableStencil(true);
		Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
		Screen.DrawShapeFill(color(0,0,0), 1, mask);
		Screen.SetStencil(ofs, SOP_Keep, SF_AllOn);
	}

	ui void DisableMask()
	{
		Screen.EnableStencil(false);
		Screen.ClearStencil();
	}

	// Draws a bar using Fill()
	// If segments is above 0, will use multiple fills to create a segmented bar
	ui void DrawFlatColorBar(vector2 pos, double curValue, double maxValue, color barColor, string leftText = "", string rightText = "", int valueColor = -1, double barwidth = 64, double barheight = 8, double indent = 0.6, color backColor = color(255, 0, 0, 0), double sparsity = 1, uint segments = 0, int flags = 0)
	{
		vector2 barpos = pos;
		// This flag centers the bar vertically. I didn't add
		// horizontal centering because it felt useless, since
		// all bars in the HUD go from left to right:
		if (flags & StatusBarCore.DI_ITEM_CENTER)
		{
			barpos.y -= barheight*0.5;
		}

		if (leftText)
		{
			statusbar.DrawString(mainHUDFont, leftText, barpos, flags|StatusBarCore.DI_TEXT_ALIGN_RIGHT);
		}

		// Background color (fills whole width):
		statusbar.Fill(backColor, barpos.x, barpos.y, barwidth, barheight, flags);
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
				statusbar.Fill(col, segPos.x, segPos.y, segW, innerBarHeight, flags);
				segPos.x += singleSegWidth + sparsity;
			}
		}
		else
		{
			statusbar.Fill(barColor, innerBarPos.x, innerBarPos.y, curInnerBarWidth, innerBarHeight, flags);
		}

		// If value color is provided, draw the current value
		// in the middle of the bar:
		if (valueColor != -1)
		{
			double fy = numHUDFont.mFont.GetHeight();
			fy = Clamp(fy, 2, barheight);
			statusbar.DrawString(numHUDFont, ""..int(curvalue), barpos + (barwidth * 0.5, barheight * 0.5 - fy * 0.5), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: valueColor);
		}
		
		if (rightText)
		{
			statusbar.DrawString(mainHUDFont, ""..rightText, barpos + (barwidth + 1, 0), flags|StatusBarCore.DI_TEXT_ALIGN_LEFT);
		}
	}

	// Returns a color and font colors based on the provided
	// percentage value (either in the 0.0-1.0 or 0-100 range).
	// Meant to be used for armor's savepercent, so it's tuned
	// to common savepercent values (50, 80 and 33):
	clearscope int, int, int, int GetArmorColor(double savePercent)
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

	clearscope int GetPercentageFontColor(int amount, int maxamount)
	{
		if (amount >= maxamount * 0.75)
			return Font.CR_Green;
		if (amount >= maxamount * 0.5)
			return Font.CR_Yellow;
		if (amount >= maxamount * 0.25)
			return Font.CR_Orange;
		return Font.CR_Red;
	}

	// Cache existing icons for Hexen armor classes
	// On the off chance somebody is crazy enough to
	// create their own Hexen armor pickups...
	// Hexen armor is split into five tiers, 0 being the strongest,
	// and 4 being the weakest  Tiers 0-3 are pickups and have associated items;
	// while 4 is your natural armor and you always have it.
	// Since tier 4 is not a pickup, we're not going to try and find
	// the icon for it.
	ui void SetupHexenArmorIcons()
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

	ui void UpdateInterpolators()
	{
		if (healthIntr)
			healthIntr.Update(CPlayer.mo.health);
		if (armorIntr)
			armorIntr.Update(armAmount);
	}

	ui double GetHealthInterpolated()
	{
		if (!healthIntr)
			healthIntr = LinearValueInterpolator.Create(healthMaxAmount, 1);
		return healthIntr.GetValue();
	}

	ui double GetArmorInterpolated()
	{
		if (!armorIntr)
			armorIntr = LinearValueInterpolator.Create(armMaxAmount, 1);
		return armorIntr.GetValue();
	}

	// This is meant to be called unconditionally
	// to get health and armor values, so that
	// they can be checked by other functions.
	// Moved here because obtaining armor amount
	// is a multi-step process, so it's easier
	// to do separately:
	ui void UpdateHealthArmor()
	{
		if (!CPlayer.mo)
			return;

		healthAmount = CPlayer.mo.health;
		healthMaxAmount = CPlayer.mo.GetMaxHealth(true);

		// Check if armor exists and is above 0
		let barm = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		let hexarm = HexenArmor(CPlayer.mo.FindInventory("HexenArmor"));
		armMaxamount = 100;
		hasHexenArmor = false;
		int r,g,b;
		if (barm)
		{
			armAmount = barm.amount;
			armMaxAmount = barm.maxamount;
			[r,g,b] = GetArmorColor(barm.savePercent);
			armorColor = color(r, g, b);
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
				armMaxAmount = 100;
				[r,g,b] = GetArmorColor(barm.savePercent);
				armorColor = color(r, g, b);
			}
		}
	}

	ui void DrawHealthArmor(double height = 28, double width = 120)
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
		int baseCol = GetHUDBackground();
		// bars background:
		BackgroundFill(pos.x, pos.y, mainBlockWidth, height, flags);
		// face background (draw separately because there's
		// a small indent between this and the bars background):
		if (drawFace)
		{
			vector2 facePos = (pos.x + mainBlockWidth + indent, pos.y);
			BackgroundFill(facePos.x, facePos.y, faceSize, faceSize, flags);
			statusbar.DrawTexture(statusBar.GetMugShot(5), (facePos.x + faceSize*0.5, facePos.y + faceSize*0.5), flags|StatusBarCore.DI_ITEM_CENTER, box: (faceSize - 2, faceSize - 2));
		}

		int barFlags = flags|StatusBarCore.DI_ITEM_CENTER;
		indent = 4;
		double iconSize = 8;
		vector2 iconPos = (pos.x + indent + iconsize * 0.5, pos.y + height*0.75);

		// Draw health cross shape (instead of drawing a health item):
		bool hasBerserk = CPlayer.mo.FindInventory('PowerStrength', true);
		double crossWidth = 4;
		double crossLength = 10;
		vector2 crossPos = iconPos;
		color crossCol = hasBerserk ? color(255,255,0,0) : color(255,0,0,0);
		statusbar.Fill(crossCol, crossPos.x - crossWidth*0.5,  crossPos.y - crossLength*0.5, crossWidth, crossLength, barFlags);
		statusbar.Fill(crossCol, crossPos.x - crossLength*0.5, crossPos.y - crossWidth*0.5, crossLength, crossWidth, barFlags);
		
		crossWidth -= hasBerserk ? 1.5 : 2;
		crossLength -= hasBerserk ? 1.5 : 2;
		crossCol = hasBerserk ? color(255,0,0,0) : color(255,255,255,255);
		statusbar.Fill(crossCol, crossPos.x - crossWidth*0.5, crossPos.y - crossLength*0.5, crossWidth, crossLength, barFlags);
		statusbar.Fill(crossCol, crossPos.x - crossLength*0.5, crossPos.y - crossWidth*0.5,  crossLength, crossWidth, barFlags);
		
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
			DrawFlatColorBar((barPosX, iconPos.y), GetHealthInterpolated(), maxhealth, color(200, 255, 255, 255), barwidth:barWidth, barheight: 10, flags:barFlags);
			DrawFlatColorBar((barPosX, iconPos.y), health, maxhealth, color(255, cRed, cGreen, cBlue), "", valueColor: Font.CR_White, barwidth:barWidth, barheight: 10, backColor: color(0,0,0,0), flags:barFlags);
		}
		else
		{
			statusbar.DrawString(mainHUDFont, String.Format("%3d", health), (barPosX, iconPos.y - fy*0.5), flags, translation:GetPercentageFontColor(health,maxhealth));
		}
		
		// Draw armor bar:
		// Check if armor exists and is above 0
		let barm = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		let hexarm = HexenArmor(CPlayer.mo.FindInventory("HexenArmor"));
		TextureID armTex;
		double armTexSize = 12;
		if (!hasHexenArmor && barm)
		{
			[cRed, cGreen, cBlue, cFntCol] = GetArmorColor(barm.savePercent);
			armTex = barm.icon;
		}
		if (hasHexenArmor && hexArm)
		{
			[cRed, cGreen, cBlue, cFntCol] = GetArmorColor(armAmount / armMaxAmount);
		}

		if (armAmount > 0)
		{
			iconPos.y = pos.y + height * 0.25;
			string ap = "AP";
			// uses Hexen armor:
			if (hasHexenArmor)
			{
				// Build an array of icons from the array previously
				// set up by SetupHexenArmorIcons():
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
						statusbar.DrawTexture(armTex, iconPos, flags|StatusBarCore.DI_ITEM_CENTER, box:(armTexSize,armTexSize));
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
							statusbar.DrawTexture(armTex, armPos, flags|StatusBarCore.DI_ITEM_CENTER, box:(armTexSize,armTexSize));
						}
					}
				}
			}

			// uses normal armor:
			else if (armTex.IsValid())
			{
				ap = "";
				statusbar.DrawTexture(armTex, iconPos, flags|StatusBarCore.DI_ITEM_CENTER, box:(armTexSize,armTexSize));
			}

			if (drawbars)
			{
				DrawFlatColorBar((barPosX, iconPos.y), GetArmorInterpolated(), armMaxamount, color(200, 255, 255, 255), barwidth:barWidth, barheight: 6, segments: barm.maxamount / 10, flags:barFlags);
				DrawFlatColorBar((barPosX, iconPos.y), armAmount, armMaxamount, color(255, cRed, cGreen, cBlue), ap, valueColor: Font.CR_White, barwidth:barWidth, barheight: 6, backColor: color(0,0,0,0), segments: barm.maxamount / 10, flags:barFlags);
			}
			else
			{
				statusbar.DrawString(mainHUDFont, String.Format("%3d", armAmount), (barPosX, iconPos.y - fy*0.5), flags, translation:cFntCol);
			}
		}
	}

	clearscope color GetAmmoColor(Ammo am)
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

	ui void DrawWeaponBlock()
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
		[am1, am2, am1amt, am2amt] = statusbar.GetCurrentAmmo();

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
		TextureID weapIcon = statusbar.GetIcon(weap, StatusBarCore.DI_FORCESCALE);
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
		BackgroundFill(pos.x, pos.y, size.x, size.y, flags);
		
		if (weapIconValid)
		{
			statusbar.DrawTexture(weapIcon, pos + (weapIconBox.x  * 0.5 + indent, size.y - weapIconBox.y * 0.5 - indent), flags|StatusBarCore.DI_ITEM_CENTER, box: (64, 18));
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
		int segments;

		// Uses only 1 ammo type - draw as calculated:
		if ((am1 && !am2) || (!am1 && am2) || (am1 == am2))
		{
			Ammo am = am1 ? am1 : am2;
			statusbar.DrawInventoryIcon(am, ammo1pos, flags|StatusBarCore.DI_ITEM_CENTER, boxSize: ammoIconBox);
			statusbar.DrawString(mainHUDFont, ""..am.amount, ammoTextPos, flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am.amount, am.maxamount));
			if (drawAmmobar)
			{
				segments = am.maxamount <= 20 ? am.maxamount : Clamp(am.maxamount / 10.0, 20, 50);
				DrawFlatColorBar(ammoBarPos, am.amount, am.maxamount, GetAmmoColor(am), barwidth: barwidth, barheight: ammoBarHeight, segments: segments, flags: flags);
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
			statusbar.DrawInventoryIcon(am1, ammo1pos, flags|StatusBarCore.DI_ITEM_CENTER, boxSize: ammoIconBox);
			statusbar.DrawString(mainHUDFont, ""..am1amt, (ammo1pos.x, ammoTextPos.y), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am1.amount, am1.maxamount));
			statusbar.DrawInventoryIcon(am2, ammo2pos, flags|StatusBarCore.DI_ITEM_CENTER, boxSize: ammoIconBox);
			statusbar.DrawString(mainHUDFont, ""..am2amt, (ammo2pos.x, ammoTextPos.y), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am2.amount, am2.maxamount));
			if (drawAmmobar)
			{
				segments = am1.maxamount <= 10 ? am1.maxamount : Clamp(am1.maxamount / 20.0, 10, 25);
				DrawFlatColorBar(ammoBarPos, am1.amount, am1.maxamount, GetAmmoColor(am1), barwidth: barwidth, barheight: ammoBarHeight, segments: segments, flags: flags);

				ammoBarPos.x = ammo2Pos.x - barWidth*0.5;
				segments = am2.maxamount <= 10 ? am2.maxamount : Clamp(am2.maxamount / 20.0, 10, 25);
				DrawFlatColorBar(ammoBarPos, am2.amount, am2.maxamount, GetAmmoColor(am2), barwidth: barwidth, barheight: ammoBarHeight, segments: segments, flags: flags);
			}
		}
	}

	// Draws a list of all ammo ordered by weapon slots,
	// akin to althud:
	ui void DrawAllAmmo()
	{
		int mode = c_drawAllAmmo.GetInt();
		if (mode <= AA_None)
			return;

		double iconSize = 6;
		int indent = 1;
		int flags = SetScreenFlags(c_AllAmmoPos.GetInt());
		vector2 ofs = ( c_AllAmmoX.GetInt(), c_AllAmmoY.GetInt() );
		let hfnt = mainHUDFont;
		double fntScale = 0.6;
		double fy = hfnt.mFont.GetHeight() * fntScale;
		double width = iconsize + indent*2 + mainHUDFont.mFont.StringWidth("000/000") * fntScale;
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
				if (!weap)
					continue;
				int added = AddWeaponAmmoToList(weap, ammoItems, mode);
				height += (iconsize + indent) * added;
			}
		}

		// Now add ammo for weapons that are not bound to any
		// slots, if any exist in player's inventory:
		for (let item = CPlayer.mo.Inv; item; item = item.Inv)
		{
			if (!item)
				continue;
			if (item is 'Weapon')
			{
				class<Weapon> weap = (class<Weapon>)(item.GetClass());
				int added = AddWeaponAmmoToList(weap, ammoItems, mode);
				height += (iconsize + indent) * added;
			}
		}

		if (ammoItems.Size() <= 0)
			return;

		// Finally, draw the ammo:
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		// Get current HUD background color
		// and current weapon's ammo:
		color col = GetHUDBackground();
		Ammo a1, a2;
		[a1, a2] = statusbar.GetCurrentAmmo();
		for (int i = 0; i < ammoItems.Size(); i++)
		{			
			Ammo am = ammoItems[i];
			if (!am)
				continue;
			// Draw color fill behind the ammo if it matches
			// the currently used weapon:
			if (am == a1 || am == a2)
			{
				statusbar.Fill(color(128, 255 - col.r, 255 - col.g, 255 - col.b), pos.x, pos.y, width, iconSize, flags);
			}
			// Draw ammo:
			statusbar.DrawInventoryIcon(am, pos + (iconSize*0.5,iconSize*0.5), flags|StatusBarCore.DI_ITEM_CENTER, boxsize:(iconSize, iconSize));
			statusbar.DrawString(hfnt, 
				String.Format("%3d\cJ/\c-%3d", am.amount, am.maxamount), 
				pos + (iconSize + indent, iconsize*0.5 -fy*0.5), 
				flags|StatusBarCore.DI_TEXT_ALIGN_LEFT, 
				translation: GetPercentageFontColor(am.amount, am.maxamount), 
				scale:(fntScale,fntScale)
			);
			pos.y += max(fy, iconsize) + indent;
		}
	}

	// Adds pointers to ammotypes in the player's inventory
	// used by the specified weapon class in the specified
	// array, and returns how many classes have been added:
	ui int AddWeaponAmmoToList(class<Weapon> weap, out array <Ammo> ammoItems, int mode = AA_All)
	{
		class<Ammo> am1, am2;
		// Depending on player's settings, they may want to see
		// ammo for all weapons, even if they don't currently
		// have that weapon. However, first we'll always try
		// to read ammo off the weapon in their inventory,
		// because ammotype1/ammotype2 fields are directly
		// writable, and some mods may change weapon's ammo types
		// on the fly:
		let ownedWeap = Weapon(CPlayer.mo.FindInventory(weap));
		// The player has that weapon:
		if (ownedWeap)
		{
			am1 = ownedWeap.ammoType1;
			am2 = ownedWeap.ammoType2;
		}
		// The player doesn't have that weapon:
		else
		{
			// If they don't want to see ammo for weapons they
			// don't have, stop here:
			if (mode == AA_OwnedWeapons)
				return 0;
			// Otherwise get the weapon's defaults and read
			// ammo types from that:
			let defWeap = GetDefaultByType((class<Weapon>)(weap));
			if (!defWeap)
				return 0;
			am1 = defWeap.ammoType1;
			am2 = defWeap.ammoType2;
		}
		// If ammo types are not defined, stop here:
		if (!am1 && !am2)
			return 0;

		// Iterate over both ammo types:
		Ammo am;
		int added;
		for (int i = 0; i < 2; i++)
		{
			// Obviously, ammo can only be displayed if the player
			// has an instance of it in their inventory (even if
			// its amount is 0 and/or they don't have a weapon
			// that can use said ammo):
			am = Ammo(CPlayer.mo.FindInventory(i == 0 ? am1 : am2));
			if (!am)
				continue;
			if (!c_AllAmmoShowDepleted.GetBool() && am.amount <= 0)
				continue;
			if (ammoItems.Find(am) != ammoItems.Size())
				continue;
			TextureID icon = statusbar.GetIcon(am, 0);
			if (!icon.IsValid())
				continue;
			added++;
			ammoItems.Push(am);
		}
		return added;
	}

	// Draws a list of custom items from the ITEMINFO lump:
	ui void DrawCustomItems()
	{
		if (!c_DrawCustomItems.GetBool())
			return;

		int itemNum;
		for (int i = 0; i < customItems.Size(); i++)
		{
			let item = customItems[i];
			if (item && CPlayer.mo.FindInventory(item))
			{
				itemNum++;
			}
		}
		if (itemNum <= 0)
			return;

		double iconSize = Clamp(c_CustomItemsIconSize.GetFloat(), 4, 64);
		int indent = 1;
		int flags = SetScreenFlags(c_CustomItemsPos.GetInt());
		vector2 ofs = ( c_CustomItemsX.GetInt(), c_CustomItemsY.GetInt() );
		let hfnt = smallHUDFont;
		double fntScale = iconSize * 0.025;
		double fy = hfnt.mFont.GetHeight() * fntScale;
		double width = iconsize + indent*4 + hfnt.mFont.StringWidth("000/000") * fntScale;
		double height = itemNum * (iconsize + indent);

		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		BackGroundFill(pos.x, pos.y, width, height, flags);

		for (int i = 0; i < customItems.Size(); i++)
		{
			let it = customItems[i];
			if (!it)
				continue;
			let item = CPlayer.mo.FindInventory(it);
			if (!item)
				continue;
			statusbar.DrawInventoryIcon(item, pos + (iconSize*0.5,iconSize*0.5), flags|StatusBarCore.DI_ITEM_CENTER, scale:ScaleToBox(item.icon, iconSize));
			statusbar.DrawString(hfnt, String.Format("%3d/%3d", item.amount, item.maxamount), pos + (iconSize + indent, iconsize*0.5 -fy*0.5), flags|StatusBarCore.DI_TEXT_ALIGN_LEFT, translation: GetPercentageFontColor(item.amount, item.maxamount), scale:(fntScale,fntScale));
			pos.y += max(fy, iconsize) + indent;
		}
	}

	ui void GetCustomItemsList()
	{
		int cl = Wads.FindLump("ITEMINFO");
		while (cl != -1)
		{
			string lumpData = Wads.ReadLump(cl);
			//lumpData = lumpData.MakeLower();
			// strip comments:
			int commentPos = lumpData.IndexOf("//");
			lumpdata = JGPUFH_StringMan.RemoveComments(lumpdata);
			lumpData = JGPUFH_StringMan.CleanWhiteSpace(lumpdata, true);
			if (jgphud_debug)
				Console.Printf("\cDITEMINFO\c- Full contents (cleaned): [%s]", lumpData);
			// Unite duplicate linebreaks, if any:
			while (lumpData.IndexOf("\n\n") >= 0)
			{
				lumpData.Replace("\n\n", "\n");
			}
			int searchPos = 0;
			int fileEnd = lumpdata.Length();
			while (searchPos >= 0 && searchPos < fileEnd)
			{
				int lineEnd = lumpData.IndexOf("\n", searchPos);
				if (lineEnd < 0)
					lineEnd = fileEnd;
				if (lineEnd == searchPos)
				{
					searchPos++;
					continue;
				}
				string clsname = lumpData.Mid(searchPos, lineEnd - searchPos);
				if (jgphud_debug)
					Console.Printf("\cDITEMINFO\c- Possible class name: [%s]", clsname);
				class<Actor> cls = clsname;
				if (cls)
				{
					if (jgphud_debug)
						Console.Printf("\cDITEMINFO\c- \cDFound item [%s]", cls.GetClassName());
					customItems.Push(cls);
				}
				else
					Console.Printf("\cDITEMINFO\c- \cGWARNING: \cD%s\cG is not a valid item name", clsname);
				if (jgphud_debug)
					Console.Printf("\cDITEMINFO\c- Searchpos %d | line end %d | file end %d", searchPos, lineEnd, fileEnd);
				searchPos = lineEnd + 1;
			}
			cl = Wads.FindLump("ITEMINFO", cl+1);
		}
	}

	// Draws directional incoming damage markers:
	ui void DrawDamageMarkers(double size = 120)
	{
		if (!c_drawDamageMarkers.GetBool())
			return;

		let dmgMarkerController = dmgMarkerControllers[consoleplayer];
		if (!dmgMarkerController)
			return;

		// Create a rectangular shape:
		if (!dmgMarker)
		{
			dmgMarker = new("Shape2D");

			vector2 p = (-0.055, -1);
			dmgMarker.Pushvertex(p);
			p.x *= -1;
			dmgMarker.Pushvertex(p);
			p.x *= -1;
			p.y = -0.5;
			dmgMarker.Pushvertex(p);
			p.x *= -1;
			dmgMarker.Pushvertex(p);

			dmgMarker.PushCoord((0,0));
			dmgMarker.PushCoord((1,0));
			dmgMarker.PushCoord((0,1));
			dmgMarker.PushCoord((1,1));

			dmgMarker.PushTriangle(0, 1, 2);
			dmgMarker.PushTriangle(1, 2, 3);
		}

		// Don't forget to multiply by hudscale:
		vector2 hudscale = statusbar.GetHudScale();
		if (!dmgMarkerTransf)
			dmgMarkerTransf = new("Shape2DTransform");
		// Cache the texture:
		if (!dmgMarkerTex || !dmgMarkerTex.IsValid())
			dmgMarkerTex = TexMan.CheckForTexture('JGPUFH_DMGMARKER');
		// Draw the shape for each damage marker data
		// in the previously built array:
		for (int i = dmgMarkerController.markers.Size() - 1; i >= 0; i--)
		{
			let dm = dmgMarkerController.markers[i];
			if (!dm)
				continue;
			
			// Vary width based on the amount of received damage:
			double width = LinearMap(dm.damage, 0, 50, size*0.2, size, true);
			dmgMarkerTransf.Clear();
			dmgMarkerTransf.Scale((width, size) * hudscale.x);
			dmgMarkerTransf.Rotate(dm.GetAngle());
			dmgMarkerTransf.Translate((Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5));
			dmgMarker.SetTransform(dmgMarkerTransf);
			Screen.DrawShape(dmgMarkerTex, false, 
				dmgMarker, 
				DTA_LegacyRenderStyle, STYLE_Add, 
				DTA_Alpha, dm.alpha
			);
		}
	}

	ui void RefreshEnemyHitMarker(bool killed = true)
	{
		reticleMarkerAlpha = 1.0;
		if (killed)
		{
			reticleMarkerScale = 1;
		}
	}

	ui void UpdateEnemyHitMarker()
	{
		if (reticleMarkerAlpha > 0)
		{
			reticleMarkerAlpha -= (reticleMarkerScale > 0 ? 0.075 : 0.15) * deltaTime;
		}
		if (reticleMarkerScale > 0)
		{
			reticleMarkerScale -= 0.1 * deltaTime;
		}
	}

	ui void DrawEnemyHitMarker()
	{
		if (!c_DrawEnemyHitMarkers.GetBool())
			return;
		
		vector2 screenCenter = (Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5);
		// Four diagonal bars:
		if (!reticleHitMarker)
		{
			reticleHitMarker = new("Shape2D");
			Vector2 p1 = (-0.08, -1);
			Vector2 p2 = (-p1.x, p1.y);
			Vector2 p3 = (p1.x, -0.25);
			Vector2 p4 = (-p3.x, p3.y);
			p1 = Actor.RotateVector(p1, -45);
			p2 = Actor.RotateVector(p2, -45);
			p3 = Actor.RotateVector(p3, -45);
			p4 = Actor.RotateVector(p4, -45);
			int id = 0;
			for (int i = 0; i < 4; i++)
			{
				reticleHitMarker.Pushvertex(p1);
				reticleHitMarker.Pushvertex(p2);
				reticleHitMarker.Pushvertex(p3);
				reticleHitMarker.Pushvertex(p4);
				reticleHitMarker.PushCoord((0,0));
				reticleHitMarker.PushCoord((0,0));
				reticleHitMarker.PushCoord((0,0));
				reticleHitMarker.PushCoord((0,0));
				reticleHitMarker.PushTriangle(id, id+1, id+2);
				reticleHitMarker.PushTriangle(id+1, id+2, id+3);
				p1 = Actor.RotateVector(p1, 90);
				p2 = Actor.RotateVector(p2, 90);
				p3 = Actor.RotateVector(p3, 90);
				p4 = Actor.RotateVector(p4, 90);
				id += 4;
			}
		}

		double alpha = reticleMarkerAlpha;
		if (alpha <= 0)
		{
			if (IsMenuOpen('JGPHUD_CrosshairOptions_menu'))
			{
				alpha = SinePulse(TICRATE*2, 0.2, 0.6, inMenus:true);
			}
			else
			{
				return;
			}
		}

		if (!reticleMarkerTransform)
			reticleMarkerTransform = new("Shape2DTransform");
		// Factor in the crosshair size but up to a point
		// as to not make these too small:
		int baseSize = c_EnemyHitMarkersSize.GetInt();
		double crosshairScaleFac = 1.0;
		if (baseSize > 0)
		{
			baseSize = Clamp(baseSize, 2, 128);
		}
		else
		{
			baseSize = 10;
			crosshairScaleFac = max(c_crosshairScale.GetFloat(), 0.2);
		}
		double size = (baseSize + baseSize * reticleMarkerScale);
		int screenFac = min(Screen.GetWidth() / 320, Screen.GetHeight() / 200);
		size *= screenFac * crosshairScaleFac;
		reticleMarkerTransform.Clear();
		reticleMarkerTransform.Scale((size, size));
		reticleMarkerTransform.Translate(screenCenter);
		reticleHitMarker.SetTransform(reticleMarkerTransform);
		color col = color(c_EnemyHitMarkersColor.GetInt());
		Screen.DrawShapeFill(color(col.b, col.g, col.r), alpha, reticleHitMarker);
	}

	ui bool CanDrawReticleBar(int which)
	{
		if (autoMapActive)
			return false;
		if (c_DrawReticleBars && c_DrawReticleBars.GetInt() != DM_AUTOHIDE)
			return true;

		which = Clamp(which, 0, reticleMarkersDelay.Size()-1);
		return reticleMarkersDelay[which] > 0;
	}

	ui void UpdateReticleBars()
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
			reticleMarkersDelay[RB_HEALTH] -= 1 * deltaTime;
		}

		if (prevArmAmount != armAmount || prevArmMaxAmount != armMaxAmount)
		{
			prevArmAmount = armAmount;
			prevArmMaxAmount = armMaxAmount;
			reticleMarkersDelay[RB_ARMOR] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_ARMOR] -= 1 * deltaTime;
		}


		Ammo am1, am2;
		[am1, am2] = statusbar.GetCurrentAmmo();
		if (am1 && (prevAmmo1Amount != am1.amount || prevAmmo1MaxAmount != am1.maxamount))
		{
			prevAmmo1Amount = am1.amount;
			prevAmmo1MaxAmount = am1.maxamount;
			reticleMarkersDelay[RB_AMMO1] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_AMMO1] -= 1 * deltaTime;
		}
		if (am2 && (prevAmmo2Amount != am2.amount || prevAmmo2MaxAmount != am2.maxamount))
		{
			prevAmmo2Amount = am2.amount;
			prevAmmo2MaxAmount = am2.maxamount;
			reticleMarkersDelay[RB_AMMO2] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_AMMO2] -= 1 * deltaTime;
		}
	}

	ui double, vector2, vector2, int, int GetReticleBarsPos(int i, double inwidth, double outwidth, double fntHeight)
	{
		i = Clamp(i, 0, 4);
		vector2 posIn;
		vector2 posOut;
		double angle;
		int inFlags = StatusBarCore.DI_TEXT_ALIGN_CENTER;
		int outFlags = StatusBarCore.DI_TEXT_ALIGN_CENTER;
		switch (i)
		{
			default:
				angle = RB_DONTDRAW;
				break;
			case RB_LEFT:
				angle = -90;
				posIn = (-inWidth, -fntHeight*0.25);
				posOut = (-outWidth, posIn.y);
				inFlags = StatusBarCore.DI_TEXT_ALIGN_LEFT;
				outFlags = StatusBarCore.DI_TEXT_ALIGN_RIGHT;
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
				inFlags = StatusBarCore.DI_TEXT_ALIGN_RIGHT;
				outFlags = StatusBarCore.DI_TEXT_ALIGN_LEFT;
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
		return angle, posIn, posOut, inFlags|StatusBarCore.DI_SCREEN_CENTER, outFlags|StatusBarCore.DI_SCREEN_CENTER;
	}

	ui void DrawReticleBars(int steps = 100)
	{
		if (c_DrawReticleBars.GetInt() <= DM_NONE)
			return;
		// Element alpha:
		double alpha = Clamp(c_ReticleBarsAlpha.GetFloat(), 0.0, 1.0);
		if (alpha <= 0)
			return;
		// Autoide
		bool autoHide = c_DrawReticleBars.GetInt() == DM_AUTOHIDE;
		// Should draw text?
		bool drawBarText = c_ReticleBarsText.GetBool();
		
		double coverAngle = BARCOVERANGLE;
		let lookTC = lookControllers[consoleplayer];
		if (!lookTC)
		{
			return;
		}

		// This is the general mask that cuts out the inner part
		// of the disks to make them appear as circular bars:
		if (!genRoundMask)
		{
			double angStep = CIRCLEANGLES / steps;
			double ang = 270;
			genRoundMask = New("Shape2D");
			// anchor point at the center:
			genRoundMask.PushVertex((0,0));
			// coords are irrelevant as usual, because no textures:
			genRoundMask.PushCoord((0,0));
			for (int i = 0; i < steps; i++)
			{
				double c = cos(ang);
				double s = sin(ang);
				genRoundMask.PushVertex((c,s));
				genRoundMask.PushCoord((0,0));
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
				genRoundMask.PushTriangle(0, i, next);
			}
		}
		if (!genRoundMaskTransfInner)
		{
			genRoundMaskTransfInner = New("Shape2DTransform");
		}
		if (!genRoundMaskTransfOuter)
		{
			genRoundMaskTransfOuter = New("Shape2DTransform");
		}

		// Position and sizes:
		vector2 screenCenter = (Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5);
		vector2 hudscale = statusbar.GetHudScale();
		double widthFac = 1.0 - Clamp(c_ReticleBarsWidth.GetFloat(), 0.0, 1.0);
		double virtualSize = c_ReticleBarsSize.GetInt();
		double secSizeFac = 1.05;
		double size = virtualSize * hudscale.x;
		double maskSize = size * widthFac;
		double secondarySize = (size * (secSizeFac / widthfac)) / secSizeFac;
		double secondaryMaskSize = secondarySize * widthFac;

		// Mask for inner bars:
		genRoundMaskTransfInner.Clear();
		genRoundMaskTransfInner.Scale((maskSize, maskSize));
		genRoundMaskTransfInner.Translate(screenCenter);
		// Mask for outer bars:
		genRoundMaskTransfOuter.Clear();
		genRoundMaskTransfOuter.Scale((secondaryMaskSize, secondaryMaskSize));
		genRoundMaskTransfOuter.Translate(screenCenter);
		
		// Font position and scale setup:
		HUDFont hfnt = numHUDFont;
		Font fnt = hfnt.mFont;
		// We need to do a lot here. The text strings, if shown, have to be shown
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
			genRoundMask.SetTransform(genRoundMaskTransfInner);
			let lt = lookTC.looktarget;
			int health = lt.health;
			let ltDef = GetDefaultByType(lt.GetClass());
			int maxhealth = max(lt.starthealth, lt.GetMaxHealth());
			EnableMask(0, genRoundMask);
			double fadeAlph = LinearMap(lookTC.targetTimer, 0, JGPUFH_LookTargetController.TARGETDISPLAYTIME / 2, 0.0, alpha, true);
			valueFrac = LinearMap(health, 0, maxhealth, 1.0, 0.0, true);
			DrawCircleSegmentShape(color(60,160,60), screenCenter, size, steps, angle, coverAngle, valueFrac, fadeAlph);
			if (drawBarText)
			{
				double s = 0.35;
				statusbar.DrawString(smallHUDFont, String.Format("%s", lt.GetTag()), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75) * s);
				statusbar.DrawString(hfnt, String.Format("%d", health), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
			}
			DisableMask();
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
				genRoundMask.SetTransform(genRoundMaskTransfInner);
				double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_HEALTH], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
				EnableMask(0, genRoundMask);
				valueFrac = LinearMap(health, 0, maxhealth, 1.0, 0.0, true);
				DrawCircleSegmentShape(color(215,100,100), screenCenter, size, steps, angle, coverAngle, valueFrac, fadeAlph);
				if (drawBarText)
				{
					statusbar.DrawString(hfnt, String.Format("%d", health), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
				}
				DisableMask();
			}
			// Armor bar (outer):
			int armAmount = armAmount;
			int armMaxAmount = armMaxAmount;
			if (CanDrawReticleBar(RB_ARMOR))
			{
				genRoundMask.SetTransform(genRoundMaskTransfOuter);
				double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_ARMOR], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
				EnableMask(0, genRoundMask);
				valueFrac = LinearMap(armAmount, 0, armMaxAmount, 1.0, 0.0, true);
				DrawCircleSegmentShape(color(armorColor.a, armorcolor.r+32, armorcolor.g+32, armorcolor.b+32), screenCenter, secondarySize, steps, angle, coverAngle, valueFrac, fadeAlph);
				if (drawBarText)
				{
					statusbar.DrawString(hfnt, String.Format("%d", armAmount), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
				}
				DisableMask();
			}
		}
		

		Ammo am1, am2;
		[am1, am2] = statusbar.GetCurrentAmmo();

		// Ammo bars:
		[angle, fntPosIn, fntPosOut, fntFlagsIn, fntFlagsOut] = GetReticleBarsPos(c_ReticleBarsAmmo.GetInt(), fontOfsIn, fontOfsOut, fy);
		if (angle != RB_DONTDRAW)
		{
			color amCol = GetAmmoColor(am1);
			// Ammo 1 (inner):
			if (am1)
			{
				if (CanDrawReticleBar(RB_AMMO1))
				{
					genRoundMask.SetTransform(genRoundMaskTransfInner);
					double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_AMMO1], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
					EnableMask(0, genRoundMask);
					valueFrac = LinearMap(am1.amount, 0, am1.maxAmount, 1.0, 0.0, true);
					DrawCircleSegmentShape(amCol, screenCenter, size, steps, angle, coverAngle, valueFrac, fadeAlph);
					if (drawBarText)
					{
						statusbar.DrawString(hfnt, String.Format("%d", am1.amount), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
					}
					DisableMask();
				}
			}
			// Ammo 2 (outer):
			if (am2 && am2 != am1)
			{
				color amCol2 = GetAmmoColor(am2);
				if (amCol2 == amCol)
				{
					amCol2 = color(int(amCol.r*0.7), int(amCol.g*0.7), int(amCol.b*0.7));
				}
				if (CanDrawReticleBar(RB_AMMO2))
				{
					genRoundMask.SetTransform(genRoundMaskTransfOuter);
					double fadeAlph = !autoHide ? alpha : LinearMap(reticleMarkersDelay[RB_AMMO2], 0, MARKERSDELAY*0.5, 0.0, alpha, true);
					EnableMask(0, genRoundMask);
					valueFrac = LinearMap(am2.amount, 0, am2.maxAmount, 1.0, 0.0, true);
					DrawCircleSegmentShape(amCol2, screenCenter, secondarySize, steps, angle, coverAngle, valueFrac, fadeAlph);
					if (drawBarText)
					{
						statusbar.DrawString(hfnt, String.Format("%d", am2.amount), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: (fntScale,fntScale*0.75));
					}
					DisableMask();
				}
			}
		}
	}

	ui void DrawCircleSegmentShape(color col, vector2 pos, double size, int steps, double angle, double coverAngle, double frac = 1.0, double alpha = 1.0)
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
		// draw mask shape:
		// Angle the mask (flip the angle if it was negative,
		// so it goes counter-clockwise instead of clockwise):
		double ofsMaskAngle = coverAngle*frac;
		if (angle <= 0)
			 ofsMaskAngle *= -1;
		roundBarsTransform.Clear();
		// Increase the size slightly just to make sure it doesn't
		// leave any stray pixels at the edge of the bar:
		roundBarsTransform.Scale((size, size)*1.05);
		roundBarsTransform.Rotate(angle + ofsMaskAngle);
		roundBarsTransform.Translate(pos);
		roundBarsAngMask.SetTransform(roundBarsTransform);
		// set mask:
		EnableMask(0, roundBarsAngMask);
		// draw bar:
		roundBarsTransform.Clear();
		roundBarsTransform.Scale((size, size));
		roundBarsTransform.Rotate(angle);
		roundBarsTransform.Translate(pos);
		roundBars.SetTransform(roundBarsTransform);
		color colBGR = color(col.b, col.g, col.r);
		Screen.DrawShapeFill(colBGR, alpha, roundBars);
		// Flash with a 50% white pulse if the value
		// is under 20%:
		if (frac >= 0.8)
		{
			double alphaSineFac = SinePulse(LinearMap(frac, 0.8, 1.0, TICRATE, TICRATE*0.34));
			Screen.DrawShapeFill(color(255,255,255), alpha * alphaSineFac * 0.5, roundBars);
		}
		DisableMask();
	}

	ui void CreateCircleSegmentShapes(out Shape2D inShape, out Shape2D outShape, int steps, double coverAngle)
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
	ui void GetWeaponSlots()
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

	ui void UpdateWeaponSlots()
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

	ui void DrawWeaponSlots()
	{
		if (c_drawWeaponSlots.GetInt() <= DM_NONE)
			return;

		if (c_drawWeaponSlots.GetInt() == DM_AUTOHIDE && slotsDisplayTime <= 0)
			return;
		
		// Always run to make sure the slot data
		// is properly set up:
		GetWeaponSlots();

		double iconWidth = Clamp(c_WeaponSlotsSize.GetInt(), 4, 100);
		vector2 box = (iconWidth, iconWidth * 0.625);
		double indent = iconWidth * 0.05;

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

		// Get the positioning flags first:
		int flags = SetScreenFlags(c_WeaponSlotsPos.GetInt());

		// Figure out alignment and width/height
		// based on it:
		int alignment = c_WeaponSlotsAlign.GetInt();
		bool vertical = (alignment != WA_HORIZONTAL);
		bool rightEdge = vertical && (flags & StatusBarCore.DI_SCREEN_RIGHT == StatusBarCore.DI_SCREEN_RIGHT);
		bool bottom = (flags & StatusBarCore.DI_SCREEN_BOTTOM == StatusBarCore.DI_SCREEN_BOTTOM);
		double horMul = vertical ? maxSlotID : totalSlots;
		double vertMul = vertical ? totalSlots : maxSlotID;
		double width = (box.x + indent) * horMul - indent; //we don't need indent at the end
		double height = (box.y + indent) * vertMul - indent; //ditto

		// Handle positioning as usual:
		vector2 ofs = ( c_WeaponSlotsX.GetInt(), c_WeaponSlotsY.GetInt() );
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);

		if (vertical)
		{
			// If it's vertical and at the right edge,
			// move the initial position to the rightmost
			// index, since indexes will go to the left:
			if (rightEdge)
				pos.x += width - box.x;
			// And if it's inverted, move it to the position
			// of thje lowest slot:
			if (alignment == WA_VERTICALINV)
				pos.y += height - box.y;
		}

		// For horizontal position, if it's at the bottom,
		// move it to the lowest index, since indexes
		// will go up:
		else if (bottom)
		{
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
					// Otherwise move the box vertically:
					else
					{
						// If it's at the bottom, move the box
						// upward instead of downward:
						double stepy = (box.y + indent) * (bottom ? -1.0 : 1.0);
						wpos.y += stepy;
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
						double stepy = (box.y + indent) * (alignment == WA_VERTICALINV ? -1.0 : 1.0);
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

	ui void DrawOneWeaponSlot(Weapon weap, vector2 pos, int flags, vector2 box, int slot = -1)
	{
		if (!weap)
			return;
		
		int fntCol = Font.CR_White;
		// Compare this weapon to readyweapon and pendingweapon:
		Weapon rweap = Weapon(CPlayer.readyweapon);
		// MUST explicitly cast it as Weapon, otherwise the pointer
		// won't be properly null-checked:
		Weapon pweap = Weapon(CPlayer.pendingweapon);
		// If the weapon in question is selected or being
		// selected, invert the colors of the box:
		if ((rweap == weap && !pweap) || pweap == weap)
		{
			fntCol = Font.CR_Gold;
			color col = GetHUDBackground();
			// Clamp the alpha, so it's not too low:
			int a = Clamp(col.a, 180, 255);
			// Do not use texture fill for this block,
			// since it's not possible to easily
			// invert colors of a texture:
			statusbar.Fill(color(a, 255 - col.r, 255 - col.g, 255 - col.b), pos.x, pos.y, box.x, box.y, flags);
		}
		else
		{
			BackgroundFill(pos.x, pos.y, box.x, box.y, flags);
		}
		statusbar.DrawInventoryIcon(weap, pos + box*0.5, flags|StatusBarCore.DI_ITEM_CENTER, boxsize: box);
		
		// draw small ammo bars at the bottom of the box:
		double barheight = box.y * 0.05;
		double barPosY = pos.y + box.y - barheight;
		Ammo am1 = weap.ammo1;
		color amCol = color(255, 0, 255, 0); //ammo1 is green
		color amCol2 = color(255, 255, 128, 0); //ammo2 is orange
		if (am1)
		{
			double barWidth = LinearMap(am1.amount, 0, am1.maxamount, 0., box.x, true);
			statusbar.Fill(amCol, pos.x, barPosY, barWidth, barheight, flags);
			barPosY -= barHeight*1.2;
		}
		// Only draw the second bar if ammotype2 isn't the same
		// as ammotype 1:
		Ammo am2 = weap.ammo2;
		if (am2 && am2 != am1)
		{
			double barWidth = LinearMap(am2.amount, 0, am2.maxamount, 0., box.x, true);
			statusbar.Fill(amCol2, pos.x, barPosY, barWidth, barheight, flags);
		}
		
		// draw slot number in the bottom right corner of the box:
		if (slot != -1)
		{
			double fs = 0.4;
			string slotNum = ""..slot;
			statusbar.DrawString(mainHUDFont, slotNum, (pos.x+box.x*0.95, pos.y), flags|StatusBarCore.DI_TEXT_ALIGN_RIGHT, fntCol, 0.8, scale:(fs, fs));
		}
	}

	// Checks if the minimap should be drawn. Has two returns:
	// 1. whether to draw the minimap at all
	// 2. whether to draw enemy radar on top
	ui bool, bool ShouldDrawMinimap()
	{
		// Cache the CVar if it hasn't been cached yet:
		if (!c_drawMinimap)
			c_drawMinimap = CVar.GetCvar('jgphud_DrawMinimap', CPlayer);
		if (!c_MinimapEnemyDisplay)
			c_MinimapEnemyDisplay = CVar.GetCvar('jgphud_MinimapEnemyDisplay', CPlayer);

		// Check CVar values:
		bool drawmap = c_drawMinimap.GetBool();
		bool drawradar = c_MinimapEnemyDisplay.GetInt();
		// Don't draw if PlayerPawn is invalid:
		if (drawmap && !CPlayer.mo)
			drawmap = false;
		// Don't draw if automap is open:
		if (drawmap && autoMapActive)
			drawmap = false;
		// Don't draw if the world has been unloaded (this prevents
		// possible crashes on tally/intermission
		// screens when moving to the next map):
		if (levelUnloaded)
			drawmap = false;
		// Just as a safety check, don't draw if
		// not in a level (this probably will never
		// be actually checked):
		if (drawmap && gamestate != GS_LEVEL)
			drawmap = false;
		// If map shouldn't be drawn, radar shouldn't
		// be drawn either. Also, clera lines and
		// monsters arrays:
		if (!drawmap)
		{
			drawradar = false;
			mapLines.Clear();
			radarMonsters.Clear();
		}
		return drawmap, drawradar;
	}

	// This draws a minimap with an optional map information block below.
	// The minimap is a pretty annoying bit. Aside from potentially causing
	// performance issues, it also has  to be drawn fully using Screen
	// methods because StatusBar doesn't have anything like shapes and
	// line drawing.
	ui void DrawMinimap()
	{
		bool drawMap, drawRadar;
		[drawMap, drawRadar] = ShouldDrawMinimap();

		double size = GetMinimapSize();
		// Almost everything has to be multiplied by hudscale.x
		// so that it matches the general HUD scale regarldess
		// of physical resolution:
		vector2 hudscale = statusbar.GetHudScale();
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
		if (drawMap)
		{
			msize = (max(size, 44), size); //going under 44 pixels looks too bad scaling-wise
		}
		vector2 mapDataSize = (msize.x, msize.y + 16);
		// draw it above the minimap if that's at the bottom:
		vector2 mapDataPos = ((flags & StatusBarCore.DI_SCREEN_BOTTOM) == StatusBarCore.DI_SCREEN_BOTTOM) ? (0, 0) : (0, msize.y);
		mapdataPos = AdjustElementPos(mapDataPos, flags, (msize.x, msize.y), ofs);
		// Since this thing is anchored to the minimap, and the minimap,
		// being drawn by Screen, ignores HUD aspect scaling, we
		// need to make sure this bit's position also ignores
		// HUD scaling:
		if (c_aspectscale.GetBool())
		{
			mapDataPos.y /= ASPECTSCALE;
		}
		DrawMapData(mapDataPos, flags, msize.x, 0.5);
		
		// If the actual minimap is disabled, stop here:
		if (!drawMap)
			return;

		size *= hudscale.x;

		// Let the player change the size of the map:
		double mapZoom = GetMinimapZoom();
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
			for (int i = 1; i <= steps; i++)
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
		bool circular = IsMinimapCircular();
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
		Color baseCol = GetHUDBackground();
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
		// Draw background:
		color backCol = c_minimapBackColor.GetInt();
		Screen.DrawShapeFill(color(255, backCol.b, backCol.g, backCol.r), 1.0, shapeToUse);

		// Apply mask
		// It's applied after outline and background scaling, 
		// so that the lines are maked within the outline:
		if (!jgphud_debugmap)
		{
			EnableMask(1, shapeToUse);
		}
		
		// Draw the minimap lines:
		DrawMinimapLines(pos, diff, playerAngle, size, hudscale.x, mapZoom);

		// White arrow at the center represeing the player:
		if (!minimapShape_Arrow)
		{
			minimapShape_Arrow = new("Shape2D");
			minimapShape_Arrow.Pushvertex((0, -1));
			minimapShape_Arrow.Pushvertex((-1, 1));
			minimapShape_Arrow.Pushvertex((1, 1));
			minimapShape_Arrow.PushCoord((0,0));
			minimapShape_Arrow.PushCoord((0,0));
			minimapShape_Arrow.PushCoord((0,0));
			minimapShape_Arrow.PushTriangle(0, 1, 2);
		}

		// Draw enemy positions on the minimap
		// if the CVAR allows that:
		if (drawRadar)
		{
			DrawEnemyRadar(pos, diff, playerAngle, size, hudscale.x, mapZoom);
		}

		// Draw the arrow representing the player:
		minimapTransform.Clear();
		double arrowSize = CPlayer.mo.radius * mapZoom * hudscale.x;
		minimapTransform.Scale((arrowSize, arrowSize));
		minimapTransform.Translate(pos + (size*0.5,size*0.5));
		minimapShape_Arrow.SetTransform(minimapTransform);
		color youColor = c_minimapYouColor.GetInt();
		Screen.DrawShapeFill(color(youColor.b, youColor.g, youColor.r), 1.0, minimapShape_Arrow);

		DrawMapMarkers(pos, diff, playerAngle, size, hudscale.x, mapZoom);
		
		DisableMask();
	}

	// Returns true if the minimap shape is set to circular
	// by the player:
	ui bool IsMinimapCircular()
	{
		return (c_CircularMinimap && c_CircularMinimap.GetBool());
	}

	ui double GetMinimapZoom()
	{
		if (!c_MinimapZoom)
			return 1.0;
		
		return Clamp(c_MinimapZoom.GetFloat(), 0.1, 10.0);
	}

	ui double GetMinimapSize()
	{
		if (!c_MinimapSize)
			return 64;
		
		return c_MinimapSize.GetFloat();
	}

	ui void UpdateMinimapLines()
	{
		if (!ShouldDrawMinimap())
		{
			return;
		}
		// We don't need to update the lines every tic.
		// Every 10 tics is enough:
		if (!Level || Level.maptime % 10 != 0)
			return;
		mapLines.Clear();
		double distFac = IsMinimapCircular() ? 1.0 : SQUARERADIUSFAC;
		double zoom = GetMinimapZoom();
		double radius = GetMinimapSize() * 4;
		double distance = ((radius) / zoom) * distFac; //account for square shapes
		let it = BlockLinesIterator.Create(CPlayer.mo, distance);
		while (it.Next())
		{
			Line ln = it.curLine;
			if (ln && IsLineVisible(ln))
			{
				mapLines.Push(ln);
			}
		}
	}

	// Determine if the line should be visible in the minimap:
	ui bool IsLineVisible(Line ln)
	{
		if (!ln)
			return false;
		
		// Don't draw if it's explicitly set to 'hidden'
		// in the map editor:
		if (ln.flags & Line.ML_DONTDRAW)
			return false;
		
		// If this line hasn't been seen yet, only draw
		// it if the user set the specified CVAR to true:
		if (!(ln.flags & Line.ML_MAPPED) && (!c_minimapDrawUnseen || c_minimapDrawUnseen.GetFloat() <= 0))
			return false;
		
		// Always draw one-sided lines:
		if (!(ln.flags & Line.ML_TWOSIDED))
			return true;
		
		// Otherwise it's a double-sided line. We need to
		// do a series of extra checks.
		
		// Always draw lines that have a special attached:
		if (ln.special)
			return true;

		// Draw it if it blocks everything or hitscans:
		if (ln.flags & Line.ML_BLOCKEVERYTHING || ln.flags & Line.ML_BLOCKHITSCAN)
			return true;

		// Draw it if it uses a walkable midtexture or
		// functions as a railing:
		if (ln.flags & Line.ML_RAILING || ln.flags & Line.ML_3DMIDTEX)
			return true;
		
		// Draw it if any of its sidedefs have a mid
		// texture at all (means it's visually important):
		for (int i = 0; i < ln.sidedef.Size(); i++)
		{
			Side s = ln.sidedef[i];
			if (!s)
				continue;
			TextureID tex = s.GetTexture(Side.mid);
			if (tex && tex.IsValid())
				return true;
		}
		
		// Get sectors adjacent to the line:
		Sector sf = ln.backsector;
		Sector ff = ln.frontsector;
		// If for some reason they're the same sector,
		// don't draw:
		if (sf == ff)
		{
			return false;
		}
		
		// Draw if there are any 3D floors attached to any
		// of the line's sectors:
		if (sf.Get3DFloorCount() > 0 || ff.Get3DFloorCount() > 0)
		{
			return true;
		}

		// Check if the adjacent sectors have a difference
		// in ceiling height. If there's difference and the
		// relevant CVAR is true, draw them:
		vector2 pos = ln.v1.p;
		if (sf.floorplane.ZAtPoint(pos) != ff.floorplane.ZAtPoint(pos) && (c_minimapDrawFloorDiff && c_minimapDrawFloorDiff.GetBool()))
		{
			return true;
		}
		// Same for floor height difference:
		if (sf.ceilingplane.ZAtPoint(pos) != ff.ceilingplane.ZAtPoint(pos) && (c_minimapDrawCeilingDiff && c_minimapDrawCeilingDiff.GetBool()))
		{
			return true;
		}
		
		// If all of those checks have failed, this linedef
		// is an invisible divisor (perhaps created for the
		// purposes of sector lighting) and drawing it
		// would only add visual noise, so we'll skip it:
		return false;
	}

	ui void DrawMinimapLines(vector2 pos, vector2 ofs, double angle, double radius, double scale = 1.0, double zoom = 1.0)
	{
		color lineCol = c_minimapLineColor.GetInt();
		color intLineCol = c_MinimapIntLineColor.GetInt();

		for (int i = 0; i < mapLines.Size(); i++)
		{
			Line ln = mapLines[i];
			if (!ln)
				continue;
				
			// Get vertices and scale them in accordance
			// with zoom value and hudscale:
			vector2 lp1 = ln.v1.p;
			vector2 lp2 = ln.v2.p;
			vector2 p1 = (lp1 - ofs) * zoom * scale;
			vector2 p2 = (lp2 - ofs) * zoom * scale;

			p1 = AlignPosToMap(p1, angle, radius);
			p2 = AlignPosToMap(p2, angle, radius);

			double thickness = 1;
			color col = GetLockColor(ln);
			int lineAlph = 255;
			if (col != -1)
			{
				thickness = 4;
				col = color(col.r, col.g, col.b);
			}
			else if (ln.activation & SPAC_PlayerActivate)
			{
				col = color(intLineCol.r, intLineCol.g, intLineCol.b);
			}
			else
			{
				col = color(lineCol.r, lineCol.g, lineCol.b);
				// One-sided lines are thicker and opaque:
				if (!(ln.flags & Line.ML_TWOSIDED))
				{
					thickness = 2;
				}
				else
				{
					lineAlph /= 2;
				}
			}
			if (!(ln.flags & Line.ML_MAPPED))
			{
				lineAlph *= Clamp(c_minimapDrawUnseen.GetFloat(), 0., 1.);
			}

			if (thickness <= 1)
				Screen.DrawLine(p1.x + pos.x, p1.y + pos.y, p2.x + pos.x, p2.y + pos.y, col, lineAlph);
			else
				Screen.DrawThickLine(p1.x + pos.x, p1.y + pos.y, p2.x + pos.x, p2.y + pos.y, thickness, col, lineAlph);
		}
	}

	ui color GetLockColor(Line l)
	{
		int lock = l.locknumber;
		// special-specific locks:
		if (!lock)
		{
			switch (l.special)
			{
			case FS_Execute:
				lock = l.Args[2];
				break;
			case Door_LockedRaise:
			case Door_Animated:
				lock = l.Args[3];
				break;
			case ACS_LockedExecute:
			case ACS_LockedExecuteDoor:
			case Generic_Door:
				lock = l.Args[4];
				break;
			}
		}
		if (!lock)
			return -1;
		
		return Key.GetMapColorForLock(lock);
	}

	ui void UpdateEnemyRadar()
	{
		if (!ShouldDrawMinimap())
		{
			return;
		}
		radarMonsters.Clear();
		double distFac = IsMinimapCircular() ? 1.0 : SQUARERADIUSFAC; //account for square shapes
		double zoom = GetMinimapZoom();
		double radius = GetMinimapSize() * 4;
		double distance = ((radius) / zoom) * distFac;
		let it = BlockThingsIterator.Create(CPlayer.mo, distance);
		while (it.Next())
		{
			let thing = it.thing;
			if (thing.bISMONSTER && (thing.bSHOOTABLE || thing.bVULNERABLE) && thing.health > 0 && CPlayer.mo.Distance2DSquared(thing) <= distance*distance)
			{
				radarMonsters.Push(thing);
			}
		}
	}

	ui void DrawEnemyRadar(vector2 pos, vector2 ofs, double angle, double radius, double scale = 1.0, double zoom = 1.0)
	{
		if (!minimapShape_Arrow || !minimapTransform)
			return;
		
		bool drawAll = c_MinimapEnemyDisplay.GetInt() >= MED_ALL;

		color foeColor = c_minimapMonsterColor.GetInt();
		color friendColor = c_minimapFriendColor.GetInt();
		for (int i = 0; i < radarMonsters.Size(); i++)
		{
			let thing = radarMonsters[i];
			if (!thing || !thing.target)
				continue;

			vector2 ePos = (thing.pos.xy - ofs) * zoom * scale;
			ePos = AlignPosToMap(ePos, angle, radius);

			// scale alpha with vertical distance:
			double vdiff = abs(CPlayer.mo.pos.z - thing.pos.z);
			double alpha = LinearMap(vdiff, 0, 512, 1.0, 0.1, true);
			// determine marker size based on the CVAR
			// (either scaled with zoom, or fixed):
			double msize = Clamp(c_minimapMapMarkersSize.GetInt(), 0, 64);
			double markerSize = (msize <= 0 ? thing.radius * zoom : msize) * scale;

			minimapTransform.Clear();
			minimapTransform.Scale((markerSize,markerSize));
			minimapTransform.Rotate(-thing.angle - angle - 90);
			minimapTransform.Translate(pos + ePos);
			minimapShape_Arrow.SetTransform(minimapTransform);
			color col = thing.IsHostile(CPLayer.mo) ? foeColor : friendColor;
			Screen.DrawShapeFill(color(col.b, col.g, col.r), alpha, minimapShape_Arrow);
		}
	}

	ui void DrawMapMarkers(vector2 pos, vector2 ofs, double angle, double radius, double scale = 1.0, double zoom = 1.0)
	{
		double distFac = IsMinimapCircular() ? 1.0 : SQUARERADIUSFAC;
		double distance = ((radius) / zoom) * distFac; //account for square shapes
		for (int i = 0; i < mapMarkers.Size(); i++)
		{
			let marker = mapMarkers[i];
			if (!marker)
				continue;
			
			if (!CPlayer.mo || CPlayer.mo.Distance2DSquared(marker) > distance*distance)
				continue;

			TextureID tex = GetMarkerTexture(marker);
			if (!tex.IsValid())
				return;

			vector2 ePos = (marker.pos.xy - ofs) * zoom * scale;
			ePos = AlignPosToMap(ePos, angle, radius);

			// scale alpha with vertical distance:
			double vdiff = abs(CPlayer.mo.pos.z - marker.pos.z);
			double alpha = LinearMap(vdiff, 0, 512, 1.0, 0.1, true);
			// determine marker size based on the CVAR
			// (either scaled with zoom, or fixed):
			double msize = Clamp(c_minimapMapMarkersSize.GetInt(), 0, 64);
			double markerSize = (msize <= 0 ? marker.radius * zoom * marker.scale.x : msize) * scale;
			vector2 mpos = pos + ePos;
			Screen.DrawTexture(tex, false, mpos.x, mpos.y, DTA_Alpha, alpha);
		}
	}

	// Gets the texture for map markers:
	clearscope TextureID GetMarkerTexture(Actor marker, bool report = false)
	{
		// Try getting it from picnum first:
		TextureID tex = marker.picnum;
		name texname = TexMan.Getname(tex);
		if (report)
			Console.Printf("%s picnum: %s", marker.GetClassName(), texname);
		// If that failed, get the curstate.sprite:
		if (!tex.IsValid() || texname == 'AMRKA0' || texname == 'TNT1A0')
		{
			tex = marker.curstate.GetSpriteTexture(0);
			texname = TexMan.Getname(tex);
			if (report)
				Console.Printf("%s curstate.sprite: %s", marker.GetClassName(), texname);
		}
		// If that failed, get the sprite and frame fields
		// (they may not be the same as curstate.sprite
		// if they were modified directly, so GetSpriteTexture
		// can't obtain them) and construct  the texture name
		// manually:
		if (!tex.IsValid() || texname == 'AMRKA0' || texname == 'TNT1A0')
		{
			string spritename = ""..marker.sprite;
			// Converts the integer frame value to a letter from the ASCII
			// table, by offsetting from "a":
			string frame = String.Format("%c", int("a")+marker.frame);
			string spritetex = String.Format("%s%s0", spritename, frame);
			tex = TexMan.CheckForTexture(spritetex);
			if (report)
				Console.Printf("%s sprite: (looking: %s | got: %s)", marker.GetClassName(), spritetex, TexMan.GetName(tex));
		}
		return tex;
	}

	ui vector2 AlignPosToMap(vector2 vec, double angle, double mapSize)
	{
		// Rotate and mirror horizontally, so that the top
		// of the minimap is pointing where the player
		// is facing:
		vec = Actor.RotateVector(vec, angle);
		vec.x *= -1;
		// Offset relative to the map center, not player
		// position:
		vec += (mapSize, mapSize)*0.5;
		return vec;
	}


	// Draw map data (kills/secrets/items/time) below the
	// minimap (even if the minimap isn't drawn, it'll be
	// attached to the same position):
	ui void DrawMapData(vector2 pos, int flags, double width, double scale = 1.0)
	{
		HUDFont hfnt = mainHUDFont;
		Font fnt = hfnt.mFont;
		let fy = fnt.GetHeight() * scale;

		pos.x += width*0.5;
		// flip if it's at the bottom:
		if ((flags & StatusBarCore.DI_SCREEN_BOTTOM) == StatusBarCore.DI_SCREEN_BOTTOM)
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
			s_right = String.Format("\cD%d:%02d:%02d", h, m, s);
			DrawMapDataElement(s_left, s_right, hfnt, pos, flags, width, scale);
		}
	}

	// Draws the actual map data element, consisting of the label
	// (left), a colon, and the value (right):
	ui void DrawMapDataElement(string str1, string str2, HUDFont hfnt, vector2 pos, int flags, double width, double scale = 1.0)
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
		statusbar.DrawString(hfnt, str1, pos-(strOfs,0), flags|StatusBarCore.DI_TEXT_ALIGN_RIGHT, scale:(strScale,strScale));
		statusbar.DrawString(hfnt, ":", pos, flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, scale:(scale,scale));
		statusbar.DrawString(hfnt, str2, pos+(strOfs,0), flags|StatusBarCore.DI_TEXT_ALIGN_LEFT, scale:(scale,scale));
	}

	clearscope int, int, int TicsToHours(int tics)
	{
		int totalSeconds = tics / TICRATE;
		int hours = (totalSeconds / 3600) % 60;
		int minutes = (totalSeconds / 60) % 60;
		int seconds = totalSeconds % 60;

		return hours, minutes, seconds;
	}

	ui void DrawPowerups()
	{
		if (!c_drawPowerups || !c_drawPowerups.GetBool())
			return;

		bool previewMode;
		// Calculate height of the block:
		int powerNum;
		for (int i = 0; i < powerupData.Size(); i++)
		{
			let pwd = powerupData[i];
			if (pwd && CPlayer.mo.FindInventory(pwd.powerupType))
			{
				powerNum++;
			}
		}
		if (powerNum <= 0)
		{
			// If the player has no active powerups but they
			// currently have the Powerups settings menu open,
			// this will set up a preview mode that draws
			// dummy powerup icons and empty timers, so that
			// the player can see where the timers will appear:
			if (IsMenuOpen('JGPHUD_Powerups_menu'))
			{
				previewMode = true;
				powerNum = powerupData.Size();
			}
			else
			{
				return;
			}
		}

		int flags = SetScreenFlags(c_PowerupsPos.GetInt());
		vector2 ofs = (c_PowerupsX.GetInt(), c_PowerupsY.GetInt());
		double iconSize = Clamp(c_PowerupsIconSize.GetInt(), 4, 100);
		int indent = 1;
		HUDFont fnt = smallHUDFont;
		double textScale = iconSize * 0.025;
		double fy = fnt.mFont.GetHeight() * textScale;
		double width = iconSize + indent;
		double height = (iconsize + indent) * powerNum + indent;
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		pos.y += iconSize*0.5;

		flags |= StatusBarCore.DI_ITEM_CENTER;
		pos.x += iconsize*0.5;
		/*double textOfs = iconsize + indent;
		if ((flags & StatusBarCore.DI_SCREEN_RIGHT) == StatusBarCore.DI_SCREEN_RIGHT)
		{
			flags |= StatusBarCore.DI_TEXT_ALIGN_RIGHT;
			textOfs = -1;
		}*/
		for (int i = 0; i < powerupData.Size(); i++)
		{
			let pwd = powerupData[i];
			if (!pwd)
				continue;
			let pow = Powerup(CPlayer.mo.FindInventory(pwd.powerupType));
			if (pow || previewMode)
			{
				int style = STYLE_TranslucentStencil;
				double alpha = SinePulse(TICRATE*2, 0.2, 0.6, inMenus:true);
				if (!previewMode)
				{
					style = pwd.renderStyle;
					alpha = pow.isBlinking() ? 0.4 : 1.0;
				}
				statusbar.DrawTexture(pwd.icon, pos, flags|StatusBarCore.DI_ITEM_CENTER, alpha: alpha, scale:ScaleToBox(pwd.icon, iconSize), style:style);
				// Account for infinite flight in singleplayer:
				if (!previewMode && !multiplayer && pow is 'PowerFlight' && Level.infinite_flight)
				{
					continue;
				}

				string s_time;
				int h,m,s;
				if (!previewMode)
				{
					[h,m,s] = TicsToHours(pow.EffectTics);
				}
				if (h > 0)
				{
					s_time = String.Format("%d:%02d:%02d", h, m, s);
				}
				else
				{
					s_time = String.Format("%d:%02d", m, s);
				}
				//statusbar.DrawString(fnt, s_time, (pos.x, pos.y - fy*0.5 - fy*0.1), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: Font.CR_BLACK, scale:(textscale,textscale*1.2));
				statusbar.DrawString(fnt, s_time, (pos.x, pos.y - fy*0.5), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, scale:(textscale,textscale));
				pos.y += iconSize + indent;
			}
		}
	}

	ui void DrawKeys()
	{
		if (!c_drawKeys.GetBool())
			return;

		bool previewMode;
		if (!CPlayer.mo.FindInventory('Key',true))
		{
			// Enable preview display if the relevant
			// menu is open but the player has no keys:
			if (IsMenuOpen('JGPHUD_Keys_menu'))
			{
				previewMode = true;
			}
			else
			{
				return;
			}
		}

		int flags = SetScreenFlags(c_KeysPos.GetInt());
		vector2 ofs = (c_KeysX.GetInt(), c_KeysY.GetInt());
		double iconSize = 10;
		int indent = 1;
		double width;
		double height;

		int keyCount = Key.GetKeyTypeCount();
		array<TextureID> keyIcons;
		for (int i = 0; i < keyCount; i++)
		{
			class<Key> kc = Key.GetKeyType(i);
			TextureID icon;
			// In preview mode, cache the icons
			// from class definitions:
			if (previewMode)
			{
				let k = GetDefaultByType(kc);
				icon = k.icon;
				if (!icon.IsValid())
				{
					icon = k.spawnstate.GetSpriteTexture(0);
				}
			}
			// Otherwise, cache them from keys
			// in player's inventory:
			else
			{
				let k = CPlayer.mo.FindInventory(kc);
				if (k)
				{
					icon = statusbar.GetIcon(k,0);
				}
			}
			if (icon.IsValid() && TexMan.GetName(icon) != 'TNT1A0')
			{
				keyIcons.Push(int(icon));
			}
		}
		int totalKeys = keyIcons.Size();
		if (totalKeys <= 0)
		{
			return;
		}

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
		
		int style = STYLE_Normal;
		double alpha = 1.0;
		int col = color(0,0,0,0);
		// altered visuals for preview mode:
		if (previewMode)
		{
			style = STYLE_TranslucentStencil;
			alpha = SinePulse(TICRATE*2, 0.2, 0.5, inMenus:true);
			col = color(int(255 * alpha),255,255,255);
		}
		BackgroundFill(pos.x, pos.y, width, height, flags, col);

		pos += (iconsize*0.5+indent, iconsize*0.5+indent);
		vector2 kpos = pos;
		// Keep track of how many keys we've drawn horizontally,
		// so we can switch to new line when we've filled all
		// columns:
		int horKeys;
		for (int i = 0; i < keyIcons.Size(); i++)
		{
			let icon = keyIcons[i];
			statusbar.DrawTexture(icon, kpos, flags|StatusBarCore.DI_ITEM_CENTER, alpha:alpha, box:(iconSize, iconSize), style:style);
			horKeys++;
			// Keep going right if this isn't the final
			// column yet:
			if (horKeys < columns)
			{
				kpos.x += iconsize + indent;
			}
			// Otherwise reached the final column - 
			// reset x pos and move y pos:
			else
			{
				horKeys = 0;
				kpos.x = pos.x;
				kpos.y += iconSize;
			}
		}
	}

	ui double GetInvBarIconSize()
	{
		if (c_InvBarIconSize)
			return c_InvBarIconSize.GetInt();
		return ITEMBARICONSIZE;
	}

	ui bool ShouldDrawInvBar(int numfields)
	{		
		// Perform the usual checks first:
		if (!c_drawInvBar.GetBool())
			return false;
		if (Level.NoInventoryBar)
			return false;
		// This does something important to make sure
		// the first item in the list is valid:
		CPlayer.mo.InvFirst = statusbar.ValidateInvFirst(numfields);
		if (!CPlayer.mo.InvFirst)
			return false;
		// Check the player has a selected item:
		if (!CPlayer.mo.InvSel)
			return false;
		
		return true;
	}

	// This draws a vaguely Silent Hill-style inventory bar,
	// where the selected item is in the center, and the other
	// items are drawn to the left and to the right of it.
	// The bar has no beginning or end and can be scrolled
	// infinitely:
	ui void DrawInventoryBar(int numfields = 7)
	{
		bool previewMode;
		if (!ShouldDrawInvBar(numfields))
		{
			if (IsMenuOpen("JGPHUD_InvBar_menu"))
			{
				previewMode = true;
			}
			else
			{
				return;
			}
		}

		Inventory invSel;
		Inventory invFirst;
		int totalItems;
		if (!previewMode)
		{
			// Cache the currently selected item:
			invSel = CPlayer.mo.InvSel;
			// Calculate the total number of items to display
			// and clamp the number of icons to that value:
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
		}

		int indent = 1;
		double iconSize = GetInvBarIconSize();
		int width = (iconSize + indent) * numfields - indent;
		int height = iconSize;

		// Validate position as usual:
		int flags = SetScreenFlags(c_InvBarPos.GetInt());
		vector2 ofs = (c_InvBarX.GetInt(), c_InvBarY.GetInt());
		vector2 pos = AdjustElementPos((width*0.5, height*0.5), flags, (width, height), ofs);

		// In preview mode we'll simply display a series
		// of pulsing fills the inv slots, and nothing else:
		if (previewMode)
		{
			double spaceWidth = width / numfields;
			int midPoint = ceil(numfields / 2);
			vector2 ppos = (pos.x - width*0.5, pos.y - height*0.5);
			for (int i = 0; i < numfields; i++)
			{
				double amin, amax;
				if (i < midPoint)
				{
					amin = LinearMap(i, 0, midPoint, 0.2, 0.4);
				}
				else
				{
					amin = LinearMap(i, midPoint, numfields - 1, 0.4, 0.2);
				}
				amax = amin + 0.2;
				int alph = int(255 * SinePulse(TICRATE*2, amin, amax, inMenus:true));
				statusbar.Fill(color(alph, 200, 200, 200), ppos.x, ppos.y, spaceWidth, height, flags);
				ppos.x += spaceWidth;
			}
			return;
		}

		vector2 cursOfs = (-iconSize*0.5 - indent, -iconSize*0.5 - indent);
		vector2 cursPos = pos + cursOfs;
		vector2 cursSize = (iconsize + indent*2, indent); //width, height

		// Show some gray fill behind the central icon
		// (which is the selected item):
		color backCol = color(80, 255,255,255);
		statusbar.Fill (backCol, cursPos.x, cursPos.y, cursSize.x, cursSize.x, flags);

		// Show gray gradient fill aimed to the left and right of
		// the selected item when the inventory bar is active,
		// to visually "open it up":
		if (statusbar.IsInventoryBarVisible())
		{
			double alph = backCol.a;
			int steps = 8;
			double sizex = (width*0.5 - cursSize.x) / steps;
			double posx = cursPos.x + cursSize.x;
			for (int i = 0; i < steps; i++)
			{
				alph *= 0.75;
				statusbar.Fill (color(int(alph), backCol.r, backCol.g, backCol.b), posx, cursPos.y, sizex, cursSize.x, flags);
				posx += sizex;
			}
			alph = backCol.a;
			posx = cursPos.x - sizex;
			for (int i = 0; i < steps; i++)
			{
				alph *= 0.75;
				statusbar.Fill (color(int(alph), backCol.r, backCol.g, backCol.b), posx, cursPos.y, sizex, cursSize.x, flags);
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
		statusBar.SetClipRect(pos.x - width*0.5, pos.y - height*0.5, width, height, flags);
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
			if (i != 0 && !statusbar.IsInventoryBarVisible() && c_AlwaysShowInvBar.GetBool())
			{
				alph *= 0.5;
			}
			double scaleFac = LinearMap(i, 0, maxField, 1.0, 0.55);
			double boxSize = iconSize * scaleFac;
			itemPos.x = pos.x + (iconSize + indent) * i + itemPosXOfs;
			TextureID icon = statusbar.GetIcon(item, 0);
			// Scale the icons to fit into the box (but without breaking their
			// aspect ratio):
			statusbar.DrawTexture(icon, itemPos, flags|StatusBarCore.DI_ITEM_CENTER, alph, scale:ScaleToBox(icon, boxSize));
			statusbar.DrawString(numHUDFont, ""..item.amount, itemPos + (boxsize*0.5, boxsize*0.5 - fy), flags|StatusBarCore.DI_TEXT_ALIGN_RIGHT, Font.CR_Gold, alpha: alph, scale:(fntscale, fntscale));
			// If the bar is not visible, stop here:
			if (!statusbar.IsInventoryBarVisible() && !c_AlwaysShowInvBar.GetBool())
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
		statusBar.ClearClipRect();

		// Draw the edges of the cursor:
		color cursCol = color(220, 80, 200, 60);
		// Top edges are always drawn:
		statusbar.Fill (cursCol, cursPos.x, cursPos.y, cursSize.x, cursSize.y, flags); // top
		statusbar.Fill (cursCol, cursPos.x, cursPos.y+cursSize.x-cursSize.y, cursSize.x, cursSize.y, flags); //bottom
		statusbar.Fill (cursCol, cursPos.x, cursPos.y, cursSize.y, cursSize.x, flags); // left
		statusbar.Fill (cursCol, cursPos.x+cursSize.x-cursSize.y, cursPos.y, cursSize.y, cursSize.x, flags); //right
	}

	ui void UpdateInventoryBar(int numfields = 7)
	{
		if (invbarCycleOfs == 0)
			return;

		double iconSize = GetInvBarIconSize();
		double step = (invbarCycleOfs > 0 ? -iconSize : iconsize) * 0.25 * deltaTime;
		invbarCycleOfs = Clamp(invbarCycleOfs + step, min(0, invbarCycleOfs), max(0, invbarCycleOfs));
	}

	// Returns actual next item, or the item
	// at the start of the list if there's nothing:
	ui Inventory NextItem(Inventory item)
	{
		if (item.NextInv())
		{
			return item.NextInv();
		}
		Inventory firstgood = item;
		while (firstgood.owner && firstgood.owner == CPlayer.mo && firstgood.PrevInv())
		{
			firstgood = firstgood.PrevInv();
		}
		return firstgood;
	}

	// Returns actual prev item, or the item
	// at the end of the list if there's nothing:
	ui Inventory PrevItem(Inventory item)
	{
		if (item.PrevInv())
		{
			return item.PrevInv();
		}
		Inventory lastgood = item;
		while (lastgood.owner && lastgood.owner == CPlayer.mo && lastgood.NextInv())
		{
			lastgood = lastgood.NextInv();
		}
		return lastgood;
	}

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

	ui transient CVar c_drawInvBar;
	ui transient CVar c_AlwaysShowInvBar;
	ui transient CVar c_InvBarIconSize;
	ui transient CVar c_InvBarPos;
	ui transient CVar c_InvBarX;
	ui transient CVar c_InvBarY;
	
	ui transient CVar c_drawDamageMarkers;

	ui transient CVar c_drawWeaponSlots;
	ui transient CVar c_WeaponSlotsSize;
	ui transient CVar c_WeaponSlotsAlign;
	ui transient CVar c_WeaponSlotsPos;
	ui transient CVar c_WeaponSlotsX;
	ui transient CVar c_WeaponSlotsY;

	ui transient CVar c_drawPowerups;
	ui transient CVar c_PowerupsIconSize;
	ui transient CVar c_PowerupsPos;
	ui transient CVar c_PowerupsX;
	ui transient CVar c_PowerupsY;

	ui transient CVar c_drawKeys;
	ui transient CVar c_KeysPos;
	ui transient CVar c_KeysX;
	ui transient CVar c_KeysY;

	ui transient CVar c_drawMinimap;
	ui transient CVar c_MinimapEnemyDisplay;
	ui transient CVar c_CircularMinimap;
	ui transient CVar c_minimapSize;
	ui transient CVar c_minimapPos;
	ui transient CVar c_minimapPosX;
	ui transient CVar c_minimapPosY;
	ui transient CVar c_minimapZoom;
	ui transient CVar c_minimapDrawUnseen;
	ui transient CVar c_minimapDrawFloorDiff;
	ui transient CVar c_minimapDrawCeilingDiff;
	ui transient CVar c_MinimapMapMarkersSize;
	ui transient CVar c_minimapBackColor;
	ui transient CVar c_minimapLineColor;
	ui transient CVar c_minimapIntLineColor;
	ui transient CVar c_minimapYouColor;
	ui transient CVar c_minimapMonsterColor;
	ui transient CVar c_minimapFriendColor;

	ui transient CVar c_DrawKills;
	ui transient CVar c_DrawItems;
	ui transient CVar c_DrawSecrets;
	ui transient CVar c_DrawTime;

	ui transient CVar c_DrawEnemyHitMarkers;
	ui transient CVar c_EnemyHitMarkersColor;
	ui transient CVar c_EnemyHitMarkersSize;
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

		if (!c_drawPowerups)
			c_drawPowerups = CVar.GetCvar('jgphud_DrawPowerups', CPlayer);
		if (!c_PowerupsIconSize)
			c_PowerupsIconSize = CVar.GetCvar('jgphud_PowerupsIconSize', CPlayer);
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
		if (!c_minimapDrawUnseen)
			c_minimapDrawUnseen = CVar.GetCvar('jgphud_MinimapDrawUnseen', CPlayer);
		if (!c_minimapDrawFloorDiff)
			c_minimapDrawFloorDiff = CVar.GetCvar('jgphud_MinimapDrawFloorDiff', CPlayer);
		if (!c_minimapDrawCeilingDiff)
			c_minimapDrawCeilingDiff = CVar.GetCvar('jgphud_MinimapDrawCeilingDiff', CPlayer);
		if (!c_minimapMapMarkersSize)
			c_minimapMapMarkersSize = CVar.GetCvar('jgphud_minimapMapMarkersSize', CPlayer);
		if (!c_minimapBackColor)
			c_minimapBackColor = CVar.GetCvar('jpghud_MinimapBackColor', CPlayer);
		if (!c_minimapLineColor)
			c_minimapLineColor = CVar.GetCvar('jgphud_MinimapLineColor', CPlayer);
		if (!c_minimapIntLineColor)
			c_minimapIntLineColor = CVar.GetCvar('jgphud_MinimapIntLineColor', CPlayer);
		if (!c_minimapYouColor)
			c_minimapYouColor = CVar.GetCvar('jgphud_MinimapYouColor', CPlayer);
		if (!c_minimapMonsterColor)
			c_minimapMonsterColor = CVar.GetCvar('jgphud_MinimapMonsterColor', CPlayer);
		if (!c_minimapFriendColor)
			c_minimapFriendColor = CVar.GetCvar('jgphud_MinimapFriendColor', CPlayer);

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
	}
}