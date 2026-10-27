import { readFileSync } from 'node:fs';
import { after, before, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, runTransaction } from 'firebase/firestore';

let environment;
before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-keybudget',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => environment?.cleanup());

for (const path of [
  'users/owner/vault/config',
  'users/owner/vault_keys/key',
  'users/owner/vault_migrations/migration',
  'users/owner/vault_items/migration-item',
  'users/owner/vault_backups/migration-generation-000000',
]) {
  test(`only the owner can access ${path}`, async () => {
    const owner = environment.authenticatedContext('owner').firestore();
    const other = environment.authenticatedContext('other').firestore();
    const anonymous = environment.unauthenticatedContext().firestore();
    await assertSucceeds(setDoc(doc(owner, path), { schemaVersion: 1, value: 'synthetic' }));
    await assertSucceeds(getDoc(doc(owner, path)));
    for (const denied of [other, anonymous]) {
      await assertFails(getDoc(doc(denied, path)));
      await assertFails(setDoc(doc(denied, path), { value: 'replacement' }));
      await assertFails(deleteDoc(doc(denied, path)));
    }
  });
}

test('source replacement and checkpoint commit together', async () => {
  const owner = environment.authenticatedContext('transaction-owner').firestore();
  const source = doc(owner, 'users/transaction-owner/credentials/one');
  const checkpoint = doc(owner, 'users/transaction-owner/vault_items/one-item');
  await setDoc(source, { encrypted_password: 'legacy' });
  await runTransaction(owner, async (transaction) => {
    await transaction.get(source);
    transaction.set(source, { encrypted_password: 'versioned' });
    transaction.set(checkpoint, { status: 'committed' });
  });
  const invalid = doc(owner, 'users/other/credentials/forbidden');
  await assertFails(runTransaction(owner, async (transaction) => {
    await transaction.get(source);
    transaction.set(source, { encrypted_password: 'must-not-commit' });
    transaction.set(invalid, { encrypted_password: 'forbidden' });
  }));
  const actual = await getDoc(source);
  if (actual.data().encrypted_password !== 'versioned') throw new Error('Partial transaction applied');
  const item = await getDoc(checkpoint);
  if (item.data().status !== 'committed') throw new Error('Missing checkpoint');
});
