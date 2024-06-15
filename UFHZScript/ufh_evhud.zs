class JGPUFH_FlexibleHUD : EventHandler
{
	const ASPECTSCALE = 1.2;
	const CIRCLEANGLES = 360.0;
	const SQUARERADIUSFAC = 1.43;
	const STR_INVALID = "<invalid>";

	private ui PlayerInfo CPlayer;
	private ui transient bool gamePaused;
	private ui transient double prevMSTime;
	private ui transient double deltaTime;
	private ui transient double fracTic;
	private ui transient int HUDTics; //incremented all the time, including while paused
	private ui transient Vector2 hudscale;

	private ui transient bool initDone;
	private bool levelUnloaded;

	const DEFFONT_Main = "BigFont";
	const DEFFONT_Small = "SmallFont";
	const DEFFONT_Num = "NewConsoleFont";
	// Apparently, HUDFont is not properly serializable,
	// so these need to be transient:
	ui transient JGPUFH_FontData mainHUDFont;
	ui transient JGPUFH_FontData smallHUDFont;
	ui transient JGPUFH_FontData numHUDFont;

	array <JGPUFH_PowerupData> powerupData;
	array <MapMarker> mapMarkers;
	
	//Generic shapes
	ui transient Shape2D shape_square;
	ui transient Shape2D shape_disk;

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

	// RGB values for the default text colors from the Font struct
	// Most of these are the 'flat' values as defined in TEXTCOLO,
	// but a few are adjusted because visual inspection showed that
	// in some cases flat values don't look right when transplanted
	// onto a pure color fill.
	static const color RealFontColors[] =
	{
		0xFFcc3333,	// CR_BRICK
		0xFFd2b48c,	// CR_TAN
		0xFFcccccc,	// CR_GREY = CR_GRAY
		0xFF00cc00,	// CR_GREEN
		0xFF996633,	// CR_BROWN
		0xFFffcc00,	// CR_GOLD
		0xFFff0000,	// CR_RED
		0xFF0000FF,	// CR_BLUE
		0xFFffaa00,	// CR_ORANGE
		0xFFFFFFFF,	// CR_WHITE
		0xFFeeee33,	// CR_YELLOW
		-1,			// CR_UNTRANSLATED
		0xFF000000,	// CR_BLACK
		0xFFB4B4FF,	// CR_LIGHTBLUE
		0xFFffcc99,	// CR_CREAM
		0xFFd1d8a8,	// CR_OLIVE
		0xFF008c00,	// CR_DARKGREEN
		0xFF800000,	// CR_DARKRED
		0xFF663333,	// CR_DARKBROWN
		0xFFFF00FF,	// CR_PURPLE
		0xFF808080,	// CR_DARKGRAY
		0xFF00FFFF,	// CR_CYAN
		0xFF343450,	// CR_ICE
		0xFFd57604,	// CR_FIRE
		0xFF506cfc,	// CR_SAPPHIRE
		0xFF236773,	// CR_TEAL
		-1
	};

	// Health/armor bars CVAR values:
	ui LinearValueInterpolator healthIntr;
	ui LinearValueInterpolator armorIntr;
	const MAINBARS_BaseWidth = 120.0;
	const MAINBARS_BaseHeight = 28.0;
	const MUGSHOT_Size = MAINBARS_BaseHeight;
	enum EDrawBars
	{
		DB_NONE,
		DB_DRAWNUMBERS,
		DB_DRAWBARS,
	}
	enum EDrawMugshot
	{
		DF_NONE,
		DF_MAINBARSRIGHT,
		DF_MAINBARSLEFT,
		DF_DETACHED,
	}
	enum EArmorDisplay
	{
		AD_ICON,
		AD_ABSORB,
		AD_BOTH,
	}
	enum ENumberDisplayModes
	{
		ND_FIXED,
		ND_AMOUNT,
		ND_ABSORB,
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
	ui transient Shape2D dmgMarker;
	ui transient Shape2DTransform dmgMarkerTransf;
	ui TextureID dmgMarkerTex;

	// Hit (reticle) markers:
	ui transient Shape2D hitmarker_cross;
	ui transient Shape2D hitmarker_triangles;
	ui transient Shape2D hitmarker_circle;
	ui transient Shape2DTransform reticleMarkerTransform;
	ui double reticleMarkerAlpha;
	ui double reticleMarkerScale;
	
	// Weapon slots
	const WEAPONBARICONSIZE = 16;
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

	// Minimap and monster radar:
	const MAPSCALEFACTOR = 8.;
	ui double prevPlayerAngle;
	ui Vector2 prevPlayerPos;
	ui int prevLevelTime;
	ui array <Line> mapLines;
	ui array <Actor> radarMonsters;
	ui transient Shape2D minimapShape_Arrow;
	ui transient Shape2DTransform minimapTransform;
	enum EMinimapDisplayModes
	{
		MDD_NONE,
		MDD_RADARONLY,
		MDD_MAPONLY,
		MDD_BOTH,
	}
	enum EMapColorType
	{
		MCT_Background,
		MCT_You,
		MCT_Wall,
		MCT_IntWall,
		MCT_Enemy,
		MCT_Friend,
	}
	static const color tradmapcol_DoomColors[] =
	{
		0xff000000, //background
		0xffffffff, //you
		0xfffc0000, //walls
		0xffffffff, //special walls
		0xff74fc6c, //monster
		0xff74fc6c  //friend
	};
	static const color tradmapcol_StrifeColors[] =
	{
		0xff000000, //background
		0xffefef00, //you
		0xffc7c3c3, //walls
		0xffffffff, //special walls
		0xfffc0000, //monster
		0xfffc0000  //friend
	};
	static const color tradmapcol_RavenColors[] =
	{
		0xff6c5440, //background
		0xffffffff, //you
		0xff4b3210, //walls
		0xffffffff, //special walls
		0xffececec, //monster
		0xffececec  //friend
	};

	// DrawInventoryBar():
	const ITEMBARICONSIZE = 18;
	ui Inventory prevInvSel;
	ui double invbarCycleOfs;
	ui bool pressedInvNext;

	// DrawCustomItems():
	ui array < class<Inventory> > customItems;

	// DrawReticleBars():
	const MARKERSDELAY = TICRATE*2;
	const BARCOVERANGLE = 80.0;
	JGPUFH_LookTargetController lookControllers[MAXPLAYERS];
	ui transient Shape2D roundBars;
	ui transient Shape2D roundBarsAngMask;
	ui transient Shape2D roundBarsInnerMask;
	ui transient Shape2D genRoundMask;
	ui transient Shape2DTransform roundBarsTransform;
	ui transient Shape2DTransform genRoundMaskTransfInner;
	ui transient Shape2DTransform genRoundMaskTransfOuter;
	ui double prevArmAmount;
	ui double prevArmMaxAmount;
	ui int prevHealth;
	ui int prevMaxHealth;
	ui int prevAmmo1Amount;
	ui int prevAmmo1MaxAmount;
	ui int prevAmmo2Amount;
	ui int prevAmmo2MaxAmount;
	ui int largestAmmoAmt;
	ui int largestAmmoMaxAmt;
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
		if (sourceDiff == 0) return 0;

		double d = (val - source_min) * (out_max - out_min) / sourceDiff + out_min;
		if (clampit) 
		{
			double truemax = out_max > out_min ? out_max : out_min;
			double truemin = out_max > out_min ? out_min : out_max;
			d = Clamp(d, truemin, truemax);
		}
		return d;
	}

	clearscope double Lerp(double from, double to, double frac)
	{
		return (from * (1.0 - frac)) + (to * frac);
	}

	clearscope double RoundToDecimal(double val, int places = 1)
	{
		int i = places**10;
		return round (val * i) / i;
	}

	clearscope bool IsVoodooDoll(PlayerPawn mo)
	{
		return !mo.player || !mo.player.mo || mo.player.mo != mo;
	}
	override void WorldThingSpawned(worldEvent e)
	{
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

	override bool InputProcess (InputEvent e)
	{
		array<int> buttons;
		Bindings.GetAllKeysForCommand(buttons, "invnext");
		if(buttons.Find(e.keyScan) != buttons.Size())
		{
			pressedInvNext = true;
		}
		buttons.Clear();
		Bindings.GetAllKeysForCommand(buttons, "invprev");
		if(buttons.Find(e.keyScan) != buttons.Size())
		{
			pressedInvNext = false;
		}
		return false;
	}

	override void WorldLoaded(worldEvent e)
	{
		if (powerupData.Size() > 0)
			return;
		
		for (int i = 0; i < AllActorClasses.Size(); i++)
		{
			let cls = AllActorClasses[i];
			if (!cls)
				continue;
			
			let pwrg = (class<PowerupGiver>)(cls);
			if (pwrg)
			{
				JGPUFH_PowerupData.CreatePowerupIcon(pwrg, powerupData);
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

	ui int GetHUDTics()
	{
		return HUDTics;
	}

	ui bool CanDrawFlexiHUD()
	{
		return c_enable.GetBool() &&
               gamestate == GS_LEVEL && gamestate != GS_TITLELEVEL &&
               CPlayer && CPlayer.mo && 
               CPlayer.camera == CPlayer.mo;
	}

	ui void UiInit()
	{
		if (initDone)
			return;

		SetupHUDFont();
		GetCustomItemsList();

		initDone = 	mainHUDFont && mainHUDFont.IsValid() && 
					smallHUDFont && smallHUDFont.IsValid() && 
					numHUDFont && numHUDFont.IsValid();
	}

	override void UiTick()
	{
		if (!CPlayer || !CPlayer.mo || !initDone)
			return;

		HUDTics++;
		if (!c_enable || !c_enable.GetBool())
			return;
		UpdateEnemyRadar();
		UpdateMinimapLines();
		if (!gamePaused)
		{
			UpdateHealthArmor();
			UpdateWeaponSlots();
			UpdatePlayerAngle();
			UpdateInterpolators();
		}
	}

	override void RenderOverlay(renderEvent e)
	{
		// Cache CVars before anything else:
		CacheCvars();
		UpdateDeltaTime();
		fracTic = e.fracTic;
		hudscale = statusbar.GetHudScale();
		if (!CanDrawFlexiHUD())
		{
			return;
		}

		UiInit();
		if (!initDone)
			return;

		statusbar.BeginHUD();
		CreateGenericShapes(); //used by the minimap and hitmarkers
		// These value updates need to be interpolated
		// with deltatime, so they happen here rather
		// than in UiTick(). They also shouldn't
		// progress if a menu is open:
		gamePaused = Menu.GetCurrentMenu();
		if (!gamePaused)
		{
			UpdateInventoryBar(deltaTime);
			UpdateReticleBars(deltaTime);
			UpdateEnemyHitMarker(deltaTime);
		}
		
		// Do not draw stuff if automap is open. This is,
		// because, one, if the user is using one of the
		// vanilla HUDs, a statusbar version will already
		// be drawn on the automap; and two, this just
		// gets noisy and not very necessary.
		if (autoMapActive)
			return;

		DrawPowerups();
		DrawKeys();
		DrawHealthArmor();
		DrawDamageMarkers();
		DrawWeaponBlock();
		DrawAllAmmo();
		DrawWeaponSlots();
		DrawMinimap();
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
	ui Vector2 AdjustElementPos(Vector2 pos, int flags, Vector2 size, Vector2 ofs = (0,0), bool real = false)
	{
		let hudscale = self.hudscale;
		Vector2 screenSize = (0,0);
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
		ofs = AdjustElementOffset(ofs);
		pos += ofs;
		return pos;
	}

	// Feed offsets from AdjustElementPos to this function.
	// What this does is, it makes sure that the offsets
	// (which are controllable by the player) always work
	// in such a way that the element can be adjusted around
	// exactly a quarter of the screen. Even when offsets are
	// being applied through virtual resolution, this can't
	// be done properly, because their distance is dependent
	// on real resolution AND the current UI scale value.
	ui Vector2 AdjustElementOffset(Vector2 ofs)
	{
		if (!c_cleanoffsets || !c_cleanoffsets.GetBool())
		{
			return ofs;
		}
		return ofs * (4.0 / hudscale.x);
	}

	ui double GetElementScale(CVar check)
	{
		if (!check)
		{
			return 1.0;
		}
		double scale = Clamp(check.GetFloat(), 0.01, 30.0);
		double baseFac = c_BaseScale ? c_BaseScale.GetFloat() : 1.0;
		if (baseFac > 0.0)
		{
			scale *= baseFac;
		}
		return scale;
	}

	// To use with DrawShapeFill which uses BGR:
	clearscope color RGB2BGR(color col)
	{
		return color(col.b, col.g, col.r);
	}

	ui Vector2 ScaleToBox(TextureID tex, double squareSize)
	{
		Vector2 size = TexMan.GetScaledSize(tex);
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

	ui void SetupHUDFont()
	{
		CVar cv;

		cv = CVar.GetCVar('jgphud_mainfont', CPlayer);
		if (cv && !cv.GetString())
		{
			cv.SetString(DEFFONT_Main);
		}
		mainHUDFont = JGPUFH_FontData.Create(DEFFONT_Main, (0.8,0.8));

		cv = CVar.GetCVar('jgphud_smallfont', CPlayer);
		if (cv && !cv.GetString())
		{
			cv.SetString(DEFFONT_Small);
		}
		smallHUDFont = JGPUFH_FontData.Create(DEFFONT_Small, (1, 1));
		
		cv = CVar.GetCVar('jgphud_numberfont', CPlayer);
		if (cv && !cv.GetString())
		{
			cv.SetString(DEFFONT_Num);
		}
		numHUDFont = JGPUFH_FontData.Create(DEFFONT_Num, (0.4, 0.4));
	}

	ui double GetFontHeight(JGPUFH_FontData fdata, double scale = 1.0)
	{
		if (!fdata)
			fdata = mainHUDFont;

		return fdata.d_font.GetGlyphHeight("0") * fdata.d_scale.y * scale;
	}

	ui HUDFont, Vector2 GetHUDFont(JGPUFH_FontData fdata)
	{
		if (!fdata)
			fdata = mainHUDFont; //safeguard

		CVar cv;
		if (fdata == mainHUDFont)
		{
			cv = CVar.GetCVar('jgphud_mainfont', CPlayer);
			if (!mainHUDFont.Update(cv.GetString()))
			{
				cv.SetString(mainHUDFont.d_fontname);
			}
		}
		else if (fdata == smallHUDFont)
		{
			cv = CVar.GetCVar('jgphud_smallfont', CPlayer);
			if (!smallHUDFont.Update(cv.GetString()))
			{
				cv.SetString(smallHUDFont.d_fontname);
			}
		}
		else if (fdata == numHUDFont)
		{
			cv = CVar.GetCVar('jgphud_numberfont', CPlayer);
			if (!numHUDFont.Update(cv.GetString()))
			{
				cv.SetString(numHUDFont.d_fontname);
			}
		}
		return fdata.d_hudfont, fdata.d_scale;
	}

	// Returns the color (or texture, if available)
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
		Vector2 box = (width, height);
		Vector2 pos = (xPos, yPos);
		
		// Stretch to fit mode:
		if (c_BackTextureStretch.GetBool())
		{
			statusbar.DrawTexture(tex, pos, flags, alpha, box, col: texCol);
			return;
		}
		
		// Otherwise tile the texture:

		// Get texture size and aspect ratio:
		Vector2 size = TexMan.GetScaledSize(tex);
		double texaspect = size.x / size.y;
		// If the texture is wider than it is tall:
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
		double time = inMenus ? GetHUDTics() : Level.mapTime;
		double pulseVal = 0.5 + 0.5 * sin(360.0 * (time + fracTic) / frequency);
		return LinearMap(pulseVal, 0.0, 1.0, startVal, endVal);
	}

	// Returns true if the menu belonging to the
	// specified class is currently open:
	ui bool IsModMenuOpen()
	{
		let mnu = Menu.GetCurrentMenu();
		return mnu && (mnu is 'JGPUFH_OptionMenu');
	}

	// Wrappers to enable and disable stencil masks:
	ui void EnableMask(int ofs, Shape2D mask, bool invert = false)
	{
		Screen.EnableStencil(true);
		Screen.SetStencil(0, SOP_Increment, SF_ColorMaskOff);
		Screen.DrawShapeFill(color(0,0,0), 1, mask);
		Screen.SetStencil(invert ? 0 : ofs, SOP_Keep, SF_AllOn);
	}

	ui void DisableMask()
	{
		Screen.EnableStencil(false);
		Screen.ClearStencil();
	}

	// Draws a bar using Fill()
	// If segments is above 0, will use multiple fills to create a segmented bar
	ui void DrawFlatColorBar(Vector2 pos, double curValue, double maxValue, color barColor, int valueColor = -1, double barwidth = 64, double barheight = 8, double indent = 0.6, color backColor = color(255, 0, 0, 0), double sparsity = 1, uint segments = 0, int flags = 0)
	{
		Vector2 barpos = pos;
		// This flag centers the bar vertically. I didn't add
		// horizontal centering because it felt useless, since
		// all bars in the HUD go from left to right:
		if (flags & StatusBarCore.DI_ITEM_CENTER)
		{
			barpos.y -= barheight*0.5;
		}

		// Background color (fills whole width):
		statusbar.Fill(backColor, barpos.x, barpos.y, barwidth, barheight, flags);
		// The bar itself is indented against the background:
		double innerBarWidth = barwidth - (indent * 2);
		double innerBarHeight = barheight - (indent * 2);
		Vector2 innerBarPos = (barpos.x + indent, barpos.y + indent);
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
			Vector2 segPos = innerBarPos;
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
			String str = ""..int(curvalue);
			HUDFont fnt = GetHUDFont(mainHUDFont);
			// Scale the font to fit the height of the bar (minus indent).
			// This is the only place in FlexiHUD where we're not using
			// GetFontHeight() and instead getting the physical height of
			// the font directly, to match it precisely to the height of the bar:
			// real height:
			Font f = fnt.mFont;
			double fontHeight = max(f.GetGlyphHeight("0"), f.GetGlyphHeight("1"), f.GetGlyphHeight("A"));
			// multiplier to match it to the bar height minus indent:
			double fntScale = (barheight - indent*2) / fontHeight;
//			if (jgphud_debug)
//			{
//				Console.MidPrint(smallfont, String.Format(
//						"font: \cd%s"
//						"\ntarget height: \cd%.2f"
//						"\nGetHeight(): \cd%d"
//						"\nGetGlyphHeight(): \cd%d"
//						"\nGetDisplacement(): \cd%d"
//						"\nGetBottomAlignOffset(): \cd%d"
//						"\nGetMaxAscender(): \cd%d"
//						"\nfinal height: \cd%.2f",
//						mainHUDFont.d_fontname,
//						barheight - indent*2,
//						fnt.mFont.GetHeight(),
//						fnt.mFont.GetGlyphHeight("0"),
//						fnt.mFont.GetDisplacement(),
//						fnt.mFont.GetBottomAlignOffset("0"),
//						fnt.mFont.GetMaxAscender("0"),
//						fontheight * fntScale
//					)
//				);
//			}
			// position the string exactly at the middle:
			Vector2 strPos = barpos + (barwidth * 0.5, indent); 
			statusbar.DrawString(fnt, str, strPos, flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: valueColor, scale:(fntScale,fntScale));
		}
	}

	ui color, int GetHealthColor(int health, int maxhealth)
	{
		double ratio = double(health) / double(maxhealth);
		color col;
		int fontColor;
		if (c_MainBarsHealthColorMode.GetInt() == ND_FIXED)
		{
			fontColor = c_MainBarsHealthColor.GetInt();
			int i = Clamp(fontColor, 0, RealFontColors.Size() - 1);
			col = RealFontColors[i];
			return col, fontColor;
		}
		int startcol, endcol;
		double colorDist;
		if (ratio <= 0.25)
		{
			startcol = c_MainbarsHealthRange_25.GetInt();
			endcol = c_MainbarsHealthRange_25.GetInt();
			colorDist = LinearMap(ratio, 0, 0.25, 0.0, 1.0);
		}
		else if (ratio <= 0.5)
		{
			startcol = c_MainbarsHealthRange_25.GetInt();
			endcol = c_MainbarsHealthRange_50.GetInt();
			colorDist = LinearMap(ratio, 0.25, 0.5, 0.0, 1.0);
		}
		else if (ratio <= 0.75)
		{
			startcol = c_MainbarsHealthRange_50.GetInt();
			endcol = c_MainbarsHealthRange_75.GetInt();
			colorDist = LinearMap(ratio, 0.5, 0.75, 0.0, 1.0);
		}
		else if (ratio <= 1.0)
		{
			startcol = c_MainbarsHealthRange_75.GetInt();
			endcol = c_MainbarsHealthRange_100.GetInt();
			colorDist = LinearMap(ratio, 0.75, 1.0, 0.0, 1.0);
		}
		else
		{
			startcol = c_MainbarsHealthRange_100.GetInt();
			endcol = c_MainbarsHealthRange_101.GetInt();
			colorDist = LinearMap(ratio, 1.0, 1.1, 0.0, 1.0);
		}
		fontColor = endcol;
		startcol = Clamp(startcol, 0, RealFontColors.Size() - 1);
		endcol = Clamp(endcol, 0, RealFontColors.Size() - 1);
		Color finalColor = GetIntermediateColor(RealFontColors[startcol], RealFontColors[endcol], colorDist);
		return finalColor, fontColor;
	}

	clearscope color GetIntermediateColor(color c1, color c2, double colordistance)
	{
		colordistance = Clamp(colordistance, 0.0, 1.0);
		Color finalColor = color(
			255,
			int(round(C1.r + (C2.r - C1.r)*colordistance)),
			int(round(C1.g + (C2.g - C1.g)*colordistance)),
			int(round(C1.b + (C2.b - C1.b)*colordistance))
		);
		return finalcolor;
	}

	// Returns a color and font colors based on the provided
	// percentage value (either in the 0.0-1.0 or 0-100 range).
	// Meant to be used for armor's savepercent, so it's tuned
	// to common savepercent values (50, 80 and 33):
	ui color, int GetArmorColor(double savePercent)
	{
		color col;
		int fontColor;
		if (c_MainBarsArmorColorMode.GetInt() == ND_FIXED)
		{
			fontColor = c_MainBarsArmorColor.GetInt();
			int i = Clamp(fontColor, 0, RealFontColors.Size() - 1);
			col = RealFontColors[i];
			return col, fontColor;
		}
		int startcol;
		int endcol;
		double colorDist;
		if (savePercent <= 0.33)
		{
			startcol = c_MainbarsAbsorbRange_33.GetInt();
			endcol = c_MainbarsAbsorbRange_33.GetInt();
			colorDist = LinearMap(savePercent, 0, 0.33, 0.0, 1.0);
		}
		else if (savePercent <= 0.5)
		{
			startcol = c_MainbarsAbsorbRange_33.GetInt();
			endcol = c_MainbarsAbsorbRange_50.GetInt();
			colorDist = LinearMap(savePercent, 0, 0.33, 0.5, 1.0);
		}
		else if (savePercent <= 0.66)
		{
			startcol = c_MainbarsAbsorbRange_50.GetInt();
			endcol = c_MainbarsAbsorbRange_66.GetInt();
			colorDist = LinearMap(savePercent, 0, 0.5, 0.66, 1.0);
		}
		else if (savePercent <= 0.8)
		{
			startcol = c_MainbarsAbsorbRange_66.GetInt();
			endcol = c_MainbarsAbsorbRange_80.GetInt();
			colorDist = LinearMap(savePercent, 0, 0.66, 0.8, 1.0);
		}
		else
		{
			startcol = c_MainbarsAbsorbRange_80.GetInt();
			endcol = c_MainbarsAbsorbRange_100.GetInt();
			colorDist = LinearMap(savePercent, 0, 0.8, 1.0, 1.0);
		}
		fontColor = endcol;
		startcol = Clamp(startcol, 0, RealFontColors.Size() - 1);
		endcol = Clamp(endcol, 0, RealFontColors.Size() - 1);
		Color finalColor = GetIntermediateColor(RealFontColors[startcol], RealFontColors[endcol], colorDist);
		return finalColor, fontColor;
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

		if (!healthIntr && healthMaxAmount > 0)
		{
			healthIntr = LinearValueInterpolator.Create(healthMaxAmount, 1);
			healthIntr.Reset(healthAmount);
		}
		if (!armorIntr && armMaxAmount > 0)
		{
			armorIntr = LinearValueInterpolator.Create(armMaxAmount, 1);
			armorIntr.Reset(armAmount);
		}
	}

	ui double GetHealthInterpolated()
	{
		if (healthIntr)
			return healthIntr.GetValue();
		return healthAmount;
	}

	ui double GetArmorInterpolated()
	{
		if (armorIntr)
			return armorIntr.GetValue();
		return healthAmount;
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
		armMaxAmount = 0;
		hasHexenArmor = false;
		if (barm)
		{
			armAmount = barm.amount;
			armMaxAmount = barm.maxamount;
			armorColor = GetArmorColor(barm.savePercent);
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
				for (int i = 0; i < hexarm.slotsIncrement.Size(); i++)
				{
					armMaxamount += hexarm.slotsIncrement[i];
				}
				armMaxamount += hexarm.slots[4];
				armorColor = GetArmorColor(armAmount / armMaxAmount);
			}
		}
	}

	ui void DrawHealthCross(Vector2 pos, Vector2 size = (4, 10), double scale = 1.0, int flags = 0)
	{
		bool hasBerserk = CPlayer.mo.FindInventory('PowerStrength', true);

		//MakeHearthShape();
		//pos = AdjustElementPos(pos, flags, size, real:true);
		//heartShapeTransform.Clear();
		//heartShapeTransform.Scale((size.y * hudscale.x * scale, size.y * hudscale.y * scale));
		//heartShapeTransform.Translate(pos);
		//heartShape.SetTransform(heartShapeTransform);
		//color col = hasBerserk? color(0, 0, 255) : color(255, 255, 255);
		//double alph = 1.0;
		//if (healthAmount <= healthMaxAmount*0.25)
		//{
			//alph = SinePulse(LinearMap(healthAmount, 0, healthMaxAmount*0.25, TICRATE*0.5, TICRATE), 0.5, 1.0);
		//}
		//Screen.DrawShapeFill(col, alph, heartShape);
		//return;

		double crossWidth = size.x * scale;
		double crossLength = size.y * scale;
		color crossCol = hasBerserk ? color(255,255,0,0) : color(255,0,0,0);
		statusbar.Fill(crossCol, pos.x - crossWidth*0.5,  pos.y - crossLength*0.5, crossWidth, crossLength, flags);
		statusbar.Fill(crossCol, pos.x - crossLength*0.5, pos.y - crossWidth*0.5, crossLength, crossWidth, flags);
		
		double indent = crossWidth * (hasBerserk ? 0.375 : 0.5);
		crossWidth -= indent;
		crossLength -= indent;
		crossCol = hasBerserk ? color(255,0,0,0) : color(255,255,255,255);
		statusbar.Fill(crossCol, pos.x - crossWidth*0.5, pos.y - crossLength*0.5, crossWidth, crossLength, flags);
		statusbar.Fill(crossCol, pos.x - crossLength*0.5, pos.y - crossWidth*0.5,  crossLength, crossWidth, flags);
	}

	ui void DrawHealthArmor()
	{
		int drawFace = ShouldDrawMugshot();
		if (drawFace == DF_DETACHED)
		{
			int flags = SetScreenFlags(c_MugshotPos.GetInt());
			double scale = GetElementScale(c_MugshotScale);
			double size = MUGSHOT_Size * scale;
			Vector2 ofs = ( c_MugshotX.GetInt(), c_MugshotY.GetInt() );
			Vector2 pos = AdjustElementPos((0,0), flags, (size, size), ofs);
			DrawMugshotFace(pos, flags, size);
		}
		int drawThis = c_drawMainbars.GetInt();
		if (drawThis <= DB_NONE || !healthAmount || !healthMaxAmount)
		{
			return;
		}

		double width = MAINBARS_BaseWidth;
		double height = MAINBARS_BaseHeight;
		double scale = GetElementScale(c_MainBarsScale);
		height *= scale;
		width *= scale;
		if (drawThis < DB_DRAWBARS)
		{
			width *= 0.5;
		}
		double barheight = height * 0.4;
		int flags = SetScreenFlags(c_MainBarsPos.GetInt());
		bool drawbars = drawThis >= DB_DRAWBARS;
		Vector2 ofs = ( c_MainBarsX.GetInt(), c_MainBarsY.GetInt() );
		Vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		if (drawFace == DF_MAINBARSLEFT || drawFace == DF_MAINBARSRIGHT)
		{
			Vector2 facePos = pos;
			bool leftScreenSide = (flags == StatusBarCore.DI_SCREEN_LEFT_TOP || flags == StatusBarCore.DI_SCREEN_LEFT_CENTER || flags == StatusBarCore.DI_SCREEN_LEFT_BOTTOM);
			bool rightScreenSide = (flags == StatusBarCore.DI_SCREEN_RIGHT_TOP || flags == StatusBarCore.DI_SCREEN_RIGHT_CENTER || flags == StatusBarCore.DI_SCREEN_RIGHT_BOTTOM);
			if (drawFace == DF_MAINBARSLEFT)
			{
				if (rightScreenSide)
				{
					facePos.x -= height + 1;
				}
				else
				{
					pos.x += height + 1;
				}
			}
			else if (drawFace == DF_MAINBARSRIGHT)
			{
				if (leftScreenSide)
				{
					facePos.x += width + 1;
				}
				else
				{
					facePos.x += width - height;
					pos.x -= height + 1;
				}
			}
			DrawMugshotFace(facepos, flags, height);
		}

		// bars background:
		BackgroundFill(pos.x, pos.y, width, height, flags);
		int barFlags = flags|StatusBarCore.DI_ITEM_CENTER;
		int indent = 4 * scale;
		double iconSize = 8 * scale;
		Vector2 iconPos = (pos.x + indent + iconsize * 0.5, pos.y + height*0.75);

		// Draw health cross shape (instead of drawing a health item):
		DrawHealthCross(iconPos, (4, 10), scale, barflags);
		
		// Calculate bar width (it should be indented deeper
		// from the edges and offset from the icon):
		int barWidth = width - iconSize - indent*3;
		double barPosX = iconPos.x + iconsize*0.5 + indent;
		// Color/font data:
		HUDFont fnt; Vector2 fntscale;
		[fnt, fntscale] = GetHUDFont(mainHUDFont);
		fntScale *= scale;
		double fy = GetFontHeight(mainHUDFont, scale);
		color cColor; int cFntCol;
		[cColor, cFntCol] = GetHealthColor(healthAmount, healthMaxAmount);
		// Draw health bar or numbers:
		if (drawbars)
		{
			DrawFlatColorBar((barPosX, iconPos.y), GetHealthInterpolated(), healthMaxAmount, color(200, 255, 255, 255), barwidth:barWidth, barheight: barheight, flags:barFlags);
			DrawFlatColorBar((barPosX, iconPos.y), healthAmount, healthMaxAmount, cColor, valueColor: Font.CR_White, barwidth:barWidth, barheight: barheight, backColor: color(0,0,0,0), flags:barFlags);
		}
		else
		{
			String healthstring = String.Format("%3d", healthAmount);
			statusbar.DrawString(fnt, healthstring, (barPosX, iconPos.y - fy*0.5), flags, translation:cFntCol, scale: fntScale);
		}
		
		// Draw armor bar:
		// Check if armor exists and is above 0
		if (armAmount <= 0)
		{
			return;
		}

		let barm = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		let hexarm = HexenArmor(CPlayer.mo.FindInventory("HexenArmor"));
		TextureID armTex;
		double armTexSize = 12 * scale;
		if (!hasHexenArmor && barm)
		{
			[cColor, cFntCol] = GetArmorColor(barm.savePercent);
			armTex = barm.icon;
		}
		if (hasHexenArmor && hexArm)
		{
			[cColor, cFntCol] = GetArmorColor(armAmount / armMaxAmount);
		}

		iconPos.y = pos.y + height * 0.25;
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
				hArmTex.Push(hexenArmorIcons[i]);
			}
			// If any icons have been pushed, draw them:
			if (hArmTex.Size() > 0)
			{
				// If there's only one armor piece, draw it as usual:
				if (hArmTex.Size() == 1)
				{
					armTex = hArmTex[0];
					statusbar.DrawTexture(armTex, iconPos, flags|StatusBarCore.DI_ITEM_CENTER, box:(armTexSize,armTexSize), scale:(scale,scale));
				}
				// If there's more, draw smaller version of them in
				// a 2x2 pattern:
				else
				{
					armTexSize *= 0.5;
					double ofs = armTexSize*0.5;
					Vector2 armPos;
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

						statusbar.DrawTexture(armTex, armPos, flags|StatusBarCore.DI_ITEM_CENTER, box:(armTexSize,armTexSize), scale:ScaleToBox(armTex, armTexSize));
					}
				}
			}
		}

		// uses normal armor:
		else
		{
			int mode = c_MainBarsArmorMode.GetInt();
			if ((mode == AD_ICON || mode == AD_BOTH) && armTex.IsValid())
			{
				statusbar.DrawTexture(armTex, iconPos, flags|StatusBarCore.DI_ITEM_CENTER, box:(armTexSize,armTexSize), scale:ScaleToBox(armTex, armTexSize));
			}
			if (mode == AD_ABSORB || mode == AD_BOTH)
			{
				HUDFont fnt2; Vector2 fntscale2;
				[fnt2, fntscale2] = GetHUDFont(numHUDFont);
				fntscale2 *= scale;
				double fy = GetFontHeight(numHUDFont, scale);
				String sp = String.Format("%d%%", round(100 * barm.savepercent));
				statusbar.DrawString(fnt2, sp, iconPos - (0, fy*0.5), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, scale:fntscale2);
			}
		}

		if (drawbars)
		{
			DrawFlatColorBar((barPosX, iconPos.y), GetArmorInterpolated(), armMaxamount, color(200, 255, 255, 255), barwidth:barWidth, barheight: barheight*0.8, segments: barm.maxamount / 10, flags:barFlags);
			DrawFlatColorBar((barPosX, iconPos.y), armAmount, armMaxamount, cColor, valueColor: Font.CR_White, barwidth:barWidth, barheight*0.8, backColor: color(0,0,0,0), segments: barm.maxamount / 10, flags:barFlags);
		}
		else
		{
			statusbar.DrawString(fnt, String.Format("%3d", armAmount), (barPosX, iconPos.y - fy*0.5), flags, translation:cFntCol, scale:fntScale);
		}
	}

	ui int ShouldDrawMugshot()
	{
		TextureID tex = StatusBar.GetMugShot(5);
		if (!tex || !tex.IsValid())
		{
			return DF_NONE;
		}
		return c_drawMugshot.GetInt();
	}

	ui void DrawMugshotFace(Vector2 pos, int flags, double size)
	{
		BackgroundFill(pos.x, pos.y, size, size, flags);
		TextureID facetex = statusBar.GetMugShot(5);
		statusbar.DrawTexture(facetex, (pos.x + size*0.5, pos.y + size*0.5), flags|StatusBarCore.DI_ITEM_CENTER, scale: ScaleToBox(facetex, size - 2));
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
		Vector2 ofs = ( c_AmmoBlockX.GetInt(), c_AmmoBlockY.GetInt() );
		double scale = GetElementScale(c_AmmoBlockScale);
		
		// As usual, calculate total block size first to do the fill.

		// Check if the weapon is using any ammo:
		Ammo am1, am2;
		int am1amt, am2amt;
		[am1, am2, am1amt, am2amt] = statusbar.GetCurrentAmmo();

		// X size is fixed, we'll calculate Y size from here:
		int indent = 1 * scale;
		Vector2 size = (66, 0) * scale;
		// predefine size for the weapon icon and ammo icon boxes:
		Vector2 weapIconBox = (size.x - indent*2, 18 * scale);
		Vector2 ammoIconBox = (size.x * 0.25 - indent*4, 16 * scale);
		double ammoTextHeight = GetFontHeight(mainHUDFont, scale);
		// If we're drawing the ammo bar, add its height and indentation
		// to total height:
		bool drawAmmobar = c_drawAmmoBar.GetBool();
		int ammoBarHeight = 8 * scale;
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
		Vector2 pos = AdjustElementPos((0,0), flags, (size.x, size.y), ofs);
		BackgroundFill(pos.x, pos.y, size.x, size.y, flags);
		
		if (weapIconValid)
		{
			statusbar.DrawTexture(weapIcon, pos + (weapIconBox.x  * 0.5 + indent, size.y - weapIconBox.y * 0.5 - indent), flags|StatusBarCore.DI_ITEM_CENTER, box: (64, 18) * scale, scale:(scale,scale));
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
		Vector2 ammo1pos = pos + (size.x * 0.5, ammoIconBox.y * 0.5 + indent);
		Vector2 ammo2pos = ammo1pos;
		// Calculate position for ammo amount text, placed right
		// below the ammo icon:
		Vector2 ammoTextPos = ammo1pos + (0, ammoIconBox.y*0.5 + indent);
		// And now the ammo bar width:
		int barwidth = size.x - indent*2;
		// and the ammo bar pos:
		Vector2 ammoBarPos = ammoTextPos + (-barwidth*0.5, ammoTextHeight + indent);
		int segments;
		
		HUDFont fnt; Vector2 fntScale;
		[fnt, fntscale] = GetHUDFont(mainHUDFont);
		fntScale *= scale;

		// Uses only 1 ammo type - draw as calculated:
		if ((am1 && !am2) || (!am1 && am2) || (am1 == am2))
		{
			Ammo am = am1 ? am1 : am2;
			statusbar.DrawInventoryIcon(am, ammo1pos, flags|StatusBarCore.DI_ITEM_CENTER, boxSize: ammoIconBox, scale:(scale,scale));
			statusbar.DrawString(fnt, ""..am.amount, ammoTextPos, flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am.amount, am.maxamount), scale:fntScale);
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
			statusbar.DrawInventoryIcon(am1, ammo1pos, flags|StatusBarCore.DI_ITEM_CENTER, boxSize: ammoIconBox, scale:(scale,scale));
			statusbar.DrawString(fnt, ""..am1amt, (ammo1pos.x, ammoTextPos.y), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am1.amount, am1.maxamount), scale:fntScale);
			statusbar.DrawInventoryIcon(am2, ammo2pos, flags|StatusBarCore.DI_ITEM_CENTER, boxSize: ammoIconBox, scale:(scale,scale));
			statusbar.DrawString(fnt, ""..am2amt, (ammo2pos.x, ammoTextPos.y), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am2.amount, am2.maxamount), scale:fntScale);
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
				AddWeaponAmmoToList(weap, ammoItems, mode);
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
				AddWeaponAmmoToList(weap, ammoItems, mode);
			}
		}

		int totalAmmo = ammoItems.Size();
		if (totalAmmo <= 0)
			return;
		
		// base scale, position and offsets:
		double scale = GetElementScale(c_AllAmmoScale);
		double iconSize = 6 * scale;
		int indent = 1 * scale;
		int flags = SetScreenFlags(c_AllAmmoPos.GetInt());
		Vector2 ofs = ( c_AllAmmoX.GetInt(), c_AllAmmoY.GetInt() );

		// font and font scale:
		HUDFont hfnt; Vector2 fntScale;
		[hfnt, fntscale] = GetHUDFont(numHUDFont);
		fntscale *= scale;
		double fy = GetFontHeight(numHUDFont, scale);

		// columns, padding, total width and height of the element:
		int columns = Clamp(c_AllAmmoColumns.GetInt(), 1, totalAmmo);
		int rows = ceil(totalAmmo / double(columns));
		bool showMax = c_AllAmmoShowMax.GetBool();
		bool showBar = c_AllAmmoShowBar.GetBool();
		int largestAmt = max(largestAmmoAmt, largestAmmoMaxAmt);
		// Always use full width if drawing a bar:
		String ammoString = (showMax || showBar)? String.Format("%d/%d", largestAmt, largestAmt) : String.Format("%d", largestAmt);
		double ammoStrWidth = hfnt.mFont.StringWidth(ammoString) * fntScale.x;
		if (showbar && showmax)
		{
			ammoStrWidth *= 1.25;
		}
		double singleColumnWidth = iconsize + indent*4 + ammoStrWidth;
		double singleRowHeight = max(fy, iconsize) + indent;
		double width = singleColumnWidth * columns;
		double height = singleRowHeight * rows;

		// set position:
		Vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);

		// Finally, draw the ammo:
		// Get current HUD background color
		// and current weapon's ammo:
		color col = GetHUDBackground();
		Ammo a1, a2;
		[a1, a2] = statusbar.GetCurrentAmmo();
		Vector2 curPos = pos;
		int curRow = 0;
		// Pad numbers if min/max is shown; otherwise no need for padding:
		int padding = String.Format("%d", largestAmt).Length();
		Vector2 barPos, innerBarPos, barSize, innerBarSize;
		barSize = (ammoStrWidth + indent*2, iconSize);
		double barIndent = barSize.y * 0.1;
		innerBarSize = (barSize.x - barIndent*2, barSize.y - barIndent*2);
		color lowColor = c_AllAmmoColorLow.GetInt();
		color highColor = c_AllAmmoColorHigh.GetInt();
		for (int i = 0; i < ammoitems.Size(); i++)
		{			
			Ammo am = ammoItems[i];
			if (!am)
				continue;
			bool current = (am == a1 || am == a2);
			// Draw color fill behind the ammo if it matches
			// the currently used weapon (but only if bars
			// aren't being drawn, otherwise the bars will
			// handle highlighting):
			if (!showBar && current)
			{
				statusbar.Fill(color(128, 255 - col.r, 255 - col.g, 255 - col.b), curPos.x, curPos.y, singleColumnWidth, iconSize, flags);
			}
			// draw the bar:
			if (showbar)
			{
				barPos = (curPos.x + iconSize + indent, curPos.y);
				innerBarPos = (barPos.x+barIndent, barPos.y+barIndent);
				// outline (current selection):
				if (current)
					statusbar.Fill(0xFFFFFFFF, curPos.x, barPos.y, singleColumnWidth, barSize.y, flags);
				// background:
				int barAlpha = current? 255 : 160;
				statusbar.Fill(color(barAlpha, 0,0,0), innerBarPos.x, innerBarPos.y, innerBarSize.x, innerBarSize.y, flags);
				// foreground:
				double amFac = LinearMap(am.amount, 0, am.maxamount, 0.0, 1.0, true);
				color barColor = GetIntermediateColor(lowColor, highColor, amFac);
				statusbar.Fill(color(barAlpha, barColor.r, barColor.g, barColor.b), innerBarPos.x, innerBarPos.y, innerBarSize.x*amFac, innerBarSize.y, flags);
			}

			// Draw icon:
			statusbar.DrawInventoryIcon(am, curPos + (iconSize*0.5,iconSize*0.5), flags|StatusBarCore.DI_ITEM_CENTER, boxsize:(iconSize, iconSize));

			// draw the string:
			String curAmmoString;
			if (showMax)
			{
				curAmmoString = String.Format("%*d\cJ/%*d", padding, am.amount, padding, am.maxamount);
			}
			else
			{
				curAmmoString = String.Format("%d", am.amount);
			}			
			statusbar.DrawString(hfnt, 
				curAmmoString,
				curPos + (iconSize + indent + ammoStrWidth*0.5, iconsize*0.5 -fy*0.5), 
				flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, 
				translation: showbar? 0xFFFFFFFF : GetPercentageFontColor(am.amount, am.maxamount), 
				scale:fntScale
			);
			curRow++;
			if (curRow < rows)
			{
				curPos.y += singleRowHeight;
			}
			else
			{
				curRow = 0;
				curPos.y = pos.y;
				curPos.x += singleColumnWidth;
			}
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
			largestAmmoAmt = max(largestAmmoAmt, am.amount);
			largestAmmoMaxAmt = max(largestAmmoMaxAmt, am.maxamount); 
		}
		return added;
	}

	// Draws a list of custom items from the ITEMINFO lump:
	ui void DrawCustomItems()
	{
		if (!c_DrawCustomItems.GetBool())
			return;

		bool previewMode;
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
		{
			if (IsModMenuOpen())
			{
				previewMode = true;
				itemNum = 4;
			}
			else
			{
				return;
			}
		}

		double scale = GetElementScale(c_CustomItemsScale);
		double iconSize = 12 * scale;
		int indent = 1 * scale;
		int flags = SetScreenFlags(c_CustomItemsPos.GetInt());
		Vector2 ofs = ( c_CustomItemsX.GetInt(), c_CustomItemsY.GetInt() );
		HUDFont hfnt; Vector2 fntscale;
		[hfnt, fntscale] = GetHUDFont(numHUDFont);
		fntscale *= scale;
		double fy = GetFontHeight(numHUDFont, scale);
		double width = iconsize + indent*4 + numHUDFont.d_font.StringWidth("000/000") * fntScale.x;
		double height = itemNum * (iconsize + indent);
		
		Vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		// visuals for preview mode:
		double alpha = SinePulse(TICRATE*2, 0.2, 0.5, inMenus:true);
		if (previewMode)
		{
			color col = color(int(255 * alpha),255,255,255);
			statusbar.Fill(col, pos.x, pos.y, width, height, flags);
		}
		else
		{
			BackgroundFill(pos.x, pos.y, width, height, flags);
		}
		int style = STYLE_TranslucentStencil;
		string text = "000/000";
		int translation = Font.CR_Untranslated;
		TextureID icon = TexMan.CheckForTexture("AMRKA0");

		int count = previewMode ? itemNum : customItems.Size();
		for (int i = 0; i < count; i++)
		{
			Inventory item;
			if (!previewMode)
			{
				let it = customItems[i];
				if (!it)
					continue;
				item = CPlayer.mo.FindInventory(it);
				if (!item)
					continue;
				icon = statusbar.GetIcon(item,0);
				style = item.GetRenderstyle();
				alpha = 1.0;
				text = String.Format("%3d/%3d", item.amount, item.maxamount);
				translation = GetPercentageFontColor(item.amount, item.maxamount);
			}
			statusbar.DrawTexture(icon, pos + (iconSize*0.5,iconSize*0.5), flags|StatusBarCore.DI_ITEM_CENTER, alpha:alpha, scale:ScaleToBox(icon, iconSize), style:style);
			statusbar.DrawString(hfnt, text, pos + (iconSize + indent, iconsize*0.5 -fy*0.5), flags|StatusBarCore.DI_TEXT_ALIGN_LEFT, translation: translation, scale: fntScale);
			pos.y += max(fy, iconsize) + indent;
		}
	}

	ui void GetCustomItemsList()
	{
		int cl = Wads.FindLump("ITEMINFO");
		while (cl != -1)
		{
			string lumpData = Wads.ReadLump(cl);
			// strip comments:
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
				class<Inventory> cls = clsname;
				if (cls && customItems.Find(cls) == customItems.Size())
				{
					if (jgphud_debug)
						Console.Printf("\cDITEMINFO\c- \cDFound item [%s]", cls.GetClassName());
					customItems.Push(cls);
				}
				else if (jgphud_debug)
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
			dmgMarker = New("Shape2D");

			Vector2 p = (-0.055, -1);
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
		if (!dmgMarkerTransf)
			dmgMarkerTransf = New("Shape2DTransform");
		// Cache the texture:
		if (!dmgMarkerTex || !dmgMarkerTex.IsValid())
			dmgMarkerTex = TexMan.CheckForTexture('JGPUFH_DMGMARKER');
		// Draw the shape for each damage marker data
		// in the previously built array:
		double playerAngle = CPlayer.mo.angle;
		for (int i = dmgMarkerController.markers.Size() - 1; i >= 0; i--)
		{
			let dm = dmgMarkerController.markers[i];
			if (!dm)
				continue;
			
			// Vary width based on the amount of received damage:
			double width = LinearMap(dm.damage, 0, 50, size*0.2, size, true);
			dmgMarkerTransf.Clear();
			dmgMarkerTransf.Scale((width, size) * hudscale.x);
			dmgMarkerTransf.Rotate(dm.GetAngle(Lerp(prevPlayerAngle, playerAngle, fracTic)));
			dmgMarkerTransf.Translate((Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5));
			dmgMarker.SetTransform(dmgMarkerTransf);
			Screen.DrawShape(dmgMarkerTex, false, 
				dmgMarker, 
				DTA_LegacyRenderStyle, STYLE_Add, 
				DTA_Alpha, dm.alpha
			);
		}
	}

	ui double GetCrosshairVertOfs()
	{
		// Compatibility with Precise Crosshair by m8f:
		CVar pc_enable = CVar.GetCVar('pc_enable', CPlayer);
		if (pc_enable && pc_enable.GetBool())
		{
			CVar pc = CVar.GetCVar('pc_y', CPlayer);
			if (pc)
			{
				return pc.GetFloat() - Screen.GetHeight() * 0.5;
			}
		}
		return 0;
	}

	ui Vector2 GetCrosshairPosition()
	{
		Vector2 screenCenter = (Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5);
		screenCenter.y += GetCrosshairVertOfs();
		return screenCenter;
	}

	ui void RefreshEnemyHitMarker(bool killed = true)
	{
		reticleMarkerAlpha = 1.0;
		if (killed)
		{
			reticleMarkerScale = 1;
		}
	}

	ui void UpdateEnemyHitMarker(double delta = 1.0)
	{
		if (reticleMarkerAlpha > 0)
		{
			reticleMarkerAlpha -= (reticleMarkerScale > 0 ? 0.075 : 0.15) * delta;
		}
		if (reticleMarkerScale > 0)
		{
			reticleMarkerScale -= 0.1 * delta;
		}
	}

	ui Shape2D, double GetHitMarkerShape()
	{
		if (!c_EnemyHitMarkersShape)
			return null, 0;
		
		if (!reticleMarkerTransform)
			reticleMarkerTransform = New("Shape2DTransform");

		// Four diagonal bars:
		if (!hitmarker_cross)
		{
			hitmarker_cross = New("Shape2D");
			Vector2 p1 = (-0.08, -1) * 0.5;
			Vector2 p2 = (-p1.x, p1.y);
			Vector2 p3 = (p1.x, p1.y * 0.25);
			Vector2 p4 = (-p3.x, p3.y);
			int id = 0;
			for (int i = 0; i < 4; i++)
			{
				hitmarker_cross.Pushvertex(p1);
				hitmarker_cross.Pushvertex(p2);
				hitmarker_cross.Pushvertex(p3);
				hitmarker_cross.Pushvertex(p4);
				hitmarker_cross.PushCoord((0,0));
				hitmarker_cross.PushCoord((0,0));
				hitmarker_cross.PushCoord((0,0));
				hitmarker_cross.PushCoord((0,0));
				hitmarker_cross.PushTriangle(id, id+1, id+2);
				hitmarker_cross.PushTriangle(id+1, id+2, id+3);
				p1 = Actor.RotateVector(p1, 90);
				p2 = Actor.RotateVector(p2, 90);
				p3 = Actor.RotateVector(p3, 90);
				p4 = Actor.RotateVector(p4, 90);
				id += 4;
			}
		}

		// Four simple triangle shapes around the crosshair:
		if (!hitmarker_triangles)
		{
			hitmarker_triangles = New("Shape2D");
			Vector2 p1 = (-1,-1) * 0.5;
			Vector2 p2 = (-0.4, -0.2) * 0.5;
			Vector2 p3 = (p2.y, p2.x);
			int id = 0;
			for (int i = 0; i < 4; i++)
			{
				hitmarker_triangles.Pushvertex(p1);
				hitmarker_triangles.Pushvertex(p2);
				hitmarker_triangles.Pushvertex(p3);
				hitmarker_triangles.PushCoord((0,0));
				hitmarker_triangles.PushCoord((0,0));
				hitmarker_triangles.PushCoord((0,0));
				hitmarker_triangles.PushTriangle(id, id+1, id+2);
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

		// A ring:
		if (!hitmarker_circle)
		{
			hitmarker_circle = New("Shape2D");
			int steps = 30;
			double angStep = CIRCLEANGLES / steps;
			Vector2 p = (0, -0.5);
			for (int i = 0; i < steps; i++)
			{
				hitmarker_circle.PushVertex(p);
				hitmarker_circle.PushCoord((0,0));
				p = Actor.RotateVector(p, angStep);
			}
			Vector2 p1 = (0, -0.45);
			for (int i = 0; i < steps; i++)
			{
				hitmarker_circle.PushVertex(p1);
				hitmarker_circle.PushCoord((0,0));
				p1 = Actor.RotateVector(p1, angStep);
			}
			for (int i = 0; i < steps; i++)
			{
				int next = i+1;
				if (next >= steps)
					next -= steps;
				hitmarker_circle.PushTriangle(i, next, i + steps);
				int nextInner = i + steps + 1;
				if (nextInner >= steps*2)
					nextInner -= steps;
				hitmarker_circle.PushTriangle(next, i + steps, nextInner);
			}
		}
	
		Shape2D shapeTouse;
		double angle;
		switch(c_EnemyHitMarkersShape.GetInt())
		{
		default:
			angle = 45;
		case 1:
			shapeToUse = hitmarker_cross;
			break;
		case 3:
			angle = 45;
		case 2:
			shapeToUse = hitmarker_triangles;
			break;
		case 4:
			shapeToUse = hitmarker_circle;
			break;
		case 5:
			shapeToUse = shape_disk; //misnomer, minimap's shape is actually a disk
			break;
		case 6:
			angle = 45;
		case 7:
			shapeToUse = shape_square;
			break;
		}
		return shapeToUse, angle;
	}

	ui void DrawEnemyHitMarker()
	{
		if (!c_DrawEnemyHitMarkers.GetBool())
			return;
		
		Vector2 screenCenter =  GetCrosshairPosition();
		double alpha = reticleMarkerAlpha;
		if (alpha <= 0)
		{
			if (IsModMenuOpen())
			{
				alpha = SinePulse(TICRATE*2, 0.2, 0.6, inMenus:true);
			}
			else
			{
				return;
			}
		}

		Shape2D shapeToUse;
		double angle;
		[shapeToUse, angle] = GetHitMarkerShape();
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
		reticleMarkerTransform.Rotate(angle);
		reticleMarkerTransform.Translate(screenCenter);
		shapeToUse.SetTransform(reticleMarkerTransform);
		color col = color(c_EnemyHitMarkersColor.GetInt());
		Screen.DrawShapeFill(RGB2BGR(col), alpha, shapeToUse);
	}

	ui bool CanDrawReticleBar(int which)
	{
		if (c_DrawReticleBars && c_DrawReticleBars.GetInt() != DM_AUTOHIDE)
			return true;

		which = Clamp(which, 0, reticleMarkersDelay.Size()-1);
		return reticleMarkersDelay[which] > 0;
	}

	ui void UpdateReticleBars(double delta = 1.0)
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
			reticleMarkersDelay[RB_HEALTH] -= 1 * delta;
		}

		if (prevArmAmount != armAmount || prevArmMaxAmount != armMaxAmount)
		{
			prevArmAmount = armAmount;
			prevArmMaxAmount = armMaxAmount;
			reticleMarkersDelay[RB_ARMOR] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_ARMOR] -= 1 * delta;
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
			reticleMarkersDelay[RB_AMMO1] -= 1 * delta;
		}
		if (am2 && (prevAmmo2Amount != am2.amount || prevAmmo2MaxAmount != am2.maxamount))
		{
			prevAmmo2Amount = am2.amount;
			prevAmmo2MaxAmount = am2.maxamount;
			reticleMarkersDelay[RB_AMMO2] = MARKERSDELAY;
		}
		else
		{
			reticleMarkersDelay[RB_AMMO2] -= 1 * delta;
		}
	}

	ui double, Vector2, Vector2, int, int GetReticleBarsPos(int i, double inwidth, double outwidth, double fntHeight)
	{
		i = Clamp(i, 0, 4);
		Vector2 posIn;
		Vector2 posOut;
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
		posIn.y += GetCrosshairVertOfs() / hudscale.y;
		posOut.y += GetCrosshairVertOfs() / hudscale.y;
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
		Vector2 screenCenter = GetCrosshairPosition();
		double widthFac = 1.0 - Clamp(c_ReticleBarsWidth.GetFloat(), 0.0, 1.0);
		double virtualSize = 18 * GetElementScale(c_ReticleBarsScale);
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
		HUDFont hfnt; Vector2 fntScale;
		[hfnt, fntScale] = GetHUDFont(numHUDFont);
		// We need to do a lot here. The text strings, if shown, have to be shown
		// in specific places, depending on where the bar is located (left, top,
		// right, bottom), and also whether it's an inner bar or an outer bar.
		// So, we need two sets of positions and two sets of flags (for inner 
		// and outer). Font height also plays a role for vertical positioning.
		// And, obviously, the angle at which the bar is rotated. All of this
		// can be set up by the player by changing the appropriate CVar.
		// See GetReticleBarsPos() with a whopping 5 return values.
		double fntScaleMul = LinearMap(virtualSize, 12, 200, 0.5, 5, true);
		fntScale *= fntScaleMul;
		double fy = GetFontHeight(numHUDFont, fntScaleMul);
		double fontOfsIn = maskSize / hudscale.x - 1;
		double fontOfsOut = secondarySize / hudscale.x + 1;
		Vector2 fntPosIn, fntPosOut;
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
				statusbar.DrawString(hfnt, String.Format("%s", lt.GetTag()), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: fntScale);
				statusbar.DrawString(hfnt, String.Format("%d", health), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: fntScale);
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
					statusbar.DrawString(hfnt, String.Format("%d", health), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: fntScale);
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
					statusbar.DrawString(hfnt, String.Format("%d", armAmount), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: fntScale);
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
						statusbar.DrawString(hfnt, String.Format("%d", am1.amount), fntPosIn, fntFlagsIn, Font.CR_White, fadeAlph, scale: fntScale);
					}
					DisableMask();
				}
			}
			// Ammo 2 (outer):
			if (am2 && am2 != am1)
			{
				// check special rules for ammo color:
				color amCol2 = GetAmmoColor(am2);
				// if no special rules were applied (color
				// is same as ammo1), make it faded compared
				// to main color:
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
						statusbar.DrawString(hfnt, String.Format("%d", am2.amount), fntPosOut, fntFlagsOut, Font.CR_White, fadeAlph, scale: fntScale);
					}
					DisableMask();
				}
			}
		}
	}

	ui void DrawCircleSegmentShape(color col, Vector2 pos, double size, int steps, double angle, double coverAngle, double frac = 1.0, double alpha = 1.0)
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
		Screen.DrawShapeFill(RGB2BGR(col), alpha, roundBars);
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
		// We need to wait here for a bit because, apparently,
		// slots set up via KEYCONF (ugh) are somehow set up
		// with a delay, and trying to set them up immediately
		// will result in vanilla weapons being cached instead:
		if (Level.maptime < 2)
			return;

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
					if (jgphud_debug)
						Console.Printf(
							"Slot \cF%d\c-, index \cF%d\c-, weapon \cD%s\c-. Pushing into the \cEWeaponSlotData\c- array", 
							sn,
							s,
							weap.GetClassName()
						);
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
		if (weaponSlotData.Size() <= 0)
			return;

		double scale = GetElementScale(c_WeaponSlotsScale);
		double iconWidth = WEAPONBARICONSIZE * scale;
		Vector2 box = (iconWidth, iconWidth * 0.625);
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
		Vector2 ofs = ( c_WeaponSlotsX.GetInt(), c_WeaponSlotsY.GetInt() );
		Vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);

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
		Vector2 wpos = pos;
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

	ui void DrawOneWeaponSlot(Weapon weap, Vector2 pos, int flags, Vector2 box, int slot = -1)
	{
		// Check for sisterweapon if the player has a PowerWeaponLevel2:
		if (weap && CPlayer.mo.FindInventory('PowerWeaponLevel2', true) && weap.sisterWeapon)
		{
			// If it passes, remap the weap pointer to its sister,
			// since that's what the player has selected now:
			let sister = Weapon(CPlayer.mo.FindInventory(weap.sisterWeapon.GetClass()));
			if (sister)
			{
				weap = sister;
			}
		}		
		if (!weap)
			return;

		int fntCol = c_WeaponSlotsNumColor.GetInt();
		// Compare this weapon to readyweapon and pendingweapon:
		Weapon rweap = Weapon(CPlayer.readyweapon);
		// MUST explicitly cast pendingweapon as Weapon, otherwise
		// the pointer won't be properly null-checked (since this 
		// is set to WP_NOCHANGE rather than an actual Actor(null)
		// pointer when there's no pendingweapon):
		Weapon pweap = Weapon(CPlayer.pendingweapon);
		// If the weapon in question is selected OR being
		// selected, invert the colors of the box.
		// Make sure not to highlight both ready and pending
		// at the same time, we don't need that:
		if ((rweap == weap && !pweap) || pweap == weap)
		{
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
		statusbar.DrawTexture(statusbar.GetIcon(weap, 0, true), pos + box*0.5, flags|StatusBarCore.DI_ITEM_CENTER, box: box);
		
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
			string slotNum = ""..slot;
			HUDFont hfnt; Vector2 fntscale;
			[hfnt, fntscale] = GetHUDFont(numHUDFont);
			fntscale *= (box.y / WEAPONBARICONSIZE) * 1.2;
			statusbar.DrawString(hfnt, slotNum, (pos.x+box.x*0.95, pos.y), flags|StatusBarCore.DI_TEXT_ALIGN_RIGHT, fntCol, 0.8, scale:fntscale);
		}
	}

	ui void CreateGenericShapes()
	{
		// Create a square shape in the (-0.5-0.5, -0.5-0.5) range:
		if (!shape_square)
		{
			shape_square = New("Shape2D");
			Vector2 mv = (-0.5, -0.5); //start at top left corner
			shape_square.PushVertex(mv);
			shape_square.PushVertex((mv.x, -mv.y));
			shape_square.PushVertex((-mv.x, mv.y));
			shape_square.PushVertex((-mv.x, -mv.y));
			for (int i = 0; i < 4; i++)
			{
				shape_square.PushCoord((0,0));
			}
			shape_square.PushTriangle(0,1,2);
			shape_square.PushTriangle(1,2,3);
		}
		// Create a disk shape in the (-0.5-0.5, -0.5-0.5) range:
		if (!shape_disk)
		{
			shape_disk = New("Shape2D");
			Vector2 cmid = (0, 0); //center
			shape_disk.PushVertex(cmid);
			shape_disk.PushCoord((0,0));
			int steps = 60;
			double angStep = CIRCLEANGLES / steps;
			Vector2 p = (0, -0.5); //edge point
			for (int i = 0; i < steps; i++)
			{
				shape_disk.PushVertex(p);
				shape_disk.PushCoord((0,0));
				p = Actor.RotateVector(p, angStep);
			}
			// Draw triangles between center,
			// edge point and the next edge point:
			for (int i = 1; i <= steps; i++)
			{
				int next = i+1;
				if (next > steps)
					next = 1;
				shape_disk.PushTriangle(0, i, next);
			}
		}
	}

	// Update player position and angle with smooth
	// interpolation between tics. Used by the
	// minimap and damage markers:
	ui void UpdatePlayerAngle()
	{
		int lt = Level.mapTime;
		if (!prevLevelTime)
			prevLevelTime = lt;
		
		if (lt > prevLevelTime)
		{
			prevPlayerAngle = CPlayer.mo.angle;
			prevPlayerPos = CPlayer.mo.pos.xy;
			prevLevelTime = lt;
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
		
		int shouldDraw = c_DrawMinimap.GetInt();

		// Check CVar values:
		bool drawmap = (shouldDraw == MDD_MAPONLY || shouldDraw == MDD_BOTH);
		bool drawradar = (shouldDraw == MDD_RADARONLY || shouldDraw == MDD_BOTH);
		bool canDraw = drawmap || drawradar;
		// Don't draw if either of these is true:
		// 1. the level has been unloaded (prevents possible crashes on tally/intermission)
		// 2. PlayerPawn is invalid
		// 3. automap is open
		// 4. we're not in a level (this will probably never happen though)
		if (candraw)
		{
			candraw = !levelUnloaded && CPlayer.mo && gamestate == GS_Level;
		}
		if (!canDraw)
		{
			drawmap = false;
			drawradar = false;
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
		// Screen flags are obtained as usual, although they're
		// only used in AdjustElementPos, not in the actual
		// drawing functions, since Screen functions don't
		// interact with statusbar DI_* flags:
		int flags = SetScreenFlags(c_MinimapPos.GetInt());
		Vector2 ofs = ( c_MinimapPosX.GetInt(), c_MinimapPosY.GetInt() );
		// Real: true makes this function return real screeen
		// coordinates rather virtual ones:
		Vector2 pos = AdjustElementPos((0,0), flags, (size, size), ofs, real:true);

		// Draw map data below the minimap
		// (or above it if it's at the bottom of the screen):
		// Figure out horizontal size first, based on the
		// width of the minimap. If the minimap is hidden,
		// we use 64 for width:
		Vector2 msize = (64, 0);
		if (drawMap || drawradar)
		{
			// Otherwise we use the minimap's width, but no
			// less than 44 pixels (otherwise it looks bad
			// due to scaling):
			msize = (max(size, 44), size);
		}
		Vector2 mapDataSize = (msize.x, msize.y + 16);
		// draw it above the minimap if that's at the bottom:
		Vector2 mapDataPos = ((flags & StatusBarCore.DI_SCREEN_BOTTOM) == StatusBarCore.DI_SCREEN_BOTTOM) ? (0, 0) : (0, msize.y);
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
		if (!drawMap && !drawradar)
		{
			return;
		}

		size *= hudscale.x;

		// Let the player change the size of the map:
		double mapZoom = GetMinimapZoom();
		mapZoom /= MAPSCALEFACTOR;
		// These are needed to position the lines on our
		// minimap to the same relative positions they are
		// in the world:
		Vector2 ppos;
		// Lerp pos and angle to smooth it with framerate:
		ppos.x = Lerp(prevPlayerPos.x, CPlayer.mo.pos.x, fracTic);
		ppos.y = Lerp(prevPlayerPos.y, CPlayer.mo.pos.y, fracTic);
		double playerAngle = -(Lerp(prevPlayerAngle, CPlayer.mo.angle, fracTic) + 90);
		Vector2 diff = Level.Vec2Diff((0,0), ppos);

		if (!minimapTransform)
		{
			minimapTransform = New("Shape2DTransform");
		}
		minimapTransform.Clear();
		// Pick the shape to use based on the player's choice:
		bool circular = IsMinimapCircular();
		Shape2D shapeToUse = circular ? shape_disk : shape_square;
		// offset to the half of the shape size:
		Vector2 shapeOfs = (size, size)*0.5;
		minimapTransform.Scale((size,size));
		minimapTransform.Translate(pos + shapeOfs);
		shapeToUse.SetTransform(minimapTransform);

		// background:
		Color baseCol = GetHUDBackground();
		double edgeThickness = 1 * hudscale.x;
		double backAlpha = Clamp(c_MinimapOpacity.GetFloat(), 0.0, 1.0);
		
		// Fill the shape with the outline color
		// (remember than DrawShapeFill is BGR, not RGB):
		Screen.DrawShapeFill(RGB2BGR(baseCol), backAlpha, shapeToUse);
		
		// Scale the shape down to draw the black background:
		minimapTransform.Clear();
		minimapTransform.Scale((size-edgeThickness,size-edgeThickness));
		minimapTransform.Translate(pos + shapeOfs);
		shapeToUse.SetTransform(minimapTransform);
		// This debug CVAR disables the mask for the minimap
		// in case I need to view everything in full:
		if (!jgphud_debugmap)
		{
			EnableMask(1, shapeToUse);
		}
		// Draw background:
		color backCol = GetMinimapColor(MCT_Background);
		Screen.DrawShapeFill(RGB2BGR(backCol), backAlpha, shapeToUse);
		
		// Draw the minimap lines:
		if (drawmap)
		{
			DrawMinimapLines(pos, diff, playerAngle, size, hudscale.x, mapZoom);
			DrawMapMarkers(pos, diff, playerAngle, size, hudscale.x, mapZoom);
		}

		// White arrow at the center representing the player:
		if (!minimapShape_Arrow)
		{
			minimapShape_Arrow = New("Shape2D");
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
		color youColor = GetMinimapColor(MCT_You);
		Screen.DrawShapeFill(RGB2BGR(youcolor), 1.0, minimapShape_Arrow);

		DrawCardinalDirections(pos, playerAngle, size);
		
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

	ui color GetMinimapColor(int type)
	{
		// Use FlexiHUD minimap colors:
		if(c_MinimapColorMode.GetInt())
		{
			color col;
			switch (type)
			{
			case MCT_Background:	col = c_minimapBackColor.GetInt();		break;
			case MCT_You:			col = c_minimapYouColor.GetInt();		break;
			case MCT_Wall:			col = c_minimapLineColor.GetInt();		break;
			case MCT_IntWall:		col = c_MinimapIntLineColor.GetInt();	break;
			case MCT_Enemy:			col = c_minimapMonsterColor.GetInt();	break;
			default:				col = c_minimapFriendColor.GetInt();	break;
			}
			return col;
		}
		// Use GZDoom colors, set to 'Custom':
		else if (c_am_colorset.GetInt() <= 0)
		{
			color col;
			switch (type)
			{
			case MCT_Background:	col = c_am_backcolor.GetInt();			break;
			case MCT_You:			col = c_am_yourcolor.GetInt();			break;
			case MCT_Wall:			col = c_am_wallcolor.GetInt();			break;
			case MCT_IntWall:		col = c_am_specialwallcolor.GetInt();	break;
			case MCT_Enemy:			col = c_am_thingcolor_monster.GetInt();	break;
			default:				col = c_am_thingcolor_friend.GetInt();	break;
			}
			return col;
		}
		else
		{
			// Use GZDoom colors, set to one of the 'traditional' colors:
			switch (c_am_colorset.GetInt())
			{
			default:	return tradmapcol_DoomColors[type];
			case 2:		return tradmapcol_StrifeColors[type];
			case 3:		return tradmapcol_RavenColors[type];
			}
		}
	}

	ui void UpdateMinimapLines()
	{
		if (!ShouldDrawMinimap())
		{
			return;
		}
		// We don't need to update the lines every tic.
		// Update once a second in menus, otherwise
		// once per 10 tics:
		int freq = gamePaused ? 35 : 10;
		if (GetHUDTics() % freq != 0)
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
		Vector2 pos = ln.v1.p;
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

	// Aligns world position to the map and rotates it
	// to match player's angle:
	ui Vector2 AlignPosToMap(Vector2 vec, double angle, double mapSize)
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

	// Performs the actual line drawing:
	//  pos - position of the element
	//  ofs - Vec2Diff between world origin (0,0) and current player position
	//  angle - player's angle
	//  radius - size of the minimap
	//  scale - hudscale
	//  zoom - current minimap zoom value
	ui void DrawMinimapLines(Vector2 pos, Vector2 ofs, double angle, double radius, double scale = 1.0, double zoom = 1.0)
	{
		color lineCol = GetMinimapColor(MCT_Wall);
		color intLineCol = GetMinimapColor(MCT_IntWall);

		for (int i = 0; i < mapLines.Size(); i++)
		{
			Line ln = mapLines[i];
			if (!ln)
				continue;
				
			// Get vertices and scale them in accordance
			// with zoom value and hudscale:
			Vector2 lp1 = ln.v1.p;
			Vector2 lp2 = ln.v2.p;
			Vector2 p1 = (lp1 - ofs) * zoom * scale;
			Vector2 p2 = (lp2 - ofs) * zoom * scale;

			p1 = AlignPosToMap(p1, angle, radius);
			p2 = AlignPosToMap(p2, angle, radius);

			double thickness = 1;
			int lineAlph = 255;
			color col = GetLockColor(ln);
			// If lock color is valid, this is a locked line,
			// so make it thick and colorize accordingly:
			if (col != -1)
			{
				thickness = 4;
				col = color(col.r, col.g, col.b);
			}
			// Otherwise check if it's any kind of interactive line
			// (don't forget to check for special, because activation
			// flags may be set up by mistake on lines that don't
			// actually do anything):
			else if (ln.activation & SPAC_PlayerActivate && ln.special != 0)
			{
				col = color(intLineCol.r, intLineCol.g, intLineCol.b);
			}
			// Otherwise apply regular line color:
			else
			{
				col = color(lineCol.r, lineCol.g, lineCol.b);
				// Double-sided lines are thick:
				if (!(ln.flags & Line.ML_TWOSIDED))
				{
					thickness = 2;
				}
				// One-sidd lines use regular thickness
				// and 50% of opacity:
				else
				{
					lineAlph /= 2;
				}
			}
			// Change opacity if this line is undiscovered:
			if (!(ln.flags & Line.ML_MAPPED))
			{
				lineAlph *= Clamp(c_minimapDrawUnseen.GetFloat(), 0., 1.);
			}

			// DrawLine is a bit cheaper than DrawThickLine, so use that
			// if thickness is 1:
			if (thickness <= 1)
				Screen.DrawLine(p1.x + pos.x, p1.y + pos.y, p2.x + pos.x, p2.y + pos.y, col, lineAlph);
			else
				Screen.DrawThickLine(p1.x + pos.x, p1.y + pos.y, p2.x + pos.x, p2.y + pos.y, thickness, col, lineAlph);
		}
	}

	// Draws NESW letters on the map:
	static const String com_letters[] = { "N", "W", "E", "S" };
	static const double com_angles[] = { 0, 90, -90, 180 };
	ui void DrawCardinalDirections(Vector2 pos, double angle, double radius)
	{
		if (!c_MinimapCardinalDir || c_MinimapCardinalDir.GetInt() <= 0)
		{
			return;
		}
		Font fnt = newConsoleFont;
		int fntColor = c_MinimapCardinalDirColor.GetInt();
		int letterSize = c_MinimapCardinalDirSize.GetInt();
		String letter;
		bool square = !IsMinimapCircular() && c_MinimapCardinalDir.GetInt() >= 2;
		double rad = square ? radius * 2 : radius;
		for (int i = 0; i < 4; i++)
		{
			letter = com_letters[i];
			// Center of the letter:
			Vector2 stringSize = (fnt.GetHeight(), fnt.StringWidth(letter));
			double letterScale = letterSize / stringSize.y;
			Vector2 charMid = (stringSize.x*0.5, stringSize.y*0.5) * letterScale;
			// Offset by a radius from the center, but
			// offset the letter from the edge by its total
			// size, so it's guaranteed to never go
			// beyond the minimap's edge:
			double charOfs = max(charMid.x, charMid.y);
			Vector2 ofs = (0, rad*0.5 - charOfs);
			// Rotate by the necessary angle:
			Vector2 p = Actor.RotateVector(ofs, angle + com_angles[i]);
			// Flip X to match top with player's facing angle:
			p.x *= -1;
			// Add half of the size to position the letter
			// relative to the center:
			p += pos + (radius,radius)*0.5;
			if (square)
			{
				//p *= 0.5;
				p.x = Clamp(p.x, pos.x + charOfs, pos.x + radius - charOfs);
				p.y = Clamp(p.y, pos.y + charOfs, pos.y + radius - charOfs);
			}
			// Add this to the letter so it's centered
			// at its target position:
			p.x -= charMid.y;
			p.y -= charMid.x;
			Screen.DrawText(fnt, fntColor, p.x, p.y, letter, DTA_ScaleX, letterScale, DTA_ScaleY, letterScale, DTA_MonoSpace, Mono_CellLeft);
		}
	}

	clearscope color GetLockColor(Line l)
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
		bool drawMap, drawRadar;
		[drawMap, drawRadar] = ShouldDrawMinimap();
		if (!drawRadar)
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

	ui void DrawEnemyRadar(Vector2 pos, Vector2 ofs, double angle, double radius, double scale = 1.0, double zoom = 1.0)
	{
		if (!minimapShape_Arrow || !shape_disk || !minimapTransform)
			return;
		
		bool drawAll = c_MinimapEnemyDisplay.GetBool();
		Shape2D shapeTouse = c_MinimapEnemyShape.GetBool() ? shape_disk : minimapShape_Arrow;

		color foeColor = GetMinimapColor(MCT_Enemy);
		color friendColor = GetMinimapColor(MCT_Friend);
		for (int i = 0; i < radarMonsters.Size(); i++)
		{
			let thing = radarMonsters[i];
			if (!thing || (!drawAll && !thing.target))
				continue;

			Vector2 ePos = (thing.pos.xy - ofs) * zoom * scale;
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
			shapeTouse.SetTransform(minimapTransform);
			color col = thing.IsHostile(CPLayer.mo) ? foeColor : friendColor;
			Screen.DrawShapeFill(RGB2BGR(col), alpha, shapeTouse);
		}
	}

	ui void DrawMapMarkers(Vector2 pos, Vector2 ofs, double angle, double radius, double scale = 1.0, double zoom = 1.0)
	{
		double distFac = IsMinimapCircular() ? 1.0 : SQUARERADIUSFAC;
		double distance = ((radius) / zoom) * distFac; //account for square shapes
		for (int i = 0; i < mapMarkers.Size(); i++)
		{
			let marker = mapMarkers[i];
			if (!marker || marker.bDORMANT)
				continue;
			
			if (!CPlayer.mo || CPlayer.mo.Distance2DSquared(marker) > distance*distance)
				continue;

			TextureID tex = GetMarkerTexture(marker);
			if (!tex.IsValid())
				return;

			Vector2 ePos = (marker.pos.xy - ofs) * zoom * scale;
			ePos = AlignPosToMap(ePos, angle, radius);
			// scale alpha with vertical distance:
			double vdiff = abs(CPlayer.mo.pos.z - marker.pos.z);
			double alpha = LinearMap(vdiff, 0, 512, 1.0, 0.1, true);
			Vector2 mpos = pos + ePos;
			Screen.DrawTexture(tex, false,
				mpos.x, mpos.y,
				DTA_Alpha, alpha,
				// Marker's size is just their graphic scaled relative
				// to their scale property, and it shouldn't change
				// with the map's zoom:
				DTA_ScaleX, marker.scale.x,
				DTA_ScaleY, marker.scale.y
			);
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

	// Draw map data (kills/secrets/items/time) below the
	// minimap (even if the minimap isn't drawn, it'll be
	// attached to the same position):
	ui void DrawMapData(Vector2 pos, int flags, double width, double scale = 1.0)
	{
		double indent = 1 * scale;

		HUDFont hfnt; Vector2 fntscale;
		[hfnt, fntscale] = GetHUDFont(smallHUDFont);
		fntscale *= scale;
		let fy = GetFontHeight(smallHUDFont, scale);

		pos.x += width*0.5;
		bool shoulDrawKills = c_DrawKills.GetBool();
		bool shoulDrawItems = c_DrawItems.GetBool();
		bool shoulDrawSecrets = c_DrawSecrets.GetBool();
		bool shoulDrawTime = c_DrawTime.GetBool();
		// flip if it's at the bottom:
		if ((flags & StatusBarCore.DI_SCREEN_BOTTOM) == StatusBarCore.DI_SCREEN_BOTTOM)
		{
			int vofs;
			if (shoulDrawKills)
				vofs++;
			if (shoulDrawItems)
				vofs++;
			if (shoulDrawSecrets)
				vofs++;
			if (shoulDrawTime)
				vofs++;
			pos.y -= ((fy + indent) * vofs + indent);
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
		if (shoulDrawKills)
		{
			DrawMapDataElement("$TXT_IMKILLS", kills, totalkills, hfnt, pos, flags, width, fntscale);
			pos.y += fy + indent;
		}

		if (shoulDrawItems)
		{
			DrawMapDataElement("$TXT_IMITEMS", items, totalitems, hfnt, pos, flags, width, fntscale);
			pos.y += fy + indent;
		}

		if (shoulDrawSecrets)
		{
			DrawMapDataElement("$TXT_IMSECRETS", secrets, totalsecrets, hfnt, pos, flags, width, fntscale);
			pos.y += fy + indent;
		}

		if (shoulDrawTime)
		{
			int h,m,s;
			[h,m,s] = TicsToHours(Level.time);
			s_right = String.Format("\cQ%d:%02d:%02d", h, m, s);
			DrawMapDataElement("$TXT_IMTIME", 0, 0, hfnt, pos, flags, width, fntscale, rightside: s_right);
		}
	}

	// Draws the actual map data element, consisting of the label
	// (left), a space, and the value (right):
	ui void DrawMapDataElement(String label, int val1, int val2, HUDFont hfnt, Vector2 pos, int flags, double width, Vector2 scale = (1,1), String rightside = "")
	{
		String str1 = StringTable.Localize(label);
		// If rightside is provided, use that text explicitly for
		// whatever comes after the label (used for level time):
		String str2 = rightside;
		// Otherwise construct the right string based on the val1
		// and val2 values, and colorize it:
		if (!rightside)
		{
			String s_right;
			// red numbers if 0:
			if (val1 <= 0)
			{
				s_right = String.Format("\cA%d\c-", val1);
			}
			// yellow numbers if not maximum:
			else if (val1 < val2)
			{
				s_right = String.Format("\cK%d\c-", val1);
			}
			// otherwise make both label and numbers green 
			// if val1 reached its maximum:
			else
			{
				str1 = String.Format("\cD%s\c-", str1);
				s_right = String.Format("\cD%d\c-", val1);
			}
			str2 = String.Format("%s/\cD%d", s_right, val2);
		}

		Font fnt = hfnt.mFont;
		// Scale the string down if it's too wide
		// to account for possible long localized
		// strings (I wish more games would do that):
		double strOfs = 3 * scale.x;
		double maxStrWidth = width*0.5 - strOfs;
		double strScale = scale.x;
		double strWidth = fnt.StringWidth(str1) * scale.x;
		if (strWidth > maxStrWidth)
		{
			strScale = (maxStrWidth / strWidth) * scale.x;
		}
		double strScale2 = scale.x;
		double strWidth2 = fnt.StringWidth(str2) * scale.x;
		if (strWidth2 > maxStrWidth)
		{
			strScale2 = (maxStrWidth / strWidth2) * scale.x;
		}
		statusbar.DrawString(hfnt, str1, pos-(strOfs,0), flags|StatusBarCore.DI_TEXT_ALIGN_RIGHT, scale:(strScale,scale.y));
		//statusbar.DrawString(hfnt, ":", pos, flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, scale:(scale,scale));
		statusbar.DrawString(hfnt, str2, pos+(strOfs,0), flags|StatusBarCore.DI_TEXT_ALIGN_LEFT, scale:(strScale2, scale.y));
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
		
		bool vertical = c_PowerupsAlignment.GetInt() > 0;
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
			if (IsModMenuOpen())
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
		Vector2 ofs = (c_PowerupsX.GetInt(), c_PowerupsY.GetInt());
		double scale = GetElementScale(c_PowerupsScale);
		double iconSize = 20.0 * scale;
		int indent = 1 * scale;
		
		HUDFont fnt; Vector2 fntscale;
		[fnt, fntscale] = GetHUDFont(numHUDFont);
		fntScale *= scale;
		double fy = GetFontHeight(numHUDFont, scale);
		
		double shortsize = iconSize + indent;
		double longsize = (iconsize + indent) * powerNum + indent;
		double width = vertical ? shortsize : longsize;
		double height = vertical ?  longsize : shortsize;
		Vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		flags |= StatusBarCore.DI_ITEM_CENTER;
		pos += (iconSize*0.5, iconsize*0.5);
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
				statusbar.DrawString(fnt, s_time, (pos.x, pos.y - fy*0.5) - (0.5,0.5), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation:Font.CR_Black, scale:fntScale);
				statusbar.DrawString(fnt, s_time, (pos.x, pos.y - fy*0.5), flags|StatusBarCore.DI_TEXT_ALIGN_CENTER, translation:c_PowerupsNumColor.GetInt(), scale:fntScale);
				if (vertical)
				{
					pos.y += iconSize + indent;
				}
				else
				{
					pos.x += iconSize + indent;
				}
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
			if (IsModMenuOpen())
			{
				previewMode = true;
			}
			else
			{
				return;
			}
		}

		int flags = SetScreenFlags(c_KeysPos.GetInt());
		Vector2 ofs = (c_KeysX.GetInt(), c_KeysY.GetInt());
		double scale = GetElementScale(c_KeysScale);
		double iconSize = 10 * scale;
		int indent = 2 * scale;
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
				keyIcons.Push(icon);
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
		Vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		
		int style = STYLE_Normal;
		double alpha = 1.0;
		// altered visuals for preview mode:
		if (previewMode)
		{
			style = STYLE_TranslucentStencil;
			alpha = SinePulse(TICRATE*2, 0.2, 0.5, inMenus:true);
			color col = color(int(255 * alpha),255,255,255);
			statusbar.Fill(col, pos.x, pos.y, width, height, flags);
		}
		else
		{
			BackgroundFill(pos.x, pos.y, width, height, flags);
		}

		pos += (iconsize*0.5+indent, iconsize*0.5+indent);
		Vector2 kpos = pos;
		// Keep track of how many keys we've drawn horizontally,
		// so we can switch to new line when we've filled all
		// columns:
		int horKeys;
		for (int i = 0; i < keyIcons.Size(); i++)
		{
			let icon = keyIcons[i];
			statusbar.DrawTexture(icon, kpos, flags|StatusBarCore.DI_ITEM_CENTER, alpha:alpha, scale:ScaleToBox(icon, iconSize), style:style);
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
			if (IsModMenuOpen() && c_drawInvBar.GetBool())
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

		double scale = GetElementScale(c_InvBarScale);
		int indent = 1 * scale;
		double iconSize = ITEMBARICONSIZE * scale;
		int width = (iconSize + indent) * numfields - indent;
		int height = iconSize;

		// Validate position as usual:
		int flags = SetScreenFlags(c_InvBarPos.GetInt());
		Vector2 ofs = (c_InvBarX.GetInt(), c_InvBarY.GetInt());
		Vector2 pos = AdjustElementPos((width*0.5, height*0.5), flags, (width, height), ofs);

		// In preview mode we'll simply display a series
		// of pulsing fills the inv slots, and nothing else:
		if (previewMode)
		{
			double spaceWidth = width / numfields;
			int midPoint = ceil(numfields / 2);
			Vector2 ppos = (pos.x - width*0.5, pos.y - height*0.5);
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

		Vector2 cursOfs = (-iconSize*0.5 - indent, -iconSize*0.5 - indent);
		Vector2 cursPos = pos + cursOfs;
		Vector2 cursSize = (iconsize + indent*2, indent); //width, height

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
			// Add positive or negative offsets to the icon:
			invbarCycleOfs = pressedInvNext ? iconSize : -iconSize;
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
		Vector2 itemPos = pos;
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
		double fntScale = iconSize / 40.;
		double fy = GetFontHeight(numHUDFont, scale);
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
			statusbar.DrawString(GetHUDFont(numHUDFont), ""..item.amount, itemPos + (boxsize*0.5, boxsize*0.5 - fy), flags|StatusBarCore.DI_TEXT_ALIGN_RIGHT, c_InvBarNumColor.GetInt(), alpha: alph, scale:(fntscale, fntscale));
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

	ui void UpdateInventoryBar(double delta = 1.0, int numfields = 7)
	{
		if (invbarCycleOfs == 0)
			return;

		double scale = GetElementScale(c_InvBarScale);
		double iconSize = ITEMBARICONSIZE * scale;
		double step = (invbarCycleOfs > 0 ? -iconSize : iconsize) * 0.25 * delta;
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
}