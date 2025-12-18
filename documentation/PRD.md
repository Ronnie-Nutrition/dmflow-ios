# Product Requirements Document (PRD)

## 1. Product Overview

### 1.1 Product Name
**DMFlow** (or alternative: ProspectPro, FunnelDM)

### 1.2 Vision Statement
A simple, mobile-first prospect tracking app that helps network marketers and sales professionals manage DM conversations across platforms, ensuring no lead falls through the cracks and every prospect moves through the funnel until conversion or disqualification.

### 1.3 Target Users
- **Primary**: Network marketers (Herbalife distributors, etc.) who prospect via Instagram, Facebook, and SMS
- **Secondary**: Coaches, consultants, and service providers who close deals in DMs
- **Tertiary**: Small sales teams needing lightweight prospect tracking without enterprise CRM complexity

### 1.4 Key Goals
- Eliminate lost leads due to forgotten follow-ups
- Provide instant visibility into "who needs attention today"
- Track every prospect from first contact to conversion or DND
- Work seamlessly on mobile while actively DMing
- No dependency on third-party platforms (ManyChat, etc.)

### 1.5 Value Proposition
Unlike web-based solutions that require ManyChat integration, DMFlow lives in your pocket and works across all messaging platforms (IG, FB, SMS, WhatsApp) with zero external dependencies.

---

## 2. Feature Specifications

### 2.1 Core Features (MVP - Phase 1)

#### Feature 1: Prospect Management
**Description**: Add, edit, and manage individual prospects with key tracking fields.

**Data Fields per Prospect**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Name | Text | Yes | Prospect's name |
| Handle | Text | No | Instagram/social handle |
| Platform | Enum | Yes | IG, Facebook, SMS, WhatsApp, Other |
| Stage | Enum | Yes | Current funnel stage |
| Last Contact | Date | Auto | Date of last interaction |
| Next Follow-Up | Date | No | Scheduled follow-up date |
| Notes | Text | No | Quick context/conversation notes |
| Hot Lead | Boolean | No | Flag for high-priority prospects |
| Created | Date | Auto | When prospect was added |

**Acceptance Criteria**:
- User can add a new prospect in under 10 seconds
- User can edit any field by tapping on it
- User can delete a prospect with confirmation
- All data persists locally and syncs to cloud

**User Flow**:
1. Tap "+" button
2. Enter name (required)
3. Select platform
4. Optionally add handle, notes, follow-up date
5. Save → Prospect appears in "New" stage

---

#### Feature 2: Funnel Pipeline View
**Description**: Visual kanban-style view showing all prospects organized by stage.

**Funnel Stages** (in order):
1. **New** - First contact made, conversation started
2. **Engaged** - Active conversation, showing interest
3. **Presented** - Shared products/opportunity info
4. **Follow-Up** - Waiting on their decision
5. **Client** - Converted! ✓
6. **DND** - Do Not Disturb / Dead lead

**Acceptance Criteria**:
- Swipe left/right to move prospect to next/previous stage
- Tap prospect card to view/edit details
- Visual count of prospects per stage
- Color-coded stages for quick scanning
- Long-press to access quick actions (call, message, delete)

**User Flow**:
1. Open app → See pipeline view by default
2. Swipe prospect card right → Moves to next stage
3. Swipe left → Moves to previous stage
4. Tap card → Opens detail view

---

#### Feature 3: Today's Follow-Ups Dashboard
**Description**: Priority view showing exactly who needs attention today.

**Sections**:
1. **Overdue** - Follow-ups past their scheduled date (red)
2. **Today** - Follow-ups scheduled for today (orange)
3. **Hot Leads** - Flagged high-priority prospects (yellow star)
4. **Recent Activity** - Prospects contacted in last 24 hours

**Acceptance Criteria**:
- Dashboard loads instantly on app open (< 1 second)
- Shows count badges for each section
- Tap any prospect to open detail view
- Quick action buttons: Mark Done, Snooze 1 Day, Move Stage

**User Flow**:
1. App opens to Today view
2. See overdue count immediately
3. Tap prospect → Take action
4. Mark complete → Moves to appropriate stage or clears follow-up

---

#### Feature 4: Quick Add from Share Sheet
**Description**: Add prospects directly from Instagram/social apps via iOS share sheet.

