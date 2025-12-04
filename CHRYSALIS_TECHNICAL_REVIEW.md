# Chrysalis Technical Review & Roadmap

**Prepared for:** Development Meeting
**Date:** December 4, 2025
**Application:** Chrysalis - Medical/Healthcare Secure Messaging Platform

---

## Executive Summary

Chrysalis is a multi-platform secure messaging application built with:
- **Mobile/Desktop/Web:** Flutter (single codebase)
- **Backend:** Node.js + Express + PostgreSQL + Prisma
- **Real-time:** Socket.IO
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Admin Panel:** React + Refine.dev

This document outlines 10 identified issues and feature requests with technical analysis and implementation recommendations.

---

## Issues & Feature Requests

### 1. Inconsistent Notifications

**Problem:** Users sometimes don't receive push notifications, or notifications arrive inconsistently.

**Root Causes Identified:**

| Issue | Location | Impact |
|-------|----------|--------|
| Missing `messageId` in push payload | `pushNotification.js` lines 37-54 | Mobile app cannot acknowledge delivery back to server |
| Web returns empty FCM token | `notification_remote_service.dart` lines 11-13 | Web users receive zero push notifications |
| Badge count stored in-memory only | `notification_service.dart` line 23 | Badge count resets on app restart |
| Firebase config mismatch | `firebase-messaging-sw.js` lines 5-13 | Web service worker points to wrong Firebase project |
| No FCM token refresh handler | Mobile app | Old/invalid tokens accumulate in database |

**Recommended Fix:**
```javascript
// Backend: pushNotification.js - Add messageId to push payload
data: {
  id: chatId,
  messageId: message.id,  // ADD THIS LINE
  type: 'conversation' | 'group',
  title: senderName,
  // ... rest of payload
}
```

**Effort:** 2-3 days
**Priority:** High

---

### 2. Messages Not Appearing in Real-Time

**Problem:** Messages sent by others don't appear until user navigates away and back. More frequent on desktop/web, but occurs on mobile too.

**Root Cause:** Race condition in socket room joining.

**Current Flow (Problematic):**
```
1. User opens chat
2. Load messages from API
3. Set up socket listeners
4. Join socket room
```

If another user sends a message after step 2 but before step 4 completes, that message is lost.

**Technical Details:**
- Location: `chat_detail_page.dart` in `addPostFrameCallback`
- No polling fallback exists if socket events are missed
- Listeners may be set on null socket during connection

**Recommended Fix:**
```dart
// Correct order - join room FIRST
await _joinRoomHelper.joinConversation(...);  // 1. Join room
_setupSocketListeners();                       // 2. Set up listeners
loadChats();                                   // 3. Load history
```

Additionally: Implement polling fallback - if no socket events for 10+ seconds, fetch via API.

**Effort:** 2-3 days
**Priority:** High

---

### 3. Badge Notifications on App Icon

**Problem:** Users want to see unread message count on the app icon (like WhatsApp).

**Current State:**

| Platform | Badge Support | Issue |
|----------|---------------|-------|
| iOS | Supported | Count stored in-memory, lost on restart |
| Android | Partial | Depends on launcher; count not persisted |
| macOS/Windows | Not implemented | Requires platform-specific code |

**Recommended Fix:**
1. Persist badge count to local storage
2. Restore count on app launch
3. Sync with server's unread count on startup
4. For desktop: Use `flutter_local_notifications` package

**Effort:** 1-2 days
**Priority:** Medium

---

### 4. File Organization (Media/Files Tab)

**Problem:** When someone sends images or files, users must scroll through chat history to find them. Users want dedicated tabs for media and files.

**Current State:**
- File upload/download works correctly
- Supported message types: TEXT, IMAGE, VIDEO, FILE, AUDIO
- Files stored in S3, metadata in database
- **No media gallery or file organization exists**

**Recommended Implementation:**

```
Chat Detail Page Structure:
├── Messages Tab (current view)
├── Media Tab (grid of images/videos)
├── Files Tab (list of documents)
└── Links Tab (parsed URLs from messages)
```

**Technical Approach:**
- Add TabBar to `chat_detail_page.dart`
- Create `MediaGalleryWidget` with grid view and thumbnails
- Create `FileListWidget` with file icons, sizes, and dates
- Filter existing messages by type (no backend changes required)

**Effort:** 2-3 days
**Priority:** Medium

---

### 5. Desktop Apps (Mac/Windows) + Web Notifications

**Problem:** Users want to use Chrysalis on computers with real notifications.

**Current State:**

| Platform | App Works | Notifications |
|----------|-----------|---------------|
| iOS | Yes | Yes (FCM Push) |
| Android | Yes | Yes (FCM Push) |
| Web | Yes | No (disabled - returns empty token) |
| macOS | Not enabled | N/A |
| Windows | Not enabled | N/A |

**Important:** Flutter natively supports macOS, Windows, and Linux. Same codebase - not a separate framework.

**To Enable Desktop Builds:**
```bash
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter build macos
flutter build windows
```

**Implementation Tasks:**

