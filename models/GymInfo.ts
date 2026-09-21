import mongoose, { Schema, Document } from 'mongoose';

export interface IGymInfo extends Document {
  name: string;
  address: string;
  phone: string;
  hours: string;
  mapsUrl: string;
  whatsappUrl: string;
  instagramUrl: string;
  facebookUrl: string;
  youtubeUrl: string;
  rating: string;
  reviewCount: string;
  updatedAt: Date;
}

const GymInfoSchema: Schema = new Schema({
  name: { type: String, default: 'Club 100 The Gym' },
  address: {
    type: String,
    default: '1st Floor TP Nagar, beside of Kalewam Restaurant, Meera Patti, Transport Nagar, Prayagraj, Uttar Pradesh 211011'
  },
  phone: { type: String, default: '070843 06574' },
  hours: { type: String, default: 'Open Daily · Closes 8:00 PM' },
  mapsUrl: {
    type: String,
    default: 'https://maps.google.com/?q=1st+Floor+TP+Nagar,+beside+of+Kalewam+Restaurant,+Meera+Patti,+Transport+Nagar,+Prayagraj,+Uttar+Pradesh+211011'
  },
  whatsappUrl: { type: String, default: 'https://wa.me/917084306574' },
  instagramUrl: { type: String, default: 'https://instagram.com' },
  facebookUrl: { type: String, default: 'https://facebook.com' },
  youtubeUrl: { type: String, default: 'https://youtube.com' },
  rating: { type: String, default: '4.8' },
  reviewCount: { type: String, default: '230' },
  updatedAt: { type: Date, default: Date.now }
});

export default mongoose.models.GymInfo || mongoose.model<IGymInfo>('GymInfo', GymInfoSchema);
