/**
 * Tests for NotificationService
 */

import {NotificationService} from '../notificationService';
import {User} from '../../types';

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
  messaging: jest.fn(() => ({
    send: jest.fn(),
  })),
}));

describe('NotificationService', () => {
  let notificationService: NotificationService;
  let mockUser: User;

  beforeEach(() => {
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
      const mockMessaging = require('firebase-admin').messaging();
      mockMessaging.send.mockResolvedValue('message-id');

      await notificationService.sendMatchNotification(mockUser, matchedUser);

      expect(mockMessaging.send).toHaveBeenCalledWith(
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

      const mockMessaging = require('firebase-admin').messaging();
      mockMessaging.send.mockClear();

      await notificationService.sendMatchNotification(userWithoutToken, matchedUser);

      expect(mockMessaging.send).not.toHaveBeenCalled();
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

      const mockMessaging = require('firebase-admin').messaging();
      mockMessaging.send.mockClear();

      await notificationService.sendMatchNotification(userWithDisabledNotifications, matchedUser);

      expect(mockMessaging.send).not.toHaveBeenCalled();
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

      const mockMessaging = require('firebase-admin').messaging();
      mockMessaging.send.mockResolvedValue('message-id');

      await notificationService.sendMessageNotification(mockUser, sender, messageData, threadId);

      expect(mockMessaging.send).toHaveBeenCalledWith(
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

      const mockMessaging = require('firebase-admin').messaging();
      mockMessaging.send.mockResolvedValue('message-id');

      await notificationService.sendMessageNotification(mockUser, sender, messageData, threadId);

      expect(mockMessaging.send).toHaveBeenCalledWith(
        expect.objectContaining({
          notification: {
            body: 'a'.repeat(100) + '...',
          },
        })
      );
    });
  });
});
