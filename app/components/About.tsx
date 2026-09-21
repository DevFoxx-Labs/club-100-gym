"use client";

import React from 'react';
import { Award, ShieldCheck, Users, Dumbbell, Clock, Heart, CheckCircle2 } from 'lucide-react';
import { motion } from 'framer-motion';

interface AboutProps {
  onOpenBooking: () => void;
}

export default function About({ onOpenBooking }: AboutProps) {
  const values = [
    {
      icon: <Award className="w-5 h-5 text-[#b5f63d]" />,
      title: "Knowledgeable & Supportive Trainers",
      desc: "Experienced coaches ready to guide your form, design personalized workout protocols, and motivate you every day."
    },
    {
      icon: <Dumbbell className="w-5 h-5 text-[#b5f63d]" />,
      title: "Top-Notch Clean Facilities",
      desc: "Wide variety of well-maintained isolation machines, barbells, dumbbells, and cardio gear kept spotless."
    },
    {
      icon: <Heart className="w-5 h-5 text-[#b5f63d]" />,
      title: "Caters to Women Too",
      desc: "Friendly, welcoming, and safe atmosphere where women feel comfortable, supported, and empowered."
    },
    {
      icon: <Clock className="w-5 h-5 text-[#b5f63d]" />,
      title: "Morning & Evening Batches",
      desc: "Flexible timings open early, closing at 8:00 PM so you can fit workouts into your daily schedule."
    }
  ];

  return (
    <section id="about" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60 relative overflow-hidden">
      
      {/* Background Radial Glow */}
      <div className="absolute bottom-1/3 right-1/4 w-[500px] h-[500px] bg-[#b5f63d]/5 rounded-full blur-[140px] pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <div className="grid lg:grid-cols-12 gap-12 items-center">

          {/* Left Column: Text & Values */}
          <motion.div
            initial={{ opacity: 0, x: -30 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true, margin: "-50px" }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="lg:col-span-6 space-y-6 text-left"
          >
            <p className="text-xs sm:text-sm font-extrabold text-slate-400 tracking-[0.25em] uppercase">
              ABOUT CLUB 100 THE GYM
            </p>

            <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight leading-[1.05]">
              TRANSFORMING LIVES THROUGH <br />
              <span className="text-[#b5f63d]">DISCIPLINE & COMMUNITY</span>
            </h2>

            <p className="text-base text-slate-300 font-medium leading-relaxed">
              Located at 1st Floor TP Nagar, beside Kalewam Restaurant in Transport Nagar, Prayagraj, <strong>Club 100 The Gym</strong> is a 4.8★ rated health club (230+ Google reviews). We provide a positive, encouraging atmosphere equipped with top-notch clean facilities and experienced trainers who care about your results.
            </p>

            <div className="space-y-3 pt-2">
              <div className="flex items-center gap-3 text-xs font-semibold text-slate-200">
                <CheckCircle2 className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <span>7 Core Workouts: HIIT, Aerobics, Crossfit, Personal Training, Weight Training, Nutrition & Cycling</span>
              </div>
              <div className="flex items-center gap-3 text-xs font-semibold text-slate-200">
                <CheckCircle2 className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <span>Affordable Pricing Plans & Friendly Staff Catering to Women</span>
              </div>
              <div className="flex items-center gap-3 text-xs font-semibold text-slate-200">
                <CheckCircle2 className="w-4 h-4 text-[#b5f63d] shrink-0" />
                <span>Online Classes & Clean Restroom Facilities Available</span>
              </div>
            </div>

            <div className="pt-4">
              <motion.button
                onClick={onOpenBooking}
                whileHover={{ scale: 1.05, boxShadow: "0px 0px 30px rgba(181,246,61,0.4)" }}
                whileTap={{ scale: 0.95 }}
                className="btn-nova-neon px-8 py-3.5 text-xs font-black flex items-center gap-2 cursor-pointer transition-all"
              >
                Claim Free 1-Day Pass →
              </motion.button>
            </div>
          </motion.div>

          {/* Right Column: 4 Feature Cards */}
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            variants={{
              hidden: { opacity: 0 },
              visible: {
                opacity: 1,
                transition: { staggerChildren: 0.15 }
              }
            }}
            className="lg:col-span-6 grid sm:grid-cols-2 gap-4"
          >
            {values.map((v, i) => (
              <motion.div
                key={i}
                variants={{
                  hidden: { opacity: 0, y: 30 },
                  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.16, 1, 0.3, 1] } }
                }}
                whileHover={{ y: -6, borderColor: "rgba(181,246,61,0.6)", boxShadow: "0px 10px 30px rgba(0,0,0,0.5)" }}
                className="card-nova p-6 rounded-2xl space-y-3 text-left transition-all border border-[#1e222d]"
              >
                <div className="p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] w-fit">
                  {v.icon}
                </div>
                <h3 className="text-sm font-black text-white">{v.title}</h3>
                <p className="text-xs text-slate-400 font-medium leading-relaxed">
                  {v.desc}
                </p>
              </motion.div>
            ))}
          </motion.div>

        </div>
      </div>
    </section>
  );
}
