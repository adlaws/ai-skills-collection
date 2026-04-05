---
name: vscode-extension-developer
description: 'Guidelines and patterns for developing VS Code extensions in TypeScript. Use when building tree views, webview panels, multi-select commands, file watchers, GitHub API integration, activity bar containers, status bar items, configuration schemas, or esbuild bundling for VS Code extensions. Covers contribution points, when clauses, contextValue patterns, and common pitfalls.'
---

# VS Code Extension Developer

Patterns and pitfalls learned from building feature-rich VS Code extensions in TypeScript. Covers tree views, webview panels, multi-select, file watching, GitHub API integration, and bundling.

## When to Use This Skill

- Building or modifying a VS Code extension
- Creating tree views with context menus, multi-select, and inline buttons
- Building webview panels with message passing and theme-aware CSS
- Implementing file watchers and configuration change listeners
- Integrating with the GitHub API (Contents API, Trees API, raw content)
- Setting up esbuild bundling for VS Code extensions
- Troubleshooting `when` clauses, `contextValue`, or menu contributions

## Project Setup

### Minimum Files

```
extension/
├── package.json          # Extension manifest (contribution points)
├── tsconfig.json         # TypeScript config
├── esbuild.js            # Bundler config
├── src/
│   ├── extension.ts      # activate() / deactivate() entry point
│   ├── types.ts          # Shared interfaces and enums
│   ├── views/            # TreeDataProviders, WebviewPanels
│   ├── services/         # Business logic (install, path resolution, etc.)
│   └── github/           # API clients
└── resources/            # Icons, logo
```

### TypeScript Configuration

```json
{
    "compilerOptions": {
        "module": "Node16",
        "target": "ES2022",
        "strict": true,
        "noImplicitReturns": true,
        "noFallthroughCasesInSwitch": true,
        "noUnusedParameters": true,
        "esModuleInterop": true,
        "resolveJsonModule": true,
        "skipLibCheck": true,
        "outDir": "out",
        "rootDir": "src"
    }
}
```

- `outDir: "out"` is for **tests only** (tsc output). Runtime uses esbuild's `dist/`.
- `skipLibCheck: true` — faster builds, skips `.d.ts` type checking.

### esbuild Configuration

```javascript
const esbuild = require('esbuild');
await esbuild.build({
    entryPoints: ['src/extension.ts'],
    bundle: true,
    outfile: 'dist/extension.js',
    external: ['vscode'],  // CRITICAL: vscode module is provided by the host
    format: 'cjs',
    platform: 'node',
    sourcemap: !production,
    minify: production,
    sourcesContent: false,
});
```

- **`external: ['vscode']`** is mandatory — the `vscode` module is injected by the extension host, not an npm package.
- **`platform: 'node'`** — Node.js builtins are available in the extension host.
- **`format: 'cjs'`** — CommonJS is required for VS Code extensions.
- Set `"main": "./dist/extension.js"` in `package.json`.

### Dual Build Output

| Directory | Tool | Purpose |
|-----------|------|---------|
| `dist/` | esbuild | Runtime bundle (what ships in VSIX) |
| `out/` | tsc | Test compilation (Mocha needs individual files) |

Watch mode runs both in parallel: `npm-run-all -p watch:esbuild watch:tsc`.

---

## package.json Contribution Points

### Activation Events

```json
"activationEvents": [
    "onView:myExtension.viewId"
]
```

Use `onView:` for lazy activation — extension loads only when the user opens the view. Avoid `*` (activates on every VS Code launch).

### Activity Bar View Container

```json
"viewsContainers": {
    "activitybar": [{
        "id": "my-extension",
        "title": "My Extension",
        "icon": "resources/icon.svg"
    }]
},
"views": {
    "my-extension": [
        { "id": "myExtension.treeView1", "name": "View 1" },
        { "id": "myExtension.treeView2", "name": "View 2" }
    ]
}
```

### viewsWelcome — Empty State Content

