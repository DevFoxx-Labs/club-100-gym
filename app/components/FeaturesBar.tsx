"use client";

import React from 'react';
import { Dumbbell, Heart, Zap, Award } from 'lucide-react';
import { motion } from 'framer-motion';

export default function FeaturesBar() {
  const features = [
    {
      icon: <Dumbbell className="w-5 h-5 text-white group-hover:text-[#b5f63d] transition-colors" />,
      title: "Top-Notch Clean Equipment",
      desc: "Well-maintained machines & weights"
    },
    {
      icon: <Heart className="w-5 h-5 text-white group-hover:text-[#b5f63d] transition-colors" />,
      title: "Caters to Women Too",
      desc: "Friendly & safe environment"
    },
    {
      icon: <Award className="w-5 h-5 text-white group-hover:text-[#b5f63d] transition-colors" />,
      title: "Knowledgeable Trainers",
      desc: "Expert guidance every step"
    },
    {
      icon: <Zap className="w-5 h-5 text-white group-hover:text-[#b5f63d] transition-colors" />,
      title: "Affordable Pricing",
      desc: "Best fitness value in Prayagraj"
    }
  ];

  return (
    <section className="bg-[#0b0c10] border-b border-[#1e222d] py-10 overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
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
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 divide-y sm:divide-y-0 sm:divide-x divide-[#1e222d]"
        >
          {features.map((feat, idx) => (
            <motion.div
              key={idx}
              variants={{
                hidden: { opacity: 0, y: 25 },
                visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: [0.16, 1, 0.3, 1] } }
              }}
              whileHover={{ y: -4 }}
              className="flex flex-col items-center text-center p-6 space-y-2 group cursor-pointer"
            >
              <div className="p-3 rounded-full bg-[#13151b] border border-[#1e222d] group-hover:border-[#b5f63d] group-hover:shadow-[0_0_20px_rgba(181,246,61,0.25)] group-hover:scale-110 transition-all duration-300">
                {feat.icon}
              </div>
              <h3 className="text-sm font-black text-white pt-1 group-hover:text-[#b5f63d] transition-colors">{feat.title}</h3>
              <p className="text-xs text-slate-400 font-medium">{feat.desc}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
