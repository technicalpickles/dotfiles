# Community tmux Plugins for a “Pull Existing Windows into Panes” Workflow

This document summarizes **tmux community plugins** that align well with the workflow you’re learning: treating panes as _existing windows pulled together_, rather than empty splits you later populate.

The focus is on **discoverability, pane movement, and layout ergonomics**, not just splitting.

---

## Your Core Mental Model (Restated)

> In tmux, you don’t create an empty split and then fill it. You **pull an existing window (pane) into another window**, and tmux creates the split automatically.

This maps directly to `join-pane`, `break-pane`, and `swap-pane`, and the plugins below mainly **wrap, expose, or simplify** those primitives.

---

## Plugins That Fit This Model Well

### 1. **tmux‑menus** (you already have this)

**Best for: discoverability and learning**

- Popup menus that expose pane/window actions visually
- Makes commands like `join-pane`, `swap-pane`, `break-pane`, and layouts _findable_
- Excellent when you’re still forming muscle memory

**Why it fits your workflow**: You can _see_ pane‑movement operations instead of remembering flags like `-h -s -t`.

---

### 2. **tmux‑fzf**

**Best for: interactive selection of windows/panes**

- Fuzzy finder UI for tmux objects
- Lets you select **source panes/windows** instead of typing indexes
- Pairs extremely well with `join-pane`

**Why it fits your workflow**: It replaces:

```
join-pane -h -s :2
```

with:

> “Pick the pane/window you want to pull in.”

This aligns strongly with your _“pull existing window”_ mental model.

---

### 3. **tmux‑tilit**

**Best for: tiling‑WM style pane ergonomics**

- Adds intuitive tiling, movement, and resizing controls
- Encourages thinking in terms of **pane placement**, not raw splits
- Faster layout iteration once panes are together

**Why it fits your workflow**: After you join panes, this plugin makes rearranging and balancing them much easier without breaking focus.

---

### 4. **tmux‑propane**

**Best for: spatial pane movement across windows**

- Move and swap panes using directional intent (left/right/up/down)
- Reduces the need to think about source/target indices

**Why it fits your workflow**: Instead of _command‑driven_ movement, you get _spatial movement_, which feels closer to how screen regions used to behave.

---

### 5. **tmux‑which‑key / tmux‑modal**

**Best for: lowering cognitive load**

- Shows available keybindings dynamically (which‑key)
- Or groups pane actions into modes (modal)

**Why it fits your workflow**: Your workflow relies on **a small set of powerful commands** (mark, join, break). These plugins make those commands easier to discover and remember.

---

## How These Complement What You Already Use

You already have:

- **tmux‑pain‑control** → ergonomic splitting/navigation
- **tmux‑menus** → discoverability

Recommended additions **without overlap**:

- **tmux‑fzf** → selecting _which_ window/pane to pull
- **tmux‑tilit** or **tmux‑propane** → manipulating panes _after_ they’re joined

---

## Suggested Minimal Plugin Stack

If you want to keep things lean while reinforcing your mental model:

- tmux‑pain‑control
- tmux‑menus
- tmux‑fzf
- (optional) tmux‑tilit

This stack supports:

1. Create or navigate to existing windows
2. Select a window/pane interactively
3. Pull it into the current window
4. Rearrange panes ergonomically

---

## Key Insight

Most tmux plugins **don’t replace **``.

The good ones:

- Reduce **index typing**
- Improve **discoverability**
- Let you think in **spatial or interactive terms** instead of flags

That means your current learning path is _exactly right_ — plugins simply smooth the edges.

---

If you want, the next natural step would be:

- A **single “pull pane here” keybinding** backed by `fzf`
- Or a **mark/join workflow wrapped in menus**

Both are very achievable with what you already have.
