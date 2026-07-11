import { chromium, type Page } from 'playwright';
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
  await placeholder.click({ force: true });
  await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 15000 });
}

export async function login(page: Page): Promise<void> {
  await page.goto(env.captureBaseUrl, { waitUntil: 'networkidle' });
  await enableFlutterSemantics(page);

  await page.getByLabel('Email').fill(env.demoPrimaryEmail);
  await page.getByLabel('Password').fill(env.demoPrimaryPassword);
  await page.getByRole('button', { name: 'Sign in' }).click();

  await page.waitForFunction(
    () => location.hash === '#/feed' || location.hash === '' || location.hash === '#/',
    undefined,
    { timeout: 30000 },
  );
  await page.waitForTimeout(2000);
}

interface ScreenSpec {
  name: string;
  hashRoute: string;
  afterNavigate?: (page: Page) => Promise<void>;
}

async function scrollToPieChart(page: Page): Promise<void> {
  await page.mouse.move(VIEWPORT.width / 2, VIEWPORT.height / 2);
  await page.mouse.wheel(0, 700);
  await page.waitForTimeout(500);
}

const SCREENS: ScreenSpec[] = [
  { name: 'feed', hashRoute: '/feed' },
  { name: 'statistics-cards', hashRoute: '/statistics/overview' },
  { name: 'statistics-piechart', hashRoute: '/statistics/overview', afterNavigate: scrollToPieChart },
  { name: 'statistics-map', hashRoute: '/statistics/map' },
  { name: 'statistics-gallery', hashRoute: '/statistics/gallery' },
  { name: 'statistics-list', hashRoute: '/statistics/history' },
  { name: 'add-drink', hashRoute: '/add-drink' },
  { name: 'bar-global', hashRoute: '/bar/sorting' },
  { name: 'bar-own', hashRoute: '/bar/custom' },
  { name: 'account-settings', hashRoute: '/profile' },
];

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
): Promise<void> {
  await page.emulateMedia({ colorScheme });
  await page.waitForTimeout(800);
  await page.screenshot({ path: filePath });
}

async function main(): Promise<void> {
  await fs.mkdir(OUTPUT_DIR, { recursive: true });

  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: VIEWPORT,
    deviceScaleFactor: DEVICE_SCALE_FACTOR,
    locale: 'en-US',
  });
  const page = await context.newPage();

  await login(page);

  for (const screen of SCREENS) {
    await goToScreen(page, screen.hashRoute);
    if (screen.afterNavigate) {
      await screen.afterNavigate(page);
    }
    await captureTheme(page, 'light', path.join(OUTPUT_DIR, `${screen.name}-light.jpg`));
    await captureTheme(page, 'dark', path.join(OUTPUT_DIR, `${screen.name}-dark.jpg`));
  }

  await browser.close();

  await fs.copyFile(
    path.join(OUTPUT_DIR, 'feed-light.jpg'),
    path.join(OUTPUT_DIR, 'theme-demo-light.jpg'),
  );
  await fs.copyFile(
    path.join(OUTPUT_DIR, 'feed-dark.jpg'),
    path.join(OUTPUT_DIR, 'theme-demo-dark.jpg'),
  );

  console.log(`Captured ${SCREENS.length} screens (light + dark) into ${OUTPUT_DIR}`);
}

const isMainModule = path.resolve(process.argv[1] ?? '') === fileURLToPath(import.meta.url);
if (isMainModule) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
