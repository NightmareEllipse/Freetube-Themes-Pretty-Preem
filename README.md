# FreeTube Themes: Pretty Preem


![Preema Ballerina (Violent Violet) theme preview](Screenshots%20of%20the%20Themes/Preema%20Ballerina%20%28Violent%20Violet%29/b.png)



A collection of preem themes for the FreeTube Desktop. The theme CSS works on Linux (“Penguin”) and macOS.
Frankly, it’s a tremendous collection—many, many themes, and they look fantastic. Some of the best FreeTube themes you’ve ever seen.
Grab your favorite and make your FreeTube great again!

Apply and removal scripts are provided for Linux installations using the Debian package (`.deb`) or Flatpak. The scripts do not currently support other package formats or operating systems.
The included main wallpapers (`a.png` or `a.jpg`) are designed for widescreen displays. Resize them to suit your screen, or use your own wallpapers. The themes are dynamic.


## Why this exists

As I understand it, FreeTube has declined some theming-related merge requests in the past, 
because the maintainers considered them a trade-off between readability and visual style.
I still wondered why FreeTube did not offer built-in support for background images, 
so this project provides an unofficial way to experiment with custom themes and backgrounds.

## How it was made

It was made with the help of the free-tier version of Luna 5.4. via Duck.ai (an anonymous proxy for ClosedAI).
If I had a 20$ subscription or a proper local model, I could have simply vibecoded it and debugged it within an hour or two. 
But due to limited context window, I was not able to feed it the source code and have it produce a fully fledged theme.
Instead, I used it as a tool, while doing my own debugging, inspecting elements with the developer tools, and applying patches and bug fixes.
In between, I also switched between Luna instances, often with Luna writing a handover for the next instance (limited context window). (Well, Luna 6.0. DuckAI implemented now a button for that)
The code was relatively smooth (I guess) until I wanted to add rounded corners. 
More than 50% of the changes are actually bug fixes that became necessary after adding rounded corners.
The Bash scripts were also made by Luna. I did a lot of debugging and worked together with Luna to get everything working.
I do not code, and I am no Elliot. 
But I do like to tinker a lot with my machines.
I think the CSS code is not pretty, but it is not messy either. Most importantly, it works and it comes with fairly good documentation.



## Screenshots
![Nier Automata Pretty Preem Edition (Ice Blue) preview](Screenshots%20of%20the%20Themes/Preem%20Ice%20Blue%20Themes%20%28Nier%20Automata%20%26%20Underworld%29/Nier%20Automata%20Pretty%20Preem%20Edition%20%28Ice%20Blue%29/b.png)

Screenshots of the themes are in the `Screenshots of the Themes/` directory. The collection is approximately 184 MB in total.



## Installation

These scripts are for Linux. The theme CSS may also work on macOS, but these scripts do not install themes on macOS.

### Requirements

- FreeTube installed as a Debian package, with `app.asar` at `/opt/FreeTube/resources/app.asar`, or installed as Flatpak.
- Python 3 and the `asar` command available in `PATH` for scripts that repack FreeTube's app archive.
- The apply script matching your installation type.
- `sudo` access for Debian and system-wide Flatpak installations. User-wide Flatpak scripts do not require `sudo`.

### Prepare the theme

1. Download and extract this repository.
2. Create `~/.scripts` if needed, then move or rename the extracted repository folder to `~/.scripts/Freetube Themes`.
3. Empty `000 Active`.
4. Copy the **contents** of one theme folder into `000 Active`; don’t copy the theme folder itself.
5. Ensure exactly one `.css` file is directly inside `000 Active`.
6. Keep the theme’s `imgs/` folder directly inside `000 Active`, with the image files referenced by the CSS.

### Apply or remove a theme

Close FreeTube, then run the apply script for your installation: Debian package or Flatpak user installation. 
Use the corresponding removal script to restore the original files. Follow the script’s instructions about sudo.

#System-wide Flatpak: No script is provided; you’ll need to adapt one yourself.


#### Debian package

Open a terminal in the directory containing the Debian scripts, then run:

