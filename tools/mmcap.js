// Renders Memory Match's card pictures from the prototype: the six animals and the card back.
// Usage: NODE_PATH=$(npm root -g) node tools/mmcap.js <output folder>
const { chromium } = require('playwright');
const out = process.argv[2];
const ANIMALS = ['dove', 'lion', 'giraffe', 'elephant', 'zebra', 'monkey'];
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 1 });
  const p = await ctx.newPage();
  await p.goto('file://' + require('path').resolve(__dirname, '../docs/prototype/story-games.html'));
  await p.waitForTimeout(1500);
  const sprites = await p.evaluate(() => [...document.querySelectorAll('svg')].filter(s => s.querySelector('symbol,linearGradient,radialGradient,pattern,clipPath')).map(s => s.outerHTML).join(''));
  const q = await ctx.newPage();
  const shot = async (name, inner, bg) => {
    await q.setContent(`<html style="background:transparent"><body style="margin:0;background:transparent"><div style="position:absolute;width:0;height:0;overflow:hidden">${sprites}</div><div id="box" style="width:512px;height:512px;display:flex;align-items:center;justify-content:center;${bg || ''}">${inner}</div></body></html>`);
    await q.waitForTimeout(200);
    await q.locator('#box').screenshot({ path: `${out}/${name}.png`, omitBackground: true });
  };
  for (const a of ANIMALS) await shot(`animal_${a}`, `<svg width="512" height="512"><use href="#icon-${a}" width="512" height="512"></use></svg>`);
  await shot('card_back', `<svg width="430" height="430" style="opacity:0.9"><use href="#icon-ark" width="430" height="430"></use></svg>`,
    'border-radius:52px;background:repeating-linear-gradient(90deg,#6B4A2E 0 56px,#4A3220 56px 64px);box-shadow:inset 0 0 0 8px rgba(255,255,255,0.15)');
  await b.close();
})();
