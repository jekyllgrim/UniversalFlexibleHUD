class JGPUFH_FlexibleHUD : BaseStatusBar
{
	HUDFont mainHUDFont;
	HUDFont numHUDFont;

	JGPUFH_HudDataHandler handler;
	array <JGPHUD_HexenArmorData> hexenArmorData;

	CVar c_aspectscale;

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
	
	CVar c_drawHitmarkers;
	CVar c_hitMarkersAlpha;
	CVar c_HitMarkersFadeTime;

	CVar c_drawWeaponSlots;
	CVar c_weaponSlotPos;
	CVar c_weaponSlotX;
	CVar c_weaponSlotY;

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

	// Health/armor bars CVAR values:
	enum EDrawBars
	{
		DB_NONE,
		DB_DRAWNUMBERS,
		DB_DRAWBARS,
	}

	// Hit (incoming damage) marker
	Shape2D hitMarker;
	Shape2DTransform hitMarkerTransf;
	array <JGPUFH_HitMarkerData> hmData;
	Actor prevAttacker;

	// Hit (reticle) marker
	Shape2D reticleHitMarker;
	double reticleMarkerAlpha;
	Shape2DTransform reticleMarkerTransform;
	
	// Weapon slots
	array <JGPUFH_WeaponSlotData> weaponSlotData;
	int maxSlotID;
	int totalSlots;

	// Minimap
	Shape2D minimapShape_Square;
	Shape2D minimapShape_Circle;
	Shape2D minimapShape_Arrow;
	Shape2DTransform minimapTransform;
	const MAPSCALEFACTOR = 8;

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

	//See GetBaseplateColor():
	CVar c_BackColor;
	CVar c_BackAlpha;

	// See DrawInventoryBar():
	Inventory prevInvSel;
	double invbarCycleOfs;

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
		mainHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true);
		fnt = "IndexFont";
		numHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true);

		GetWeaponSlots();
	}

	override void Tick()
	{
		super.Tick();
		UpdateHitMarkers();
		UpdateReticleHitMarker();
		GetWeaponSlots();
		UpdateInventoryBar();
	}

	override void Draw(int state, double ticFrac)
	{
		super.Draw(state, ticFrac);

		if (state == HUD_None || state == HUD_AltHud)
			return;
		
		BeginHUD();
		CacheCvars(); //cache CVars before anything else

		DrawHealthArmor();
		DrawHitMarkers();
		DrawReticleHitMarker();
		DrawWeaponBlock();
		DrawAllAmmo();
		DrawWeaponSlots();
		DrawMinimap();
		DrawPowerups();
		DrawKeys();
		DrawInventoryBar();
	}

	void CacheCvars()
	{
		if (!handler)
			handler = JGPUFH_HudDataHandler(EventHandler.Find("JGPUFH_HudDataHandler"));

		if (!c_aspectscale)
			c_aspectscale = CVar.GetCvar('hud_aspectscale', CPlayer);

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

		if (!c_drawHitmarkers)
			c_drawHitmarkers = CVar.GetCvar('jgphud_DrawHitmarkers', CPlayer);
		if (!c_hitMarkersAlpha)
			c_hitMarkersAlpha = CVar.GetCvar('jgphud_HitMarkersAlpha', CPlayer);
		if (!c_HitMarkersFadeTime)
			c_HitMarkersFadeTime = CVar.GetCvar('jgphud_HitMarkersFadeTime', CPlayer);

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
		if (!c_weaponSlotPos)
			c_weaponSlotPos = CVar.GetCvar('jgphud_WeaponSlotPos', CPlayer);
		if (!c_weaponSlotX)
			c_weaponSlotX = CVar.GetCvar('jgphud_WeaponSlotX', CPlayer);
		if (!c_weaponSlotY)
			c_weaponSlotY = CVar.GetCvar('jgphud_WeaponSlotY', CPlayer);

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
	}

	// Adjusts position of the element so that it never ends up
	// outside the screen. It also flips X and Y offset values
	// if the edge is at the bottom/right, so that positive
	// values are always aimed inward, and negative values cannot
	// take the element outside the screen.
	// If 'real' is true, returns real screen coordinates multiplied
	// but hudscale, rather than StatusBar coordinates.
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
			double aspect = c_aspectscale.GetBool() ? 1.2 : 1;
			hudscale.y /= aspect;
			pos.x *= hudscale.x;
			pos.y *= hudscale.y;
			size.x *= hudscale.x;
			size.y *= hudscale.y;
		}

		if ((flags & DI_SCREEN_HCENTER) == DI_SCREEN_HCENTER)
		{
			pos.x += -size.x*0.5 + screenSize.x * 0.5;
		}
		if ((flags & DI_SCREEN_VCENTER) == DI_SCREEN_VCENTER)
		{
			pos.y += -size.y*0.5 + screenSize.y * 0.5;
		}

		if ((flags & DI_SCREEN_CENTER) != DI_SCREEN_CENTER)
		{
			if ((flags & DI_SCREEN_TOP) == DI_SCREEN_TOP)
			{
				if (ofs.y < 0)
					ofs.y = 0;
			}
			if ((flags & DI_SCREEN_LEFT) == DI_SCREEN_LEFT)
			{
				if (ofs.x < 0)
					ofs.x = 0;
			}

			if ((flags & DI_SCREEN_RIGHT) == DI_SCREEN_RIGHT)
			{
				pos.x += -size.x + screenSize.x;
				if (ofs.x > 0)
					ofs.x = -abs(ofs.x);
				else
					ofs.x = 0;
			}		
			if ((flags & DI_SCREEN_BOTTOM) == DI_SCREEN_BOTTOM)
			{
				pos.y += -size.y + screenSize.y;
				if (ofs.y > 0)
					ofs.y = -abs(ofs.y);
				else
					ofs.y = 0;
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
		if (!c_BackColor)
			c_BackColor = CVar.GetCVar('jgphud_BackColor', CPlayer);
		if (!c_BackAlpha)
			c_BackAlpha = CVar.GetCVar('jgphud_BackAlpha', CPlayer);
			
		int a = 255 * c_BackAlpha.GetFloat();
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
			DrawString(mainHUDFont, leftText, barpos + (-1, 0), flags|DI_TEXT_ALIGN_RIGHT);

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
			DrawString(mainHUDFont, ""..rightText, barpos + (barwidth + 1, 0), flags|DI_TEXT_ALIGN_LEFT);
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
	void SetupHexenArmorIcons()
	{
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
				// in Hexen armor the health field is used to
				// determine class (from 0 to 4, 0 being best,
				// and 4 being natural armor you have by default)
				int armorClass = def.health;
				let had = JGPHUD_HexenArmorData.Create(icon, armorClass);
				hexenArmorData.Push(had);
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
		// Draw health bar:
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
		bool hasHexenArmor;
		int bestHexenArmorPiece;
		double armAmount;
		double armMaxamount = 100;
		TextureID armTex;
		double armTexSize = 12;
		if (barm)
		{
			armAmount = barm.amount;
			armMaxAmount = barm.maxamount;
			[cRed, cGreen, cBlue, cFntCol] = GetArmorColor(barm.savePercent);
			armTex = barm.icon;
		}
		if (hexArm)
		{
			for (int i = 0; i < hexArm.Slots.Size(); i++)
			{
				armAmount += hexArm.Slots[i];
			}
			if (armAmount > 0)
			{
				if (hexenArmorData.Size() <= 0)
				{
					SetupHexenArmorIcons();
				}
				for (int i = 0; i < hexArm.Slots.Size(); i++)
				{
					if (hexArm.Slots[i] > hexArm.Slots[bestHexenArmorPiece])
					{
						bestHexenArmorPiece = i;
					}
				}
				for (int i = 0; i < hexenArmorData.Size(); i++)
				{
					let had = hexenArmorData[i];
					if (had && bestHexenArmorPiece == had.armorClass)
					{
						armTex = had.icon;
						break;
					}
				}
				armMaxAmount = 80;
				hasHexenArmor = true;
				[cRed, cGreen, cBlue, cFntCol] = GetArmorColor(armAmount / armMaxAmount);
			}
		}

		iconPos.y = pos.y + height * 0.25;
		if (armAmount > 0)
		{
			string ap = "AP";
			if (armTex.isValid())
			{
				ap = "";
				// uses Hexen armor:
				/*if (hasHexenArmor && bestHexenArmorPiece < 4)
				{
					vector2 armPos = iconPos + (-armTexSize*0.5, armTexSize*0.5);
					armTexSize *= 0.5;
					for (int i = 4; i >= bestHexenArmorPiece; i--)
					{
						TextureID icon;
						for (int j = 0; j <hexenArmorData.Size(); j++)
						{
							let had = hexenArmorData[j];
							if (had && had.armorClass == i)
							{
								icon = had.icon;
								break;
							}
						}
						DrawTexture(icon, armPos, flags|DI_ITEM_CENTER, box:(armTexSize,armTexSize));
						armPos += (2, -2);
					}
				}*/

				// uses normal armor:
				//else
				//{
					DrawTexture(armTex, iconPos, flags|DI_ITEM_CENTER, box:(armTexSize,armTexSize));
				//}

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
		vector2 weapIconBox = (size.x - indent*2, 18);
		vector2 ammoIconBox = (size.x * 0.25 - indent*4, 16);
		double ammoTextHeight = mainHUDFont.mFont.GetHeight();
		int ammoBarHeight = 8;
		// If at least one ammo type exists, add ammoIconBox height
		// and indentation to total height:
		if (am1 || am2)
		{
			size.y += ammoIconBox.y + ammoTextHeight + indent*4;
		}
		
		// If we're drawing the ammo bar, add its height and indentation
		// to total height:
		bool drawAmmobar = c_drawAmmoBar.GetBool();
		if (drawAmmobar && (am1 || am2))
		{
			size.y += ammoBarHeight + indent*2;
		}
		
		// If weapon icon is to be draw (check CVAR and the validity of
		// the icon), add its height and indentation to total height:
		TextureID weapIcon = GetIcon(weap, DI_FORCESCALE);
		bool weapIconValid = c_DrawWeapon.GetBool() && weapIcon.IsValid() && TexMan.GetName(weapIcon) != 'TNT1A0';
		if (weapIconValid)
		{
			size.y += weapIconBox.y + indent*2;
		}

		// If there are no ammotypes or weapon icons, stop here:
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
				DrawFlatColorBar(ammoBarPos, am.amount, am.maxamount, color(255, 192, 128, 40), barwidth: barwidth, barheight: ammoBarHeight, segments: am.maxamount / 10, flags: flags);
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
				DrawFlatColorBar(ammoBarPos, am1.amount, am1.maxamount, color(255, 192, 128, 40), barwidth: barwidth, barheight: ammoBarHeight, segments: am1.maxamount / 20, flags: flags);
				ammoBarPos.x = ammo2Pos.x - barWidth*0.5;
				DrawFlatColorBar(ammoBarPos, am2.amount, am2.maxamount, color(255, 192, 128, 40), barwidth: barwidth, barheight: ammoBarHeight, segments: am2.maxamount / 20, flags: flags);
			}
		}
	}

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
		for (int sn = 0; sn <= 10; sn++)
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

	void UpdateAttacker(double angle)
	{
		let hmd = JGPUFH_HitMarkerData.Create(angle);
		if (hmd)
		{
			hmData.Push(hmd);
		}
	}

	void DrawHitMarkers(double size = 80)
	{
		if (!c_drawHitmarkers.GetBool())
			return;

		if (!hitMarker)
		{
			hitMarker = new("Shape2D");

			vector2 p = (-0.1, -1);
			hitMarker.Pushvertex(p);
			hitMarker.PushCoord((0,0));
			p.x*= -1;
			hitMarker.Pushvertex(p);
			hitMarker.PushCoord((0,0));
			p.x *= -0.4;
			p.y = -0.55;
			hitMarker.Pushvertex(p);
			hitMarker.PushCoord((0,0));
			p.x*= -1;
			hitMarker.Pushvertex(p);
			hitMarker.PushCoord((0,0));

			hitMarker.PushTriangle(0, 1, 2);
			hitMarker.PushTriangle(1, 2, 3);
		}

		vector2 hudscale = GetHudScale();
		if (!hitMarkerTransf)
			hitMarkerTransf = new("Shape2DTransform");
		for (int i = hmData.Size() - 1; i >= 0; i--)
		{
			let hmd = JGPUFH_HitMarkerData(hmData[i]);
			if (!hmd)
				continue;
			
			hitMarkerTransf.Clear();
			hitMarkerTransf.Scale((size, size) * hudscale.x);
			hitMarkerTransf.Rotate(hmd.angle);
			hitMarkerTransf.Translate((Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5));
			hitMarker.SetTransform(hitMarkerTransf);
			Screen.DrawShapeFill(color(0, 0, 255), hmd.alpha, hitMarker);
		}
	}

	void UpdateHitMarkers()
	{
		for (int i = hmData.Size() - 1; i >= 0; i--)
		{
			let hmd = JGPUFH_HitMarkerData(hmData[i]);
			if (!hmd)
				continue;

			hmd.alpha -= c_HitMarkersAlpha.GetFloat() / (c_HitMarkersFadeTime.GetFloat() * TICRATE);
			if (hmd.alpha <= 0)
			{
				hmd.Destroy();
				hmData.Delete(i);
			}
		}
	}

	void RefreshReticleHitMarker()
	{
		reticleMarkerAlpha = c_HitMarkersAlpha.GetFloat();
	}

	void UpdateReticleHitMarker()
	{
		if (reticleMarkerAlpha > 0)
		{
			reticleMarkerAlpha -= 0.1;
		}
	}

	void DrawReticleHitMarker()
	{
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
			vector2 hudscale = GetHudScale();
			double size = 14 * CVar.GetCvar('CrosshairScale', CPlayer).GetFloat();	
			reticleMarkerTransform.Clear();
			reticleMarkerTransform.Scale((size, size) * hudscale.x);
			reticleMarkerTransform.Translate((Screen.GetWidth() * 0.5, Screen.GetHeight() * 0.5));
			reticleHitMarker.SetTransform(reticleMarkerTransform);
			Screen.DrawShapeFill(color(0, 0, 255), reticleMarkerAlpha, reticleHitMarker);
		}
	}

	void GetWeaponSlots()
	{
		if (weaponSlotData.Size() > 0)
			return;

		WeaponSlots wslots = CPlayer.weapons;
		if (!wslots)
			return;

		for (int i = 1; i <= 10; i++)
		{
			// Slot 0 is the 10th slot:
			int sn = i >= 10 ? 0 : i;
			int size = wslots.SlotSize(sn);
			if (size <= 0)
				continue;

			for (int s = 0; s < size; s++)
			{
				class<Weapon> weap = wslots.GetWeapon(sn, s);
				if (weap)
				{
					let wsd = JGPUFH_WeaponSlotData.Create(sn, s, weap);
					if (wsd)
					{
						totalSlots = i;
						maxSlotID = size+1; //index 0 is 1st box
						weaponSlotData.Push(wsd);
					}
				}
			}
		}
	}

	void DrawWeaponSlots(vector2 box = (16, 10))
	{
		if (c_drawWeaponSlots.GetBool() == false)
			return;

		int flags = SetScreenFlags(c_weaponSlotPos.GetInt());
		vector2 ofs = ( c_weaponSlotX.GetInt(), c_weaponSlotY.GetInt() );
		double indent = 2;
		double width = (box.x + indent) * totalSlots - indent; //we don't need indent at the end
		double height = (box.y + indent) * maxSlotID - indent; //ditto
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		vector2 wpos = pos;
		for (int i = 0; i < weaponSlotData.Size(); i++)
		{
			let wsd = weaponSlotData[i];
			if (wsd)
			{
				if (wsd.slotIndex == 0 && i > 0)
				{
					wpos.x += (box.x + indent);
				}
				wpos.y = pos.y + (box.y + indent) * wsd.slotIndex;
				
				// greenish fill if the weapon is currently selected:
				color col = GetBaseplateColor();
				int fntCol = Font.CR_Untranslated;
				if (CPlayer.readyweapon && CPlayer.readyweapon.GetClass() == wsd.weaponClass)
				{
					col = color(180, 80, 200, 60);
					fntCol = Font.CR_Gold;
				}
				Fill(col, wpos.x, wpos.y, box.x, box.y, flags);
				DrawInventoryIcon(CPlayer.mo.FindInventory(wsd.weaponClass), wpos + box*0.5, flags|DI_ITEM_CENTER, boxsize: box);
				double fy = mainHUDFont.mFont.GetHeight();
				string slotNum = ""..wsd.slot;
				DrawString(mainHUDFont, slotNum, (wpos.x+box.x, wpos.y+box.y-fy*0.5), flags|DI_TEXT_ALIGN_RIGHT, fntCol, 0.8, scale:(0.5, 0.5));
			}
		}
	}

	// The minimap is a pretty annoying bit. Aside from potentially causing
	// performance issues, it also has  to be drawn fully using Screen
	// methods because StatusBar doesn't have anything like shapes and
	// line drawing.
	void DrawMinimap()
	{
		if (!c_drawMinimap.GetBool() || automapActive)
			return;
		
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
			double angStep = 360. / steps;
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
		bool circular = c_CircularMinimap.GetBool();
		Shape2D shapeToUse = circular ? minimapShape_Circle : minimapShape_Square;
		// A circular shape that was created around (0,0) has to be
		// scaled to 50% and moved to the center of the element,
		// since it's drawn from the center, not the corner,
		// in contrast to a square:
		double shapeFac = circular ? 0.5 : 1.;
		vector2 shapeOfs = circular ? (size*shapeFac,size*shapeFac) : (0,0);
		minimapTransform.Scale((size,size) * shapeFac);
		minimapTransform.Translate(pos + shapeOfs);
		shapeToUse.SetTransform(minimapTransform);

		// background:
		Color baseCol = GetBaseplateColor();
		double edgeThickness = 1 * hudscale.x;
		
		// Fill the shaep with the draw the outline color
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

	void DrawMapData(vector2 pos, vector2 box, int flags)
	{
		let fy = mainHUDFont.mFont.GetHeight();

		if ((flags & DI_SCREEN_BOTTOM) == DI_SCREEN_BOTTOM)
		{
			pos.y -= fy;
		}
	}

	int, int TicsToSeconds(int tics)
	{
		int totalSeconds = tics / TICRATE;
		int minutes = (totalSeconds / 60) % 60;
		int seconds = totalSeconds % 60;

		return minutes, seconds;
	}

	override void DrawPowerups()
	{
		if (!c_drawPowerups.GetBool())
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
		HUDFont fnt = mainHUDFont;
		double textScale = 0.8;
		double fy = fnt.mFont.GetHeight() * textScale;
		double width = fnt.mFont.StringWidth("00:00") * textScale + iconSize + indent;
		double height = (iconsize + indent) * powerNum + indent;
		vector2 pos = AdjustElementPos((0,0), flags, (width, height), ofs);
		pos.y += iconSize*0.5;

		for (int i = 0; i < powerNum; i++)
		{
			let pwd = handler.powerupData[i];
			if (!pwd)
				continue;
			let pow = Powerup(CPlayer.mo.FindInventory(pwd.powerupType));
			if (pow)
			{
				DrawTexture(pwd.icon, (pos.x + iconSize*0.5, pos.y), flags|DI_ITEM_CENTER, box:(iconSize, iconSize));
				int min, sec;
				[min, sec] = TicsToSeconds(pow.EffectTics);
				DrawString(fnt, String.Format("%2d:%2d",min,sec), (pos.x + iconsize + indent, pos.y - fy*0.5), flags|DI_TEXT_ALIGN_LEFT, alpha: pow.isBlinking() ? 0.5 : 1.0, scale:(textscale,textscale));
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
		// If there are 3 keys or fewer, the columns are = total keys,
		// and rows = 1.
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

	const ITEMBARICONSIZE = 28;

	double GetInvBarIconSize()
	{
		if (c_InvBarIconSize)
			return c_InvBarIconSize.GetInt();
		return ITEMBARICONSIZE;
	}

	void DrawInventoryBar(int numfields = 7)
	{
		// Perform the usual checks first:
		if (!c_drawInvBar.GetBool())
			return;
		if (Level.NoInventoryBar)
			return;
		CPlayer.mo.InvFirst = ValidateInvFirst(numfields);
		if (!CPlayer.mo.InvFirst)
			return;
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
		numfields = Clamp(numfields, 1, totalItems);

		// numfields must be an odd number:
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

		// Show some grey behind the center (selected item) icon:
		color backCol = color(80, 255,255,255);
		Fill (backCol, cursPos.x, cursPos.y, cursSize.x, cursSize.x, flags);

		// Show gray gradient fill aimed to the left and right of
		// the selected item when the inventory bar is active:
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
		// Hide two edge icons:
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
		CPlayer.mo.InvFirst = ValidateInvFirst(numfields);
		if (!CPlayer.mo.InvFirst)
			return;

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

class JGPHUD_HexenArmorData ui
{
	TextureID icon;
	int armorClass;

	static JGPHUD_HexenArmorData Create(TextureID icon, int armorClass)
	{
		let had = JGPHUD_HexenArmorData(New("JGPHUD_HexenArmorData"));
		if (had)
		{
			had.icon = icon;
			had.armorClass = armorClass;
		}
		return had;
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

class JGPUFH_WeaponSlotData ui
{
	int slot;
	int slotIndex;
	class<Weapon> weaponClass;

	static JGPUFH_WeaponSlotData Create(int slot, int slotIndex, class<Weapon> weaponClass)
	{
		let wsd = JGPUFH_WeaponSlotData(New("JGPUFH_WeaponSlotData"));
		if (wsd)
		{
			wsd.slot = slot;
			wsd.slotIndex = slotIndex;
			wsd.weaponClass = weaponClass;
		}
		return wsd;
	}
}

class JGPUFH_HitMarkerData ui
{
	double angle;
	double alpha;

	static JGPUFH_HitMarkerData Create(double angle)
	{
		let hmd = JGPUFH_HitMarkerData(New("JGPUFH_HitMarkerData"));
		if (hmd)
		{
			hmd.angle = angle;
			hmd.alpha = Cvar.GetCvar("jgphud_HitMarkersAlpha", players[consoleplayer]).GetFloat();
		}
		return hmd;
	}
}

class JGPUFH_HudDataHandler : EventHandler
{
	ui JGPUFH_FlexibleHUD hud;
	array <JGPUFH_PowerupData> powerupData;
	transient CVar c_ScreenReddenFactor;

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

	// The weird hack that is mean to give icons to powerups
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
			// if so, abort:
			TextureID icon = pwr.Icon;
			if (icon.isValid() && TexMan.GetName(icon) != 'TNT1A0')
				return;

			// Check if tha powerup was already processed:
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