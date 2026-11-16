# HueForge Floating Frame

**Live app:** https://mikebernasconi.github.io/hueforge-frame-maker/

Design by Michael Bernasconi. It's a floating frame with a flat bottom and an open back, and the HueForge
print is glued in from the front. The stand slides into two dovetails and leans the frame back 10°. It is printed in the
frame's lower bay and snaps off on breakaway tabs.

| File | What it is |
| --- | --- |
| [`index.html`](index.html) | **The web app** served by GitHub Pages. One self-contained file (about 11.5 MB). Enter width and height, click Generate, then download a 3MF or STL. |
| [`HueForge_Frame_Maker.html`](HueForge_Frame_Maker.html) | The same app, for downloading and opening offline. Double-click it; it works with no install and no internet. |
| [`HueForge_Floating_Frame_Customizer.scad`](HueForge_Floating_Frame_Customizer.scad) | The same design as one OpenSCAD file, for the OpenSCAD Customizer and MakerWorld's Parametric Model Maker |
| `src/` | Source for rebuilding the HTML (see `src/BUILD.md`) |

## Using the web app
1. Open the [live app](https://mikebernasconi.github.io/hueforge-frame-maker/), or double-click `HueForge_Frame_Maker.html`. It opens in Chrome, Edge, Firefox or Safari, with no internet needed.
2. Enter your HueForge print's **width and height** in mm (the size you set in HueForge). The other settings are under *Advanced*.
3. Click **Generate**. A 3D preview appears in about a second.
4. Click **Download 3MF** (best for Bambu Studio) or **Download STL**.

If the stand doesn't fit in the bay (frames smaller than about 100 x 150 mm), the app says so and puts the stand **beside** the frame.

## Print settings
* Print exactly as exported: the frame back face down and the stand lying flat. **No supports. No brim.** A brim would weld
  the stand into its bay.
* PLA, 0.16 or 0.20 mm layers, 3 walls, 5 top and 4 bottom layers, 15% gyroid. Use a clean PEI plate.
* For 133.33 x 200 mm, it uses about 64.5 g and takes about 1 h 53 min (PrusaSlicer estimate; Bambu Studio will differ a bit).
* After printing, snap the stand out of the bay (twist it at the tabs) and clean any whisker with a flush cutter.
  Slide it into the two dovetails on the back of the spine, from the right when you look at the back.
  If it's too tight, regenerate with *stand clearance* 0.12-0.15 and reprint just the stand ("Stand only").
* Glue the print onto the ledge with small dots of E6000 or gel CA. Hang it on the keyhole with a #6-#8 pan-head screw.

## Hosting the web app on GitHub Pages
1. Create a public repo on github.com, for example `hueforge-frame-maker`.
2. Upload `HueForge_Frame_Maker.html`, renamed to **`index.html`**. Uploading the licence files and the `.scad` is good practice.
3. Go to **Settings → Pages → Build and deployment → Deploy from a branch → `main` / root → Save**.
4. After a minute the app is live at `https://<user>.github.io/hueforge-frame-maker/`. Any static host works the same way
   (Netlify drop, Cloudflare Pages), because the file loads nothing from the internet.

This repository is already laid out that way: `index.html` at the root, plus an empty `.nojekyll` so Pages serves the file as-is.

## Posting to MakerWorld as a parametric model
1. On makerworld.com go to **Upload → Model**. In the editor, choose to create a **Parametric model** (OpenSCAD / Parametric
   Model Maker), then upload `HueForge_Floating_Frame_Customizer.scad`.
2. Check that the parameter tabs show up: *Your HueForge print*, *Advanced - frame*, *Advanced - stand* and
   *Advanced - stand in bay / tabs*. Generate the default 133.33 x 200 to test it.
3. Add photos and the print settings above, and credit: *"Design by Michael Bernasconi."* Publish.

The file follows the Parametric Model Maker's known rules:
* It is one file with no `include` or `use` lines, no `import()`, and no fonts or text.
* Controls use standard Customizer syntax: `/* [Tab] */` groups, `// [min:step:max]` sliders, `// [value:Label]`
  dropdowns, checkboxes, and a `[Hidden]` tab for internal values.
* There are no `color()` calls in the output, so the maker won't treat it as multi-colour.
* It renders in about 3 s with CGAL and under 0.3 s with Manifold.

Known MakerWorld limit: very large models can fail when the maker auto-arranges the plate (people report a ceiling of about
240 x 235 mm). Very large frames may then need the web app or desktop OpenSCAD instead.

## Credits and licences
Design by Michael Bernasconi. The web app bundles **OpenSCAD** (GPL-2.0, https://openscad.org; WASM build
https://github.com/lorenzowritescode/openscad-wasm) and **three.js** (MIT); their licence texts are included
(`LICENSE-OpenSCAD-GPL2.txt` and `LICENSE-three.js-MIT.txt`).