```json
"viewsWelcome": [{
    "view": "myExtension.treeView2",
    "contents": "Nothing here yet.\n[Open Settings](command:myExtension.openSettings)"
}]
```

Supports clickable `command:` URIs in the content markdown.

### Commands with Codicons

```json
{
    "command": "myExtension.install",
    "title": "Install",
    "icon": "$(cloud-download)",
    "category": "My Extension"
}
```

Every command that appears as a toolbar or inline button needs an `icon` using `$(codicon-name)` syntax.

---

## Menus: The `when` Clause and `contextValue` System

### How It Works

1. **Tree items** set `contextValue` (a string) in the `TreeItem` constructor.
2. **Menu entries** in `package.json` use `when: "viewItem == 'someValue'"` to target specific item types.
3. `view == 'myExtension.viewId'` scopes to a specific tree view.

### Critical Pattern: Scope × State Context Values

When items have multiple dimensions (e.g. scope AND update status), encode both in the `contextValue`:

```typescript
// In your TreeItem constructor:
this.contextValue = resource.scope === 'local'
    ? (hasUpdate ? 'installedResourceWorkspaceUpdatable' : 'installedResourceWorkspace')
    : (hasUpdate ? 'installedResourceGlobalUpdatable' : 'installedResourceGlobal');
```

**Gotcha:** This creates 4 variants, and every menu entry must enumerate ALL applicable variants:

```json
{
    "command": "myExtension.uninstall",
    "when": "view == 'myExtension.installed' && viewItem =~ /^installedResource/",
    "group": "2_remove@1"
}
```

Use **regex matching** (`viewItem =~ /pattern/`) to avoid listing every variant. This is much cleaner than long `||` chains.

### Menu Groups and Ordering

```json
"view/item/context": [
    { "command": "cmd1", "group": "inline@1" },     // Icon button, position 1
    { "command": "cmd2", "group": "inline@2" },     // Icon button, position 2
    { "command": "cmd3", "group": "navigation@1" }, // Context menu, top section
    { "command": "cmd4", "group": "1_actions@1" },  // Context menu, named section
    { "command": "cmd5", "group": "2_remove@1" }    // Context menu, separator before this
]
```

- **`inline@N`** — icon buttons on the tree row (right side). Keep to 2-3 max.
- **`navigation@N`** — top section of context menu (no separator above).
- **`N_name@M`** — numbered prefix controls separator placement. Same prefix = same group.
- A command often appears **twice**: once in `inline` (button) and once in a named group (right-click menu).

### Custom Context Keys for Toolbar Buttons

```typescript
// Set programmatically:
vscode.commands.executeCommand('setContext', 'myExtension:searchActive', true);
```

```json
{
    "command": "myExtension.clearSearch",
    "when": "view == 'myExtension.marketplace' && myExtension:searchActive",
    "group": "navigation@3"
}
```

Use context keys to toggle toolbar buttons conditionally (e.g. show "Clear Search" only when a search is active).

---

## Tree Views

### Creating Tree Views (Not Just Registering)

```typescript
// Use createTreeView() — NOT registerTreeDataProvider()
const treeView = vscode.window.createTreeView('myExtension.viewId', {
    treeDataProvider: provider,
    canSelectMany: true,      // Enable Shift+Click, Ctrl+Click
    showCollapseAll: true,    // Add collapse-all button to toolbar
});
context.subscriptions.push(treeView);
```

You need the `TreeView` object for `canSelectMany`, `showCollapseAll`, and `.reveal()`.

### TreeItem Subclasses Pattern

Create distinct subclasses per tree level:

