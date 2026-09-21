import mongoose, { Schema, Document } from 'mongoose';

export interface IService extends Document {
  title: string;
  subtitle: string;
  img: string;
  category: string;
  desc: string;
  createdAt: Date;
}

const ServiceSchema: Schema = new Schema({
  title: { type: String, required: true },
  subtitle: { type: String, required: true },
  img: { type: String, default: '/class_hiit.jpg' },
  category: { type: String, required: true },
  desc: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.models.Service || mongoose.model<IService>('Service', ServiceSchema);
