/**
 * Discoverability sync handler.
 *
 * Keeps a stored `isDiscoverable` boolean on each user document in sync with
 * the privacy-related fields (accountStatus, isDeleted, isProfilePrivate).
 *
 * Firestore security rules for `list` queries can then gate on a single
 * equality check (`resource.data.isDiscoverable == true`) instead of
 * per-document inequality checks that cause permission-denied on queries.
 */

import {onDocumentWritten} from 'firebase-functions/v2/firestore';

interface UserData {
  accountStatus?: string;
  isDeleted?: boolean;
  isProfilePrivate?: boolean;
  isDiscoverable?: boolean;
}

function computeDiscoverable(data: UserData): boolean {
  const status = data.accountStatus ?? 'active';
  if (status !== 'active') return false;
  if (data.isDeleted === true) return false;
  if (data.isProfilePrivate === true) return false;
  return true;
}

export class DiscoverabilityHandlers {
  onUserWritten = onDocumentWritten('users/{userId}', async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return; // document deleted

    const data = after.data() as UserData;
    const computed = computeDiscoverable(data);

    if (data.isDiscoverable === computed) return; // already correct

    await after.ref.update({isDiscoverable: computed});
    console.log(
      `🔄 Synced isDiscoverable=${computed} for user ${event.params.userId}`
    );
  });
}
