import { chromium, type Page } from 'playwright';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
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
