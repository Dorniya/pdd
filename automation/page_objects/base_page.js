const { until, Key } = require('selenium-webdriver');

class BasePage {
  /**
   * @param {import('selenium-webdriver').WebDriver} driver The Selenium WebDriver instance.
   */
  constructor(driver) {
    this.driver = driver;
  }

  /**
   * Helper to wait for a specific condition.
   */
  async wait(condition, timeout = 10000) {
    return this.driver.wait(condition, timeout);
  }

  /**
   * Executes a shadow-DOM search script to locate a Flutter semantic element by aria-label and role.
   * Returns a standard Selenium WebElement.
   */
  async findSemanticElement(ariaLabel, role = null, timeout = 10000) {
    const driver = this.driver;
    
    // Wait until the element is located
    return driver.wait(async () => {
      try {
        const el = await driver.executeScript((label, rl) => {
          function search(root) {
            if (!root) return null;
            
            // Search shadow root first
            if (root.shadowRoot) {
              const found = search(root.shadowRoot);
              if (found) return found;
            }
            
            // Search children first
            const children = root.children || [];
            for (let i = 0; i < children.length; i++) {
              const found = search(children[i]);
              if (found) return found;
            }
            
            // Check current node last
            if (root.getAttribute) {
              const currentLabel = root.getAttribute('aria-label');
              const currentRole = root.getAttribute('role');
              const currentText = root.textContent ? root.textContent.trim() : '';
              
              let labelMatch = false;
              if (label) {
                labelMatch = (currentLabel === label || (currentLabel && currentLabel.includes(label))) ||
                             (currentText === label || currentText.includes(label));
              } else {
                labelMatch = true;
              }
              
              let roleMatch = false;
              if (rl) {
                if (rl === 'text-field') {
                  roleMatch = currentRole === 'text-field' || currentRole === 'textbox' || root.tagName === 'INPUT';
                } else if (rl === 'button') {
                  roleMatch = currentRole === 'button' || root.tagName === 'BUTTON';
                } else {
                  roleMatch = currentRole === rl;
                }
              } else {
                roleMatch = true;
              }
              
              if (labelMatch && roleMatch) {
                return root;
              }
            }
            
            return null;
          }
          
          const view = document.querySelector('flutter-view');
          let res = null;
          if (view) {
            res = search(view);
          }
          if (!res) {
            res = search(document.body);
          }
          return res;
        }, ariaLabel, role);
        
        return el;
      } catch (err) {
        return null;
      }
    }, timeout, `Timeout waiting for semantic element with label: "${ariaLabel}" and role: "${role}"`);
  }

  /**
   * Inputs text into a semantic text-field.
   */
  async type(ariaLabel, text) {
    const el = await this.findSemanticElement(ariaLabel, 'text-field');
    try {
      // Focus and select all text so we can clear it with a single Backspace keypress
      await this.driver.executeScript(
        'arguments[0].focus(); ' +
        'arguments[0].setSelectionRange(0, arguments[0].value.length);',
        el
      );
      await el.sendKeys(Key.BACK_SPACE);
    } catch (e) {
      console.warn(`[BasePage] Custom select-and-delete clear failed: ${e.message}. Falling back to standard clear.`);
      try {
        await el.clear();
      } catch (err) {
        // Ignore fallback clear errors
      }
    }
    if (text !== '') {
      await el.sendKeys(text);
    }
  }

  /**
   * Clicks a semantic element (button, link, tab).
   */
  async click(ariaLabel, role = 'button') {
    const el = await this.findSemanticElement(ariaLabel, role);
    await el.click();
  }

  /**
   * Validates if a specific semantic element or snackbar message is present.
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
   * Utility sleep helper.
   */
  async sleep(ms) {
    await this.driver.sleep(ms);
  }
}

module.exports = BasePage;