**Acceptance Criteria**:
- Share a profile or conversation → DMFlow appears in share options
- Pre-fills handle/name when available
- Opens mini-form to set stage and add notes
- Saves without leaving the source app

**User Flow**:
1. In Instagram, tap share on a profile
2. Select DMFlow
3. Quick form appears
4. Add notes, set stage
5. Save → Return to Instagram

---

#### Feature 5: Search & Filter
**Description**: Find any prospect quickly across the entire database.

**Search Capabilities**:
- Search by name or handle
- Filter by stage
- Filter by platform
- Filter by date range (last contact, created)
- Filter by hot lead flag

**Acceptance Criteria**:
- Search results appear as user types
- Filters can be combined
- Clear all filters with one tap
- Search works offline

---

#### Feature 6: Basic Analytics
**Description**: Simple stats to track performance.

**Metrics Displayed**:
- Total prospects by stage
- Conversion rate (New → Client)
- Average time in each stage
- Follow-up compliance rate
- Weekly/monthly activity summary

**Acceptance Criteria**:
- Stats update in real-time
- Simple visual charts (bar/pie)
- Export weekly summary (optional)

---

### 2.2 Phase 2 Features (Post-Launch)

1. **Message Templates**: Save and reuse proven DM scripts
2. **A/B Script Tracking**: Track which messages convert better
3. **Team Support**: Multiple users, shared pipeline (for coaches with teams)
4. **Automated Reminders**: Push notifications for follow-ups
5. **Calendar Integration**: Sync follow-ups with iOS Calendar
6. **iCloud Sync**: Seamless sync across iPhone and iPad
7. **Apple Watch Complication**: Quick view of today's follow-up count
8. **Siri Shortcuts**: "Hey Siri, add a new prospect"
9. **Widget**: Home screen widget showing overdue count
10. **Export to CSV**: Download prospect data for analysis

### 2.3 Out of Scope (Not in V1)

- Direct Instagram/Facebook API integration (no auto-DM sending)
- Web dashboard
- Android version (iOS first)
- CRM integrations (Salesforce, HubSpot, etc.)
- Payment/invoicing features
- Multi-language support

---

## 3. Technical Requirements

### 3.1 Platform Requirements
- **iOS**: Minimum iOS 16.0+
- **Devices**: iPhone (primary), iPad (secondary)
- **Framework**: Native Swift/SwiftUI