```typescript
class RepoTreeItem extends vscode.TreeItem {
    constructor(public readonly repo: Repository) {
        super(repo.label, vscode.TreeItemCollapsibleState.Expanded);
    }
}
class CategoryTreeItem extends vscode.TreeItem {
    constructor(public readonly category: string, itemCount: number) {
        super(category, vscode.TreeItemCollapsibleState.Collapsed);
        this.description = `${itemCount}`;
    }
}
class ResourceTreeItem extends vscode.TreeItem {
    constructor(public readonly resource: ResourceItem) {
        super(resource.name, vscode.TreeItemCollapsibleState.None);
        this.contextValue = 'resource';
        this.command = { command: 'myExtension.preview', title: 'Preview', arguments: [this] };
        this.tooltip = new vscode.MarkdownString(`**${resource.name}**\n\n${resource.description}`);
        this.iconPath = new vscode.ThemeIcon('file');
    }
}
```

- **Click-to-preview**: Set `this.command` on leaf items to auto-trigger a command on click.
- **Rich tooltips**: Use `vscode.MarkdownString` with `appendMarkdown()` — supports bold, code, links.
- Store the data model (`resource`, `repo`) as a public readonly field for easy extraction in command handlers.

### Multi-Select Command Handling

When `canSelectMany: true`, VS Code passes `(clickedItem, selectedItems[])`:

```typescript
function resolveItems(
    clicked: ResourceTreeItem | ResourceItem,
    selected?: (ResourceTreeItem | ResourceItem)[]
): ResourceItem[] {
    if (selected && selected.length > 0) {
        return selected
            .map(s => s instanceof ResourceTreeItem ? s.resource : s)
            .filter(Boolean);
    }
    return [clicked instanceof ResourceTreeItem ? clicked.resource : clicked];
}

// Command registration:
vscode.commands.registerCommand('myExtension.install', (clicked, selected) => {
    const items = resolveItems(clicked, selected);
    // items is always an array, even for single clicks
});
```

**Gotcha:** The `selected` array **includes** the clicked item. Don't process the `clicked` item separately when `selected` has content.

### Bulk Operations Pattern

```typescript
await vscode.window.withProgress(
    { location: vscode.ProgressLocation.Notification, title: 'Installing...', cancellable: true },
    async (progress, token) => {
        for (const [i, item] of items.entries()) {
            if (token.isCancellationRequested) break;
            progress.report({ increment: (1 / items.length) * 100, message: item.name });
            await installItem(item);
        }
    }
);
```

For bulk **uninstall**, show a single "Remove All" confirmation, then use a silent variant (no per-item dialog):

```typescript
if (items.length > 1) {
    const confirm = await vscode.window.showWarningMessage(
        `Remove ${items.length} resources?`, { modal: true }, 'Remove All'
    );
    if (confirm !== 'Remove All') return;
    for (const item of items) {
        await uninstallSilent(item); // No per-item confirmation
    }
}
```

---

## Webview Panels

### Singleton-Per-Resource Pattern

```typescript
class DetailPanel {
    private static panels = new Map<string, DetailPanel>();

    static createOrShow(extensionUri: vscode.Uri, item: ResourceItem) {
        const key = item.id;
        const existing = this.panels.get(key);
        if (existing) { existing._panel.reveal(); return existing; }

        const panel = vscode.window.createWebviewPanel(
            'myExtension.detail', item.name,
            vscode.ViewColumn.One,
            { enableScripts: true, retainContextWhenHidden: true,
              localResourceRoots: [extensionUri] }
        );
        const instance = new DetailPanel(panel, item, extensionUri);
        this.panels.set(key, instance);
        return instance;
    }
}
```

- **`retainContextWhenHidden: true`** keeps webview state alive when tab is hidden (trades memory for UX).
- **`localResourceRoots`** restricts file access to extension directory only.

### Content Security Policy

