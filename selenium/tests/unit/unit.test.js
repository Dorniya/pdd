const { expect } = require('chai');
const {
  calculateStreak,
  calculateAverageAccuracy,
  formatDuration,
  calculateBMI,
  classifyBMI,
  classifyBP,
  calculateCalorieBurn
} = require('../../utils/business_logic');

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

    it('TC-UNI-04 | Unit | Streak_Calculation | Calculate streak with duplicated dates in same day | Unit', function() {
      const today = new Date();
      const dates = [today.toISOString(), today.toISOString()];
      expect(calculateStreak(dates)).to.equal(1);
    });

    it('TC-UNI-05 | Unit | Streak_Calculation | Calculate streak for single today session | Unit', function() {
      const today = new Date();
      expect(calculateStreak([today.toISOString()])).to.equal(1);
    });

    it('TC-UNI-06 | Unit | Streak_Calculation | Calculate streak for single yesterday session | Unit', function() {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      expect(calculateStreak([yesterday.toISOString()])).to.equal(1);
    });

    it('TC-UNI-07 | Unit | Streak_Calculation | Calculate streak for out-of-order date strings | Unit', function() {
      const today = new Date();
      const yesterday = new Date();
      yesterday.setDate(today.getDate() - 1);
      const dates = [yesterday.toISOString(), today.toISOString()];
      expect(calculateStreak(dates)).to.equal(2);
    });

    it('TC-UNI-08 | Unit | Streak_Calculation | Calculate streak with gap of two days | Unit', function() {
      const today = new Date();
      const threeDaysAgo = new Date();
      threeDaysAgo.setDate(today.getDate() - 3);
      const dates = [today.toISOString(), threeDaysAgo.toISOString()];
      expect(calculateStreak(dates)).to.equal(1);
    });

    it('TC-UNI-09 | Unit | Streak_Calculation | Calculate streak with multiple gaps | Unit', function() {
      const today = new Date();
      const yesterday = new Date();
      yesterday.setDate(today.getDate() - 1);
      const fourDaysAgo = new Date();
      fourDaysAgo.setDate(today.getDate() - 4);
      const fiveDaysAgo = new Date();
      fiveDaysAgo.setDate(today.getDate() - 5);
      const dates = [today.toISOString(), yesterday.toISOString(), fourDaysAgo.toISOString(), fiveDaysAgo.toISOString()];
      expect(calculateStreak(dates)).to.equal(2);
    });

    it('TC-UNI-10 | Unit | Streak_Calculation | Calculate streak for extremely long histories | Unit', function() {
      const dates = [];
      const today = new Date();
      for (let i = 0; i < 30; i++) {
        const d = new Date();
        d.setDate(today.getDate() - i);
        dates.push(d.toISOString());
      }
      expect(calculateStreak(dates)).to.equal(30);
    });

    it('TC-UNI-11 | Unit | Streak_Calculation | Calculate streak for future date strings | Unit', function() {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      expect(calculateStreak([tomorrow.toISOString()])).to.equal(0);
    });

    it('TC-UNI-12 | Unit | Streak_Calculation | Calculate streak with non-ISO string parsing | Unit', function() {
      const dates = [new Date().toDateString()];
      expect(calculateStreak(dates)).to.equal(1);
    });
  });

  describe('calculateAverageAccuracy()', function() {
    it('TC-UNI-13 | Unit | Accuracy_Averaging | Handle averaging for empty session arrays | Unit', function() {
      expect(calculateAverageAccuracy([])).to.equal(0);
      expect(calculateAverageAccuracy(null)).to.equal(0);
    });

    it('TC-UNI-14 | Unit | Accuracy_Averaging | Correctly average multiple integers | Unit', function() {
      expect(calculateAverageAccuracy([80, 90, 85, 95])).to.equal(88);
    });

    it('TC-UNI-15 | Unit | Accuracy_Averaging | Correctly average when total accuracy is zero | Unit', function() {
      expect(calculateAverageAccuracy([0, 0, 0])).to.equal(0);
    });

    it('TC-UNI-16 | Unit | Accuracy_Averaging | Correctly average single accuracy value | Unit', function() {
      expect(calculateAverageAccuracy([97])).to.equal(97);
    });

    it('TC-UNI-17 | Unit | Accuracy_Averaging | Correctly handle decimal rounding up | Unit', function() {
      expect(calculateAverageAccuracy([100, 100, 50])).to.equal(83); // 250 / 3 = 83.33 -> 83
    });

    it('TC-UNI-18 | Unit | Accuracy_Averaging | Correctly handle decimal rounding down | Unit', function() {
      expect(calculateAverageAccuracy([80, 81])).to.equal(81); // 161 / 2 = 80.5 -> 81
    });

    it('TC-UNI-19 | Unit | Accuracy_Averaging | Correctly handle out-of-bounds metrics inputs | Unit', function() {
      expect(calculateAverageAccuracy([-10, 150])).to.equal(70);
    });
  });

  describe('formatDuration()', function() {
    it('TC-UNI-20 | Unit | Duration_Formatting | Formats seconds under one minute | Unit', function() {
      expect(formatDuration(0)).to.equal('00:00');
      expect(formatDuration(45)).to.equal('00:45');
    });

    it('TC-UNI-21 | Unit | Duration_Formatting | Formats seconds over one minute but under one hour | Unit', function() {
      expect(formatDuration(90)).to.equal('01:30');
      expect(formatDuration(3599)).to.equal('59:59');
    });

    it('TC-UNI-22 | Unit | Duration_Formatting | Formats seconds exceeding one hour | Unit', function() {
      expect(formatDuration(3600)).to.equal('01:00:00');
      expect(formatDuration(3665)).to.equal('01:01:05');
      expect(formatDuration(72122)).to.equal('20:02:02');
    });

    it('TC-UNI-23 | Unit | Duration_Formatting | Formats negative duration values | Unit', function() {
      expect(formatDuration(-100)).to.equal('00:00');
    });

    it('TC-UNI-24 | Unit | Duration_Formatting | Formats extremely large duration numbers | Unit', function() {
      expect(formatDuration(360000)).to.equal('100:00:00');
    });

    it('TC-UNI-25 | Unit | Duration_Formatting | Formats single digit seconds | Unit', function() {
      expect(formatDuration(5)).to.equal('00:05');
    });

    it('TC-UNI-26 | Unit | Duration_Formatting | Formats null/undefined inputs | Unit', function() {
      expect(formatDuration(null)).to.equal('00:00');
      expect(formatDuration(undefined)).to.equal('00:00');
    });

    it('TC-UNI-27 | Unit | Duration_Formatting | Formats exact 10 minutes | Unit', function() {
      expect(formatDuration(600)).to.equal('10:00');
    });
  });

  describe('calculateBMI()', function() {
    it('TC-UNI-28 | Unit | BMI_Calculation | Verify standard normal height and weight | Unit', function() {
      expect(calculateBMI(70, 175)).to.equal(22.9);
    });

    it('TC-UNI-29 | Unit | BMI_Calculation | Verify zero/negative weight height bounds | Unit', function() {
      expect(calculateBMI(0, 175)).to.equal(0);
      expect(calculateBMI(70, -100)).to.equal(0);
    });

    it('TC-UNI-30 | Unit | BMI_Calculation | Verify high obesity values | Unit', function() {
      expect(calculateBMI(120, 160)).to.equal(46.9);
    });

    it('TC-UNI-31 | Unit | BMI_Calculation | Verify extremely low underweight values | Unit', function() {
      expect(calculateBMI(40, 180)).to.equal(12.3);
    });
  });

  describe('classifyBMI()', function() {
    it('TC-UNI-32 | Unit | BMI_Classification | Classify underweight and normal weight BMI | Unit', function() {
      expect(classifyBMI(15.0)).to.equal('Underweight');
      expect(classifyBMI(22.0)).to.equal('Normal');
    });

    it('TC-UNI-33 | Unit | BMI_Classification | Classify overweight and obese BMI | Unit', function() {
      expect(classifyBMI(27.5)).to.equal('Overweight');
      expect(classifyBMI(33.1)).to.equal('Obese');
    });

    it('TC-UNI-34 | Unit | BMI_Classification | Classify negative and zero BMI | Unit', function() {
      expect(classifyBMI(0)).to.equal('Unknown');
      expect(classifyBMI(-5)).to.equal('Unknown');
    });
  });

  describe('classifyBP()', function() {
    it('TC-UNI-35 | Unit | BP_Classification | Classify normal and elevated blood pressures | Unit', function() {
      expect(classifyBP(115, 75)).to.equal('Normal');
      expect(classifyBP(125, 78)).to.equal('Elevated');
    });

    it('TC-UNI-36 | Unit | BP_Classification | Classify stage 1 and stage 2 hypertensive levels | Unit', function() {
      expect(classifyBP(135, 85)).to.equal('Stage 1 Hypertension');
      expect(classifyBP(145, 95)).to.equal('Stage 2 Hypertension');
    });

    it('TC-UNI-37 | Unit | BP_Classification | Classify hypertensive crisis and invalid levels | Unit', function() {
      expect(classifyBP(190, 125)).to.equal('Hypertensive Crisis');
      expect(classifyBP(-120, 80)).to.equal('Unknown');
    });
  });

  describe('calculateCalorieBurn()', function() {
    it('TC-UNI-38 | Unit | Calorie_Burn | Verify normal burn at low intensity | Unit', function() {
      expect(calculateCalorieBurn(60, 30, 'low')).to.equal(79); // 2.5 * 3.5 * 60 * 30 / 200 = 78.75 -> 79
    });

    it('TC-UNI-39 | Unit | Calorie_Burn | Verify normal burn at high intensity | Unit', function() {
      expect(calculateCalorieBurn(75, 45, 'high')).to.equal(295); // 5.0 * 3.5 * 75 * 45 / 200 = 295.31 -> 295
    });

    it('TC-UNI-40 | Unit | Calorie_Burn | Verify invalid inputs returns zero burn | Unit', function() {
      expect(calculateCalorieBurn(-70, 30)).to.equal(0);
      expect(calculateCalorieBurn(70, 0)).to.equal(0);
    });
  });
});
