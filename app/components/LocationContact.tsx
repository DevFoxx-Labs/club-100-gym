"use client";

import React, { useRef, useState, useEffect } from 'react';
import { MapPin, Phone, Clock, Navigation, MessageSquare, Flame, Dumbbell, Users, ShieldCheck, Star } from 'lucide-react';
import { motion, useScroll, useTransform, useSpring } from 'framer-motion';
import { defaultGymInfo } from '@/lib/defaultContent';

interface LocationContactProps {
  onOpenBooking: () => void;
}

export default function LocationContact({ onOpenBooking }: LocationContactProps) {
  const sectionRef = useRef<HTMLDivElement>(null);
  const [gymInfo, setGymInfo] = useState<any>(defaultGymInfo);

  useEffect(() => {
    fetchGymInfo();
  }, []);

  const fetchGymInfo = async () => {
    try {
      const res = await fetch('/api/admin/content/gym-info');
      const data = await res.json();
      if (data.success && data.data) {
        setGymInfo(data.data);
      }
    } catch (err) {
      console.warn('Using default fallback gym info');
    }
  };

  const mapsUrl = gymInfo.mapsUrl || defaultGymInfo.mapsUrl;
  const whatsappUrl = (gymInfo.whatsappUrl || defaultGymInfo.whatsappUrl) + "?text=" + encodeURIComponent("Hello Club 100 The Gym, I want to inquire about gym membership and claim a 1-day free trial pass.");

  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"]
  });

  const bgY = useTransform(scrollYProgress, [0, 1], ["-10%", "10%"]);
  const smoothBgY = useSpring(bgY, { stiffness: 90, damping: 25 });

  return (
    <section ref={sectionRef} id="contact" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60 relative overflow-hidden">
      
      {/* Full-width 3D Parallax Gym Background Image */}
      <div className="absolute inset-0 z-0 pointer-events-none overflow-hidden">
        <motion.img
          style={{ y: smoothBgY }}
          src="/contact_bg.png"
          alt="Club 100 Interior Background"
          className="w-full h-[125%] object-cover opacity-60 object-center -top-[12%] absolute"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-[#0b0c10] via-[#0b0c10]/80 to-[#0b0c10] z-10" />
        <div className="absolute inset-0 bg-gradient-to-r from-[#0b0c10] via-transparent to-[#0b0c10] opacity-80 z-10" />
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid lg:grid-cols-12 gap-8 items-stretch">

          {/* Left Column */}
          <div className="lg:col-span-6 space-y-6 text-left flex flex-col justify-between">
            
            <div className="space-y-4">
              <p className="text-xs sm:text-sm font-extrabold text-slate-400 tracking-[0.25em] uppercase">
                VISIT OUR HEALTH CLUB
              </p>

              <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight leading-[1.05]">
                Location & <br />
                <span className="text-[#b5f63d]">Contact</span> Details
              </h2>

              <p className="text-xs sm:text-sm text-slate-300 font-medium leading-relaxed max-w-lg">
                Conveniently located in Transport Nagar, TP Nagar, Prayagraj. Come train with us and reach your fitness goals in a friendly, positive environment.
              </p>

              {/* Address Card */}
              <div className="bg-[#13151b]/85 backdrop-blur-md rounded-3xl p-6 border border-[#1e222d] space-y-4 shadow-xl">
                <div className="flex items-start gap-4">
                  <div className="p-3 rounded-2xl bg-[#b5f63d]/15 text-[#b5f63d] border border-[#b5f63d]/30 shrink-0">
                    <MapPin className="w-6 h-6" />
                  </div>
                  <div className="space-y-1">
                    <h3 className="text-lg font-black text-white">{gymInfo.name || defaultGymInfo.name}</h3>
                    <p className="text-xs font-medium text-slate-300 leading-relaxed">
                      {gymInfo.address || defaultGymInfo.address}
                    </p>
                  </div>
                </div>

                <div className="pt-1">
                  <a
                    href={mapsUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#0b0c10]/80 border border-[#1e222d] hover:border-[#b5f63d] text-slate-300 hover:text-white text-xs font-extrabold transition-colors"
                  >
                    <Navigation className="w-3.5 h-3.5 text-[#b5f63d]" /> Open in Google Maps →
                  </a>
                </div>
              </div>

              {/* Timings & Helpline Side-by-side Grid */}
              <div className="grid sm:grid-cols-2 gap-4">
                <div className="bg-[#13151b]/85 backdrop-blur-md rounded-3xl p-5 border border-[#1e222d] space-y-2">
                  <div className="flex items-center gap-2 text-xs font-black text-slate-400">
                    <div className="p-1.5 rounded-full bg-[#0b0c10] border border-[#1e222d]">
                      <Clock className="w-4 h-4 text-white" />
                    </div>
                    Gym Operating Hours
                  </div>
                  <h4 className="text-sm sm:text-base font-black text-white">
                    {gymInfo.hours || defaultGymInfo.hours}
                  </h4>
                  <p className="text-[11px] text-slate-400 font-medium">Morning & Evening training batches open daily.</p>
                </div>

                <div className="bg-[#13151b]/85 backdrop-blur-md rounded-3xl p-5 border border-[#1e222d] space-y-2">
                  <div className="flex items-center gap-2 text-xs font-black text-slate-400">
                    <div className="p-1.5 rounded-full bg-[#0b0c10] border border-[#1e222d]">
                      <Phone className="w-4 h-4 text-white" />
                    </div>
                    Direct Helpline
                  </div>
                  <a href={`tel:${(gymInfo.phone || defaultGymInfo.phone).replace(/\s+/g, '')}`} className="text-sm sm:text-base font-black text-[#b5f63d] hover:underline block">
                    {gymInfo.phone || defaultGymInfo.phone}
                  </a>
                  <p className="text-[11px] text-slate-400 font-medium">Call for admissions, passes & details.</p>
                </div>
              </div>

              {/* Action Buttons Row */}
              <div className="flex flex-col sm:flex-row gap-3 pt-2">
                <a
                  href={whatsappUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full py-3.5 rounded-full bg-[#b5f63d] text-[#0b0c10] font-black text-xs shadow-xl shadow-[#b5f63d]/20 flex items-center justify-center gap-2 cursor-pointer hover:scale-105 transition-transform"
                >
                  <MessageSquare className="w-4 h-4 fill-[#0b0c10]" /> Chat on WhatsApp →
                </a>

                <button
                  onClick={onOpenBooking}
                  className="w-full py-3.5 rounded-full bg-[#0b0c10] border border-slate-700 hover:border-[#b5f63d] text-white font-black text-xs flex items-center justify-center gap-2 cursor-pointer transition-colors"
                >
                  <Flame className="w-4 h-4 text-[#b5f63d]" /> Claim Free Day Pass
                </button>
              </div>
            </div>

            {/* Bottom 3 Feature Pillars */}
            <div className="grid grid-cols-3 gap-3 pt-6 border-t border-[#1e222d] text-left">
              <div className="flex items-center gap-2">
                <Dumbbell className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <div>
                  <span className="block text-xs font-black text-white">Top Equipment</span>
                  <span className="text-[10px] text-slate-500 font-semibold">Clean & well-maintained</span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <div>
                  <span className="block text-xs font-black text-white">Helpful Staff</span>
                  <span className="text-[10px] text-slate-500 font-semibold">Knowledgeable trainers</span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <div>
                  <span className="block text-xs font-black text-white">Caters to Women</span>
                  <span className="text-[10px] text-slate-500 font-semibold">Friendly environment</span>
                </div>
              </div>
            </div>

          </div>

          {/* Right Column: Google Maps & Location Card */}
          <div className="lg:col-span-6 bg-[#13151b] rounded-3xl p-4 border border-[#1e222d] space-y-4 shadow-2xl flex flex-col justify-between">
            
            {/* Live Interactive Map Embed */}
            <div className="relative w-full h-[260px] rounded-2xl overflow-hidden bg-[#0b0c10] border border-[#1e222d] shadow-2xl group">
              <iframe
                title="Club 100 The Gym Google Maps Location"
                src="https://maps.google.com/maps?q=1st+Floor+TP+Nagar,+beside+of+Kalewam+Restaurant,+Meera+Patti,+Transport+Nagar,+Prayagraj,+Uttar+Pradesh+211011&t=&z=16&ie=UTF8&iwloc=&output=embed"
                width="100%"
                height="100%"
                style={{ border: 0, filter: 'grayscale(0.7) contrast(1.15) opacity(0.9)' }}
                allowFullScreen={false}
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
                className="w-full h-full"
              />

              {/* Floating Overlay Badge on Map */}
              <div className="absolute top-3 left-3 bg-[#0b0c10]/95 border border-[#b5f63d] backdrop-blur-md px-3 py-1.5 rounded-full flex items-center gap-2 shadow-xl">
                <div className="w-5 h-5 rounded-full bg-[#b5f63d] text-[#0b0c10] flex items-center justify-center font-black">
                  <MapPin className="w-3 h-3" />
                </div>
                <span className="text-xs font-black text-white">{gymInfo.name || defaultGymInfo.name}</span>
                <span className="text-[10px] font-extrabold text-[#b5f63d] bg-[#b5f63d]/15 px-2 py-0.5 rounded-full">
                  {gymInfo.rating || defaultGymInfo.rating} ★ ({gymInfo.reviewCount || defaultGymInfo.reviewCount})
                </span>
              </div>

              {/* Bottom Directions Button */}
              <div className="absolute bottom-3 right-3">
                <a
                  href={mapsUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-3.5 py-1.5 rounded-full bg-[#b5f63d] text-[#0b0c10] font-black text-[11px] flex items-center gap-1.5 shadow-xl hover:scale-105 transition-transform"
                >
                  <Navigation className="w-3.5 h-3.5 fill-[#0b0c10]" /> Get Directions →
                </a>
              </div>
            </div>

            {/* Middle Card: Facade / Gym Photo */}
            <div className="relative rounded-2xl overflow-hidden border border-[#1e222d] bg-[#0b0c10] h-[190px] group">
              <img
                src="/hero_athlete.jpg"
                alt="Club 100 Gym Facade"
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 opacity-90"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0b0c10] via-transparent to-transparent opacity-60" />
            </div>

            {/* Bottom Card: Stats & Google Rating Row */}
            <div className="grid grid-cols-3 gap-2 p-4 rounded-2xl bg-[#0b0c10] border border-[#1e222d] text-left">
              <div className="flex items-center gap-2">
                <Users className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <div>
                  <span className="block text-xs font-black text-white">Positive</span>
                  <span className="text-[10px] text-slate-400 font-medium">Vibe & Atmosphere</span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <Star className="w-4 h-4 text-amber-400 fill-amber-400 shrink-0" />
                <div>
                  <span className="block text-xs font-black text-white">{gymInfo.rating || defaultGymInfo.rating} / 5</span>
                  <span className="text-[10px] text-slate-400 font-medium">{gymInfo.reviewCount || defaultGymInfo.reviewCount} Reviews</span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <MapPin className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <div>
                  <span className="block text-xs font-black text-white">TP Nagar</span>
                  <span className="text-[10px] text-slate-400 font-medium">Transport Nagar</span>
                </div>
              </div>
            </div>

          </div>

        </div>
      </div>
    </section>
  );
}
