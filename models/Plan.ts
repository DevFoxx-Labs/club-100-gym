import mongoose, { Schema, Document } from 'mongoose';

export interface IPlan extends Document {
  name: string;
  monthlyPrice: string;
  yearlyPrice: string;
  period: string;
  popular: boolean;
  badge?: string;
  features: string[];
  createdAt: Date;
}

const PlanSchema: Schema = new Schema({
  name: { type: String, required: true },
  monthlyPrice: { type: String, required: true },
  yearlyPrice: { type: String, required: true },
  period: { type: String, default: '/month' },
  popular: { type: Boolean, default: false },
  badge: { type: String },
  features: [{ type: String }],
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.models.Plan || mongoose.model<IPlan>('Plan', PlanSchema);