```typescript
const nonce = generateNonce(); // Random 32-char string
const csp = `default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}'`;
```

```html
<meta http-equiv="Content-Security-Policy" content="${csp}">
<script nonce="${nonce}">...</script>
```

- **`default-src 'none'`** — blocks everything by default.
- **`style-src 'unsafe-inline'`** — allows inline `<style>` blocks.
- **`script-src 'nonce-...'`** — only scripts with the matching `nonce` attribute can run.
- No external resources can be loaded (images, fonts, scripts).

### Theme-Aware CSS with VS Code Variables

```css
body {
    color: var(--vscode-foreground);
    background-color: var(--vscode-editor-background);
    font-family: var(--vscode-font-family);
    font-size: var(--vscode-font-size);
}
a { color: var(--vscode-textLink-foreground); }
button {
    background-color: var(--vscode-button-background);
    color: var(--vscode-button-foreground);
}
pre {
    background-color: var(--vscode-textBlockQuote-background);
    border-left: 3px solid var(--vscode-textBlockQuote-border);
}
```

VS Code injects CSS variables that automatically match the active theme. **Always use these** instead of hardcoded colors.

### Message Passing (Webview ↔ Extension)

```typescript
// In webview script:
const vscode = acquireVsCodeApi(); // Can only be called ONCE
document.getElementById('installBtn')?.addEventListener('click', () => {
    vscode.postMessage({ command: 'install', scope: 'workspace' });
});

// In extension:
panel.webview.onDidReceiveMessage(message => {
    switch (message.command) {
        case 'install':
            vscode.commands.executeCommand('myExtension.install', item, message.scope);
            break;
        case 'openExternal':
            vscode.env.openExternal(vscode.Uri.parse(message.url));
            break;
    }
}, undefined, disposables);
```

**Gotcha:** `acquireVsCodeApi()` can only be called once per webview lifecycle. Calling it twice throws.

### HTML Escaping

```typescript
function escapeHtml(text: string): string {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}
```

**Always escape** user-provided content injected into HTML strings. Never use template literals with raw user strings.

### Markdown Rendering

```typescript
import markdownIt from 'markdown-it';
const md = markdownIt({ html: false, linkify: true, typographer: true });
const rendered = md.render(content);
```

- **`html: false`** — prevents raw HTML injection from markdown content.
- **`linkify: true`** — auto-links bare URLs.

---

## File System Operations

### Path Resolution with `~/` Convention

```typescript
import * as os from 'os';

function resolvePath(location: string, workspaceFolder?: vscode.WorkspaceFolder): vscode.Uri | undefined {
    if (location.startsWith('~')) {
        const expanded = location.replace(/^~/, os.homedir());
        return vscode.Uri.file(expanded);
    }
    if (!workspaceFolder) return undefined;
    return vscode.Uri.joinPath(workspaceFolder.uri, ...location.split(/[/\\]/));
}

function isGlobal(location: string): boolean {
    return location.startsWith('~');
}
```

- Paths starting with `~` are global (home directory).
- All other paths are workspace-relative.
- Use `vscode.Uri.joinPath()` with individual path segments (not string concatenation).

### Delete to Trash

```typescript
await vscode.workspace.fs.delete(uri, { recursive: true, useTrash: true });
```

Always use `useTrash: true` for user-facing deletions — allows recovery.

### Diff Before Overwrite

```typescript
const choice = await vscode.window.showWarningMessage(
    `'${name}' already exists.`, 'Overwrite', 'Compare'
);
if (choice === 'Compare') {
    await vscode.commands.executeCommand('vscode.diff', existingUri, newContentUri, `${name}: Local ↔ New`);
}
```

---

## File Watching

### Two-Layer Watching Pattern

For directories that may appear or disappear:

```typescript
class MyProvider implements vscode.Disposable {
    private watchers: fs.FSWatcher[] = [];
    private debounceTimer?: NodeJS.Timeout;
    private intervalId?: NodeJS.Timer;

    constructor() {
        this.setupWatchers();
        // Periodic check for newly created/deleted folders
        this.intervalId = setInterval(() => this.checkPaths(), 30_000);
    }

    private setupWatchers() {
        this.watchers.forEach(w => w.close()); // Clean up old watchers
        this.watchers = [];
        for (const path of existingPaths) {
            const watcher = fs.watch(path, { recursive: true }, () => {
                this.debouncedRefresh();
            });
            this.watchers.push(watcher);
        }
    }

