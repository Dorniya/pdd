const { expect } = require('chai');
const LoginPage = require('../page_objects/login_page');
const SignupPage = require('../page_objects/signup_page');
const DashboardPage = require('../page_objects/dashboard_page');

describe('Functional | Application Features', function() {
  let loginPage;
  let signupPage;
  let dashboardPage;

  before(function() {
    if (!global.driver) {
      this.skip();
    }
    loginPage = new LoginPage(global.driver);
    signupPage = new SignupPage(global.driver);
    dashboardPage = new DashboardPage(global.driver);
  });

  it('TC-FUN-01 | Functional | Navigation_Flow | Verify transition between Login and Signup screens | Functional', async function() {
    console.log('[Test] TC-FUN-01: Verifying login to registration routing...');
    
    await loginPage.clickCreateAccount();
    const signupHeaderExists = await signupPage.isTextPresent('Create Account');
    expect(signupHeaderExists).to.be.true;

    await signupPage.clickBackToLogin();
    const loginHeaderExists = await loginPage.isTextPresent('Login');
    expect(loginHeaderExists).to.be.true;
  });

  it('TC-FUN-02 | Functional | Dashboard_Actions | Check dashboard widgets when authenticated | Functional', async function() {
    console.log('[Test] TC-FUN-02: Checking authenticated dashboard actions...');
    
    // Check if we are already logged in (e.g. if the previous E2E test left us logged in)
    const onDashboard = await dashboardPage.isTextPresent('Yoga Dashboard', 2000);
    
    if (!onDashboard) {
      console.log('[Test] Not logged in, skipping dashboard functional test (expected).');
      this.skip();
    } else {
      // Navigate tabs
      await dashboardPage.navigateToTab('Yoga');
      const yogaListVisible = await dashboardPage.isTextPresent('Yoga Poses') || await dashboardPage.isTextPresent('Beginner');
      expect(yogaListVisible).to.be.true;
      
      await dashboardPage.navigateToTab('Profile');
      const profileVisible = await dashboardPage.isTextPresent('Workout History');
      expect(profileVisible).to.be.true;
      
      await dashboardPage.navigateToTab('Home');
    }
  });
});
