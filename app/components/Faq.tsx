"use client";

import React, { useState, useRef } from 'react';
import { Plus, Minus, ChevronDown, ChevronUp, Headphones, MessageSquare, Clock, Users, ShieldCheck, HelpCircle } from 'lucide-react';
import { motion, AnimatePresence, useScroll, useTransform, useSpring } from 'framer-motion';

interface FaqProps {
  onOpenBooking: () => void;
}

export default function Faq({ onOpenBooking }: FaqProps) {
  const [openIdx, setOpenIdx] = useState(0); // Default open first question
  const sectionRef = useRef<HTMLDivElement>(null);

  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"]
  });

  const bgY = useTransform(scrollYProgress, [0, 1], ["-8%", "8%"]);
  const smoothBgY = useSpring(bgY, { stiffness: 90, damping: 25 });

  const faqs = [
    {
      question: "What fitness services and classes are offered at Club 100?",
      answer: "We offer 7 core fitness programs: HIIT exercise classes, Aerobics, Crossfit conditioning, 1-on-1 Personal Training, Weight Training, Nutrition Consulting, and Indoor Cycling spin studio sessions."
    },
    {
      question: "Does Club 100 Gym cater to women?",
      answer: "Yes! Club 100 features a friendly, zero-judgment atmosphere with supportive staff that specifically caters to women, ensuring a safe and comfortable workout environment for everyone."
    },
    {
      question: "What are the operating hours for Club 100 The Gym?",
      answer: "We open early in the morning and close at 8:00 PM daily. Dedicated morning and evening training batches are available to fit any busy routine."
    },
    {
      question: "Are online classes and remote consultation available?",
      answer: "Yes, we offer online workout classes and diet & nutrition consultation for members who need flexible remote training options."
    },
    {
      question: "Where exactly is Club 100 The Gym located in Prayagraj?",
      answer: "We are located at 1st Floor TP Nagar, beside Kalewam Restaurant, Meera Patti, Transport Nagar, Prayagraj, Uttar Pradesh 211011."
    },
    {
      question: "What facilities and equipment are available?",
      answer: "Our gym features a wide variety of top-notch, clean, and well-maintained equipment (barbells, dumbbells, cable crossover, cardio decks), along with clean restrooms and changing areas."
    },
    {
      question: "Are trainers experienced and helpful?",
      answer: "Our members consistently highlight our knowledgeable and supportive trainers who are always on the gym floor ready to assist with form, technique, and motivation."
    },
    {
      question: "How affordable are the membership plans?",
      answer: "We pride ourselves on offering top-quality health club facilities at budget-friendly prices with no hidden charges, plus 1-day free trial passes for new members."
    }
  ];

  const bottomPillars = [
    {
      icon: <Clock className="w-5 h-5 text-[#b5f63d]" />,
      title: "Closes 8:00 PM",
      desc: "Morning & Evening Batches"
    },
    {
      icon: <MessageSquare className="w-5 h-5 text-[#b5f63d]" />,
      title: "Direct WhatsApp",
      desc: "Fast responses on 070843 06574"
    },
    {
      icon: <Users className="w-5 h-5 text-[#b5f63d]" />,
      title: "Women Friendly",
      desc: "Safe & inclusive environment"
    },
    {
      icon: <ShieldCheck className="w-5 h-5 text-[#b5f63d]" />,
      title: "Top-Notch Clean",
      desc: "Spotless facilities & restrooms"
    }
  ];

  return (
    <section ref={sectionRef} id="faq" className="py-20 bg-[#0b0c10] border-b border-[#1e222d]/60 relative overflow-hidden">
      
      {/* Full Section 3D Parallax Background Image */}
      <div className="absolute inset-0 pointer-events-none z-0 overflow-hidden">
        <motion.img
          style={{ y: smoothBgY }}
          src="/faq_bg.png"
          alt="Club 100 FAQ Background"
          className="w-full h-[125%] object-cover object-center opacity-75 -top-[12%] absolute"
        />
        <div className="absolute inset-0 bg-gradient-to-r from-[#0b0c10] via-[#0b0c10]/80 to-[#0b0c10]" />
        <div className="absolute inset-0 bg-gradient-to-t from-[#0b0c10] via-transparent to-[#0b0c10]/85 z-10" />
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 w-full space-y-12">
        
        {/* Top Header Row */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 text-left">
          <div className="space-y-3 max-w-2xl">
            <div className="flex items-center gap-3">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#13151b] border border-[#b5f63d]/40 text-[#b5f63d] text-xs font-black uppercase tracking-wider">
                <HelpCircle className="w-3.5 h-3.5" /> FAQ
              </span>
              <span className="text-xs font-extrabold text-slate-500 tracking-[0.2em] uppercase">
                —— QUESTIONS? WE'VE GOT YOU.
              </span>
            </div>

            <h2 className="text-4xl sm:text-6xl font-black text-white tracking-tight leading-[1.05]">
              Frequently Asked <span className="text-[#b5f63d]">Questions</span>
            </h2>

            <p className="text-xs sm:text-sm text-slate-300 font-medium leading-relaxed">
              Everything you need to know about Club 100 The Gym in Transport Nagar, Prayagraj.
            </p>
          </div>

          <div className="shrink-0 self-start md:self-end">
            <button
              onClick={onOpenBooking}
              className="px-6 py-3.5 rounded-full bg-[#13151b]/90 border border-[#1e222d] hover:border-[#b5f63d] text-white font-extrabold text-xs flex items-center gap-3 shadow-xl backdrop-blur-md hover:scale-105 transition-all cursor-pointer"
            >
              <div className="p-1.5 rounded-full bg-[#b5f63d] text-[#0b0c10]">
                <Headphones className="w-3.5 h-3.5" />
              </div>
              Still Have Questions? <span className="text-[#b5f63d]">Contact Support →</span>
            </button>
          </div>
        </div>

        {/* Two Columns Accordion Questions Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 lg:gap-6 text-left items-start">
          {faqs.map((faq, idx) => {
            const isOpen = openIdx === idx;
            return (
              <motion.div
                key={idx}
                initial={false}
                className={`rounded-2xl border transition-all overflow-hidden ${
                  isOpen
                    ? 'bg-[#13151b]/95 border-[#b5f63d]/60 shadow-xl shadow-[#b5f63d]/10'
                    : 'bg-[#13151b]/75 border-[#1e222d] hover:border-slate-700'
                }`}
              >
                <button
                  onClick={() => setOpenIdx(isOpen ? -1 : idx)}
                  className="w-full p-5 flex items-center justify-between gap-4 text-left cursor-pointer"
                >
                  <div className="flex items-center gap-3.5">
                    <div
                      className={`w-7 h-7 rounded-full flex items-center justify-center font-bold text-xs shrink-0 transition-colors ${
                        isOpen
                          ? 'bg-[#b5f63d] text-[#0b0c10]'
                          : 'bg-[#0b0c10] border border-[#1e222d] text-slate-300'
                      }`}
                    >
                      {isOpen ? <Minus className="w-4 h-4 stroke-[3]" /> : <Plus className="w-4 h-4" />}
                    </div>
                    <h3 className="text-sm sm:text-base font-black text-white">
                      {faq.question}
                    </h3>
                  </div>

                  <div className="text-slate-400 shrink-0">
                    {isOpen ? <ChevronUp className="w-4 h-4 text-[#b5f63d]" /> : <ChevronDown className="w-4 h-4" />}
                  </div>
                </button>

                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: "auto", opacity: 1 }}
                      exit={{ opacity: 0, height: 0 }}
                      transition={{ duration: 0.3, ease: "easeInOut" }}
                    >
                      <div className="px-5 pb-5 pl-14 text-xs sm:text-sm text-slate-300 font-medium leading-relaxed border-t border-[#1e222d]/40 pt-3">
                        {faq.answer}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            );
          })}
        </div>

        {/* Bottom 4 Value Pillars Bar */}
        <div className="pt-10 border-t border-[#1e222d]/80 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 text-left">
          {bottomPillars.map((p, i) => (
            <motion.div
              key={i}
              whileHover={{ y: -4 }}
              className="flex items-center gap-3.5 p-4 rounded-2xl bg-[#13151b]/60 border border-[#1e222d] transition-all"
            >
              <div className="p-3 rounded-xl bg-[#0b0c10] border border-[#1e222d] shrink-0">
                {p.icon}
              </div>
              <div>
                <h4 className="text-xs font-black text-white">{p.title}</h4>
                <p className="text-[11px] text-slate-400 font-medium">{p.desc}</p>
              </div>
            </motion.div>
          ))}
        </div>

      </div>
    </section>
  );
}
