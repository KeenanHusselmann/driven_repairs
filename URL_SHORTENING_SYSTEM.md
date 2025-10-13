# URL Shortening System for Feedback Links

## Overview
The feedback link system now uses short, user-friendly URLs instead of long URLs with many parameters.

## How It Works

### 1. **Database Schema** (Version 4)
- Added `short_urls` table with fields:
  - `id`: Unique identifier
  - `shortCode`: 6-character random code (e.g., "a3x9k2")
  - `fullUrl`: Original long feedback URL with all parameters
  - `ticketId`: Associated ticket (optional)
  - `customerId`: Associated customer
  - `createdAt`: Creation timestamp
  - `expiresAt`: Expiration date (90 days by default)
  - `clickCount`: Track how many times the link is used

### 2. **Short URL Generation**
- When generating a feedback link, the system:
  1. Builds the full URL with all customer/ticket/device parameters
  2. Creates a 6-character random code (letters + numbers)
  3. Stores the mapping in the database
  4. Returns the short URL: `https://lkq8fgjg-8080.eun1.devtunnels.ms/s/a3x9k2`

### 3. **URL Redirection**
- The feedback server handles `/s/<shortCode>` routes
- When a short URL is accessed:
  1. Looks up the shortCode in the database
  2. Checks if the link has expired
  3. Increments the click count
  4. Redirects to the full feedback form URL with all parameters
  5. Returns 404 if link not found or expired

### 4. **Benefits**
- ✅ **User-Friendly**: Short, memorable links (e.g., `/s/a3x9k2` instead of 300+ character URLs)
- ✅ **Trackable**: Know how many times each link was clicked
- ✅ **Expirable**: Links automatically expire after 90 days
- ✅ **Secure**: Random codes are hard to guess
- ✅ **Mobile-Friendly**: Easy to share via SMS, WhatsApp, email

### 5. **Example URLs**

**Before (Long URL):**
```
https://lkq8fgjg-8080.eun1.devtunnels.ms/feedback_form.html?ticket=abc123&customer=xyz789&name=John%20Doe&email=john@example.com&phone=555-1234&date=October%2013%2C%202025&technician=Jane%20Smith&ticketTitle=Laptop%20Repair&ticketStatus=Completed&ticketPriority=High&deviceBrand=Dell&deviceModel=XPS%2015&deviceType=Laptop&deviceSerial=SN123456
```

**After (Short URL):**
```
https://lkq8fgjg-8080.eun1.devtunnels.ms/s/a3x9k2
```

## Files Modified/Created

### New Files:
1. `lib/models/short_url.dart` - ShortUrl model
2. `lib/providers/short_url_provider.dart` - Provider for managing short URLs

### Modified Files:
1. `lib/services/database_service.dart` - Updated to version 4, added short_urls table
2. `lib/screens/performance_overview_screen.dart` - Creates short URLs when generating feedback links
3. `lib/main.dart` - Added ShortUrlProvider to MultiProvider
4. `lib/providers/providers.dart` - Exported ShortUrlProvider
5. `feedback_server.dart` - Added `/s/<shortCode>` redirect handler

## Usage in Performance Overview Screen

When you click "Generate Link" for a customer:
1. System creates the full feedback URL with all parameters
2. Automatically generates a short code (e.g., "a3x9k2")
3. Stores the mapping in the database
4. Shows the short URL in the dialog: `https://lkq8fgjg-8080.eun1.devtunnels.ms/s/a3x9k2`
5. You copy and send this short, friendly link to the customer
6. When customer clicks it, they're redirected to the full feedback form with all their info pre-filled

## Expiration & Tracking

- Links expire after **90 days** by default
- Each click is tracked in the `clickCount` field
- Expired links return a "Link Expired" page
- Admin can view all short URLs and their statistics

## Security Notes

- Short codes are 6 characters (36^6 = 2.1 billion combinations)
- Codes are randomly generated to prevent guessing
- Links are tied to specific customers and tickets
- Expired links cannot be used
- Click tracking helps detect suspicious activity
