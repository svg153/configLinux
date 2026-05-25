const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

function readArg(name) {
  const prefix = `--${name}=`;
  const arg = process.argv.slice(2).find((item) => item.startsWith(prefix));
  return arg ? arg.slice(prefix.length) : undefined;
}

const scriptRoot = __dirname;
const logsDir = process.env.ENGRAM_LOGS_DIR || path.join(scriptRoot, 'logs');
const baseUrl = readArg('url') || process.env.ENGRAM_MONITOR_URL || 'http://127.0.0.1:5174/';
const token = readArg('token') || process.env.ENGRAM_E2E_TOKEN;
const screenshot = readArg('screenshot') || process.env.ENGRAM_E2E_SCREENSHOT || path.join(logsDir, 'engram-monitor-e2e.png');

if (!token) {
  throw new Error('Missing token. Provide --token=<value> or set ENGRAM_E2E_TOKEN.');
}

async function launchBrowser() {
  const attempts = [
    { channel: 'msedge', label: 'msedge' },
    { channel: 'chrome', label: 'chrome' },
    { channel: undefined, label: 'bundled' }
  ];

  const errors = [];
  for (const attempt of attempts) {
    try {
      const browser = await chromium.launch({
        channel: attempt.channel,
        headless: true
      });
      return { browser, label: attempt.label };
    } catch (error) {
      errors.push(`${attempt.label}: ${error.message}`);
    }
  }

  throw new Error(`Could not launch a browser. ${errors.join(' | ')}`);
}

(async () => {
  const { browser, label } = await launchBrowser();
  const page = await browser.newPage({ viewport: { width: 1440, height: 1200 } });

  try {
    await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 60000 });
    await page.getByRole('button', { name: /Memories/i }).click();

    const searchInput = page.locator('input[placeholder*="Search by title"]');
    await searchInput.waitFor({ state: 'visible', timeout: 15000 });
    await searchInput.fill(token);

    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1500);

    const bodyText = await page.locator('body').innerText();
    const visibleToken = bodyText.includes(token);
    const resultSummary = await page.locator('text=/result/').first().textContent().catch(() => null);
    const matchingButtons = await page.locator('button').evaluateAll((nodes, currentToken) => {
      return nodes
        .map((node) => (node.innerText || '').trim())
        .filter((text) => text.includes(currentToken));
    }, token);

    await fs.promises.mkdir(path.dirname(screenshot), { recursive: true });
    await page.screenshot({ path: screenshot, fullPage: true });

    console.log(JSON.stringify({
      browser: label,
      url: baseUrl,
      token,
      visibleToken,
      resultSummary,
      matchingButtons,
      screenshot
    }, null, 2));

    if (!visibleToken) {
      throw new Error(`Token ${token} was not visible in the rendered monitor UI.`);
    }
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});