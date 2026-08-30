(() => {
  const slides = {
    everyone: {
      headline: 'Use one finger to touch the iPhone.',
      subhead: 'Everyone joins the same quick, shared choice.',
      mode: 'together',
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
      mode: 'tap-in',
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
    pinball: {
      headline: 'Tap the seats. Then let it roll.',
      subhead: 'Two to twelve equal-area regions give every seat the same odds.',
      mode: 'pinball',
      pinball: 'setup',
      pinballTitle: '6 seats in',
      pinballDetail: 'Equal areas give every seat the same odds.',
      rings: [],
    },
    'pinball-run': {
      headline: 'A real path. A real landing.',
      subhead: 'No preselected winner—the final resting place decides.',
      mode: 'pinball',
      pinball: 'run',
      pinballTitle: 'Pinball!',
      pinballDetail: 'The final resting place decides.',
      rings: [],
    },
    'pinball-winner': {
      headline: 'Where it stops decides who starts.',
      subhead: 'The glowing seat owns the result. Play again anytime.',
      mode: 'pinball',
      pinball: 'winner',
      pinballTitle: 'Seat 4 goes first.',
      pinballDetail: 'Play again keeps the same seating.',
      rings: [],
    },
    about: {
      headline: 'Private. Offline. No accounts.',
      subhead: 'Everything happens on this iPhone—no ads or tracking.',
      mode: 'together',
      rings: [],
      about: true,
    },
  };

  const requested = new URLSearchParams(location.search).get('slide') || 'everyone';
  const name = Object.hasOwn(slides, requested) ? requested : 'everyone';
  const slide = slides[name];
  document.body.classList.add('slide-' + name);
  document.getElementById('headline').textContent = slide.headline;
  document.getElementById('subhead').textContent = slide.subhead;
  document.getElementById('app-hint').textContent = slide.hint || '';

  const modeToggle = document.getElementById('mode-toggle');
  modeToggle.dataset.mode = slide.mode;
  modeToggle.setAttribute('aria-label', slide.mode === 'tap-in' ? 'Tap In mode' : slide.mode === 'pinball' ? 'Pinball mode' : 'Together mode');
  modeToggle.setAttribute('aria-pressed', String(slide.mode !== 'together'));

  const ringContainer = document.getElementById('rings');
  for (const ringSpec of slide.rings) {
    const x = ringSpec[0];
    const y = ringSpec[1];
    const color = ringSpec[2];
    const className = ringSpec[3] || '';
    const label = ringSpec[4] || '';
    const ring = document.createElement('div');
    ring.className = ('ring ' + className).trim();
    ring.style.left = x + '%';
    ring.style.top = y + '%';
    ring.style.setProperty('--color', color);
    ring.textContent = label;
    ringContainer.appendChild(ring);
  }

  if (slide.tapIn) {
    const count = slide.count || slide.rings.length;
    document.getElementById('tap-in-dock').hidden = false;
    document.getElementById('player-count').textContent = count + ' players in';
    document.getElementById('tap-in-guidance').textContent = slide.guidance;
    document.getElementById('pick-entry').textContent = 'Pick from ' + count;
  }

  if (slide.pinball) renderPinball(slide.pinball, slide);
  if (slide.about) document.getElementById('about-card').hidden = false;

  function renderPinball(state, configuration) {
    const board = document.getElementById('pinball-board');
    const dock = document.getElementById('pinball-dock');
    // SVGElement does not reliably reflect the HTML `hidden` property. Remove
    // the attribute explicitly so the board is visible in every renderer.
    board.removeAttribute('hidden');
    dock.hidden = false;
    document.getElementById('pinball-title').textContent = configuration.pinballTitle;
    document.getElementById('pinball-detail').textContent = configuration.pinballDetail;

    const colors = ['#35e8ff', '#ff3bd4', '#adff32', '#a988ff', '#ffb23f', '#4d8dff'];
    const origin = 0.055;
    const winnerIndex = state === 'winner' ? 3 : -1;
    const regions = document.getElementById('pinball-regions');

    for (let index = 0; index < colors.length; index += 1) {
      const polygon = svgElement('polygon');
      const points = [[450, 725]];
      const samples = 32;
      for (let sample = 0; sample <= samples; sample += 1) {
        const phase = origin + (index + sample / samples) / colors.length;
        points.push(boundaryPoint(phase));
      }
      polygon.setAttribute('points', points.map(pointText).join(' '));
      polygon.setAttribute('fill', hexWithAlpha(colors[index], index === winnerIndex ? 0.34 : 0.105));
      polygon.setAttribute('stroke', index === winnerIndex ? colors[index] : 'rgba(255,255,255,0.24)');
      polygon.classList.add('pinball-region');
      if (index === winnerIndex) polygon.classList.add('winner-region');
      regions.appendChild(polygon);
    }

    const center = svgElement('circle');
    center.setAttribute('cx', '450');
    center.setAttribute('cy', '725');
    center.setAttribute('r', '7');
    center.classList.add('pinball-center');
    regions.appendChild(center);

    const seats = document.getElementById('pinball-seats');
    for (let index = 0; index < colors.length; index += 1) {
      const boundary = boundaryPoint(origin + (index + 0.5) / colors.length);
      const x = 450 + (boundary[0] - 450) * 0.73;
      const y = 725 + (boundary[1] - 725) * 0.73;
      const group = svgElement('g');
      group.classList.add('pinball-seat');
      if (index === winnerIndex) group.classList.add('winner-seat');
      group.style.setProperty('--seat-color', colors[index]);
      group.setAttribute('transform', 'translate(' + x.toFixed(1) + ' ' + y.toFixed(1) + ')');
      const circle = svgElement('circle');
      circle.setAttribute('r', '45');
      const label = svgElement('text');
      label.textContent = String(index + 1);
      label.setAttribute('y', '1');
      group.append(circle, label);
      seats.appendChild(group);
    }

    if (state === 'run' || state === 'winner') {
      const winnerBoundary = boundaryPoint(origin + (winnerIndex + 0.5) / colors.length);
      const winnerEnd = [
        450 + (winnerBoundary[0] - 450) * 0.55,
        725 + (winnerBoundary[1] - 725) * 0.55,
      ];
      const runEnd = [690, 1175];
      const endpoint = state === 'winner' ? winnerEnd : runEnd;
      const path = [
        [450, 725],
        [875, 1038],
        [630, 1425],
        [25, 982],
        [676, 25],
        [875, 210],
        [302, 1425],
        [25, 1220],
        [420, 25],
        endpoint,
      ];
      const trail = document.getElementById('pinball-trail');
      const ball = document.getElementById('pinball-ball');
      trail.setAttribute('points', path.map(pointText).join(' '));
      ball.setAttribute('cx', endpoint[0].toFixed(1));
      ball.setAttribute('cy', endpoint[1].toFixed(1));
    }

    if (state === 'winner') {
      const actions = document.querySelector('.pinball-actions');
      const buttons = actions.querySelectorAll('button');
      actions.classList.add('is-result');
      buttons[0].textContent = 'Play again';
      buttons[0].className = 'primary-action';
      buttons[1].textContent = 'New group';
      buttons[1].className = 'secondary-action';
      buttons[2].hidden = true;
      buttons[3].hidden = true;
    }
  }

  function boundaryPoint(rawPhase) {
    const phase = ((rawPhase % 1) + 1) % 1;
    const halfWidth = 450;
    const halfHeight = 725;
    const quarterUnit = halfWidth * halfHeight;
    const area = phase * 900 * 1450;
    let x;
    let y;

    if (area < 0.5 * quarterUnit) {
      const fraction = area / (0.5 * quarterUnit);
      x = halfWidth;
      y = halfHeight * fraction;
    } else if (area < 1.5 * quarterUnit) {
      const fraction = (area - 0.5 * quarterUnit) / quarterUnit;
      x = halfWidth - 2 * halfWidth * fraction;
      y = halfHeight;
    } else if (area < 2.5 * quarterUnit) {
      const fraction = (area - 1.5 * quarterUnit) / quarterUnit;
      x = -halfWidth;
      y = halfHeight - 2 * halfHeight * fraction;
    } else if (area < 3.5 * quarterUnit) {
      const fraction = (area - 2.5 * quarterUnit) / quarterUnit;
      x = -halfWidth + 2 * halfWidth * fraction;
      y = -halfHeight;
    } else {
      const fraction = (area - 3.5 * quarterUnit) / (0.5 * quarterUnit);
      x = halfWidth;
      y = -halfHeight + halfHeight * fraction;
    }

    return [450 + x, 725 + y];
  }

  function svgElement(name) {
    return document.createElementNS('http://www.w3.org/2000/svg', name);
  }

  function pointText(point) {
    return point[0].toFixed(1) + ',' + point[1].toFixed(1);
  }

  function hexWithAlpha(hex, alpha) {
    const red = parseInt(hex.slice(1, 3), 16);
    const green = parseInt(hex.slice(3, 5), 16);
    const blue = parseInt(hex.slice(5, 7), 16);
    return 'rgba(' + red + ',' + green + ',' + blue + ',' + alpha + ')';
  }
})();