| Task | Effort |
|------|--------|
| Enable desktop build targets | 1 hour |
| UI responsive adjustments for larger screens | 1-2 days |
| Native notifications via socket (not FCM) | 1-2 days |
| Code signing (macOS notarization, Windows certificate) | 1-2 days |
| Build and distribution pipeline | 1 day |
| **Total for Desktop** | **~1 week** |

**Desktop Notification Approach:**
- Cannot use FCM push on desktop the same way as mobile
- Keep socket connection alive
- When `new_message` event arrives via socket, show native OS notification
- Use `flutter_local_notifications` package (supports macOS/Windows)

**Web Notifications Fix:**
```dart
// Current (broken):
static Future<String?> getToken() async {
  if (kIsWeb) return '';  // Returns empty string!
}

// Fixed:
static Future<String?> getToken() async {
  if (kIsWeb) {
    return await FirebaseMessaging.instance.getToken(vapidKey: 'YOUR_VAPID_KEY');
  }
}
```

**Effort:** Desktop apps ~1 week; Web notifications ~2-3 days
**Priority:** Medium-High

---

### 6. Android Frequent Re-Login

**Problem:** Android users get logged out frequently and must re-enter credentials.

**Root Causes Identified:**

| Issue | Detail |
|-------|--------|
| No proactive token refresh | Access token expires in 15 minutes; app only refreshes after receiving 401 error |
| Aggressive logout behavior | Any error during refresh triggers immediate logout and clears all local data |
| No retry logic | Single network hiccup during refresh results in logout |
| Android device ID instability | `ANDROID_ID` can change after factory reset or Play Services update |
| `expiresAt` not stored | App doesn't know when token will expire |

**Current Flow (Problematic):**
```
User idle 15+ minutes → Token expires
User performs action → API returns 401
App attempts refresh → If ANY error occurs → Immediate LOGOUT
```

**Recommended Flow:**
```
App startup → Read expiresAt from storage
Set timer → Refresh 2 minutes before expiry
Refresh fails → Retry 3x with exponential backoff
All retries fail → Then logout
```

**Implementation:**
```dart
void _scheduleTokenRefresh() async {
  final expiresAt = await storage.read('expiresAt');
  final refreshTime = expiresAt.subtract(Duration(minutes: 2));

  Timer(refreshTime.difference(DateTime.now()), () async {
    try {
      await _refreshToken();
      _scheduleTokenRefresh(); // Schedule next refresh
    } catch (e) {
      // Implement retry with backoff
    }
  });
}
```

**Effort:** 2-3 days
**Priority:** High

---

### 7. Role-Based Direct Messaging

**Problem:** Need certain user roles to be able to DM each other while restricting others.

**Current State:**

| Aspect | Status |
|--------|--------|
| Existing Roles | SUPERADMIN, ADMIN, USER |
| UI Restriction | DMs blocked at UI level (tap on user does nothing) |
| Backend Restriction | None - if UI bypassed, backend would allow message |

**Current Implementation (UI Block Only):**
```dart
// search_group.dart lines 78-82
if (result.isUserType) {
  log('User tapped: ${result.name}');
  return;  // Blocks DM initiation - no navigation occurs
}
```

**Recommended Implementation:**

1. **Add new role to Prisma schema:**
```prisma
enum Role {
  SUPERADMIN
  ADMIN
  MEMBER    // New role for users who can DM each other
  USER
}
```

2. **Create permission configuration:**
```javascript
// config/dmPermissions.js
const canDM = {
  SUPERADMIN: ['SUPERADMIN', 'ADMIN', 'MEMBER', 'USER'],
  ADMIN: ['SUPERADMIN', 'ADMIN', 'MEMBER', 'USER'],
  MEMBER: ['SUPERADMIN', 'ADMIN', 'MEMBER'],  // Can DM other MEMBERs
  USER: ['SUPERADMIN', 'ADMIN'],               // Cannot DM other USERs
};
```

3. **Add backend enforcement:**
```javascript
// chat.service.js - in sendMessage function
if (!canDM[sender.role].includes(recipient.role)) {
  throw new Error('You do not have permission to message this user');
}
```

4. **Update mobile UI to allow DMs for permitted roles**

**Effort:** 1-2 days
**Priority:** Medium

---

### 8. Reply to Messages + See Who Reacted

#### 8A: Reply to Messages (Quote/Threading)

**Current State:** Feature does not exist.

No `replyToId` field in database, no threading, no quote functionality.

**Required Changes:**

| Layer | Change Required |
|-------|-----------------|
| Database | Add `replyToId` field to Message model |
| API | Accept `replyToId` parameter in send message endpoint |
| Socket | Include quoted message data in events |
| Mobile | Long-press menu with "Reply" option; quoted message preview in UI |

**UI Example:**
```
┌─────────────────────────────┐
│ ┌─────────────────────────┐ │
│ │ Replying to: "Hey..."   │ │  ← Quoted message
│ └─────────────────────────┘ │
│ My response here            │  ← New message
└─────────────────────────────┘
```

**Effort:** 3-5 days
**Priority:** Medium

---

#### 8B: See Who Reacted

