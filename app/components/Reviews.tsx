"use client";

import React from 'react';
import { Star, Quote, ThumbsUp, ShieldCheck, Heart, Sparkles, CheckCircle2 } from 'lucide-react';
import { motion } from 'framer-motion';

export default function Reviews() {
  const googleReviews = [
    {
      author: "Verified Google Reviewer",
      rating: 5,
      date: "Google Review",
      quote: "Great place for the workout...awsm environment...",
      tag: "Positive Atmosphere & Vibe"
    },
    {
      author: "Transport Nagar Member",
      rating: 5,
      date: "Google Review",
      quote: "The staff is helpful and the atmosphere is positive.",
      tag: "Supportive Staff"
    },
    {
      author: "Prayagraj Gym Goer",
      rating: 5,
      date: "Google Review",
      quote: "Nice gym with experienced trainers at affordable price",
      tag: "Experienced & Affordable"
    },
    {
      author: "Active Trainee",
      rating: 5,
      date: "Google Review",
      quote: "Wide variety of top-notch, clean equipment. Supportive trainers who are always ready to help.",
      tag: "Clean Top-Notch Equipment"
    }
  ];

  return (
    <section id="reviews" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

        {/* Header */}
        <div className="text-center max-w-3xl mx-auto space-y-4">
          <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-amber-500/20 text-amber-400 text-xs font-extrabold uppercase tracking-wider border border-amber-500/30">
            <Star className="w-3.5 h-3.5 fill-amber-400" /> VERIFIED GOOGLE REVIEWS
          </div>
          <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight">
            4.8 ★ Rated on Google (230 Reviews)
          </h2>
          <p className="text-slate-300 text-sm sm:text-base font-medium leading-relaxed max-w-2xl mx-auto">
            "People say this gym has a positive atmosphere with well-maintained facilities and a wide variety of top-notch, clean equipment. They also highlight the knowledgeable and supportive trainers who are always ready to help."
          </p>
        </div>

        {/* AI Summary Highlight Box */}
        <div className="mt-8 p-6 rounded-3xl bg-[#13151b] border border-[#b5f63d]/40 max-w-3xl mx-auto text-left flex items-start gap-4 shadow-xl">
          <div className="p-3 rounded-2xl bg-[#b5f63d]/15 text-[#b5f63d] border border-[#b5f63d]/30 shrink-0">
            <Sparkles className="w-6 h-6" />
          </div>
          <div className="space-y-1">
            <span className="text-[11px] font-black text-[#b5f63d] uppercase tracking-wider block">Summarised by Google AI</span>
            <p className="text-xs sm:text-sm text-slate-200 font-medium leading-relaxed">
              Caters to women • Online classes available • Restrooms • Friendly service & experienced trainers at affordable prices in TP Nagar, Transport Nagar, Prayagraj.
            </p>
          </div>
        </div>

        {/* Reviews Grid */}
        <div className="grid md:grid-cols-2 gap-6 mt-12 text-left">
          {googleReviews.map((rev, idx) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: idx * 0.1 }}
              whileHover={{ y: -6 }}
              className="bg-[#13151b] p-6 sm:p-8 rounded-3xl space-y-4 border border-[#1e222d] hover:border-[#b5f63d]/50 transition-all relative flex flex-col justify-between shadow-2xl"
            >
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1 text-amber-400">
                    {[...Array(rev.rating)].map((_, i) => (
                      <Star key={i} className="w-4 h-4 fill-amber-400" />
                    ))}
                  </div>
                  <span className="text-[10px] font-black px-2.5 py-0.5 rounded-full bg-[#b5f63d]/15 text-[#b5f63d] border border-[#b5f63d]/30 uppercase tracking-wider">
                    {rev.tag}
                  </span>
                </div>

                <Quote className="w-8 h-8 text-[#b5f63d]/40" />

                <p className="text-sm sm:text-base font-semibold text-slate-200 leading-relaxed italic">
                  "{rev.quote}"
                </p>
              </div>

              <div className="pt-4 border-t border-[#1e222d] flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-black text-white">{rev.author}</h4>
                  <p className="text-[10px] text-slate-400 font-medium">{rev.date}</p>
                </div>
                <div className="flex items-center gap-1 text-xs font-bold text-slate-400">
                  <ThumbsUp className="w-3.5 h-3.5 text-[#b5f63d]" /> Helpful
                </div>
              </div>

            </motion.div>
          ))}
        </div>

      </div>
    </section>
  );
}
