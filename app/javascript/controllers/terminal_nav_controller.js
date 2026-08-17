import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "back"]
  static values = { indexUrl: String }

  connect() {
    this.selectedIndex = 0
    this.handleKeyDown = this.handleKeyDown.bind(this)
    window.addEventListener("keydown", this.handleKeyDown)
    this.registerContentLinks()
    this.updateActiveItem()
  }

  disconnect() {
    window.removeEventListener("keydown", this.handleKeyDown)
  }

  get allTargets() {
    const sidebarItems = [...this.itemTargets]
    const contentLinks = Array.from(document.querySelectorAll(".markdown-body a"))
    return [...sidebarItems, ...contentLinks]
  }

  registerContentLinks() {
    const contentLinks = document.querySelectorAll(".markdown-body a")
    contentLinks.forEach(link => {
      if (!link.hasAttribute("data-nav-registered")) {
        link.setAttribute("data-nav-registered", "true")
        link.classList.add("px-1", "py-0.5", "transition-colors")
        link.addEventListener("mouseenter", () => {
          const idx = this.allTargets.indexOf(link)
          if (idx !== -1) {
            this.selectedIndex = idx
            this.updateActiveItem()
          }
        })
      }
    })
  }

  handleKeyDown(event) {
    if (["INPUT", "TEXTAREA"].includes(document.activeElement.tagName)) {
      return
    }

    const items = this.allTargets

    switch (event.key) {
      case "ArrowDown":
      case "j":
        event.preventDefault()
        if (items.length > 0) {
          this.selectedIndex = (this.selectedIndex + 1) % items.length
          this.updateActiveItem()
        }
        break

      case "ArrowUp":
      case "k":
        event.preventDefault()
        if (items.length > 0) {
          this.selectedIndex = (this.selectedIndex - 1 + items.length) % items.length
          this.updateActiveItem()
        }
        break

      case "Enter":
        event.preventDefault()
        if (items.length > 0 && items[this.selectedIndex]) {
          const currentItem = items[this.selectedIndex]
          const href = currentItem.getAttribute("href")
          if (href && href.startsWith("#")) {
            this.scrollToHeading(href)
          } else {
            currentItem.click()
          }
        }
        break

      case "Backspace":
      case "Escape":
        if (this.hasBackTarget) {
          event.preventDefault()
          this.backTarget.click()
        } else if (this.hasIndexUrlValue && window.location.pathname !== this.indexUrlValue) {
          event.preventDefault()
          window.location.href = this.indexUrlValue
        }
        break
    }
  }

  updateActiveItem() {
    const items = this.allTargets
    if (items.length === 0) return

    items.forEach((item, idx) => {
      const bullet = item.querySelector(".nav-bullet")
      const dateText = item.querySelector(".nav-date")

      if (idx === this.selectedIndex) {
        item.classList.add("active-nav-link", "bg-gray-300", "text-black")
        item.classList.remove("text-gray-300")
        if (bullet) {
          bullet.classList.add("text-black")
          bullet.classList.remove("text-gray-500")
        }
        if (dateText) {
          dateText.classList.add("text-black")
          dateText.classList.remove("text-gray-400")
        }
        item.scrollIntoView({ block: "nearest", behavior: "smooth" })
      } else {
        item.classList.remove("active-nav-link", "bg-gray-300", "text-black")
        item.classList.add("text-gray-300")
        if (bullet) {
          bullet.classList.remove("text-black")
          bullet.classList.add("text-gray-500")
        }
        if (dateText) {
          dateText.classList.remove("text-black")
          dateText.classList.add("text-gray-400")
        }
      }
    })
  }

  scrollToHeading(href) {
    const targetEl = document.querySelector(href)
    if (targetEl) {
      targetEl.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }
}
