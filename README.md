# Autosplitter for Payday 2

A Livesplit autosplitter for Payday 2.
It can automatically start the timer when a heist begins and split after a heist is completed.
Additionally the in-game heist timer is reported as "Game Time" to Livesplit.
A few configurations can be changed via the in-game mod options menu.

The mod supports 3 different game time modes:
1. *In-Game Heist Time*
  * Uses Payday's own clock, which is shown at the top of the screen or in the crew stats tab after a heist
  * Slowmotion slows the timer
  * Restarts, Fails, Terminating are supported
2. *Real Time Heist Only*
  * Unpauses the timer when the heist begins, and pauses it when the heist ends
  * Slowmotion has no effect on the timer
  * Restarts, Terminating, Pausing in single player are supported
3. *Load Removed Time*
  * Pauses the timer during loading screens
  * Timer continues running after a heist and during menus
  * Waiting for other players in multiplayer is currently ignored


## Installation

This is a Payday 2 mod

1. Download and install [SuperBLT](https://superblt.znix.xyz/)
2. Download the [Latest Release](https://github.com/dyrax/payday2-autosplitter/releases/latest/download/AutoSplitter.zip) of the mod
3. Extract the main folder to `mods/` in your Payday 2 installation directory

## Usage

Simply start the game and Livesplit. The mod connects automatically to Livesplit.
Configuration is done via the in-game mod options menu. The default settings are fine for 5-maps.
