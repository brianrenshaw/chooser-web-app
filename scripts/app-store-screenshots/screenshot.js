(() => {
  const slides = {
    everyone: {
      headline: 'Use one finger to touch the iPhone.',
      subhead: 'Everyone joins the same quick, shared choice.',
      hint: '',
      rings: [
        [28, 28, '#35e8ff'],
        [72, 32, '#ff3bd4'],
        [32, 69, '#adff32'],
        [72, 73, '#a988ff'],
      ],
    },
    'tap-in': {
      headline: 'Big group? Take turns tapping.',
      subhead: 'Each player taps once. Then pick from the full group.',
      hint: '',
      tapIn: true,
      count: 12,
      guidance: 'Keep tapping, or pick when ready.',
      rings: [
        [24, 20, '#35e8ff', 'raffle', '1'],
        [50, 20, '#ff3bd4', 'raffle', '2'],
        [76, 20, '#adff32', 'raffle', '3'],
        [24, 36, '#a988ff', 'raffle', '4'],
        [50, 36, '#ffb23f', 'raffle', '5'],
        [76, 36, '#35e8ff', 'raffle', '6'],
        [24, 52, '#ff3bd4', 'raffle', '7'],
        [50, 52, '#adff32', 'raffle', '8'],
        [76, 52, '#a988ff', 'raffle', '9'],
        [24, 68, '#ffb23f', 'raffle', '10'],
        [50, 68, '#35e8ff', 'raffle', '11'],
        [76, 68, '#ff3bd4', 'raffle', '12'],
      ],
    },
    countdown: {
      headline: 'Hold on. The tension builds.',
      subhead: 'Color, motion, and iPhone haptics make the choice feel big.',
      hint: '',
      rings: [
        [30, 30, '#35e8ff'],
        [70, 35, '#ff3bd4'],
        [31, 70, '#adff32'],
        [71, 72, '#ffb23f'],
      ],
    },
    winner: {
      headline: "One fair choice. That's who's first.",
      subhead: 'On-device randomness picks one person—then you can go again.',
      hint: 'Lift, then place fingers to choose again.',
      rings: [
        [29, 29, '#35e8ff', 'loser'],
        [70, 34, '#ff3bd4', 'winner'],
        [32, 70, '#adff32', 'loser'],
        [72, 72, '#a988ff', 'loser'],
      ],
    },
    about: {
      headline: 'No setup. No accounts. Just choose.',
      subhead: 'Private, focused, and completely offline.',
      hint: '',
      rings: [],
      about: true,
    },
  };

  const requested = new URLSearchParams(location.search).get('slide') || 'everyone';
  const name = Object.hasOwn(slides, requested) ? requested : 'everyone';
  const slide = slides[name];
  document.body.classList.add(`slide-${name}`);
  document.getElementById('headline').textContent = slide.headline;
  document.getElementById('subhead').textContent = slide.subhead;
  document.getElementById('app-hint').textContent = slide.hint;

  const ringContainer = document.getElementById('rings');
  for (const [x, y, color, className = '', label = ''] of slide.rings) {
    const ring = document.createElement('div');
    ring.className = `ring ${className}`.trim();
    ring.style.left = `${x}%`;
    ring.style.top = `${y}%`;
    ring.style.setProperty('--color', color);
    ring.textContent = label;
    ringContainer.appendChild(ring);
  }

  const modeToggle = document.getElementById('mode-toggle');
  modeToggle.setAttribute('aria-pressed', String(Boolean(slide.tapIn)));

  if (slide.tapIn) {
    const count = slide.count ?? slide.rings.length;
    document.getElementById('tap-in-dock').hidden = false;
    document.getElementById('player-count').textContent = `${count} players in`;
    document.getElementById('tap-in-guidance').textContent = slide.guidance;
    document.getElementById('pick-entry').textContent = `Pick from ${count}`;
  }

  if (slide.about) document.getElementById('about-card').hidden = false;
})();
