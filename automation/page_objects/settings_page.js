const BasePage = require('./base_page');

class SettingsPage extends BasePage {
  constructor(driver) {
    super(driver);
  }

  async navigateToHealthDetails() {
    console.log('[SettingsPage] Navigating to Health Details...');
    await this.click('Health Details', 'button');
    await this.sleep(1500); // Wait for transition
  }

  async updateHealthDetails({ bp, sugar, hr, pain, age, weight, height }) {
    console.log('[SettingsPage] Filling health details form...');
    if (bp !== undefined) await this.type('Blood Pressure', bp);
    if (sugar !== undefined) await this.type('Blood Sugar (mg/dL)', sugar.toString());
    if (hr !== undefined) await this.type('Heart Rate (bpm)', hr.toString());
    if (pain !== undefined) await this.type('Pain Level (1-10)', pain.toString());
    if (age !== undefined) await this.type('Age', age.toString());
    if (weight !== undefined) await this.type('Weight (kg)', weight.toString());
    if (height !== undefined) await this.type('Height (cm)', height.toString());
  }

  async clickSave() {
    console.log('[SettingsPage] Saving health details...');
    await this.click('Save Health Details', 'button');
    await this.sleep(1500); // Wait for saving response snackbar
  }

  async verifySaveSuccess() {
    return this.isTextPresent('Health details saved successfully.');
  }

  async verifyValidationError(errorMsg) {
    return this.isTextPresent(errorMsg);
  }
}

module.exports = SettingsPage;
