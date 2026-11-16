# Rebuilding HueForge_Frame_Maker.html

The page is one file: OpenSCAD 2025.01 (WASM, from npm `openscad-wasm-prebuilt@1.2.0`, Manifold backend),
three.js 0.170 + OrbitControls, the app code, and `HueForge_Floating_Frame_Customizer.scad`, all bundled inline.

```bash
npm i openscad-wasm-prebuilt@1.2.0 three@0.170.0 esbuild@0.24.0
mkdir -p build && cp node_modules/openscad-wasm-prebuilt/dist/openscad.js build/openscad.js
# patch: reuse the compiled WASM module between runs (each Generate needs a fresh OpenSCAD instance)
sed -i 's/const wasmBinary = await wasm();/const wasmBinary = (globalThis.__hfWasmModule = globalThis.__hfWasmModule || await wasm());/' build/openscad.js
mkdir -p app && cp app.js core.js template.html app/ && cp ../HueForge_Floating_Frame_Customizer.scad app/frame.scad
npx esbuild app/app.js --bundle --format=iife --loader:.scad=text --minify --outfile=bundle.js
python3 build.py      # paths inside build.py point at /tmp/wasm on the build box - adjust
```
The page reads the Customizer parameters straight from the .scad, so changing the .scad (and rebuilding) updates the form.
