// Pruebas de las reglas de seguridad de Firestore (REQ-16).
// Se ejecutan contra el emulador de Firestore en GitHub Actions.
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment, assertSucceeds, assertFails,
} = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, collection, deleteDoc } = require('firebase/firestore');

let env;
const tarea = { title: 'Entregar Fase III', isCompleted: false, createdAt: new Date(), updatedAt: new Date() };

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-reglas-mis-tareas',
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

test('un usuario puede crear, leer y borrar sus propias tareas', async () => {
  const db = env.authenticatedContext('ana').firestore();
  const ref = doc(db, 'users/ana/tasks/t1');
  await assertSucceeds(setDoc(ref, tarea));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(getDocs(collection(db, 'users/ana/tasks')));
  await assertSucceeds(deleteDoc(ref));
});

test('un usuario puede crear y leer su documento de perfil users/{uid}', async () => {
  const db = env.authenticatedContext('ana').firestore();
  await assertSucceeds(setDoc(doc(db, 'users/ana'), { name: 'Ana', email: 'ana@mistareas.test' }));
  await assertSucceeds(getDoc(doc(db, 'users/ana')));
});

test('un usuario NO puede leer las tareas de otro usuario', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/beto/tasks/t1'), tarea);
  });
  const db = env.authenticatedContext('ana').firestore();
  await assertFails(getDoc(doc(db, 'users/beto/tasks/t1')));
  await assertFails(getDocs(collection(db, 'users/beto/tasks')));
});

test('un usuario NO puede escribir ni borrar en la cuenta de otro usuario', async () => {
  const db = env.authenticatedContext('ana').firestore();
  await assertFails(setDoc(doc(db, 'users/beto/tasks/t2'), tarea));
  await assertFails(deleteDoc(doc(db, 'users/beto/tasks/t1')));
});

test('sin iniciar sesión no se puede leer ni escribir nada', async () => {
  const db = env.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/ana/tasks/t1')));
  await assertFails(setDoc(doc(db, 'users/ana/tasks/t1'), tarea));
});

test('las colecciones fuera de users/{uid} están cerradas', async () => {
  const db = env.authenticatedContext('ana').firestore();
  await assertFails(setDoc(doc(db, 'otra/coleccion'), { x: 1 }));
  await assertFails(getDocs(collection(db, 'users')));
});
