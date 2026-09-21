import mongoose, { Schema, Document } from 'mongoose';

export interface IInquiry extends Document {
  referenceId: string;
  name: string;
  phone: string;
  passType: string;
  program: string;
  timeSlot: string;
  status: string;
  createdAt: Date;
}

const InquirySchema: Schema = new Schema({
  referenceId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  passType: { type: String, required: true },
  program: { type: String, required: true },
  timeSlot: { type: String, required: true },
  status: { type: String, default: 'Pending' },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.models.Inquiry || mongoose.model<IInquiry>('Inquiry', InquirySchema);
