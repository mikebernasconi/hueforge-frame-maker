import { chromium } from "playwright-core";
import fs from "fs";
const url = "file:///workspace/hueforge/frame/share/HueForge_Frame_Maker.html";
const browser = await chromium.launch({ executablePath: "/usr/bin/google-chrome", args: ["--use-gl=swiftshader", "--enable-unsafe-swiftshader"] });
const ctx = await browser.newContext({ acceptDownloads: true, viewport: { width: 1400, height: 900 }, offline: true });
const page = await ctx.newPage();
const errs = []; page.on("pageerror", e => errs.push(String(e))); page.on("console", m => { if (m.type() === "error") errs.push(m.text()); });
const requests = []; page.on("request", r => { if (!r.url().startsWith("file:") && !r.url().startsWith("blob:") && !r.url().startsWith("data:")) requests.push(r.url()); });
const t0 = Date.now();
await page.goto(url);
await page.waitForFunction(() => window.__lastResult, null, { timeout: 120000 });
console.log("first generate after load:", Date.now() - t0, "ms", JSON.stringify(await page.evaluate(() => window.__lastResult)));
console.log("status:", await page.textContent("#status"));
await page.screenshot({ path: "/workspace/hueforge/frame/share/screenshot_133x200.png" });
const dl = async (sel, path) => { const [d] = await Promise.all([page.waitForEvent("download"), page.click(sel)]); await d.saveAs(path); return d.suggestedFilename(); };
console.log("downloaded", await dl("#dl_stl", "/tmp/cz/web_133.33x200.stl"), await dl("#dl_3mf", "/tmp/cz/web_133.33x200.3mf"));
for (const [w, h] of [[100, 150], [72, 72], [200, 250]]) {
  await page.fill("#p_panel_w", String(w)); await page.fill("#p_panel_h", String(h));
  await page.evaluate(() => window.__lastResult = null);
  const t1 = Date.now(); await page.click("#gen");
  await page.waitForFunction(() => window.__lastResult, null, { timeout: 60000 });
  console.log(w, h, Date.now() - t1, "ms", JSON.stringify(await page.evaluate(() => window.__lastResult)));
  await dl("#dl_stl", `/tmp/cz/web_${w}x${h}.stl`);
  if (w === 72) await page.screenshot({ path: "/workspace/hueforge/frame/share/screenshot_72x72_fallback.png" });
}
// stand only + back view
await page.fill("#p_panel_w", "133.33"); await page.fill("#p_panel_h", "200");
await page.selectOption("#p_part", "stand_only"); await page.evaluate(() => window.__lastResult = null); await page.click("#gen");
await page.waitForFunction(() => window.__lastResult); console.log("stand_only", JSON.stringify(await page.evaluate(() => window.__lastResult)));
await dl("#dl_stl", "/tmp/cz/web_stand.stl");
await page.selectOption("#p_part", "frame_with_stand"); await page.check("#viewback"); await page.evaluate(() => window.__lastResult = null); await page.click("#gen");
await page.waitForFunction(() => window.__lastResult); await page.waitForTimeout(500);
await page.screenshot({ path: "/workspace/hueforge/frame/share/screenshot_back_view.png" });
console.log("external requests:", requests.length, requests.slice(0, 3)); console.log("page errors:", errs);
await browser.close();
