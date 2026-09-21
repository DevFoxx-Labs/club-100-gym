"use client";

import React, { useState } from 'react';
import { X, Dumbbell, CheckCircle2, MessageSquare } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

interface BookingModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function BookingModal({ isOpen, onClose }: BookingModalProps) {
  const [step, setStep] = useState<'form' | 'success'>('form');
  const [formData, setFormData] = useState({
    passType: 'Free 1-Day Trial Pass',
    program: 'HIIT Exercise Classes',
    timeSlot: 'Morning Batch (6:00 AM)',
    name: '',
    phone: '',
    goal: 'Weight Loss & Toning'
  });

  const [bookingRef, setBookingRef] = useState('');

  const programOptions = [
    "HIIT Exercise Classes",
    "Aerobics & Fitness",
    "Crossfit Conditioning",
    "Personal Training (1-on-1)",
    "Weight Training",
    "Nutrition Consulting",
    "Indoor Cycling / Spin"
  ];

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const randomRef = 'CLUB100-' + Math.floor(10000 + Math.random() * 90000);
    setBookingRef(randomRef);
    setStep('success');
  };

  const whatsappMessage = encodeURIComponent(
    `Hello Club 100 The Gym (TP Nagar Prayagraj), I want to claim my free pass!\nRef ID: ${bookingRef}\nPass Type: ${formData.passType}\nProgram: ${formData.program}\nName: ${formData.name}\nPhone: ${formData.phone}\nSlot: ${formData.timeSlot}`
  );

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-[#0b0c10]/85 backdrop-blur-md"
          />

          {/* Modal Container */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
            className="relative w-full max-w-xl bg-[#13151b] rounded-3xl shadow-2xl border border-[#b5f63d]/40 overflow-hidden my-8 text-white z-10 text-left"
          >

            {/* Modal Header */}
            <div className="bg-[#b5f63d] p-6 text-[#0b0c10] flex items-center justify-between">
              <div className="space-y-1">
                <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[#0b0c10]/15 text-[#0b0c10] text-xs font-black">
                  <Dumbbell className="w-3.5 h-3.5" /> CLUB 100 THE GYM • TP NAGAR
                </div>
                <h3 className="text-xl sm:text-2xl font-black">Claim Free Pass / Join Gym</h3>
              </div>
              <button
                onClick={onClose}
                className="p-2 rounded-full bg-[#0b0c10]/15 hover:bg-[#0b0c10]/30 text-[#0b0c10] transition-colors cursor-pointer"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            {step === 'form' ? (
              <form onSubmit={handleSubmit} className="p-6 sm:p-8 space-y-5">

                {/* Pass Type */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-extrabold text-[#b5f63d] uppercase tracking-wider">
                    Select Inquiry / Pass Type
                  </label>
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      type="button"
                      onClick={() => setFormData({ ...formData, passType: 'Free 1-Day Trial Pass' })}
                      className={`p-3 rounded-xl border text-xs font-extrabold transition-all cursor-pointer ${
                        formData.passType === 'Free 1-Day Trial Pass'
                          ? 'bg-[#b5f63d] text-[#0b0c10] border-[#b5f63d] shadow-md'
                          : 'bg-[#0b0c10] text-slate-400 border-[#1e222d]'
                      }`}
                    >
                      🔥 Free 1-Day Trial Pass
                    </button>
                    <button
                      type="button"
                      onClick={() => setFormData({ ...formData, passType: 'Gym Membership Inquiry' })}
                      className={`p-3 rounded-xl border text-xs font-extrabold transition-all cursor-pointer ${
                        formData.passType === 'Gym Membership Inquiry'
                          ? 'bg-[#38bdf8] text-[#0b0c10] border-[#38bdf8] shadow-md'
                          : 'bg-[#0b0c10] text-slate-400 border-[#1e222d]'
                      }`}
                    >
                      💪 Membership & Pricing
                    </button>
                  </div>
                </div>

                {/* Program Selection */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-extrabold text-[#b5f63d] uppercase tracking-wider">
                    Interested Training Service
                  </label>
                  <select
                    value={formData.program}
                    onChange={(e) => setFormData({ ...formData, program: e.target.value })}
                    className="w-full p-3 rounded-xl border border-[#1e222d] bg-[#0b0c10] font-bold text-white text-xs sm:text-sm focus:outline-none focus:border-[#b5f63d]"
                  >
                    {programOptions.map((opt, i) => (
                      <option key={i} value={opt}>{opt}</option>
                    ))}
                  </select>
                </div>

                {/* Time Slot */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-extrabold text-[#b5f63d] uppercase tracking-wider">
                    Preferred Batch Time Slot
                  </label>
                  <select
                    value={formData.timeSlot}
                    onChange={(e) => setFormData({ ...formData, timeSlot: e.target.value })}
                    className="w-full p-3 rounded-xl border border-[#1e222d] bg-[#0b0c10] font-semibold text-white text-sm focus:outline-none focus:border-[#b5f63d]"
                  >
                    <option value="Morning Batch (6:00 AM)">🌅 Morning Batch (6:00 AM)</option>
                    <option value="Morning Batch (8:00 AM)">☀️ Morning Batch (8:00 AM)</option>
                    <option value="Evening Batch (5:00 PM)">🌆 Evening Batch (5:00 PM)</option>
                    <option value="Night Batch (7:00 PM - 8:00 PM)">🌙 Evening Batch (7:00 PM - 8:00 PM)</option>
                  </select>
                </div>

                {/* Name & Phone */}
                <div className="grid sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="block text-xs font-extrabold text-[#b5f63d] uppercase tracking-wider">
                      Your Full Name
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. Rahul Sharma"
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="w-full p-3 rounded-xl border border-[#1e222d] bg-[#0b0c10] font-medium text-white text-sm focus:outline-none focus:border-[#b5f63d]"
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="block text-xs font-extrabold text-[#b5f63d] uppercase tracking-wider">
                      Phone Number
                    </label>
                    <input
                      type="tel"
                      required
                      placeholder="e.g. 070843 06574"
                      value={formData.phone}
                      onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                      className="w-full p-3 rounded-xl border border-[#1e222d] bg-[#0b0c10] font-medium text-white text-sm focus:outline-none focus:border-[#b5f63d]"
                    />
                  </div>
                </div>

                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  type="submit"
                  className="w-full py-4 rounded-2xl btn-nova-neon text-[#0b0c10] font-black text-base shadow-xl transition-all cursor-pointer"
                >
                  Generate Free Pass Reference →
                </motion.button>

              </form>
            ) : (
              <div className="p-8 space-y-6 text-center">
                <div className="w-16 h-16 rounded-full bg-[#b5f63d]/20 text-[#b5f63d] flex items-center justify-center mx-auto border border-[#b5f63d]/40">
                  <CheckCircle2 className="w-10 h-10" />
                </div>

                <div className="space-y-2">
                  <span className="px-3 py-1 rounded-full bg-[#b5f63d]/20 text-[#b5f63d] text-xs font-extrabold border border-[#b5f63d]/40">
                    Pass Reference: {bookingRef}
                  </span>
                  <h4 className="text-2xl font-black text-white">Free Trial Pass Ready!</h4>
                  <p className="text-slate-300 text-sm font-medium">
                    Pass reserved for <strong>{formData.name}</strong> ({formData.passType}).
                  </p>
                </div>

                <div className="p-4 rounded-2xl bg-[#0b0c10] border border-[#1e222d] text-left text-xs space-y-2 font-medium">
                  <div className="flex justify-between border-b border-[#1e222d] pb-1.5">
                    <span className="text-slate-400">Gym Location:</span>
                    <span className="font-bold text-[#b5f63d]">TP Nagar, Transport Nagar, Prayagraj</span>
                  </div>
                  <div className="flex justify-between border-b border-[#1e222d] pb-1.5">
                    <span className="text-slate-400">Selected Service:</span>
                    <span className="font-bold text-white">{formData.program}</span>
                  </div>
                  <div className="flex justify-between border-b border-[#1e222d] pb-1.5">
                    <span className="text-slate-400">Batch Timing:</span>
                    <span className="font-bold text-[#38bdf8]">{formData.timeSlot}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Direct Helpline:</span>
                    <span className="font-bold text-white">070843 06574</span>
                  </div>
                </div>

                <div className="space-y-3 pt-2">
                  <a
                    href={`https://wa.me/917084306574?text=${whatsappMessage}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="w-full py-3.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-sm shadow-md flex items-center justify-center gap-2 cursor-pointer"
                  >
                    <MessageSquare className="w-4 h-4" /> Send Pass to WhatsApp Reception
                  </a>

                  <button
                    onClick={onClose}
                    className="w-full py-3 rounded-xl border border-[#1e222d] text-slate-300 font-bold text-sm hover:bg-[#1e222d] transition-colors cursor-pointer"
                  >
                    Close Window
                  </button>
                </div>
              </div>
            )}

          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
