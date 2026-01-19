/**
 * Test user creation Cloud Function handlers
 * Used for development and testing purposes
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

interface CreateTestUsersRequest {
  count?: number; // Total users to create (default: 60)
  cities?: Array<{name: string; lat: number; lng: number; key: string}>;
}

interface CreateTestUsersResponse {
  success: boolean;
  created: number;
  failed: number;
  userIds?: string[]; // Optional - can be omitted for large batches
  message: string;
}

// Maximum users per request (prevent quota exhaustion)
const MAX_USERS_PER_REQUEST = 500;
const MIN_USERS_PER_REQUEST = 1;
const DEFAULT_BATCH_SIZE = 10; // Users to create in parallel

export class TestUserHandlers {
  // Test data constants
  private readonly maleNames = [
    'James', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas',
    'Christopher', 'Charles', 'Daniel', 'Matthew', 'Anthony', 'Mark', 'Donald',
    'Steven', 'Paul', 'Andrew', 'Joshua', 'Kenneth', 'Kevin',
  ];

  private readonly femaleNames = [
    'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan',
    'Jessica', 'Sarah', 'Karen', 'Nancy', 'Lisa', 'Betty', 'Helen', 'Sandra',
    'Donna', 'Carol', 'Ruth', 'Sharon', 'Michelle',
  ];

  private readonly lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson',
    'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
  ];

  private readonly interests = [
    'Travel', 'Photography', 'Music', 'Cooking', 'Fitness', 'Reading', 'Movies',
    'Dancing', 'Sports', 'Art', 'Technology', 'Fashion', 'Food', 'Adventure',
    'Yoga', 'Gaming', 'Hiking', 'Coffee', 'Wine', 'Volunteering', 'Languages',
    'Business', 'Education',
  ];

  private readonly occupations = [
    'Software Engineer', 'Marketing Manager', 'Teacher', 'Doctor', 'Lawyer',
    'Artist', 'Entrepreneur', 'Sales Representative', 'Designer', 'Consultant',
    'Nurse', 'Accountant', 'Chef', 'Photographer', 'Writer', 'Engineer',
    'Business Analyst', 'Project Manager', 'Real Estate Agent', 'Therapist',
  ];

  private readonly educationLevels = [
    'High School',
    'Some College',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
  ];

  /**
   * Create test users for development/testing
   * Requires admin secret token in Authorization header for security
   */
  createTestUsers = functions.runWith({
    timeoutSeconds: 540, // Max timeout (9 minutes) for large batches
  }).https.onRequest(async (req: functions.https.Request, res: functions.Response): Promise<void> => {
      try {
        // 1. Authentication check
        const authHeader = req.headers.authorization;
        // Read from Firebase Functions config (set via firebase functions:config:set)
        // Falls back to environment variable, then default dev secret
        const adminSecret = functions.config().admin?.secret || 
                           process.env.ADMIN_SECRET || 
                           'dev-secret-change-in-production';
        
        if (!authHeader || authHeader !== `Bearer ${adminSecret}`) {
          res.status(401).json({
            success: false,
            message: 'Unauthorized. Provide valid admin secret in Authorization header.',
          });
          return;
        }

        // 2. Input validation
        const data: CreateTestUsersRequest = req.body || {};
        const requestedCount = data.count || 60;
        const validatedCount = Math.min(
          Math.max(MIN_USERS_PER_REQUEST, requestedCount),
          MAX_USERS_PER_REQUEST
        );

        if (requestedCount !== validatedCount) {
          console.warn(`⚠️  Count adjusted from ${requestedCount} to ${validatedCount}`);
        }

        // Validate cities if provided
        const cities = data.cities || [
          {name: 'Atlanta, GA', lat: 33.7490, lng: -84.3880, key: 'atlanta'},
          {name: 'Miami, FL', lat: 25.7617, lng: -80.1918, key: 'miami'},
          {name: 'Houston, TX', lat: 29.7604, lng: -95.3698, key: 'houston'},
        ];

        if (cities.length === 0) {
          res.status(400).json({
            success: false,
            message: 'At least one city is required',
          });
          return;
        }

        console.log(`🚀 Creating ${validatedCount} test users across ${cities.length} cities...`);

        // 3. Generate unique request ID for this batch
        const requestId = crypto.randomBytes(4).toString('hex');

        // 4. Calculate distribution
        const usersPerCity = Math.floor(validatedCount / cities.length);
        const usersPerGender = Math.floor(usersPerCity / 2);

        const created: string[] = [];
        const errors: string[] = [];
        let failed = 0;

        // 5. Process cities in parallel, users in batches
        for (const city of cities) {
          console.log(`🏙️  Creating users for ${city.name}...`);

          // Create male users in batches
          const maleResults = await this.createUsersInBatches(
            'male',
            city,
            usersPerGender,
            requestId,
            DEFAULT_BATCH_SIZE
          );
          created.push(...maleResults.created);
          errors.push(...maleResults.errors);
          failed += maleResults.failed;

          // Create female users in batches
          const femaleResults = await this.createUsersInBatches(
            'female',
            city,
            usersPerGender,
            requestId,
            DEFAULT_BATCH_SIZE
          );
          created.push(...femaleResults.created);
          errors.push(...femaleResults.errors);
          failed += femaleResults.failed;
        }

        const message = `Successfully created ${created.length} test users${failed > 0 ? ` (${failed} failed)` : ''}`;
        console.log(`✅ ${message}`);

        // Only include userIds for smaller batches to avoid large response
        const result: CreateTestUsersResponse = {
          success: true,
          created: created.length,
          failed,
          userIds: created.length <= 100 ? created : undefined,
          message,
        };

        res.status(200).json(result);

      } catch (error: any) {
        console.error('❌ Fatal error in createTestUsers:', error);
        await this.logError('createTestUsers', error, {requestBody: req.body});
        res.status(500).json({
          success: false,
          message: 'Internal server error',
          created: 0,
          failed: 0,
        });
      }
    }
  );

  /**
   * Create users in parallel batches with error handling
   */
  private async createUsersInBatches(
    gender: 'male' | 'female',
    city: {name: string; lat: number; lng: number; key: string},
    count: number,
    requestId: string,
    batchSize: number
  ): Promise<{created: string[]; failed: number; errors: string[]}> {
    const created: string[] = [];
    const errors: string[] = [];
    let failed = 0;

    for (let i = 0; i < count; i += batchSize) {
      const currentBatchSize = Math.min(batchSize, count - i);
      const batchPromises = Array.from({length: currentBatchSize}, (_, j) =>
        this.createTestUser(gender, city, i + j, requestId)
          .then(uid => ({success: true, uid, index: i + j}))
          .catch(error => ({success: false, error, index: i + j}))
      );

      const results = await Promise.allSettled(batchPromises);
      
      for (const result of results) {
        if (result.status === 'fulfilled') {
          const value = result.value;
          if (value.success && 'uid' in value) {
            created.push(value.uid);
          } else if (!value.success && 'error' in value) {
            failed++;
            const errorMsg = value.error instanceof Error ? value.error.message : String(value.error);
            errors.push(`${gender} user ${value.index} in ${city.name}: ${errorMsg}`);
          }
        } else {
          failed++;
          errors.push(`${gender} user batch failed: ${result.reason}`);
        }
      }

      // Small delay between batches to avoid overwhelming Firebase
      if (i + batchSize < count) {
        await this.delay(200);
      }
    }

    return {created, failed, errors};
  }

  /**
   * Create a single test user with proper error handling
   */
  private async createTestUser(
    gender: 'male' | 'female',
    city: {name: string; lat: number; lng: number; key: string},
    index: number,
    requestId: string
  ): Promise<string> {
    // Use crypto for better randomness and unique IDs
    const uniqueId = crypto.randomBytes(4).toString('hex');
    const random = Math.random();
    
    // Generate unique email using request ID and unique ID
    const email = `test_${city.key}_${gender}_${requestId}_${uniqueId}@test.com`;
    
    // Generate user data with improved random selection
    const firstName = gender === 'male'
      ? this.maleNames[Math.floor(random * this.maleNames.length)]
      : this.femaleNames[Math.floor(random * this.femaleNames.length)];
    const lastName = this.lastNames[Math.floor(random * this.lastNames.length)];
    const age = 22 + Math.floor(random * 24); // 22-45
    const birthDate = new Date();
    birthDate.setFullYear(birthDate.getFullYear() - age);

    // Generate interests using shuffle approach (cleaner)
    const interestCount = 3 + Math.floor(random * 6); // 3-9 interests
    const shuffledInterests = [...this.interests].sort(() => Math.random() - 0.5);
    const userInterests = shuffledInterests.slice(0, Math.min(interestCount, this.interests.length));

    const occupation = this.occupations[Math.floor(random * this.occupations.length)];
    const education = this.educationLevels[Math.floor(random * this.educationLevels.length)];

    // Generate location with slight randomization
    const locationRandom = Math.random();
    const lat = city.lat + (locationRandom - 0.5) * 0.1;
    const lng = city.lng + (locationRandom - 0.5) * 0.1;

    // Generate bio
    const bio = this.generateBio(userInterests, occupation, random);
    
    // Generate photos
    const photoCount = 2 + Math.floor(random * 3);
    const photos = Array.from({length: photoCount}, (_, i) => 
      `https://via.placeholder.com/400x600/4A90E2/FFFFFF?text=${gender === 'male' ? 'M' : 'F'}+${i + 1}`
    );

    let userRecord: admin.auth.UserRecord | null = null;

    try {
      // Create Firebase Auth user
      userRecord = await admin.auth().createUser({
        email,
        password: 'testpassword123',
        displayName: `${firstName} ${lastName}`,
      });

      // Create Firestore document
      const userData = {
        name: `${firstName} ${lastName}`,
        email,
        age,
        birthDate: admin.firestore.Timestamp.fromDate(birthDate),
        gender,
        location: new admin.firestore.GeoPoint(lat, lng),
        city: city.name,
        cityKey: city.key,
        interests: userInterests,
        occupation,
        education,
        bio,
        isTestUser: true,
        testUserType: 'dating_app_test',
        profileCompleted: true,
        photos,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        preferences: {
          ageRange: {
            min: age - 3,
            max: age + 5,
          },
          maxDistance: 50,
          interestedIn: gender === 'male' ? ['female'] : ['male'],
        },
      };

      await admin.firestore().collection('users').doc(userRecord.uid).set(userData);

      return userRecord.uid;
    } catch (error: any) {
      // Clean up orphaned Auth user if Firestore write failed
      if (userRecord?.uid) {
        try {
          await admin.auth().deleteUser(userRecord.uid);
        } catch (deleteError) {
          console.error(`Failed to cleanup orphaned Auth user ${userRecord.uid}:`, deleteError);
        }
      }
      throw error;
    }
  }

  /**
   * Generate a random bio based on interests and occupation
   */
  private generateBio(interests: string[], occupation: string, random: number): string {
    const bios = [
      `Loving life in my city! ${occupation} by day, ${interests[0].toLowerCase()} enthusiast by night. Looking for someone to share adventures with!`,
      `Passionate about ${interests.slice(0, 2).join(' and ').toLowerCase()}. Looking for genuine connections and fun times.`,
      `Living my best life! Love ${interests[0].toLowerCase()}, ${interests.length > 1 ? interests[1].toLowerCase() : 'good conversation'}, and meeting new people.`,
      `Adventure seeker and ${interests[0].toLowerCase()} lover. ${occupation} who believes in work-life balance. Let's explore together!`,
      `Positive vibes only! Enjoy ${interests.slice(0, 3).join(', ').toLowerCase()}. Looking for genuine connections and fun times.`,
    ];
    return bios[Math.floor(random * bios.length)];
  }

  /**
   * Log errors to Firestore for monitoring (consistent with other handlers)
   */
  private async logError(operation: string, error: Error, context: any): Promise<void> {
    try {
      await admin.firestore().collection('errorLogs').add({
        operation,
        error: error.message,
        stack: error.stack,
        context,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (logError) {
      console.error('Failed to log error to Firestore:', logError);
    }
  }

  /**
   * Delay helper for rate limiting
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
