// The demo's guided tour: Avo the avocado walks a visitor through the panel and points at what he talks about.
// His lines and stops are in config/tour.yml, his markup in app/views/avo/partials/_tour.html.erb.
(() => {
  // The base class Avo hands to its add-ons, so this file needs no bundler.
  const { Controller } = window.FakeStimulus

  const REST = { left: 102, right: 78 } // each arm's angle while it hangs at his side
  const EASE = "cubic-bezier(0.22, 1, 0.36, 1)"
  const PAD = 6 // the spotlight's margin around what it lights
  const GAP = 14 // between him and what he points at
  const EDGE = 12 // the closest he gets to the edge of the window
  const FIELDS = "input, textarea, select, [contenteditable]"

  class TourController extends Controller {
    static targets = [
      "spotlight", "hole", "guide", "mascot", "leftArm", "rightArm", "bubble", "text",
      "greeting", "sound", "nav", "paused", "counter", "back", "next", "done", "mute", "voiceOn", "voiceOff"
    ]

    // Runs on every page: Turbo carries the node over, and Stimulus disconnects and connects it on the way.
    connect() {
      if (this.lit === undefined) this.lit = []
      this.angles ||= { ...REST }
      this.tries ||= 0
      // One player for every line: a browser lets a player speak again once a click has let it speak.
      this.voice ||= new Audio()
      // Turbo scrolls a page it renders back to the top, which can come after he has lit something low on it.
      this.onLoad = () => {
        this.sync()
        this.show(this.lit?.[0])
      }
      this.onKey = (event) => this.key(event)
      this.onFocus = () => this.unfocus()
      this.onPick = (event) => (this.theirs = event.target.closest?.(FIELDS))
      this.onSend = (event) => this.sending(event)
      this.onSent = (event) => this.sent(event)
      document.addEventListener("turbo:load", this.onLoad)
      document.addEventListener("keydown", this.onKey)
      document.addEventListener("focusin", this.onFocus)
      document.addEventListener("pointerdown", this.onPick)
      document.addEventListener("turbo:submit-start", this.onSend)
      document.addEventListener("turbo:submit-end", this.onSent)

      // In development the search results open under a notice about resources with no search: ticked away here,
      // as its own "Don't show again" does.
      document.cookie = "avo_global_search_warning_closed=true; path=/; max-age=31536000"
      if (new URLSearchParams(location.search).has("tour")) this.replay()
      this.sync()
      this.follow()
    }

    disconnect() {
      document.removeEventListener("turbo:load", this.onLoad)
      document.removeEventListener("keydown", this.onKey)
      document.removeEventListener("focusin", this.onFocus)
      document.removeEventListener("pointerdown", this.onPick)
      document.removeEventListener("turbo:submit-start", this.onSend)
      document.removeEventListener("turbo:submit-end", this.onSent)
      cancelAnimationFrame(this.frame)
    }

    // Actions

    start() {
      this.save({ mode: "sound" })
    }

    withSound() {
      this.hear(true)
      this.go(0)
    }

    withoutSound() {
      this.hear(false)
      this.go(0)
    }

    // Says the line on screen again, out loud or not.
    mute() {
      this.hear(!this.hearing)
      this.scene = null
      this.sync()
    }

    next() {
      this.go(this.saved.index + 1)
    }

    back() {
      this.go(this.saved.index - 1)
    }

    resume() {
      this.go(this.saved.index)
    }

    // Escape closes him, and the right and left arrows turn the stops like slides. An arrow the page used itself (a
    // tab row, the image viewer) is left alone.
    key(event) {
      if (this.element.hidden || this.bubbleTarget.hidden) return
      if (event.key === "Escape") return this.end()

      // A field he opened, like the chat's composer, has focus without the visitor choosing it. It is theirs once
      // they click it or type in it, and from then on its arrows move their caret.
      const field = event.target.closest?.(FIELDS)
      if (field && event.key.length === 1) this.theirs = field

      const { mode, index } = this.saved
      const { steps } = this.copy
      const turn = { ArrowRight: 1, ArrowLeft: -1 }[event.key]
      const held = event.repeat || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey
      if (mode !== "running" || !turn || held || event.defaultPrevented || (field && field === this.theirs)) return
      if (!steps[index + turn] || (turn > 0 && steps[index].wait)) return

      event.preventDefault()
      this.go(index + turn)
    }

    greet() {
      this.save({ mode: "greeting" })
    }

    end() {
      this.save({ mode: "idle" })
    }

    finish() {
      localStorage.setItem("tour", "done")
      this.end()
    }

    never() {
      localStorage.setItem("tour", "never")
      this.sync()
    }

    // The visitor's turn: a stop that waits for a button has no Next, and moves on once the form that button sent has
    // gone through. By the button, because a card's Cancel sends the same form.
    sending({ detail }) {
      // Told apart as it starts. By its end the chat may have swapped the card over its live connection, and a
      // button that has left the page matches no selector.
      if (this.waiting && detail.formSubmission.submitter?.matches(this.waiting)) this.awaited = detail.formSubmission
    }

    sent({ detail }) {
      if (detail.formSubmission !== this.awaited) return

      this.awaited = null
      if (detail.success && this.waiting) this.next()
    }

    // What the stop expects has not come: the chat's answer, or the button the visitor is to press. The chat sends
    // over a live connection, and what went out before this page was listening is only on the server. Closing its
    // window and opening it again loads what the chat holds.
    async recover() {
      const { mode, index } = this.saved
      const step = mode === "running" && this.copy.steps[index]
      const expected = step && (step.expect || step.wait)
      if (!expected || !step.retry || document.querySelector(expected)) return (this.asked = null)

      this.asked ||= Date.now()
      if (Date.now() - this.asked < 8000 || this.tries >= 3) return

      this.asked = Date.now()
      this.tries += 1
      document.querySelector(step.retry)?.click()
      await new Promise((resolve) => setTimeout(resolve, 250))
      document.querySelector(step.retry)?.click()
    }

    get waiting() {
      const { mode, index } = this.saved
      return mode === "running" && this.copy.steps[index]?.wait
    }

    // Where the tour stands
    //
    // The tab remembers the mode and the stop, so a reload or a new page carries on. The browser remembers only
    // "never" (don't ask again) and "done" (no greeting next time).

    get saved() {
      if (localStorage.getItem("tour") === "never") return { mode: "never" }

      const fallback = localStorage.getItem("tour") === "done" ? "idle" : "greeting"
      return JSON.parse(sessionStorage.getItem("tour")) || { mode: fallback }
    }

    store(state) {
      sessionStorage.setItem("tour", JSON.stringify(state))
    }

    save(state) {
      this.store(state)
      this.sync()
    }

    get hearing() {
      return sessionStorage.getItem("tour-sound") === "on"
    }

    hear(on) {
      on ? sessionStorage.setItem("tour-sound", "on") : sessionStorage.removeItem("tour-sound")
    }

    // "?tour" on any page starts over, even after "Don't ask again": the profile menu links to it.
    replay() {
      localStorage.removeItem("tour")
      this.store({ mode: "running", index: 0 })
      history.replaceState(history.state, "", location.pathname)
    }

    // His lines, read from the page each time: see the note on the node that holds them.
    get copy() {
      return JSON.parse(document.getElementById("tour-copy").dataset.copy)
    }

    path(index) {
      const { path, follow } = this.copy.steps[index] || {}
      if (!follow) return path && `${window.Avo.configuration.root_path}/${path}`

      // Where a link on screen leads: the last match, as the product the chat named last. The tab remembers it for
      // the stops that stay on that page, where the link may be gone.
      const link = [...document.querySelectorAll(follow)].at(-1)
      if (link) sessionStorage.setItem("tour-followed", new URL(link.href).pathname)
      return sessionStorage.getItem("tour-followed")
    }

    // By the path alone: a stop's query (a filter) is gone from the address once the page applies it.
    away(index) {
      return this.path(index) && new URL(this.path(index), location.origin).pathname !== location.pathname
    }

    go(index) {
      this.acted = false
      this.tries = 0
      this.untype()
      const path = this.path(index)
      if (!path || path === location.pathname + location.search) return this.save({ mode: "running", index })

      // The stop is on another page. He holds still while it loads, and its first sync picks the tour up.
      this.store({ mode: "running", index })
      this.close()
      this.run = this.lit = null
      this.spotlightTarget.hidden = true
      window.Turbo.visit(path)
    }

    // Shows what the saved state says. Safe to call twice: it returns early when nothing changed.
    sync() {
      let { mode, index } = this.saved
      // The visitor left the stop's page on their own: he waits in his corner instead of dragging them back.
      if (mode === "running" && this.away(index)) {
        mode = "paused"
        this.store({ mode, index })
      }

      const scene = [mode, index, location.pathname].join()
      const same = scene === this.scene
      if (same && (this.lit || []).every((element) => element.isConnected)) return
      this.scene = scene

      const copy = this.copy
      const step = copy.steps[index] || {}
      const entering = this.element.hidden
      this.close()
      this.element.hidden = mode === "never"
      this.element.dataset.mode = mode
      this.mascotTarget.disabled = mode !== "idle"
      this.bubbleTarget.hidden = mode === "idle"
      this.greetingTarget.hidden = mode !== "greeting"
      this.soundTarget.hidden = mode !== "sound"
      this.navTarget.hidden = mode !== "running"
      this.pausedTarget.hidden = mode !== "paused"
      this.muteTarget.hidden = !["running", "paused"].includes(mode)
      this.muteTarget.setAttribute("aria-pressed", this.hearing)
      this.voiceOnTarget.hidden = !this.hearing
      this.voiceOffTarget.hidden = this.hearing

      if (mode === "running") {
        const last = index === copy.steps.length - 1
        const focused = document.activeElement === this.nextTarget
        this.counterTarget.textContent = `${index + 1} / ${copy.steps.length}`
        this.backTarget.hidden = index === 0
        this.nextTarget.hidden = last || !!step.wait
        this.doneTarget.hidden = !last
        if (last && focused) this.doneTarget.focus()
      }

      // With nothing to point at he waves: the greeting, the pause and the goodbye.
      this.element.classList.toggle("tour--waving", mode !== "idle" && !(mode === "running" && step.target))
      const line = { running: step, paused: copy.paused }[mode] || { text: copy[mode] }
      // A page that reloads under him, as after an action, swaps what he lit: he points again and says nothing twice.
      if (!same) this.say(line.text, line.clip)
      this.light(mode === "running" ? step : {})
      if (entering) this.animate(this.mascotTarget, [{ transform: "translateY(1rem) scale(0.6)", opacity: 0 }, {}], 450)
    }

    // His mouth moves for as long as the clip plays, or about as long as the line takes to read.
    say(text = "", clip) {
      const quiet = () => this.element.classList.remove("tour--talking")
      const mime = () => (this.hush = setTimeout(quiet, Math.min(text.length * 30, 2400)))

      // A line may carry one link, written [label](url). Built as nodes, so the copy never becomes markup.
      const [before, label, url, after] = text.split(/\[([^\]]+)\]\(([^)]+)\)/)
      this.textTarget.replaceChildren(before)
      if (url) {
        const link = Object.assign(document.createElement("a"), { href: url, target: "_blank", rel: "noopener" })
        link.textContent = label
        this.textTarget.append(link, after)
      }
      this.animate(this.bubbleTarget, [{ transform: "translateY(0.375rem)", opacity: 0 }, {}], 260)
      this.element.classList.add("tour--talking")
      clearTimeout(this.hush)
      this.voice.pause()
      if (!clip || !this.hearing) return mime()

      this.voice.src = clip
      this.voice.onended = quiet
      // After a reload no click has let him speak yet, so he mimes the line.
      this.voice.play().catch(mime)
    }

    // Lights what the stop points at. While he looks for it he holds still (lit is null), so a target that is
    // there already never shows him leaving for his corner first.
    async light({ open, click, target, place, type, enter, query }) {
      const run = (this.run = {})
      this.lit = null

      if (click || type) this.quiet = run
      // He clicks and types once per arrival at a stop. The sound button, or a page that reloads under him, only makes
      // him point again: the chat's question is not asked twice.
      if (this.acted) click = type = query = null
      this.acted = true
      this.drawer(target)
      // A table that loads once it is in view has nothing to click until then.
      if (target) this.show(document.querySelector(target))

      // The icon he opens is lit with what it opened: it shows where to hover.
      this.icon = (open && (await this.find(open))[0]) || null
      if (run !== this.run) return
      this.peek(this.icon)

      // Hidden ones too: an action's link waits inside a closed dropdown.
      const buttons = click ? await this.find(click, true) : []
      if (run !== this.run) return
      buttons.forEach((button) => button.click())
      setTimeout(() => this.unfocus(), 500)

      const found = target ? await this.find(target) : []
      if (run !== this.run) return

      this.point(found)
      this.side = place
      this.show(found[0])
      if (found.length) {
        const hop = { transform: "translateY(-0.5rem) rotate(-6deg)", offset: 0.4 }
        this.animate(this.mascotTarget, [{ transform: "none" }, hop, { transform: "none" }], 500)
      }
      if (type) this.type(target, type, enter, run)
      // A table that loads on its own inside the page has its own address, and its filters are part of it.
      const table = query && found[0]?.closest("turbo-frame[src]")
      if (table && !table.src.includes(query)) table.src = `${table.src}&${query}`
    }

    // Scrolls what he lights into the window. A table too tall for it, as on a phone, is shown from its top, clear
    // of the page's sticky header.
    show(element) {
      if (!element) return

      const tall = element.offsetHeight > innerHeight - 160
      if (tall) element.style.scrollMarginTop = "5rem"
      element.scrollIntoView({ block: tall ? "start" : "nearest" })
    }

    // What he lights can sit above him. The panel's top bar: a class lifts him over it. A modal, which the browser
    // draws over every page layer: he joins that top layer after it, as a popover, and leaves it with the stop.
    point(found) {
      const bar = document.querySelector(".top-navbar")
      this.element.classList.toggle("tour--over-bar", found.some((lit) => lit.contains(bar) || bar?.contains(lit)))
      const guide = this.guideTarget
      if (guide.matches(":popover-open")) guide.hidePopover()
      if (found.some((lit) => lit.closest(":popover-open, dialog:modal"))) guide.showPopover()

      this.lit = this.icon?.isConnected ? [this.icon, ...found] : found
      this.glide()
    }

    // What the stop points at is looked up again a few times a second, with no page load to say it changed: search
    // results arrive after he typed, the chat swaps its box once its chat exists, a card comes and goes.
    relight() {
      const { mode, index } = this.saved
      const target = mode === "running" && this.copy.steps[index]?.target
      if (!target || !this.lit) return

      const found = [...document.querySelectorAll(target)].filter((match) => match.getClientRects().length)
      // A table that fills in after he lit it grows out of the window: a change of height brings it back in.
      const tall = found[0]?.offsetHeight
      if (tall !== this.tall) this.show(found[0])
      this.tall = tall

      const lit = this.lit.filter((element) => element !== this.icon)
      if (found.length !== lit.length || found.some((match, at) => match !== lit[at])) this.point(found)
    }

    // Types into the target's plain field or rich box a key at a time, through its value and never by focusing it: on
    // a phone focus would bring up the keyboard.
    async type(target, text, enter, run) {
      const pause = () => new Promise((resolve) => setTimeout(resolve, 45))
      // Looked up at every key: the chat swaps its box for another when a chat is opened from its tab.
      const box = () => [...document.querySelectorAll(target)].find((match) => {
        return match.matches("input, textarea, lexxy-editor") && match.getClientRects().length
      })
      const line = document.createElement("p")

      for (let length = 1; length <= text.length + 1; length++) {
        await pause()
        const field = box()
        if (run !== this.run || !field) return

        const plain = field.matches("input, textarea")
        if (length > text.length) {
          const input = field.querySelector("[contenteditable]") || field
          const key = new KeyboardEvent("keydown", { key: "Enter", bubbles: true, cancelable: true })
          if (enter) input.dispatchEvent(key)
          break
        }
        line.textContent = text.slice(0, length)
        field.value = plain ? line.textContent : line.outerHTML
        if (plain) {
          this.typed = field
          field.dispatchEvent(new Event("input", { bubbles: true }))
        }
      }
      setTimeout(() => this.unfocus(), 500)
    }

    // A plain field he typed into is emptied when he moves on, and a click elsewhere closes what it opened.
    untype() {
      const field = this.typed
      this.typed = null
      if (!field?.isConnected) return

      field.value = ""
      field.dispatchEvent(new Event("input", { bubbles: true }))
      document.body.click()
    }

    // On a phone a focused field brings up the keyboard, and what he opens focuses one: the chat's composer, the
    // action's first field. While a stop that clicks or types is on, only a field the visitor tapped keeps focus.
    unfocus() {
      const focused = document.activeElement
      const touch = matchMedia("(pointer: coarse)").matches
      const field = focused?.matches(FIELDS) && focused !== this.theirs
      if (touch && field && this.quiet === this.run) focused.blur()
    }

    // On a phone the menu is a drawer. He opens it for a stop that points into it, and shuts it once he moves on.
    drawer(target) {
      const toggle = document.querySelector("[data-sidebar-toggle-icon]")
      if (this.opened && toggle?.dataset.sidebarState !== "open") this.opened = false

      const matches = target ? [...document.querySelectorAll(target)] : []
      const items = matches.filter((item) => item.closest(".avo-sidebar"))
      // The closed drawer waits off screen, left of the window.
      const wanted = items.length > 0 && (this.opened || !items.some((item) => item.getBoundingClientRect().right > 0))
      if (wanted === !!this.opened || !toggle) return

      toggle.click()
      this.opened = wanted
    }

    // The visible matches, waited for up to a second and a half: a page's frames and popovers arrive late.
    async find(selector, hidden = false) {
      for (let attempt = 0; attempt < 30; attempt++) {
        const matches = [...document.querySelectorAll(selector)]
        const visible = matches.filter((match) => hidden || match.getClientRects().length)
        if (visible.length) return visible

        await new Promise((resolve) => setTimeout(resolve, 50))
      }

      return []
    }

    // Opens a preview icon's popover and keeps it open while he talks: on its own it closes on any click.
    peek(icon) {
      this.peeked = icon?._tippy
      this.peeked?.setProps({ trigger: "manual", hideOnClick: false })
      this.peeked?.show()
    }

    close() {
      if (this.peeked && !this.peeked.state.isDestroyed) {
        this.peeked.setProps({ trigger: "mouseenter focus", hideOnClick: true })
        this.peeked.hide()
      }
      this.peeked = null
    }

    // Placing him
    //
    // Checked on every frame, because a scroll, a resize, a late frame or a growing popover all move the target.
    // Nothing is written unless something moved.

    follow() {
      this.frames = (this.frames || 0) + 1
      if (this.frames % 20 === 0) {
        this.relight()
        this.recover()
      }
      this.position()
      this.frame = requestAnimationFrame(() => this.follow())
    }

    glide() {
      this.placed = null
      this.element.classList.add("tour--gliding")
      clearTimeout(this.settle)
      this.settle = setTimeout(() => this.element.classList.remove("tour--gliding"), 600)
    }

    position() {
      if (!this.lit || this.element.hidden) return

      const guide = this.guideTarget
      const box = this.box()
      const { x, y, flip = false } = this.spot(box)
      const key = [box && Object.values(box).map(Math.round), Math.round(x), Math.round(y), flip].join()
      if (key === this.placed) return
      this.placed = key

      // His first appearance has nowhere to glide from.
      if (!guide.style.transform) this.element.classList.remove("tour--gliding")

      // Sized while still hidden, so a spotlight that comes back appears in place instead of sliding in.
      if (box) {
        const [area, bump] = this.shape(box)
        this.holeTargets.forEach((hole, at) => this.cut(hole, at % 2 ? bump : area, area))
      }
      this.spotlightTarget.hidden = !box

      guide.classList.toggle("tour__guide--flip", flip)
      guide.style.transform = `translate(${Math.round(x)}px, ${Math.round(y)}px)`
      this.aim(box, x, y)
    }

    // The window's width without its scrollbar.
    get width() {
      return document.documentElement.clientWidth
    }

    // The area that holds every lit element, kept inside the window. Null when none of it is on screen.
    box() {
      return this.area(this.lit)
    }

    // The boxes the spotlight is cut from. One around everything lit. Or two, when he opened it from an icon: the
    // area, and the icon reaching into it, so the ring runs around both as one shape.
    shape(box) {
      const icon = this.lit.includes(this.icon) && this.area([this.icon])
      const area = icon && this.area(this.lit.filter((element) => element !== this.icon))
      if (!area) return [box]

      const reach = 12
      const top = icon.top > area.bottom - reach ? area.bottom - reach : icon.top
      const bottom = icon.bottom < area.top + reach ? area.top + reach : icon.bottom
      const left = icon.left > area.right - reach ? area.right - reach : icon.left
      const right = icon.right < area.left + reach ? area.left + reach : icon.right
      return [area, { left, top, width: right - left, height: bottom - top }]
    }

    // A hole's place, as attributes and as styles: the styles are what glides, where a browser can.
    cut(hole, box, area) {
      const { left, top, width, height } = box || { left: area.left, top: area.top, width: 0, height: 0 }
      Object.entries({ x: left, y: top, width, height }).forEach(([name, value]) => {
        hole.setAttribute(name, value)
        hole.style[name] = `${value}px`
      })
    }

    area(elements) {
      const rects = elements.map((element) => element.getBoundingClientRect()).filter((rect) => rect.width)
      if (!rects.length) return null

      // Clear of the panel's top bar, which would hide the ring's top edge. Not when he is lifted over the bar.
      const lifted = this.element.classList.contains("tour--over-bar")
      const bar = (!lifted && document.querySelector(".top-navbar")?.getBoundingClientRect().bottom) || 0
      const left = Math.max(Math.min(...rects.map((rect) => rect.left)) - PAD, 4)
      const top = Math.max(Math.min(...rects.map((rect) => rect.top)) - PAD, bar + 4)
      const right = Math.min(Math.max(...rects.map((rect) => rect.right)) + PAD, this.width - 4)
      const bottom = Math.min(Math.max(...rects.map((rect) => rect.bottom)) + PAD, innerHeight - 4)

      if (right <= left || bottom <= top) return null

      return { left, top, right, bottom, width: right - left, height: bottom - top }
    }

    // Beside the box, on the first side with room. With no box, or one that fills the window, his corner.
    spot(box) {
      const { offsetWidth: width, offsetHeight: height } = this.guideTarget
      // The chat bar owns the very corner. He talks from above it, and waits to be asked tucked in beside it
      // when it leaves him room: on a phone the bar is as wide as the window.
      const beside = document.querySelector(".avo_ai_bar__dock")?.getBoundingClientRect().left - width - 8
      const corner = { x: Math.max(this.width - width - 20, EDGE), y: innerHeight - height - 64, flip: true }
      if (this.element.dataset.mode === "idle" && beside >= EDGE) return { x: beside, y: innerHeight - height - 16 }
      // Something that fills much of the window leaves him his corner, unless the stop says where to stand.
      if (!box || (!this.side && box.width * box.height > this.width * innerHeight * 0.35)) return corner

      const x = Math.min(Math.max(box.left + box.width / 2 - width / 2, EDGE), this.width - width - EDGE)
      const y = Math.min(Math.max(box.top + box.height / 2 - height / 2, EDGE), innerHeight - height - EDGE)
      // He stands at the end of the bubble nearest to what he points at. Above or below it, that is the right end
      // when the window's edge pushed the bubble left of the box.
      const flip = box.left + box.width / 2 > x + width / 2 + 1
      const sides = {
        right: box.right + GAP + width <= this.width - EDGE && { x: box.right + GAP, y },
        below: box.bottom + GAP + height <= innerHeight - EDGE && { x, y: box.bottom + GAP, flip },
        above: box.top - GAP - height >= EDGE && { x, y: box.top - GAP - height, flip },
        left: box.left - GAP - width >= EDGE && { x: box.left - GAP - width, y, flip: true }
      }

      return [this.side, "right", "below", "above", "left"].map((side) => sides[side]).find(Boolean) || corner
    }

    // Turns the arm on the box's side to the nearest point of it, and lets the other one hang.
    aim(box, x, y) {
      const mascot = this.mascotTarget
      const unit = mascot.offsetWidth / 28 // his drawing is 28 units wide and starts 2 units left of zero
      const left = x + mascot.offsetLeft
      const centre = left + mascot.offsetWidth / 2
      const shoulder = y + mascot.offsetTop + 13.4 * unit
      let side, angle

      if (box) {
        let to = {
          x: Math.min(Math.max(centre, box.left), box.right),
          y: Math.min(Math.max(shoulder, box.top), box.bottom)
        }
        // He stands inside it: its middle is the best he can point at.
        if (to.x === centre && to.y === shoulder) to = { x: box.left + box.width / 2, y: box.top + box.height / 2 }

        side = to.x < centre ? "left" : "right"
        const from = left + ((side === "left" ? 5.6 : 18.4) + 2) * unit
        // Never steeper than 50 degrees: straight up or down, the arm hides behind his body or looks at rest.
        const tilt = Math.min(Math.max((Math.atan2(to.y - shoulder, Math.abs(to.x - from)) * 180) / Math.PI, -50), 50)
        angle = side === "left" ? 180 - tilt : tilt
      }

      for (const arm of ["left", "right"]) this.turn(arm, arm === side ? angle : REST[arm], arm === side)
    }

    turn(arm, angle, pointing) {
      // The short way round: without this, going from 170 to -170 degrees swings through the front of him.
      const from = this.angles[arm]
      this.angles[arm] = from + ((((angle - from) % 360) + 540) % 360) - 180
      this.element.style.setProperty(`--tour-arm-${arm}`, `${this.angles[arm]}deg`)
      this[`${arm}ArmTarget`].classList.toggle("tour__arm--pointing", pointing)
    }

    animate(element, frames, duration) {
      if (!matchMedia("(prefers-reduced-motion: reduce)").matches) element.animate(frames, { duration, easing: EASE })
    }
  }

  window.Stimulus.register("tour", TourController)
})()
