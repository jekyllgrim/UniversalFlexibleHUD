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
	static void CreatePowerupIcon(PowerupGiver pwrg, out array <JGPUFH_PowerupData> powerupData)
	{
		// Get PowerupGiver's powerupType field:
		let pwr = GetDefaultByType((class<Inventory>)(pwrg.powerupType));
		if (!pwr)
			return;

		if (jgphud_debug)
			Console.Printf("\cHPOWERUPDATA\c- Trying to find icon for %s", pwr.GetClassName());
		// Check if that powerup was already processed:
		JGPUFH_PowerupData pwd;
		let pwrCls = pwr.GetClass();
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
		if (icon.isValid() && TexMan.GetName(icon) != 'TNT1A0')
		{
			if (jgphud_debug)
				Console.Printf("\cHPOWERUPDATA\c- Powerup %s already has icon: %s", pwr.GetClassName(), TexMan.GetName(icon));
			pwd = JGPUFH_PowerupData.Create(icon, pwrCls, pwrg.GetRenderstyle());
			powerupData.Push(pwd);
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
		if (!player)
			return;
		PlayerPawn ppawn = player.mo;
		if (!ppawn)
			return;
		
		// If the marker for this attacker already exists,
		// update its alpha and add damage:
		if (attacker)
		{
			if (!c_DamageMarkersAlpha)
				c_DamageMarkersAlpha = Cvar.GetCvar("jgphud_DamageMarkersAlpha", player);
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

	clearscope double GetAngle()
	{
		if (attacker && ppawn)
		{
			return Actor.DeltaAngle(ppawn.AngleTo(attacker), ppawn.angle);
		}
		return angle;
	}
}

// Since LineTrace (for some reason) is only play-scoped,
// a separate play-scoped thinker is needed per each
// player so that they could call LineTrace and detect
// if the player is looking at any enemy:
class JGPUFH_LookTargetController : Thinker
{
	protected PlayerPawn pp;
	Actor looktarget;
	int targetTimer;
	const TARGETDISPLAYTIME = TICRATE;

	static JGPUFH_LookTargetController Create(PlayerPawn pp)
	{
		let ltc = New("JGPUFH_LookTargetController");
		if (ltc)
		{
			ltc.pp = pp;
		}
		return ltc;
	}

	override void Tick()
	{
		if (!pp)
		{
			Destroy();
			return;
		}
		if (!pp.player || pp.health <= 0)
			return;
		
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