    private debouncedRefresh() {
        if (this.debounceTimer) clearTimeout(this.debounceTimer);
        this.debounceTimer = setTimeout(() => this.refresh(), 1000);
    }

    dispose() {
        this.watchers.forEach(w => w.close());
        if (this.debounceTimer) clearTimeout(this.debounceTimer);
        if (this.intervalId) clearInterval(this.intervalId);
    }
}
```

1. **`fs.watch()`** (Node.js native, recursive) — detects file changes inside existing directories.
2. **`setInterval()`** — periodic existence check for directories that might appear/disappear.
3. **Debouncing** — 1-second delay prevents rapid-fire refreshes from file bursts.
4. Register the provider in `context.subscriptions` so `dispose()` runs on deactivation.

### VS Code FileSystemWatcher

For watching specific file patterns workspace-wide:

```typescript
const watcher = vscode.workspace.createFileSystemWatcher('**/.agents/**/*');
watcher.onDidCreate(() => syncStatus());
watcher.onDidDelete(() => syncStatus());
context.subscriptions.push(watcher);
```

---

## GitHub API Integration

### Dual API Strategy

| API | When to Use | Rate Limit |
|-----|------------|------------|
| Contents API (`/repos/:owner/:repo/contents/:path`) | Full repos, listing category folders | 60/hr (unauth) or 5000/hr (auth) |
| Trees API (`/repos/:owner/:repo/git/trees/:branch?recursive=1`) | Repos with `skillsPath` — single request scans everything | Same |
| Raw content (`raw.githubusercontent.com`) | File content download | No rate limit consumed |

### Auth Token Cascade

```typescript
async function getToken(): Promise<string | undefined> {
    // 1. Explicit setting
    const configured = vscode.workspace.getConfiguration('myExtension').get<string>('githubToken');
    if (configured) return configured;

    // 2. VS Code built-in GitHub auth (silent)
    try {
        const session = await vscode.authentication.getSession('github', ['repo'], { silent: true });
        if (session) return session.accessToken;
    } catch {}

    // 3. VS Code built-in GitHub auth (prompt once)
    if (!authPrompted) {
        authPrompted = true;
        try {
            const session = await vscode.authentication.getSession('github', ['repo'], { createIfNone: false });
            if (session) return session.accessToken;
        } catch {}
    }

    return undefined; // Falls back to unauthenticated (60 req/hr)
}
```

**Gotcha:** Use a flag (`authPrompted`) to prevent re-prompting on every API call. Prompt at most once per session.

### Parallel Category Fetching with `Promise.allSettled`

```typescript
const results = await Promise.allSettled(
    categories.map(cat => fetchCategory(owner, repo, branch, cat))
);

const items = results
    .filter((r): r is PromiseFulfilledResult<Item[]> => r.status === 'fulfilled')
    .flatMap(r => r.value);
```

**`Promise.allSettled`** (not `Promise.all`) — if one category 404s (doesn't exist in the repo), the others still load.

### In-Memory Caching

```typescript
interface CacheEntry<T> { data: T; timestamp: number; }
const cache = new Map<string, CacheEntry<unknown>>();

