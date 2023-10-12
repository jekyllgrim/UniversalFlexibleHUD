class JGP_FlexibleHUD : BaseStatusBar
{
	HUDFont mainHUDFont;
	HUDFont smallHUDFont;
	HUDFont numHUDFont;

	JGP_HudDataHandler handler;

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

	// Hit (incoming damage) marker
	Shape2D hitMarker;
	Shape2DTransform hitMarkerTransf;
	array <JGP_HitMarkerData> hmData;
	Actor prevAttacker;

	// Hit (reticle) marker
	Shape2D reticleHitMarker;
	double reticleMarkerAlpha;
	Shape2DTransform reticleMarkerTransform;
	
	// Weapon slots
	array <JGP_WeaponSlotData> weaponSlotData;
	int maxSlotID;
	int totalSlots;

	// Minimap
	Shape2D minimapShape_Square;
	Shape2D minimapShape_Circle;
	Shape2D minimapShape_Arrow;
	Shape2DTransform minimapTransform;
	const MAPSCALEFACTOR = 8;

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
		Font fnt = "BigUpper";
		mainHUDFont = HUDFont.Create(fnt);
		fnt = "Confont";
		smallHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true);
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
	}

	void CacheCvars()
	{
		if (!handler)
			handler = JGP_HudDataHandler(EventHandler.Find("JGP_HudDataHandler"));

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
	vector2 AdjustPosition(vector2 pos, int flags, vector2 size, vector2 ofs = (0,0), bool real = false)
	{
		vector2 screenSize = (0,0);
		vector2 hudscale = GetHudScale();
		if (real)
		{
			screenSize = (Screen.GetWidth(), Screen.GetHeight());
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
		return pos + ofs;
	}

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

	// A CVar value should be passed here to return appropriate flags:
	int SetScreenFlags(int val)
	{
		val = Clamp(val, 0, ScreenFlags.Size() - 1);
		return ScreenFlags[val];
	}

	CVar c_BackColor;
	CVar c_BackAlpha;
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
			DrawString(smallHUDFont, leftText, barpos + (-1, 0), flags|DI_TEXT_ALIGN_RIGHT);

		Fill(backColor, barpos.x, barpos.y, barwidth, barheight, flags);
		double innerBarWidth = barwidth - (indent * 2);
		double innerBarHeight = barheight - (indent * 2);
		double curInnerBarWidth = LinearMap(curValue, 0, maxValue, 0, innerBarWidth, true);
		vector2 innerBarPos = (barpos.x + indent, barpos.y + indent);
		if (sparsity > 0 && segments > 0)
		{
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
			double singleSegWidth = (innerBarWidth - (segments - 1) * sparsity) / segments;
			vector2 segPos = innerBarPos;
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

		if (valueColor != -1)
		{
			double fy = numHUDFont.mFont.GetHeight();
			DrawString(numHUDFont, ""..int(curvalue), barpos + (barwidth * 0.5, barheight * 0.5 - fy * 0.5), flags|DI_TEXT_ALIGN_CENTER, translation: valueColor);
		}
		
		if (rightText)
			DrawString(smallHUDFont, ""..rightText, barpos + (barwidth + 1, 0), flags|DI_TEXT_ALIGN_LEFT);
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

	void DrawHealthArmor(double height = 28, double width = 120)
	{
		int drawThis = c_drawMainbars.GetInt();
		if (drawThis <= 0)
			return;

		int flags = SetScreenFlags(c_MainBarsPos.GetInt());
		int indent = 1;
		int faceSize = height;
		int mainBlockWidth = width;
		bool drawbars = drawThis >= 2;
		bool drawface = c_DrawFace.GetBool();

		let barm = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		bool hasArmor = (barm && barm.amount > 0);
		if (!drawbars)
		{
			mainBlockWidth *= 0.36;
		}
		width = mainBlockWidth;
		if (drawface)
		{
			width += indent + faceSize;
		}
		vector2 ofs = ( c_MainBarsX.GetInt(), c_MainBarsY.GetInt() );
		vector2 pos = AdjustPosition((0,0), flags, (width, height), ofs);
		
		int baseCol = GetBaseplateColor();
		// bars background:
		Fill(baseCol, pos.x, pos.y, mainBlockWidth, height, flags);
		// face background:
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

		// Draw health cross shape:
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
		
		int barWidth = mainBlockWidth - iconSize - indent*3;
		double barPosX = iconPos.x + iconsize*0.5 + indent;
		double fy = smallHUDFont.mFont.GetHeight();
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
			DrawString(smallHUDFont, String.Format("%3d", health), (barPosX, iconPos.y - fy*0.5), translation:GetPercentageFontColor(health,maxhealth));
		}
		
		// Draw armor bar:
		iconPos.y = pos.y + height * 0.25;
		if (hasArmor)
		{
			int armAmount = barm.amount;
			int armMaxAmount = barm.maxamount;
			TextureID armTex = barm.icon;
			string ap = "AP";
			[cRed, cGreen, cBlue, cFntCol] = GetArmorColor(barm.savePercent);
			if (armTex.isValid())
			{
				ap = "";
				DrawTexture(barm.icon, iconPos, flags|DI_ITEM_CENTER, box:(14,14));
			}
			if (drawbars)
			{
				DrawFlatColorBar((barPosX, iconPos.y), armAmount, armMaxamount, color(255, cRed, cGreen, cBlue), ap, valueColor: Font.CR_White, barwidth:barWidth, barheight: 6, segments: barm.maxamount / 10, flags:barFlags);
			}
			else
			{
				DrawString(smallHUDFont, String.Format("%3d", armAmount), (barPosX, iconPos.y - fy*0.5), translation:cFntCol);
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
		
		Ammo am1, am2;
		int am1amt, am2amt;
		[am1, am2, am1amt, am2amt] = GetCurrentAmmo();

		int indent = 1;
		vector2 size = (66, 0);
		vector2 weapIconBox = (size.x - indent*2, 18);
		vector2 ammoIconBox = (size.x * 0.25 - indent*4, 16);
		double ammoTextHeight = smallHUDFont.mFont.GetHeight();
		int ammoBarHeight = 8;
		if (am1 || am2)
		{
			size.y += ammoIconBox.y + ammoTextHeight + indent*4;
		}
		
		bool drawAmmobar = c_drawAmmoBar.GetBool();
		if (drawAmmobar && (am1 || am2))
		{
			size.y += ammoBarHeight + indent*2;
		}
		
		TextureID weapIcon = GetIcon(weap, DI_FORCESCALE);
		bool weapIconValid = weapIcon.IsValid();
		if (weapIconValid && c_DrawWeapon.GetBool())
		{
			size.y += weapIconBox.y + indent*2;
		}

		vector2 pos = AdjustPosition((0,0), flags, (size.x, size.y), ofs);

		if (weapIconValid || am1 || am2)
		{
			Fill(GetBaseplateColor(), pos.x, pos.y, size.x, size.y, flags);
		}
		if (weapIconValid && c_DrawWeapon.GetBool())
		{
			DrawTexture(weapIcon, pos + (weapIconBox.x  * 0.5 + indent, size.y - weapIconBox.y * 0.5 - indent), flags|DI_ITEM_CENTER, box: (64, 18));
		}

		if (!am1 && !am2)
			return;

		vector2 ammo1pos = pos + (size.x * 0.5, ammoIconBox.y * 0.5 + indent);
		vector2 ammo2pos = ammo1pos;
		vector2 ammoTextPos = ammo1pos + (0, ammoIconBox.y*0.5 + indent);
		int barwidth = size.x - indent*2;
		vector2 ammoBarPos = ammoTextPos + (-barwidth*0.5, ammoTextHeight + indent);
		// Uses only 1 ammo type:
		if ((am1 && !am2) || (!am1 && am2))
		{
			Ammo am = am1 ? am1 : am2;
			DrawInventoryIcon(am, ammo1pos, flags|DI_ITEM_CENTER, boxSize: ammoIconBox);
			DrawString(smallHUDFont, ""..am.amount, ammoTextPos, flags|DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am.amount, am.maxamount));
			if (drawAmmobar)
			{
				DrawFlatColorBar(ammoBarPos, am.amount, am.maxamount, color(255, 192, 128, 40), barwidth: barwidth, barheight: ammoBarHeight, segments: am.maxamount / 10, flags: flags);				
			}
		}
		// Uses 2 ammo types:
		else
		{
			ammo1pos.x = pos.x + (size.x * 0.25);
			ammo2pos.x = pos.x + (size.x * 0.75);
			barwidth = size.x * 0.5 - indent * 4;
			ammoBarPos.x = ammo1Pos.x - barWidth*0.5;
			DrawInventoryIcon(am1, ammo1pos, flags|DI_ITEM_CENTER, boxSize: ammoIconBox);
			DrawString(smallHUDFont, ""..am1amt, (ammo1pos.x, ammoTextPos.y), flags|DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am1.amount, am1.maxamount));
			DrawInventoryIcon(am2, ammo2pos, flags|DI_ITEM_CENTER, boxSize: ammoIconBox);
			DrawString(smallHUDFont, ""..am2amt, (ammo2pos.x, ammoTextPos.y), flags|DI_TEXT_ALIGN_CENTER, translation: GetPercentageFontColor(am2.amount, am2.maxamount));
			if (drawAmmobar)
			{
				DrawFlatColorBar(ammoBarPos, am1.amount, am1.maxamount, color(255, 192, 128, 40), barwidth: barwidth, barheight: ammoBarHeight, segments: am1.maxamount / 20, flags: flags);
				ammoBarPos.x = ammo2Pos.x - barWidth*0.5;
				DrawFlatColorBar(ammoBarPos, am2.amount, am2.maxamount, color(255, 192, 128, 40), barwidth: barwidth, barheight: ammoBarHeight, segments: am2.maxamount / 20, flags: flags);
			}
		}
		return;
	}

	void DrawAllAmmo()
	{
		if (!c_drawAllAmmo.GetBool())
			return;

		double iconSize = 6;
		int indent = 1;
		int flags = SetScreenFlags(c_AllAmmoPos.GetInt());
		vector2 ofs = ( c_AllAmmoX.GetInt(), c_AllAmmoY.GetInt() );
		let hfnt = smallHUDFont;
		double fntScale = 0.6;
		double fy = hfnt.mFont.GetHeight() * fntScale;
		double width = iconsize + indent + smallHUDFont.mFont.StringWidth("000/000") * fntScale;
		double height;

		array <Ammo> ammoItems;
		for (let item = CPlayer.mo.inv; item; item = item.Inv)
		{
			Ammo am = Ammo(item);
			if (am)
			{
				let icon = GetIcon(am, DI_SKIPSPAWN|DI_SKIPREADY);
				if (!icon.IsValid())
					continue;
				ammoItems.Push(am); 
				height += iconsize + indent;
			}
		}
		if (ammoItems.Size() <= 0)
			return;

		vector2 pos = AdjustPosition((0,0), flags, (width, height), ofs);
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
		let hmd = JGP_HitMarkerData.Create(angle);
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
			let hmd = JGP_HitMarkerData(hmData[i]);
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
			let hmd = JGP_HitMarkerData(hmData[i]);
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
				class<Weapon> weap = CPlayer.weapons.GetWeapon(sn, s);
				if (weap)
				{
					let wsd = JGP_WeaponSlotData.Create(sn, s, weap);
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
		vector2 pos = AdjustPosition((0,0), flags, (width, height), ofs);
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
				double fy = smallHUDFont.mFont.GetHeight();
				string slotNum = ""..wsd.slot;
				DrawString(smallHUDFont, slotNum, (wpos.x+box.x, wpos.y+box.y-fy*0.5), flags|DI_TEXT_ALIGN_RIGHT, fntCol, 0.8, scale:(0.5, 0.5));
			}
		}
	}

	// The minimap is a pretty annoying bit. Aside from potentially causing
	// performance issues, it also has  to be drawn fully using Screen
	// methods because StatusBar doesn't have anything like shapes and
	// line drawing.
	void DrawMinimap()
	{
		if (!c_drawMinimap.GetBool())
			return;
		
		double size = c_MinimapSize.GetFloat();
		// Almost everything has to be multiplied by hudscale.x
		// so that it matches the general HUD scale regarldess
		// of physical resolution:
		vector2 hudscale = GetHudScale();
		// Screen flags are obtained as usual, although they're
		// only used in AdjustPosition, not in the actual
		// drawing functions, since Screen functions don't
		// interact with statusbar DI_* flags:
		int flags = SetScreenFlags(c_MinimapPos.GetInt());
		vector2 ofs = ( c_MinimapPosX.GetInt(), c_MinimapPosY.GetInt() );
		// Real: true makes this function return real screeen
		// coordinates rather virtual ones:
		vector2 pos = AdjustPosition((0,0), flags, (size, size), ofs, real:true);
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
		HUDFont fnt = smallHUDFont;
		double textScale = 0.8;
		double fy = fnt.mFont.GetHeight() * textScale;
		double width = fnt.mFont.StringWidth("00:00") * textScale + iconSize + indent;
		double height = (iconsize + indent) * powerNum + indent;
		vector2 pos = AdjustPosition((0,0), flags, (width, height), ofs);
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

		int totalKeys = Key.GetKeyTypeCount();
//		int possessedKeys;
//		for (Inventory item = CPlayer.mo.Inv; item; item = item.Inv)
//		{
//			Key ki = Key(item);
//			if (ki)
//			{
//				possessedKeys++;
//			}
//		}
//		totalKeys = min(possessedKeys, totalKeys);
		if (totalKeys <= 0)
			return;

		int placesInRow = ceil(totalKeys / (totalKeys*0.5) + 1);
		width = (iconsize + indent) * placesInRow + indent;
		height = (iconsize + indent) * (placesInRow-1);

		vector2 pos = AdjustPosition((0,0), flags, (width, height), ofs);
		Fill(GetBaseplateColor(), pos.x, pos.y, width, height);

		pos += (iconsize*0.5+indent, iconsize*0.5+indent);
		vector2 kpos = pos;
		int horKeys;
		for(int i = 0; i < totalKeys; i++)
		{
			Key inv = Key(CPlayer.mo.FindInventory(Key.GetKeyType(i)));
			if (!inv)
				continue;
			TextureID icon = GetIcon(inv, 0);
			if (!icon.IsValid() || TexMan.GetName(icon) == 'TNT1A0')
				continue;
			DrawTexture(icon, kpos, flags|DI_ITEM_CENTER, box:(iconSize, iconSize));
			horKeys++;
			if (horKeys >= placesInRow)
			{
				horKeys = 0;
				kpos.x = pos.x;
				kpos.y += iconSize;
			}
			else
			{
				kpos.x += iconsize + indent;
			}
		}
	}

	int, int TicsToSeconds(int tics)
	{
		int totalSeconds = tics / TICRATE;
		int minutes = (totalSeconds / 60) % 60;
		int seconds = totalSeconds % 60;

		return minutes, seconds;
	}
}

