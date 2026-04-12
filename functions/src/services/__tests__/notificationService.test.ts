/**
 * Tests for NotificationService
 */

import {NotificationService} from '../notificationService';
import {User} from '../../types';

// Single messaging instance so service + tests share the same `send` mock.
const messagingSingleton = {send: jest.fn()};

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      add: jest.fn(),
      doc: jest.fn(() => ({
        set: jest.fn(),
        get: jest.fn(),
      })),
    })),
  })),
  messaging: jest.fn(() => messagingSingleton),
}));

describe('NotificationService', () => {
  let notificationService: NotificationService;
  let mockUser: User;

  beforeEach(() => {
    messagingSingleton.send.mockClear();
    notificationService = new NotificationService();
    mockUser = {
      id: 'test-user-id',
      name: 'Test User',
      pushToken: 'test-push-token',
      notificationPreferences: {
        matchNotifications: true,
        messageNotifications: true,
        superLikeNotifications: true,
        likeNotifications: true,
      },
    };
  });

  describe('sendMatchNotification', () => {
    it('should send match notification successfully', async () => {
      const matchedUser: User = {
        id: 'matched-user-id',
        name: 'Matched User',
      };

      // Mock the messaging send method
      messagingSingleton.send.mockResolvedValue('message-id');

      await notificationService.sendMatchNotification(mockUser, matchedUser);

      expect(messagingSingleton.send).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: {
            title: '🎉 It\'s a Match!',
            body: 'You and Matched User liked each other!',
          },
          token: 'test-push-token',
        })
      );
    });

    it('should not send notification if user has no push token', async () => {
      const userWithoutToken = {...mockUser, pushToken: undefined};
      const matchedUser: User = {
        id: 'matched-user-id',
        name: 'Matched User',
      };

      messagingSingleton.send.mockClear();

      await notificationService.sendMatchNotification(userWithoutToken, matchedUser);

      expect(messagingSingleton.send).not.toHaveBeenCalled();
    });

    it('should not send notification if match notifications are disabled', async () => {
      const userWithDisabledNotifications = {
        ...mockUser,
        notificationPreferences: {
          ...mockUser.notificationPreferences,
          matchNotifications: false,
        },
      };
      const matchedUser: User = {
        id: 'matched-user-id',
        name: 'Matched User',
      };

      messagingSingleton.send.mockClear();

      await notificationService.sendMatchNotification(userWithDisabledNotifications, matchedUser);

      expect(messagingSingleton.send).not.toHaveBeenCalled();
    });

    it('should not send notification if enableAllNotifications is false', async () => {
      const userMasterOff = {
        ...mockUser,
        notificationPreferences: {
          ...mockUser.notificationPreferences,
          enableAllNotifications: false,
        },
      };
      const matchedUser: User = {
        id: 'matched-user-id',
        name: 'Matched User',
      };

      messagingSingleton.send.mockClear();

      await notificationService.sendMatchNotification(userMasterOff, matchedUser);

      expect(messagingSingleton.send).not.toHaveBeenCalled();
    });

    it('should not send notification if muteAllNotifications is true', async () => {
      const userMuted = {
        ...mockUser,
        notificationPreferences: {
          ...mockUser.notificationPreferences,
          muteAllNotifications: true,
        },
      };
      const matchedUser: User = {
        id: 'matched-user-id',
        name: 'Matched User',
      };

      messagingSingleton.send.mockClear();

      await notificationService.sendMatchNotification(userMuted, matchedUser);

      expect(messagingSingleton.send).not.toHaveBeenCalled();
    });
  });

  describe('sendMessageNotification', () => {
    it('should send message notification successfully', async () => {
      const sender: User = {
        id: 'sender-id',
        name: 'Sender User',
      };
      const messageData = {
        text: 'Hello, how are you?',
      };
      const threadId = 'test-thread-id';

      messagingSingleton.send.mockResolvedValue('message-id');

      await notificationService.sendMessageNotification(mockUser, sender, messageData, threadId);

      expect(messagingSingleton.send).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: {
            title: 'Sender User',
            body: 'Hello, how are you?',
          },
          token: 'test-push-token',
        })
      );
    });

    it('should truncate long messages', async () => {
      const sender: User = {
        id: 'sender-id',
        name: 'Sender User',
      };
      const longMessage = 'a'.repeat(150);
      const messageData = {
        text: longMessage,
      };
      const threadId = 'test-thread-id';

      messagingSingleton.send.mockResolvedValue('message-id');

      await notificationService.sendMessageNotification(mockUser, sender, messageData, threadId);

      expect(messagingSingleton.send).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: expect.objectContaining({
            body: expect.stringMatching(/^a{100}\.\.\.$/),
          }),
        })
      );
    });
  });
});
