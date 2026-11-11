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

  class TourController extends Controller {
    static targets = [
      "spotlight", "guide", "mascot", "leftArm", "rightArm", "bubble", "text",
      "greeting", "sound", "nav", "paused", "counter", "back", "next", "done", "mute", "voiceOn", "voiceOff"
    ]

    static values = { steps: Array, greeting: String, sound: String, paused: Object }

    // Runs on every page: Turbo carries the node over, and Stimulus disconnects and connects it on the way.
    connect() {
      if (this.lit === undefined) this.lit = []
      this.angles ||= { ...REST }
      // One player for every line: a browser lets a player speak again once a click has let it speak.
      this.voice ||= new Audio()
      this.onLoad = () => this.sync()
      this.onKey = (event) => event.key === "Escape" && !this.element.hidden && !this.bubbleTarget.hidden && this.end()
      document.addEventListener("turbo:load", this.onLoad)
      document.addEventListener("keydown", this.onKey)

      if (new URLSearchParams(location.search).has("tour")) this.replay()
      this.sync()
      this.follow()
    }

    disconnect() {
      document.removeEventListener("turbo:load", this.onLoad)
      document.removeEventListener("keydown", this.onKey)
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

    path(index) {
      const path = this.stepsValue[index]?.path
      return path && `${window.Avo.configuration.root_path}/${path}`
    }

    // By the path alone: a stop's query (a filter) is gone from the address once the page applies it.
    away(index) {
      return this.path(index) && new URL(this.path(index), location.origin).pathname !== location.pathname
    }

    go(index) {
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
      if (scene === this.scene && (this.lit || []).every((element) => element.isConnected)) return
      this.scene = scene

      const step = this.stepsValue[index] || {}
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
        const last = index === this.stepsValue.length - 1
        const focused = document.activeElement === this.nextTarget
        this.counterTarget.textContent = `${index + 1} / ${this.stepsValue.length}`
        this.backTarget.hidden = index === 0
        this.nextTarget.hidden = last
        this.doneTarget.hidden = !last
        if (last && focused) this.doneTarget.focus()
      }

      // With nothing to point at he waves: the greeting, the pause and the goodbye.
      this.element.classList.toggle("tour--waving", mode !== "idle" && !(mode === "running" && step.target))
      const asked = { greeting: this.greetingValue, sound: this.soundValue }
      const line = { running: step, paused: this.pausedValue }[mode] || { text: asked[mode] }
      this.say(line.text, line.clip)
      this.light(mode === "running" ? step : {})
      if (entering) this.animate(this.mascotTarget, [{ transform: "translateY(1rem) scale(0.6)", opacity: 0 }, {}], 450)
    }

    // His mouth moves for as long as the clip plays, or about as long as the line takes to read.
    say(text = "", clip) {
      const quiet = () => this.element.classList.remove("tour--talking")
      const mime = () => (this.hush = setTimeout(quiet, Math.min(text.length * 30, 2400)))

      this.textTarget.textContent = text
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
    async light({ open, click, target, place, type, enter }) {
      const run = (this.run = {})
      this.lit = null

      const icon = open && (await this.find(open))[0]
      if (run !== this.run) return
      this.peek(icon)

      // Hidden ones too: an action's link waits inside a closed dropdown.
      const buttons = click ? await this.find(click, true) : []
      if (run !== this.run) return
      buttons.forEach((button) => button.click())

      const found = target ? await this.find(target) : []
      if (run !== this.run) return

      this.lit = found
      this.side = place
      found[0]?.scrollIntoView({ block: "nearest" })
      this.glide()
      if (found.length) {
        const hop = { transform: "translateY(-0.5rem) rotate(-6deg)", offset: 0.4 }
        this.animate(this.mascotTarget, [{ transform: "none" }, hop, { transform: "none" }], 500)
      }
      if (type && found[0]) this.type(found[0], type, enter, run)
    }

    // Types into the lit field a key at a time, as the browser's own typing does, so a rich editor takes it too.
    async type(field, text, enter, run) {
      const pause = () => new Promise((resolve) => setTimeout(resolve, 45))
      const input = field.matches("[contenteditable]") ? field : field.querySelector("[contenteditable]") || field
      if (input.textContent.trim() === text) return

      input.focus()
      document.execCommand("selectAll")
      document.execCommand("delete")
      for (const key of text) {
        await pause()
        if (run !== this.run) return
        document.execCommand("insertText", false, key)
      }
      await pause()
      if (enter && run === this.run) {
        input.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter", bubbles: true, cancelable: true }))
      }
    }

    // The visible matches, waited for up to a second and a half: a page's frames and popovers arrive late.
    async find(selector, hidden = false) {
      for (let attempt = 0; attempt < 30; attempt++) {
        const visible = [...document.querySelectorAll(selector)].filter((element) => hidden || element.getClientRects().length)
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
      const spotlight = this.spotlightTarget
      if (box) {
        Object.assign(spotlight.style, {
          top: `${box.top}px`, left: `${box.left}px`, width: `${box.width}px`, height: `${box.height}px`
        })
      }
      spotlight.hidden = !box

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
      const rects = this.lit.map((element) => element.getBoundingClientRect()).filter((rect) => rect.width)
      if (!rects.length) return null

      const left = Math.max(Math.min(...rects.map((rect) => rect.left)) - PAD, 4)
      const top = Math.max(Math.min(...rects.map((rect) => rect.top)) - PAD, 4)
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
      if (!box || box.width * box.height > this.width * innerHeight * 0.35) return corner

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