**Current State:** Reactions work, but users cannot see who reacted.

| What Works | What's Missing |
|------------|----------------|
| Add/remove reactions | View reactor names |
| See emoji + count | Tap to view reactor list |
| Backend sends user data | Mobile app ignores reactor info |

**Key Finding:** Backend already sends reactor information - mobile app doesn't display it.

**Fix:**
```dart
// Add tap handler to reaction display
GestureDetector(
  onTap: () => _showReactorsList(emoji, reactors),
  child: Row(
    children: [
      Text(emoji),
      Text(count.toString()),
    ],
  ),
)

void _showReactorsList(String emoji, List<User> reactors) {
  showModalBottomSheet(
    // Display list of user avatars and names
  );
}
```

**Effort:** 1-2 days
**Priority:** Low-Medium (easy win)

---

### 9. View Group Members

**Problem:** Users want to see who is in their group when they tap "Members."

**Current State:**

| Layer | Status |
|-------|--------|
| Database | GroupMember model exists with all data |
| API | Returns full member list |
| Mobile UI | Only displays count ("5 members"), no member list view |

**Security Concern:** Group API endpoints have no authentication. Anyone can view any group's member list.

**Recommended Fix:**

1. **Add member list UI:**
```dart
void _showMembersList() {
  showModalBottomSheet(
    builder: (_) => MemberListWidget(members: group.members),
  );
}
```

2. **Secure the API:**
```javascript
// Add authentication and membership verification
router.get('/:groupId', authenticate, verifyGroupMember, groupController.getGroupDetails);
```

**Effort:** 1 day for UI; +1 day to secure API
**Priority:** Low (easy win)

---

### 10. File Sender Cannot See Own Sent Files (NEW BUG)

**Problem:** When a user sends a picture or file, the sender cannot see or download it, but other users can.

**Root Cause:** Bug in `chat_detail_bloc.dart` at line 234.

The code incorrectly overwrites the valid S3 URL with a local placeholder path.

**Bug Location:**
```dart
// chat_detail_bloc.dart lines 234-235 - INCORRECT
return m.copyWith(
  status: 'SENT',
  fileUrl: savedFilePath,  // BUG: savedFilePath is "/temp/filename.pdf"
  id: sent.id,
);
```

**What Happens:**
1. User sends file
2. Backend uploads to S3, returns correct URL in `sent.fileUrl`
3. Mobile app ignores `sent.fileUrl` and uses local `savedFilePath` instead
4. Sender tries to download from invalid path → fails
5. Other users receive correct URL via Socket.IO → works

**Fix:**
```dart
// Change line 234 from:
fileUrl: savedFilePath,

// To:
fileUrl: sent.fileUrl,
```

**Effort:** 30 minutes (one-line fix)
**Priority:** High

---

## Summary: Prioritized Roadmap

### Quick Wins (1-2 days each)

| Item | Description | Effort |
|------|-------------|--------|
| 10 | Fix file sender bug | 30 minutes |
| 9 | View group members UI | 1 day |
| 8B | See who reacted | 1-2 days |
| 3 | Badge count persistence | 1-2 days |

### Bug Fixes (2-3 days each)

| Item | Description | Effort |
|------|-------------|--------|
| 1 | Fix notification inconsistency | 2-3 days |
| 2 | Fix real-time message delivery | 2-3 days |
| 6 | Fix Android re-login | 2-3 days |

### Medium Features (2-5 days each)

| Item | Description | Effort |
|------|-------------|--------|
| 4 | Media/files tabs | 2-3 days |
| 7 | Role-based DM permissions | 1-2 days |
| 5 | Web notifications | 2-3 days |

### Larger Features

| Item | Description | Effort |
|------|-------------|--------|
| 5 | Desktop apps (Mac/Windows) | ~1 week |
| 8A | Reply to messages | 3-5 days |

---

## Technical Debt & Security Notes

1. **Group API Security:** Endpoints lack authentication - anyone can view group member details
2. **Firebase Config:** Web service worker has hardcoded credentials pointing to wrong project
3. **Token Storage:** `expiresAt` field from JWT not stored or used for proactive refresh
4. **Device ID:** Android `ANDROID_ID` can change, causing authentication issues

---

## Appendix: Key File Locations

**Mobile App (Flutter):**
- `lib/features/chat_detail/presentation/bloc/chat_detail_bloc.dart` - Message handling, file bug
- `lib/features/chat_detail/presentation/pages/chat_detail_page.dart` - Chat UI, socket listeners
- `lib/features/notifications/presentation/service/notification_service.dart` - Push notifications
- `lib/core/network/auth_interceptor.dart` - Token refresh logic
- `lib/features/search_groups/presentation/pages/search_group.dart` - DM UI block

**Backend (Node.js):**
- `src/services/chat.service.js` - Message sending, no role checks
- `src/utils/pushNotification.js` - Push notification payload
- `src/socket.js` - Real-time events
- `src/routes/groups.route.js` - Unsecured group endpoints
- `prisma/schema.prisma` - Database models

**Web:**
- `web/firebase-messaging-sw.js` - Incorrect Firebase config
