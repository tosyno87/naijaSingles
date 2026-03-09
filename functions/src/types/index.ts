/**
 * Type definitions for NaijaSingles Cloud Functions
 */

export interface User {
  id: string;
  name?: string;
  email?: string;
  phone?: string;
  pushToken?: string;
  notificationPreferences?: NotificationPreferences;
  imageUrl?: string[];
  Pictures?: string[];
  photos?: string[];
  photoUrl?: string;
  [key: string]: any;
}

export interface NotificationPreferences {
  matchNotifications?: boolean;
  messageNotifications?: boolean;
  superLikeNotifications?: boolean;
  likeNotifications?: boolean;
}

export interface Match {
  id: string;
  users: string[];
  createdAt: Date;
  [key: string]: any;
}

export interface Message {
  id: string;
  senderId: string;
  text?: string;
  timestamp: Date;
  [key: string]: any;
}

export interface ChatThread {
  id: string;
  userIds: string[];
  [key: string]: any;
}

export interface SuperLike {
  id: string;
  fromUserId: string;
  toUserId: string;
  createdAt: Date;
  [key: string]: any;
}

export interface Like {
  id: string;
  LikedBy: string;
  createdAt: Date;
  [key: string]: any;
}

export interface NotificationData {
  id: string;
  type: 'match' | 'message' | 'super_like' | 'superLike' | 'like';
  title: string;
  message: string;
  avatarUrl?: string;
  actionId: string;
  superLikeId?: string;
  timestamp: Date;
  isRead: boolean;
}

export interface NotificationLog {
  id: string;
  userId: string;
  type: string;
  status: 'sent' | 'failed' | 'stored';
  timestamp: Date;
  error?: string;
}

export interface NotificationMessage {
  notification: {
    title: string;
    body: string;
  };
  data: {
    type: string;
    [key: string]: string;
  };
  token: string;
  android?: {
    notification: {
      icon: string;
      color: string;
      sound: string;
      channelId: string;
    };
  };
  apns?: {
    payload: {
      aps: {
        sound: string;
        badge: number;
      };
    };
  };
}

export enum NotificationType {
  MATCH = 'match',
  MESSAGE = 'message',
  SUPER_LIKE = 'super_like',
  LIKE = 'like',
}

export enum NotificationStatus {
  SENT = 'sent',
  FAILED = 'failed',
  STORED = 'stored',
}
