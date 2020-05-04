My desktop is connected to two monitors and one TV, and for various reasons I find myself needing to switch my primary display more often than most people.

![My battlestation](/molten-matter/announcing-satouindp/battlestation.jpg)

This is my monitor setup. There's also a TV behind me, which I use to watch movies and play videogames. My laptop is also connected to the central monitor.

When I'm working on my laptop I usually have my central monitor rotated by 90° (code looks better on a tall screen) and a music player open on the right monitor, so either I bend my neck 90° every time I need to do something on the central monitor, or I switch the primary display to the right. If I want to play videogames on the TV I need to switch the primary display to the TV, because most games don't have an option to change the display they go full screen on.

To change primary displays on Windows you have to go on a certain control panel section whose name I can never reliably recall when I'm searching for it from the start menu. (Doesn't help that they change the names of the control panel sections every other update.) Then you have to click on the display you want to make primary, scroll down, and click on a checkbox. That's usually enough to put me off playing any videogames on the TV.

I needed something to do this more quickly.

There's probably a bunch of tools that already do this, but I don't think any of them are open source. If this was Linux I could easily write a script with xrandr, but this is Windows. Stuff here goes clickety click instead of clickety clack, and opening a terminal breaks the harmony.

The other day I finally decided to scratch this itch. A couple hours later I emerged with [SatouinDp](https://github.com/steinuil/SatouinDp).

![SatouinDp in action](/molten-matter/announcing-satouindp/satouin.jpg)

It's simply a taskbar icon that shows the list of displays, and when you click on one it sets that one as the primary display. It's written in F# and it calls directly to the Win32 API to change the display settings. Maybe I'll write a post about how to do that too some other day.

It's been very useful so far.

# Further reading

* [Situated software](https://web.archive.org/web/20040411202042/http://www.shirky.com/writings/situated_software.html)
* [Use Windows API from C# to set primary monitor](https://stackoverflow.com/questions/195267/use-windows-api-from-c-sharp-to-set-primary-monitor)