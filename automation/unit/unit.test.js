const { expect } = require('chai');
const {
  calculateStreak,
  calculateAverageAccuracy,
  formatDuration
} = require('../utils/business_logic');

describe('Unit | Dashboard Business Logic Helpers', function() {

  describe('calculateStreak()', function() {
    it('TC-UNI-01 | Unit | Streak_Calculation | Calculate streak for empty histories | Unit', function() {
      expect(calculateStreak([])).to.equal(0);
      expect(calculateStreak(null)).to.equal(0);
    });

    it('TC-UNI-02 | Unit | Streak_Calculation | Calculate streak for active consecutive days | Unit', function() {
      const today = new Date();
      const yesterday = new Date();
      yesterday.setDate(today.getDate() - 1);
      const dayBefore = new Date();
      dayBefore.setDate(today.getDate() - 2);

      const dates = [
        today.toISOString(),
        yesterday.toISOString(),
        dayBefore.toISOString()
      ];

      expect(calculateStreak(dates)).to.equal(3);
    });

    it('TC-UNI-03 | Unit | Streak_Calculation | Calculate streak where newest session is broken | Unit', function() {
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

      const dates = [threeDaysAgo.toISOString()];
      expect(calculateStreak(dates)).to.equal(0);
    });
  });

  describe('calculateAverageAccuracy()', function() {
    it('TC-UNI-04 | Unit | Accuracy_Averaging | Handle averaging for empty session arrays | Unit', function() {
      expect(calculateAverageAccuracy([])).to.equal(0);
      expect(calculateAverageAccuracy(null)).to.equal(0);
    });

    it('TC-UNI-05 | Unit | Accuracy_Averaging | Correctly average multiple integers | Unit', function() {
      expect(calculateAverageAccuracy([80, 90, 85, 95])).to.equal(88);
      expect(calculateAverageAccuracy([100, 100, 50])).to.equal(83);
    });
  });

  describe('formatDuration()', function() {
    it('TC-UNI-06 | Unit | Duration_Formatting | Formats seconds under one minute | Unit', function() {
      expect(formatDuration(0)).to.equal('00:00');
      expect(formatDuration(45)).to.equal('00:45');
    });

    it('TC-UNI-07 | Unit | Duration_Formatting | Formats seconds over one minute but under one hour | Unit', function() {
      expect(formatDuration(90)).to.equal('01:30');
      expect(formatDuration(3599)).to.equal('59:59');
    });

    it('TC-UNI-08 | Unit | Duration_Formatting | Formats seconds exceeding one hour | Unit', function() {
      expect(formatDuration(3600)).to.equal('01:00:00');
      expect(formatDuration(3665)).to.equal('01:01:05');
      expect(formatDuration(72122)).to.equal('20:02:02');
    });
  });
});
