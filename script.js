(function () {
  const searchToggles = document.querySelectorAll("[data-search-toggle]");
  const searchPanel = document.querySelector("[data-search-panel]");
  const searchClose = document.querySelector("[data-search-close]");
  const searchInput = document.querySelector("[data-search-input]");
  const searchResults = document.querySelector("[data-search-results]");
  const newsletterForms = document.querySelectorAll("[data-newsletter-form]");
  const recentlyViewed = document.querySelector("[data-recently-viewed]");
  const recentlyViewedList = document.querySelector("[data-recently-viewed-list]");
  const readingProgress = document.querySelector("[data-reading-progress] span");
  const articleBody = document.querySelector(".article-body");
  const currentMobileNavItem = document.querySelector(".mobile-nav a[aria-current=\"page\"]");
  const articles = Array.isArray(window.TABI_ARTICLES) ? window.TABI_ARTICLES : [];
  let lastFocusedElement = null;
  const lang = document.documentElement.lang === "ja" ? "ja" : "en";
  const messages = {
    en: {
      noMatches: "No matching guides yet.",
      fallbackTopic: "TABI",
      popularSearches: ["Kyoto", "food", "itinerary", "matcha", "ryokan", "quiet travel"],
      noMatchesHelp: "Try Kyoto, food, itinerary, matcha, ryokan, or quiet travel.",
      invalidEmail: "Please enter a valid email address.",
      newsletterThanks: "Thank you. The next TABI letter will find you soon.",
      viewed: "Viewed"
    },
    ja: {
      noMatches: "一致するガイドはまだありません。",
      fallbackTopic: "TABI",
      popularSearches: ["京都", "食", "旅程", "抹茶", "旅館", "静かな旅"],
      noMatchesHelp: "京都、食、旅程、抹茶、旅館、静かな旅などで探してみてください。",
      invalidEmail: "有効なメールアドレスを入力してください。",
      newsletterThanks: "ありがとうございます。次のTABIレターをお届けします。",
      viewed: "閲覧"
    }
  };

  function t(key) {
    return messages[lang][key] || messages.en[key] || key;
  }

  function openSearch() {
    if (!searchPanel) return;
    lastFocusedElement = document.activeElement;
    searchPanel.hidden = false;
    document.body.classList.add("search-open");
    searchToggles.forEach((searchToggle) => searchToggle.setAttribute("aria-expanded", "true"));
    renderSearch("");
    window.setTimeout(() => searchInput && searchInput.focus(), 0);
  }

  function closeSearch() {
    if (!searchPanel) return;
    searchPanel.hidden = true;
    document.body.classList.remove("search-open");
    searchToggles.forEach((searchToggle) => searchToggle.setAttribute("aria-expanded", "false"));
    if (searchInput) searchInput.value = "";
    if (lastFocusedElement && typeof lastFocusedElement.focus === "function") {
      lastFocusedElement.focus();
    }
  }

  function renderSearch(query) {
    if (!searchResults) return;
    const normalized = normalizeSearchText(query);
    const tokens = normalized.split(/\s+/).filter(Boolean);
    const matches = articles
      .map((article) => {
        const rank = scoreArticle(article, tokens);
        return { article, rank };
      })
      .filter((item) => !tokens.length || item.rank > 0)
      .sort((a, b) => b.rank - a.rank || (b.article.score || 0) - (a.article.score || 0))
      .slice(0, 8);

    if (!matches.length) {
      searchResults.innerHTML = [
        '<div class="search-result search-empty">',
        '<strong>' + escapeHtml(t("noMatches")) + '</strong>',
        '<span>' + escapeHtml(messages[lang].noMatchesHelp || messages.en.noMatchesHelp || "") + '</span>',
        renderPopularSearches(),
        '</div>'
      ].join("");
      return;
    }

    const popularSearches = tokens.length ? "" : renderPopularSearches("top");
    searchResults.innerHTML = popularSearches + matches
      .map((item) => {
        const article = item.article;
        const labels = Array.isArray(article.tagLabels) && article.tagLabels.length ? article.tagLabels : article.tags || [];
        const tags = labels.slice(0, 3).map((tag) => "#" + tag).join(" ");
        return [
          '<a class="search-result" href="' + article.url + '">',
          "<strong>" + escapeHtml(article.title) + "</strong>",
          "<span>" + escapeHtml(article.languageLabel || "") + " / " + escapeHtml(article.categoryLabel) + " / " + escapeHtml(article.topic || t("fallbackTopic")) + " / " + escapeHtml(article.audience || "") + " / " + escapeHtml(tags) + "</span>",
          "</a>"
        ].join("");
      })
      .join("");
  }

  function scoreArticle(article, tokens) {
    if (!tokens.length) return article.score || 0;

    const fields = {
      title: normalizeSearchText(article.title || ""),
      summary: normalizeSearchText(article.summary || ""),
      category: normalizeSearchText(article.categoryLabel || article.category || ""),
      topic: normalizeSearchText(article.topic || ""),
      audience: normalizeSearchText(article.audience || ""),
      aliases: normalizeSearchText((article.aliases || []).join(" ")),
      tags: normalizeSearchText((article.tags || []).concat(article.tagLabels || []).join(" "))
    };

    return tokens.reduce((total, token) => {
      let score = 0;
      if (fields.title.includes(token)) score += 18;
      if (fields.aliases.includes(token)) score += 16;
      if (fields.tags.includes(token)) score += 12;
      if (fields.topic.includes(token)) score += 9;
      if (fields.category.includes(token)) score += 7;
      if (fields.audience.includes(token)) score += 6;
      if (fields.summary.includes(token)) score += 4;
      if (fields.title.startsWith(token)) score += 8;
      return total + score;
    }, 0);
  }

  function normalizeSearchText(value) {
    return String(value || "")
      .toLowerCase()
      .normalize("NFKC")
      .replace(/[ぁ-ん]/g, (char) => String.fromCharCode(char.charCodeAt(0) + 0x60))
      .replace(/[・、。／/|｜]+/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  function renderPopularSearches(variant) {
    const searches = messages[lang].popularSearches || messages.en.popularSearches || [];
    if (!searches.length) return "";
    const className = variant === "top" ? "search-suggestions search-suggestions-top" : "search-suggestions";
    return '<div class="' + className + '">' + searches.map((term) => '<button type="button" data-search-suggestion="' + escapeHtml(term) + '">' + escapeHtml(term) + '</button>').join("") + '</div>';
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  searchToggles.forEach((searchToggle) => {
    searchToggle.addEventListener("click", openSearch);
  });

  if (searchClose) {
    searchClose.addEventListener("click", closeSearch);
  }

  if (searchPanel) {
    searchPanel.addEventListener("click", (event) => {
      if (event.target === searchPanel) closeSearch();
    });
  }

  if (searchInput) {
    searchInput.addEventListener("input", (event) => renderSearch(event.target.value));
  }

  if (searchResults && searchInput) {
    searchResults.addEventListener("click", (event) => {
      const button = event.target.closest("[data-search-suggestion]");
      if (!button) return;
      searchInput.value = button.getAttribute("data-search-suggestion") || "";
      renderSearch(searchInput.value);
      searchInput.focus();
    });
  }

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && searchPanel && !searchPanel.hidden) {
      closeSearch();
    }
    if (event.key === "Tab" && searchPanel && !searchPanel.hidden) {
      const focusable = searchPanel.querySelectorAll('a[href], button:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])');
      if (!focusable.length) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    }
  });

  newsletterForms.forEach((form) => {
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      const input = form.querySelector('input[type="email"]');
      const status = form.parentElement.querySelector("[data-newsletter-status]");
      const value = input ? input.value.trim() : "";

      if (!value || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        if (status) status.textContent = t("invalidEmail");
        return;
      }

      if (status) status.textContent = t("newsletterThanks");
      form.reset();
    });
  });

  function getRecentKey() {
    return "tabi:recent:" + lang;
  }

  function readRecentPages() {
    try {
      return JSON.parse(window.localStorage.getItem(getRecentKey()) || "[]");
    } catch (error) {
      return [];
    }
  }

  function writeRecentPages(items) {
    try {
      window.localStorage.setItem(getRecentKey(), JSON.stringify(items.slice(0, 6)));
    } catch (error) {
      // Ignore storage errors so browsing still works in private or restricted contexts.
    }
  }

  function getCurrentPage() {
    const canonical = document.querySelector('link[rel="canonical"]');
    const kicker = document.querySelector(".page-kicker, .card-cat");
    const title = document.title.replace(/\s[-|]\sTABI$/, "").trim();
    return {
      title,
      url: canonical ? canonical.href : window.location.href,
      label: kicker ? kicker.textContent.trim() : "TABI",
      viewedAt: Date.now()
    };
  }

  function renderRecentPages() {
    if (!recentlyViewed || !recentlyViewedList) return;
    const currentUrl = getCurrentPage().url;
    const items = readRecentPages().filter((item) => item && item.url && item.url !== currentUrl).slice(0, 3);
    if (!items.length) {
      recentlyViewed.hidden = true;
      return;
    }
    recentlyViewed.hidden = false;
    recentlyViewedList.innerHTML = items.map((item) => [
      '<a href="' + escapeHtml(item.url) + '">',
      '<small>' + escapeHtml(item.label || t("viewed")) + '</small>',
      '<strong>' + escapeHtml(item.title || "TABI") + '</strong>',
      '</a>'
    ].join("")).join("");
  }

  function rememberCurrentPage() {
    const current = getCurrentPage();
    if (!current.title || current.title === "TABI") return;
    const items = readRecentPages().filter((item) => item && item.url !== current.url);
    writeRecentPages([current].concat(items));
  }


  function updateReadingProgress() {
    if (!readingProgress || !articleBody) return;
    const rect = articleBody.getBoundingClientRect();
    const total = Math.max(1, rect.height - window.innerHeight * 0.35);
    const read = Math.min(total, Math.max(0, -rect.top + window.innerHeight * 0.12));
    readingProgress.style.transform = "scaleX(" + (read / total).toFixed(4) + ")";
  }

  if (currentMobileNavItem) {
    window.setTimeout(() => {
      currentMobileNavItem.scrollIntoView({ behavior: "smooth", block: "nearest", inline: "center" });
    }, 120);
  }

  if (readingProgress && articleBody) {
    updateReadingProgress();
    window.addEventListener("scroll", updateReadingProgress, { passive: true });
    window.addEventListener("resize", updateReadingProgress);
  }
  const initialQuery = new URLSearchParams(window.location.search).get("q");
  if (initialQuery && searchInput) {
    openSearch();
    searchInput.value = initialQuery;
    renderSearch(initialQuery);
  }

  renderRecentPages();
  rememberCurrentPage();
})();
