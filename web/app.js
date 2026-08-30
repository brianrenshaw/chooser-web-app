(() => {
  const mainContent = document.getElementById('main-content');
  const stage = document.getElementById('stage');
  const hint = document.getElementById('hint');
  const appChrome = document.getElementById('app-chrome');
  const modeToggleButton = document.getElementById('mode-toggle');
  const infoButton = document.getElementById('info-button');

  const tapInDock = document.getElementById('tap-in-dock');
  const playerCount = document.getElementById('player-count');
  const tapInGuidance = document.getElementById('tap-in-guidance');
  const tapInResult = document.getElementById('tap-in-result');
  const collectingActions = document.getElementById('collecting-actions');
  const resultActions = document.getElementById('result-actions');
  const undoEntryButton = document.getElementById('undo-entry');
  const clearEntriesButton = document.getElementById('clear-entries');
  const pickEntryButton = document.getElementById('pick-entry');
  const pickAgainButton = document.getElementById('pick-again');
  const newGroupButton = document.getElementById('new-group');
  const liveStatus = document.getElementById('live-status');

  const aboutBackdrop = document.getElementById('about-backdrop');
  const aboutDialog = document.getElementById('about-dialog');
  const closeAboutButton = document.getElementById('close-about');
  const togetherInstructions = document.getElementById('together-instructions');
  const tapInInstructions = document.getElementById('tap-in-instructions');

  const confirmBackdrop = document.getElementById('confirm-backdrop');
  const confirmDialog = document.getElementById('confirm-dialog');
  const confirmTitle = document.getElementById('confirm-title');
  const confirmMessage = document.getElementById('confirm-message');
  const confirmCancelButton = document.getElementById('confirm-cancel');
  const confirmAcceptButton = document.getElementById('confirm-accept');

  const WAIT_MS = 1500;
  const COUNTDOWN_MS = 1000;
  const PULSE_BASE_MS = 1200;
  const PULSE_FAST_MS = 150;
  const MAX_RAFFLE_PLAYERS = 50;
  const GOLDEN_ANGLE = 137.508;

  const MODE = {
    TOGETHER: 'TOGETHER',
    TAP_IN: 'TAP_IN',
  };

  const STATE = {
    IDLE: 'IDLE',
    WAITING: 'WAITING',
    COLLECTING: 'COLLECTING',
    COUNTDOWN: 'COUNTDOWN',
    REVEALED: 'REVEALED',
  };

  const supportsOKLCH = window.CSS?.supports?.('color', 'oklch(72% 0.28 190)') ?? false;
  const pointers = new Map();
  const rafflePending = new Map();
  const raffleEntries = [];

  let currentMode = MODE.TOGETHER;
  let state = STATE.IDLE;
  let nextRaffleId = 1;
  let nextRaffleNumber = 1;
  let raffleWinnerId = null;
  let raffleDrawSnapshot = [];
  let lastHue = Math.random() * 360;
  let waitTimer = null;
  let countdownStart = 0;
  let countdownRaf = null;
  let layoutRaf = null;
  let lastTickAt = 0;
  let revealVibrationActive = false;
  let confirmationResolver = null;
  let confirmationRestoreFocus = null;
  let announcementTimer = null;
  const feedbackTimeouts = new Set();

  function nextHue() {
    lastHue = (lastHue + GOLDEN_ANGLE) % 360;
    return lastHue;
  }

  function colorsForHue(hue) {
    return {
      ringColor: supportsOKLCH ? `oklch(72% 0.28 ${hue})` : `hsl(${hue} 100% 60%)`,
      ringGlow: supportsOKLCH ? `oklch(82% 0.22 ${hue})` : `hsl(${hue} 100% 72%)`,
    };
  }

  function applyRingColors(el, ringColor, ringGlow) {
    el.style.setProperty('--ring-color', ringColor);
    el.style.setProperty('--ring-glow', ringGlow);
  }

  function announce(message) {
    if (announcementTimer) clearTimeout(announcementTimer);
    liveStatus.textContent = '';
    announcementTimer = window.setTimeout(() => {
      announcementTimer = null;
      liveStatus.textContent = message;
    }, 10);
  }

  function clearAnnouncement() {
    if (announcementTimer) clearTimeout(announcementTimer);
    announcementTimer = null;
    liveStatus.textContent = '';
  }

  function scheduleFeedback(callback, delay) {
    const timeout = setTimeout(() => {
      feedbackTimeouts.delete(timeout);
      callback();
    }, delay);
    feedbackTimeouts.add(timeout);
  }

  function cancelScheduledFeedback() {
    for (const timeout of feedbackTimeouts) clearTimeout(timeout);
    feedbackTimeouts.clear();
    if (revealVibrationActive && navigator.vibrate) {
      try { navigator.vibrate(0); } catch (_) {}
    }
    revealVibrationActive = false;
  }

  function setPulseDuration(ms) {
    stage.style.setProperty('--pulse-duration', `${ms}ms`);
  }

  function vibrate(pattern) {
    if (!navigator.vibrate) return false;
    try { return navigator.vibrate(pattern) !== false; } catch (_) { return false; }
  }

  let audioCtx = null;
  function ensureAudio() {
    if (!audioCtx) {
      const Ctor = window.AudioContext || window.webkitAudioContext;
      if (!Ctor) return null;
      audioCtx = new Ctor();
    }
    if (audioCtx.state === 'suspended') audioCtx.resume();
    return audioCtx;
  }

  function click(opts = {}) {
    const ctx = ensureAudio();
    if (!ctx) return;
    const freq = opts.freq ?? 90;
    const dur = opts.dur ?? 0.05;
    const vol = opts.vol ?? 0.35;
    const type = opts.type ?? 'sine';
    const t0 = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(freq * 1.6, t0);
    osc.frequency.exponentialRampToValueAtTime(Math.max(40, freq), t0 + dur);
    gain.gain.setValueAtTime(0, t0);
    gain.gain.linearRampToValueAtTime(vol, t0 + 0.005);
    gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(gain).connect(ctx.destination);
    osc.start(t0);
    osc.stop(t0 + dur + 0.02);
  }

  function nativeHaptics() {
    const cap = window.Capacitor;
    if (!cap?.isNativePlatform?.()) return null;
    return cap.Plugins?.Haptics ?? null;
  }

  function fingerLandHaptic() {
    vibrate(10);
    const haptics = nativeHaptics();
    if (haptics?.impact) {
      haptics.impact({ style: 'LIGHT' }).catch(() => {});
      return;
    }
    click({ freq: 70, dur: 0.04, vol: 0.18 });
  }

  function tick(intensity) {
    vibrate(Math.round(15 + 45 * intensity));
    const haptics = nativeHaptics();
    if (haptics?.impact) {
      const style = intensity < 0.2 ? 'MEDIUM' : 'HEAVY';
      haptics.impact({ style }).catch(() => {});
      return;
    }
    click({
      freq: 70 + 180 * intensity,
      dur: 0.04 + 0.03 * intensity,
      vol: 0.18 + 0.35 * intensity,
    });
  }

  function revealHaptic() {
    revealVibrationActive = vibrate([0, 60, 70, 60, 70, 60, 240]);
    if (revealVibrationActive) {
      scheduleFeedback(() => { revealVibrationActive = false; }, 560);
    }
    const haptics = nativeHaptics();
    if (haptics?.impact) {
      [0, 70, 140, 210, 290, 380].forEach((delay) =>
        scheduleFeedback(() => haptics.impact({ style: 'HEAVY' }).catch(() => {}), delay)
      );
      if (haptics.vibrate) {
        scheduleFeedback(() => haptics.vibrate({ duration: 300 }).catch(() => {}), 420);
      }
      if (haptics.notification) {
        scheduleFeedback(() => haptics.notification({ type: 'SUCCESS' }).catch(() => {}), 760);
      }
      return;
    }
    const ctx = ensureAudio();
    if (!ctx) return;
    click({ freq: 220, dur: 0.18, vol: 0.55, type: 'triangle' });
    scheduleFeedback(() => click({ freq: 440, dur: 0.25, vol: 0.4, type: 'triangle' }), 60);
    scheduleFeedback(() => click({ freq: 660, dur: 0.35, vol: 0.3, type: 'triangle' }), 140);
  }

  function cancelTimers() {
    if (waitTimer) {
      clearTimeout(waitTimer);
      waitTimer = null;
    }
    if (countdownRaf) {
      cancelAnimationFrame(countdownRaf);
      countdownRaf = null;
    }
    cancelScheduledFeedback();
  }

  function randomIndex(length) {
    if (!window.crypto?.getRandomValues) return Math.floor(Math.random() * length);
    const values = new Uint32Array(1);
    const limit = Math.floor(0x100000000 / length) * length;
    do {
      window.crypto.getRandomValues(values);
    } while (values[0] >= limit);
    return values[0] % length;
  }

  function setAppInert(isInert) {
    mainContent.inert = isInert;
    appChrome.inert = isInert;
    tapInDock.inert = isInert;
    mainContent.setAttribute('aria-hidden', String(isInert));
    appChrome.setAttribute('aria-hidden', String(isInert));
    tapInDock.setAttribute('aria-hidden', String(isInert || currentMode !== MODE.TAP_IN));
    if (!isInert) {
      mainContent.removeAttribute('aria-hidden');
      appChrome.removeAttribute('aria-hidden');
      if (currentMode === MODE.TAP_IN) tapInDock.removeAttribute('aria-hidden');
    }
  }

  function updateModeToggle() {
    const tapInSelected = currentMode === MODE.TAP_IN;
    modeToggleButton.setAttribute('aria-pressed', String(tapInSelected));
    modeToggleButton.title = tapInSelected ? 'Switch to Together' : 'Switch to Tap In';
    modeToggleButton.disabled = state === STATE.COUNTDOWN || rafflePending.size > 0;
    infoButton.disabled = state === STATE.COUNTDOWN;
  }

  function updateBodyState() {
    const together = currentMode === MODE.TOGETHER;
    const interactionActive = together
      ? pointers.size > 0 || state === STATE.WAITING || state === STATE.COUNTDOWN
      : state === STATE.COUNTDOWN;
    document.body.classList.toggle('mode-together', together);
    document.body.classList.toggle('mode-tap-in', !together);
    document.body.classList.toggle('interaction-active', interactionActive);
    document.body.classList.toggle('countdown-active', state === STATE.COUNTDOWN);
    document.body.classList.toggle('tap-result', !together && state === STATE.REVEALED);
  }

  function updateStageClasses() {
    stage.classList.toggle('has-fingers', pointers.size > 0);
    stage.classList.toggle('has-raffle-entries', raffleEntries.length > 0);
    stage.classList.toggle('has-pending-entry', rafflePending.size > 0);
    stage.classList.toggle('is-revealed', state === STATE.REVEALED);
  }

  function renderTapInControls() {
    const isTapIn = currentMode === MODE.TAP_IN;
    tapInDock.hidden = !isTapIn;
    if (!isTapIn) return;

    const count = raffleEntries.length;
    const collecting = state === STATE.COLLECTING;
    const drawing = state === STATE.COUNTDOWN;
    const revealed = state === STATE.REVEALED;
    const pending = rafflePending.size > 0;

    playerCount.textContent = `${count} ${count === 1 ? 'player' : 'players'} in`;
    playerCount.hidden = revealed;
    tapInGuidance.hidden = revealed;
    tapInResult.hidden = !revealed;
    collectingActions.hidden = revealed;
    resultActions.hidden = !revealed;

    if (revealed) {
      const winner = raffleEntries.find((entry) => entry.id === raffleWinnerId);
      tapInResult.textContent = winner ? `Player ${winner.number} goes first.` : '';
    } else if (drawing) {
      tapInGuidance.textContent = 'Choosing…';
    } else if (count >= MAX_RAFFLE_PLAYERS) {
      tapInGuidance.textContent = '50-player limit reached. Pick when ready.';
    } else if (count === 0) {
      tapInGuidance.textContent = 'Each player taps once.';
    } else if (count === 1) {
      tapInGuidance.textContent = 'Add at least one more.';
    } else {
      tapInGuidance.textContent = 'Keep tapping, or pick when ready.';
    }

    pickEntryButton.textContent = drawing ? 'Choosing…' : `Pick from ${count}`;
    undoEntryButton.disabled = !collecting || count === 0 || pending;
    clearEntriesButton.disabled = !collecting || count === 0 || pending;
    pickEntryButton.disabled = !collecting || count < 2 || pending;
  }

  function renderApp() {
    updateModeToggle();
    updateBodyState();
    updateStageClasses();
    renderTapInControls();

    const isTapIn = currentMode === MODE.TAP_IN;
    togetherInstructions.hidden = isTapIn;
    tapInInstructions.hidden = !isTapIn;
    const entrySurfaceActive = isTapIn && state === STATE.COLLECTING;
    stage.tabIndex = entrySurfaceActive ? 0 : -1;
    if (entrySurfaceActive) {
      stage.setAttribute('role', 'button');
      stage.setAttribute('aria-label', 'Tap once to add a player');
      stage.setAttribute('aria-describedby', 'hint');
    } else {
      stage.removeAttribute('role');
      stage.removeAttribute('aria-label');
      stage.removeAttribute('aria-describedby');
    }
  }

  function clearFingerRings() {
    for (const pointer of pointers.values()) pointer.el.remove();
    pointers.clear();
    updateStageClasses();
  }

  function addFingerRing(id, x, y) {
    const el = document.createElement('div');
    el.className = 'ring finger-ring';
    el.style.left = `${x}px`;
    el.style.top = `${y}px`;
    const hue = nextHue();
    const { ringColor, ringGlow } = colorsForHue(hue);
    applyRingColors(el, ringColor, ringGlow);
    stage.appendChild(el);
    pointers.set(id, { el, x, y, hue });
    fingerLandHaptic();
    renderApp();
  }

  function moveFingerRing(id, x, y) {
    const pointer = pointers.get(id);
    if (!pointer) return;
    pointer.x = x;
    pointer.y = y;
    pointer.el.style.left = `${x}px`;
    pointer.el.style.top = `${y}px`;
  }

  function removeFingerRing(id) {
    const pointer = pointers.get(id);
    if (!pointer) return;
    pointer.el.remove();
    pointers.delete(id);
    renderApp();
  }

  function enterTogetherIdle() {
    cancelTimers();
    state = STATE.IDLE;
    setPulseDuration(PULSE_BASE_MS);
    hint.textContent = 'Place two or more fingers.';
    renderApp();
  }

  function enterTogetherWaiting() {
    cancelTimers();
    state = STATE.WAITING;
    setPulseDuration(PULSE_BASE_MS);
    renderApp();
    waitTimer = setTimeout(() => {
      if (currentMode === MODE.TOGETHER && state === STATE.WAITING && pointers.size >= 2) {
        startCountdown(MODE.TOGETHER, revealTogetherWinner);
      }
    }, WAIT_MS);
  }

  function startCountdown(expectedMode, completion) {
    cancelTimers();
    state = STATE.COUNTDOWN;
    countdownStart = performance.now();
    lastTickAt = 0;
    setPulseDuration(PULSE_BASE_MS);
    renderApp();

    const step = (now) => {
      if (currentMode !== expectedMode || state !== STATE.COUNTDOWN) return;
      const progress = Math.min(1, (now - countdownStart) / COUNTDOWN_MS);
      const eased = progress * progress;
      const duration = PULSE_BASE_MS + (PULSE_FAST_MS - PULSE_BASE_MS) * eased;
      setPulseDuration(duration);
      const tickInterval = Math.max(60, duration);
      if (now - lastTickAt >= tickInterval) {
        lastTickAt = now;
        tick(eased);
      }
      if (progress >= 1) {
        countdownRaf = null;
        completion();
        return;
      }
      countdownRaf = requestAnimationFrame(step);
    };
    countdownRaf = requestAnimationFrame(step);
  }

  function revealTogetherWinner() {
    cancelTimers();
    state = STATE.REVEALED;
    const entries = Array.from(pointers.values());
    if (entries.length === 0) {
      enterTogetherIdle();
      return;
    }
    const winner = entries[randomIndex(entries.length)];
    for (const pointer of entries) {
      if (pointer === winner) pointer.el.classList.add('winner');
      else pointer.el.classList.add('loser');
    }
    hint.textContent = 'Lift, then place fingers to choose again.';
    revealHaptic();
    renderApp();
  }

  function handleTogetherPointerDown(event) {
    event.preventDefault();
    ensureAudio();
    if (state === STATE.REVEALED) {
      clearFingerRings();
      enterTogetherIdle();
      addFingerRing(event.pointerId, event.clientX, event.clientY);
      return;
    }

    addFingerRing(event.pointerId, event.clientX, event.clientY);
    if (state === STATE.IDLE) {
      if (pointers.size >= 2) enterTogetherWaiting();
    } else if (state === STATE.WAITING) {
      enterTogetherWaiting();
    } else if (state === STATE.COUNTDOWN) {
      enterTogetherWaiting();
    }
  }

  function handleTogetherPointerMove(event) {
    if (!pointers.has(event.pointerId)) return;
    event.preventDefault();
    moveFingerRing(event.pointerId, event.clientX, event.clientY);
  }

  function handleTogetherPointerEnd(event) {
    if (!pointers.has(event.pointerId)) return;
    event.preventDefault();
    if (state === STATE.REVEALED) return;

    removeFingerRing(event.pointerId);
    if (state === STATE.WAITING) {
      if (pointers.size < 2) enterTogetherIdle();
      else enterTogetherWaiting();
    } else if (state === STATE.COUNTDOWN && pointers.size < 2) {
      enterTogetherIdle();
    }
  }

  function preferredRaffleRingSize(count) {
    if (count <= 5) return 140;
    return Math.max(44, Math.round(140 * Math.sqrt(5 / count)));
  }

  function getRafflePlayfield() {
    const chromeRect = appChrome.getBoundingClientRect();
    const dockRect = tapInDock.getBoundingClientRect();
    const chromeStyle = getComputedStyle(appChrome);
    const sidePadding = Math.max(
      16,
      Number.parseFloat(chromeStyle.paddingLeft) || 0,
      Number.parseFloat(chromeStyle.paddingRight) || 0
    );
    const left = sidePadding;
    const right = Math.max(left + 1, window.innerWidth - sidePadding);
    const top = Math.max(16, chromeRect.bottom + 8);
    const bottom = Math.max(top + 1, Math.min(window.innerHeight - 16, dockRect.top - 8));
    const field = {
      left,
      top,
      width: right - left,
      height: bottom - top,
    };
    field.centerX = field.left + field.width / 2;
    field.centerY = field.top + field.height / 2;
    stage.style.setProperty('--playfield-center-x', `${field.centerX}px`);
    stage.style.setProperty('--playfield-center-y', `${field.centerY}px`);
    return field;
  }

  function chooseGrid(count, field) {
    const preferred = preferredRaffleRingSize(count);
    const gap = count >= 30 ? 6 : count >= 12 ? 8 : 12;
    const fieldRatio = field.width / Math.max(1, field.height);
    let best = null;

    for (let columns = 1; columns <= count; columns += 1) {
      const rows = Math.ceil(count / columns);
      const cellWidth = field.width / columns;
      const cellHeight = field.height / rows;
      const diameter = Math.min(preferred, cellWidth - gap, cellHeight - gap);
      if (diameter <= 0) continue;
      const emptySlots = rows * columns - count;
      const shapePenalty = Math.abs(columns / rows - fieldRatio);
      const candidate = { columns, rows, cellWidth, cellHeight, diameter, emptySlots, shapePenalty };
      if (
        !best ||
        candidate.diameter > best.diameter + 0.5 ||
        (Math.abs(candidate.diameter - best.diameter) <= 0.5 && candidate.emptySlots < best.emptySlots) ||
        (
          Math.abs(candidate.diameter - best.diameter) <= 0.5 &&
          candidate.emptySlots === best.emptySlots &&
          candidate.shapePenalty < best.shapePenalty
        )
      ) {
        best = candidate;
      }
    }
    return best;
  }

  function applyRaffleRingSize(el, diameter) {
    const safeDiameter = Math.max(36, Math.floor(diameter));
    el.style.setProperty('--raffle-size', `${safeDiameter}px`);
    el.style.setProperty('--raffle-stroke', `${Math.max(2, safeDiameter * 3 / 140).toFixed(2)}px`);
    el.style.setProperty('--raffle-glow', `${Math.max(10, safeDiameter * 24 / 140).toFixed(1)}px`);
    el.style.setProperty('--raffle-font-size', `${Math.max(13, Math.min(34, safeDiameter * 0.27)).toFixed(1)}px`);
  }

  function layoutRaffleEntries() {
    layoutRaf = null;
    if (currentMode !== MODE.TAP_IN) return;
    const field = getRafflePlayfield();
    const count = raffleEntries.length;
    if (count === 0) return;

    if (state === STATE.REVEALED && raffleWinnerId !== null) {
      const heroDiameter = Math.min(140, Math.max(36, Math.min(field.width, field.height) - 20));
      for (const entry of raffleEntries) {
        if (entry.id !== raffleWinnerId) continue;
        entry.el.style.left = `${field.centerX}px`;
        entry.el.style.top = `${field.centerY}px`;
        applyRaffleRingSize(entry.el, heroDiameter);
      }
      return;
    }

    const grid = chooseGrid(count, field);
    if (!grid) return;
    for (let index = 0; index < count; index += 1) {
      const row = Math.floor(index / grid.columns);
      const indexInRow = index % grid.columns;
      const remaining = count - row * grid.columns;
      const itemsInRow = Math.min(grid.columns, remaining);
      const rowWidth = itemsInRow * grid.cellWidth;
      const rowStart = field.left + (field.width - rowWidth) / 2;
      const x = rowStart + grid.cellWidth * (indexInRow + 0.5);
      const y = field.top + grid.cellHeight * (row + 0.5);
      const entry = raffleEntries[index];
      entry.el.style.left = `${x}px`;
      entry.el.style.top = `${y}px`;
      applyRaffleRingSize(entry.el, grid.diameter);
    }
  }

  function requestRaffleLayout() {
    if (layoutRaf) cancelAnimationFrame(layoutRaf);
    layoutRaf = requestAnimationFrame(layoutRaffleEntries);
  }

  function clearPendingRaffleTouches() {
    for (const pending of rafflePending.values()) pending.el.remove();
    rafflePending.clear();
    renderApp();
  }

  function stripRaffleResultStyles() {
    for (const entry of raffleEntries) {
      entry.el.classList.remove('tap-winner', 'tap-loser');
    }
  }

  function clearRaffleEntries() {
    clearPendingRaffleTouches();
    for (const entry of raffleEntries) entry.el.remove();
    raffleEntries.length = 0;
    nextRaffleId = 1;
    nextRaffleNumber = 1;
    raffleWinnerId = null;
    raffleDrawSnapshot = [];
    if (layoutRaf) {
      cancelAnimationFrame(layoutRaf);
      layoutRaf = null;
    }
    renderApp();
  }

  function enterRaffleCollecting() {
    cancelTimers();
    state = STATE.COLLECTING;
    raffleWinnerId = null;
    raffleDrawSnapshot = [];
    stripRaffleResultStyles();
    setPulseDuration(PULSE_BASE_MS);
    hint.textContent = 'Each player taps once.';
    renderApp();
    requestRaffleLayout();
  }

  function createPendingRaffleRing(pointerId, x, y) {
    const el = document.createElement('div');
    el.className = 'ring raffle-ring raffle-pending';
    el.setAttribute('aria-hidden', 'true');
    el.style.left = `${x}px`;
    el.style.top = `${y}px`;
    const hue = (lastHue + GOLDEN_ANGLE) % 360;
    const { ringColor, ringGlow } = colorsForHue(hue);
    applyRingColors(el, ringColor, ringGlow);
    stage.appendChild(el);
    rafflePending.set(pointerId, { el, x, y });
    fingerLandHaptic();
    renderApp();
  }

  function commitRaffleEntry(el) {
    const id = nextRaffleId;
    nextRaffleId += 1;
    const number = nextRaffleNumber;
    nextRaffleNumber += 1;
    const hue = nextHue();
    const { ringColor, ringGlow } = colorsForHue(hue);
    el.classList.remove('raffle-pending');
    el.textContent = String(number);
    applyRingColors(el, ringColor, ringGlow);
    const entry = {
      id,
      number,
      hue,
      ringColor,
      ringGlow,
      el,
    };
    raffleEntries.push(entry);
    announce(`Player ${entry.number} added. ${raffleEntries.length} players total.`);
    renderApp();
    requestRaffleLayout();
    return entry;
  }

  function addKeyboardRaffleEntry() {
    if (currentMode !== MODE.TAP_IN || state !== STATE.COLLECTING) return;
    if (raffleEntries.length + rafflePending.size >= MAX_RAFFLE_PLAYERS) {
      announce('50-player limit reached. Pick when ready.');
      renderApp();
      return;
    }
    ensureAudio();
    const field = getRafflePlayfield();
    const el = document.createElement('div');
    el.className = 'ring raffle-ring';
    el.setAttribute('aria-hidden', 'true');
    el.style.left = `${field.centerX}px`;
    el.style.top = `${field.centerY}px`;
    stage.appendChild(el);
    fingerLandHaptic();
    commitRaffleEntry(el);
  }

  function handleRafflePointerDown(event) {
    if (state !== STATE.COLLECTING) return;
    event.preventDefault();
    ensureAudio();
    if (raffleEntries.length + rafflePending.size >= MAX_RAFFLE_PLAYERS) {
      announce('50-player limit reached. Pick when ready.');
      renderApp();
      return;
    }
    try { stage.setPointerCapture(event.pointerId); } catch (_) {}
    createPendingRaffleRing(event.pointerId, event.clientX, event.clientY);
  }

  function handleRafflePointerMove(event) {
    const pending = rafflePending.get(event.pointerId);
    if (!pending) return;
    event.preventDefault();
    pending.x = event.clientX;
    pending.y = event.clientY;
    pending.el.style.left = `${event.clientX}px`;
    pending.el.style.top = `${event.clientY}px`;
  }

  function handleRafflePointerUp(event) {
    const pending = rafflePending.get(event.pointerId);
    if (!pending) return;
    event.preventDefault();
    rafflePending.delete(event.pointerId);
    try { stage.releasePointerCapture(event.pointerId); } catch (_) {}
    if (currentMode !== MODE.TAP_IN || state !== STATE.COLLECTING) {
      pending.el.remove();
      renderApp();
      return;
    }
    commitRaffleEntry(pending.el);
  }

  function handleRafflePointerCancel(event) {
    const pending = rafflePending.get(event.pointerId);
    if (!pending) return;
    event.preventDefault();
    pending.el.remove();
    rafflePending.delete(event.pointerId);
    renderApp();
  }

  function undoRaffleEntry() {
    if (currentMode !== MODE.TAP_IN || state !== STATE.COLLECTING || rafflePending.size > 0) return;
    const removed = raffleEntries.pop();
    if (!removed) return;
    removed.el.remove();
    nextRaffleNumber = removed.number;
    announce(`Player ${removed.number} removed. ${raffleEntries.length} players total.`);
    renderApp();
    requestRaffleLayout();
  }

  function startRaffleDraw() {
    const validPhase = state === STATE.COLLECTING || state === STATE.REVEALED;
    if (
      currentMode !== MODE.TAP_IN ||
      !validPhase ||
      raffleEntries.length < 2 ||
      rafflePending.size > 0
    ) {
      return;
    }
    stripRaffleResultStyles();
    raffleWinnerId = null;
    raffleDrawSnapshot = raffleEntries.slice();
    announce(`Drawing from ${raffleDrawSnapshot.length} players.`);
    requestRaffleLayout();
    startCountdown(MODE.TAP_IN, revealRaffleWinner);
  }

  function revealRaffleWinner() {
    cancelTimers();
    if (currentMode !== MODE.TAP_IN || raffleDrawSnapshot.length === 0) {
      enterRaffleCollecting();
      return;
    }
    const winner = raffleDrawSnapshot[randomIndex(raffleDrawSnapshot.length)];
    raffleWinnerId = winner.id;
    state = STATE.REVEALED;
    for (const entry of raffleEntries) {
      if (entry.id === raffleWinnerId) entry.el.classList.add('tap-winner');
      else entry.el.classList.add('tap-loser');
    }
    announce(`Player ${winner.number} goes first.`);
    revealHaptic();
    renderApp();
    requestRaffleLayout();
    requestAnimationFrame(() => pickAgainButton.focus());
  }

  function startNewRaffleGroup() {
    if (currentMode !== MODE.TAP_IN) return;
    clearRaffleEntries();
    enterRaffleCollecting();
    announce('New group ready. Each player taps once.');
    stage.focus();
  }

  function handleStagePointerDown(event) {
    if (currentMode === MODE.TOGETHER) handleTogetherPointerDown(event);
    else handleRafflePointerDown(event);
  }

  function handleStagePointerMove(event) {
    if (currentMode === MODE.TOGETHER) handleTogetherPointerMove(event);
    else handleRafflePointerMove(event);
  }

  function handleStagePointerUp(event) {
    if (currentMode === MODE.TOGETHER) handleTogetherPointerEnd(event);
    else handleRafflePointerUp(event);
  }

  function handleStagePointerCancel(event) {
    if (currentMode === MODE.TOGETHER) handleTogetherPointerEnd(event);
    else handleRafflePointerCancel(event);
  }

  function switchMode(nextMode) {
    if (nextMode === currentMode) return;
    clearAnnouncement();
    cancelTimers();
    clearFingerRings();
    clearPendingRaffleTouches();
    if (nextMode === MODE.TOGETHER) {
      clearRaffleEntries();
      currentMode = MODE.TOGETHER;
      enterTogetherIdle();
    } else {
      currentMode = MODE.TAP_IN;
      state = STATE.IDLE;
      enterRaffleCollecting();
    }
    renderApp();
    announce(nextMode === MODE.TAP_IN ? 'Tap In mode.' : 'Together mode.');
  }

  async function requestModeSwitch(nextMode) {
    if (nextMode === currentMode || state === STATE.COUNTDOWN || rafflePending.size > 0) return;
    cancelScheduledFeedback();
    if (currentMode === MODE.TAP_IN && raffleEntries.length > 0) {
      const count = raffleEntries.length;
      const confirmed = await showConfirmation({
        title: 'Switch to Together?',
        message: `This clears ${count} ${count === 1 ? 'player' : 'players'}.`,
        cancelLabel: 'Cancel',
        acceptLabel: 'Switch',
      });
      if (!confirmed) return;
    }
    switchMode(nextMode);
  }

  function closeConfirmation(accepted) {
    if (confirmBackdrop.hidden) return;
    const resolve = confirmationResolver;
    const restoreFocus = confirmationRestoreFocus;
    confirmationResolver = null;
    confirmationRestoreFocus = null;
    confirmBackdrop.hidden = true;
    document.body.classList.remove('confirm-open');
    setAppInert(false);
    if (restoreFocus?.isConnected) restoreFocus.focus();
    if (resolve) resolve(accepted);
  }

  function showConfirmation({ title, message, cancelLabel, acceptLabel }) {
    if (!aboutBackdrop.hidden || !confirmBackdrop.hidden) return Promise.resolve(false);
    confirmTitle.textContent = title;
    confirmMessage.textContent = message;
    confirmCancelButton.textContent = cancelLabel;
    confirmAcceptButton.textContent = acceptLabel;
    confirmationRestoreFocus = document.activeElement;
    confirmBackdrop.hidden = false;
    document.body.classList.add('confirm-open');
    setAppInert(true);
    confirmDialog.focus();
    return new Promise((resolve) => {
      confirmationResolver = resolve;
    });
  }

  async function confirmClearRaffleEntries() {
    if (state !== STATE.COLLECTING || raffleEntries.length === 0 || rafflePending.size > 0) return;
    const count = raffleEntries.length;
    const confirmed = await showConfirmation({
      title: `Clear ${count} ${count === 1 ? 'player' : 'players'}?`,
      message: 'Everyone will need to tap in again.',
      cancelLabel: 'Keep players',
      acceptLabel: 'Clear',
    });
    if (!confirmed) return;
    clearRaffleEntries();
    enterRaffleCollecting();
    announce('All players cleared.');
    stage.focus();
  }

  function openAbout() {
    if (state === STATE.COUNTDOWN) return;
    if (currentMode === MODE.TOGETHER) {
      clearFingerRings();
      enterTogetherIdle();
    } else {
      clearPendingRaffleTouches();
      cancelScheduledFeedback();
    }
    togetherInstructions.hidden = currentMode !== MODE.TOGETHER;
    tapInInstructions.hidden = currentMode !== MODE.TAP_IN;
    aboutBackdrop.hidden = false;
    document.body.classList.add('about-open');
    setAppInert(true);
    aboutDialog.focus();
  }

  function closeAbout() {
    if (aboutBackdrop.hidden) return;
    aboutBackdrop.hidden = true;
    document.body.classList.remove('about-open');
    setAppInert(false);
    infoButton.focus();
    if (currentMode === MODE.TAP_IN) requestRaffleLayout();
  }

  function trapDialogFocus(event, dialog, closeAction) {
    if (event.key === 'Escape') {
      event.preventDefault();
      closeAction();
      return;
    }
    if (event.key !== 'Tab') return;
    const focusable = Array.from(dialog.querySelectorAll('a[href], button:not([disabled])'));
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (!first || !last) {
      event.preventDefault();
      dialog.focus();
    } else if (event.shiftKey && (document.activeElement === first || document.activeElement === dialog)) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault();
      first.focus();
    } else if (!dialog.contains(document.activeElement)) {
      event.preventDefault();
      first.focus();
    }
  }

  stage.addEventListener('pointerdown', handleStagePointerDown);
  stage.addEventListener('pointermove', handleStagePointerMove);
  stage.addEventListener('pointerup', handleStagePointerUp);
  stage.addEventListener('pointercancel', handleStagePointerCancel);
  stage.addEventListener('keydown', (event) => {
    if (currentMode !== MODE.TAP_IN || (event.key !== 'Enter' && event.key !== ' ')) return;
    event.preventDefault();
    if (event.repeat) return;
    addKeyboardRaffleEntry();
  });

  modeToggleButton.addEventListener('click', () => {
    const nextMode = currentMode === MODE.TOGETHER ? MODE.TAP_IN : MODE.TOGETHER;
    requestModeSwitch(nextMode);
  });
  undoEntryButton.addEventListener('click', undoRaffleEntry);
  clearEntriesButton.addEventListener('click', confirmClearRaffleEntries);
  pickEntryButton.addEventListener('click', startRaffleDraw);
  pickAgainButton.addEventListener('click', startRaffleDraw);
  newGroupButton.addEventListener('click', startNewRaffleGroup);

  infoButton.addEventListener('click', openAbout);
  closeAboutButton.addEventListener('click', closeAbout);
  aboutBackdrop.addEventListener('click', (event) => {
    if (event.target === aboutBackdrop) closeAbout();
  });

  confirmCancelButton.addEventListener('click', () => closeConfirmation(false));
  confirmAcceptButton.addEventListener('click', () => closeConfirmation(true));
  confirmBackdrop.addEventListener('click', (event) => {
    if (event.target === confirmBackdrop) closeConfirmation(false);
  });

  document.addEventListener('keydown', (event) => {
    if (!confirmBackdrop.hidden) {
      trapDialogFocus(event, confirmDialog, () => closeConfirmation(false));
    } else if (!aboutBackdrop.hidden) {
      trapDialogFocus(event, aboutDialog, closeAbout);
    }
  });

  document.addEventListener('visibilitychange', () => {
    if (!document.hidden) return;
    if (currentMode === MODE.TOGETHER) {
      clearFingerRings();
      enterTogetherIdle();
      return;
    }

    clearPendingRaffleTouches();
    if (state === STATE.COUNTDOWN) {
      enterRaffleCollecting();
      announce('Draw canceled. Pick again when ready.');
    } else {
      cancelScheduledFeedback();
      renderApp();
    }
  });

  window.addEventListener('resize', () => {
    if (currentMode === MODE.TAP_IN) requestRaffleLayout();
  });
  window.addEventListener('orientationchange', () => {
    if (currentMode === MODE.TAP_IN) requestRaffleLayout();
  });

  document.addEventListener('contextmenu', (event) => event.preventDefault());
  document.addEventListener('gesturestart', (event) => event.preventDefault());

  setPulseDuration(PULSE_BASE_MS);
  enterTogetherIdle();
})();
