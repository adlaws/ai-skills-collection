---
name: rider-plugin-developer
description: 'Guidelines and pitfalls for developing JetBrains/Rider/IntelliJ plugins in Kotlin. Use when building plugin UI with tool windows, trees, split panes, detail panels, HTML rendering, mouse event handling, background tasks, SVG icons, or Swing components inside the IntelliJ Platform. Covers Gradle setup, plugin.xml, threading, CSS limitations, and common NPEs.'
---

# Rider / JetBrains Plugin Developer

Hard-won lessons from building IntelliJ Platform plugins in Kotlin. This skill captures platform-specific gotchas, Swing/AWT constraints inside IntelliJ, and correct patterns for common plugin features.

## When to Use This Skill

- Building or modifying a JetBrains/IntelliJ/Rider plugin
- Creating tool window UIs with trees, split panes, or detail panels
- Rendering HTML content inside `JEditorPane`
- Handling mouse events on `com.intellij.ui.treeStructure.Tree`
- Running background tasks and updating the UI from results
- Troubleshooting plugin icons not displaying
- Working with `plugin.xml`, Gradle IntelliJ Plugin, or services

## Project Setup

### Gradle & Dependencies

```kotlin
plugins {
    id("org.jetbrains.kotlin.jvm") version "1.9.25"
    id("org.jetbrains.intellij") version "1.17.4"
}

intellij {
    version.set("2024.1.4")
    type.set("IC") // Community — works across all JetBrains IDEs including Rider
}

dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.12.0")  // HTTP client
    implementation("com.google.code.gson:gson:2.11.0")     // JSON
    implementation("org.yaml:snakeyaml:2.2")               // YAML frontmatter
}
```

- JVM target: **17**
- `sinceBuild`: **241**, `untilBuild`: **261.\***
- Set `kotlin.stdlib.default.dependency = false` in `gradle.properties`

### plugin.xml Essentials

- Use `<depends>com.intellij.modules.platform</depends>` for cross-IDE compatibility
- Register services with `<applicationService>` (global) or `<projectService>` (per-project)
- Tool windows use `<toolWindow>` with a `factoryClass` implementing `ToolWindowFactory`
- Icon paths in `<toolWindow icon="...">` are relative to `src/main/resources/`

---

## UI: Critical Swing/AWT Pitfalls Inside IntelliJ

### JEditorPane HTML/CSS — ONLY CSS1 Is Supported

**THIS IS THE #1 GOTCHA.** Java's `JEditorPane("text/html", ...)` uses an ancient HTML 3.2 / CSS1 renderer. Using CSS2/CSS3 properties causes a **silent `NullPointerException`** deep in `javax.swing.text.html.CSS` that crashes `setText()`.

#### Properties That CRASH JEditorPane

| Property | Crash? | Reason |
|----------|--------|--------|
| `border-radius` | **YES** | Not in CSS1 |
| `overflow-x` / `overflow-y` | **YES** | Not in CSS1 |
| `display: inline-block` | **YES** | Only `block`, `inline`, `list-item`, `none` |
| `line-height: 1.5` (unitless) | **YES** | Must use `pt`, `px`, or `%` |
| `background` (shorthand) | **YES** | Use `background-color` instead |
| `margin` (shorthand with 2+ values) | **YES** | Use `margin-top`, `margin-bottom`, etc. |
| `padding` (shorthand with 2+ values) | **YES** | Use `padding-top`, `padding-left`, etc. |
| `border: none` | **YES** | Not recognized |

#### Safe CSS Pattern

```css
body { font-family: sans-serif; font-size: 12pt; margin: 12px;
       background-color: #2b2d30; color: #bbbbbb; }
h1 { margin-top: 0; margin-bottom: 4px; }
pre { background-color: #1e1e1e; padding: 10px; }
code { background-color: #1e1e1e; padding: 2px; }
a { color: #589df6; }
```

#### Error Signature When CSS Is Wrong

```
java.lang.NullPointerException: Cannot invoke "javax.swing.text.html.CSS$CssValue.parseCssValue(String)" because "conv" is null
    at javax.swing.text.html.CSS.getInternalCSSValue(CSS.java:849)
```

If you see this stack trace, **strip all non-CSS1 properties from your `<style>` block**.

### Theme-Aware Colors

Use IntelliJ's `UIUtil` for theme-compatible colors:

```kotlin
val bg = UIUtil.getPanelBackground()
val fg = UIUtil.getLabelForeground()
val muted = UIUtil.getInactiveTextColor()
val isDark = UIUtil.isUnderDarcula() // deprecated but functional
fun colorToHex(c: Color) = String.format("#%02x%02x%02x", c.red, c.green, c.blue)
```

---

### Mouse Events on IntelliJ's Tree Component

**`TreeSelectionListener` is UNRELIABLE** on `com.intellij.ui.treeStructure.Tree`. Selection events may not fire on click. **`mouseClicked` is UNRELIABLE on Linux** — any sub-pixel mouse movement between press and release suppresses it.

#### Correct Pattern: Use `mousePressed`

```kotlin
tree.addMouseListener(object : MouseAdapter() {
    override fun mousePressed(e: MouseEvent) {
        if (e.isPopupTrigger) { handlePopup(e); return }
        if (SwingUtilities.isLeftMouseButton(e)) {
            val path = tree.getPathForLocation(e.x, e.y) ?: return
            val node = path.lastPathComponent as? DefaultMutableTreeNode ?: return
            val data = node.userObject as? MyNodeData ?: return
            if (e.clickCount == 2) {
                openResource(data)
            } else {
                SwingUtilities.invokeLater { detailPanel.showItem(data) }
            }
        }
    }
    override fun mouseReleased(e: MouseEvent) { handlePopup(e) }
})
```

Key points:
- **`mousePressed`** always fires — use it for detail panel updates
- **`mouseReleased`** handles popup trigger on Linux (where `isPopupTrigger` is true on release, not press)
- Use `tree.getPathForLocation(e.x, e.y)` — not `tree.lastSelectedPathComponent` — because selection state may not be updated yet
- Wrap detail panel updates in `SwingUtilities.invokeLater` so the tree repaints selection highlight first
- Handle right-click context menus in the SAME MouseAdapter to avoid event conflicts

#### Things That Do NOT Work

| Approach | Problem |
|----------|---------|
| `tree.addTreeSelectionListener` | Events don't fire reliably on IntelliJ's `Tree` |
| `mouseClicked` handler | Suppressed on Linux with any mouse movement between press/release |
| `tree.lastSelectedPathComponent` in mousePressed | Selection may not be updated yet at press time |

---

### Threading & Background Tasks

#### EDT Rules

- All Swing/UI updates **MUST** run on the Event Dispatch Thread (EDT)
- File I/O, network calls, and heavy computation **MUST NOT** run on EDT

#### Lightweight Background Work (Preferred)

```kotlin
ApplicationManager.getApplication().executeOnPooledThread {
    val result = doExpensiveWork()
    ApplicationManager.getApplication().invokeLater {
        updateUI(result) // runs on EDT
    }
}
```

#### Heavy Tasks with Progress Bar

```kotlin
ProgressManager.getInstance().run(object : Task.Backgroundable(project, "Working…", false) {
    override fun run(indicator: ProgressIndicator) {
        // runs on background thread
    }
})
```

Use `executeOnPooledThread` for quick operations (detail panel content fetch). Reserve `ProgressManager` for user-visible long operations (install, update). Using `ProgressManager` for every click causes noticeable UI lag.

#### Parallel HTTP Requests

```kotlin
val executor = Executors.newFixedThreadPool(8)
val futures = items.map { item ->
    executor.submit(Callable { fetchItem(item) })
}
val results = futures.mapNotNull { it.get() }
```

Use `ConcurrentHashMap` for thread-safe result collection. OkHttp timeouts should be 15s (not 30s) for interactive UI.

---

## SVG Icons for Plugin Logo

The `pluginIcon.svg` and `pluginIcon_dark.svg` files shown in the JetBrains plugin installation panel must be **clean SVGs**:

### Requirements

- Place in `src/main/resources/` (root of resources)
- Size: **40×40px** recommended
- Must be named exactly `pluginIcon.svg` and `pluginIcon_dark.svg`

### SVG Gotchas

| Issue | Symptom | Fix |
|-------|---------|-----|
| Inkscape metadata | Icon doesn't render | Remove `sodipodi:*`, `inkscape:*` namespaces |
| `xml:space="preserve"` | Icon doesn't render | Remove attribute |
| CSS `style` attributes | May not render | Use direct `fill="..."` attributes on elements |
| Large file size (>10KB) | Slow/broken render | Strip metadata, optimize paths |

### Clean SVG Template

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40" width="40" height="40">
    <path d="M..." fill="#4A90D9"/>