function getCached<T>(key: string, ttlMs: number): T | undefined {
    const entry = cache.get(key);
    if (entry && Date.now() - entry.timestamp < ttlMs) return entry.data as T;
    cache.delete(key);
    return undefined;
}
```

---

## Configuration

### Per-Category Settings Pattern

```json
"myExtension.installLocation.chatmodes": { "type": "string", "default": ".agents/chatmodes" },
"myExtension.installLocation.instructions": { "type": "string", "default": ".agents/instructions" },
"myExtension.globalInstallLocation.chatmodes": { "type": "string", "default": "~/.agents/chatmodes" }
```

- Install locations are **free-form strings**, not enums — users can customize paths.
- Paths starting with `~/` are resolved to the home directory.
- Both workspace-local and global scopes get separate settings.

### Complex Array Settings

```json
"myExtension.repositories": {
    "type": "array",
    "items": {
        "type": "object",
        "required": ["owner", "repo"],
        "properties": {
            "owner": { "type": "string" },
            "repo": { "type": "string" },
            "branch": { "type": "string", "default": "main" },
            "enabled": { "type": "boolean", "default": true }
        }
    }
}
```

### Reacting to Configuration Changes

```typescript
vscode.workspace.onDidChangeConfiguration(e => {
    if (e.affectsConfiguration('myExtension.repositories')) {
        marketplaceProvider.refresh();
    }
    if (e.affectsConfiguration('myExtension.installLocation') ||
        e.affectsConfiguration('myExtension.globalInstallLocation')) {
        installedProvider.refresh();
    }
}, undefined, context.subscriptions);
```

Use `affectsConfiguration()` with the setting prefix — it handles sub-keys automatically.

---

## Status Bar

```typescript
const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
statusBar.command = 'myExtension.quickActions';
statusBar.text = '$(tools) 5 $(cloud-download) 2';
statusBar.tooltip = '5 installed, 2 updates available';
statusBar.show();
context.subscriptions.push(statusBar);

// Update when data changes:
installedProvider.onDidChangeTreeData(() => updateStatusBar());
```

- Uses Codicons in `text` property: `$(codicon-name)`.
- `command` triggers a quick-pick menu on click.

---

## Testing

### Framework: Mocha in Extension Host

Tests run in a **real VS Code Extension Host** via `@vscode/test-electron`:

```typescript
import * as assert from 'assert';
import * as vscode from 'vscode';

suite('My Feature', () => {
    test('should do something', async () => {
        // vscode API is fully available here
        assert.strictEqual(result, expected);
    });
});
```

- Uses **`tdd` UI** (`suite()`/`test()` syntax), not `describe()`/`it()`.
- Tests compile with `tsc` to `out/`, not bundled with esbuild.
- **Linux CI**: Requires `xvfb-run npm test` for headless execution.

### Sandboxed Testing

```bash
code --extensionDevelopmentPath=. \
     --user-data-dir=/tmp/test-profile \
     --extensions-dir=/tmp/test-extensions
