# AGENTS.md - CloudStream Plugins Development Guide

This repository contains Turkish CloudStream provider plugins. Each plugin is a separate Android library module.

## Project Structure

```
├── PluginName/
│   ├── build.gradle.kts          # Plugin config (version, authors, tvTypes)
│   └── src/main/kotlin/com/keyiflerolsun/
│       ├── PluginName.kt         # Main provider (extends MainAPI)
│       ├── PluginNamePlugin.kt   # Plugin entry point (@CloudstreamPlugin)
│       ├── PluginNameModels.kt   # Data classes for API responses
│       └── *Extractor.kt         # Video extractors (extends ExtractorApi)
├── __Temel/                      # Template plugin (disabled)
├── build.gradle.kts              # Root build config
├── settings.gradle.kts           # Module inclusion
├── KONTROL.py                    # Domain change checker script
└── local-runner/                 # Docker-based CI/CD
```

## Build Commands

```bash
# Build all plugins
./gradlew make

# Build all plugins + generate plugins.json
./gradlew make makePluginsJson

# Build a single plugin
./gradlew :PluginName:make

# Clean build
./gradlew clean

# Build with errors continuing (useful when some plugins fail)
./gradlew make makePluginsJson --continue

# Check compilation without building
./gradlew compileDebugKotlin
```

## Testing a Single Plugin

```bash
# Compile single plugin
./gradlew :AnimeciX:compileDebugKotlin

# Build single plugin to .cs3
./gradlew :AnimeciX:make

# Output: AnimeciX/build/AnimeciX.cs3
```

## Creating a New Plugin

1. Copy `__Temel/` to `NewPlugin/`
2. Rename files and classes
3. Update `build.gradle.kts`:
   ```kotlin
   version = 1
   cloudstream {
       authors     = listOf("yourname")
       language    = "tr"
       description = "Plugin description"
       status      = 1  // 0:Down, 1:Ok, 2:Slow, 3:Beta
       tvTypes     = listOf("Movie", "TvSeries", "Anime")
       iconUrl     = "https://example.com/favicon.ico"
   }
   ```
4. Plugin auto-included if `build.gradle.kts` exists

## Code Style Guidelines

### Package & Imports

```kotlin
// Header comment (required)
// ! Bu arac @keyiflerolsun tarafindan | @KekikAkademi icin yazilmistir.

package com.keyiflerolsun

// Android imports first
import android.util.Log
import android.util.Base64

// CloudStream imports (use wildcards)
import com.lagradost.cloudstream3.*
import com.lagradost.cloudstream3.utils.*
import com.lagradost.cloudstream3.LoadResponse.Companion.addActors

// Third-party imports
import com.fasterxml.jackson.annotation.JsonProperty
import org.jsoup.nodes.Element
```

### MainAPI Provider Class

```kotlin
class PluginName : MainAPI() {
    override var mainUrl              = "https://example.com"
    override var name                 = "PluginName"
    override val hasMainPage          = true
    override var lang                 = "tr"
    override val hasQuickSearch       = false
    override val supportedTypes       = setOf(TvType.Movie, TvType.TvSeries)

    // Sequential loading for CloudFlare sites
    override var sequentialMainPage            = true
    override var sequentialMainPageDelay       = 200L  // milliseconds
    override var sequentialMainPageScrollDelay = 200L

    override val mainPage = mainPageOf(
        "${mainUrl}/category1" to "Category 1",
        "${mainUrl}/category2" to "Category 2",
    )

    override suspend fun getMainPage(page: Int, request: MainPageRequest): HomePageResponse { }
    override suspend fun search(query: String): List<SearchResponse> { }
    override suspend fun load(url: String): LoadResponse? { }
    override suspend fun loadLinks(...): Boolean { }
}
```

### Plugin Entry Point

```kotlin
@CloudstreamPlugin
class PluginNamePlugin: Plugin() {
    override fun load(context: Context) {
        registerMainAPI(PluginName())
        registerExtractorAPI(CustomExtractor())  // if needed
    }
}
```

### Data Models (Jackson)

```kotlin
data class ApiResponse(
    @JsonProperty("data") val data: List<Item>,
    @JsonProperty("total_count") val totalCount: Int,  // snake_case -> camelCase
)

data class Item(
    @JsonProperty("id") val id: Int,
    @JsonProperty("title") val title: String,
    @JsonProperty("poster") val poster: String?,  // nullable if optional
)
```

### Extractor Class

```kotlin
open class CustomExtractor : ExtractorApi() {
    override val name            = "CustomExtractor"
    override val mainUrl         = "https://player.example.com"
    override val requiresReferer = true

    override suspend fun getUrl(
        url: String,
        referer: String?,
        subtitleCallback: (SubtitleFile) -> Unit,
        callback: (ExtractorLink) -> Unit
    ) {
        // Extract video URL and call callback
        callback.invoke(
            newExtractorLink(
                source = this.name,
                name   = this.name,
                url    = videoUrl,
                type   = INFER_TYPE
            ) {
                headers = mapOf("Referer" to referer)
                quality = getQualityFromName("1080p")
            }
        )
    }
}
```

### Logging Convention

```kotlin
Log.d("Kekik_${this.name}", "message » $variable")
```

### Error Handling