class JGP_PowerupData play
{
	TextureID icon;
	class<Inventory> powerupType;

	static JGP_PowerupData Create(TextureID icon, class<Inventory> powerupType)
	{
		let pwd = JGP_PowerupData(New("JGP_PowerupData"));
		if (pwd)
		{
			pwd.icon = icon;
			pwd.powerupType = powerupType;
		}
		return pwd;
	}
}

class JGP_WeaponSlotData ui
{
	int slot;
	int slotIndex;
	class<Weapon> weaponClass;

	static JGP_WeaponSlotData Create(int slot, int slotIndex, class<Weapon> weaponClass)
	{
		let wsd = JGP_WeaponSlotData(New("JGP_WeaponSlotData"));
		if (wsd)
		{
			wsd.slot = slot;
			wsd.slotIndex = slotIndex;
			wsd.weaponClass = weaponClass;
		}
		return wsd;
	}
}

class JGP_HitMarkerData ui
{
	double angle;
	double alpha;

	static JGP_HitMarkerData Create(double angle)
	{
		let hmd = JGP_HitMarkerData(New("JGP_HitMarkerData"));
		if (hmd)
		{
			hmd.angle = angle;
			hmd.alpha = Cvar.GetCvar("jgphud_HitMarkersAlpha", players[consoleplayer]).GetFloat();
		}
		return hmd;
	}
}

class JGP_HudDataHandler : EventHandler
{
	ui JGP_FlexibleHUD hud;
	array <JGP_PowerupData> powerupData;
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
			JGP_PowerupData pwd;
			let pwrCls = pwr.GetClass();
			for (int i = 0; i < powerupData.Size(); i++)
			{
				pwd = powerupData[i];
				if (pwd && pwd.powerupType == pwrCls)
					return;
			}
			
			// Try remembering the PowerupGiver's icon as this
			// powerup's icon:
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
				pwd = JGP_PowerupData.Create(icon, pwrCls);
				powerupData.Push(pwd);
			}
		}
	}

	override void InterfaceProcess(consoleEvent e)
	{
		if (!e.isManual)
		{
			if (!hud)
				hud = JGP_FlexibleHUD(StatusBar);
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