import { NextResponse } from 'next/server';
import { connectToDatabase } from '@/lib/mongodb';
import Trainer from '@/models/Trainer';
import { defaultTrainers } from '@/lib/defaultContent';

export async function GET() {
  try {
    await connectToDatabase();
    const trainers = await Trainer.find().sort({ createdAt: 1 });
    if (trainers && trainers.length > 0) {
      return NextResponse.json({ success: true, data: trainers });
    }
    return NextResponse.json({ success: true, data: defaultTrainers });
  } catch (error) {
    return NextResponse.json({ success: true, data: defaultTrainers });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    await connectToDatabase();
    const newTrainer = await Trainer.create(body);
    return NextResponse.json({ success: true, data: newTrainer });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { _id, ...updateData } = body;
    await connectToDatabase();
    const updatedTrainer = await Trainer.findByIdAndUpdate(_id, updateData, { new: true });
    return NextResponse.json({ success: true, data: updatedTrainer });
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
    await Trainer.findByIdAndDelete(id);
    return NextResponse.json({ success: true, message: 'Trainer deleted' });
  } catch (error: any) {
    return NextResponse.json({ success: false, message: error.message }, { status: 500 });
  }
}
