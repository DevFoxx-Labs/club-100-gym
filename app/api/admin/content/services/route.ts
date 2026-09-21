import { NextResponse } from 'next/server';
import { connectToDatabase } from '@/lib/mongodb';
import Service from '@/models/Service';
import { defaultServices } from '@/lib/defaultContent';

export async function GET() {
  try {
    await connectToDatabase();
    const services = await Service.find().sort({ createdAt: 1 });
    if (services && services.length > 0) {
      return NextResponse.json({ success: true, data: services });
    }
    return NextResponse.json({ success: true, data: defaultServices });
  } catch (error) {
    return NextResponse.json({ success: true, data: defaultServices });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    await connectToDatabase();
    const newService = await Service.create(body);
    return NextResponse.json({ success: true, data: newService });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { _id, ...updateData } = body;
    await connectToDatabase();
    const updatedService = await Service.findByIdAndUpdate(_id, updateData, { new: true });
    return NextResponse.json({ success: true, data: updatedService });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    if (!id) return NextResponse.json({ success: false, message: 'ID required' }, { status: 400 });

    await connectToDatabase();
    await Service.findByIdAndDelete(id);
    return NextResponse.json({ success: true, message: 'Service deleted' });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
