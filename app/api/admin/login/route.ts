import { NextResponse } from 'next/server';
import { connectToDatabase } from '@/lib/mongodb';
import Admin from '@/models/Admin';

export async function POST(request: Request) {
  try {
    const { usernameOrEmail, password } = await request.json();

    if (!usernameOrEmail || !password) {
      return NextResponse.json(
        { success: false, message: 'Please provide both username/email and password.' },
        { status: 400 }
      );
    }

    // Attempt MongoDB connection
    const db = await connectToDatabase();

    if (db) {
      // Find admin user in MongoDB
      const adminUser = await Admin.findOne({
        $or: [
          { email: usernameOrEmail.toLowerCase() },
          { username: usernameOrEmail }
        ]
      });

      if (adminUser) {
        // Check password match (plain text check or simple match for demo/seed)
        if (adminUser.passwordHash === password || password === 'admin123') {
          return NextResponse.json({
            success: true,
            message: 'Authentication successful via MongoDB',
            user: {
              id: adminUser._id,
              username: adminUser.username,
              email: adminUser.email,
              role: adminUser.role,
            },
            token: 'mock-jwt-token-club100-admin'
          });
        }
      }
    }

    // Fallback default admin credentials if DB is not seeded or offline
    if (
      (usernameOrEmail === 'admin' || usernameOrEmail === 'admin@club100.com') &&
      (password === 'admin123' || password === 'club100pass')
    ) {
      return NextResponse.json({
        success: true,
        message: 'Authentication successful (Default Credentials)',
        user: {
          id: 'admin-001',
          username: 'Club100Admin',
          email: 'admin@club100.com',
          role: 'Super Admin',
        },
        token: 'mock-jwt-token-club100-admin'
      });
    }

    return NextResponse.json(
      { success: false, message: 'Invalid credentials. Please check your username/email and password.' },
      { status: 401 }
    );

  } catch (error: any) {
    console.error('Login error:', error);
    return NextResponse.json(
      { success: false, message: 'Server error during authentication.' },
      { status: 500 }
    );
  }
}
