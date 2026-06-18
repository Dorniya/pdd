const BasePage = require('./base_page');

class SignupPage extends BasePage {
  constructor(driver) {
    super(driver);
  }

  async register(email, password) {
    console.log(`[SignupPage] Attempting mobile registration for: ${email}`);
    await this.type('Email', email);
    await this.type('Password', password);
    await this.click('Sign Up', 'button');
    await this.sleep(1500); // Wait for transition
  }

  async clickBackToLogin() {
    console.log('[SignupPage] Navigating back to Login Screen...');
    await this.click('Back to Login', 'button');
    await this.sleep(1000);
  }
}

module.exports = SignupPage;
