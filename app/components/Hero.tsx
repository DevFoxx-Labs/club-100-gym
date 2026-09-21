"use client";

import React, { useRef } from 'react';
import { ArrowRight, Play, Star, ShieldCheck, Heart } from 'lucide-react';
import { motion, useScroll, useTransform, useSpring } from 'framer-motion';

interface HeroProps {
  onOpenBooking: () => void;
}

export default function Hero({ onOpenBooking }: HeroProps) {
  const heroRef = useRef<HTMLDivElement>(null);

  // Scroll parallax for background hero athlete image
  const { scrollYProgress } = useScroll({
    target: heroRef,
    offset: ["start start", "end start"]
  });

  const heroBgY = useTransform(scrollYProgress, [0, 1], ["0%", "22%"]);
  const heroBgScale = useTransform(scrollYProgress, [0, 1], [1, 1.12]);
  const smoothHeroBgY = useSpring(heroBgY, { stiffness: 80, damping: 25 });
  const smoothHeroBgScale = useSpring(heroBgScale, { stiffness: 80, damping: 25 });

  return (
    <section ref={heroRef} id="home" className="relative min-h-[92vh] flex items-center bg-[#0b0c10] text-white overflow-hidden pt-6 pb-16 border-b border-[#1e222d]/60">
      
      {/* Background Hero Image - Full Width Parallax Overlay */}
      <div className="absolute inset-y-0 right-0 w-full lg:w-7/12 pointer-events-none z-0 overflow-hidden">
        <motion.img
          style={{ y: smoothHeroBgY, scale: smoothHeroBgScale }}
          src="/hero_athlete.jpg"
          alt="Club 100 Athlete Background"
          className="w-full h-[120%] object-cover object-center sm:object-right-top opacity-90 -top-[10%] absolute"
        />
        {/* Seamless Radial & Linear Gradients blending Left and Bottom into #0b0c10 */}
        <div className="absolute inset-0 bg-gradient-to-r from-[#0b0c10] via-[#0b0c10]/80 lg:via-[#0b0c10]/40 to-transparent z-10" />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0b0c10] via-transparent to-transparent opacity-90 z-10" />
      </div>

      {/* Background Radial Neon Glow */}
      <div className="absolute top-1/3 left-1/4 w-[600px] h-[600px] bg-[#b5f63d]/10 rounded-full blur-[140px] pointer-events-none z-0" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 w-full">
        <div className="max-w-2xl text-left space-y-6 pt-2">

          {/* Badge / Rating Pill */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
            className="inline-flex items-center gap-2.5 px-3.5 py-1.5 rounded-full bg-[#13151b] border border-[#b5f63d]/40 backdrop-blur-md"
          >
            <div className="flex items-center gap-1 text-amber-400">
              <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
              <span className="text-xs font-black text-white">4.8</span>
            </div>
            <span className="text-[11px] font-bold text-slate-300">
              (230 Google Reviews) • Transport Nagar, Prayagraj
            </span>
          </motion.div>

          {/* Uppercase Subtitle */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.05, ease: [0.16, 1, 0.3, 1] }}
            className="text-xs sm:text-sm font-extrabold text-slate-400 tracking-[0.3em] uppercase block"
          >
            STRONGER — HAPPIER — YOU
          </motion.p>

          {/* Main Display Headline */}
          <motion.h1
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
            className="text-5xl sm:text-7xl lg:text-8xl font-black text-white tracking-tight leading-[1.05]"
          >
            A HEALTHIER <br />
            <span className="text-[#b5f63d] drop-shadow-[0_0_20px_rgba(181,246,61,0.4)]">YOU</span> STARTS <br />
            HERE
          </motion.h1>

          {/* Subtext */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.25 }}
            className="text-base sm:text-lg text-slate-300 font-medium leading-relaxed max-w-lg"
          >
            Health club with top-notch equipment & certified trainers to reach your fitness goals. Friendly service catering to women too.
          </motion.p>

          {/* Action Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.35 }}
            className="flex flex-wrap items-center gap-4 pt-2"
          >
            <motion.button
              onClick={onOpenBooking}
              whileHover={{ scale: 1.05, boxShadow: "0px 0px 30px rgba(181,246,61,0.5)" }}
              whileTap={{ scale: 0.95 }}
              className="btn-nova-neon px-8 py-3.5 text-sm font-black flex items-center gap-2 cursor-pointer shadow-xl shadow-[#b5f63d]/20 transition-all"
            >
              Get Started <ArrowRight className="w-4 h-4" />
            </motion.button>

            <motion.button
              onClick={onOpenBooking}
              whileHover={{ scale: 1.04 }}
              whileTap={{ scale: 0.96 }}
              className="px-6 py-3 rounded-full border border-slate-700 bg-[#13151b]/80 hover:bg-[#1e222d] text-slate-200 font-bold text-xs flex items-center gap-3 transition-all cursor-pointer backdrop-blur-sm"
            >
              <div className="w-6 h-6 rounded-full bg-[#1e222d] flex items-center justify-center text-white">
                <Play className="w-3 h-3 fill-white ml-0.5" />
              </div>
              Watch Gym Tour
            </motion.button>
          </motion.div>

          {/* Stats Row */}
          <motion.div
            initial={{ opacity: 0, y: 25 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.45 }}
            className="grid grid-cols-3 gap-6 pt-8 border-t border-[#1e222d]/80 max-w-lg"
          >
            <motion.div whileHover={{ y: -3 }} className="space-y-1">
              <span className="text-2xl sm:text-4xl font-black text-white tracking-tight block">4.8 ★</span>
              <p className="text-xs text-slate-400 font-semibold">230 Reviews</p>
            </motion.div>

            <motion.div whileHover={{ y: -3 }} className="space-y-1">
              <span className="text-2xl sm:text-4xl font-black text-[#b5f63d] tracking-tight block">7+</span>
              <p className="text-xs text-slate-400 font-semibold">Core Programs</p>
            </motion.div>

            <motion.div whileHover={{ y: -3 }} className="space-y-1">
              <span className="text-2xl sm:text-4xl font-black text-white tracking-tight block">100%</span>
              <p className="text-xs text-slate-400 font-semibold">Clean Equipment</p>
            </motion.div>
          </motion.div>

        </div>
      </div>

      {/* Far Right Vertical Scroll Bar Indicator */}
      <div className="hidden lg:flex flex-col items-center justify-center absolute right-6 top-1/2 -translate-y-1/2 space-y-4 z-10">
        <span className="text-[10px] font-extrabold text-slate-400 tracking-[0.25em] uppercase rotate-90 origin-center whitespace-nowrap">
          SCROLL
        </span>
        <div className="w-0.5 h-16 bg-[#1e222d] relative overflow-hidden">
          <motion.div
            animate={{ y: [0, 64, 0] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
            className="w-full h-4 bg-[#b5f63d]"
          />
        </div>
      </div>

    </section>
  );
}