```

Prevents test runs from modifying the user's real VS Code setup.

---

## Packaging

```bash
npx @vscode/vsce package
```

### `.vscodeignore`

```
src/**
out/**
node_modules/**
.vscode/**
tsconfig.json
esbuild.js
eslint.config.*
*.test.ts
```

The VSIX should only contain: `dist/extension.js`, `package.json`, `resources/`, `README.md`, `LICENSE`.

### Cross-Platform Build Scripts

Always provide build/packaging scripts for **all three shell environments** so the extension can be built on any platform:

| Platform | Script | Invocation |
|----------|--------|------------|
| Linux / macOS | `build_package.sh` | `./build_package.sh [--vscode] [--rider]` |
| Windows CMD | `build_package.bat` | `build_package.bat [--vscode] [--rider]` |
| Windows PowerShell | `build_package.ps1` | `.\build_package.ps1 [-VSCode] [-Rider]` |

#### Script Structure

Every build script should follow this structure:

1. **Parse arguments** — support flags to build individual targets (e.g. `--vscode`, `--rider`) and `--help`. Default to building all targets when no flags are provided.
2. **Check prerequisites** — verify required tools are installed *before* any build work begins. If anything is missing, print platform-specific installation instructions and exit immediately (no partial builds).
3. **Clean previous artefacts** — remove old build outputs from the project root.
4. **Build each target** — run the appropriate build commands.
5. **Copy artefacts** — move built packages to a consistent output location (project root).
6. **Report summary** — print success/failure status and the location of built artefacts.

#### Prerequisite Checks — Requirements

**Always check prerequisites upfront**, before any build step runs. This avoids partial builds that fail halfway through.

For a VS Code extension, check:
- `node` — Node.js runtime (required version, e.g. 22.x LTS)
- `npm` — Node package manager (ships with Node.js)
- `git` — required by `@vscode/vsce` during packaging

For a JetBrains/Gradle plugin (if the monorepo includes one), also check:
- `java` — JDK (verify version >= required, e.g. 17)
- `javac` — confirms a full JDK not just a JRE
- `gradlew` / `gradlew.bat` — Gradle wrapper presence (fall back to system `gradle` if missing)

For each tool, report:
- **If found**: print the tool name and its version (e.g. `✔ Node.js found: v22.14.0`)
- **If missing**: print a clear error and **platform-specific install instructions**

If any prerequisite is missing, print a summary and exit **before touching any build steps**.

#### Platform-Specific Install Hints

Each script should suggest the most natural installation method for its platform:

**Bash (`build_package.sh`)** — detect the OS and package manager:
```bash
install_hint() {
    local tool="$1"
    if [[ "$(uname)" == "Darwin" ]]; then
        case "$tool" in
            node) echo "  brew install node" ;;
            git)  echo "  brew install git" ;;
            java) echo "  brew install temurin   (Adoptium JDK 17+)" ;;
        esac
    else
        # Detect Linux distro by available package manager
        if command -v apt-get &>/dev/null; then
            case "$tool" in
                node) echo "  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -"
                      echo "  sudo apt-get install -y nodejs" ;;
                git)  echo "  sudo apt-get install -y git" ;;
                java) echo "  sudo apt-get install -y openjdk-17-jdk" ;;
            esac
        elif command -v dnf &>/dev/null; then
            # Fedora/RHEL hints...
        elif command -v pacman &>/dev/null; then
            # Arch hints...
        else
            # Generic download URLs as fallback
        fi
    fi
}
```

**Batch (`build_package.bat`)** — suggest `winget` commands and download URLs:
```bat
:check_cmd
where %~1 >nul 2>&1
if errorlevel 1 (
    echo   MISSING: %~2 is NOT installed or not on PATH.
    if /i "%~1"=="node" (
        echo     Download Node.js 22.x LTS: https://nodejs.org/
        echo     Or install via winget:     winget install OpenJS.NodeJS.LTS
    )
    if /i "%~1"=="git" (
        echo     Download Git: https://git-scm.com/download/win
        echo     Or install via winget: winget install Git.Git
    )
    if /i "%~1"=="java" (
        echo     Download JDK 17+: https://adoptium.net/
        echo     Or install via winget: winget install EclipseAdoptium.Temurin.17.JDK
    )
    set PREREQ_OK=0
) else (
    for /f "tokens=*" %%v in ('%~1 --version 2^>^&1') do (
        echo   OK %~2 found: %%v
        goto :check_cmd_done
    )
)
:check_cmd_done
exit /b 0
```

**PowerShell (`build_package.ps1`)** — suggest `winget`, Chocolatey, and download URLs with coloured output:
```powershell
function Test-Prerequisite {
    param(
        [string]$Command, [string]$Label,
        [string]$VersionArg = '--version',
        [string[]]$InstallHint
    )
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = & $Command $VersionArg 2>&1 | Select-Object -First 1
        Write-Host "  OK $Label found: $ver"
        return $true
    } else {
        Write-Host "  MISSING: $Label is NOT installed." -ForegroundColor Red
        foreach ($hint in $InstallHint) {
            Write-Host "    $hint" -ForegroundColor Yellow
        }
        return $false
    }
}

# Example usage:
Test-Prerequisite -Command 'node' -Label 'Node.js' -InstallHint @(
    'Download Node.js 22.x LTS: https://nodejs.org/',
    'Or install via winget:     winget install OpenJS.NodeJS.LTS',
    'Or via Chocolatey:         choco install nodejs-lts'
)
```

#### Java Version Validation

When a JDK is required, checking that `java` exists is not enough — also verify the major version meets the minimum:

```bash
# Bash — extract major version from "openjdk version \"17.0.x\"" output
JAVA_VER=$(java -version 2>&1 | head -1 | sed -E 's/.*"([0-9]+).*/\1/')
if [[ "$JAVA_VER" -lt 17 ]]; then
    echo "  ⚠ Java $JAVA_VER detected — JDK 17+ required."
