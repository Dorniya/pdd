const { until } = require('selenium-webdriver');

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
            
            // Check current node
            if (root.getAttribute) {
              const currentLabel = root.getAttribute('aria-label');
              const currentRole = root.getAttribute('role');
              
              let match = false;
              if (label && rl) {
                match = (currentLabel === label || (currentLabel && currentLabel.includes(label))) && currentRole === rl;
              } else if (label) {
                match = currentLabel && (currentLabel === label || currentLabel.includes(label));
              } else if (rl) {
                match = currentRole === rl;
              }
              
              if (match) return root;
            }
            
            // Search shadow root
            if (root.shadowRoot) {
              const found = search(root.shadowRoot);
              if (found) return found;
            }
            
            // Search children
            const children = root.children || [];
            for (let i = 0; i < children.length; i++) {
              const found = search(children[i]);
              if (found) return found;
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
    // Clear first if needed (sending backspaces or using clear)
    try {
      await el.clear();
    } catch (e) {
      // Clear might fail for custom semantic inputs, ignore and write
    }
    await el.sendKeys(text);
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
