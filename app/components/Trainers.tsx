"use client";

import React, { useState, useEffect } from 'react';
import { Star, ArrowRight, ArrowLeft, Users, Sliders, X, CheckCircle } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { defaultTrainers } from '@/lib/defaultContent';

interface TrainersProps {
  onOpenBooking: () => void;
}

export default function Trainers({ onOpenBooking }: TrainersProps) {
  const [selectedTrainer, setSelectedTrainer] = useState<any>(null);
  const [trainers, setTrainers] = useState<any[]>(defaultTrainers);

  useEffect(() => {
    fetchTrainers();
  }, []);

  const fetchTrainers = async () => {
    try {
      const res = await fetch('/api/admin/content/trainers');
      const data = await res.json();
      if (data.success && data.data && data.data.length > 0) {
        setTrainers(data.data);
      }
    } catch (err) {
      console.warn('Using default fallback trainers');
    }
  };

  return (
    <section id="trainers" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60 relative overflow-hidden">
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 w-full space-y-12">
        
        {/* Top Header Row */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center text-left">
          
          <div className="lg:col-span-7 space-y-4">
            
            <div className="flex items-center gap-3">
              <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#13151b] border border-[#b5f63d]/40 text-white text-xs font-black uppercase tracking-wider">
                <Users className="w-3.5 h-3.5 text-[#b5f63d]" /> OUR TRAINERS
              </span>
              <span className="text-xs font-extrabold text-slate-400 tracking-[0.2em] uppercase">
                —— KNOWLEDGEABLE & SUPPORTIVE
              </span>
            </div>

            <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight leading-[1.05]">
              Guided by <br />
              <span className="text-[#b5f63d]">Experienced Coaches</span>
            </h2>

            <p className="text-xs sm:text-sm text-slate-300 font-medium leading-relaxed max-w-xl">
              Our friendly, certified trainers are always ready to assist, correct your technique, and help you reach your goals in an encouraging environment.
            </p>
          </div>

          <div className="lg:col-span-5 relative flex items-center justify-end">
            
            <div className="absolute top-2 left-4 z-20 pointer-events-none transform -rotate-6">
              <span className="font-handwriting text-2xl sm:text-3xl text-slate-200 block drop-shadow-md">
                Great Support
              </span>
              <span className="font-handwriting text-2xl sm:text-3xl text-[#b5f63d] block relative">
                Real Transformation
              </span>
            </div>

            <div className="relative w-56 sm:w-64 h-64 sm:h-72 rounded-3xl overflow-hidden border border-[#1e222d] shadow-2xl bg-[#13151b] z-10 group">
              <img
                src="/trainer_hero.jpg"
                alt="Club 100 Head Coach"
                className="w-full h-full object-cover object-top group-hover:scale-105 transition-transform duration-700 opacity-90"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0b0c10] via-transparent to-transparent" />
            </div>

          </div>

        </div>

        {/* Trainer Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 text-left">
          {trainers.map((trainer, idx) => (
            <motion.div
              key={trainer._id || idx}
              whileHover={{ y: -8 }}
              onClick={() => setSelectedTrainer(trainer)}
              className={`relative rounded-3xl p-4 flex flex-col justify-between transition-all duration-300 cursor-pointer overflow-hidden group shadow-2xl ${
                trainer.isTopRated
                  ? 'bg-[#13151b] border-2 border-[#b5f63d] shadow-[0_0_30px_rgba(181,246,61,0.15)]'
                  : 'bg-[#13151b] border border-[#1e222d] hover:border-[#b5f63d]/60'
              }`}
            >
              {trainer.isTopRated && (
                <div className="absolute top-6 left-6 z-20 inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#b5f63d] text-slate-950 text-xs font-black uppercase tracking-wider shadow-lg">
                  <Star className="w-3.5 h-3.5 fill-slate-950 stroke-slate-950" /> Top Rated
                </div>
              )}

              <div className="relative h-72 sm:h-80 rounded-2xl overflow-hidden bg-[#0b0c10] mb-4">
                <img
                  src={trainer.image || '/trainer_hero.jpg'}
                  alt={trainer.name}
                  className="w-full h-full object-cover object-top group-hover:scale-108 transition-transform duration-700 opacity-90"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#13151b] via-[#13151b]/20 to-transparent" />
              </div>

              <div className="space-y-2.5 px-2 pb-2">
                <span className="text-[11px] font-extrabold text-[#b5f63d] tracking-wider uppercase block">
                  {trainer.category}
                </span>

                <h3 className="text-2xl font-black text-white group-hover:text-[#b5f63d] transition-colors">
                  {trainer.name}
                </h3>

                <p className="text-xs font-semibold text-slate-400">
                  {trainer.specialties}
                </p>

                <p className="text-xs text-slate-300 font-medium leading-relaxed line-clamp-2 pt-1">
                  {trainer.description}
                </p>

                <div className="flex items-center justify-between pt-4 border-t border-[#1e222d] mt-4">
                  <span className="text-xs font-bold text-slate-400">★ {trainer.rating || 4.8} (Certified)</span>
                  <div className="w-9 h-9 rounded-full bg-[#0b0c10] border border-[#1e222d] flex items-center justify-center text-white group-hover:bg-[#b5f63d] group-hover:text-slate-950 group-hover:border-[#b5f63d] transition-all">
                    <ArrowRight className="w-4 h-4" />
                  </div>
                </div>

              </div>

            </motion.div>
          ))}
        </div>

        {/* Bottom Banner Card */}
        <div className="rounded-3xl bg-[#13151b] border border-[#1e222d] p-6 sm:p-8 flex flex-col md:flex-row items-center justify-between gap-6 relative overflow-hidden text-left shadow-2xl">
          <div className="flex items-center gap-4 sm:gap-6">
            <div className="w-12 h-12 rounded-2xl bg-[#0b0c10] border border-[#1e222d] flex items-center justify-center text-[#b5f63d] shrink-0 shadow-inner">
              <Sliders className="w-6 h-6" />
            </div>

            <div className="space-y-1">
              <span className="text-[11px] font-extrabold text-slate-400 tracking-[0.2em] uppercase block">
                EXPERIENCED TRAINERS AT AFFORDABLE PRICE
              </span>
              <h3 className="text-xl sm:text-2xl font-black text-white">
                Personalized Training & Guidance
              </h3>
              <p className="text-xs sm:text-sm text-slate-400 font-medium">
                Reach out to our desk for 1-on-1 personal training packages tailored to your schedule.
              </p>
            </div>
          </div>

          <button
            onClick={onOpenBooking}
            className="px-6 py-3.5 rounded-full bg-[#b5f63d] text-slate-950 font-black text-xs hover:bg-[#c4f85e] hover:scale-105 transition-all shadow-lg shadow-[#b5f63d]/20 flex items-center gap-2 cursor-pointer shrink-0"
          >
            Inquire Personal Training <ArrowRight className="w-4 h-4" />
          </button>
        </div>

      </div>

      {/* Trainer Detail Modal */}
      <AnimatePresence>
        {selectedTrainer && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedTrainer(null)}
              className="absolute inset-0 bg-[#0b0c10]/85 backdrop-blur-md"
            />

            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="relative w-full max-w-xl bg-[#13151b] rounded-3xl p-6 sm:p-8 border border-[#b5f63d]/40 text-white z-10 space-y-6 shadow-2xl text-left"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-center gap-4">
                  <img
                    src={selectedTrainer.image || '/trainer_hero.jpg'}
                    alt={selectedTrainer.name}
                    className="w-16 h-16 rounded-2xl object-cover border-2 border-[#b5f63d]/40"
                  />
                  <div>
                    <span className="text-xs font-bold text-[#b5f63d] uppercase tracking-wider block">
                      {selectedTrainer.category}
                    </span>
                    <h3 className="text-2xl font-black text-white">{selectedTrainer.name}</h3>
                    <p className="text-xs text-slate-400 font-semibold">{selectedTrainer.experience} Experience • ★ {selectedTrainer.rating || 4.8}</p>
                  </div>
                </div>

                <button
                  onClick={() => setSelectedTrainer(null)}
                  className="p-2 rounded-full bg-[#1e222d] text-slate-400 hover:text-white cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <p className="text-xs sm:text-sm text-slate-300 leading-relaxed font-medium">
                {selectedTrainer.fullBio}
              </p>

              <div className="space-y-2 pt-2 border-t border-[#1e222d]">
                <h4 className="text-xs font-black text-white uppercase tracking-wider">Certifications & Credentials</h4>
                <div className="space-y-1.5">
                  {selectedTrainer.certifications?.map((cert: string, idx: number) => (
                    <div key={idx} className="flex items-center gap-2 text-xs text-slate-300 font-semibold">
                      <CheckCircle className="w-4 h-4 text-[#b5f63d] shrink-0" />
                      <span>{cert}</span>
                    </div>
                  ))}
                </div>
              </div>

              <button
                onClick={() => {
                  setSelectedTrainer(null);
                  onOpenBooking();
                }}
                className="w-full btn-nova-neon py-3.5 text-center text-xs font-black uppercase tracking-wider cursor-pointer"
              >
                Book 1-on-1 Session with {selectedTrainer.name} →
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

    </section>
  );
}
