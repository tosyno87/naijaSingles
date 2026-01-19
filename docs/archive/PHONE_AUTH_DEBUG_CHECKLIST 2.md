# 🔍 Phone Auth Debug Checklist

## Step-by-Step Debugging

### 1. **Check Console Logs** ⚠️ CRITICAL

When you click "Continue", you should see these logs:

```
═══════════════════════════════════════════════════════
📱 PHONE AUTH REQUEST
═══════════════════════════════════════════════════════
Country Code: +234
User Input: 800 000 0000
Cleaned Input: 8000000000
Full Number (sent to Firebase): +2348000000000
💡 COPY THIS EXACT NUMBER to Firebase Console test numbers:
   +2348000000000
═══════════════════════════════════════════════════════
```

**If you DON'T see these logs:**
- ❌ The button click isn't triggering the event
- ❌ Check if button is disabled (should be green when valid)
- ❌ Check console for any errors before this

---

### 2. **Verify Firebase Console Format**

**Firebase Console shows formatted numbers:**
- UI might show: `+234 800 000 0000` or `+234-800-000-0000`

**But Firebase stores them as:**
- Internal format: `+2348000000000` (no spaces, no dashes)

**Solution:**
1. In Firebase Console, you can add numbers WITH or WITHOUT spaces/dashes
2. Firebase will normalize them internally
3. But to be safe, **add the number EXACTLY as shown in console logs**
4. Copy the exact number from logs: `+2348000000000`
5. Paste it in Firebase Console test numbers (with or without spaces - Firebase handles it)

---

### 3. **Test with Known Good Number**

Try this guaranteed-to-work setup:

**Firebase Console:**
- Phone: `+16505553434` (or `+1 650-555-3434` - both work)
- Code: `123456`

**In Your App:**
- Select country code: `+1` (USA)
- Enter phone: `6505553434`
- Click Continue
- **Check console logs** - should show: `+16505553434`
- Enter code: `123456`
- Should work! ✅

---

### 4. **What to Check in Console Logs**

After clicking "Continue", look for:

**✅ Success Path:**
```
📱 PHONE AUTH REQUEST
Full Number (sent to Firebase): +2348000000000
🔥 FIREBASE PHONE AUTH CALLED
✅ VERIFICATION CODE SENT!
```

**❌ Error Path:**
```
📱 PHONE AUTH REQUEST
Full Number (sent to Firebase): +2348000000000
🔥 FIREBASE PHONE AUTH CALLED
❌ PHONE AUTH ERROR
Error: invalid-phone-number: ...
```

---

### 5. **Common Issues**

| Issue | Solution |
|-------|----------|
| **No logs appear** | Button not working / event not firing - check button state |
| **invalid-phone-number** | Number format wrong - check console for exact format sent |
| **missing-verification-code** | Test number not in Firebase Console - add it |
| **invalid-verification-code** | Wrong code entered - use code from Firebase Console |
| **Nothing happens** | Check if button is disabled (gray = disabled, green = enabled) |

---

### 6. **Quick Test**

1. **Open app** → Go to "Sign Up with Phone"
2. **Enter:** `6505553434` with country code `+1`
3. **Click Continue** (button should be green)
4. **Check console** - you should see logs
5. **If logs appear but error:** Check the exact number format in logs
6. **Add that exact number** to Firebase Console test numbers
7. **Set code:** `123456`
8. **Try again** - should work!

---

## 🚨 Still Not Working?

**Share these details:**
1. Do you see the "📱 PHONE AUTH REQUEST" logs when clicking Continue?
2. What exact phone number appears in the logs?
3. What error message (if any) appears in logs?
4. Is the "Continue" button green/enabled when you click it?

This will help identify the exact issue!

