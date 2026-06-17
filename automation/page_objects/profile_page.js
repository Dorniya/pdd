const BasePage = require('./base_page');

class ProfilePage extends BasePage {
  constructor(driver) {
    super(driver);
  }

  async clickWorkoutHistory() {
    console.log('[ProfilePage] Navigating to Workout History...');
    await this.click('Workout History', 'button');
    await this.sleep(1000);
  }

  async clickFavorites() {
    console.log('[ProfilePage] Navigating to Favorites...');
    await this.click('Favorites', 'button');
    await this.sleep(1000);
  }

  async clickSettings() {
    console.log('[ProfilePage] Navigating to Settings...');
    await this.click('Settings', 'button');
    await this.sleep(1000);
  }

  async clickLogout() {
    console.log('[ProfilePage] Clicking Logout option...');
    await this.click('Logout', 'button');
    await this.sleep(1500); // Wait for routing back to login
  }
}

module.exports = ProfilePage;
