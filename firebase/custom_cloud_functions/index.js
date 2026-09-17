const admin = require("firebase-admin/app");
admin.initializeApp();

const updateStreak = require("./update_streak.js");
exports.updateStreak = updateStreak.updateStreak;
const checkStreakOnOpen = require("./check_streak_on_open.js");
exports.checkStreakOnOpen = checkStreakOnOpen.checkStreakOnOpen;
