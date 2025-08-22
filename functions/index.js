const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateRanking = functions.firestore
    .document('rankings/{puzzleId}')
    .onWrite(async (change, context) => {
        const puzzleId = context.params.puzzleId;
        const rankingRef = admin.firestore().collection('rankings').doc(puzzleId);
        const snapshot = await rankingRef.get();

        if (!snapshot.exists) return null;

        const data = snapshot.data();
        const topTimes = data.topTimes || [];

        topTimes.sort((a, b) => a.time - b.time);

        if (topTimes.length > 10) {
            topTimes.splice(10);
        }

        return rankingRef.update({ topTimes });
    });
