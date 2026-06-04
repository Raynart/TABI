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
    var items = track.innerHTML;
    track.innerHTML = items + items; // duplicate for infinite scroll
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
  });

})();