</svg>
```

---

## Tool Window Architecture

### Split Pane with Detail Panel

```kotlin
// Tree on top, detail panel on bottom
val splitPane = JSplitPane(JSplitPane.VERTICAL_SPLIT, treePanel, detailPanel)
splitPane.resizeWeight = 0.55  // 55% tree, 45% detail
splitPane.dividerSize = 5
splitPane.isContinuousLayout = true
```

### Loading Overlay with CardLayout

```kotlin
private val treeCard = JPanel(CardLayout())
private val CARD_TREE = "tree"
private val CARD_LOADING = "loading"

fun showLoading() {
    (treeCard.layout as CardLayout).show(treeCard, CARD_LOADING)
}
fun showTree() {
    (treeCard.layout as CardLayout).show(treeCard, CARD_TREE)
}
```

### Animated Spinner

Use IntelliJ's built-in step icons with a `javax.swing.Timer`:

```kotlin
private val spinnerIcons = arrayOf(
    AllIcons.Process.Step_1, AllIcons.Process.Step_2,
    AllIcons.Process.Step_3, AllIcons.Process.Step_4,
    AllIcons.Process.Step_5, AllIcons.Process.Step_6,
    AllIcons.Process.Step_7, AllIcons.Process.Step_8
)
private var spinnerIndex = 0
private val spinnerTimer = Timer(100) {
    loadingLabel.icon = spinnerIcons[spinnerIndex % spinnerIcons.size]
    spinnerIndex++
}
```

### Multi-Select Trees

```kotlin
tree.selectionModel.selectionMode = TreeSelectionModel.DISCONTIGUOUS_TREE_SELECTION
// When canSelectMany is enabled, adapt context menus to selection count
val selectedItems = tree.selectionPaths?.mapNotNull {
    (it.lastPathComponent as? DefaultMutableTreeNode)?.userObject as? MyNodeData
} ?: emptyList()
```

---

## Common Patterns

### Service Registration

```xml
<!-- Application-level (singleton across IDE) -->
<applicationService serviceImplementation="com.example.MySettingsService"/>

<!-- Project-level (one per open project) -->
<projectService serviceImplementation="com.example.MyProjectService"/>
```

Access:
```kotlin
// Application service
val settings = service<MySettingsService>() // or MySettingsService.getInstance()

// Project service
val projectService = project.service<MyProjectService>()
```

### PersistentStateComponent for Settings

```kotlin
@State(name = "MySettings", storages = [Storage("myPlugin.xml")])
class MySettingsService : PersistentStateComponent<MySettingsService.State> {
    data class State(var myProp: String = "default")
    private var state = State()
    override fun getState() = state
    override fun loadState(s: State) { state = s }
}
```

### File Watching

Use IntelliJ's VFS listener for file change detection:

```kotlin
val connection = project.messageBus.connect(disposable)
connection.subscribe(VirtualFileManager.VFS_CHANGES, object : BulkFileListener {
    override fun after(events: List<VFileEvent>) {
        // Filter events by path and refresh UI
    }
})
```

---

## Debugging Tips

- **Log location**: Help → Show Log in Explorer (or `~/.cache/JetBrains/<product>/log/idea.log`)
- Use `Logger.getInstance(MyClass::class.java)` with `LOG.warn()` for visible diagnostic output
- `LOG.info()` may be filtered out by default; use `LOG.warn()` during debugging
- To verify click handling: temporarily update a visible label text + color in the handler before any complex logic
- Build cycle: `./gradlew buildPlugin` produces a `.zip` in `build/distributions/`

## Troubleshooting

| Issue | Root Cause | Solution |
|-------|-----------|----------|
| Detail panel shows blank on click | CSS2/3 in HTML causes NPE in `JEditorPane.setText()` | Use only CSS1 properties |
| Tree clicks don't fire handlers | Using `TreeSelectionListener` | Switch to `MouseAdapter.mousePressed` |
| Left clicks unresponsive | Using `mouseClicked` (unreliable on Linux) | Switch to `mousePressed` |
| Plugin icon missing in Marketplace | SVG has Inkscape metadata or CSS styles | Clean SVG, use `fill` attributes |
| UI freezes on click | Blocking EDT with I/O or network | Use `executeOnPooledThread` + `invokeLater` |
| Slow marketplace loading | Sequential HTTP requests | Parallelize with `Executors.newFixedThreadPool` |
| `ProgressManager` causes lag | Heavy overhead for simple tasks | Use `executeOnPooledThread` for lightweight work |
| `CardLayout` card doesn't switch | Forgot `revalidate()` + `repaint()` | Call both after `show()` |
