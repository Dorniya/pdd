class BasePage {
  /**
   * @param {WebdriverIO.Browser} driver The WebdriverIO Appium driver instance.
   */
  constructor(driver) {
    this.driver = driver;
  }

  /**
   * Locates an element on Android by searching Accessibility ID, Text, or content-desc.
   */
  async findSemanticElement(label, role = null, timeout = 10000) {
    const driver = this.driver;

    // We try several selectors:
    // 1. Accessibility ID selector (content-desc) matching label
    // 2. UiSelector matching description
    // 3. UiSelector matching text
    // 4. XPath fallback
    const selectors = [
      `~${label}`,
      `android=new UiSelector().description("${label}")`,
      `android=new UiSelector().descriptionContains("${label}")`,
      `android=new UiSelector().text("${label}")`,
      `android=new UiSelector().textContains("${label}")`,
      `//*[contains(@content-desc, '${label}')]`,
      `//*[contains(@text, '${label}')]`
    ];

    let element = null;

    await driver.waitUntil(async () => {
      for (const selector of selectors) {
        try {
          const el = await driver.$(selector);
          if (await el.isExisting()) {
            element = el;
            return true;
          }
        } catch (e) {
          // Continue trying other selectors
        }
      }
      return false;
    }, {
      timeout,
      timeoutMsg: `Could not find mobile element with label: "${label}"`
    });

    if (!element) {
      throw new Error(`Timeout waiting for element with label: "${label}"`);
    }

    return element;
  }

  /**
   * Inputs text into a mobile input field.
   */
  async type(label, text) {
    console.log(`[BasePage] Typing "${text}" into field: "${label}"`);
    const el = await this.findSemanticElement(label);
    
    // Clear field
    await el.click();
    await el.clearValue();
    
    if (text !== '') {
      await el.setValue(text);
    }
  }

  /**
   * Clicks a mobile button or element.
   */
  async click(label, role = 'button') {
    console.log(`[BasePage] Clicking element: "${label}"`);
    const el = await this.findSemanticElement(label);
    await el.click();
  }

  /**
   * Checks if specific text is visible on the screen.
   */
  async isTextPresent(text, timeout = 5000) {
    try {
      await this.findSemanticElement(text, null, timeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  /**
   * Sleep helper.
   */
  async sleep(ms) {
    await this.driver.pause(ms);
  }
}

module.exports = BasePage;
