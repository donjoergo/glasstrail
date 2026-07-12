import { chromium, type BrowserContext, type Page } from 'playwright';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { promises as fs } from 'node:fs';
import { env } from './lib/env.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = path.resolve(__dirname, '..', '..', 'landing', 'assets', 'screenshots');

const VIEWPORT = { width: 480, height: 1000 };
const DEVICE_SCALE_FACTOR = 3;

export async function enableFlutterSemantics(page: Page): Promise<void> {
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached', timeout: 30000 });
  // Flutter positions this element at `left:-1px; top:-1px` by design (kept off-screen
  // for sighted users but focusable for screen readers), so it sits outside the
  // viewport and Playwright's coordinate-based click can't reach it even with
  // `force: true`. Dispatch a real DOM click instead, which doesn't need hit-testing.
  await placeholder.evaluate((el) => (el as HTMLElement).click());
  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 15000 });
}

export async function login(page: Page): Promise<void> {
  await page.goto(env.captureBaseUrl, { waitUntil: 'networkidle' });
  await enableFlutterSemantics(page);

  await page.getByLabel('Email').fill(env.demoPrimaryEmail);
  // Flutter's obscured password field ignores Playwright's synthetic `fill()`
  // (it silently no-ops — the DOM value never updates), so it needs a real
  // click-and-type instead.
  await page.getByLabel('Password').click();
  await page.keyboard.type(env.demoPrimaryPassword, { delay: 20 });
  // The auth screen has two "Sign in"-labeled elements: the sign-in/create-account
  // tab toggle above the form, and the actual submit button below it — the submit
  // button is always the last one in the accessibility tree.
  await page.getByRole('button', { name: 'Sign in' }).last().click();

  await page.waitForFunction(
    () => location.hash === '#/feed' || location.hash === '' || location.hash === '#/',
    undefined,
    { timeout: 360000 },
  );
  await page.waitForTimeout(2000);
}

interface ViewportOverride {
  width: number;
  height: number;
  deviceScaleFactor?: number;
}

interface ScreenSpec {
  name: string;
  hashRoute: string;
  afterNavigate?: (page: Page) => Promise<void>;
  // Defaults to the shared mobile VIEWPORT/DEVICE_SCALE_FACTOR when omitted.
  viewport?: ViewportOverride;
  // Extra time to let the screen settle after a light/dark switch, before the
  // screenshot. Defaults to 2000ms. The map needs more: swapping styles reloads
  // the whole tile layer, and with clustering off every individual marker has
  // to re-render rather than just a handful of cluster bubbles.
  themeSettleMs?: number;
}

async function scrollToPieChart(page: Page): Promise<void> {
  await page.mouse.move(VIEWPORT.width / 2, VIEWPORT.height / 2);
  await page.mouse.wheel(0, 2000);
  await page.waitForTimeout(500);
}

async function disableMapClustering(page: Page): Promise<void> {
  // The "Cluster" toggle is a canvas-painted chip with no accessible name (it never
  // surfaces in the semantics tree, unlike every other interactive control on this
  // screen), so it can't be targeted with a role/label locator — only a coordinate
  // click reaches it. Position is fixed to the mobile VIEWPORT (480x1000).
  await page.mouse.click(70, 180);
  await page.waitForTimeout(500);
}

async function disableDesktopMapClustering(page: Page): Promise<void> {
  // Same canvas-painted, semantics-less toggle as disableMapClustering, just at the
  // desktop viewport's map position (1440x900).
  await page.mouse.click(644, 163);
  await page.waitForTimeout(500);
}

const SCREENS: ScreenSpec[] = [
  { name: 'feed', hashRoute: '/feed' },
  { name: 'statistics-cards', hashRoute: '/statistics/overview' },
  { name: 'statistics-piechart', hashRoute: '/statistics/overview', afterNavigate: scrollToPieChart },
  { name: 'statistics-map', hashRoute: '/statistics/map', afterNavigate: disableMapClustering, themeSettleMs: 4000 },
  { name: 'statistics-gallery', hashRoute: '/statistics/gallery' },
  { name: 'statistics-list', hashRoute: '/statistics/history' },
  { name: 'add-drink', hashRoute: '/add-drink' },
  { name: 'bar-global', hashRoute: '/bar/sorting' },
  { name: 'bar-own', hashRoute: '/bar/custom' },
  { name: 'account-settings', hashRoute: '/profile' },
  { name: 'notifications', hashRoute: '/notifications', viewport: { width: 480, height: 343 } },
  {
    name: 'desktop',
    hashRoute: '/statistics',
    // Comfortably clears the app's `large` breakpoint (1200px, AppBreakpoints.large)
    // so the feed renders its widescreen master-detail layout with the side nav rail.
    // 16:10 matches the `.desktop-screen img` aspect-ratio baked into landing/index.html.
    viewport: { width: 1440, height: 900, deviceScaleFactor: 2 },
    afterNavigate: disableDesktopMapClustering,
    themeSettleMs: 4000,
  },
];

