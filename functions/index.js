const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Job programado que expira reservas con status 'reserved' más antiguas que 12 horas.
exports.expireOldReservations = functions.pubsub
  .schedule('every 5 minutes')
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    const maxAgeMs = 12 * 60 * 60 * 1000; // 12 horas
    const cutoff = new Date(Date.now() - maxAgeMs);
    const q = await db.collection('bookings').where('status', '==', 'reserved').where('timestamp', '<', cutoff).get();
    console.log(`Found ${q.size} reserved bookings to expire`);
    for (const doc of q.docs) {
      const data = doc.data();
      const horarioId = data.horarioId;
      const seatIndex = data.seatIndex;
      const horarioRef = db.collection('horarios').doc(String(horarioId));
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(horarioRef);
          const map = snap.exists ? snap.data() : {};
          const booked = Array.isArray(map?.bookedSeats) ? map.bookedSeats : [];
          const newBooked = booked.filter((s) => s !== seatIndex);
          tx.set(horarioRef, { bookedSeats: newBooked }, { merge: true });
          tx.delete(doc.ref);
        });
        console.log(`Expired booking ${doc.id} (horario ${horarioId}, seat ${seatIndex})`);
      } catch (err) {
        console.error('Error expiring booking', doc.id, err);
      }
    }
    return null;
  });
