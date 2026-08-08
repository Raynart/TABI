/* ============================================================
   TABI — script.js
   Top page rendering + UI behaviors
   ============================================================ */

(function () {
  'use strict';

  /* Escape text before it goes into innerHTML. */
  function esc(s) {
    return String(s == null ? '' : s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  /* ===== TICKER: duplicate items for seamless loop ===== */
  function initTicker() {
    var track = document.getElementById('ticker-track');
    if (!track) return;
    // HTML already duplicates items for seamless loop — no JS duplication needed
  }

  /* ===== HERO DOTS ===== */
  function initHeroDots() {
    var dots = document.querySelectorAll('.hero-dot');
    if (!dots.length) return;
    dots.forEach(function (dot, i) {
      dot.addEventListener('click', function () {
        dots.forEach(function (d) { d.classList.remove('active'); });
        dot.classList.add('active');
      });
    });
  }

  /* ===== READING PROGRESS BAR ===== */
  function initProgressBar() {
    var bar = document.querySelector('.progress-bar');
    if (!bar) return;
    window.addEventListener('scroll', function () {
      var scrollTop = window.scrollY;
      var docHeight = document.documentElement.scrollHeight - window.innerHeight;
      var progress = docHeight > 0 ? (scrollTop / docHeight) * 100 : 0;
      bar.style.width = Math.min(progress, 100) + '%';
    }, { passive: true });
  }

  /* ===== BACK TO TOP ===== */
  function initBackTop() {
    var btn = document.querySelector('.back-top');
    if (!btn) return;
    window.addEventListener('scroll', function () {
      if (window.scrollY > 400) {
        btn.classList.add('visible');
      } else {
        btn.classList.remove('visible');
      }
    }, { passive: true });
    btn.addEventListener('click', function () {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  /* ===== MOBILE MENU ===== */
  function initMobileMenu() {
    var btn = document.querySelector('.header-menu-btn');
    var nav = document.querySelector('.header-nav');
    if (!btn || !nav) return;
    // Toggle a class rather than writing inline styles: inline display:flex used to
    // survive a resize past the breakpoint, leaving the menu stuck open on desktop.
    btn.addEventListener('click', function () {
      var isOpen = nav.classList.toggle('is-open');
      btn.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      btn.setAttribute('aria-label', isOpen ? 'Close menu' : 'Open menu');
    });
    nav.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') {
        nav.classList.remove('is-open');
        btn.setAttribute('aria-expanded', 'false');
        btn.setAttribute('aria-label', 'Open menu');
      }
    });
  }

  /* ===== NEWSLETTER FORM ===== */
  function initNewsletter() {
    var forms = document.querySelectorAll('.nl-form');
    forms.forEach(function (form) {
      form.addEventListener('submit', function (e) {
        e.preventDefault();
        var input = form.querySelector('.nl-input');
        var btn   = form.querySelector('.nl-btn');
        if (!input || !input.value.includes('@')) {
          input && input.focus();
          return;
        }
        btn.textContent = 'Thanks! ✓';
        btn.disabled = true;
        input.value = '';
      });
    });
  }

  /* ===== LAZY IMAGES =====
     Images now ship with a real src and loading="lazy", so the browser handles
     deferral natively and the preload scanner can see them. Nothing to do here.
     The old data-src observer defeated both, and left every image blank when it
     did not run. */

  /* ===== SCROLL HINT: hide on scroll ===== */
  function initScrollHint() {
    var hint = document.querySelector('.scroll-hint');
    if (!hint) return;
    var hidden = false;
    window.addEventListener('scroll', function () {
      if (!hidden && window.scrollY > 80) {
        hint.style.opacity = '0';
        hint.style.transition = 'opacity 0.4s';
        hidden = true;
      }
    }, { passive: true });
  }

  /* ===== ACTIVE NAV LINK ===== */
  function initActiveNav() {
    var path = window.location.pathname;
    document.querySelectorAll('.header-nav a').forEach(function (link) {
      if (link.getAttribute('href') && path.includes(link.getAttribute('href'))) {
        link.classList.add('active');
      }
    });
  }

  /* ===== SEARCH ===== */
  function initSearch() {
    var openBtn  = document.getElementById('search-open');
    var overlay  = document.getElementById('search-overlay');
    var closeBtn = document.getElementById('search-close');
    var input    = document.getElementById('search-input');
    var results  = document.getElementById('search-results');
    if (!openBtn || !overlay) return;

    var articles = null;
    var base = (document.querySelector('base') || {}).href || '/';
    var lastFocused = null;

    function isOpen() { return overlay.classList.contains('open'); }

    function openSearch() {
      lastFocused = document.activeElement;
      overlay.classList.add('open');
      overlay.removeAttribute('aria-hidden');
      overlay.removeAttribute('inert');
      document.body.style.overflow = 'hidden';
      openBtn.setAttribute('aria-expanded', 'true');
      input.focus();
      if (!articles) {
        fetch(base + 'articles-slim.json')
          .then(function (r) { return r.json(); })
          .then(function (data) { articles = data; })
          .catch(function () { articles = []; });
      }
    }

    function closeSearch() {
      if (!isOpen()) return;
      overlay.classList.remove('open');
      overlay.setAttribute('aria-hidden', 'true');
      overlay.setAttribute('inert', '');
      document.body.style.overflow = '';
      openBtn.setAttribute('aria-expanded', 'false');
      input.value = '';
      results.innerHTML = '';
      // Return focus to whatever opened the dialog, not the top of the document.
      if (lastFocused && lastFocused.focus) lastFocused.focus();
      lastFocused = null;
    }

    openBtn.addEventListener('click', openSearch);
    closeBtn.addEventListener('click', closeSearch);
    overlay.addEventListener('click', function (e) { if (e.target === overlay) closeSearch(); });

    document.addEventListener('keydown', function (e) {
      if (!isOpen()) return;
      if (e.key === 'Escape') { closeSearch(); return; }
      if (e.key !== 'Tab') return;
      // Keep focus inside the dialog while it is open.
      var focusable = overlay.querySelectorAll(
        'a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])');
      if (!focusable.length) return;
      var first = focusable[0];
      var last  = focusable[focusable.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault(); last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault(); first.focus();
      }
    });

    var searchTimer;
    input.addEventListener('input', function () {
      clearTimeout(searchTimer);
      searchTimer = setTimeout(function () {
        var q = input.value.trim().toLowerCase();
        if (!q || !articles) { results.innerHTML = ''; return; }
        var hits = articles.filter(function (a) {
          return a.title.toLowerCase().indexOf(q) !== -1 ||
                 (a.excerpt || '').toLowerCase().indexOf(q) !== -1 ||
                 (a.tags || []).some(function (t) { return t.indexOf(q) !== -1; });
        }).slice(0, 6);
        if (!hits.length) {
          results.innerHTML = '<p class="search-empty">No results for &ldquo;' + esc(q) + '&rdquo;</p>';
          return;
        }
        results.innerHTML = hits.map(function (a) {
          var url     = base + 'articles/' + encodeURIComponent(a.id) + '.html';
          var catFmt  = (a.category || '').replace(/-/g, ' ');
          var excerpt = (a.excerpt || '').slice(0, 90) + '…';
          return '<a href="' + esc(url) + '" class="search-result">' +
                 '<span class="search-result-cat">' + esc(catFmt) + '</span>' +
                 '<span class="search-result-title">' + esc(a.title) + '</span>' +
                 '<span class="search-result-excerpt">' + esc(excerpt) + '</span>' +
                 '</a>';
        }).join('');
      }, 200);
    });
  }

  /* ===== SHARE BUTTONS ===== */
  function initShareButtons() {
    document.querySelectorAll('.share-copy').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var url = btn.dataset.url;
        if (navigator.clipboard) {
          navigator.clipboard.writeText(url).then(function () {
            var orig = btn.textContent;
            btn.textContent = 'Copied!';
            setTimeout(function () { btn.textContent = orig; }, 2000);
          });
        }
      });
    });
  }

  /* ===== ANALYTICS (consent-gated) =====
     The page only declares window.TABI_GA_ID; the tag itself is loaded here, and
     only once the visitor has accepted. Loading it in <head> would have run
     analytics before the banner was answered. */
  function loadAnalytics() {
    if (!window.TABI_GA_ID || window.__tabiGaLoaded) return;
    window.__tabiGaLoaded = true;
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(window.TABI_GA_ID);
    document.head.appendChild(s);
    window.dataLayer = window.dataLayer || [];
    function gtag() { window.dataLayer.push(arguments); }
    window.gtag = gtag;
    gtag('js', new Date());
    gtag('config', window.TABI_GA_ID);
  }

  /* ===== ADS (consent-gated) =====
     Same contract as analytics: the page only declares window.TABI_ADS_CLIENT and
     leaves inert <ins class="adsbygoogle"> placeholders. The library is fetched
     here, after consent, and each slot is filled once. Without consent no ad
     request is made and no ad cookie is set -- the placeholders just stay empty. */
  function loadAds() {
    if (!window.TABI_ADS_CLIENT || window.__tabiAdsLoaded) return;
    var slots = document.querySelectorAll('ins.adsbygoogle');
    if (!slots.length) return;
    window.__tabiAdsLoaded = true;

    var s = document.createElement('script');
    s.async = true;
    s.crossOrigin = 'anonymous';
    s.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' +
            encodeURIComponent(window.TABI_ADS_CLIENT);
    document.head.appendChild(s);

    window.adsbygoogle = window.adsbygoogle || [];
    for (var i = 0; i < slots.length; i++) {
      window.adsbygoogle.push({});
    }
  }

  /* ===== GDPR BANNER ===== */
  function initGdprBanner() {
    var choice = localStorage.getItem('tabi-cookie-consent');
    if (choice === 'accepted') { loadAnalytics(); loadAds(); }

    var banner = document.getElementById('gdpr-banner');
    if (!banner || choice) return;
    banner.classList.add('visible');
    document.getElementById('gdpr-accept').addEventListener('click', function () {
      localStorage.setItem('tabi-cookie-consent', 'accepted');
      banner.classList.remove('visible');
      loadAnalytics();
      loadAds();
    });
    document.getElementById('gdpr-decline').addEventListener('click', function () {
      localStorage.setItem('tabi-cookie-consent', 'declined');
      banner.classList.remove('visible');
    });
  }

  /* ===== PAGINATION =====
     Listings are now paginated when the pages are generated: page 2 onward have
     their own URLs and the links are plain anchors, so pagination works without
     JavaScript and each page can be linked to and indexed. Nothing to do here. */

  /* ===== TOC SCROLL SPY ===== */
  function initTocSpy() {
    var toc = document.querySelector('.toc');
    if (!toc) return;
    var sections = document.querySelectorAll('.article-section');
    if (!sections.length) return;
    var active = null;

    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        var h2 = entry.target.querySelector('h2');
        if (!h2) return;
        var link = toc.querySelector('a[href="#' + h2.id + '"]');
        if (!link) return;
        if (entry.isIntersecting) {
          if (active) active.classList.remove('toc-active');
          link.classList.add('toc-active');
          active = link;
        }
      });
    }, { rootMargin: '-8% 0px -78% 0px' });

    sections.forEach(function (sec) { observer.observe(sec); });
  }

  /* ===== INIT ===== */
  document.addEventListener('DOMContentLoaded', function () {
    initTicker();
    initHeroDots();
    initProgressBar();
    initBackTop();
    initMobileMenu();
    initNewsletter();
    initScrollHint();
    initActiveNav();
    initSearch();
    initShareButtons();
    initGdprBanner();
    initTocSpy();
  });

})();
