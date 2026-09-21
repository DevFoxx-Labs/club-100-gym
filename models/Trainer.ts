import mongoose, { Schema, Document } from 'mongoose';

export interface ITrainer extends Document {
  name: string;
  category: string;
  specialties: string;
  description: string;
  fullBio: string;
  experience: string;
  certifications: string[];
  rating: number;
  isTopRated: boolean;
  image: string;
  createdAt: Date;
}

const TrainerSchema: Schema = new Schema({
  name: { type: String, required: true },
  category: { type: String, required: true },
  specialties: { type: String, required: true },
  description: { type: String, required: true },
  fullBio: { type: String, required: true },
  experience: { type: String, required: true },
  certifications: [{ type: String }],
  rating: { type: Number, default: 4.8 },
  isTopRated: { type: Boolean, default: false },
  image: { type: String, default: '/trainer_hero.jpg' },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.models.Trainer || mongoose.model<ITrainer>('Trainer', TrainerSchema);
