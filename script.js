/* ============================================================
   TABI — script.js
   Top page rendering + UI behaviors
   ============================================================ */

(function () {
  'use strict';

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
    var btn  = document.querySelector('.header-menu-btn');
    var nav  = document.querySelector('.header-nav');
    if (!btn || !nav) return;
    btn.addEventListener('click', function () {
      var isOpen = nav.style.display === 'flex';
      nav.style.display = isOpen ? '' : 'flex';
      nav.style.flexDirection = 'column';
      nav.style.position = 'absolute';
      nav.style.top = '68px';
      nav.style.left = '0';
      nav.style.right = '0';
      nav.style.background = 'var(--paper)';
      nav.style.padding = '16px 32px 24px';
      nav.style.borderBottom = '1px solid var(--border)';
      nav.style.zIndex = '100';
      btn.setAttribute('aria-expanded', isOpen ? 'false' : 'true');
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

  /* ===== LAZY IMAGES ===== */
  function initLazyImages() {
    if (!('IntersectionObserver' in window)) return;
    var images = document.querySelectorAll('img[data-src]');
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          var img = entry.target;
          img.src = img.dataset.src;
          img.removeAttribute('data-src');
          observer.unobserve(img);
        }
      });
    }, { rootMargin: '200px' });
    images.forEach(function (img) { observer.observe(img); });
  }

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

    function openSearch() {
      overlay.classList.add('open');
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
      overlay.classList.remove('open');
      document.body.style.overflow = '';
      openBtn.setAttribute('aria-expanded', 'false');
      input.value = '';
      results.innerHTML = '';
    }

    openBtn.addEventListener('click', openSearch);
    closeBtn.addEventListener('click', closeSearch);
    overlay.addEventListener('click', function (e) { if (e.target === overlay) closeSearch(); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape') closeSearch(); });

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
          results.innerHTML = '<p class="search-empty">No results for “' + q + '”</p>';
          return;
        }
        results.innerHTML = hits.map(function (a) {
          var url     = base + 'articles/' + a.id + '.html';
          var catFmt  = (a.category || '').replace(/-/g, ' ');
          var excerpt = (a.excerpt || '').slice(0, 90) + '…';
          return '<a href="' + url + '" class="search-result">' +
                 '<span class="search-result-cat">' + catFmt + '</span>' +
                 '<span class="search-result-title">' + a.title + '</span>' +
                 '<span class="search-result-excerpt">' + excerpt + '</span>' +
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

  /* ===== GDPR BANNER ===== */
  function initGdprBanner() {
    var banner = document.getElementById('gdpr-banner');
    if (!banner || localStorage.getItem('tabi-cookie-consent')) return;
    banner.classList.add('visible');
    document.getElementById('gdpr-accept').addEventListener('click', function () {
      localStorage.setItem('tabi-cookie-consent', 'accepted');
      banner.classList.remove('visible');
    });
    document.getElementById('gdpr-decline').addEventListener('click', function () {
      localStorage.setItem('tabi-cookie-consent', 'declined');
      banner.classList.remove('visible');
    });
  }

  /* ===== PAGINATION ===== */
  function initPagination() {
    document.querySelectorAll('[data-paginate]').forEach(function (grid) {
      var perPage = parseInt(grid.dataset.paginate, 10) || 12;
      var cards   = Array.from(grid.querySelectorAll('.ed-card'));
      if (cards.length <= perPage) return;

      var currentPage  = 1;
      var totalPages   = Math.ceil(cards.length / perPage);
      var paginationEl = document.createElement('div');
      paginationEl.className = 'pagination';
      grid.parentNode.insertBefore(paginationEl, grid.nextSibling);

      function showPage(page) {
        currentPage = page;
        cards.forEach(function (card, i) {
          card.style.display = (i >= (page - 1) * perPage && i < page * perPage) ? '' : 'none';
        });
        paginationEl.innerHTML = '';
        for (var i = 1; i <= totalPages; i++) {
          var btn = document.createElement('button');
          btn.className = 'pg-btn' + (i === currentPage ? ' active' : '');
          btn.textContent = i;
          (function (p) {
            btn.addEventListener('click', function () {
              showPage(p);
              window.scrollTo({ top: 0, behavior: 'smooth' });
            });
          }(i));
          paginationEl.appendChild(btn);
        }
      }

      showPage(1);
    });
  }

  /* ===== INIT ===== */
  document.addEventListener('DOMContentLoaded', function () {
    initTicker();
    initHeroDots();
    initProgressBar();
    initBackTop();
    initMobileMenu();
    initNewsletter();
    initLazyImages();
    initScrollHint();
    initActiveNav();
    initSearch();
    initShareButtons();
    initGdprBanner();
    initPagination();
  });

})();
