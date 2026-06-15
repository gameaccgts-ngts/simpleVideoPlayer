document.addEventListener('DOMContentLoaded', function () {
    const video = document.getElementById('video');
    const listEl = document.getElementById('playlist');
    const searchEl = document.getElementById('search');
    const filtersEl = document.getElementById('filters');
    const countEl = document.getElementById('count');
    const noResultsEl = document.getElementById('no-results');
    const nowTitleEl = document.getElementById('now-title');
    const prevBtn = document.getElementById('prev-btn');
    const nextBtn = document.getElementById('next-btn');
    const emptyState = document.getElementById('empty-state');
    const errorState = document.getElementById('error-state');

    // The story list now lives in videos.json — edit that file to add/remove videos,
    // no code changes needed. Each entry: { name, src, category }.
    const STORAGE_KEY = 'ipd-last-video';
    let videos = [];
    let categories = [];
    let activeCategory = 'All';
    let query = '';
    let currentSrc = null;

    // ---- Build category filter chips ----
    function buildFilters() {
        filtersEl.innerHTML = '';
        categories.forEach((cat) => {
            const btn = document.createElement('button');
            btn.className = 'chip' + (cat === activeCategory ? ' active' : '');
            btn.type = 'button';
            btn.textContent = cat;
            btn.setAttribute('role', 'tab');
            btn.addEventListener('click', () => {
                activeCategory = cat;
                filtersEl.querySelectorAll('.chip').forEach(c => c.classList.toggle('active', c === btn));
                render();
            });
            filtersEl.appendChild(btn);
        });
    }

    // ---- Render the playlist (respecting search + category) ----
    function render() {
        const q = query.trim().toLowerCase();
        const matches = videos.filter(v =>
            (activeCategory === 'All' || v.category === activeCategory) &&
            (q === '' || v.name.toLowerCase().includes(q) || v.category.toLowerCase().includes(q))
        );

        listEl.innerHTML = '';
        let lastCategory = null;

        matches.forEach((v) => {
            // Group heading (only when not searching within a single category view)
            if (activeCategory === 'All' && v.category !== lastCategory) {
                const heading = document.createElement('li');
                heading.className = 'group-heading';
                heading.textContent = v.category;
                listEl.appendChild(heading);
                lastCategory = v.category;
            }

            const li = document.createElement('li');
            li.className = 'item' + (v.src === currentSrc ? ' playing' : '');
            li.tabIndex = 0;
            li.dataset.src = v.src;
            li.innerHTML =
                '<span class="item-icon" aria-hidden="true">' +
                (v.src === currentSrc ? '❚❚' : '▶') + '</span>' +
                '<span class="item-name"></span>';
            li.querySelector('.item-name').textContent = v.name;

            const play = () => selectVideo(v.src, true);
            li.addEventListener('click', play);
            li.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); play(); }
            });
            listEl.appendChild(li);
        });

        countEl.textContent = matches.length;
        noResultsEl.hidden = matches.length > 0;
    }

    // ---- Load + (optionally) play a video ----
    function selectVideo(src, autoplay) {
        const meta = videos.find(v => v.src === src);
        if (!meta) return;

        currentSrc = src;
        video.src = src;
        video.load();

        nowTitleEl.textContent = meta.category + ' · ' + meta.name;
        emptyState.hidden = true;
        errorState.hidden = true;
        video.hidden = false;

        localStorage.setItem(STORAGE_KEY, src);
        updateNavButtons();
        render();

        if (autoplay) {
            const p = video.play();
            if (p && typeof p.catch === 'function') p.catch(() => {/* autoplay may be blocked */});
        }
    }

    // ---- Prev / Next across the full list ----
    function move(step) {
        const idx = videos.findIndex(v => v.src === currentSrc);
        if (idx === -1) return;
        const next = videos[idx + step];
        if (next) selectVideo(next.src, true);
    }

    function updateNavButtons() {
        const idx = videos.findIndex(v => v.src === currentSrc);
        prevBtn.disabled = idx <= 0;
        nextBtn.disabled = idx === -1 || idx >= videos.length - 1;
    }

    // ---- Events ----
    searchEl.addEventListener('input', () => { query = searchEl.value; render(); });
    prevBtn.addEventListener('click', () => move(-1));
    nextBtn.addEventListener('click', () => move(1));

    video.addEventListener('error', () => {
        if (!currentSrc) return;
        video.hidden = true;
        emptyState.hidden = true;
        errorState.hidden = false;
    });
    video.addEventListener('ended', () => move(1)); // auto-advance to the next story

    document.addEventListener('keydown', (e) => {
        if (e.target === searchEl) return;
        if (e.key === 'ArrowRight') move(1);
        if (e.key === 'ArrowLeft') move(-1);
    });

    // ---- Load the story list from JSON, then start up ----
    function start() {
        categories = ['All', ...Array.from(new Set(videos.map(v => v.category)))];
        buildFilters();
        render();

        const last = localStorage.getItem(STORAGE_KEY);
        if (last && videos.some(v => v.src === last)) {
            selectVideo(last, false); // restore without autoplaying on load
        }
    }

    fetch('videos.json')
        .then((res) => {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
        })
        .then((data) => {
            videos = Array.isArray(data) ? data : [];
            start();
        })
        .catch((err) => {
            console.error('Could not load videos.json:', err);
            emptyState.hidden = true;
            errorState.hidden = false;
            errorState.querySelector('p').textContent =
                "Couldn't load the story list (videos.json). If you opened this file directly, " +
                'run it through a local web server instead — browsers block fetch() on file:// URLs.';
        });
});
