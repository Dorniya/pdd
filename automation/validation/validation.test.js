const { expect } = require('chai');
const LoginPage = require('../page_objects/login_page');
const SignupPage = require('../page_objects/signup_page');

describe('Validation | Input Field Checking', function() {
  let loginPage;
  let signupPage;

  before(function() {
    if (!global.driver) {
      this.skip();
    }
    loginPage = new LoginPage(global.driver);
    signupPage = new SignupPage(global.driver);
  });

  it('TC-VAL-01 | Validation | Login_Fields | Trigger empty email and password login validation | Validation', async function() {
    console.log('[Test] TC-VAL-01: Verifying login validation snackbar for empty inputs...');
    
    // Attempt login with empty fields
    await loginPage.login('', '');
    
    // Check validation message
    const hasSnackbar = await loginPage.verifyErrorMessage('Please enter email and password.');
    expect(hasSnackbar).to.be.true;
  });

  it('TC-VAL-02 | Validation | Signup_Fields | Trigger empty email and password registration validation | Validation', async function() {
    console.log('[Test] TC-VAL-02: Verifying signup validation snackbar for empty inputs...');
    
    await loginPage.clickCreateAccount();
    
    // Attempt registration with empty fields
    await signupPage.register('', '');
    
    // Check validation message
    const hasSnackbar = await loginPage.verifyErrorMessage('Please enter email and password.');
    expect(hasSnackbar).to.be.true;
    
    await signupPage.clickBackToLogin();
  });
});
