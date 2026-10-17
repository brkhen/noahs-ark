// Renders the hub's remaining art from the web prototype (docs/prototype/story-games.html):
// the portraits of Noah and his sons (Hall of the Ark) and the rainbow promise picture.
// Run: node tools/hallcap.js assets/art/hub
const { chromium } = require('playwright');
const out = process.argv[2];
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 1 });
  const p = await ctx.newPage();
  await p.goto('file://' + require('path').resolve(__dirname, '../docs/prototype/story-games.html'));
  await p.waitForTimeout(2000);
  for (const sel of ['[data-profile="grownup"]', '#introDismissBtn', '#hallBtn']) {
    await p.evaluate(s => { const e = document.querySelector(s); if (e && e.offsetParent !== null) e.click(); }, sel);
    await p.waitForTimeout(800);
  }
  const sprites = await p.evaluate(() => [...document.querySelectorAll('svg')].filter(s => s.querySelector('symbol,linearGradient,radialGradient,pattern,clipPath')).map(s => s.outerHTML).join(''));
  const shot = async (html, size, file) => {
    const q = await ctx.newPage();
    await q.setContent(`<html><body style="margin:0;background:transparent"><div style="position:absolute;width:0;height:0;overflow:hidden">${sprites}</div><div id="capbox" style="width:${size[0]}px;height:${size[1]}px">${html}</div></body></html>`);
    await q.waitForTimeout(200);
    await q.locator('#capbox').screenshot({ path: `${out}/${file}`, omitBackground: true });
    await q.close();
  };
  const tiles = await p.evaluate(() => [...document.querySelectorAll('#hallFamily .portrait svg')].map(s => s.outerHTML));
  const names = ['noah', 'shem', 'ham', 'japheth'];
  for (let i = 0; i < tiles.length; i++) {
    // The prototype's tile background, as a circle, behind the figure.
    const svg = tiles[i].replace('<svg', '<svg width="400" height="400" style="display:block;width:400px;height:400px;border-radius:50%;background:linear-gradient(180deg,#CFE6F5,#E6EFD9)"');
    await shot(svg, [400, 400], `family_${names[i]}.png`);
  }
  const promise = await p.evaluate(() => document.querySelector('#promisePreview svg').outerHTML);
  await shot(promise.replace('<svg', '<svg width="880" height="400" style="display:block"'), [880, 400], 'promise.png');
  await b.close();
})();
