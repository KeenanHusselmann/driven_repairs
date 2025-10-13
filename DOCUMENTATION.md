# Driven Repairs Management System - Documentation

## Table of Contents
1. [URL Shortening System](#url-shortening-system)
2. [Testing Procedures](#testing-procedures)
3. [Git Workflow](#git-workflow)
4. [Review Checklist](#review-checklist)

---

## URL Shortening System

### Overview
The URL shortening system converts long feedback form URLs into short, shareable links that are mobile-friendly and trackable.

### Comparison: Before & After

#### BEFORE (Long URL) ❌
```
https://lkq8fgjg-8080.eun1.devtunnels.ms/feedback_form.html?ticket=c7f4e2d1-8a3b-4c9e-b1d5-6f8a9c2e4b7d&customer=a9b8c7d6-e5f4-3a2b-1c0d-9e8f7a6b5c4d&name=John%20Doe&email=john.doe%40example.com&phone=555-123-4567&date=October%2013%2C%202025&technician=Jane%20Smith&ticketTitle=Laptop%20Screen%20Repair&ticketStatus=Completed&ticketPriority=High&deviceBrand=Dell&deviceModel=XPS%2015&deviceType=Laptop&deviceSerial=DELL-XPS-2024-001
```

**Character Count:** 432 characters  
**User Experience:** Difficult to read, copy, share  
**Mobile-Friendly:** No - breaks on SMS/WhatsApp  
**Trackable:** No  
**Expirable:** No  

#### AFTER (Short URL) ✅
```
https://lkq8fgjg-8080.eun1.devtunnels.ms/s/a3x9k2
```

**Character Count:** 53 characters  
**User Experience:** Clean, professional, memorable  
**Mobile-Friendly:** Yes - perfect for SMS/WhatsApp  
**Trackable:** Yes - click count tracked  
**Expirable:** Yes - 90 day expiration  

### Technical Implementation

#### Database Schema (Version 4)
```sql
CREATE TABLE short_urls (
  id TEXT PRIMARY KEY,
  shortCode TEXT UNIQUE NOT NULL,
  fullUrl TEXT NOT NULL,
  ticketId TEXT,
  customerId TEXT,
  clicks INTEGER DEFAULT 0,
  expiresAt INTEGER NOT NULL,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  FOREIGN KEY (ticketId) REFERENCES repair_tickets(id) ON DELETE SET NULL,
  FOREIGN KEY (customerId) REFERENCES customers(id) ON DELETE SET NULL
);

CREATE UNIQUE INDEX idx_short_urls_short_code ON short_urls(shortCode);
CREATE INDEX idx_short_urls_ticket_id ON short_urls(ticketId);
CREATE INDEX idx_short_urls_customer_id ON short_urls(customerId);
```

#### Short Code Generation
- **Length:** 6 characters
- **Characters:** a-z, 0-9 (36 possible characters per position)
- **Total Combinations:** 36^6 = 2,176,782,336 possible codes
- **Collision Handling:** Random regeneration if collision detected

#### Features
- ✅ **90-day expiration** - Links automatically expire after 90 days
- ✅ **Click tracking** - Every redirect increments click counter
- ✅ **Customer/Ticket linking** - Links associated with specific customers and tickets
- ✅ **Server redirect** - `/s/<shortCode>` → full URL with 301 redirect
- ✅ **Database persistence** - All short URLs stored in SQLite

### API Endpoints

#### Create Short URL
```dart
final shortUrlProvider = context.read<ShortUrlProvider>();
final shortUrl = await shortUrlProvider.createShortUrl(
  fullUrl: 'https://example.com/feedback_form.html?...',
  ticketId: 'ticket-123',
  customerId: 'customer-456',
  expiresAt: DateTime.now().add(Duration(days: 90)),
);
```

#### Redirect Short URL
```
GET /s/<shortCode>
→ 301 Redirect to full URL
→ Increments click count
```

### Usage in Application
1. Navigate to Performance Overview screen
2. Click "Send Customer Feedback" button
3. Select customer (and optionally a specific ticket)
4. Click "Generate Link"
5. Short URL is created and displayed
6. Copy link and send via email, SMS, or WhatsApp

---

## Testing Procedures

### Prerequisites
1. Flutter app running: `flutter run -d windows`
2. Feedback server running: `dart feedback_server.dart`

### Test 1: Generate Short URL
1. Open Performance Overview screen
2. Click **"Send Customer Feedback"** button
3. Select a customer from dropdown
4. (Optional) Select a specific ticket
5. Click **"Generate Link"**
6. **Expected:** Dialog shows short URL like `https://lkq8fgjg-8080.eun1.devtunnels.ms/s/a3x9k2`
7. **Verify:** URL is short (not long with all parameters)

### Test 2: Redirect Functionality
1. Copy the short URL from previous test
2. Paste into browser address bar
3. Press Enter
4. **Expected:** Browser redirects to feedback form with all parameters
5. **Verify:** All customer/ticket/device data is pre-filled in form

### Test 3: Click Tracking
1. Visit the same short URL multiple times
2. Check database (or admin panel if available)
3. **Expected:** Click count increases with each visit
4. **Verify:** Counter increments correctly

### Test 4: Link Expiration
1. Create a short URL with near-expiration date (for testing)
2. Wait for expiration time
3. Try to visit the expired link
4. **Expected:** Error message or redirect to expired page
5. **Verify:** Expired links don't work

### Test 5: Complete Integrated Workflow
1. Submit feedback via web form
2. Click "Sync Feedback" button in app
3. **Verify:** Performance metrics update
4. Create device with customer selection
5. Create ticket with customer/device dropdowns
6. Mark ticket as completed
7. **Verify:** Feedback link dialog appears automatically
8. Generate short feedback link
9. Open link in browser
10. **Verify:** All information displays correctly on feedback form

---

## Git Workflow

### Repository Information
- **GitHub URL:** https://github.com/KeenanHusselmann/driven_repairs.git
- **Branch:** main
- **Initial Commit:** 2532dcd - "Initial commit: Driven Repairs Management System with URL shortening"

### Quick Commands (PowerShell)
```powershell
# Check status
git status

# Add all changes
git add .

# Commit with message
git commit -m "Your commit message"

# Push to GitHub
git push origin main

# Pull latest changes
git pull origin main

# View commit history
git log --oneline

# Create new branch
git checkout -b feature/new-feature

# Switch branches
git checkout main
```

### Commit Message Guidelines
- **feat:** New feature (e.g., "feat: add URL shortening system")
- **fix:** Bug fix (e.g., "fix: resolve feedback form submission issue")
- **docs:** Documentation changes (e.g., "docs: update README")
- **style:** Code style changes (e.g., "style: format code")
- **refactor:** Code refactoring (e.g., "refactor: simplify ticket creation")
- **test:** Test additions/changes (e.g., "test: add unit tests for ShortUrlProvider")
- **chore:** Maintenance tasks (e.g., "chore: update dependencies")

### Workflow Options

#### Option 1: Simple Push (No Branching)
```powershell
git add .
git commit -m "feat: add new feature"
git push origin main
```

#### Option 2: Feature Branch Workflow
```powershell
# Create feature branch
git checkout -b feature/url-shortening

# Make changes and commit
git add .
git commit -m "feat: implement URL shortening"

# Push feature branch
git push origin feature/url-shortening

# Merge to main (via GitHub PR or locally)
git checkout main
git merge feature/url-shortening
git push origin main
```

#### Option 3: Commit Often, Push Later
```powershell
# Multiple small commits
git add .
git commit -m "feat: add ShortUrl model"

git add .
git commit -m "feat: add ShortUrlProvider"

git add .
git commit -m "feat: integrate short URLs in UI"

# Push all commits at once
git push origin main
```

---

## Review Checklist

### Code Quality
- [ ] All compile errors fixed
- [ ] No lint warnings (or documented exceptions)
- [ ] Code follows Dart/Flutter style guidelines
- [ ] Proper error handling implemented
- [ ] Loading states handled appropriately

### Functionality
- [ ] All features working as expected
- [ ] Database migrations successful
- [ ] URL shortening system operational
- [ ] Feedback form submission working
- [ ] Feedback sync working
- [ ] Customer/device/ticket creation working
- [ ] Auto-ticket numbering working (NA-DDMMYY###)
- [ ] Dashboard metrics showing real-time data

### User Interface
- [ ] Responsive design working
- [ ] Material 3 design implemented
- [ ] Watermark logo displaying correctly
- [ ] Navigation working smoothly
- [ ] Dialogs and forms user-friendly
- [ ] Error messages clear and helpful

### Performance
- [ ] App launches quickly
- [ ] No memory leaks
- [ ] Database queries optimized
- [ ] Large lists use lazy loading
- [ ] Images optimized

### Testing
- [ ] Manual testing completed
- [ ] Edge cases tested
- [ ] Error scenarios handled
- [ ] Cross-platform compatibility (Windows)

### Documentation
- [ ] README.md updated
- [ ] Code comments added where necessary
- [ ] API documentation complete
- [ ] User guide created (if applicable)

### Deployment
- [ ] Release build successful
- [ ] App icon configured
- [ ] Version number updated
- [ ] Changelog created

### Git & Repository
- [ ] All changes committed
- [ ] Meaningful commit messages
- [ ] Code pushed to GitHub
- [ ] .gitignore properly configured
- [ ] No sensitive data in repository

---

## Additional Resources

### File Structure
```
driven_repairs_fresh/
├── lib/
│   ├── main.dart
│   ├── models/          # Data models
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   └── services/        # Business logic
├── assets/
│   └── images/          # App assets
├── web_feedback/
│   └── feedback_form.html
├── feedback_storage/    # Feedback JSON files
├── windows/             # Windows platform files
├── pubspec.yaml         # Dependencies
├── README.md
└── DOCUMENTATION.md     # This file
```

### Key Files
- **feedback_server.dart** - Standalone Dart server for feedback form
- **lib/models/short_url.dart** - ShortUrl model
- **lib/providers/short_url_provider.dart** - ShortUrl state management
- **lib/services/database_service.dart** - SQLite database (version 5)
- **lib/screens/performance_overview_screen.dart** - Feedback link generation

### Database Versions
- **Version 1-3:** Initial schema
- **Version 4:** Added short_urls table
- **Version 5:** Added createdBy column to repair_tickets table

### Contact
For questions or issues, contact the development team or refer to the GitHub repository issues section.

---

**Last Updated:** October 13, 2025
