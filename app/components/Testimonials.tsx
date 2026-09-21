"use client";

import React, { useState, useRef } from 'react';
import { ChevronLeft, ChevronRight, Star, Quote } from 'lucide-react';
import { motion, useScroll, useTransform, useSpring } from 'framer-motion';

export default function Testimonials() {
  const sectionRef = useRef<HTMLDivElement>(null);
  const [activeIdx, setActiveIdx] = useState(0);

  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"]
  });

  const bgY = useTransform(scrollYProgress, [0, 1], ["-10%", "10%"]);
  const smoothBgY = useSpring(bgY, { stiffness: 90, damping: 25 });

  const reviews = [
    {
      quote: "Club 100 Gym has the best positive environment. The equipment is extremely clean and trainers are super supportive.",
      author: "Sneha R.",
      role: "Member since 2023",
      avatar: "/avatar_sarah.jpg",
      rating: 5
    },
    {
      quote: "Reasonable prices, top-notch machines, and friendly trainers. Perfect place for workout in TP Nagar.",
      author: "Amit K.",
      role: "Member since 2022",
      avatar: "/avatar_jason.jpg",
      rating: 5
    },
    {
      quote: "Very welcoming to women. Aerobics and Crossfit sessions are full of energy!",
      author: "Pooja V.",
      role: "Member since 2024",
      avatar: "/avatar_priya.jpg",
      rating: 5
    }
  ];

  const handlePrev = () => {
    setActiveIdx((prev) => (prev === 0 ? reviews.length - 1 : prev - 1));
  };

  const handleNext = () => {
    setActiveIdx((prev) => (prev === reviews.length - 1 ? 0 : prev + 1));
  };

  return (
    <section ref={sectionRef} id="community" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60 relative overflow-hidden min-h-[600px] flex items-center">
      
      {/* Full Section Parallax Background Image */}
      <div className="absolute inset-0 pointer-events-none z-0 overflow-hidden">
        <motion.img
          style={{ y: smoothBgY }}
          src="/community_bg.png"
          alt="Athlete Community Background"
          className="w-full h-[125%] object-cover object-center opacity-75 -top-[12%] absolute"
        />
        {/* Seamless Dark Vignette Gradients */}
        <div className="absolute inset-0 bg-gradient-to-b from-[#0b0c10] via-[#0b0c10]/75 to-[#0b0c10] z-10" />
        <div className="absolute inset-0 bg-gradient-to-r from-[#0b0c10] via-transparent to-[#0b0c10] opacity-80 z-10" />
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 w-full space-y-10">
        
        {/* Top Header Row */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 text-left">
          <div className="space-y-3 max-w-xl">
            <p className="text-xs sm:text-sm font-extrabold text-[#b5f63d] tracking-[0.25em] uppercase">
              COMMUNITY & STORIES
            </p>
            <h2 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-[1.05]">
              “A stronger, <span className="text-[#b5f63d]">happier me.”</span>
            </h2>
            <p className="text-xs sm:text-sm text-slate-300 font-medium leading-relaxed">
              Real results from members at Transport Nagar, Prayagraj. Join a community that moves you forward every day.
            </p>
          </div>

          <div className="flex items-center gap-6 self-start md:self-end">
            <div className="hidden sm:flex items-center gap-3">
              <div className="flex -space-x-3">
                <img src="/avatar_sarah.jpg" alt="Member" className="w-9 h-9 rounded-full border-2 border-[#0b0c10] object-cover" />
                <img src="/avatar_jason.jpg" alt="Member" className="w-9 h-9 rounded-full border-2 border-[#0b0c10] object-cover" />
                <img src="/avatar_priya.jpg" alt="Member" className="w-9 h-9 rounded-full border-2 border-[#0b0c10] object-cover" />
              </div>
              <div className="text-left">
                <span className="text-sm font-black text-white block">4.8 ★ (230)</span>
                <span className="text-[11px] text-slate-400 font-medium">Google Rated</span>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <button
                onClick={handlePrev}
                className="w-11 h-11 rounded-full bg-[#13151b]/90 border border-[#1e222d] text-white flex items-center justify-center hover:border-[#b5f63d] hover:text-[#b5f63d] transition-all cursor-pointer backdrop-blur-md"
                aria-label="Previous testimonial"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <button
                onClick={handleNext}
                className="w-11 h-11 rounded-full bg-[#13151b]/90 border border-[#1e222d] text-white flex items-center justify-center hover:border-[#b5f63d] hover:text-[#b5f63d] transition-all cursor-pointer backdrop-blur-md"
                aria-label="Next testimonial"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Horizontal Cards Grid Layout */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-left">
          {reviews.map((rev, idx) => {
            const isActive = activeIdx === idx;
            return (
              <motion.div
                key={idx}
                onClick={() => setActiveIdx(idx)}
                whileHover={{ y: -6 }}
                className={`rounded-3xl p-6 border backdrop-blur-md transition-all cursor-pointer flex flex-col justify-between space-y-6 ${
                  isActive
                    ? 'bg-[#13151b]/95 border-[#b5f63d] shadow-2xl shadow-[#b5f63d]/15 ring-1 ring-[#b5f63d]/40'
                    : 'bg-[#13151b]/80 border-[#1e222d] opacity-90 hover:opacity-100 hover:border-slate-700'
                }`}
              >
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1">
                      {[...Array(rev.rating)].map((_, i) => (
                        <Star key={i} className="w-4 h-4 fill-[#b5f63d] text-[#b5f63d]" />
                      ))}
                    </div>
                    <Quote className="w-6 h-6 text-[#b5f63d]/40" />
                  </div>

                  <p className="text-xs sm:text-sm font-medium text-slate-200 leading-relaxed italic">
                    "{rev.quote}"
                  </p>
                </div>

                <div className="flex items-center gap-3.5 pt-4 border-t border-[#1e222d]/80">
                  <img
                    src={rev.avatar}
                    alt={rev.author}
                    className="w-11 h-11 rounded-full object-cover shrink-0 border-2 border-[#b5f63d]/30"
                  />
                  <div>
                    <h4 className="text-sm font-black text-white">{rev.author}</h4>
                    <span className="text-[11px] text-slate-400 font-semibold">{rev.role}</span>
                  </div>
                </div>
              </motion.div>
            );
          })}
        </div>

      </div>
    </section>
  );
}
