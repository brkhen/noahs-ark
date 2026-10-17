// Records the prototype's Story Sequence finale, frame by frame on virtual time.
// Usage: NODE_PATH=$(npm root -g) node tools/record_finale.js <frames folder> 24 26
// then: ffmpeg -framerate 24 -start_number 3 -i <frames folder>/%04d.png -c:v libtheora -q:v 7 -pix_fmt yuv420p assets/video/rainbow_finale.ogv
// (frames 0-2 are the page still fading in, so the video starts at frame 3)
const { chromium } = require('playwright');
const fs = require('fs');
const out = process.argv[2], FPS = +(process.argv[3] || 24), SECS = +(process.argv[4] || 30);
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true });
  const p = await ctx.newPage();
  await p.goto('file://' + require('path').resolve(__dirname, '../docs/prototype/story-games.html'));
  await p.waitForTimeout(2000);
  for (const sel of ['[data-profile="grownup"]', '#introDismissBtn', '#ncGo']) {
    await p.evaluate(s => { const e = document.querySelector(s); if (e && e.offsetParent !== null) e.click(); }, sel); await p.waitForTimeout(800);
  }
  await p.addStyleTag({ content: '.zoom-ctl{display:none!important} #rainbowStage{height:340px!important} .finale-stage{border-radius:0!important}' });
  const cdp = await ctx.newCDPSession(p);
  await cdp.send('Emulation.setVirtualTimePolicy', { policy: 'pause' });
  await p.evaluate(() => { window.__t = performance.now(); document.getElementById('previewRainbowBtn').click(); });
  const step = 1000 / FPS;
  for (let i = 0; i < FPS * SECS; i++) {
    await new Promise(res => { cdp.once('Emulation.virtualTimeBudgetExpired', res); cdp.send('Emulation.setVirtualTimePolicy', { policy: 'advance', budget: step }); });
    const box = await p.evaluate(() => {
      const fin = document.getElementById('finalePanel'), rb = document.getElementById('rainbowPanel');
      const st = !rb.classList.contains('hidden') ? document.getElementById('rainbowStage') : document.getElementById('finaleStage');
      let r = { x: 0, y: 0, width: st.offsetWidth, height: st.offsetHeight }; for (let e = st; e; e = e.offsetParent) { r.x += e.offsetLeft; r.y += e.offsetTop; }
      const msg = !rb.classList.contains('hidden') ? document.getElementById('rainbowMsg') : document.getElementById('finaleMsg');
      return { x: r.x - scrollX, y: r.y - scrollY, w: r.width, h: r.height, msg: msg.classList.contains('show') ? msg.textContent : '' };
    });
    const shot = await cdp.send('Page.captureScreenshot', { format: 'png', clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: 3 } });
    fs.writeFileSync(`${out}/${String(i).padStart(4, '0')}.png`, Buffer.from(shot.data, 'base64'));
    fs.appendFileSync(`${out}/captions.txt`, `${i}\t${box.msg}\n`);
  }
  await b.close();
})();
