document.addEventListener("DOMContentLoaded", () => {
  const isPostPage = document.body.dataset.pageType === "show";
  let activeIndex = 0;

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
    if (items.length === 0) return;

    switch (event.key) {
      case "ArrowDown":
      case "j":
      case "J":
        event.preventDefault();
        if (activeIndex < items.length - 1) {
          activeIndex++;
          updateActiveState();
        }
        break;

      case "ArrowUp":
      case "k":
      case "K":
        event.preventDefault();
        if (activeIndex > 0) {
          activeIndex--;
          updateActiveState();
        }
        break;

      case "Enter":
        event.preventDefault();
        const activeItem = items[activeIndex];
        if (activeItem) {
          activeItem.click();
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