sudo ./apply-freetube-deb-theme.sh

To restore the original FreeTube files:
sudo ./remove-freetube-deb-theme.sh

To switch themes, copy the new theme’s contents into 000 Active and run the apply script again. You don’t need to run the removal script when switching themes. My themes are designed to work when applied this way, so they won’t appear as a mashup.
To restore the original FreeTube files, run:

sudo ./remove-freetube-deb-theme.sh

#### Flatpak (user installation)

Open a terminal in the directory containing the Flatpak (User) scripts, then run:
./apply-freetube-flatpak-user-theme.sh

To switch themes, copy the new theme’s contents into 000 Active and run the apply script again. You don’t need to run the removal script when switching themes. My themes are designed to work when applied this way, so they won’t appear as a mashup.
To restore the original FreeTube files, run:
./remove-freetube-flatpak-user-theme.sh

![Matrix & Malfoid theme — screenshot A](Screenshots%20of%20the%20Themes/Preem%20Green%20Matrix%20%26%20Malfoid%20Theme/Matrix/a.png)
![Matrix & Malfoid theme — screenshot B](Screenshots%20of%20the%20Themes/Preem%20Green%20Matrix%20%26%20Malfoid%20Theme/Matrix/b.png)
![Matrix & Malfoid theme — screenshot D](Screenshots%20of%20the%20Themes/Preem%20Green%20Matrix%20%26%20Malfoid%20Theme/Matrix/d.png)
![Matrix & Malfoid theme — screenshot E](Screenshots%20of%20the%20Themes/Preem%20Green%20Matrix%20%26%20Malfoid%20Theme/Matrix/e.png)

### Bonus
For a little surprise, select “Dracula” in FreeTube’s settings.

