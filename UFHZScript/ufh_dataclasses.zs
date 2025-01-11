// Storage class for powerup data
class JGPUFH_PowerupData play
{
	TextureID icon;
	class<Inventory> powerupType;
	int renderStyle;

	static JGPUFH_PowerupData Create(TextureID icon, class<Inventory> powerupType, int renderStyle)
	{
		let pwd = JGPUFH_PowerupData(New("JGPUFH_PowerupData"));
		if (pwd)
		{
			pwd.icon = icon;
			pwd.powerupType = powerupType;
			// Keeping Normal is useless, switch to Translucent
			// to let us apply alpha to it:
			if (renderStyle == STYLE_Normal)
			{
				renderStyle = STYLE_Translucent;
			}
			pwd.renderStyle = renderStyle;
		}
		return pwd;
	}

	// The weird hack that is meant to give icons to powerups
	// that have no icons defined (like the Doom powerups):
	static void CreatePowerupIcon(class<PowerupGiver> pwrgCls, out array <JGPUFH_PowerupData> powerupData)
	{
		let pwrg = GetDefaultByType((class<PowerupGiver>)(pwrgCls));
		if (!pwrg || !pwrg.powerupType)
			return;
		// Get PowerupGiver's powerupType field:
		let pwr = GetDefaultByType((class<Inventory>)(pwrg.powerupType));
		if (!pwr)
			return;

		if (jgphud_debug)
			Console.Printf("\cHPOWERUPDATA\c- Trying to find icon for %s", pwr.GetClassName());

		JGPUFH_PowerupData pwd;
		let pwrCls = pwr.GetClass();
		// Check if that powerup was already processed:
		for (int i = 0; i < powerupData.Size(); i++)
		{
			pwd = powerupData[i];
			if (pwd && pwd.powerupType == pwrCls)
			{
				if (jgphud_debug)
					Console.Printf("\cHPOWERUPDATA\c- Powerup %s already processed; aborting", pwrCls.GetClassName());
				return;
			}
		}

		// Check if that powerupType has a proper icon;
		// if so, we're good, so abort:
		TextureID icon = pwr.Icon;
		if (icon.isValid() && TexMan.GetName(icon).IndexOf("TNT1") < 0)
		{
			if (jgphud_debug)
				Console.Printf("\cHPOWERUPDATA\c- Powerup %s already has icon: %s", pwr.GetClassName(), TexMan.GetName(icon));
			pwd = JGPUFH_PowerupData.Create(icon, pwrCls, pwrg.GetRenderstyle());
			powerupData.Push(pwd);
			return;
		}
		
		icon = JGPUFH_FlexibleHUD.FirstSpriteTexInSequence(pwrg.spawnstate);
		if (icon.isValid())
		{
			if (jgphud_debug)
				Console.Printf("\cHPOWERUPDATA\c- \cDPowerup %s now has a new icon: %s", pwr.GetClassName(), TexMan.GetName(icon));
			pwd = JGPUFH_PowerupData.Create(icon, pwrCls, pwrg.GetRenderstyle());
			powerupData.Push(pwd);
		}
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

// Damage markers have to be handled in play scope,
// because the markers needs to be angled towards
// the attacker, and actor pointers can't be transferred
// from play scope to UI scope. So, this thinker will
// create and update damage markers:
class JGPUFH_DmgMarkerController : Thinker
{
	array <JGPUFH_DmgMarker> markers;
	protected PlayerInfo player;
	protected transient CVar c_DamageMarkersAlpha;
	protected transient CVar c_DamageMarkersFadeTime;

	static JGPUFH_DmgMarkerController Create(PlayerInfo player)
	{
		let hmd = New("JGPUFH_DmgMarkerController");
		if (hmd)
		{
			hmd.player = player;
		}
		return hmd;
	}

	clearscope PlayerInfo GetPlayer()
	{
		return player;
	}

	// Creates a new marker:
	void AddMarker(Actor attacker, double angle = 0, int damage = 0)
	{
		if (!player || !attacker)
			return;
		PlayerPawn ppawn = player.mo;
		if (!ppawn)
			return;
		if (!c_DamageMarkersAlpha)
			c_DamageMarkersAlpha = Cvar.GetCvar("jgphud_DamageMarkersAlpha", player);
		
		// If the marker for this attacker already exists,
		// update its alpha and add damage:
		for (int i = markers.Size() - 1; i >= 0; i--)
		{
			let dm = JGPUFH_DmgMarker(markers[i]);
			if (dm && dm.attacker == attacker)
			{
				dm.alpha = c_DamageMarkersAlpha.GetFloat();
				dm.damage += damage;
				return;
			}
		}

		// Otherwise make a new marker:
		let dm = JGPUFH_DmgMarker.Create(ppawn, attacker, angle, c_DamageMarkersAlpha.GetFloat(), damage);
		if (dm)
		{
			markers.Push(dm);
		}
	}

	// Update alpha of all markers:
	override void Tick()
	{
		if (!c_DamageMarkersFadeTime)
			c_DamageMarkersFadeTime = CVar.GetCvar('jgphud_DamageMarkersFadeTime', player);
		if (!c_DamageMarkersAlpha)
			c_DamageMarkersAlpha = Cvar.GetCvar("jgphud_DamageMarkersAlpha", player);
		for (int i = markers.Size() - 1; i >= 0; i--)
		{
			let dm = JGPUFH_DmgMarker(markers[i]);
			if (!dm)
				continue;

			dm.Update(c_DamageMarkersAlpha.GetFloat() / (c_DamageMarkersFadeTime.GetFloat() * TICRATE));
			if (dm.alpha <= 0)
			{
				dm.Destroy();
				markers.Delete(i);
			}
		}
	}
}

// This container stores the marker's alpha,
// attacker, angle and the PlayerPawn the
// marker is attached to:
class JGPUFH_DmgMarker play
{
	protected PlayerPawn ppawn;
	Actor attacker;
	double alpha;
	double angle;
	int damage;

	// Attacker is optional. The marker can be just explicitly
	// angled instead of having an attacker, because markers
	// can be used to react to environmental damage:
	static JGPUFH_DmgMarker Create(PlayerPawn ppawn, Actor attacker = null, double angle = 0, double alpha = 1.0, int damage = 0)
	{
		let dm = New("JGPUFH_DmgMarker");
		if (dm)
		{
			dm.attacker = attacker;
			dm.angle = angle;
			dm.ppawn = ppawn;
			dm.alpha = alpha;
			dm.damage = damage;
		}
		return dm;
	}

	void Update(double alphaStep = 0.0)
	{
		alpha -= alphaStep;
		// This is done here mainly for cases when attacked was
		// initially valid but then became null (e.g. it was a
		// projectile that disappeared) before the marker itself
		// faded out. When that happens, we need it to point
		// at the last remembered position
		if (attacker && ppawn)
		{
			angle = Actor.DeltaAngle(ppawn.AngleTo(attacker), ppawn.angle);
		}
	}

	// The argument here is used so that we can pass
	// a subtic-lerped player angle in the HUD rather
	// that reading current player's angle every tic:
	clearscope double GetAngle(double playerangle = 0)
	{
		if (attacker && ppawn)
		{
			return Actor.DeltaAngle(ppawn.AngleTo(attacker), playerangle);
		}
		return angle;
	}
}

class JGPUFH_LookTargetTracer : LineTracer
{
	static clearscope JGPUFH_LookTargetTracer Fire(PlayerPawn pp)
	{
		if (!pp) return null;

		let tracer = new('JGPUFH_LookTargetTracer');
		
		Vector3 dir = (Actor.AngleToVector(pp.angle, cos(pp.pitch)), -sin(pp.pitch));
		Vector3 start = pp.pos + (0, 0, pp.height * 0.5 - pp.floorclip + pp.AttackZOffset*pp.player.crouchFactor);
		tracer.Trace(start, pp.cursector, dir, PLAYERMISSILERANGE,
			0,
			wallmask: Line.ML_BLOCKEVERYTHING,
			ignore: pp);
		return tracer;
	}

	override ETraceStatus TraceCallback()
	{
		if (results.HitType == TRACE_HitActor && results.HitActor)
		{
			let victim = results.HitActor;
			if (victim.bShootable && victim.health > 0)
			{
				return TRACE_Stop;
			}
			return TRACE_Skip;
		}

		switch (results.HitType)
		{
			case TRACE_HitWall:
			case TRACE_HitFloor:
			case TRACE_HitCeiling:
				return TRACE_Stop;
				break;
		}

		return TRACE_Skip;
	}
}

class JGPUFH_StringMan
{
	static clearscope string CleanWhiteSpace(string workstring, bool removeSpaces = false)
	{
		// Strip tabs, carraige returns, "clearlocks",
		// add linebreaks before "{" and "}":
		workstring.Replace("\t", "");
		workstring.Replace("\r", "");
		workstring.Replace("{", "\n{");
		workstring.Replace("}", "\n}");
		// Clean possible bad bytes at the very end of
		// the string, because ReadLump returns an
		// incorrect '0' byte at the end of ReadLump
		// in 4.10:
		int len = workstring.Length();
		if (workstring.ByteAt(len - 1) == 0)
		{
			workstring = workstring.Left(len -1);
		}
		// Unite duplicate linebreaks, if any:
		while (workstring.IndexOf("\n\n") >= 0)
		{
			workstring.Replace("\n\n", "\n");
		}
		// Remove all spaces, if removeSpaces is true:
		if (removeSpaces)
		{
			workstring.Replace(" ", "");
		}
		// Otherwise clean spaces:
		else
		{
			// Unite duplicate spaces, if any:
			while (workstring.IndexOf("  ") >= 0)
			{
				workstring.Replace("  ", " ");
			}
			// Remove spaces next to linebreaks:
			workstring.Replace("\n ", "\n");
			workstring.Replace(" \n", "\n");
		}
		return workstring;
	}

	static clearscope string RemoveComments(string workstring)
	{
		int commentPos = workstring.IndexOf("//");
		while (commentpos >= 0)
		{
			int lineEnd = workstring.IndexOf("\n", commentPos) - 1;
			workstring.Remove(commentPos, lineEnd - commentPos);
			commentPos = workstring.IndexOf("//");
		}
		commentPos = workstring.IndexOf("/*");
		while (commentpos >= 0)
		{
			int lineEnd = workstring.IndexOf("*/", commentPos) - 1;
			workstring.Remove(commentPos, lineEnd - commentPos);
			commentPos = workstring.IndexOf("/*");
		}
		return workstring;
	}
}

class JGPUFH_FontData ui
{
	protected name		d_fontname_def;
	protected Font 		d_font_def;
	protected HUDFont 	d_hudfont_def;
	protected Vector2 	d_scale_def;

	name				d_fontname;
	Font 				d_font;
	HUDFont 			d_hudfont;
	Vector2 			d_scale;

	static JGPUFH_FontData Create(name fontname, Vector2 scale)
	{
		Font fnt = Font.FindFont(fontname);
		if (!fnt)
			return null;

		let fd = New('JGPUFH_FontData');
		fd.d_fontname		= fontname;
		fd.d_font			= fnt;
		fd.d_hudfont 		= HUDFont.Create(fnt);
		fd.d_scale			= scale;

		fd.d_fontname_def	= fd.d_fontname;
		fd.d_font_def		= fd.d_font;
		fd.d_hudfont_def 	= fd.d_hudfont;
		fd.d_scale_def		= fd.d_scale;
		return fd;
	}

	bool IsValid()
	{
		return self && self.d_font && self.d_hudfont && self.d_font_def && self.d_hudfont_def;
	}

	void Reset()
	{
		d_fontname		= d_fontname_def;
		d_font			= d_font_def;
		d_hudfont		= d_hudfont_def;
		d_scale			= d_scale_def;
	}

	bool Update(name newFontName)
	{
		if (newFontName == d_fontname)
		{
			return true;
		}

		Font fnt = Font.FindFont(newFontName);
		if (!fnt)
		{
			Reset();
			return false;
		}
		
		d_font = fnt;
		d_fontname = newFontName;
		d_hudfont = HUDFont.Create(fnt);
		Vector2 size = (d_font_def.GetCharWidth("0"), d_font_def.GetGlyphHeight("0"));
		Vector2 altSize = (fnt.GetCharWidth("0"), fnt.GetGlyphHeight("0"));
		d_scale.x = d_scale_def.x * (size.x / altSize.x);
		d_scale.y = d_scale_def.y * (size.y / altSize.y);
		return true;
	}
}