const { chromium } = require('playwright');
const out = process.argv[2];
const ROUNDS = [['build','board1','rain1','land1'],['build','board2','shut','rain2','land2'],['build','board3','shut3','rain3','dove','rainbow']];
const WANT = {build:'build', board1:'board', rain1:'rain', land1:'land', shut:'shut', dove:'dove', rainbow:'rainbow'};
let sprites = null;
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 1 });
  const p = await ctx.newPage();
  await p.goto('file://' + require('path').resolve(__dirname, '../docs/prototype/story-games.html'));
  await p.waitForTimeout(2000);
  for (const sel of ['[data-profile="grownup"]', '#introDismissBtn', '#ncGo', '#playSeqBtn']) {
    await p.evaluate(s => { const e = document.querySelector(s); if (e && e.offsetParent !== null) e.click(); }, sel); await p.waitForTimeout(800);
  }
  for (let r = 0; r < 3; r++) {
    await p.waitForTimeout(800);
    for (const id of ROUNDS[r]) {
      if (WANT[id]) {
        const html = await p.evaluate(i => document.querySelector('.seq-card[data-id="'+i+'"] svg').outerHTML, id);
        if (!sprites) sprites = await p.evaluate(() => [...document.querySelectorAll('svg')].filter(s => s.querySelector('symbol,linearGradient,radialGradient,pattern,clipPath')).filter(s => !s.closest('.seq-card')).map(s => s.outerHTML).join(''));
        const q = await ctx.newPage();
        await q.setContent(`<html style="background:transparent"><body style="margin:0;background:transparent"><div style="position:absolute;width:0;height:0;overflow:hidden">${sprites}</div><div id="capbox" style="width:512px;height:512px">${html.replace('<svg', '<svg width="512" height="512" style="width:512px;height:512px;display:block"')}</div></body></html>`);
        await q.waitForTimeout(200);
        await q.locator('#capbox').screenshot({ path: `${out}/ev_${WANT[id]}.png`, omitBackground: true });
        await q.close();
      }
      await p.evaluate(i => document.querySelector('.seq-card[data-id="'+i+'"]').click(), id);
      await p.waitForTimeout(250);
    }
    await p.waitForTimeout(1600);
    await p.evaluate(() => document.getElementById('seqOverlayBtn').click());
    await p.waitForTimeout(3400);
  }
  await b.close();
})();
