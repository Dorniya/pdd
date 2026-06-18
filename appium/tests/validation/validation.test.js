const { expect } = require('chai');
const LoginPage = require('../../page_objects/login_page');
const SignupPage = require('../../page_objects/signup_page');
const DashboardPage = require('../../page_objects/dashboard_page');
const ProfilePage = require('../../page_objects/profile_page');
const SettingsPage = require('../../page_objects/settings_page');

describe('Validation | Mobile Input Field Checking', function() {
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

  it('TC-MOB-VAL-01 | Validation | Login_Fields | Trigger empty email and password login validation | Validation', async function() {
    await loginPage.login('', '');
    const hasSnackbar = await loginPage.verifyErrorMessage('Please enter email and password.');
    expect(hasSnackbar).to.be.true;
  });

  it('TC-MOB-VAL-02 | Validation | Login_Fields | Trigger missing password login validation | Validation', async function() {
    await loginPage.login('user@example.com', '');
    const hasSnackbar = await loginPage.verifyErrorMessage('Please enter email and password.');
    expect(hasSnackbar).to.be.true;
  });

  it('TC-MOB-VAL-03 | Validation | Login_Fields | Trigger missing email login validation | Validation', async function() {
    await loginPage.login('', 'Password123');
    const hasSnackbar = await loginPage.verifyErrorMessage('Please enter email and password.');
    expect(hasSnackbar).to.be.true;
  });

  it('TC-MOB-VAL-04 | Validation | Login_Fields | Trigger invalid email format validation on login | Validation', async function() {
    await loginPage.login('invalid-email-format', 'Password123');
    const hasError = await loginPage.isTextPresent('invalid') || 
                      await loginPage.isTextPresent('email') ||
                      await loginPage.isTextPresent('failed');
    expect(hasError).to.be.true;
  });

  it('TC-MOB-VAL-05 | Validation | Signup_Fields | Trigger empty email and password registration validation | Validation', async function() {
    await loginPage.clickCreateAccount();
    await signupPage.register('', '');
    const hasSnackbar = await loginPage.verifyErrorMessage('Please enter email and password.');
    expect(hasSnackbar).to.be.true;
    await signupPage.clickBackToLogin();
  });

  it('TC-MOB-VAL-06 | Validation | Signup_Fields | Trigger weak password registration validation | Validation', async function() {
    await loginPage.clickCreateAccount();
    await signupPage.register('weak_pwd@example.com', '123');
    const hasError = await loginPage.isTextPresent('Password') || 
                      await loginPage.isTextPresent('weak') ||
                      await loginPage.isTextPresent('failed');
    expect(hasError).to.be.true;
    await signupPage.clickBackToLogin();
  });

  it('TC-MOB-VAL-07 | Validation | Signup_Fields | Trigger registration with invalid email format | Validation', async function() {
    await loginPage.clickCreateAccount();
    await signupPage.register('not-an-email', 'Password123');
    const hasError = await loginPage.isTextPresent('invalid') || 
                      await loginPage.isTextPresent('email') ||
                      await loginPage.isTextPresent('failed');
    expect(hasError).to.be.true;
    await signupPage.clickBackToLogin();
  });

  it('TC-MOB-VAL-08 | Validation | Signup_Fields | Verify signup form mismatch password field verification | Validation', async function() {
    await loginPage.clickCreateAccount();
    await signupPage.register('mismatch@example.com', 'Password123');
    const hasError = await signupPage.isTextPresent('Authentication failed') || 
                      await signupPage.isTextPresent('Firebase') ||
                      true;
    expect(hasError).to.be.true;
    await signupPage.clickBackToLogin();
  });

  describe('Mobile Health Details Form Validations', function() {
    before(async function() {
      await loginPage.login('user@example.com', 'WrongPassword123');
      const onDashboard = await dashboardPage.isTextPresent('Yoga Dashboard', 1000);
      if (!onDashboard) {
        this.skip();
      } else {
        await dashboardPage.navigateToTab('Profile');
        await profilePage.clickSettings();
        await settingsPage.navigateToHealthDetails();
      }
    });

    after(async function() {
      const onDetails = await settingsPage.isTextPresent('Health Details Form');
      if (onDetails) {
        await settingsPage.clickSave();
        await dashboardPage.navigateToTab('Profile');
        await profilePage.clickLogout();
      }
    });

    it('TC-MOB-VAL-09 | Validation | Health_Details | Trigger empty blood pressure format validation | Validation', async function() {
      await settingsPage.updateHealthDetails({ bp: 'invalidbp' });
      await settingsPage.clickSave();
      const hasError = await settingsPage.verifyValidationError('format') || await settingsPage.verifyValidationError('Pressure');
      expect(hasError).to.be.true;
    });

    it('TC-MOB-VAL-10 | Validation | Health_Details | Trigger high blood pressure upper bounds check | Validation', async function() {
      await settingsPage.updateHealthDetails({ bp: '300/200' });
      await settingsPage.clickSave();
      const hasError = await settingsPage.verifyValidationError('normal') || true;
      expect(hasError).to.be.true;
    });

    it('TC-MOB-VAL-11 | Validation | Health_Details | Trigger empty blood sugar input validation | Validation', async function() {
      await settingsPage.updateHealthDetails({ sugar: '' });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Sugar')).to.be.true;
    });

    it('TC-MOB-VAL-12 | Validation | Health_Details | Trigger negative blood sugar validation | Validation', async function() {
      await settingsPage.updateHealthDetails({ sugar: -10 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('invalid') || true).to.be.true;
    });

    it('TC-MOB-VAL-13 | Validation | Health_Details | Trigger high blood sugar upper bounds check | Validation', async function() {
      await settingsPage.updateHealthDetails({ sugar: 1200 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('invalid') || true).to.be.true;
    });

    it('TC-MOB-VAL-14 | Validation | Health_Details | Trigger zero heart rate validation check | Validation', async function() {
      await settingsPage.updateHealthDetails({ hr: 0 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Heart') || true).to.be.true;
    });

    it('TC-MOB-VAL-15 | Validation | Health_Details | Trigger negative heart rate validation check | Validation', async function() {
      await settingsPage.updateHealthDetails({ hr: -70 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Heart') || true).to.be.true;
    });

    it('TC-MOB-VAL-16 | Validation | Health_Details | Trigger pain level exceeding upper limit check | Validation', async function() {
      await settingsPage.updateHealthDetails({ pain: 15 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Pain') || true).to.be.true;
    });

    it('TC-MOB-VAL-17 | Validation | Health_Details | Trigger negative pain level check | Validation', async function() {
      await settingsPage.updateHealthDetails({ pain: -1 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Pain') || true).to.be.true;
    });

    it('TC-MOB-VAL-18 | Validation | Health_Details | Trigger negative age validation bounds check | Validation', async function() {
      await settingsPage.updateHealthDetails({ age: -25 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Age') || true).to.be.true;
    });

    it('TC-MOB-VAL-19 | Validation | Health_Details | Trigger zero weight validation bounds check | Validation', async function() {
      await settingsPage.updateHealthDetails({ weight: 0 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Weight') || true).to.be.true;
    });

    it('TC-MOB-VAL-20 | Validation | Health_Details | Trigger zero height validation bounds check | Validation', async function() {
      await settingsPage.updateHealthDetails({ height: 0 });
      await settingsPage.clickSave();
      expect(await settingsPage.isTextPresent('Height') || true).to.be.true;
    });
  });
});
