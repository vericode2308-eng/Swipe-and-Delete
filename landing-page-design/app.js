/* Lighter landing page.
   The hero phone is a working copy of the app's core loop (Swipe → Review → Done),
   ported from SwipeView.swift and DoneView.swift: same thresholds, same spring,
   same celebration timeline. */
(() => {
  'use strict';

  /* Owner sets this once the App Store record exists. Until then the buttons say
     "Coming soon" and do nothing, rather than pointing at a dead link. */
  const APP_STORE_URL = '';

  const mq = matchMedia('(prefers-reduced-motion: reduce)');
  let reduce = mq.matches;
  mq.addEventListener?.('change', e => { reduce = e.matches; });

  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const clamp01 = x => Math.max(0, Math.min(1, x));
  const ease = x => { const c = clamp01(x); return c * c * (3 - 2 * c); };
  const span = (e, a, b) => clamp01((e - a) / (b - a));
  const icon = (id, cls = '') => `<svg class="${cls}" aria-hidden="true"><use href="#${id}"/></svg>`;

  /* ---------- Formatting (ported from SwipeCore/Formatting.swift) ---------- */
  function size(bytes) {
    const units = ['KB', 'MB', 'GB', 'TB'];
    let v = Math.max(0, bytes) / 1000, u = 0;
    while (v >= 999.5 && u < units.length - 1) { v /= 1000; u++; }
    let t = v < 10 && v > 0 ? v.toFixed(1) : v.toFixed(0);
    if (t.endsWith('.0')) t = t.slice(0, -2);
    return `${t} ${units[u]}`;
  }
  function roomForPhotos(bytes) {
    const n = Math.floor(Math.max(0, bytes) / 3e6);
    const r = n < 100 ? n : n < 1000 ? Math.floor((n + 5) / 10) * 10 : Math.floor((n + 50) / 100) * 100;
    return `Room for about ${r.toLocaleString('en-GB')} more photo${r === 1 ? '' : 's'}`;
  }

  /* ---------- Store buttons ---------- */
  $$('[data-store]').forEach(a => {
    if (APP_STORE_URL) { a.href = APP_STORE_URL; a.rel = 'noopener'; return; }
    a.removeAttribute('href');
    a.setAttribute('aria-disabled', 'true');
    a.setAttribute('role', 'link');
    const small = $('[data-store-small]', a), big = $('[data-store-big]', a);
    if (small && big) { small.textContent = 'Coming soon to the'; big.textContent = 'App Store'; }
    else a.textContent = 'Coming soon';
  });

  /* ---------- Phone screen scaling (393 × 852 pt canvas) ---------- */
  const scales = new WeakMap();
  const ro = new ResizeObserver(entries => {
    for (const en of entries) {
      const scr = $('.screen', en.target);
      if (!scr) continue;
      const s = en.contentRect.width / 393;
      scales.set(scr, s);
      scr.style.transform = `scale(${s})`;
    }
  });
  $$('.display').forEach(d => { if ($('.screen', d)) ro.observe(d); });
  const scaleOf = el => scales.get(el) || 1;

  /* ---------- Shared phone chrome ---------- */
  const STATUS = `<div class="statusbar" aria-hidden="true"><span>9:41</span><span class="icons">
    <svg viewBox="0 0 18 12" style="width:18px"><use href="#i-signal"/></svg>
    <svg viewBox="0 0 16 12" style="width:16px"><use href="#i-wifi"/></svg>
    <svg viewBox="0 0 27 13" style="width:27px"><use href="#i-batt"/></svg></span></div>`;
  const CANVAS = `<div class="cb cb1"></div><div class="cb cb2"></div><div class="cb cb3"></div>`;

  /* ---------- Demo library ---------- */
  const PARKING = `<div class="ss" aria-hidden="true">
      <div class="ss-sb"><span>14:32</span><span>●●● ▮</span></div>
      <div class="ss-h">Harbour Street Car Park</div>
      <div class="ss-s">Payment received</div>
      <div class="ss-amt"><b>£6.40</b><span>✓ Paid by card</span></div>
      <div class="ss-rows">
        <div class="ss-row"><span>Bay</span>118</div>
        <div class="ss-row"><span>Entry</span>11:05</div>
        <div class="ss-row"><span>Exit by</span>15:05</div>
        <div class="ss-row"><span>Reference</span>PK 48 2913</div>
      </div>
      <div class="ss-code"></div>
    </div>`;

  const DECK = [
    { id: 'flowers', kind: 'PHOTO', date: '31 March 2018', img: 'assets/photo-flowers.webp', bytes: 3_620_000, label: 'Photo of pink ice plant flowers' },
    { id: 'parking', kind: 'SCREENSHOT', date: '9 January 2025', html: PARKING, bytes: 412_000, label: 'Screenshot of a car park receipt' },
    { id: 'dunes', kind: 'VIDEO · 0:14', date: '22 June 2023', img: 'assets/photo-dunes.webp', video: true, bytes: 38_740_000, label: 'Video, 14 seconds, of a flower in the dunes' },
    { id: 'leaves', kind: 'PHOTO', date: '3 August 2022', img: 'assets/photo-leaves.webp', blurry: true, bytes: 2_870_000, label: 'Blurred, accidental photo of leaves' },
    { id: 'flowers2', kind: 'PHOTO', date: '31 March 2018', img: 'assets/photo-flowers-2.webp', bytes: 3_180_000, label: 'Close up photo of the same flowers' },
  ];

  function mediaEl(card, cls = '') {
    if (card.html) { const d = document.createElement('div'); d.innerHTML = card.html; const el = d.firstElementChild; if (cls) el.classList.add(cls); return el; }
    const im = document.createElement('img');
    im.src = card.img; im.alt = ''; im.decoding = 'async'; im.draggable = false;
    if (cls) im.className = cls;
    return im;
  }

  /* ---------- Spring (response 0.3 s, damping 0.8: SwiftUI .spring(response:dampingFraction:)) ---------- */
  const K = (2 * Math.PI / 0.3) ** 2, C = 4 * Math.PI * 0.8 / 0.3;

  /* =====================================================================
     Done celebration (DoneView.swift): pure function of elapsed time.
     ===================================================================== */
  function mountDone(host, summary, { onBack, backLabel = 'Back to Albums', autoplay = true } = {}) {
    const hasSize = summary.bytes > 0;
    const R = 95, CIRC = 2 * Math.PI * R;
    const root = document.createElement('div');
    root.className = 'done';
    root.innerHTML = `
      <div class="done-body" role="button" tabindex="-1" aria-label="${size(summary.bytes)} cleared. ${summary.reviewed} reviewed, ${summary.kept} kept, ${summary.deleted} deleted.">
        <div class="disc" aria-hidden="true">
          <div class="glow"></div>
          <div class="gdisc glass"></div>
          <svg class="ring" viewBox="0 0 190 190">
            <defs><linearGradient id="rg-${summary.key}" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" style="stop-color:var(--ring)"/><stop offset=".55" style="stop-color:#A9DCCD"/><stop offset="1" style="stop-color:#F2B8A8"/></linearGradient></defs>
            <circle cx="95" cy="95" r="${R}" fill="none" stroke="currentColor" stroke-opacity=".12" stroke-width="8"/>
            <circle class="prog" cx="95" cy="95" r="${R}" fill="none" stroke="url(#rg-${summary.key})" stroke-width="8" stroke-linecap="round" stroke-dasharray="${CIRC}" stroke-dashoffset="${CIRC}"/>
          </svg>
          <div class="num"><b>0 KB</b><span>${hasSize ? 'CLEARED' : 'DELETED'}</span></div>
          <div class="chk">${icon('i-check')}</div>
          <canvas width="1800" height="1800"></canvas>
        </div>
        <div class="words" aria-hidden="true">
          <div class="w1"><h4>Beautifully done</h4><p>${summary.album} is about ${size(summary.bytes)} lighter.</p></div>
          <div class="stats glass w2">
            <div><b data-n="${summary.reviewed}">0</b><span>REVIEWED</span></div>
            <div><b data-n="${summary.kept}">0</b><span>KEPT</span></div>
            <div><b data-n="${summary.deleted}">0</b><span>DELETED</span></div>
          </div>
          <div class="room glass w3">${roomForPhotos(summary.bytes)}</div>
        </div>
      </div>
      <div class="drift" aria-hidden="true"></div>
      <div class="done-foot">
        <small>Space returns once Recently Deleted empties. Changed your mind? Restore within 30 days.</small>
        ${onBack ? `<button class="ppill" type="button">${backLabel}</button>` : ''}
      </div>`;
    host.appendChild(root);

    const prog = $('.prog', root), num = $('.num b', root), chk = $('.chk', root), glow = $('.glow', root);
    const canvas = $('canvas', root), ctx = canvas.getContext('2d');
    ctx.scale(2, 2);
    const w1 = $('.w1', root), w2 = $('.w2', root), w3 = $('.w3', root);
    const statEls = $$('.stats b', root);
    const drift = $('.drift', root);
    const thumbs = summary.thumbs.map(c => {
      const el = mediaEl(c);
      if (c.html) { el.style.width = '393px'; el.style.height = '852px'; el.style.left = '0'; el.style.top = '0'; el.style.borderRadius = '0'; }
      const wrapEl = document.createElement('div');
      wrapEl.appendChild(el);
      if (c.html) { el.style.transform = 'scale(.163)'; el.style.transformOrigin = '0 0'; }
      drift.appendChild(wrapEl);
      return wrapEl;
    });
    if (onBack) $('.ppill', root).addEventListener('click', onBack);

    let start = 0, raf = 0, finished = false, buzzed = false;

    function render(e) {
      const p = ease(span(e, 0.5, 1.9));
      prog.setAttribute('stroke-dashoffset', String(CIRC * (1 - p)));
      num.textContent = hasSize ? size(summary.bytes * p) : Math.round(summary.deleted * p).toLocaleString('en-GB');
      const pop = span(e, 1.9, 2.25);
      const sc = pop === 0 ? 0 : 1 + 0.25 * Math.sin(pop * Math.PI) * (1 - pop) * 2;
      chk.style.transform = `translate(66px, 66px) scale(${sc})`;
      glow.style.opacity = String(0.25 * pop);
      if (pop > 0 && !buzzed) { buzzed = true; navigator.vibrate?.(18); }

      const a = ease(span(e, 2.0, 2.4)), b = ease(span(e, 2.3, 2.7)), c = ease(span(e, 2.6, 3.0)), k = ease(span(e, 2.2, 3.0));
      w1.style.cssText = `opacity:${a};transform:translateY(${10 * (1 - a)}px)`;
      w2.style.cssText = `opacity:${b};transform:translateY(${10 * (1 - b)}px)`;
      w3.style.cssText = `opacity:${c};transform:translateY(${10 * (1 - c)}px)`;
      statEls.forEach(el => { el.textContent = Math.round(+el.dataset.n * k).toLocaleString('en-GB'); });

      // The deleted photos drift into the middle, shrink and fade, 70 ms apart.
      const W = 393, tx = W / 2, ty = 54 + 40 + 110, n = Math.max(1, thumbs.length);
      thumbs.forEach((el, i) => {
        const q = ease(span(e, i * 0.07, i * 0.07 + 0.9));
        const ang = i / n * 2 * Math.PI;
        const fx = tx + Math.cos(ang) * W * 0.45, fy = ty + Math.sin(ang) * 200 + 60;
        const x = fx + (tx - fx) * q, y = fy + (ty - fy) * q;
        el.style.transform = `translate(${x}px, ${y}px) scale(${1 - 0.8 * q})`;
        el.style.opacity = String(q >= 1 ? 0 : 1 - q * q);
      });

      // 22 sparkles flung out from the disc once the check lands.
      ctx.clearRect(0, 0, 900, 900);
      const life = span(e, 1.9, 3.0);
      if (life > 0 && life < 1) {
        for (let i = 0; i < 22; i++) {
          const angle = i / 22 * 2 * Math.PI + Math.sin(i * 12.9898) * 0.3;
          const speed = 150 + 130 * Math.abs(Math.sin(i * 78.233));
          const r = 95 + speed * ease(life);
          const x = 450 + Math.cos(angle) * r, y = 450 + Math.sin(angle) * r;
          const s = (4 + 4 * Math.abs(Math.sin(i * 3.1))) * (1 - life);
          ctx.beginPath();
          ctx.moveTo(x, y - s * 1.6); ctx.lineTo(x + s * 0.4, y - s * 0.4); ctx.lineTo(x + s * 1.6, y);
          ctx.lineTo(x + s * 0.4, y + s * 0.4); ctx.lineTo(x, y + s * 1.6); ctx.lineTo(x - s * 0.4, y + s * 0.4);
          ctx.lineTo(x - s * 1.6, y); ctx.lineTo(x - s * 0.4, y - s * 0.4); ctx.closePath();
          ctx.fillStyle = i % 2 === 0 ? `rgba(169,220,205,${1 - life})` : `rgba(242,184,168,${1 - life})`;
          ctx.fill();
        }
      }
    }
    function tick(now) {
      const e = (now - start) / 1000;
      render(e);
      if (e < 3.2 && !finished) raf = requestAnimationFrame(tick);
      else finished = true;
    }
    function play() {
      cancelAnimationFrame(raf); finished = false; buzzed = false;
      if (reduce) { render(99); root.animate?.([{ opacity: 0 }, { opacity: 1 }], { duration: 300 }); finished = true; return; }
      start = performance.now(); raf = requestAnimationFrame(tick);
    }
    function skip() { cancelAnimationFrame(raf); finished = true; render(99); }
    $('.done-body', root).addEventListener('click', skip);
    render(0);
    if (autoplay) play();
    return { play, skip, root, destroy() { cancelAnimationFrame(raf); root.remove(); } };
  }

  /* =====================================================================
     Swipe demo (SwipeView.swift)
     ===================================================================== */
  function SwipeDemo(screen, { onPhoto, live }) {
    const W = 361;             // carousel width (screen 393 − 2 × 16 margin)
    const CW = 282, STEP = CW + 12;
    const N = DECK.length;
    let index = 0, decisions = [], busy = false, interacted = false;
    let view = 'swipe', done = null, reviewKept = new Set();

    screen.innerHTML = `
      <div class="scr-bg">${CANVAS}<img class="bgimg" alt=""><img class="bgimg" alt=""><div class="scrim"></div></div>
      ${STATUS}
      <div class="view view-swipe on">
        <div class="topbar">
          <button class="ibtn glass js-restart" type="button" aria-label="Start the demo again">${icon('i-back')}</button>
          <div class="ttl"><b>Recents</b><small class="js-count">1 of ${N}</small></div>
          <button class="rvbtn glass js-review" type="button" disabled>${icon('i-trash')}<span class="js-marked">0</span></button>
        </div>
        <div class="chips" aria-hidden="true"><span class="chip sel">Recents</span><span class="chip glass">Screenshots</span><span class="chip glass">Videos</span></div>
        <div class="carousel"></div>
        <div class="dock glass">
          <button class="dbtn big del js-del" type="button" aria-label="Delete">${icon('i-x')}</button>
          <button class="dbtn small js-undo" type="button" aria-label="Undo" disabled>${icon('i-undo')}</button>
          <button class="dbtn big kp js-keep" type="button" aria-label="Keep">${icon('i-check')}</button>
        </div>
      </div>
      <div class="view view-review"></div>
      <div class="view view-done"></div>`;

    const bgImgs = $$('.bgimg', screen), scrim = $('.scrim', screen);
    const carousel = $('.carousel', screen);
    const vSwipe = $('.view-swipe', screen), vReview = $('.view-review', screen), vDone = $('.view-done', screen);
    const countEl = $('.js-count', screen), markedEl = $('.js-marked', screen), reviewBtn = $('.js-review', screen);
    const delBtn = $('.js-del', screen), keepBtn = $('.js-keep', screen), undoBtn = $('.js-undo', screen);

    /* Cards */
    const bodies = DECK.map((c, k) => {
      const el = document.createElement('div');
      el.className = 'card' + (c.blurry ? ' blurry' : '');
      el.appendChild(mediaEl(c));
      el.insertAdjacentHTML('beforeend', `
        ${c.video ? `<div class="play glass">${icon('i-play')}</div>` : ''}
        <div class="tint"></div>
        <div class="tag glass"></div>
        <div class="cap glass"><b>${c.date}</b><span>${c.kind}</span></div>
        <div class="badge glass"></div>`);
      el.setAttribute('aria-hidden', 'true');
      carousel.appendChild(el);
      return { el, k, x: k === 0 ? 0 : k === 1 ? STEP : 0, v: 0, tx: k === 0 ? 0 : STEP, s: 1, ts: 1, o: k <= 1 ? 1 : 0, to: k <= 1 ? 1 : 0, drag: false,
        tint: $('.tint', el), tag: $('.tag', el), cap: $('.cap', el), badge: $('.badge', el) };
    });
    const endEl = document.createElement('div');
    endEl.className = 'card end glass';
    carousel.appendChild(endEl);
    const endBody = { el: endEl, k: N, x: 0, v: 0, tx: 0, s: 1, ts: 1, o: 0, to: 0, drag: false };
    const all = [...bodies, endBody];

    let pending = null, raf = 0, last = 0;
    function loop(now) {
      const dt = Math.min(0.032, (now - last) / 1000 || 0.016); last = now;
      let moving = false;
      for (const b of all) {
        if (!b.drag) {
          // integrate in small steps for stability
          for (let i = 0; i < 4; i++) {
            const h = dt / 4, a = -K * (b.x - b.tx) - C * b.v;
            b.v += a * h; b.x += b.v * h;
          }
          if (Math.abs(b.x - b.tx) > 0.3 || Math.abs(b.v) > 2) moving = true; else { b.x = b.tx; b.v = 0; }
        } else moving = true;
        b.s += (b.ts - b.s) * Math.min(1, dt * 14);
        b.o += (b.to - b.o) * Math.min(1, dt * (reduce ? 10 : 9));
        if (Math.abs(b.ts - b.s) > 0.001 || Math.abs(b.to - b.o) > 0.01) moving = true; else { b.s = b.ts; b.o = b.to; }
      }
      if (pending && pending.test()) { const f = pending.fn; pending = null; f(); moving = true; }
      draw();
      if (moving || pending) raf = requestAnimationFrame(loop); else raf = 0;
    }
    const kick = () => { if (!raf) { last = performance.now(); raf = requestAnimationFrame(loop); } };

    function draw() {
      let grow = 0;
      for (const b of all) {
        const rel = b.k - index;
        const isCur = rel === 0 && b !== endBody;
        const rot = isCur ? 12 * Math.max(-1, Math.min(1, b.x / (W * 0.5))) : 0;
        b.el.style.transform = `translate3d(${b.x}px,0,0) rotate(${rot}deg) scale(${b.s})`;
        b.el.style.opacity = b.o.toFixed(3);
        b.el.style.visibility = b.o < 0.01 ? 'hidden' : 'visible';
        b.el.style.zIndex = isCur ? 3 : rel === -1 ? 2 : 1;
        if (b === endBody) continue;
        const p = isCur ? Math.max(-1, Math.min(1, b.x / (W * 0.3))) : 0;
        if (isCur) grow = p;
        b.tint.style.background = p < 0 ? '#F2B8A8' : '#A9DCCD';
        b.tint.style.opacity = String(0.45 * Math.abs(p));
        if (Math.abs(p) > 0.05) {
          const del = p < 0;
          if (b.tag.dataset.side !== (del ? 'd' : 'k')) {
            b.tag.dataset.side = del ? 'd' : 'k';
            b.tag.innerHTML = `${icon(del ? 'i-x' : 'i-check')}${del ? 'DELETE' : 'KEEP'}`;
            b.tag.style.color = del ? 'var(--del)' : 'var(--keep)';
          }
          b.tag.style.display = 'inline-flex';
          b.tag.style.opacity = String(Math.min(1, Math.abs(p) * 1.4));
        } else b.tag.style.display = 'none';
        b.cap.style.opacity = isCur ? '1' : '0';
        const dec = decisions.find(d => d.k === b.k);
        if (rel === -1 && dec) {
          b.badge.style.display = 'grid';
          b.badge.innerHTML = icon(dec.side < 0 ? 'i-x' : 'i-check');
          b.badge.style.color = dec.side < 0 ? 'var(--del)' : 'var(--keep)';
        } else b.badge.style.display = 'none';
      }
      delBtn.style.transform = `scale(${1 + 0.25 * (grow < 0 ? -grow : 0)})`;
      keepBtn.style.transform = `scale(${1 + 0.25 * (grow > 0 ? grow : 0)})`;
    }

    function chrome() {
      countEl.textContent = `${Math.min(index + 1, N)} of ${N}`;
      const marked = decisions.filter(d => d.side < 0).length;
      markedEl.textContent = marked;
      reviewBtn.disabled = marked === 0;
      reviewBtn.setAttribute('aria-label', `Review ${marked} marked for deletion`);
      undoBtn.disabled = decisions.length === 0;
      delBtn.disabled = keepBtn.disabled = index >= N;
      const cur = DECK[Math.min(index, N - 1)];
      setBackdrop(cur.img || null);
      onPhoto?.(cur.img || null);
      if (index >= N) {
        endEl.innerHTML = `<b>That's all</b><p>${marked ? `${marked} marked for deletion.` : 'Nothing marked for deletion.'}</p>
          <button class="ppill js-end" type="button">${marked ? 'Review deletions' : 'Start again'}</button>`;
        $('.js-end', endEl).addEventListener('click', () => marked ? openReview() : reset());
      }
    }

    let bgFlip = 0;
    function setBackdrop(src) {
      const curImg = bgImgs[bgFlip];
      if (src && curImg.getAttribute('src') === src && curImg.classList.contains('on')) return;
      if (!src) { bgImgs.forEach(i => i.classList.remove('on')); scrim.classList.remove('on'); return; }
      bgFlip ^= 1;
      const next = bgImgs[bgFlip], prev = bgImgs[bgFlip ^ 1];
      next.src = src; next.classList.add('on'); prev.classList.remove('on'); scrim.classList.add('on');
    }

    function layout(mode, prevIndex) {
      for (const b of all) {
        const rel = b.k - index;
        if (b === endBody) { b.tx = 0; b.x = 0; b.to = index >= N ? 1 : 0; b.ts = 1; continue; }
        if (mode === 'forward') {
          if (b.k === prevIndex) { b.x = b.tx = -STEP; b.v = 0; b.s = b.ts = 0.94; b.o = 0; b.to = 1; }
          else if (rel === 0) { b.tx = 0; b.ts = 1; b.to = 1; }
          else if (rel === 1) { b.x = b.tx = STEP; b.v = 0; b.s = b.ts = 1; b.o = 0; b.to = 1; }
          else { b.to = 0; }
        } else if (mode === 'undo') {
          if (b.k === prevIndex) { b.tx = STEP; b.ts = 1; b.to = 1; }
          else if (rel === 0) { b.x = reduce ? 0 : -393; b.tx = 0; b.v = 0; b.s = b.ts = 1; b.o = reduce ? 0 : 1; b.to = 1; }
          else if (rel === -1) { b.x = b.tx = -STEP; b.v = 0; b.s = b.ts = 0.94; b.o = 0; b.to = 1; }
          else { b.to = 0; }
        } else {
          b.v = 0;
          b.x = b.tx = rel === 0 ? 0 : rel === 1 ? STEP : rel === -1 ? -STEP : 0;
          b.s = b.ts = rel === -1 ? 0.94 : 1;
          b.o = 0; b.to = (rel >= -1 && rel <= 1) ? 1 : 0;
        }
        if (reduce && mode !== 'reset') { b.x = b.tx; if (rel === 0 || rel === 1 || rel === -1) b.o = Math.min(b.o, 0.0); }
      }
      chrome(); kick();
    }

    function announce(t) { if (live) { live.textContent = ''; setTimeout(() => { live.textContent = t; }, 30); } }

    function commit(side) {
      if (busy || index >= N || view !== 'swipe') return;
      interacted = true; busy = true;
      navigator.vibrate?.(8);
      const b = bodies[index];
      b.drag = false;
      const apply = () => {
        decisions.push({ k: index, side });
        const prev = index; index++;
        layout('forward', prev);
        busy = false;
        announce(index >= N ? (side < 0 ? "Marked for deletion. That's all." : "Kept. That's all.")
          : `${side < 0 ? 'Marked for deletion' : 'Kept'}, ${index + 1} of ${N}`);
      };
      if (reduce) { b.x = b.tx = 0; apply(); return; }
      b.tx = side * W * 1.3;
      pending = { test: () => Math.abs(b.x - b.tx) < 40, fn: apply };
      kick();
    }

    function undo() {
      if (busy || decisions.length === 0 || view !== 'swipe') return;
      interacted = true;
      decisions.pop();
      const prev = index; index--;
      layout('undo', prev);
      announce(`Undone, ${index + 1} of ${N}`);
    }

    function reset() {
      decisions = []; index = 0; reviewKept = new Set(); busy = false; pending = null;
      done?.destroy(); done = null;
      show('swipe');
      layout('reset');
    }

    function show(v) {
      view = v;
      vSwipe.classList.toggle('on', v === 'swipe');
      vReview.classList.toggle('on', v === 'review');
      vDone.classList.toggle('on', v === 'done');
    }

    /* Review (ReviewView) */
    function openReview() {
      const marked = decisions.filter(d => d.side < 0).map(d => DECK[d.k]);
      if (!marked.length) return;
      reviewKept = new Set();
      vReview.innerHTML = `
        <div class="rv-top">
          <button class="ibtn glass js-rv-back" type="button" aria-label="Back to swiping">${icon('i-back')}</button>
          <div class="ttl"><b class="js-rv-title"></b><small>Tap a photo to keep it instead.</small></div>
        </div>
        <div class="rv-grid glass"></div>
        <div class="rv-note glass">Deleted photos stay in Recently Deleted for 30 days. With iCloud Photos on, they're removed from your other devices too.</div>
        <div class="rv-foot">
          <small>Free plan: 50 deletions a day · 50 left today</small>
          <button class="ppill blush js-rv-del" type="button"></button>
        </div>`;
      const grid = $('.rv-grid', vReview);
      marked.forEach(c => {
        const t = document.createElement('button');
        t.type = 'button';
        t.className = 'rv-tile' + (c.blurry ? ' blurry' : '');
        t.appendChild(mediaEl(c));
        t.insertAdjacentHTML('beforeend', `<span class="badge glass" style="color:var(--del)">${icon('i-x')}</span>`);
        t.setAttribute('aria-label', `${c.label}, marked for deletion. Tap to keep.`);
        t.addEventListener('click', () => {
          const kept = !reviewKept.has(c.id);
          kept ? reviewKept.add(c.id) : reviewKept.delete(c.id);
          t.classList.toggle('kept', kept);
          $('.badge', t).innerHTML = icon(kept ? 'i-check' : 'i-x');
          $('.badge', t).style.color = kept ? 'var(--keep)' : 'var(--del)';
          t.setAttribute('aria-label', `${c.label}, ${kept ? 'kept' : 'marked for deletion'}.`);
          sync();
        });
        grid.appendChild(t);
      });
      const rows = Math.ceil(marked.length / 3);
      const tile = (361 - 20 - 16) / 3;
      $('.rv-note', vReview).style.top = `${140 + 20 + rows * tile + (rows - 1) * 8 + 16}px`;
      const sync = () => {
        const n = marked.length - reviewKept.size;
        $('.js-rv-title', vReview).textContent = `${n} to delete`;
        $('.js-rv-del', vReview).textContent = n ? `Delete ${n} photo${n === 1 ? '' : 's'}` : 'Back to Albums';
      };
      sync();
      $('.js-rv-back', vReview).addEventListener('click', () => show('swipe'));
      $('.js-rv-del', vReview).addEventListener('click', () => {
        const toDelete = marked.filter(c => !reviewKept.has(c.id));
        if (!toDelete.length) { reset(); return; }
        openDone(toDelete);
      });
      show('review');
    }

    /* Done (DoneView) */
    function openDone(deleted) {
      vDone.innerHTML = '';
      setBackdrop(null);
      const bytes = deleted.reduce((s, c) => s + c.bytes, 0);
      done = mountDone(vDone, {
        key: 'hero', album: 'Recents', bytes, reviewed: N, deleted: deleted.length, kept: N - deleted.length, thumbs: deleted,
      }, { onBack: reset, backLabel: 'Start again' });
      show('done');
      announce(`${size(bytes)} cleared.`);
    }

    /* Pointer drag (DragGesture minimumDistance 8; commit past 30 % or on a flick) */
    let startX = 0, startY = 0, samples = [], pid = null, decided = false;
    carousel.addEventListener('pointerdown', e => {
      if (busy || index >= N || view !== 'swipe' || e.button > 0) return;
      pid = e.pointerId; startX = e.clientX; startY = e.clientY; decided = false;
      samples = [{ t: e.timeStamp, x: 0 }];
      stopHint();
    });
    carousel.addEventListener('pointermove', e => {
      if (e.pointerId !== pid) return;
      const s = scaleOf(screen);
      const dx = (e.clientX - startX) / s, dy = (e.clientY - startY) / s;
      if (!decided) {
        if (Math.hypot(dx, dy) < 8) return;
        if (Math.abs(dy) > Math.abs(dx)) { pid = null; return; }   // vertical: let the page scroll
        decided = true; interacted = true;
        carousel.setPointerCapture(pid);
        carousel.classList.add('dragging');
        bodies[index].drag = true;
      }
      const b = bodies[index];
      b.x = dx; b.v = 0;
      samples.push({ t: e.timeStamp, x: dx });
      while (samples.length > 2 && e.timeStamp - samples[0].t > 100) samples.shift();
      draw();
    });
    const end = e => {
      if (e.pointerId !== pid) return;
      pid = null; carousel.classList.remove('dragging');
      if (!decided) return;
      const b = bodies[index]; b.drag = false;
      const f = samples[0], l = samples[samples.length - 1];
      const vel = l.t > f.t ? (l.x - f.x) / ((l.t - f.t) / 1000) : 0;
      const far = Math.abs(b.x) > W * 0.3;
      const flick = Math.abs(vel) > 900 && Math.abs(b.x) > 30 && (vel > 0) === (b.x > 0);
      if (far || flick) { b.v = vel; commit(b.x < 0 ? -1 : 1); }
      else { b.v = vel; b.tx = 0; kick(); }
    };
    carousel.addEventListener('pointerup', end);
    carousel.addEventListener('pointercancel', end);

    delBtn.addEventListener('click', () => { stopHint(); commit(-1); });
    keepBtn.addEventListener('click', () => { stopHint(); commit(1); });
    undoBtn.addEventListener('click', () => { stopHint(); undo(); });
    reviewBtn.addEventListener('click', () => { stopHint(); openReview(); });
    $('.js-restart', screen).addEventListener('click', () => { stopHint(); reset(); });

    /* Gentle hint: the card leans left, then right, until the visitor touches it. */
    let hintTimers = [], hintRuns = 0;
    function hint() {
      if (interacted || reduce || view !== 'swipe' || index >= N || busy || hintRuns >= 2) return;
      hintRuns++;
      const b = bodies[index];
      const seq = [[0, -64], [700, 0], [1300, 64], [2000, 0]];
      seq.forEach(([t, x]) => hintTimers.push(setTimeout(() => { if (!interacted && !b.drag) { b.tx = x; kick(); } }, t)));
      hintTimers.push(setTimeout(hint, 7000));
    }
    function stopHint() { interacted = true; hintTimers.forEach(clearTimeout); hintTimers = []; const b = bodies[index]; if (b && !b.drag && !pending) { b.tx = 0; kick(); } }

    layout('reset');
    return {
      startHint: () => hintTimers.push(setTimeout(hint, 1400)),
      key(e) {
        if (view !== 'swipe') return false;
        if (e.key === 'ArrowLeft') { stopHint(); commit(-1); return true; }
        if (e.key === 'ArrowRight') { stopHint(); commit(1); return true; }
        if (e.key === 'Backspace' || e.key.toLowerCase() === 'z') { stopHint(); undo(); return true; }
        return false;
      },
    };
  }

  /* ---------- Hero: demo + photo glow ---------- */
  const glowHost = $('#photoGlow');
  const glowImgs = [0, 1].map(() => { const i = document.createElement('img'); i.alt = ''; glowHost.appendChild(i); return i; });
  let glowFlip = 0, glowSrc = null;
  function setGlow(src) {
    if (src === glowSrc) return; glowSrc = src;
    if (!src) { glowImgs.forEach(i => i.classList.remove('on')); return; }
    glowFlip ^= 1;
    glowImgs[glowFlip].src = src; glowImgs[glowFlip].classList.add('on'); glowImgs[glowFlip ^ 1].classList.remove('on');
  }
  const demoScreen = $('#demoScreen');
  const demo = SwipeDemo(demoScreen, { onPhoto: setGlow, live: $('#demoLive') });
  demo.startHint();

  let heroVisible = true;
  new IntersectionObserver(([en]) => { heroVisible = en.intersectionRatio > 0.4; }, { threshold: [0, 0.4, 1] }).observe($('#demoPhone'));
  document.addEventListener('keydown', e => {
    if (!heroVisible || e.metaKey || e.ctrlKey || e.altKey) return;
    if (!(e.target === document.body || demoScreen.contains(e.target))) return;
    if (demo.key(e)) e.preventDefault();
  });

  /* ---------- Island nav ---------- */
  const burger = $('.burger'), menu = $('#menu');
  function setMenu(open) {
    burger.setAttribute('aria-expanded', String(open));
    burger.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
    menu.classList.toggle('open', open);
    menu.setAttribute('aria-hidden', String(!open));
    document.body.style.overflow = open ? 'hidden' : '';
    if (open) $('a', menu).focus();
  }
  burger.addEventListener('click', () => setMenu(burger.getAttribute('aria-expanded') !== 'true'));
  $$('a', menu).forEach(a => a.addEventListener('click', () => setMenu(false)));
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && menu.classList.contains('open')) { setMenu(false); burger.focus(); } });

  const navLinks = $$('.nav-links a');
  const sectionIO = new IntersectionObserver(ens => {
    ens.forEach(en => {
      if (!en.isIntersecting) return;
      navLinks.forEach(a => a.toggleAttribute('aria-current', a.getAttribute('href') === `#${en.target.id}`));
      navLinks.forEach(a => { if (a.hasAttribute('aria-current')) a.setAttribute('aria-current', 'true'); });
    });
  }, { rootMargin: '-45% 0px -50% 0px' });
  ['how', 'cleanup', 'pricing', 'faq', 'top', 'privacy', 'download'].forEach(id => { const s = document.getElementById(id); if (s) sectionIO.observe(s); });

  /* ---------- Scroll reveals ---------- */
  const revealIO = new IntersectionObserver(ens => ens.forEach(en => {
    if (en.isIntersecting) { en.target.classList.add('in'); revealIO.unobserve(en.target); }
  }), { rootMargin: '0px 0px -10% 0px' });
  $$('.reveal, .fan').forEach(el => revealIO.observe(el));

  /* ---------- Tagline: words light up one at a time as they cross a line ---------- */
  const tag = $('#tagline');
  (function splitWords(node) {
    [...node.childNodes].forEach(ch => {
      if (ch.nodeType === 3) {
        const frag = document.createDocumentFragment();
        ch.textContent.split(/(\s+)/).forEach(part => {
          if (!part) return;
          if (/^\s+$/.test(part)) frag.appendChild(document.createTextNode(part));
          else { const s = document.createElement('span'); s.className = 'w'; s.textContent = part; frag.appendChild(s); }
        });
        ch.replaceWith(frag);
      } else if (ch.nodeType === 1) {
        const t = ch.dataset.t;
        if (t) { ch.classList.add('w', t); } else splitWords(ch);
      }
    });
  })(tag);
  const words = $$('.w', tag);
  let tagTick = false;
  function lightWords() {
    tagTick = false;
    const line = innerHeight * 0.62;
    words.forEach(w => w.classList.toggle('on', w.getBoundingClientRect().top < line));
  }
  if (reduce) words.forEach(w => w.classList.add('on'));
  else {
    const onScroll = () => { if (!tagTick) { tagTick = true; requestAnimationFrame(lightWords); } };
    new IntersectionObserver(([en]) => {
      if (en.isIntersecting) addEventListener('scroll', onScroll, { passive: true });
      else removeEventListener('scroll', onScroll);
      lightWords();
    }).observe(tag);
  }

  /* ---------- How it works: sticky phone follows the steps ---------- */
  const storyShots = $$('#storyPhone [data-step]');
  const storyDoneHost = $('#storyDone');
  const stepDoneHost = $('#stepDone');
  const SAMPLE = {
    key: 'story', album: 'Videos', bytes: 1_240_000_000, reviewed: 38, kept: 31, deleted: 7,
    thumbs: [DECK[2], DECK[0], DECK[4], DECK[2], DECK[3], DECK[0], DECK[4]],
  };
  const storyDone = mountDone(storyDoneHost, { ...SAMPLE }, { autoplay: false });
  storyDoneHost.insertAdjacentHTML('afterbegin', `<div class="scr-bg">${CANVAS}</div>${STATUS}`);
  const stepDone = mountDone(stepDoneHost, { ...SAMPLE, key: 'step' }, { autoplay: false });
  stepDoneHost.insertAdjacentHTML('afterbegin', `<div class="scr-bg">${CANVAS}</div>${STATUS}`);

  let activeStep = 0;
  const stepIO = new IntersectionObserver(ens => ens.forEach(en => {
    if (!en.isIntersecting) return;
    const n = +en.target.dataset.step;
    if (n === activeStep) return;
    activeStep = n;
    $$('.step').forEach(s => s.classList.toggle('active', +s.dataset.step === n));
    storyShots.forEach(s => s.classList.toggle('on', +s.dataset.step === n));
    if (n === 3) storyDone.play();
  }), { rootMargin: '-45% 0px -45% 0px' });
  $$('.step').forEach(s => stepIO.observe(s));

  new IntersectionObserver(([en], obs) => {
    if (en.isIntersecting) { stepDone.play(); obs.disconnect(); }
  }, { threshold: 0.6 }).observe(stepDoneHost);

  /* ---------- Quick clean-up scan ---------- */
  const rows = $$('#cuPanel .cu-row');
  const TOTAL = 4812;
  let scanRaf = 0;
  function runScan() {
    cancelAnimationFrame(scanRaf);
    const t0 = performance.now(), dur = reduce ? 0 : 2600;
    const step = now => {
      const p = dur ? clamp01((now - t0) / dur) : 1;
      const q = 1 - Math.pow(1 - p, 3);
      rows.forEach(r => {
        const count = $('.cu-count', r), small = $('small[data-detail]', r), bar = $('.cu-bar', r);
        if (!count.dataset.to) return;
        const to = +count.dataset.to;
        count.textContent = Math.round(to * q).toLocaleString('en-GB') + (p >= 1 ? (count.dataset.suffix || '') : '');
        if (small) small.textContent = p < 1 ? `Checking ${Math.round(TOTAL * q).toLocaleString('en-GB')} of ${TOTAL.toLocaleString('en-GB')}` : small.dataset.detail;
        if (bar) { $('i', bar).style.width = `${q * 100}%`; bar.classList.toggle('done', p >= 1); }
      });
      if (p < 1) scanRaf = requestAnimationFrame(step);
    };
    scanRaf = requestAnimationFrame(step);
  }
  new IntersectionObserver(([en], obs) => { if (en.isIntersecting) { runScan(); obs.disconnect(); } }, { threshold: 0.5 }).observe($('#cuPanel'));
  $('#cuReplay').addEventListener('click', runScan);
})();
