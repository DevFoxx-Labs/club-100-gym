"use client";

import React, { useState, useEffect } from 'react';
import { ArrowRight, ArrowUpRight, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { defaultServices } from '@/lib/defaultContent';

interface ServicesProps {
  onOpenBooking: () => void;
}

export default function Services({ onOpenBooking }: ServicesProps) {
  const [selectedProgram, setSelectedProgram] = useState<any>(null);
  const [servicesList, setServicesList] = useState<any[]>(defaultServices);

  useEffect(() => {
    fetchServices();
  }, []);

  const fetchServices = async () => {
    try {
      const res = await fetch('/api/admin/content/services');
      const data = await res.json();
      if (data.success && data.data && data.data.length > 0) {
        setServicesList(data.data);
      }
    } catch (err) {
      console.warn('Using default fallback services');
    }
  };

  return (
    <section id="services" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

        {/* Section Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-12">
          <div className="space-y-2 text-left">
            <p className="text-xs sm:text-sm font-extrabold text-slate-400 tracking-[0.25em] uppercase">
              SERVICES OFFERED AT CLUB 100
            </p>
            <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight">
              Workouts for Every Goal
            </h2>
          </div>

          <button
            onClick={onOpenBooking}
            className="flex items-center gap-2 text-xs font-black text-[#b5f63d] hover:underline uppercase tracking-wider cursor-pointer"
          >
            Claim Free Trial Class <ArrowRight className="w-4 h-4" />
          </button>
        </div>

        {/* Service Cards Grid */}
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          variants={{
            hidden: { opacity: 0 },
            visible: {
              opacity: 1,
              transition: { staggerChildren: 0.12 }
            }
          }}
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 text-left"
        >
          {servicesList.map((cls, idx) => (
            <motion.div
              key={cls._id || idx}
              variants={{
                hidden: { opacity: 0, y: 35 },
                visible: { opacity: 1, y: 0, transition: { duration: 0.7, ease: [0.16, 1, 0.3, 1] } }
              }}
              whileHover={{ y: -10 }}
              onClick={() => setSelectedProgram(cls)}
              className="relative h-[380px] rounded-3xl overflow-hidden bg-[#13151b] border border-[#1e222d] hover:border-[#b5f63d]/60 group cursor-pointer shadow-2xl transition-all"
            >
              <img
                src={cls.img || '/class_hiit.jpg'}
                alt={cls.title}
                className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 opacity-85"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#0b0c10] via-black/40 to-transparent" />

              {/* Category Pill Tag */}
              <div className="absolute top-4 left-4 z-10">
                <span className="px-3 py-1 rounded-full bg-[#0b0c10]/80 border border-[#b5f63d]/40 text-[#b5f63d] text-[10px] font-black uppercase tracking-wider backdrop-blur-md">
                  {cls.category}
                </span>
              </div>

              <div className="absolute bottom-6 left-6 right-6 flex items-end justify-between z-10">
                <div className="space-y-1">
                  <h3 className="text-xl font-black text-white group-hover:text-[#b5f63d] transition-colors leading-snug">
                    {cls.title}
                  </h3>
                  <p className="text-xs text-slate-300 font-semibold">{cls.subtitle}</p>
                </div>

                {/* Circle Arrow Button */}
                <div className="w-9 h-9 rounded-full bg-slate-900/80 border border-slate-700/80 backdrop-blur-md flex items-center justify-center text-white group-hover:bg-[#b5f63d] group-hover:text-slate-950 group-hover:scale-110 transition-all shrink-0 ml-2">
                  <ArrowUpRight className="w-4 h-4" />
                </div>
              </div>
            </motion.div>
          ))}
        </motion.div>

      </div>

      {/* Detail Modal */}
      <AnimatePresence>
        {selectedProgram && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedProgram(null)}
              className="absolute inset-0 bg-[#0b0c10]/85 backdrop-blur-md"
            />

            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: 20 }}
              className="relative w-full max-w-lg bg-[#13151b] rounded-3xl p-6 sm:p-8 border border-[#b5f63d]/40 text-white z-10 space-y-6 shadow-2xl text-left"
            >
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-xs font-bold text-[#b5f63d] uppercase tracking-wider block">{selectedProgram.category}</span>
                  <h3 className="text-2xl font-black text-white">{selectedProgram.title}</h3>
                </div>
                <button
                  onClick={() => setSelectedProgram(null)}
                  className="p-2 rounded-full bg-[#1e222d] text-slate-400 hover:text-white cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <p className="text-sm text-slate-300 leading-relaxed font-medium">
                {selectedProgram.desc}
              </p>

              <button
                onClick={() => {
                  setSelectedProgram(null);
                  onOpenBooking();
                }}
                className="w-full btn-nova-neon py-3.5 text-center text-xs font-black uppercase tracking-wider cursor-pointer"
              >
                Claim Free Trial Session →
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </section>
  );
}
