import { NextResponse } from 'next/server';
import { connectToDatabase } from '@/lib/mongodb';
import GymInfo from '@/models/GymInfo';
import { defaultGymInfo } from '@/lib/defaultContent';

export async function GET() {
  try {
    await connectToDatabase();
    const info = await GymInfo.findOne();
    if (info) {
      return NextResponse.json({ success: true, data: info });
    }
    return NextResponse.json({ success: true, data: defaultGymInfo });
  } catch (error) {
    return NextResponse.json({ success: true, data: defaultGymInfo });
  }
}

export async function PUT(request: Request) {
  try {
    const body = await request.json();
    await connectToDatabase();
    
    let info = await GymInfo.findOne();
    if (info) {
      info = await GymInfo.findByIdAndUpdate(info._id, { ...body, updatedAt: new Date() }, { new: true });
    } else {
      info = await GymInfo.create(body);
    }

    return NextResponse.json({ success: true, data: info });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
