Cloud Function programada: expirar reservas antiguas
===============================================

Este directorio contiene una función de Firebase (Node.js) que busca documentos en
la colección `bookings` con `status == 'reserved'` y `timestamp` anterior a 12 horas,
los elimina y actualiza la lista `horarios/{id}.bookedSeats` en una transacción.

Requisitos
- Tener un proyecto Firebase configurado.
- Firebase CLI instalado y autenticado: `npm install -g firebase-tools` y `firebase login`.
- Para usar funciones programadas necesitas el plan Blaze (habilita Cloud Scheduler).

Despliegue
1. Sitúate en el directorio `functions` y instala dependencias:
```bash
cd functions
npm install
```
2. Inicializa/selecciona tu proyecto Firebase y despliega la función programada:
```bash
firebase use <your-project-id>
firebase deploy --only functions:expireOldReservations
```

Pruebas locales
- Puedes probar la lógica localmente escribiendo un script de test que cree documentos
  `bookings` con `status: 'reserved'` y `timestamp` antiguo, y ejecutar `firebase emulators:start`.

Notas
- La función corre cada 5 minutos (ajustable) y requiere permisos de escritura en Firestore.
