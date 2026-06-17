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
    // Bottom tabs have labels like "Home", "Yoga", "Profile", "Settings"
    await this.click(tabName, 'button');
    await this.sleep(1000);
  }
}

module.exports = DashboardPage;
