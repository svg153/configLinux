# Draft issue — support configurable Engram backend port in `engram-monitor`

Use this as a starting point when opening an issue in the official `engram-monitor` repository.

## Suggested title

Support configurable Engram backend port instead of hardcoding `127.0.0.1:7437`

## Context

`engram-monitor` currently assumes that the Engram HTTP API is always available at:

- `http://127.0.0.1:7437`

In my setup, that default port can already be occupied by another local process, so I need to run Engram on a different port such as `7440` or `7454`.

The monitor works correctly once `vite.config.ts` is changed from a hardcoded target to an environment-driven one.

## Current behavior

The Vite proxy is hardcoded to:

```ts
target: 'http://127.0.0.1:7437'
```

This means the UI cannot talk to an Engram backend running on a different port unless the local source is patched manually.

## Why this is a problem

- the default port may already be busy
- users may intentionally run multiple Engram instances on different ports
- local development setups often need a fallback port strategy
- downstream users currently need to maintain a local patch just to change the backend port

## Example scenario

In my Windows setup:

- `7437` was not reliably usable for the API
- Engram was started successfully on `7454`
- `engram-monitor` worked correctly after changing the proxy target to use `process.env.ENGRAM_PORT`

Validated working combination:

- Engram API: `http://127.0.0.1:7454/health`
- Monitor UI: `http://127.0.0.1:5184/`

The setup was also verified end-to-end by:

1. saving a real observation with `engram save`
2. querying the direct Engram API
3. querying the monitor proxy
4. verifying in the rendered UI that the observation is visible

## Proposed change

Allow the Vite proxy target to be configured through an environment variable, for example:

```ts
const engramPort = process.env.ENGRAM_PORT ?? '7437';

target: `http://127.0.0.1:${engramPort}`
```

## Minimal patch

```diff
+const engramPort = process.env.ENGRAM_PORT ?? '7437';

 export default defineConfig({
   server: {
     proxy: {
       '/engram-api': {
-        target: 'http://127.0.0.1:7437',
+        target: `http://127.0.0.1:${engramPort}`,
         changeOrigin: true,
         rewrite: (path) => path.replace(/^\/engram-api/, '')
       }
     }
   }
 })
```

## Optional follow-up ideas

- document `ENGRAM_PORT` in the README
- allow overriding the full backend URL, not just the port
- make the dev script respect the same variable consistently across platforms

## Local workaround currently used

I am keeping a local patch in `vite.config.ts` to make the proxy configurable, because without it the monitor cannot follow the Engram API when it is forced onto an alternate port.
