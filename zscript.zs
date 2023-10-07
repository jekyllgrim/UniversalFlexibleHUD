version "4.10"

class JGP_FlexibleHUD : BaseStatusBar
{
	HUDFont mainHUDFont;
	HUDFont smallHUDFont;
	HUDFont numHUDFont;
	CVar mainFontVar;
	CVar smallFontVar;
	CVar numFontVar;

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
		mainFontVar = CVar.GetCVar('jgphud_mainfont', players[consoleplayer]);
		smallFontVar = CVar.GetCVar('jgphud_smallfont', players[consoleplayer]);
		numFontVar = CVar.GetCVar('jgphud_numberfont', players[consoleplayer]);
		
		Font fnt = Font.FindFont(mainFontVar ? mainFontVar.GetString() : "BigUpper");
		if (!fnt)
			fnt = "BigUpper";
		mainHUDFont = HUDFont.Create(fnt);
		
		fnt = Font.FindFont(smallFontVar ? smallFontVar.GetString() : "Confont");
		if (!fnt)
			fnt = "Confont";
		smallHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true);
		
		fnt = Font.FindFont(numFontVar ? numFontVar.GetString() : "IndexFont");
		if (!fnt)
			fnt = "IndexFont";
		numHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), true);
	}

	override void Draw(int state, double ticFrac)
	{
		super.Draw(state, ticFrac);

		if (state == HUD_None || state == HUD_AltHud)
			return;
		
		BeginHUD();
		DrawHitMarkers();
		DrawHealthArmor((1,-1));
		DrawWeaponBlock((-1, -1));
		DrawAllAmmo((-34, -54), DI_SCREEN_RIGHT_BOTTOM);
	}

	override void Tick()
	{
		super.Tick();
		UpdateHitMarkers();
	}

	void DrawFlatColorBar(vector2 pos, double curValue, double maxValue, color barColor, string leftText = "", string rightText = "", int valueColor = -1, double barwidth = 64, double barheight = 8, double indent = 0.6, color backColor = color(255, 0, 0, 0), double sparsity = 1, uint segments = 0, int flags = 0, double scale = 1.0)
	{
		barwidth *= scale;
		barheight *= scale;
		indent *= scale;
		sparsity *= scale;

		DrawString(smallHUDFont, leftText, pos + (-1, 0), flags|DI_TEXT_ALIGN_RIGHT, scale: (scale, scale));

		vector2 barpos = pos;// + (0, barheight * 0.5);
		Fill(backColor, barpos.x, barpos.y, barwidth, barheight, flags);
		double innerBarWidth = barwidth - (indent * 2);
		double innerBarHeight = barheight - (indent * 2);
		double curInnerBarWidth = LinearMap(curValue, 0, maxValue, 0, innerBarWidth, true);
		vector2 innerBarPos = (barpos.x + indent, barpos.y + indent);
		if (sparsity > 0 && segments > 0)
		{
			double singleSegWidth = (innerBarWidth - (segments - 1) * sparsity) / segments;
			vector2 segPos = innerBarPos;
			while (segPos.x < curInnerBarWidth + innerBarPos.x)
			{
				double segW = min(singleSegWidth, curInnerBarWidth - segPos.x + innerBarPos.x);
				Fill(barcolor, segPos.x, segPos.y, segW, innerBarHeight, flags);
				segPos.x += singleSegWidth + sparsity;
			}
		}
		else
		{
			Fill(barColor, innerBarPos.x, innerBarPos.y, curInnerBarWidth, innerBarHeight, flags);
		}

		if (valueColor != -1)
		{
			double fy = numHUDFont.mFont.GetHeight() * scale;
			DrawString(numHUDFont, ""..int(curvalue), pos + (barwidth * 0.5, barheight * 0.5 - fy * 0.5), flags|DI_TEXT_ALIGN_CENTER, translation: valueColor, scale: (scale, scale));
		}
		
		DrawString(smallHUDFont, ""..rightText, pos + (barwidth + 1, 0), flags|DI_TEXT_ALIGN_LEFT, scale: (scale, scale));
	}

	color GetBaseplateColor()
	{
		return color(140,113,66,80);
	}

	void DrawHealthArmor(vector2 pos = (0,0), int flags = DI_SCREEN_LEFT_BOTTOM, double barwidth = 72, bool drawMug = true, double scale = 1.0)
	{
		let barm = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		bool hasArmor = (barm && barm.amount > 0);
		int bkgOfs = 14;
		if (hasArmor)
			bkgOfs *= 2;
		vector2 fillpos = (pos.x, pos.y - bkgOfs);
		vector2 fillSize = (barwidth + 24, bkgOfs);
		Fill(GetBaseplateColor(),
			fillpos.x,
			fillpos.y,
			fillSize.x,
			fillSize.y,
			flags
		);
		if (CVar.GetCvar('jgphud_drawface', CPlayer))
		{
			fillpos.x += fillSize.x + 1;
			fillSize.x = hasArmor ? bkgOfs : bkgOfs * 2;
			fillSize.y = fillSize.x;
			fillpos.y = pos.y - fillSize.x;
			Fill(GetBaseplateColor(),
				fillpos.x,
				fillpos.y,
				fillSize.x,
				fillSize.y,
				flags
			);
			DrawTexture(GetMugShot(5), (fillpos.x + fillSize.x * 0.5, fillpos.y + fillSize.y * 0.5), flags|DI_ITEM_CENTER, box:fillSize - (2,2));
		}
		int barFlags = flags|DI_ITEM_LEFT_BOTTOM;
		pos += (18, -10);

		// Draw health bar:
		int health = CPlayer.mo.health;
		int maxhealth = CPlayer.mo.GetMaxHealth(true);
		int cRed = LinearMap(health, 0, maxhealth, 160, 0, true);
		int cGreen = LinearMap(health, 0, maxhealth, 0, 160, true);
		int cBlue = LinearMap(health, maxhealth, maxhealth * 2, 0, 160, true);
		DrawFlatColorBar(pos, health, maxhealth, color(255, cRed, cGreen, cBlue), "", valueColor: Font.CR_White, barwidth:barwidth, flags:barFlags);
		vector2 crossPos = pos - (4, 0);
		double crossLength = 8;
		double crossWidth = 2;
		Fill(color(255,132,40,40),
			crossPos.x - crossLength - 1,
			crossPos.y - 1,
			crossLength + 2,
			crossLength + 2,
			flags);
		Fill(color(255,200,200,200), 
			crossPos.x - crossLength * 0.5 - crossWidth * 0.5, 
			crossPos.y, 
			crossWidth, 
			crossLength, 
			flags);
		Fill(color(255,200,200,200), 
			crossPos.x - crossLength, 
			crossPos.y + crossLength * 0.5 - crossWidth * 0.5, 
			crossLength, 
			crossWidth, 
			flags);
		
		// Draw armor bar:
		pos += (0, -14);
		if (hasArmor)
		{
			int armAmount = barm.amount;
			int armMaxAmount = barm.maxamount;
			int savePercent = barm.savePercent * 100;
			cRed = 0;
			cGreen = 0;
			cBlue = 0;
			if (savePercent >= 50)
			{
				cBlue = 255;
				if (savePercent >= 80)
				{
					cGreen = 255;
				}
			}
			else 
			{
				cRed = 72;
				if (savePercent >= 33)
				{
					cGreen = 160;
				}
			}
			TextureID armTex = barm.icon;
			string ap = "AP";
			if (armTex.isValid())
			{
				ap = "";
				DrawTexture(barm.icon, pos + (-8, 8 * 0.5), flags|DI_ITEM_CENTER, box:(14,14));
			}
			//String.Format("[%d\%]", savePercent)
			DrawFlatColorBar(pos, armAmount, armMaxamount, color(255, cRed, cGreen, cBlue), ap, valueColor: Font.CR_White,barwidth:barwidth, segments: barm.maxamount / 10, flags:barFlags);
		}
	}

	int GetAmmoColor(Ammo am)
	{
		int amount = am.amount;
		int maxamount = am.maxamount;
		if (amount >= maxamount * 0.75)
			return Font.CR_Green;
		if (amount >= maxamount * 0.5)
			return Font.CR_Yellow;
		if (amount >= maxamount * 0.25)
			return Font.CR_Orange;
		return Font.CR_Red;
	}

	void DrawWeaponBlock(vector2 pos = (0,0), int flags = DI_SCREEN_RIGHT_BOTTOM)
	{
		let weap = CPlayer.readyweapon;
		if (!weap)
			return;

		Ammo am1, am2;
		int am1amt, am2amt;
		[am1, am2, am1amt, am2amt] = GetCurrentAmmo();

		vector2 size = (66, 50);
		if (!am1 && !am2)
			size.y *= 0.5;			
		
		let icon = weap.icon;
		if ((!icon.isValid() || TexMan.GetName(icon) == "TNT1A0") && weap.spawnstate)
		{
			icon = weap.spawnState.GetSpriteTexture(0);
		}
		if (!icon.isValid() || TexMan.GetName(icon) == "TNT1A0")
		{
			icon = weap.FindState('Ready').GetSpriteTexture(0);
		}
		if (icon.IsValid() || am1 || am2)
		{
			Fill(GetBaseplateColor(), pos.x - size.x, pos.y - size.y, size.x, size.y, flags);
		}
		if (icon.IsValid())
		{
			vector2 iconBox = (64, 18);
			DrawTexture(icon, pos - (iconBox.x  * 0.5 + 1, iconBox.y * 0.5 + 1), flags|DI_ITEM_CENTER, box: (64, 18));
		}

		if (!am1 && !am2)
			return;

		vector2 ammoBoxSize = (22, 16);
		vector2 ammo1pos = pos + (-size.x * 0.5, -size.y + ammoBoxSize.y * 0.5 + 1);
		vector2 ammo2pos = ammo1pos;
		// Uses only 1 ammo type:
		if ((am1 && !am2) || (!am1 && am2))
		{
			Ammo am = am1 ? am1 : am2;
			DrawInventoryIcon(am, ammo1pos, flags|DI_ITEM_CENTER, boxSize: ammoBoxSize);
			DrawString(smallHUDFont, ""..am.amount, (ammo1pos.x, pos.y - 32), flags|DI_TEXT_ALIGN_CENTER, translation: GetAmmoColor(am));
		}
		// Uses 2 ammo types:
		else
		{
			ammo1pos.x = pos.x + (-size.x * 0.25);
			ammo2pos.x = pos.x + (-size.x * 0.75);
			DrawInventoryIcon(am1, ammo1pos, flags|DI_ITEM_CENTER, boxSize: ammoBoxSize);
			DrawString(smallHUDFont, ""..am1amt, (ammo1pos.x, pos.y - 32), flags|DI_TEXT_ALIGN_CENTER, translation: GetAmmoColor(am1));
			DrawInventoryIcon(am2, ammo2pos, flags|DI_ITEM_CENTER, boxSize: ammoBoxSize);
			DrawString(smallHUDFont, ""..am2amt, (ammo2pos.x, pos.y - 32), flags|DI_TEXT_ALIGN_CENTER, translation: GetAmmoColor(am2));
		}
	}

	void DrawAllAmmo(vector2 pos, int flags = 0)
	{
		double iconSize = 6;
		pos -= (iconsize, iconsize * 0.5);
		flags |= DI_ITEM_CENTER;
		let hfnt = smallHUDFont;
		double fntScale = 0.6;
		double fy = hfnt.mFont.GetHeight() * fntScale;
		Inventory item;
		for (let item = CPlayer.mo.inv; item; item = item.Inv)
		{
			Ammo am = Ammo(item);
			if (am)
			{
				let icon = am.icon;
				if (!icon || !icon.IsValid())
					continue;
				DrawTexture(icon, pos, flags, box:(iconSize, iconSize));
				DrawString(hfnt, String.Format("%3d/%3d", am.amount, am.maxamount), pos + (iconsize * 0.5 + 1, -fy * 0.5),flags, translation: GetAmmoColor(am), scale:(fntScale,fntScale));
				pos.y -= (iconsize + 1);
			}
		}
	}

	Shape2D hitMarker;
	Shape2DTransform hitMarkerTransf;
	array <JGP_HitMarkerData> hmData;
	Actor prevAttacker;

	void CreateHitIndicator()
	{
		if (!hitMarker)
		{
			hitMarker = new("Shape2D");
			hitMarker.Pushvertex((-0.25,-1.0));
			hitMarker.Pushvertex((0.25,-1.0));
			hitMarker.Pushvertex((-0.25,-1.0) * 0.8);
			hitMarker.Pushvertex((0.25,-1.0) * 0.8);
			hitMarker.PushCoord((0,0));
			hitMarker.PushCoord((0,0));
			hitMarker.PushCoord((0,0));
			hitMarker.PushCoord((0,0));
			hitMarker.PushTriangle(0, 1, 2);
			hitMarker.PushTriangle(1, 2, 3);
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
		CreateHitIndicator();

		for (int i = hmData.Size() - 1; i >= 0; i--)
		{
			let hmd = JGP_HitMarkerData(hmData[i]);
			if (!hmd)
				continue;
			
			vector2 hudscale = GetHudScale();
			
			hitMarkerTransf = new("Shape2DTransform");
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

			hmd.alpha -= 0.025;
			if (hmd.alpha <= 0)
			{
				hmData.Delete(i);
			}
		}
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

class JGP_HitMarkerHandler : StaticEventHandler
{
	ui JGP_FlexibleHUD hud;

	override void WorldThingDamaged(worldEvent e)
	{
		let pmo = PlayerPawn(e.thing);
		if (!pmo) return;
		let attacker = pmo.player.attacker;
		if (!attacker) return;
		
		EventHandler.SendInterfaceEvent(pmo.PlayerNumber(), "PlayerWasAttacked", Actor.DeltaAngle(pmo.AngleTo(attacker), pmo.angle));
	}

	override void InterfaceProcess(consoleEvent e)
	{
		if (!e.isManual && e.name == "PlayerWasAttacked")
		{
			if (!hud)
				hud = JGP_FlexibleHUD(StatusBar);
			hud.UpdateAttacker(e.args[0]);
		}
	}
}