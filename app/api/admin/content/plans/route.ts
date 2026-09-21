import { NextResponse } from 'next/server';
import { connectToDatabase } from '@/lib/mongodb';
import Plan from '@/models/Plan';
import { defaultPlans } from '@/lib/defaultContent';

export async function GET() {
  try {
    await connectToDatabase();
    const plans = await Plan.find().sort({ createdAt: 1 });
    if (plans && plans.length > 0) {
      return NextResponse.json({ success: true, data: plans });
    }
    return NextResponse.json({ success: true, data: defaultPlans });
  } catch (error) {
    return NextResponse.json({ success: true, data: defaultPlans });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    await connectToDatabase();
    const newPlan = await Plan.create(body);
    return NextResponse.json({ success: true, data: newPlan });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { _id, ...updateData } = body;
    await connectToDatabase();
    const updatedPlan = await Plan.findByIdAndUpdate(_id, updateData, { new: true });
    return NextResponse.json({ success: true, data: updatedPlan });
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
    await Plan.findByIdAndDelete(id);
    return NextResponse.json({ success: true, message: 'Plan deleted' });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
