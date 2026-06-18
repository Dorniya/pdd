const { remote } = require('webdriverio');
const fs = require('fs');
const path = require('path');
const config = require('../config/config.json');

// Java SDK dynamic environment config for Windows
function configureJavaEnvironment() {
  const javaStudioHome = 'C:\\Program Files\\Android\\Android Studio\\jbr';
  if (fs.existsSync(javaStudioHome)) {
    process.env.JAVA_HOME = javaStudioHome;
    const javaBin = path.join(javaStudioHome, 'bin');
    if (!process.env.PATH.includes(javaBin)) {
      process.env.PATH = `${javaBin};${process.env.PATH}`;
    }
    console.log(`[DriverHelper] Injected JAVA_HOME environment path: ${javaStudioHome}`);
  } else {
    console.log('[DriverHelper] WARNING: Java SDK at Android Studio path was not found.');
  }
}

// Setup reporting folders
const screenshotDirFull = path.join(__dirname, '..', config.screenshotDir);
const reportDirFull = path.join(__dirname, '..', config.reportDir);

if (!fs.existsSync(screenshotDirFull)) {
  fs.mkdirSync(screenshotDirFull, { recursive: true });
}
if (!fs.existsSync(reportDirFull)) {
  fs.mkdirSync(reportDirFull, { recursive: true });
}

/**
 * Initializes a new WebdriverIO Appium session.
 */
async function createDriver() {
  configureJavaEnvironment();

  console.log(`[DriverHelper] Connecting to Appium Server at http://${config.appiumHost}:${config.appiumPort}${config.appiumPath}`);
  
  const driver = await remote({
    hostname: config.appiumHost,
    port: config.appiumPort,
    path: config.appiumPath,
    capabilities: config.capabilities,
    logLevel: 'warn',
    connectionRetryTimeout: 120000,
    connectionRetryCount: 2
  });

  return driver;
}

/**
 * Captures a screenshot when a mobile test fails.
 */
async function takeScreenshot(driver, testName) {
  try {
    const cleanName = testName.replace(/[^a-zA-Z0-9]/g, '_');
    const filename = `fail_mobile_${cleanName}_${Date.now()}.png`;
    const filepath = path.join(screenshotDirFull, filename);

    await driver.saveScreenshot(filepath);

    console.log(`[DriverHelper] Mobile screenshot captured on failure: ${filepath}`);
    return filepath;
  } catch (error) {
    console.error('[DriverHelper] Failed to capture mobile screenshot:', error.message);
    return null;
  }
}

module.exports = {
  createDriver,
  takeScreenshot
};
