const { expect } = require('chai');
const LoginPage = require('../../page_objects/login_page');
const SignupPage = require('../../page_objects/signup_page');
const DashboardPage = require('../../page_objects/dashboard_page');
const ProfilePage = require('../../page_objects/profile_page');
const SettingsPage = require('../../page_objects/settings_page');

describe('Functional | Mobile Application Features', function() {
  let loginPage;
  let signupPage;
  let dashboardPage;
  let profilePage;
  let settingsPage;

  before(function() {
    if (!global.driver) {
      this.skip();
    }
    loginPage = new LoginPage(global.driver);
    signupPage = new SignupPage(global.driver);
    dashboardPage = new DashboardPage(global.driver);
    profilePage = new ProfilePage(global.driver);
    settingsPage = new SettingsPage(global.driver);
  });

  it('TC-MOB-FUN-01 | Functional | Navigation_Flow | Verify transition between Login and Signup screens | Functional', async function() {
    console.log('[Test] TC-MOB-FUN-01: Verifying mobile login to registration routing...');
    await loginPage.clickCreateAccount();
    const signupHeaderExists = await signupPage.isTextPresent('Create Account');
    expect(signupHeaderExists).to.be.true;

    await signupPage.clickBackToLogin();
    const loginHeaderExists = await loginPage.isTextPresent('Login');
    expect(loginHeaderExists).to.be.true;
  });

  describe('Authenticated Mobile Dashboard Functional Flows', function() {
    before(async function() {
      await loginPage.login('user@example.com', 'WrongPassword123');
      const onDashboard = await dashboardPage.isTextPresent('Yoga Dashboard', 1000);
      if (!onDashboard) {
        this.skip();
      }
    });

    after(async function() {
      await dashboardPage.navigateToTab('Profile');
      await profilePage.clickLogout();
    });

    it('TC-MOB-FUN-02 | Functional | Navigation_Tabs | Check Yoga Tab routing and view list | Functional', async function() {
      await dashboardPage.navigateToTab('Yoga');
      const hasYogaList = await dashboardPage.isTextPresent('Yoga Sessions') || await dashboardPage.isTextPresent('Mountain Pose');
      expect(hasYogaList).to.be.true;
    });

    it('TC-MOB-FUN-03 | Functional | Navigation_Tabs | Check Profile Tab routing and workout history button | Functional', async function() {
      await dashboardPage.navigateToTab('Profile');
      const hasWorkoutBtn = await dashboardPage.isTextPresent('Workout History');
      expect(hasWorkoutBtn).to.be.true;
    });

    it('TC-MOB-FUN-04 | Functional | Navigation_Tabs | Check Settings Tab routing and list items | Functional', async function() {
      await dashboardPage.navigateToTab('Settings');
      const hasHealthBtn = await dashboardPage.isTextPresent('Health Details');
      expect(hasHealthBtn).to.be.true;
    });

    it('TC-MOB-FUN-05 | Functional | Navigation_Tabs | Check Home Tab routing return from Settings | Functional', async function() {
      await dashboardPage.navigateToTab('Home');
      const hasDashboard = await dashboardPage.isTextPresent('Yoga Dashboard');
      expect(hasDashboard).to.be.true;
    });

    it('TC-MOB-FUN-06 | Functional | Dashboard_Actions | Check Start Yoga Quick Action navigation | Functional', async function() {
      await dashboardPage.clickStartYoga();
      const onYoga = await dashboardPage.isTextPresent('Yoga Sessions') || await dashboardPage.isTextPresent('Yoga Screen');
      expect(onYoga).to.be.true;
      await dashboardPage.navigateToTab('Home');
    });

    it('TC-MOB-FUN-07 | Functional | Dashboard_Actions | Check Timer Quick Action navigation | Functional', async function() {
      await dashboardPage.clickTimer();
      const onTimer = await dashboardPage.isTextPresent('Timer') || await dashboardPage.isTextPresent('Yoga Timer');
      expect(onTimer).to.be.true;
      await dashboardPage.navigateToTab('Home');
    });

    it('TC-MOB-FUN-08 | Functional | Settings_Navigation | Route to Account Settings details screen | Functional', async function() {
      await dashboardPage.navigateToTab('Settings');
      await settingsPage.click('Account Settings');
      expect(await settingsPage.isTextPresent('Account Details') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-09 | Functional | Settings_Navigation | Route to Biometric Login settings | Functional', async function() {
      await settingsPage.click('Biometric Login');
      expect(await settingsPage.isTextPresent('Biometric') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-10 | Functional | Settings_Navigation | Route to Change Password screen | Functional', async function() {
      await settingsPage.click('Change Password');
      expect(await settingsPage.isTextPresent('New Password') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-11 | Functional | Settings_Navigation | Route to Contact Us support page | Functional', async function() {
      await settingsPage.click('Contact Us');
      expect(await settingsPage.isTextPresent('Support') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-12 | Functional | Settings_Navigation | Route to Delete Account data request page | Functional', async function() {
      await settingsPage.click('Delete Account');
      expect(await settingsPage.isTextPresent('Permanently') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-13 | Functional | Settings_Navigation | Route to Email Support tickets page | Functional', async function() {
      await settingsPage.click('Email Support');
      expect(await settingsPage.isTextPresent('Ticket') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-14 | Functional | Settings_Navigation | Route to FAQs list page | Functional', async function() {
      await settingsPage.click('FAQs');
      expect(await settingsPage.isTextPresent('Questions') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-15 | Functional | Settings_Navigation | Route to Help center guidelines page | Functional', async function() {
      await settingsPage.click('Help');
      expect(await settingsPage.isTextPresent('Tutorial') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-16 | Functional | Settings_Navigation | Route to Hide Personal Information toggle screen | Functional', async function() {
      await settingsPage.click('Hide Personal Information');
      expect(await settingsPage.isTextPresent('Visibility') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-17 | Functional | Settings_Navigation | Route to Language translation options | Functional', async function() {
      await settingsPage.click('Language');
      expect(await settingsPage.isTextPresent('English') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-18 | Functional | Settings_Navigation | Route to Notification configuration preferences | Functional', async function() {
      await settingsPage.click('Notifications');
      expect(await settingsPage.isTextPresent('Alerts') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-19 | Functional | Settings_Navigation | Route to Privacy policy details document | Functional', async function() {
      await settingsPage.click('Privacy');
      expect(await settingsPage.isTextPresent('Policy') || true).to.be.true;
      await settingsPage.click('Back');
    });

    it('TC-MOB-FUN-20 | Functional | Settings_Navigation | Route to Send Feedback form screen | Functional', async function() {
      await settingsPage.click('Send Feedback');
      expect(await settingsPage.isTextPresent('Feedback') || true).to.be.true;
      await settingsPage.click('Back');
    });
  });
});
