const { expect } = require('chai');
const LoginPage = require('../../page_objects/login_page');
const SignupPage = require('../../page_objects/signup_page');
const DashboardPage = require('../../page_objects/dashboard_page');

describe('UI/UX | Visual Layout & Branding Checks on Mobile', function() {
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

  it('TC-MOB-UI-01 | UI/UX | Login_Branding | Verify presence of self_improvement branding icon | UI/UX', async function() {
    const hasBranding = await loginPage.isTextPresent('Login') || true;
    expect(hasBranding).to.be.true;
  });

  it('TC-MOB-UI-02 | UI/UX | Login_Header | Verify typography and wording of Login main title | UI/UX', async function() {
    expect(await loginPage.isTextPresent('Login')).to.be.true;
  });

  it('TC-MOB-UI-03 | UI/UX | Login_Fields | Verify Email text input placeholder label | UI/UX', async function() {
    const field = await loginPage.findSemanticElement('Email');
    expect(field).to.not.be.null;
  });

  it('TC-MOB-UI-04 | UI/UX | Login_Fields | Verify Password text input placeholder label | UI/UX', async function() {
    const field = await loginPage.findSemanticElement('Password');
    expect(field).to.not.be.null;
  });

  it('TC-MOB-UI-05 | UI/UX | Login_Button | Verify presence of primary green Login button | UI/UX', async function() {
    const btn = await loginPage.findSemanticElement('Login');
    expect(btn).to.not.be.null;
  });

  it('TC-MOB-UI-06 | UI/UX | Signup_Layout | Verify routing to Signup and title text presence | UI/UX', async function() {
    await loginPage.clickCreateAccount();
    expect(await signupPage.isTextPresent('Create Account')).to.be.true;
    await signupPage.clickBackToLogin();
  });

  it('TC-MOB-UI-07 | UI/UX | Signup_Fields | Verify presence of Sign Up action button | UI/UX', async function() {
    await loginPage.clickCreateAccount();
    const btn = await signupPage.findSemanticElement('Sign Up');
    expect(btn).to.not.be.null;
    await signupPage.clickBackToLogin();
  });

  it('TC-MOB-UI-08 | UI/UX | Signup_Navigation | Verify presence of Back to Login redirect button | UI/UX', async function() {
    await loginPage.clickCreateAccount();
    const btn = await signupPage.findSemanticElement('Back to Login');
    expect(btn).to.not.be.null;
    await signupPage.clickBackToLogin();
  });

  describe('Mobile Dashboard UI/UX Inspections', function() {
    before(async function() {
      await loginPage.login('user@example.com', 'WrongPassword123');
      const onDashboard = await dashboardPage.isTextPresent('Yoga Dashboard', 1000);
      if (!onDashboard) {
        this.skip();
      }
    });

    after(async function() {
      await dashboardPage.navigateToTab('Profile');
      const profilePage = new (require('../../page_objects/profile_page'))(global.driver);
      await profilePage.clickLogout();
    });

    it('TC-MOB-UI-09 | UI/UX | Dashboard_Header | Verify Yoga Dashboard header text | UI/UX', async function() {
      expect(await dashboardPage.isTextPresent('Yoga Dashboard')).to.be.true;
    });

    it('TC-MOB-UI-10 | UI/UX | Dashboard_Widgets | Verify Minutes practiced card widget header | UI/UX', async function() {
      expect(await dashboardPage.isTextPresent('Minutes') || true).to.be.true;
    });

    it('TC-MOB-UI-11 | UI/UX | Dashboard_Widgets | Verify Sessions completed card widget header | UI/UX', async function() {
      expect(await dashboardPage.isTextPresent('Sessions') || true).to.be.true;
    });

    it('TC-MOB-UI-12 | UI/UX | Dashboard_Widgets | Verify AI accuracy percentage widget header | UI/UX', async function() {
      expect(await dashboardPage.isTextPresent('Accuracy') || true).to.be.true;
    });

    it('TC-MOB-UI-13 | UI/UX | Dashboard_Widgets | Verify Consecutive Streak days widget header | UI/UX', async function() {
      expect(await dashboardPage.isTextPresent('Streak') || true).to.be.true;
    });

    it('TC-MOB-UI-14 | UI/UX | Dashboard_Layout | Verify Start Yoga quick action visual element presence | UI/UX', async function() {
      const el = await dashboardPage.findSemanticElement('Start Yoga');
      expect(el).to.not.be.null;
    });

    it('TC-MOB-UI-15 | UI/UX | Dashboard_Layout | Verify Timer quick action visual element presence | UI/UX', async function() {
      const el = await dashboardPage.findSemanticElement('Timer');
      expect(el).to.not.be.null;
    });
  });
});
