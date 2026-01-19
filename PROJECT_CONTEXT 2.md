# AfroPeep Project Context

> **Purpose**: This document provides essential context for AI agents working on the AfroPeep codebase. It outlines the app's purpose, architecture, key features, and development practices.

## 🎯 Project Overview

**AfroPeep** (formerly NaijaSingles) is a Flutter-based dating and social networking app specifically designed for Africans in the diaspora. The app combines traditional dating features (swiping, matching, chatting) with community-focused features (events, communities hub) to create a culturally relevant platform.

### Core Mission
- Connect Africans in the diaspora through dating and social networking
- Provide culturally relevant features and content
- Build community through events and shared experiences
- Maintain high standards for user safety and content moderation

## 🏗️ Architecture

### Tech Stack
- **Framework**: Flutter 3.32.3+ (Dart 3.5+)
- **State Management**: BLoC pattern
- **Backend**: Firebase (Firestore, Auth, Storage, Functions)
- **Maps**: Google Maps API
- **CI/CD**: Fastlane, GitHub Actions
- **Platforms**: iOS, Android

### Project Structure
```
lib/
├── core/              # Shared utilities, constants, themes
├── features/          # Feature modules (auth, match, chat, events, etc.)
│   ├── auth/
│   ├── match/
│   ├── chat/
│   ├── events/
│   └── profile/
├── main.dart
└── ...
```

### Key Architectural Principles
1. **Feature-based modular structure** - Each feature is self-contained
2. **Clean Architecture** - Separation of data, domain, and presentation layers
3. **BLoC for state management** - Predictable state management
4. **Repository pattern** - Abstraction layer for data sources
5. **Dependency injection** - Using Riverpod or similar

## ✨ Core Features

### 1. Dating Features
- **Swipe Interface**: Card-based swiping (Pass, Like, Super Like)
- **Matching System**: Mutual like detection, match creation
- **Premium Features**: Swipe limits, Super Like limits, Rewind/Undo
- **User Discovery**: Location-based matching with filters

### 2. Chat & Messaging
- Real-time chat using Firestore
- Typing indicators
- Message moderation
- Match-based chat threads

### 3. Events & Communities
- Eventbrite API integration for Afrocentric events
- RSVP functionality
- Community groups
- Event discovery and filtering

### 4. Profile Management
- Comprehensive profile creation
- Photo uploads
- Profile verification system
- Content moderation for bios and names

### 5. Safety & Moderation
- Content moderation service (text filtering)
- Profile verification (email, phone, photo, ID, employment)
- User reporting system
- Security rules enforcement

## 🔐 Security & Best Practices

### Security Measures
- Environment-based configuration (no hardcoded secrets)
- Firestore security rules
- Content moderation for user-generated content
- Profile verification system
- Secure authentication (phone, email)

### Code Quality
- Dart style guidelines and Effective Dart
- Null safety enforced
- Comprehensive testing (unit, widget, integration)
- Linting with `flutter analyze`
- Code reviews required

## 📱 App Sections

1. **Communities Hub** - Events and community groups
2. **Connect** - Dating/swiping functionality
3. **Messages** - Chat system
4. **Profile** - User profiles and settings

## 🚀 Development Workflow

### Branch Strategy
- `main` - Production releases
- `develop` - Integration branch
- `feature/*` - Feature development
- `release/*` - Release preparation
- `hotfix/*` - Critical fixes

### Environments
- **Development**: `naijasingles-dev` (feature branches)
- **Staging**: `naijasingles-staging` (release branches)
- **Production**: `naijasingles-prod` (main branch)

### Testing
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for critical flows
- Manual testing guides in `docs/testing/`

## 📚 Documentation Structure

- `docs/architecture/` - System design and architecture
- `docs/guides/` - How-to guides and tutorials
- `docs/features/` - Feature-specific documentation
- `docs/deployment/` - Deployment guides
- `docs/testing/` - Testing guides and procedures
- `docs/archive/` - Historical/outdated documentation

## 🎨 Design Guidelines

### Theme
- **Primary Color**: Green accents (brand color)
- **Background**: #FFF6E5 (warm beige)
- **Font**: Montserrat (primary), system fonts (fallback)
- **Material 3**: Use Material You components where possible

### UI Principles
- Responsive design (mobile, tablet, web)
- Reusable widgets
- Consistent spacing and typography
- Accessibility considerations

## 🔧 Key Services & Repositories

### Services
- `LikesService` - Like handling and mutual detection
- `MatchService` - Match creation and management
- `SuperLikeService` - Super like functionality
- `ContentModerationService` - Text moderation
- `ProfileVerificationService` - Verification management
- `UserSearchRepo` - User discovery and filtering

### Firebase Collections
- `users` - User profiles
- `matches` - Match records
- `likes` - Like records
- `chats` - Chat threads
- `messages` - Chat messages
- `events` - Event data
- `rsvps` - RSVP records

## 🚨 Common Issues & Solutions

### Known Patterns
- Use BLoC for state management
- Always handle null safety
- Use const constructors where possible
- Cache results to minimize rebuilds
- Follow repository pattern for data access

### Debugging
- See `DEBUG_GUIDE.md` for debugging procedures
- Use Flutter DevTools for performance profiling
- Check Firebase console for backend issues

## 📖 Additional Resources

- **Main README**: `README.md` - Setup and quick start
- **Deployment**: `docs/deployment/DEPLOYMENT_GUIDE.md`
- **Security**: `docs/guides/SECURITY_AND_SETUP_GUIDE.md`
- **Testing**: `docs/testing/` - Testing guides

## 🎯 Development Priorities

1. **User Safety**: Content moderation, verification, reporting
2. **Performance**: Optimize matching, caching, reduce rebuilds
3. **User Experience**: Smooth navigation, responsive UI
4. **Feature Completeness**: Complete advanced filters, boost features
5. **Monetization**: Premium features, ad integration (future)

---

**Last Updated**: December 2024  
**Maintained By**: Development Team  
**For Questions**: See relevant documentation in `docs/` directory

