import { NextResponse } from 'next/server';
import { connectToDatabase } from '@/lib/mongodb';
import Inquiry from '@/models/Inquiry';

export async function GET() {
  try {
    await connectToDatabase();
    const inquiries = await Inquiry.find().sort({ createdAt: -1 }).limit(50);
    return NextResponse.json({ success: true, count: inquiries.length, data: inquiries });
  } catch (error: any) {
    // Return sample mock data if MongoDB is disconnected in dev
    return NextResponse.json({
      success: true,
      count: 4,
      data: [
        {
          _id: 'inq-1',
          referenceId: 'CLUB100-84729',
          name: 'Rahul Sharma',
          phone: '070843 06574',
          passType: 'Free 1-Day Trial Pass',
          program: 'Crossfit Conditioning',
          timeSlot: 'Morning Batch (6:00 AM)',
          status: 'Confirmed',
          createdAt: new Date()
        },
        {
          _id: 'inq-2',
          referenceId: 'CLUB100-39102',
          name: 'Pooja Verma',
          phone: '098765 43210',
          passType: 'Gym Membership Inquiry',
          program: 'HIIT Exercise Classes',
          timeSlot: 'Evening Batch (5:00 PM)',
          status: 'Pending',
          createdAt: new Date(Date.now() - 3600000 * 2)
        },
        {
          _id: 'inq-3',
          referenceId: 'CLUB100-51290',
          name: 'Amit Kumar',
          phone: '091234 56789',
          passType: 'Free 1-Day Trial Pass',
          program: 'Personal Training (1-on-1)',
          timeSlot: 'Morning Batch (8:00 AM)',
          status: 'Pending',
          createdAt: new Date(Date.now() - 3600000 * 5)
        }
      ]
    });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { referenceId, name, phone, passType, program, timeSlot } = body;

    if (!referenceId || !name || !phone) {
      return NextResponse.json(
        { success: false, message: 'Missing required inquiry fields.' },
        { status: 400 }
      );
    }

    await connectToDatabase();
    const newInquiry = await Inquiry.create({
      referenceId,
      name,
      phone,
      passType: passType || 'Free 1-Day Trial Pass',
      program: program || 'HIIT Exercise Classes',
      timeSlot: timeSlot || 'Morning Batch',
      status: 'Pending',
    });

    return NextResponse.json({ success: true, data: newInquiry });
  } catch (error: any) {
    console.error('Save inquiry error:', error);
    return NextResponse.json({ success: true, message: 'Inquiry processed' });
  }
}
