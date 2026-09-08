document.addEventListener("DOMContentLoaded", () => {
  const isPostPage = document.body.dataset.pageType === "show";
  let activeIndex = 0;

  // Gerenciamento de Zoom para leitura de posts
  let currentZoom = parseFloat(localStorage.getItem("blog_post_zoom")) || 1.0;

  function applyZoom(newZoom) {
    currentZoom = Math.min(Math.max(newZoom, 0.7), 1.6);
    currentZoom = Math.round(currentZoom * 10) / 10;
    localStorage.setItem("blog_post_zoom", currentZoom.toString());

    const markdownBody = document.querySelector(".markdown-body");
    if (markdownBody) {
      markdownBody.style.zoom = currentZoom;
      markdownBody.style.setProperty("--content-zoom", currentZoom);
    }
  }

  if (isPostPage) {
    applyZoom(currentZoom);

    const btnZoomIn = document.getElementById("btn-zoom-in");
    const btnZoomOut = document.getElementById("btn-zoom-out");

    if (btnZoomIn) {
      btnZoomIn.addEventListener("click", (e) => {
        e.preventDefault();
        applyZoom(currentZoom + 0.1);
      });
    }

    if (btnZoomOut) {
      btnZoomOut.addEventListener("click", (e) => {
        e.preventDefault();
        applyZoom(currentZoom - 0.1);
      });
    }
  }

  function getNavItems() {
    return Array.from(document.querySelectorAll(".nav-item"));
  }

  function updateActiveState() {
    const items = getNavItems();
    if (items.length === 0) return;

    if (activeIndex < 0) activeIndex = 0;
    if (activeIndex >= items.length) activeIndex = items.length - 1;

    items.forEach((item, idx) => {
      if (idx === activeIndex) {
        item.classList.add("active-nav-link");
        item.scrollIntoView({ block: "nearest", behavior: "smooth" });
      } else {
        item.classList.remove("active-nav-link");
      }
    });
  }

  updateActiveState();

  document.addEventListener("keydown", (event) => {
    if (["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement.tagName)) {
      return;
    }

    const items = getNavItems();

    switch (event.key) {
      case "ArrowDown":
      case "j":
      case "J":
        if (items.length > 0) {
          event.preventDefault();
          if (activeIndex < items.length - 1) {
            activeIndex++;
            updateActiveState();
          }
        }
        break;

      case "ArrowUp":
      case "k":
      case "K":
        if (items.length > 0) {
          event.preventDefault();
          if (activeIndex > 0) {
            activeIndex--;
            updateActiveState();
          }
        }
        break;

      case "Enter":
        if (items.length > 0) {
          event.preventDefault();
          const activeItem = items[activeIndex];
          if (activeItem) {
            activeItem.click();
          }
        }
        break;

      case "+":
      case "=":
        if (isPostPage) {
          event.preventDefault();
          applyZoom(currentZoom + 0.1);
        }
        break;

      case "-":
      case "_":
        if (isPostPage) {
          event.preventDefault();
          applyZoom(currentZoom - 0.1);
        }
        break;

      case "0":
        if (isPostPage && (event.ctrlKey || event.metaKey)) {
          event.preventDefault();
          applyZoom(1.0);
        }
        break;

      case "Backspace":
      case "Escape":
        if (isPostPage) {
          event.preventDefault();
          const rootPath = document.body.dataset.rootPath || "/";
          window.location.href = rootPath;
        }
        break;

      default:
        break;
    }
  });
});
