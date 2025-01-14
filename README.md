# FlexiHUD for GZDoom

**FlexiHUD** is a universal, highly flexible HUD mod for GZDoom, written entirely in ZScript. Not only can you see all the usual information and a lot more, but you can also MOVE every single element!

## Features

### General

* FlexiHUD is drawn on top of your current HUD, with the help of an EventHandler class. Normally, you would hide your default HUD (by pressing = twice or typing `screenblocks 12` in the console), but you can also combine FlexiHUD with the default HUD, by choosing which parts of FlexiHUD are shown. FlexiHUD itself can be toggled at a press of a custom bind.
* Comes with a preset system that lets you save your current FlexiHUD arrangement.
* Not a single graphical element — everything is done through code (aside from a couple of virtual textures in TEXTURES).
* Every single element can be toggled on/off, attached to any screen angle or edge, and offset from there.
* Many elements have several display modes (such as disabled/autohide after delay/always show)
* You can select your own color and opacity for background of the elements
* Heretic, Hexen and Strife support: full inventory bar with fluid animation. Hexen armor is fully accounted for and displays all possessed armor elements.
* Can display powerup icons even for powerups that don't have them (like Doom powerups).
* Currently supports 6 languages: English, German, French, Brazilian Portugese, Spanish LatAm and Russian. All text is in LANGUAGE.csv, more localizations are welcome.
* Heavily commented code—I hope you can learn from it!
* MIT licence (can be used by anyone for any purpose, just copy the license file into your project)

### HUD elements

* **Health, armor and mugshot**
  
  * Health/armor can be represented with numbers or bars
  
  * Mugshot can be toggled

* **Current weapon and ammo**
  
  * Shows the current ammo amount and icon(s)
  
  * Weapon icon and ammo bar that can be toggled

* **All Ammo**
  
  * Shows a list of all ammo possessed by the player
  
  * Can show all ammo or only the ammo that you have weapons for
  
  * Color-coded to represent the amount left. Ammo for current weapon is highlighted

* **Weapon slots**
  
  * Shows a list of current weapons and their slots
  
  * Slots have small Quake 2-styled bars representing the amount of ammo for that weapon
  
  * Can be arranged horizontally or vertically (with bottom>top/top>bottom options)
  
  * Adjustable icon size
  
  * Supports always show/auto-hide display

* **Minimap and map data**
  
  * A minimap of the level (supports adjustable zoom and size, can be square or circular)
  
  * Can also display monster markers (which can be enabled combined with the minimap or separately from it)
  
  * Customizable minimap colors, size and shape (square or circular)
  
  * Optional Map Data block that can show kills, secrets, items and level time (all toggleablle)
  
  * Also supports map markers, such as the ones used by [Hellscape Navigator](https://github.com/mmaulwurff/hellscape-navigator/tree/master)

* **Powerup timers**
  
  * Shows icons and remaining time for current powerups (in a horizontal or vertical arrangement)
  
  * Obtains icons even for those powerups that don't have them (provided the powerup in question is associated with a PowerupGiver class)

* **Reticle bars**
  
  * Half-Life-styled round bars around the crosshair that represent health, armor, current ammo and the health of the monster you're looking at
  
  * Each bar can be individually toggled and moved to one of the four positions around the crosshair
  
  * Adjustable size and width of the bars
  
  * Supports always show/auto-hide display

* **Incoming damage markers**
  
  * Doom Eternal-styled round damage markers that point at the enemy that has damaged you
  
  * Adjustable maximum opacity and fade-out time
  
  * As a separate option, you can adjust the multiplier for the vanilla damage screen reddeing factor. For example, you can set it to 0.0 in case you want to rely solely on the damage markers as indicators of incoming damage.

* **Hit markers**
  
  * Hit marker around your crosshair that flashes when you hit an enemy
  
  * Several hit marker shapes to choose from
  
  * Adjustable size and color. Size can either match the crosshair or be set explicitly
  
  * The marker will grow larger if your attack killed the enemy

* **Inventory bar**
  
  * Animated, smoothly scrolling inventory bar (shows up in the games/mods that actually have items that can be put in the inventory, like Heretic)
  
  * Supports always visible mode (in the style of Alternative HUD) or auto-hide (only the selected item is visible)

* **Custom items**
  
  * A special block that will display items added to the ITEMINFO lump in the mod (see the contents of ITEMINFO for an example and explanation). Can be utilized to display ammo or items that, for some reason, cannot be captured by other HUD blocks (or just in case you want to display a specific item class separately).

## Credits

Agent_Ash aka Jekyll Grim Payne - idea, code, Russian localization

RicardoLuis - the preset system

generic name guy - Brazilian Portugese localization

devloek - German localization

Nikki - Spanish LatAm localization

Ac!d (acid_citric) - French localization