function selectScreens(names: string[]): ScreenSpec[] {
  if (names.length === 0) {
    return SCREENS;
  }
  const byName = new Map(SCREENS.map((screen) => [screen.name, screen]));
  const unknown = names.filter((name) => !byName.has(name));
  if (unknown.length > 0) {
    const valid = SCREENS.map((screen) => screen.name).join(', ');
    throw new Error(`Unknown screen(s): ${unknown.join(', ')}. Valid screens: ${valid}`);
  }
  return names.map((name) => byName.get(name)!);
}

function renderProgress(current: number, total: number, label: string): void {
  const barWidth = 24;
  const filled = Math.round((current / total) * barWidth);
  const bar = '#'.repeat(filled) + '-'.repeat(barWidth - filled);
  process.stdout.write(`\r[${bar}] ${current}/${total} ${label}`.padEnd(70));
}

async function goToScreen(page: Page, hashRoute: string): Promise<void> {
  await page.evaluate((route) => {
    location.hash = route;
  }, hashRoute);
  await page.waitForTimeout(1500);
}

async function captureTheme(
  page: Page,
  colorScheme: 'light' | 'dark',
  filePath: string,
  settleMs = 2000,
): Promise<void> {
  await page.emulateMedia({ colorScheme });
  await page.waitForTimeout(settleMs);
  await page.screenshot({ path: filePath });
}

function viewportKey(viewport: ViewportOverride): string {
  return `${viewport.width}x${viewport.height}@${viewport.deviceScaleFactor ?? DEVICE_SCALE_FACTOR}`;
}

async function main(): Promise<void> {
  await fs.mkdir(OUTPUT_DIR, { recursive: true });

  const screensToRun = selectScreens(process.argv.slice(2));

  const browser = await chromium.launch();
  const mobileViewport: ViewportOverride = { width: VIEWPORT.width, height: VIEWPORT.height, deviceScaleFactor: DEVICE_SCALE_FACTOR };
  const mobileContext = await browser.newContext({
    viewport: VIEWPORT,
    deviceScaleFactor: DEVICE_SCALE_FACTOR,
    locale: 'en-US',
  });
  const mobilePage = await mobileContext.newPage();

  await login(mobilePage);
  const storageState = await mobileContext.storageState();

  const pagesByViewport = new Map<string, { context: BrowserContext; page: Page }>();
  pagesByViewport.set(viewportKey(mobileViewport), { context: mobileContext, page: mobilePage });

  async function getPageFor(viewport?: ViewportOverride): Promise<Page> {
    const resolved = viewport ?? mobileViewport;
    const key = viewportKey(resolved);
    let entry = pagesByViewport.get(key);
    if (!entry) {
      const context = await browser.newContext({
        viewport: { width: resolved.width, height: resolved.height },
        deviceScaleFactor: resolved.deviceScaleFactor ?? DEVICE_SCALE_FACTOR,
        locale: 'en-US',
        storageState,
      });
      const page = await context.newPage();
      await page.goto(env.captureBaseUrl, { waitUntil: 'networkidle' });
      entry = { context, page };
      pagesByViewport.set(key, entry);
    }
    return entry.page;
  }

  const totalSteps = screensToRun.length * 2;
  let step = 0;

  for (const screen of screensToRun) {
    const page = await getPageFor(screen.viewport);
    await goToScreen(page, screen.hashRoute);
    if (screen.afterNavigate) {
      await screen.afterNavigate(page);
    }
    for (const theme of ['light', 'dark'] as const) {
      step += 1;
      renderProgress(step, totalSteps, `${screen.name} (${theme})`);
      await captureTheme(
        page,
        theme,
        path.join(OUTPUT_DIR, `${screen.name}-${theme}.jpg`),
        screen.themeSettleMs,
      );
    }
  }
  process.stdout.write('\n');

  if (screensToRun.some((screen) => screen.name === 'feed')) {
    await fs.copyFile(
      path.join(OUTPUT_DIR, 'feed-light.jpg'),
      path.join(OUTPUT_DIR, 'theme-demo-light.jpg'),
    );
    await fs.copyFile(
      path.join(OUTPUT_DIR, 'feed-dark.jpg'),
      path.join(OUTPUT_DIR, 'theme-demo-dark.jpg'),
    );
  }

  for (const { context } of pagesByViewport.values()) {
    await context.close();
  }
  await browser.close();

  console.log(`Captured ${screensToRun.length} screen(s) (light + dark) into ${OUTPUT_DIR}`);
}

const isMainModule = path.resolve(process.argv[1] ?? '') === fileURLToPath(import.meta.url);
if (isMainModule) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