fi
```

```powershell
# PowerShell — parse major version
$javaVerOutput = & java -version 2>&1 | Select-Object -First 1
if ($javaVerOutput -match '"(\d+)') {
    if ([int]$Matches[1] -lt 17) {
        Write-Host "  WARNING: Java $($Matches[1]) — JDK 17+ required." -ForegroundColor Yellow
    }
}
```

#### Gradle Wrapper Handling

The Gradle wrapper (`gradlew` / `gradlew.bat`) should be committed to the repository. If it's missing, fall back to system `gradle` to regenerate it, but warn the user:

```bash
if [[ ! -f "$SCRIPT_DIR/rider/gradlew" ]]; then
    if command -v gradle &>/dev/null; then
        echo "  ✔ Gradle wrapper missing, but system Gradle found (will regenerate)"
    else
        echo "  ✘ Gradle wrapper missing and 'gradle' not on PATH."
        echo "    Try a fresh git checkout, or install Gradle: https://gradle.org/install/"
        PREREQ_OK=false
    fi
fi
```

#### PowerShell Execution Policy Note

When documenting the PowerShell script, always mention the execution policy workaround:
```
If PowerShell blocks the script, run:
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

#### Key Principles

- **Fail fast**: check all prerequisites before any build step. Never leave a half-built state.
- **Be specific**: show exact install commands, not just "install Node.js". Include `winget`, `brew`, `apt`, `choco` as appropriate for the platform.
- **Report versions**: when a tool is found, print its version so the user can verify compatibility.
- **Batch-friendly subroutines**: in `.bat` files, use `call :label` subroutines since batch doesn't have functions. Use `setlocal enabledelayedexpansion` for variable expansion inside `if` blocks.
- **PowerShell idioms**: use `[CmdletBinding()] param()` for proper switch parameters (`-VSCode` not `--vscode`), `Push-Location`/`Pop-Location` for directory changes, and structured `try`/`catch`/`finally` error handling.
- **Consistent exit codes**: all three scripts should return 0 on success, non-zero on failure.

---

## Common Pitfalls

| Issue | Root Cause | Solution |
|-------|-----------|----------|
| Menu items don't appear | Wrong `when` clause or `contextValue` | Test with `viewItem =~ /regex/` for multi-variant context values |
| Command appears but is grayed out | Missing command registration | Ensure `registerCommand()` is called in `activate()` |
| Tree doesn't update | Forgot to fire change event | Call `_onDidChangeTreeData.fire()` after data changes |
| Webview loses state on tab switch | Default behavior | Set `retainContextWhenHidden: true` |
| `acquireVsCodeApi` error | Called it twice | Store result in a variable, call only once |
| Extension activates too early | Using `*` activation event | Use specific events like `onView:`, `onCommand:` |
| Tests fail on Linux CI | No display server | Use `xvfb-run npm test` |
| Unauth GitHub rate limit (60/hr) | No token configured | Use `vscode.authentication.getSession('github', ...)` |
| `Promise.all` fails if one category 404s | All-or-nothing semantics | Use `Promise.allSettled` and filter fulfilled results |
| File watchers leak on deactivation | Not disposed | Implement `Disposable`, register in `context.subscriptions` |
| Config change handler fires for unrelated settings | Listening too broadly | Use `e.affectsConfiguration('myExtension.specificKey')` |
| Multi-select command receives wrong args | Signature mismatch | Accept `(clicked, selected?)` — selected includes clicked item |
