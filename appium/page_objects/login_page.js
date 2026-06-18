const BasePage = require('./base_page');

class LoginPage extends BasePage {
  constructor(driver) {
    super(driver);
  }

  async login(email, password) {
    console.log(`[LoginPage] Attempting mobile login with: ${email}`);
    await this.type('Email', email);
    await this.type('Password', password);
    await this.click('Login', 'button');
    await this.sleep(1500); // Wait for transition
  }

  async clickCreateAccount() {
    console.log('[LoginPage] Navigating to Registration Screen...');
    await this.click('Create New Account', 'button');
    await this.sleep(1000);
  }

  async verifyErrorMessage(expectedMsg) {
    return this.isTextPresent(expectedMsg);
  }
}

module.exports = LoginPage;
