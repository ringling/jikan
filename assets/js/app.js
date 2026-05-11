// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

const Hooks = {}

Hooks.LocalBackup = {
  STORAGE_KEY: "jikan:backups",
  MAX_BACKUPS: 5,

  mounted() {
    this.handleEvent("save_backup", (payload) => {
      if (!payload.entries || payload.entries.length === 0) return
      const backups = this.loadBackups()
      backups.unshift({
        id: payload.backed_up_at,
        backed_up_at: payload.backed_up_at,
        entry_count: payload.entries.length,
        filters_description: payload.filters_description,
        entries: payload.entries
      })
      this.saveBackups(backups.slice(0, this.MAX_BACKUPS))
    })

    const manageBtn = document.getElementById("manage-backups-btn")
    if (manageBtn) {
      manageBtn.addEventListener("click", () => this.showAdmin())
    }

    // Event delegation for download/delete buttons inside the admin table
    const tbody = document.getElementById("backup-admin-tbody")
    if (tbody) {
      tbody.addEventListener("click", (e) => {
        const btn = e.target.closest("button[data-action]")
        if (!btn) return
        const idx = parseInt(btn.dataset.index, 10)
        const backups = this.loadBackups()
        if (isNaN(idx) || !backups[idx]) return
        if (btn.dataset.action === "download") {
          this.downloadBackup(backups[idx])
        } else if (btn.dataset.action === "delete") {
          backups.splice(idx, 1)
          this.saveBackups(backups)
          this.renderAdminTable()
        }
      })
    }
  },

  loadBackups() {
    try { return JSON.parse(localStorage.getItem(this.STORAGE_KEY)) || [] }
    catch (_) { return [] }
  },

  saveBackups(backups) {
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(backups))
  },

  showAdmin() {
    const modal = document.getElementById("backup-admin-modal")
    this.renderAdminTable()
    modal.showModal()
  },

  renderAdminTable() {
    const backups = this.loadBackups()
    const tbody = document.getElementById("backup-admin-tbody")
    const indicator = document.getElementById("backup-slots-indicator")
    if (indicator) indicator.textContent = `${backups.length} of ${this.MAX_BACKUPS} slots used`
    if (backups.length === 0) {
      tbody.innerHTML = `
        <tr><td colspan="4" class="text-center py-8">
          <div class="flex flex-col items-center gap-2 opacity-60">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-10">
              <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
            </svg>
            <span>No backups saved yet</span>
            <span class="text-xs">Use the Backup menu to create one</span>
          </div>
        </td></tr>`
      return
    }
    tbody.innerHTML = backups.map((b, idx) => `
      <tr>
        <td>${new Date(b.backed_up_at).toLocaleString()}</td>
        <td>${b.entry_count}</td>
        <td>${this.escapeHtml(b.filters_description)}</td>
        <td class="flex gap-2">
          <button type="button" class="btn btn-xs btn-outline" data-action="download" data-index="${idx}">Download</button>
          <button type="button" class="btn btn-xs btn-error btn-outline" data-action="delete" data-index="${idx}">Delete</button>
        </td>
      </tr>
    `).join("")
  },

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str ?? ""
    return div.innerHTML
  },

  downloadBackup(backup) {
    const blob = new Blob([JSON.stringify(backup.entries, null, 2)], {type: "application/json"})
    const a = document.createElement("a")
    a.href = URL.createObjectURL(blob)
    a.download = `jikan_backup_${backup.backed_up_at.replace(/[:.]/g, "-")}.json`
    a.click()
    URL.revokeObjectURL(a.href)
  }
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

