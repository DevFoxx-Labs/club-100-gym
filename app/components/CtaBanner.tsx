"use client";

import React from 'react';
import { ArrowRight } from 'lucide-react';

interface CtaBannerProps {
  onOpenBooking: () => void;
}

export default function CtaBanner({ onOpenBooking }: CtaBannerProps) {
  return (
    <section className="py-10 bg-[#0b0c10] border-b border-[#1e222d]/60 relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="relative rounded-2xl overflow-hidden border border-black/80 bg-[#08090c] min-h-[260px] sm:min-h-[290px] flex items-center shadow-2xl">
          
          {/* Background Gym Image */}
          <div className="absolute inset-0 z-0 pointer-events-none">
            <img
              src="/gym_interior_neon.jpg"
              alt="Club 100 Gym Interior"
              className="w-full h-full object-cover object-center opacity-65"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/60 to-black/40 z-10 pointer-events-none" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-black/50 z-10 pointer-events-none" />
          </div>

          {/* Banner Inner Content Grid */}
          <div className="relative z-20 w-full px-8 sm:px-14 py-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-8">
            
            <div className="space-y-3 text-left max-w-lg">
              <p className="text-[11px] sm:text-xs font-bold text-slate-400 tracking-[0.25em] uppercase">
                READY TO START AT CLUB 100?
              </p>

              <h2 className="text-3xl sm:text-4xl lg:text-[44px] font-black text-white tracking-tight leading-[1.08] uppercase">
                YOUR STRONGER <br />
                <span className="text-[#b5f63d]">TOMORROW</span> AWAITS
              </h2>

              <p className="text-xs sm:text-sm text-slate-300 font-normal pt-1">
                Join today and experience top-notch equipment & expert guidance.
              </p>
            </div>

            <div className="my-auto">
              <button
                onClick={onOpenBooking}
                className="px-9 py-4 rounded-full bg-[#b5f63d] hover:bg-[#a3e527] text-[#0b0c10] font-black text-base flex items-center gap-3 shadow-[0_0_30px_rgba(181,246,61,0.3)] hover:scale-105 transition-transform cursor-pointer"
              >
                Join Now <ArrowRight className="w-5 h-5 stroke-[2.5]" />
              </button>
            </div>

          </div>

        </div>
      </div>
    </section>
  );
}
