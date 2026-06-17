const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const fs = require('fs');
const path = require('path');
const config = require('../config/config.json');

// Ensure directories exist
if (!fs.existsSync(config.screenshotDir)) {
  fs.mkdirSync(config.screenshotDir, { recursive: true });
}
if (!fs.existsSync(config.reportDir)) {
  fs.mkdirSync(config.reportDir, { recursive: true });
}

/**
 * Initializes a new Selenium WebDriver instance based on the configuration.
 */
async function createDriver() {
  const options = new chrome.Options();
  
  // Configure browser window size
  options.addArguments('--window-size=1280,800');
  
  if (config.headless) {
    options.addArguments('--headless=new');
    options.addArguments('--disable-gpu');
    options.addArguments('--no-sandbox');
    options.addArguments('--disable-dev-shm-usage');
  }

  // Enable gathering performance logs (to fetch console log errors)
  const loggingPrefs = new chrome.logging.Preferences();
  loggingPrefs.setLevel(chrome.logging.Type.BROWSER, chrome.logging.Level.ALL);
  options.setLoggingPrefs(loggingPrefs);

  const driver = await new Builder()
    .forBrowser(config.browser)
    .setChromeOptions(options)
    .build();

  return driver;
}

/**
 * Traverses Flutter's shadow DOM and clicks the flt-semantics-placeholder
 * to enable semantic HTML nodes (exposing buttons, inputs, etc. to Selenium).
 */
async function enableSemantics(driver) {
  // Wait a short duration for the app script to load
  await driver.sleep(2000);
  
  const enabled = await driver.executeScript(() => {
    function findSemantics(root) {
      if (!root) return null;
      if (root.tagName === 'FLT-SEMANTICS-PLACEHOLDER') return root;
      if (root.shadowRoot) {
        const found = findSemantics(root.shadowRoot);
        if (found) return found;
      }
      const children = root.children || [];
      for (let i = 0; i < children.length; i++) {
        const found = findSemantics(children[i]);
        if (found) return found;
      }
      return null;
    }

    const view = document.querySelector('flutter-view');
    let placeholder = null;
    if (view) {
      if (view.shadowRoot) {
        placeholder = view.shadowRoot.querySelector('flt-semantics-placeholder');
      }
      if (!placeholder) {
        placeholder = findSemantics(view);
      }
    }
    if (!placeholder) {
      placeholder = findSemantics(document.body);
    }

    if (placeholder) {
      placeholder.click();
      return true;
    }
    return false;
  });

  if (enabled) {
    console.log('[DriverHelper] Flutter accessibility/semantics successfully enabled.');
  } else {
    console.log('[DriverHelper] Flutter semantics placeholder not found. Semantics might be auto-enabled or unavailable.');
  }
  // Wait for the semantic overlay to populate
  await driver.sleep(1500);
}

/**
 * Captures a screenshot when a test fails.
 * Returns the absolute path where the screenshot was saved.
 */
async function takeScreenshot(driver, testName) {
  try {
    const cleanName = testName.replace(/[^a-zA-Z0-9]/g, '_');
    const filename = `fail_${cleanName}_${Date.now()}.png`;
    const filepath = path.join(process.cwd(), config.screenshotDir, filename);
    
    const screenshot = await driver.takeScreenshot();
    fs.writeFileSync(filepath, screenshot, 'base64');
    
    console.log(`[DriverHelper] Screenshot captured on failure: ${filepath}`);
    return filepath;
  } catch (error) {
    console.error('[DriverHelper] Failed to capture screenshot:', error.message);
    return null;
  }
}

/**
 * Extracts and filters browser logs (console logs, warning, errors).
 */
async function getBrowserLogs(driver) {
  try {
    const logs = await driver.manage().logs().get(chrome.logging.Type.BROWSER);
    return logs.map(log => `[${log.level.name}] ${log.message}`).join('\n');
  } catch (error) {
    return `Failed to fetch browser logs: ${error.message}`;
  }
}

module.exports = {
  createDriver,
  enableSemantics,
  takeScreenshot,
  getBrowserLogs
};
