// Records one of the prototype's story scenes, frame by frame on virtual time: the rainbow
// (Story Sequence's finale), or the animals boarding the ark up to the rainbow (Memory Match's).
// Usage: NODE_PATH=$(npm root -g) node tools/record_finale.js <frames folder> 24 27 [previewRainbowBtn|previewStampedeBtn]
// then: ffmpeg -framerate 24 -start_number 3 -i <frames folder>/%04d.png -c:v libtheora -q:v 7 -pix_fmt yuv420p assets/video/rainbow_finale.ogv
// (frames 0-2 are the page still fading in, so the video starts at frame 3)
const { chromium } = require('playwright');
const fs = require('fs');
const SCALE = 2.5; // 1060x850 frames: sharp on a phone, light enough to play smoothly
const out = process.argv[2], FPS = +(process.argv[3] || 24), SECS = +(process.argv[4] || 30);
const BUTTON = process.argv[5] || 'previewRainbowBtn'; // previewStampedeBtn records Memory Match's scene
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: SCALE, isMobile: true, hasTouch: true });
  const p = await ctx.newPage();
  // Virtual time only moves timers, not screen frames, so drive requestAnimationFrame from a
  // timer; otherwise the walkers leaving the ark jump straight to where they end up.
  await p.addInitScript(() => { window.requestAnimationFrame = cb => setTimeout(() => cb(performance.now()), 1000 / 60); });
  // CSS and Web Animations run on the real clock, which races ahead while each frame is
  // captured. So hold every animation still and set its time from the virtual clock instead.
  await p.addInitScript(() => {
    window.__syncAnimations = () => {
      const now = performance.now();
      for (const a of document.getAnimations()) {
        if (a.__t0 === undefined) a.__t0 = now - (a.currentTime || 0);
        a.currentTime = now - a.__t0;
      }
    };
  });
  await p.goto('file://' + require('path').resolve(__dirname, '../docs/prototype/story-games.html'));
  await p.waitForTimeout(2000);
  for (const sel of ['[data-profile="grownup"]', '#introDismissBtn', '#ncGo']) {
    await p.evaluate(s => { const e = document.querySelector(s); if (e && e.offsetParent !== null) e.click(); }, sel); await p.waitForTimeout(800);
  }
  await p.addStyleTag({ content: '.zoom-ctl{display:none!important} #rainbowStage{height:340px!important} .finale-stage{border-radius:0!important}' });
  const cdp = await ctx.newCDPSession(p);
  await cdp.send('Emulation.setVirtualTimePolicy', { policy: 'pause' });
  await p.evaluate(b => { window.__t = performance.now(); document.getElementById(b).click(); }, BUTTON);
  const step = 1000 / FPS;
  for (let i = 0; i < FPS * SECS; i++) {
    // Now and then the budget-expired event never comes; ask again rather than hang.
    for (let done = false; !done;) {
      done = await new Promise(res => {
        const t = setTimeout(() => res(false), 5000);
        cdp.once('Emulation.virtualTimeBudgetExpired', () => { clearTimeout(t); res(true); });
        cdp.send('Emulation.setVirtualTimePolicy', { policy: 'advance', budget: step });
      });
    }
    await p.evaluate(() => window.__syncAnimations());
    const box = await p.evaluate(() => {
      const fin = document.getElementById('finalePanel'), rb = document.getElementById('rainbowPanel');
      const st = !rb.classList.contains('hidden') ? document.getElementById('rainbowStage') : document.getElementById('finaleStage');
      let r = { x: 0, y: 0, width: st.offsetWidth, height: st.offsetHeight }; for (let e = st; e; e = e.offsetParent) { r.x += e.offsetLeft; r.y += e.offsetTop; }
      const msg = !rb.classList.contains('hidden') ? document.getElementById('rainbowMsg') : document.getElementById('finaleMsg');
      return { rainbow: !rb.classList.contains('hidden'), x: r.x - scrollX, y: r.y - scrollY, w: r.width, h: r.height, msg: msg.classList.contains('show') ? msg.textContent : '' };
    });
    // The animals' scene runs on into the rainbow; that part is its own recording.
    if (BUTTON === 'previewStampedeBtn' && box.rainbow) break;
    // A screenshot can also stall waiting for a frame; nudge the clock a hair and try again.
    let shot = null;
    while (!shot) {
      shot = await Promise.race([
        cdp.send('Page.captureScreenshot', { format: 'png', clip: { x: box.x, y: box.y, width: box.w, height: box.h, scale: SCALE } }),
        new Promise(res => setTimeout(() => res(null), 5000)),
      ]);
      if (!shot) cdp.send('Emulation.setVirtualTimePolicy', { policy: 'advance', budget: 1 });
    }
    fs.writeFileSync(`${out}/${String(i).padStart(4, '0')}.png`, Buffer.from(shot.data, 'base64'));
    fs.appendFileSync(`${out}/captions.txt`, `${i}\t${box.msg}\n`);
  }
  await b.close();
})();