```kotlin
// Use parsedSafe for nullable parsing
val response = app.get(url).parsedSafe<ApiResponse>() ?: return null

// Throw for critical errors
throw ErrorLoadingException("PluginName: Error message")
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `DiziBox`, `TauVideoExtractor` |
| Files | Match class name | `DiziBox.kt`, `DiziBoxModels.kt` |
| Properties | camelCase | `mainUrl`, `hasMainPage` |
| Constants | UPPER_SNAKE | `INFER_TYPE` |
| Data classes | PascalCase | `AnimeSearch`, `TitleVideos` |

### Domain URL Pattern

```kotlin
override var mainUrl = "https://example.com"  // var, not val (for domain updates)
```

Domain changes are auto-detected by `KONTROL.py` and updated via CI/CD.

## Dependencies Available

- `com.github.Blatzar:NiceHttp` - HTTP client
- `org.jsoup:jsoup` - HTML parsing
- `com.fasterxml.jackson` - JSON parsing
- `kotlinx-coroutines-android` - Async operations
- CloudStream stubs - All CloudStream APIs

## Common Patterns

### HTML Parsing
```kotlin
val document = app.get(url).document
val items = document.select("div.item").map { it.toSearchResult() }
```

### JSON API
```kotlin
val response = app.get(apiUrl).parsedSafe<ApiResponse>()
```

### Headers for Protected Sites
```kotlin
app.get(url, headers = mapOf(
    "x-api-key" to "key",
    "Referer" to mainUrl
))
```

### CloudFlare Bypass
```kotlin
private val cloudflareKiller by lazy { CloudflareKiller() }
private val interceptor by lazy { CloudflareInterceptor(cloudflareKiller) }
```

## Local Runner (Docker-based CI/CD)

This repository includes a Docker-based local runner that replaces GitHub Actions workflows.
Located in `local-runner/` directory.

### Architecture

```
┌─────────────────────────────────────────┐
│         Docker Container                │
│  - JDK 17, Python 3.11, Android SDK     │
│  - Cron scheduler                       │
│  - kontrol.sh (domain checker)          │
│  - derleyici.sh (builder)               │
└─────────────────────────────────────────┘
                    │
                    ▼ git push
              GitHub builds branch
                    │
                    ▼
          CloudStream App (repo.json)
```

### Starting the Local Runner

```bash
cd local-runner

# Build and start container
docker compose up -d --build

# View logs
docker logs -f cloudstream-builder

# Stop container
docker compose down
```

### Automatic Schedule

The container runs these tasks automatically via cron:

| Time | Task | Description |
|------|------|-------------|
| 00:11, 09:11, 18:11 | `kontrol.sh` | Checks domain changes, triggers build if needed |

### Manual Build After Code Changes

After modifying plugin code, run the build manually:

```bash
# Run builder inside container
docker exec cloudstream-builder /app/scripts/derleyici.sh

# Or run domain check + build
docker exec cloudstream-builder /app/scripts/kontrol.sh
```

### Workflow: Code Change → GitHub Push

1. **Make your code changes** in plugin files
2. **Commit to master branch**:
   ```bash
   git add .
   git commit -m "Fix: Updated extractor for NewSite"
   git push origin master
   ```
3. **Trigger build** (choose one):
   ```bash
   # Option A: Run builder directly
   docker exec cloudstream-builder /app/scripts/derleyici.sh
   
   # Option B: Wait for cron (every 9 hours)
   ```
4. **Builder automatically**:
   - Pulls latest master
   - Compiles all plugins with `./gradlew make makePluginsJson --continue`
   - Copies `.cs3` files to builds branch
   - Pushes to `builds` branch on GitHub

5. **CloudStream app** fetches updates from:
   ```
   https://raw.githubusercontent.com/{user}/Kekik-cloudstream/refs/heads/builds/repo.json
   ```

### Local Runner Files

```
local-runner/
├── Dockerfile           # Container image (JDK, Python, Android SDK, Cron)
├── docker-compose.yml   # Container configuration
├── crontab              # Scheduled tasks
├── entrypoint.sh        # Container startup script
├── scripts/
│   ├── derleyici.sh     # Plugin builder script
│   └── kontrol.sh       # Domain checker script
└── README.md            # Usage instructions
```

### Checking Build Status

```bash
# Check if container is running
docker ps | grep cloudstream

# View build logs
docker exec cloudstream-builder tail -50 /var/log/derleyici.log

# View domain check logs
docker exec cloudstream-builder tail -50 /var/log/kontrol.log

# List compiled plugins
docker exec cloudstream-builder ls /repo/*/build/*.cs3
```

### Troubleshooting

```bash
# Enter container shell
docker exec -it cloudstream-builder bash

# Check cron status
docker exec cloudstream-builder service cron status

# Manually test gradle build
docker exec cloudstream-builder bash -c 'cd /repo && ./gradlew :AnimeciX:make'

# Check GitHub push permissions
docker exec cloudstream-builder bash -c 'cd /repo && git push --dry-run origin master'
```

### Important Notes

- Container uses SSH keys from host (`~/.ssh/` mounted read-only)
- Builds are pushed to `builds` branch with force push
- If a plugin fails to compile, others continue (`--continue` flag)
- Old plugin versions are preserved if new build fails
