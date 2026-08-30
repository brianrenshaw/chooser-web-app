(() => {
  const slides = {
    everyone: {
      headline: 'Everyone puts a finger in.',
      subhead: 'One phone. One shared moment. No setup.',
      hint: '',
      rings: [
        [28, 28, '#35e8ff'],
        [72, 32, '#ff3bd4'],
        [32, 69, '#adff32'],
        [72, 73, '#a988ff'],
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
  for (const [x, y, color, className = ''] of slide.rings) {
    const ring = document.createElement('div');
    ring.className = `ring ${className}`.trim();
    ring.style.left = `${x}%`;
    ring.style.top = `${y}%`;
    ring.style.setProperty('--color', color);
    ringContainer.appendChild(ring);
  }

  if (slide.about) document.getElementById('about-card').hidden = false;
})();
