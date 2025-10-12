# 🚀 Quick Start: Test Data Generation

## ⚡ Fast Commands

### Preview Test Users (No Firebase Required)
```bash
# Preview 20 users per city
dart scripts/generate_test_users.dart preview all 20

# Preview specific city
dart scripts/generate_test_users.dart preview atlanta 10
dart scripts/generate_test_users.dart preview miami 15
dart scripts/generate_test_users.dart preview houston 25

# View statistics
dart scripts/generate_test_users.dart stats all 20
```

### What You'll Get

**📊 60 Test Users (20 per city):**
- **👨 30 Males** - Ages 22-45, diverse backgrounds
- **👩 30 Females** - Ages 22-45, diverse backgrounds
- **🏙️ 3 Cities** - Atlanta, Miami, Houston

**✅ Complete Profiles:**
- Realistic names (James Smith, Jennifer Garcia, etc.)
- Valid email addresses (`test_atlanta_male_1234@test.com`)
- Geographic coordinates within city limits
- 3-8 diverse interests per user
- Profile bios and occupations
- Age-appropriate preferences

---

## 📋 Example Output

```
🏙️ Atlanta, GA (33.749, -84.388)
================================

👨 Male Users (10):
   1. James Smith (28) - Software Engineer
      📧 test_atlanta_male_1234@test.com
      📍 (33.7490, -84.3880)
      🎯 Technology, Travel, Photography
      💬 "Passionate about technology and travel. Let's connect!"
      
   2. Michael Johnson (32) - Marketing Manager
      📧 test_atlanta_male_5678@test.com
      📍 (33.7550, -84.3920)
      🎯 Music, Fitness, Food
      💬 "Love music and staying fit. Looking to meet new people!"
```

---

## 🎯 Testing Scenarios

### **Match Algorithm Testing**
Use these users to test:
- ✅ Geographic matching (within city)
- ✅ Age preference filtering
- ✅ Interest-based compatibility
- ✅ Gender preference matching

### **Discovery Feed Testing**
- ✅ User card display
- ✅ Profile photo loading
- ✅ Swipe interactions
- ✅ Match notifications

### **Messaging Testing**
- ✅ Chat conversations
- ✅ Message delivery
- ✅ Real-time updates
- ✅ Notification system

---

## 💡 Next Steps

### **1. Preview Your Test Data**
```bash
dart scripts/generate_test_users.dart preview all 20
```

### **2. Review the Profiles**
Check that names, ages, locations, and interests look realistic.

### **3. Create Users in Firebase**
Use one of these methods:

**Option A: Flutter Admin Panel**
1. Navigate to Admin → Test Data Management
2. Click "Generate All" or select specific cities
3. Wait for users to be created

**Option B: Backend Script** (Future Implementation)
```bash
# When implemented
firebase functions:shell
testDataGenerator.generateAll({count: 20})
```

**Option C: Manual Testing**
Use the preview data as a reference for manual user creation.

---

## 🔧 Customization

### **Adjust User Count**
```bash
# Generate more users per city
dart scripts/generate_test_users.dart preview all 30  # 30 per city = 90 total

# Generate fewer for quick testing
dart scripts/generate_test_users.dart preview all 6   # 6 per city = 18 total
```

### **City-Specific Testing**
```bash
# Focus on one city
dart scripts/generate_test_users.dart preview atlanta 50

# Multiple cities with different counts
dart scripts/generate_test_users.dart preview atlanta 30
dart scripts/generate_test_users.dart preview miami 20
```

---

## 📊 Test Data Features

### **Realistic Demographics**
- **Names**: Common American names (diverse backgrounds)
- **Ages**: 22-45 (primary dating app demographic)
- **Locations**: Actual city coordinates with realistic variation
- **Occupations**: 20+ professional careers

### **Diverse Interests**
Travel, Photography, Music, Cooking, Fitness, Reading, Movies, Dancing,
Sports, Art, Technology, Fashion, Food, Adventure, Yoga, Gaming, Hiking,
Coffee, Wine, Volunteering, Languages, Business, Education

### **Complete Profiles**
- ✅ Profile bio (interest-based, engaging)
- ✅ Photos (2-4 per user)
- ✅ Preferences (age range, distance, gender)
- ✅ Education and occupation
- ✅ Last active timestamp

---

## 🎉 You're Ready to Test!

Your dating app now has comprehensive, realistic test data ready to go.

**🚀 Start Testing:**
1. **Run the preview** - See what users will be created
2. **Generate in Firebase** - Create actual user accounts
3. **Test features** - Match algorithm, discovery, messaging
4. **Monitor performance** - App behavior with realistic data

**💡 Pro Tip:** Start with 6-10 users per city for initial testing,
then scale up to 20+ for performance and load testing.

---

## 📚 More Information

- **Full Testing Guide**: See `TESTING_GUIDE.md`
- **Implementation Details**: See `lib/services/test_data_generator_service.dart`
- **Admin UI**: See `lib/features/admin/test_data_management_screen.dart`

Happy Testing! 🎯
