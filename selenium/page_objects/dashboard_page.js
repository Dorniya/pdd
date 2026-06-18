const BasePage = require('./base_page');

class DashboardPage extends BasePage {
  constructor(driver) {
    super(driver);
  }

  async verifyStatValue(title, expectedValue) {
    console.log(`[DashboardPage] Verifying stat "${title}" is: ${expectedValue}`);
    // Stats cards are semantic nodes with label like 'Sessions' and 'Minutes'
    const statTitleEl = await this.findSemanticElement(title, null);
    const valueEl = await this.findSemanticElement(expectedValue, null);
    return statTitleEl !== null && valueEl !== null;
  }

  async clickStartYoga() {
    console.log('[DashboardPage] Clicking "Start Yoga" quick action...');
    await this.click('Start Yoga', 'button');
    await this.sleep(1000);
  }

  async clickTimer() {
    console.log('[DashboardPage] Clicking "Timer" quick action...');
    await this.click('Timer', 'button');
    await this.sleep(1000);
  }

  async navigateToTab(tabName) {
    console.log(`[DashboardPage] Navigating to Bottom Tab: ${tabName}`);
    // Bottom tabs can be hidden when on a full-screen sub-page navigator.
    // Use a 5s per-attempt timeout so 3 attempts finish in ~18s < Mocha 30s limit.
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        // Use shorter 5s timeout per attempt instead of default 10s
        const el = await this.findSemanticElement(tabName, 'button', 5000);
        await el.click();
        await this.sleep(1000);
        return; // Success
      } catch (e) {
        if (attempt < 2) {
          console.warn(`[DashboardPage] Tab "${tabName}" not found on attempt ${attempt + 1}. Navigating back to expose tab bar...`);
          try { await this.goBack(); } catch (be) {}
          await this.sleep(1000);
        } else {
          // Final attempt failed — throw to let caller handle it
          throw e;
        }
      }
    }
  }
}

module.exports = DashboardPage;
