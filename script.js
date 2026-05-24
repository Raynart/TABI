(function () {
  const searchToggles = document.querySelectorAll("[data-search-toggle]");
  const searchPanel = document.querySelector("[data-search-panel]");
  const searchClose = document.querySelector("[data-search-close]");
  const searchInput = document.querySelector("[data-search-input]");
  const searchResults = document.querySelector("[data-search-results]");
  const newsletterForms = document.querySelectorAll("[data-newsletter-form]");
  const articles = Array.isArray(window.TABI_ARTICLES) ? window.TABI_ARTICLES : [];

  function openSearch() {
    if (!searchPanel) return;
    searchPanel.hidden = false;
    document.body.style.overflow = "hidden";
    renderSearch("");
    window.setTimeout(() => searchInput && searchInput.focus(), 0);
  }

  function closeSearch() {
    if (!searchPanel) return;
    searchPanel.hidden = true;
    document.body.style.overflow = "";
    if (searchInput) searchInput.value = "";
  }

  function renderSearch(query) {
    if (!searchResults) return;
    const normalized = query.trim().toLowerCase();
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
      searchResults.innerHTML = '<div class="search-result"><span>No matching guides yet.</span></div>';
      return;
    }

    searchResults.innerHTML = matches
      .map((item) => {
        const article = item.article;
        const tags = (article.tags || []).slice(0, 3).map((tag) => "#" + tag).join(" ");
        return [
          '<a class="search-result" href="' + article.url + '">',
          "<strong>" + escapeHtml(article.title) + "</strong>",
          "<span>" + escapeHtml(article.categoryLabel) + " / " + escapeHtml(article.topic || "TABI") + " / " + escapeHtml(tags) + "</span>",
          "</a>"
        ].join("");
      })
      .join("");
  }

  function scoreArticle(article, tokens) {
    if (!tokens.length) return article.score || 0;

    const fields = {
      title: String(article.title || "").toLowerCase(),
      summary: String(article.summary || "").toLowerCase(),
      category: String(article.categoryLabel || article.category || "").toLowerCase(),
      topic: String(article.topic || "").toLowerCase(),
      tags: (article.tags || []).join(" ").toLowerCase()
    };

    return tokens.reduce((total, token) => {
      let score = 0;
      if (fields.title.includes(token)) score += 18;
      if (fields.tags.includes(token)) score += 12;
      if (fields.topic.includes(token)) score += 9;
      if (fields.category.includes(token)) score += 7;
      if (fields.summary.includes(token)) score += 4;
      if (fields.title.startsWith(token)) score += 8;
      return total + score;
    }, Math.round((article.score || 0) / 10));
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

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && searchPanel && !searchPanel.hidden) {
      closeSearch();
    }
  });

  newsletterForms.forEach((form) => {
    form.addEventListener("submit", (event) => {
      event.preventDefault();
      const input = form.querySelector('input[type="email"]');
      const status = form.parentElement.querySelector("[data-newsletter-status]");
      const value = input ? input.value.trim() : "";

      if (!value || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
        if (status) status.textContent = "Please enter a valid email address.";
        return;
      }

      if (status) status.textContent = "Thank you. The next TABI letter will find you soon.";
      form.reset();
    });
  });
})();
