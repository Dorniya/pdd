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
    let retries = 2;
    while (retries > 0) {
      try {
        const el = await this.findSemanticElement(ariaLabel, 'text-field');
        try {
          await this.driver.executeScript(
            'arguments[0].focus(); ' +
            'arguments[0].setSelectionRange(0, arguments[0].value.length);',
            el
          );
          await el.sendKeys(Key.BACK_SPACE);
        } catch (e) {
          try {
            await el.clear();
          } catch (err) {}
        }
        if (text !== '') {
          await el.sendKeys(text);
        }
        return; // Success
      } catch (err) {
        retries--;
        if (retries === 0) throw err;
        console.warn(`[BasePage] Stale/failed element in type("${ariaLabel}"). Retrying...`);
        await this.sleep(1000);
      }
    }
  }

  async click(ariaLabel, role = 'button') {
    let retries = 2;
    while (retries > 0) {
      try {
        const el = await this.findSemanticElement(ariaLabel, role);
        await el.click();
        return; // Success
      } catch (err) {
        retries--;
        if (retries === 0) throw err;
        console.warn(`[BasePage] Stale/failed element in click("${ariaLabel}", "${role}"). Retrying...`);
        await this.sleep(1000);
      }
    }
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

  /**
   * Navigates the browser back one page (equivalent to pressing the browser Back button).
   * Useful in after-hooks to escape Settings sub-pages before navigating tabs.
   */
  async goBack() {
    try {
      await this.driver.navigate().back();
      await this.sleep(1500);
    } catch (e) {
      // Ignore errors – the page may not have history
    }
  }

  /**
   * Hard-navigates the browser to the root app URL, then re-enables
   * the Flutter semantic accessibility layer so element lookups work.
   * Use as a last-resort reset in after-hooks when tab navigation fails.
   */
  async navigateToApp(baseUrl = 'http://localhost:8080') {
    await this.driver.get(baseUrl);
    // Wait for Flutter engine to bootstrap
    await this.sleep(4000);
    // Re-enable Flutter semantic accessibility layer (same as startup)
    await this.driver.executeScript(() => {
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
        if (!placeholder) placeholder = findSemantics(view);
      }
      if (!placeholder) placeholder = findSemantics(document.body);
      if (placeholder) { placeholder.click(); return true; }
      return false;
    });
    // Wait for semantic nodes to be rendered
    await this.sleep(2000);
  }

  /**
   * Attempts to reach the Login screen by:
   * 1. Trying to find a semantic Login element
   * 2. Falling back to a hard page reload (with semantics re-enable) if not found
   */
  async ensureOnLoginPage(baseUrl = 'http://localhost:8080') {
    let onLogin = await this.isTextPresent('Login', 2000);
    if (onLogin) return;

    // Hard navigate to app root. This will redirect to Dashboard if logged in.
    await this.navigateToApp(baseUrl);

    // Check if we are on Dashboard
    const onDashboard = await this.isTextPresent('Yoga Dashboard', 3000);
    if (onDashboard) {
      console.log('[BasePage] Detected active session on Dashboard. Performing logout to reset state...');
      try {
        // Settings tab has a clear Logout button
        await this.click('Settings', 'button');
        await this.sleep(1000);
        await this.click('Logout', 'button');
        await this.sleep(2000);
      } catch (e) {
        console.warn('[BasePage] Settings logout failed: ' + e.message + '. Trying Profile logout...');
        try {
          await this.click('Profile', 'button');
          await this.sleep(1000);
          await this.click('Logout', 'button');
          await this.sleep(2000);
        } catch (err) {
          console.error('[BasePage] Both logout routes failed. Force clearing storage.');
          try {
            await this.driver.executeScript('window.localStorage.clear(); window.sessionStorage.clear();');
            await this.driver.manage().deleteAllCookies();
            await this.navigateToApp(baseUrl);
          } catch (storageErr) {}
        }
      }
    }

    // Verify we are now on login page
    onLogin = await this.isTextPresent('Login', 5000);
    if (!onLogin) {
      console.warn('[BasePage] Failed to reach Login page. Force clearing IndexedDB databases...');
      try {
        await this.driver.executeScript(`
          if (window.indexedDB && window.indexedDB.databases) {
            window.indexedDB.databases().then(dbs => {
              dbs.forEach(db => {
                try { window.indexedDB.deleteDatabase(db.name); } catch(e) {}
              });
            });
          }
          window.localStorage.clear();
          window.sessionStorage.clear();
        `);
        await this.driver.manage().deleteAllCookies();
        await this.navigateToApp(baseUrl);
      } catch (dbErr) {}
    }
  }
}

module.exports = BasePage;
