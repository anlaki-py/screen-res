# ASRM (Android Screen Resolution Manager)

Hey! So, this is ASRM - a little tool I cooked up to handle screen resolution and density stuff on Android, designed to run right in **Termux**.

It took a *ton* of time generating, testing, and debugging this thing, but I think it's finally in a pretty stable state now!

## What It Does (The Short Version)

* **Simple Menu:** Uses `dialog` so you don't have to remember weird commands.
* **Set Custom Res:** Punch in the width/height you want.
* **Presets:** Save settings you use often so you can switch back and forth easily.
* **Reset Button:** A quick way to get back to your phone's default screen settings.
* **Backup/Restore:** Save your current setup before experimenting.

## The "Oh Crap" Safety Net (15s Countdown!)

We've all been there – change the resolution and suddenly the screen is black or unusable. That's why I added this:

* After you change settings, you've got **15 seconds**.
* If the screen looks good, **hit Enter** to keep it.
* If it's messed up or you do nothing, it **automatically switches back** to how it was before.

Trust me, this feature alone saved me a bunch of headaches during testing!

## How to Use in Termux (*ROOT REQUIRED*)

1.  **Get the needed bits:**
```bash
pkg update && pkg install dialog tsu
```
(Android has the main `wm` command built-in)
1.  **Allow it to run:**
```bash
chmod +x asrm.sh
```
1.  **Fire it up:**
```bash
sudo bash asrm.sh
```
1.  Just follow the menus!

## Quick Heads-Up (Disclaimer)

Look, this script fiddles with system display settings. While I've worked hard to make it stable and added the safety countdown, things can still go sideways. Use it at your own risk, okay? I'm not responsible if your screen does something funky. The full "official" disclaimer is in the script file too.

Hope you find it useful!