Too complicated? Ask [Duck.ai](https://duck.ai/)
or any other large machine life-form.


## Updates

Of course, you have to run the appropriate `apply` script again after an official FreeTube update if you want to continue using the custom theme.
The scripts are unofficial and may need changes if FreeTube changes its internal files or layout.
The theme is strongly tied to a particular FreeTube HTML structure and its class names.
It may break if FreeTube changes its DOM structure or class names.
The entire section below is particularly vulnerable:

/* ==========================================================================
   FreeTube Rounded Interface Theme
   ========================================================================== */

If too many bugs appear and you can’t be bothered to bug-fix them yourself,
or you don’t have access to good LLMs, delete only the" FreeTube Rounded Interface Theme"  portion 
(all the way down to near the bottom)
but keep the


/* ==========================================================================
   Custom "Whatever" Theme Colors
   ========================================================================== */
   section alive.

If you want to manually bug-fix things, Section 5 is interesting.
Or you DO just clean up the code and make it bug free with a proper model and proper context window.
Coding is solved.




u may or may not wanna keep the "@media not all" section.


### How likely is FreeTube's layout to change?

I have been using FreeTube for a long time and have not noticed major changes to its overall user interface. 
Because of that, I do not expect the entire layout to suddenly be replaced.

Well, it actually depends on their usage of AI, and I think open-source projects will be exploding, 
emerging, and flourishing everywhere, while closed-source projects will become a rarity.
However, smaller changes to the HTML or DOM structure can still happen anyway during normal development.
FreeTube may add or remove wrapper elements, rename classes, change the order of elements, introduce new components, 
or adjust individual pages without performing a complete redesign.
This theme is therefore more likely to need occasional small fixes than to stop working completely overnight.
The more resilient selectors in this stylesheet target recognizable class names, such as:

CSS
#app .videoThumbnail
#app .iconDropdown
#app .profileDropdown
#app .watchVideoPlaylist

The more vulnerable selectors are the very long selectors that depend on an exact parent-child structure, for example:


css
#app > div > div.ft-flex-box.flexBox.routerView
  > div > div.ft-card.card
  > div > div:nth-child(3)

(I know xD)

If FreeTube adds, removes, or rearranges one of those intermediate elements, that particular rule may stop matching even though the rest of the theme continues to work.


The theme should work on different toasters and across different screen sizes.
It will probably remain usable through ordinary FreeTube updates.
Some individual rules may need adjustment after future updates.
A major redesign could require more extensive changes.
The theme should be considered tied to the FreeTube version and DOM structure against which it was tested.
I used it with GNU/Linux.
Electricity is optional.

![Makima Supreme — screenshot A](Screenshots%20of%20the%20Themes/Makima%20Supreme/a.png)
![Makima Supreme — screenshot D](Screenshots%20of%20the%20Themes/Makima%20Supreme/d.png)
![Makima Supreme — screenshot E](Screenshots%20of%20the%20Themes/Makima%20Supreme/e.png)
![Makima Supreme — screenshot F](Screenshots%20of%20the%20Themes/Makima%20Supreme/f.png)



## License 

This project is licensed under the GNU General Public License, version 3 or, at your option, any later version.







## Customization

This project is intended for the **FreeTube Desktop Theme**. The CSS file includes several sections that can be adjusted to suit your preferences.

### Theme colors

At the very bottom of the CSS file, you will find the following section:


/* ==========================================================================
   Custom "Whatever" Theme Colors
   ========================================================================== */

This is the main section for changing the theme’s color values. You can adjust the colors manually or copy this section into an LLM of your choice, together with a reference image, and ask it to create a matching color palette.


### Thumbnail grid size
Just above the Custom "Whatever" Theme Colors section is an "@media not all" block that controls an alternative thumbnail grid layout.

To enable it, change:
@media not all
to
@media all

This will enable a larger thumbnail grid, making individual thumbnails bigger.
Keep in mind that the available space is distributed across the thumbnails currently shown. 
If you only have a few videos or playlists visible, they may occupy most or all of the grid. 
For example, one playlist thumbnail may fill the entire grid, while two thumbnails will share the available space.
FreeTube already includes a native UI scaling option under Settings. 
However, that setting scales the entire interface, including the settings pages, top bar, and sidebar. 
If you only want to adjust the thumbnail grid, you can enable this CSS-based alternative instead.

The value most likely to require adjustment is: 340px

Experiment with this value until the grid matches your preferred size. 
Personally, I use FreeTube’s built-in UI scaler at 100% or 110%, but the CSS option provides more targeted control.


![Vaporwave II — screenshot A](Screenshots%20of%20the%20Themes/Vaporwave%20Themes/Vaporwave%20II/a.png)
![Vaporwave II — screenshot C](Screenshots%20of%20the%20Themes/Vaporwave%20Themes/Vaporwave%20II/c.png)
![Vaporwave II — screenshot E](Screenshots%20of%20the%20Themes/Vaporwave%20Themes/Vaporwave%20II/e.png)


### Background and glossy styling
The section between approximately line 35:


/* ==========================================================================
   Local PNG background and glossy style
   ========================================================================== */
and approximately line 113:



/* ==========================================================================
   FreeTube Rounded Interface Theme
   ========================================================================== */


This area controls the local background image and the glossy, glass-like appearance of the main content panels.

You can experiment with:

- The local background image
- Background scaling, positioning, and repetition
- The background fallback color
- Panel transparency through the `rgba()` values
- Glossy gradients, borders, and shadows
- The strength of the backdrop blur
- The visual contrast between the background image and the main content panels



### Rounded interface section
The FreeTube Rounded Interface Theme section contains some redundant rules. 
Not every apparently redundant rule should be removed though. 
Some of them were added to address layout or rendering issues that appeared while developing the rounded interface.
Cleaning up this section may be possible, but do it like a surgeon uh-huh, uh-huh.
Removing rules without testing can reintroduce bugs that were previously fixed.
There may be cleaner ways to enforce some of these styles, 
especially with a detailed understanding of FreeTube’s source code and layout. 
A future revision could potentially replace this section with a more concise CSS appendix, or even a completely new stylesheet built from the ground up.
For now, the CSS is intentionally practical rather than perfect. It may not be the most elegant implementation, but it is documented, adjustable, and works well for its intended purpose.
And we are here for the eye candy, innit? :-)
