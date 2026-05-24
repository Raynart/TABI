(function () {
  const searchToggle = document.querySelector("[data-search-toggle]");
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
    const matches = articles
      .filter((article) => {
        const haystack = [
          article.title,
          article.summary,
          article.category,
          (article.tags || []).join(" ")
        ].join(" ").toLowerCase();
        return !normalized || haystack.includes(normalized);
      })
      .slice(0, 8);

    if (!matches.length) {
      searchResults.innerHTML = '<div class="search-result"><span>No matching guides yet.</span></div>';
      return;
    }

    searchResults.innerHTML = matches
      .map((article) => {
        const tags = (article.tags || []).slice(0, 3).map((tag) => "#" + tag).join(" ");
        return [
          '<a class="search-result" href="' + article.url + '">',
          "<strong>" + escapeHtml(article.title) + "</strong>",
          "<span>" + escapeHtml(article.categoryLabel) + " / " + escapeHtml(tags) + "</span>",
          "</a>"
        ].join("");
      })
      .join("");
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  if (searchToggle) {
    searchToggle.addEventListener("click", openSearch);
  }

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