### 3.2 Architecture
- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Local Storage**: SwiftData (iOS 17+) with Core Data fallback
- **Cloud Sync**: CloudKit (Apple's free sync service)

### 3.3 External Integrations

| Integration | Purpose | Priority |
|-------------|---------|----------|
| CloudKit | Data sync across devices | MVP |
| iOS Share Extension | Quick add from other apps | MVP |
| Local Notifications | Follow-up reminders | MVP |
| iOS Calendar (EventKit) | Calendar sync | Phase 2 |
| Siri/Shortcuts | Voice commands | Phase 2 |

### 3.4 Authentication
- **Method**: Sign in with Apple (required for CloudKit)
- **Fallback**: Local-only mode (no account required)
- **Session**: Persistent until user signs out

### 3.5 Data Storage

**Local Storage**:
- SwiftData for structured prospect data
- UserDefaults for app preferences
- Keychain for any sensitive data

**Cloud Storage**:
- CloudKit private database (free, included with Apple ID)
- Automatic sync when online
- Full offline support with sync on reconnect

**Data Model**:
```swift
@Model
class Prospect {
    var id: UUID
    var name: String
    var handle: String?
    var platform: Platform
    var stage: FunnelStage
    var lastContact: Date
    var nextFollowUp: Date?
    var notes: String?
    var isHotLead: Bool
    var createdAt: Date
    var updatedAt: Date
}

enum Platform: String, Codable {
    case instagram, facebook, sms, whatsapp, other
}

enum FunnelStage: String, Codable, CaseIterable {
    case new, engaged, presented, followUp, client, dnd
}
```

### 3.6 Performance Requirements
- App launch time: < 2 seconds
- Add prospect: < 500ms
- Search results: < 200ms
- Offline mode: Full functionality
- Sync latency: < 5 seconds when online

### 3.7 Security Requirements
- Data encryption: At rest via iOS Data Protection
- CloudKit: End-to-end encrypted in private database
- No third-party analytics that collect PII
- GDPR/CCPA compliant data handling

---

## 4. Design & UX

### 4.1 Design System

**Color Palette**:
| Color | Hex | Usage |
|-------|-----|-------|
| Primary | #007AFF | CTAs, links, active states |
| Success | #34C759 | Client stage, positive actions |
| Warning | #FF9500 | Today's follow-ups, hot leads |
| Danger | #FF3B30 | Overdue, DND stage |
| Background | #F2F2F7 | App background (light mode) |
| Card | #FFFFFF | Prospect cards |

**Typography**:
- Primary: SF Pro (system default)
- Headers: SF Pro Bold
- Body: SF Pro Regular
- Numbers: SF Pro Rounded

**Component Library**: Native iOS components (UIKit/SwiftUI standard)

### 4.2 Navigation Structure

```
Tab Bar Navigation
├── Today (Home)
│   ├── Overdue Section
│   ├── Today Section
│   ├── Hot Leads Section
│   └── Recent Activity
├── Pipeline
│   ├── Kanban View (default)
│   └── List View (toggle)
├── Search
│   ├── Search Bar
│   └── Filter Options
├── Stats
│   ├── Overview
│   └── Detailed Metrics
└── Settings
    ├── Account
    ├── Notifications
    ├── Data & Sync
    └── About
```

### 4.3 Key Screens

#### Screen 1: Today Dashboard (Home Tab)
- **Purpose**: Immediate visibility into daily priorities
- **Key Elements**:
  - Greeting with today's date
  - Overdue count badge (prominent if > 0)
  - Today's follow-ups list
  - Hot leads section
  - Quick add FAB (floating action button)

#### Screen 2: Pipeline View
- **Purpose**: Full funnel visibility and stage management
- **Key Elements**:
  - Horizontal scrolling stage columns
  - Prospect cards with name, platform icon, days in stage
  - Stage headers with count
  - Swipe gestures for stage movement
  - Pull-to-refresh

#### Screen 3: Prospect Detail
- **Purpose**: View and edit all prospect information
- **Key Elements**:
  - Profile header (name, handle, platform)
  - Stage selector (visual pipeline)
  - Follow-up date picker
  - Notes text area (expandable)
  - Hot lead toggle
  - Activity timeline (future)
  - Action buttons (Message, Call, Delete)

#### Screen 4: Add Prospect
- **Purpose**: Quick prospect creation
- **Key Elements**:
  - Name field (auto-focus, required)
  - Platform selector (icons)
  - Handle field (optional)
  - Notes field (optional)
  - Follow-up date (optional)
  - Hot lead toggle
  - Save button

#### Screen 5: Stats Dashboard
- **Purpose**: Performance tracking
- **Key Elements**:
  - Pipeline summary (bar chart by stage)
  - Conversion funnel visualization
  - Key metrics cards
  - Time period selector

---

## 5. Deployment & Release

### 5.1 App Store Submission

| Field | Value |
|-------|-------|
| Bundle ID | com.ronnie.dmflow |
| App Name | DMFlow - DM Prospect Tracker |
| Version | 1.0.0 |
| Category | Business / Productivity |
| Price | Free (or $4.99 one-time) |
| Deployment Target | iOS 16.0+ |
| Privacy Policy | [URL TBD] |
| Support URL | [URL TBD] |

### 5.2 App Store Metadata

**Subtitle** (30 chars): Track DMs. Close Deals.

**Keywords**: dm tracker, prospect tracker, sales crm, network marketing, instagram dm, follow up, leads, pipeline, herbalife, mlm, social selling

**Description**:
```
Never lose another lead in your DMs.

DMFlow is the simple prospect tracker built for network marketers, coaches, and anyone who closes deals through direct messages.

TRACK YOUR PIPELINE
• Move prospects through your funnel: New → Engaged → Presented → Follow-Up → Client
• Swipe to change stages instantly
• Flag hot leads for priority follow-up

NEVER MISS A FOLLOW-UP
• See exactly who needs attention today
• Set follow-up reminders
• Track overdue conversations

WORKS EVERYWHERE
• Track prospects from Instagram, Facebook, SMS, WhatsApp
• No third-party integrations required
• Add prospects directly from any app via Share Sheet

SIMPLE & FAST
• Add a prospect in seconds
• Search your entire database instantly
• Works offline, syncs automatically

Built by a network marketer, for network marketers. Stop losing deals to forgotten follow-ups.
```

### 5.3 Build Configurations

| Config | Server | Logging | Analytics |
|--------|--------|---------|-----------|
| Debug | Local/Mock | Verbose | Disabled |
| Staging | CloudKit Dev | Standard | Enabled |
| Release | CloudKit Prod | Errors Only | Enabled |

### 5.4 Code Signing
- Apple Team ID: [Your Team ID]
- Provisioning: Automatic via Xcode
- Capabilities Required:
  - CloudKit
  - Push Notifications
  - App Groups (for Share Extension)
  - Sign in with Apple

---

## 6. Success Metrics

### 6.1 Product Metrics (Post-Launch)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Daily Active Users | 100+ in first month | Analytics |
| Prospects Added/User/Week | 10+ | In-app tracking |
| Follow-up Completion Rate | 80%+ | In-app tracking |
| App Store Rating | 4.5+ stars | App Store Connect |
| Retention (Day 7) | 40%+ | Analytics |
| Retention (Day 30) | 25%+ | Analytics |

### 6.2 Personal Success Metrics (Ronnie)

| Metric | Target |
|--------|--------|
| Follow-up compliance | 100% (never miss a scheduled follow-up) |
| Lead response time | < 24 hours |
| Conversion rate tracking | Visible improvement over 30 days |
| Time saved | 30+ minutes/day vs. manual tracking |

---

## 7. Timeline & Milestones

### Development Timeline (Estimated)

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Week 1 | 5 days | Project setup, data models, basic CRUD |
| Week 2 | 5 days | Pipeline view, stage management, swipe gestures |
| Week 3 | 5 days | Today dashboard, follow-up logic, notifications |
| Week 4 | 3 days | Search, filters, basic stats |
| Week 5 | 3 days | Share extension, CloudKit sync |
| Week 6 | 3 days | Polish, testing, bug fixes |
| Week 7 | 2 days | App Store assets, submission |

**Total Estimated Time**: 4-6 weeks to MVP

### Key Milestones

| Milestone | Target Date |
|-----------|-------------|
| PRD Complete | ✅ Today |
| GitHub Repo Created | Day 1 |
| Core Data Model & CRUD | Week 1 |
| Pipeline View Working | Week 2 |
| Today Dashboard Complete | Week 3 |
| Beta Testing (TestFlight) | Week 5 |
| App Store Submission | Week 6-7 |
| Public Launch | Week 7-8 |

---

## 8. GitHub Issues (Ready to Import)

These issues can be created in your GitHub repo for development tracking:

### MVP Issues

```markdown
## Issue 1: Project Setup & Architecture
- [ ] Create Xcode project with SwiftUI
- [ ] Set up SwiftData models
- [ ] Configure CloudKit container
- [ ] Set up MVVM folder structure
- [ ] Add launch screen and app icon placeholder
Labels: setup, priority-high

## Issue 2: Prospect Data Model
- [ ] Create Prospect model with all fields
- [ ] Create Platform enum
- [ ] Create FunnelStage enum
- [ ] Set up SwiftData container
- [ ] Write unit tests for model
Labels: feature, data

## Issue 3: Add Prospect Screen
- [ ] Create AddProspectView
- [ ] Name field with validation
- [ ] Platform selector
- [ ] Handle field
- [ ] Notes field
- [ ] Follow-up date picker
- [ ] Hot lead toggle
- [ ] Save functionality
Labels: feature, ui

## Issue 4: Pipeline/Kanban View
- [ ] Create PipelineView
- [ ] Stage columns with headers
- [ ] Prospect cards component
- [ ] Horizontal scroll between stages
- [ ] Swipe to change stage
- [ ] Stage count badges
Labels: feature, ui, priority-high

## Issue 5: Prospect Detail View
- [ ] Create ProspectDetailView
- [ ] Display all prospect fields
- [ ] Edit mode functionality
- [ ] Stage change interface
- [ ] Delete with confirmation
Labels: feature, ui

## Issue 6: Today Dashboard
- [ ] Create TodayView
- [ ] Overdue section with query
- [ ] Today section with query
- [ ] Hot leads section
- [ ] Recent activity section
- [ ] Quick action buttons
Labels: feature, ui, priority-high

## Issue 7: Tab Bar Navigation
- [ ] Set up TabView
- [ ] Today tab
- [ ] Pipeline tab
- [ ] Search tab
- [ ] Stats tab
- [ ] Settings tab
Labels: feature, navigation

## Issue 8: Search & Filter
- [ ] Create SearchView
- [ ] Search by name/handle
- [ ] Filter by stage
- [ ] Filter by platform
- [ ] Filter by date range
- [ ] Combine filters
Labels: feature

## Issue 9: Local Notifications
- [ ] Request notification permissions
- [ ] Schedule follow-up reminders
- [ ] Morning summary notification
- [ ] Handle notification taps
Labels: feature

## Issue 10: Share Extension
- [ ] Create Share Extension target
- [ ] Handle shared content
- [ ] Quick add form
- [ ] Save to main app database
Labels: feature, enhancement

## Issue 11: CloudKit Sync
- [ ] Configure CloudKit schema
- [ ] Implement sync logic
- [ ] Handle conflicts
- [ ] Offline support
- [ ] Sync status indicator
Labels: feature, sync

## Issue 12: Stats Dashboard
- [ ] Create StatsView
- [ ] Pipeline summary chart
- [ ] Conversion metrics
- [ ] Time-in-stage metrics
- [ ] Period selector
Labels: feature

## Issue 13: Settings Screen
- [ ] Create SettingsView
- [ ] Account section
- [ ] Notification preferences
- [ ] Data management
- [ ] About/version info
Labels: feature

## Issue 14: App Store Preparation
- [ ] Create app icon (all sizes)
- [ ] Take screenshots (all devices)
- [ ] Write App Store description
- [ ] Create privacy policy
- [ ] Prepare preview video (optional)
Labels: release

## Issue 15: Testing & Polish
- [ ] Unit tests for ViewModels
- [ ] UI tests for critical flows
- [ ] Performance testing
- [ ] Accessibility audit
- [ ] Bug fixes
Labels: testing, polish
```

---

## 9. Notes & Constraints

### Constraints
1. **Single Developer**: Scope must remain achievable for solo development
2. **No Backend Server**: Using CloudKit eliminates server costs/maintenance
3. **iOS Only for MVP**: Android can come later if there's demand
4. **No Auto-DM Features**: Staying compliant with Instagram ToS

### Dependencies
1. Apple Developer Account ($99/year) - already have for CalTrackPro
2. CloudKit container setup
3. App Store Connect access

### Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Scope creep | High | Medium | Strict MVP adherence |
| CloudKit complexity | Medium | Medium | Start with local-only, add sync later |
| App Store rejection | Low | High | Follow guidelines, have privacy policy |
| User adoption | Medium | Medium | Use personally first, iterate based on real usage |

### Open Questions
1. Pricing strategy: Free with limits? One-time purchase? Subscription?
2. App name: DMFlow, ProspectPro, FunnelDM, or something else?
3. Should Phase 1 include the Share Extension or save for Phase 2?

---

## 10. Appendix

### A. Competitive Analysis

| Feature | DMTracker.ai | DMFlow (Ours) |
|---------|--------------|---------------|
| Platform | Web | Native iOS |
| ManyChat Required | Yes | No |
| Custom Stages | Limited | Fully Custom |
| SMS/WhatsApp | No | Yes |
| Offline Mode | No | Yes |
| Price | ~$30/mo | One-time or Free |
| Setup Time | 5+ min | Instant |

### B. User Stories

1. As a network marketer, I want to add a prospect in under 10 seconds so I can stay in the flow while DMing.
2. As a user, I want to see who I need to follow up with today so I never miss an opportunity.
3. As a user, I want to swipe to move prospects through stages so tracking is effortless.
4. As a user, I want to track prospects from all platforms in one place so I have a complete picture.
5. As a user, I want my data to sync across devices so I can access it anywhere.

### C. Glossary

- **DM**: Direct Message
- **DND**: Do Not Disturb (prospect marked as dead/uninterested)
- **Hot Lead**: High-priority prospect likely to convert
- **Pipeline**: Visual representation of prospects at each funnel stage
- **Funnel**: The stages a prospect moves through from first contact to conversion
