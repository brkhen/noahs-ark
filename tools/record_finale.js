// Records one of the prototype's story scenes, frame by frame on virtual time: the rainbow
// (Story Sequence's finale), or the animals boarding the ark up to the rainbow (Memory Match's).
// Usage: NODE_PATH=$(npm root -g) node tools/record_finale.js <frames folder> 24 27 [previewRainbowBtn|previewStampedeBtn]
// then: ffmpeg -framerate 24 -start_number 3 -i <frames folder>/%04d.png -ss 0.1667 -i <frames folder>/sound.wav
//   -c:v libtheora -q:v 7 -pix_fmt yuv420p -c:a libvorbis -q:a 5 -shortest assets/video/rainbow_finale.ogv
// (frames 0-2 are the page still fading in, so the video starts at frame 3, which is 4/24 s into the sound)
// The scene's sounds (rain, thunder, hoofbeats...) are the prototype's own Web Audio, rendered into sound.wav.
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
  // The page's sound engine renders offline instead, on the same virtual clock as the pictures,
  // so every sound lands on its frame. It's written out as sound.wav at the end.
  await p.addInitScript(secs => {
    const Offline = window.OfflineAudioContext;
    window.AudioContext = window.webkitAudioContext = function () {
      const ctx = new Offline(2, Math.ceil(48000 * secs), 48000);
      Object.defineProperty(ctx, 'currentTime', { get: () => window.__t === undefined ? 0 : Math.max(0, (performance.now() - window.__t) / 1000) });
      Object.defineProperty(ctx, 'state', { get: () => 'running' });
      ctx.resume = ctx.suspend = () => Promise.resolve();
      window.__actx = ctx;
      return ctx;
    };
    // Cutting a sound off is done with a gain ramp, which keeps its time; a disconnect would
    // silence the whole offline render, so leave everything connected.
    AudioNode.prototype.disconnect = function () {};
  }, SECS + 1);
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
  // Render the sound, nudging the clock along until it's done (it waits on the page's clock).
  await p.evaluate(() => { if (window.__actx) window.__actx.startRendering().then(buf => { window.__sound = buf; }); });
  for (let k = 0; k < 600 && await p.evaluate(() => !!window.__actx && !window.__sound); k++) {
    await new Promise(res => { cdp.once('Emulation.virtualTimeBudgetExpired', res); cdp.send('Emulation.setVirtualTimePolicy', { policy: 'advance', budget: 100 }); });
    await new Promise(res => setTimeout(res, 50));
  }
  const wav = await p.evaluate(() => {
    const buf = window.__sound;
    if (!buf) return null;
    const n = buf.length, ch = buf.numberOfChannels, out = new DataView(new ArrayBuffer(44 + n * ch * 2));
    const str = (o, t) => [...t].forEach((c, i) => out.setUint8(o + i, c.charCodeAt(0)));
    str(0, 'RIFF'); out.setUint32(4, 36 + n * ch * 2, true); str(8, 'WAVEfmt '); out.setUint32(16, 16, true);
    out.setUint16(20, 1, true); out.setUint16(22, ch, true); out.setUint32(24, buf.sampleRate, true);
    out.setUint32(28, buf.sampleRate * ch * 2, true); out.setUint16(32, ch * 2, true); out.setUint16(34, 16, true);
    str(36, 'data'); out.setUint32(40, n * ch * 2, true);
    const data = [...Array(ch).keys()].map(c => buf.getChannelData(c));
    for (let i = 0; i < n; i++) for (let c = 0; c < ch; c++) out.setInt16(44 + (i * ch + c) * 2, Math.max(-1, Math.min(1, data[c][i])) * 32767, true);
    let bin = ''; const bytes = new Uint8Array(out.buffer);
    for (let i = 0; i < bytes.length; i += 32768) bin += String.fromCharCode(...bytes.subarray(i, i + 32768));
    return btoa(bin);
  });
  if (wav) fs.writeFileSync(`${out}/sound.wav`, Buffer.from(wav, 'base64'));
  await b.close();
})();
