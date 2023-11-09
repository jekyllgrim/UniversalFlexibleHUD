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


class JGPUFH_LockData ui
{
	int lockNumber;
	color lockColor;
	int gametype;

	static JGPUFH_LockData Create(int lockNumber, color lockColor, int gametype)
	{
		let lcd = New("JGPUFH_LockData");
		if (lcd)
		{
			lcd.lockNumber = lockNumber;
			lcd.lockColor = lockColor;
			lcd.gametype = gametype;
		}
		return lcd;
	}

	// Iterates over the LOCKDEFS lump and obtains
	// mapcolor strings to record the color for
	// each lock:
	static void GetLockData(out array<JGPUFH_LockData> lockdata)
	{
		int cl = Wads.FindLump("LOCKDEFS");
		string lockStr = "lock ";
		int lockStrLength = lockStr.Length();
		string mcStr = "mapcolor ";
		int mcStrLength = mcStr.Length();
		while (cl != -1)
		{
			// Get the contents of the lump and make
			// them lowercase for easier iteration:
			string lumpData = Wads.ReadLump(cl);
			lumpData = lumpData.MakeLower();
			// strip comments:
			int commentPos = lumpData.IndexOf("//");
			while (commentpos >= 0)
			{
				int lineEnd = lumpData.IndexOf("\n", commentPos) - 1;
				lumpData.Remove(commentPos, lineEnd - commentPos);
				commentPos = lumpData.IndexOf("//");
			}
			commentPos = lumpData.IndexOf("/*");
			while (commentpos >= 0)
			{
				int lineEnd = lumpData.IndexOf("*/", commentPos) - 1;
				lumpData.Remove(commentPos, lineEnd - commentPos);
				commentPos = lumpData.IndexOf("/*");
			}
			// Strip tabs, carraige returns, "clearlocks",
			// add linebreaks before "{" and "}":
			lumpData.Replace("\t", "");
			lumpData.Replace("\r", "");
			lumpData.Replace("clearlocks", "");
			lumpData.Replace("{", "\n{");
			lumpData.Replace("}", "\n}");
			// Unite duplicate linebreaks, if any:
			while (lumpData.IndexOf("\n\n") >= 0)
			{
				lumpData.Replace("\n\n", "\n");
			}
			// Unite duplicate spaces, if any:
			while (lumpData.IndexOf("  ") >= 0)
			{
				lumpData.Replace("  ", " ");
			}
			// Remove spaces next to linebreaks:
			lumpData.Replace("\n ", "\n");
			lumpData.Replace(" \n", "\n");
			//Console.Printf("lumpdata: %s", lumpdata);
			// Record the end of the file:
			int fileEndPos = lumpdata.Length() - 1;

			// Find the first mention of "lock ":
			int searchPos = lumpData.IndexOf(lockStr);
			while (searchPos >= 0 && searchPos < fileEndPos)
			{
				if (jgphud_debug)
					Console.PrintF("\cFLOCKDEFS\c- Found '%s' at %d", lumpData.Mid(searchPos, lockStrLength), searchPos);

				// Move search position forward by the length of the "lock " string:
				searchPos += lockStrLength;
				// The end of first line is the first "{"
				// Don't forget to deduct 1 from the end of the line to avoid
				// capturing "{" itself:
				int lineEnd = lumpData.IndexOf("{", searchPos) - 1;
				// Find the first space and the first end of the line after it:
				int spacePos = lumpData.IndexOf(" ", searchPos);
				if (spacePos < searchPos)
					spacePos = lineEnd;
				// Lock definitions come in two formats:
				// "Lock 1 Gamename" = "lock ", number, space, "Gamename", linebreak
				// "Lock 1" - "lock ", number, linebreak
				// If there's a space before the linebreak, then there IS
				// a gametype definition, so we'll record that:
				string lockgame;
				int gametype = GAME_Any;
				if (spacePos < lineEnd)
				{
					lockgame = lumpData.Mid(spacePos + 1, lineEnd - spacePos - 1);
					// Convert into actual gametype:
					name lg = lockgame;
					switch (lg)
					{
						default:
							gametype = GAME_Any;
							break;
						case 'doom':
							gametype = GAME_Doom;
							break;
						case 'heretic':
							gametype = GAME_Heretic;
							break;
						case 'hexen':
							gametype = GAME_Hexen;
							break;
						case 'strife':
							gametype = GAME_Strife;
							break;
						case 'chex':
							gametype = GAME_Chex;
							break;
					}
				}
				// Now to find the number. It'll be after "lock " and before
				// either a space OR the end of the line, whichever is closer:
				spacePos = min(spacePos, lineEnd);
				// This is our lock number:
				string lockNum = lumpData.Mid(searchPos, spacePos - searchPos);
				
				if (jgphud_debug)
					Console.Printf("\cFLOCKDEFS\c- Found lock number [%s] Game: [%s]", lockNum, lockgame);

				// Move search position to the space/linebreak:
				searchPos = spacePos;
				// Get the position of the next "lock " or,if there
				// isn't one, the end of the file. We need this to
				// make sure that the other stuff we find in this
				// block is actually relevant for the current lock:
				int blockEnd = lumpdata.IndexOf(lockStr, searchPos);
				if (blockEnd < 0)
				{
					blockEnd = fileEndPos;
				}

				// Find the mention of "mapcolor ":
				int colorPos = lumpData.IndexOf(mcStr, searchPos);

				// Mapcolor is optional. So, we'll only continue from here
				// if the "mapcolor " string is mentioned after "lock " BEFORE
				// the next instance of "lock " - this means it's actually
				// related to the current lock:
				
				if (jgphud_debug)
					Console.Printf("\cFLOCKDEFS\c- Looking for mapcolor. Searchpos %d, colorpos %d, blockEnd %d", searchpos, colorPos, blockEnd);
				if (colorPos > searchPos && colorPos < blockEnd)
				{
					// Move to the position after "mapcolor ":
					int pos = colorPos + mcStrLength;
					// Find the end of the line (either a linebreak, 
					// or "}", whiever is closer):
					lineEnd = min(lumpData.IndexOf("}", pos), lumpData.IndexOf("\n", pos));
					// Proceed if pos and lineEnd are valid:
					if (pos >= searchPos && lineEnd >= searchPos && pos < lineEnd)
					{
						int R, G, B;
						// Get all 3 colors:
						for (int i = 0; i < 3 && pos < lineEnd; i++)
						{
							// Find the first space (or end of line):
							spacePos = min(lumpData.IndexOf(" ", pos), lineEnd);
							// Get the text between that space and
							// the search position:
							string s = lumpData.Mid(pos, spacepos - pos);
							// Convert to int and record:
							int cn = s.ToInt();
							switch (i)
							{
								case 0: R = cn; break;
								case 1: G = cn; break;
								case 2: B = cn; break;
							}
							// Move the search position up:
							pos = spacePos+1;
						}

						// Finally, we can record the number, color and gametype
						// of the lock into the specialized array:
						let ld = JGPUFH_LockData.Create(locknum.ToInt(), color(r,g,b), gametype);
						lockdata.Push(ld);

						if (jgphud_debug)
							Console.Printf("\cFLOCKDEFS\c- \cDCached lock. No: [%d], color: (%d,%d,%d), gametype: %d (%s)", ld.lockNumber, ld.lockColor.r, ld.lockColor.g, ld.lockColor.b, ld.gametype, lockgame);
					}
				}
				searchPos = blockEnd;
				searchPos = lumpData.IndexOf(lockStr, searchPos);
			}
			cl = Wads.FindLump("LOCKDEFS", cl+1);
		}
	}
}