# Testing the URL Shortening System

## Prerequisites
1. Flutter app is running (`flutter run -d windows`)
2. Feedback server is running (`dart feedback_server.dart`)

## Test Steps

### Test 1: Generate Short URL
1. Open the app and navigate to **Performance Overview** screen
2. Click **"Send Customer Feedback"** button
3. Select a customer from the dropdown
4. (Optional) Select a specific ticket
5. Click **"Generate Link"**
6. **Expected Result:** Dialog shows a short URL like:
   ```
   https://lkq8fgjg-8080.eun1.devtunnels.ms/s/a3x9k2
   ```
   (NOT the long URL with all parameters)

### Test 2: Copy Short URL
1. In the dialog, click **"Copy Link"**
2. **Expected Result:** 
   - Green snackbar: "Link copied to clipboard!"
   - Dialog closes

### Test 3: Verify Database Entry
1. Check the database (you can use a SQLite viewer)
2. Query: `SELECT * FROM short_urls ORDER BY createdAt DESC LIMIT 1;`
3. **Expected Result:** New entry with:
   - `shortCode`: 6-character code (e.g., "a3x9k2")
   - `fullUrl`: Long URL with all parameters
   - `customerId`: Customer ID
   - `ticketId`: Ticket ID (if selected)
   - `createdAt`: Current timestamp
   - `expiresAt`: 90 days from now
   - `clickCount`: 0

### Test 4: Test Short URL Redirect
1. Open browser
2. Paste the short URL: `https://lkq8fgjg-8080.eun1.devtunnels.ms/s/a3x9k2`
3. Press Enter
4. **Expected Result:**
   - Browser redirects to feedback form
   - Feedback form has all customer/ticket/device info pre-filled
   - URL bar shows the long URL with parameters

### Test 5: Verify Click Tracking
1. Query database again: `SELECT clickCount FROM short_urls WHERE shortCode = 'a3x9k2';`
2. **Expected Result:** `clickCount` increased to 1
3. Click the short URL again
4. **Expected Result:** `clickCount` increased to 2

### Test 6: Test Expired Link (Manual)
1. In database, set `expiresAt` to a past date:
   ```sql
   UPDATE short_urls 
   SET expiresAt = strftime('%s', 'now', '-1 day') * 1000 
   WHERE shortCode = 'a3x9k2';
   ```
2. Try to access the short URL
3. **Expected Result:** Page shows "Link Expired" message

### Test 7: Test Invalid Link
1. Open browser
2. Navigate to: `https://lkq8fgjg-8080.eun1.devtunnels.ms/s/invalid123`
3. **Expected Result:** Page shows "404 - Link Not Found"

### Test 8: Test Multiple Links
1. Generate 3 different feedback links for different customers
2. **Expected Result:** Each gets a unique short code
3. Verify all 3 short codes redirect to correct feedback forms

### Test 9: Share via SMS (Real-World Test)
1. Generate a short URL
2. Copy it and send via SMS to your phone
3. Click the link on mobile
4. **Expected Result:** 
   - Link is clickable
   - Redirects to feedback form
   - Form is mobile-responsive
   - All data pre-filled

### Test 10: End-to-End Workflow
1. Create a new ticket with customer and device
2. Mark ticket as completed
3. Generate short feedback link
4. Share link (copy to clipboard)
5. Open link in browser
6. Submit feedback via form
7. In app, click "Sync Feedback" button
8. **Expected Result:** New rating appears in Performance Overview

## Server Console Output

When feedback server is running and handling short URLs, you should see:

```
Starting Driven Repairs Feedback Server...
Database initialized
Server running on http://0.0.0.0:8080
Redirecting a3x9k2 to https://lkq8fgjg-8080.eun1.devtunnels.ms/feedback_form.html?... (click #1)
Redirecting a3x9k2 to https://lkq8fgjg-8080.eun1.devtunnels.ms/feedback_form.html?... (click #2)
```

## Troubleshooting

### Issue: Short URL not created
- Check Flutter console for errors
- Verify ShortUrlProvider is registered in main.dart
- Ensure database upgraded to version 4

### Issue: 404 on short URL
- Verify feedback server is running
- Check server console for errors
- Verify database has the short_urls table

### Issue: Redirect not working
- Check feedback_server.dart has `/s/<shortCode>` route
- Verify database connection in server
- Check browser network tab for redirect response

### Issue: Link expires immediately
- Check system date/time is correct
- Verify `expiresAt` calculation in provider (should be 90 days in future)

## Success Criteria ✅

- [ ] Short URLs are generated (6 characters)
- [ ] Long URLs are NOT shown to users
- [ ] Short URLs redirect correctly
- [ ] All customer/ticket/device data is pre-filled after redirect
- [ ] Click counts increment
- [ ] Expired links show error message
- [ ] Invalid links show 404
- [ ] Database entries created correctly
- [ ] Links work on mobile devices
- [ ] Professional appearance (short, clean URLs)
