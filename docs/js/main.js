(function () {
  const navToggle = document.querySelector(".nav-toggle");
  const nav = document.querySelector(".nav");
  const downloadBtn = document.getElementById("download-btn");
  const downloadNote = document.getElementById("download-note");
  const gameZip = "downloads/LostEco-v1.0-Windows.zip";

  if (navToggle && nav) {
    navToggle.addEventListener("click", function () {
      nav.classList.toggle("open");
    });

    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () {
        nav.classList.remove("open");
      });
    });
  }

  document.querySelectorAll(".faq-question").forEach(function (button) {
    button.addEventListener("click", function () {
      const item = button.closest(".faq-item");
      const isOpen = item.classList.contains("open");

      document.querySelectorAll(".faq-item.open").forEach(function (openItem) {
        openItem.classList.remove("open");
      });

      if (!isOpen) {
        item.classList.add("open");
      }
    });
  });

  if (downloadBtn) {
    fetch(gameZip, { method: "HEAD" })
      .then(function (response) {
        if (response.ok) {
          downloadBtn.href = gameZip;
          downloadBtn.removeAttribute("aria-disabled");
          if (downloadNote) {
            downloadNote.classList.add("hidden");
          }
        } else if (downloadNote) {
          downloadNote.classList.remove("hidden");
        }
      })
      .catch(function () {
        if (downloadNote) {
          downloadNote.classList.remove("hidden");
        }
      });

    downloadBtn.addEventListener("click", function (event) {
      if (downloadBtn.getAttribute("aria-disabled") === "true") {
        event.preventDefault();
        if (downloadNote) {
          downloadNote.scrollIntoView({ behavior: "smooth", block: "nearest" });
        }
      }
    });
  }
})();
